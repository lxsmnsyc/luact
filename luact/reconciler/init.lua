-- Creates a renderer from a host config.
--
-- Rendering is split into small units of work, one fiber each. The host
-- drives the work by calling `renderer.work_loop(deadline)`, typically once
-- per frame. `deadline()` returns the milliseconds left in the frame and the
-- loop yields when it drops below 1. Updates are batched: calling a state
-- setter only schedules work, nothing renders until the work loop runs.
--
-- Updates scheduled by a layout effect are rendered synchronously right after
-- the commit, so the host never shows the intermediate state.

local tags = require "luact.reconciler.tags"
local fiber_module = require "luact.reconciler.fiber"
local begin_work = require "luact.reconciler.begin_work"
local complete_work = require "luact.reconciler.complete_work"
local commit = require "luact.reconciler.commit"
local throw = require "luact.reconciler.throw"
local hooks = require "luact.reconciler.hooks"
local schedule = require "luact.reconciler.schedule"

local EFFECT = tags.effect
local has_flag = tags.has

local NESTED_UPDATE_LIMIT = 50

local function noop()
end

local function identity(value)
  return value
end

local function return_true()
  return true
end

local function return_false()
  return false
end

local REQUIRED = { "create_instance", "append_child", "remove_child" }

local function resolve_host_config(config)
  if type(config) ~= "table" then
    error("create_renderer: expected a host config table", 3)
  end
  for i = 1, #REQUIRED do
    local name = REQUIRED[i]
    if type(config[name]) ~= "function" then
      error("create_renderer: host config is missing the function `" .. name .. "`", 3)
    end
  end

  local host = {}
  for k, v in pairs(config) do
    host[k] = v
  end

  local function missing(name)
    return function ()
      error("The host config does not implement `" .. name .. "`", 0)
    end
  end

  host.create_text_instance = host.create_text_instance or missing("create_text_instance")
  host.insert_before = host.insert_before or missing("insert_before")
  host.append_initial_child = host.append_initial_child or host.append_child
  host.append_child_to_container = host.append_child_to_container or host.append_child
  host.insert_in_container_before = host.insert_in_container_before or host.insert_before
  host.remove_child_from_container = host.remove_child_from_container or host.remove_child
  host.prepare_update = host.prepare_update or return_true
  host.commit_update = host.commit_update or noop
  host.commit_text_update = host.commit_text_update or noop
  host.finalize_initial_children = host.finalize_initial_children or return_false
  host.commit_mount = host.commit_mount or noop
  host.prepare_for_commit = host.prepare_for_commit or noop
  host.reset_after_commit = host.reset_after_commit or noop
  host.get_public_instance = host.get_public_instance or identity
  host.schedule_work = host.schedule_work or noop
  return host
end

-- Recomputes whether any child of `wip` has pending work.
local function reset_child_pending_work(wip)
  local child = wip.child
  while child ~= nil do
    if child.pending_work or child.child_pending_work then
      wip.child_pending_work = true
      return
    end
    child = child.sibling
  end
  wip.child_pending_work = false
end

-- Completes `unit` and its ancestors until one has a sibling left to work
-- on. Fibers that threw are unwound up to the error boundary that caught.
local function complete_unit_of_work(root, unit)
  local host = root.host
  local wip = unit
  while true do
    root.cursor = wip
    local current = wip.alternate
    local return_fiber = wip.parent
    local sibling = wip.sibling

    if not has_flag(wip.effect_tag, EFFECT.INCOMPLETE) then
      complete_work(host, current, wip)
      reset_child_pending_work(wip)

      if return_fiber ~= nil and not has_flag(return_fiber.effect_tag, EFFECT.INCOMPLETE) then
        -- append the effects of the subtree, then this fiber's own effect
        if return_fiber.first_effect == nil then
          return_fiber.first_effect = wip.first_effect
        end
        if wip.last_effect ~= nil then
          if return_fiber.last_effect ~= nil then
            return_fiber.last_effect.next_effect = wip.first_effect
          end
          return_fiber.last_effect = wip.last_effect
        end
        if wip.effect_tag > EFFECT.PERFORMED_WORK then
          if return_fiber.last_effect ~= nil then
            return_fiber.last_effect.next_effect = wip
          else
            return_fiber.first_effect = wip
          end
          return_fiber.last_effect = wip
        end
      end
    else
      -- this fiber threw or has a child that threw
      local next_unit = throw.unwind_work(wip)
      if next_unit ~= nil then
        -- a boundary caught the error: render it again
        return next_unit
      end
      if return_fiber ~= nil then
        return_fiber.first_effect = nil
        return_fiber.last_effect = nil
        return_fiber.effect_tag = tags.add(return_fiber.effect_tag, EFFECT.INCOMPLETE)
      end
    end

    if sibling ~= nil then
      return sibling
    end
    if return_fiber == nil then
      return nil
    end
    wip = return_fiber
  end
end

local function perform_unit_of_work(root, unit)
  root.cursor = unit
  local next_unit = begin_work(unit.alternate, unit)
  unit.memoized_props = unit.pending_props
  if next_unit == nil then
    next_unit = complete_unit_of_work(root, unit)
  end
  return next_unit
end

local function work_loop_body(root, deadline)
  local source = root.thrown_fiber
  if source ~= nil then
    root.thrown_fiber = nil
    root.next_unit_of_work = complete_unit_of_work(root, source)
  end
  while root.next_unit_of_work ~= nil do
    root.next_unit_of_work = perform_unit_of_work(root, root.next_unit_of_work)
    if deadline ~= nil and deadline() < 1 then
      return
    end
  end
end

-- Runs units of work until the tree is complete or the deadline is reached.
-- Returns true when the tree is complete.
local function render_root(root, deadline)
  while true do
    local ok, err = pcall(work_loop_body, root, deadline)
    if ok then
      return root.next_unit_of_work == nil
    end

    hooks.reset_after_throw()
    local source = root.cursor
    if source == nil or source.parent == nil then
      -- nothing can catch this, drop the render
      root.next_unit_of_work = nil
      root.wip_root_fiber = nil
      error(err, 0)
    end
    throw.throw_exception(source.parent, source, err)
    -- complete the failed fiber inside the protected loop, since completing
    -- its ancestors can throw too
    root.thrown_fiber = source
    root.next_unit_of_work = source
  end
end

local function has_render_work(root)
  local current = root.current
  return current.pending_work or current.child_pending_work
end

return function (host_config)
  local host = resolve_host_config(host_config)

  local renderer = {}
  local scheduled_roots = {}

  local function ensure_scheduled(root)
    if root.is_committing then
      -- updates from layout effects render before the host is drawn
      root.needs_sync_render = true
    end
    if root.is_scheduled then
      return
    end
    root.is_scheduled = true
    scheduled_roots[#scheduled_roots + 1] = root
    host.schedule_work()
  end

  local function unschedule(root)
    root.is_scheduled = false
    for i = 1, #scheduled_roots do
      if scheduled_roots[i] == root then
        table.remove(scheduled_roots, i)
        return
      end
    end
  end

  local function has_pending(root)
    return root.next_unit_of_work ~= nil
      or has_render_work(root)
      or commit.has_pending_passive_effects(root)
  end

  local function finish_commit(root)
    local finished_work = root.wip_root_fiber
    root.wip_root_fiber = nil
    root.cursor = nil
    commit.commit_root(root, finished_work)

    if root.has_uncaught_error then
      local err = root.uncaught_error
      root.has_uncaught_error = false
      root.uncaught_error = nil
      root.needs_sync_render = false
      root.is_working = false
      if not has_pending(root) then
        unschedule(root)
      end
      error(err, 0)
    end
  end

  -- Renders and commits the pending work of a root. Returns true if work is
  -- left when the deadline is reached.
  local function perform_work_on_root(root, deadline)
    if root.is_working then
      error("Cannot run the work loop while a root is rendering or committing.", 0)
    end

    local nested_updates = 0
    local render_deadline = deadline
    local is_first = true

    while true do
      if root.next_unit_of_work == nil then
        -- Passive effects of an earlier call run now. Those of a commit made
        -- by this call wait for the next call, unless another render follows.
        if is_first then
          commit.flush_passive_effects(root)
        end
        if not has_render_work(root) then
          return false
        end
        if not is_first then
          commit.flush_passive_effects(root)
        end
        root.wip_root_fiber = fiber_module.create_work_in_progress(root.current, nil)
        root.next_unit_of_work = root.wip_root_fiber
      end

      is_first = false
      root.is_working = true
      local ok, completed = pcall(render_root, root, render_deadline)
      if not ok then
        root.is_working = false
        error(completed, 0)
      end
      if not completed then
        root.is_working = false
        return true
      end

      ok, completed = pcall(finish_commit, root)
      root.is_working = false
      if not ok then
        error(completed, 0)
      end

      if root.needs_sync_render then
        root.needs_sync_render = false
        nested_updates = nested_updates + 1
        if nested_updates > NESTED_UPDATE_LIMIT then
          error(
            "Maximum update depth exceeded. A layout effect updates state on "
              .. "every render, which causes an infinite loop.",
            0
          )
        end
        render_deadline = nil
      elseif deadline ~= nil and deadline() < 1 then
        return has_pending(root)
      else
        render_deadline = deadline
      end
    end
  end

  local function process_root(root, deadline)
    local ok, more = pcall(perform_work_on_root, root, deadline)
    if not ok then
      if not has_pending(root) then
        unschedule(root)
      end
      error(more, 0)
    end
    if not more and not has_pending(root) then
      unschedule(root)
    end
    return more
  end

  -- Performs scheduled work until `deadline()` returns less than 1
  -- millisecond. Without a deadline, all work is done. Returns true if work
  -- is left.
  function renderer.work_loop(deadline)
    local roots = {}
    for i = 1, #scheduled_roots do
      roots[i] = scheduled_roots[i]
    end
    for i = 1, #roots do
      -- the first root always makes progress
      if i > 1 and deadline ~= nil and deadline() < 1 then
        break
      end
      local root = roots[i]
      if process_root(root, deadline) and root.is_scheduled then
        -- move unfinished roots to the back so other roots get a turn
        unschedule(root)
        root.is_scheduled = true
        scheduled_roots[#scheduled_roots + 1] = root
      end
    end
    return #scheduled_roots > 0
  end

  local function assert_not_working()
    for i = 1, #scheduled_roots do
      if scheduled_roots[i].is_working then
        error("flush_sync cannot be called while rendering or committing.", 3)
      end
    end
  end

  -- Calls `fn`, then renders and commits all scheduled updates right away.
  -- Passive effects of the last commit stay pending.
  function renderer.flush_sync(fn)
    assert_not_working()
    local result = nil
    if fn ~= nil then
      result = fn()
    end
    local guard = 0
    local index = 1
    while index <= #scheduled_roots do
      local root = scheduled_roots[index]
      if root.next_unit_of_work ~= nil or has_render_work(root) then
        guard = guard + 1
        if guard > 1000 then
          error("flush_sync: work did not settle", 2)
        end
        process_root(root, nil)
        index = 1
      else
        index = index + 1
      end
    end
    return result
  end

  -- Calls `fn`, then runs all scheduled work and effects until nothing is
  -- left. Meant for tests.
  function renderer.act(fn)
    assert_not_working()
    local result = nil
    if fn ~= nil then
      result = fn()
    end
    local guard = 0
    while #scheduled_roots > 0 do
      guard = guard + 1
      if guard > 1000 then
        error("act: work did not settle", 2)
      end
      local root = scheduled_roots[1]
      process_root(root, nil)
      if root.is_scheduled then
        local ok, err = pcall(commit.flush_passive_effects, root)
        if not ok then
          error(err, 0)
        end
        if not has_pending(root) then
          unschedule(root)
        end
      end
    end
    return result
  end

  function renderer.has_pending_work()
    return #scheduled_roots > 0
  end

  local Root = {}
  Root.__index = Root

  -- Renders `element` into the root. The render happens on the next work
  -- loop.
  function Root:render(element)
    if self.is_unmounted then
      error("Cannot render into a root that was unmounted.", 2)
    end
    local queue = self.current.update_queue
    local update = { kind = "element", element = element, next = nil }
    if queue.last == nil then
      queue.first = update
    else
      queue.last.next = update
    end
    queue.last = update
    schedule.schedule_update_on_fiber(self.current)
  end

  -- Unmounts the tree right away, running every cleanup.
  function Root:unmount()
    if self.is_unmounted then
      return
    end
    self:render(nil)
    renderer.flush_sync()
    commit.flush_passive_effects(self)
    self.is_unmounted = true
    if not has_pending(self) then
      unschedule(self)
    end
  end

  function renderer.create_root(container)
    local root = setmetatable({
      container_info = container,
      host = host,
      current = nil,
      ensure_scheduled = ensure_scheduled,

      is_scheduled = false,
      is_working = false,
      is_committing = false,
      is_unmounted = false,
      needs_sync_render = false,

      wip_root_fiber = nil,
      next_unit_of_work = nil,
      cursor = nil,
      thrown_fiber = nil,

      pending_passive_effects = {},
      pending_passive_unmounts = {},
      deletions = {},

      has_uncaught_error = false,
      uncaught_error = nil,
    }, Root)
    root.current = fiber_module.create_host_root_fiber(root)
    return root
  end

  renderer.host_config = host

  return renderer
end
