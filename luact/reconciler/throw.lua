-- Error handling for the render phase and the commit phase.
--
-- When a fiber throws while rendering, the nearest ErrorBoundary above it is
-- marked with SHOULD_CAPTURE and gets a capture update. The work loop then
-- completes the failed fibers as INCOMPLETE up to the boundary, which renders
-- again with its fallback. If no boundary catches the error, the root
-- unmounts its tree and the error is raised again after the commit.

local tags = require "luact.reconciler.tags"
local schedule = require "luact.reconciler.schedule"

local WORK = tags.work
local EFFECT = tags.effect
local has_flag = tags.has
local add_flag = tags.add
local remove_flag = tags.remove

local M = {}

local function describe_fiber(fiber)
  local tag = fiber.tag
  if tag == WORK.HOST_COMPONENT then
    return tostring(fiber.type)
  end
  local component = nil
  if tag == WORK.FUNCTION_COMPONENT then
    component = fiber.type
  elseif tag == WORK.MEMO_COMPONENT then
    component = fiber.type.type
  elseif tag == WORK.ERROR_BOUNDARY then
    return "ErrorBoundary"
  elseif tag == WORK.CONTEXT_PROVIDER then
    return "Context.Provider"
  elseif tag == WORK.CONTEXT_CONSUMER then
    return "Context.Consumer"
  end
  if component ~= nil and debug and debug.getinfo then
    local info = debug.getinfo(component, "S")
    if info ~= nil then
      return "component at " .. tostring(info.short_src) .. ":" .. tostring(info.linedefined)
    end
  end
  return nil
end

-- Lists the components from `fiber` up to the root, one per line.
function M.get_component_stack(fiber)
  local lines = {}
  local node = fiber
  while node ~= nil do
    local name = describe_fiber(node)
    if name ~= nil then
      lines[#lines + 1] = "    in " .. name
    end
    node = node.parent
  end
  return table.concat(lines, "\n")
end

local function enqueue(queue, update)
  if queue.last == nil then
    queue.first = update
  else
    queue.last.next = update
  end
  queue.last = update
end

local function enqueue_capture(boundary, value, source_fiber)
  enqueue(boundary.update_queue, {
    kind = "capture",
    error = value,
    info = { component_stack = M.get_component_stack(source_fiber) },
    next = nil,
  })
end

local function enqueue_root_error(root_fiber, value)
  enqueue(root_fiber.update_queue, { kind = "error", error = value, next = nil })
end

-- Render phase: `source_fiber` threw `value`.
function M.throw_exception(return_fiber, source_fiber, value)
  -- the source fiber did not finish, its effects are invalid
  source_fiber.effect_tag = add_flag(source_fiber.effect_tag, EFFECT.INCOMPLETE)
  source_fiber.first_effect = nil
  source_fiber.last_effect = nil

  local node = return_fiber
  while node ~= nil do
    local tag = node.tag
    if tag == WORK.ERROR_BOUNDARY and not has_flag(node.effect_tag, EFFECT.DID_CAPTURE) then
      node.effect_tag = add_flag(node.effect_tag, EFFECT.SHOULD_CAPTURE)
      node.pending_work = true
      enqueue_capture(node, value, source_fiber)
      return
    elseif tag == WORK.HOST_ROOT then
      node.effect_tag = add_flag(node.effect_tag, EFFECT.SHOULD_CAPTURE)
      node.pending_work = true
      enqueue_root_error(node, value)
      return
    end
    node = node.parent
  end
end

-- Called on INCOMPLETE fibers while completing. Returns the fiber to render
-- again if it can handle the error.
function M.unwind_work(wip)
  local tag = wip.tag
  if tag == WORK.ERROR_BOUNDARY or tag == WORK.HOST_ROOT then
    local flags = wip.effect_tag
    if has_flag(flags, EFFECT.SHOULD_CAPTURE) then
      flags = remove_flag(flags, EFFECT.SHOULD_CAPTURE)
      flags = remove_flag(flags, EFFECT.INCOMPLETE)
      wip.effect_tag = add_flag(flags, EFFECT.DID_CAPTURE)
      return wip
    end
  end
  return nil
end

-- Commit phase and passive effects: `source_fiber` threw `value`. Schedules
-- the nearest boundary to render its fallback. Boundaries that already show
-- their fallback are skipped. `start` is the first ancestor to check, for
-- fibers that were already detached from the tree.
function M.capture_commit_phase_error(source_fiber, value, start)
  local node = start or source_fiber.parent
  while node ~= nil do
    if
      node.tag == WORK.ERROR_BOUNDARY
      and node.state_node ~= nil
      and not node.memoized_state.has_error
      and not (node.alternate ~= nil and node.alternate.memoized_state.has_error)
    then
      enqueue_capture(node, value, source_fiber)
      if schedule.schedule_update_on_fiber(node) ~= nil then
        return
      end
    elseif node.tag == WORK.HOST_ROOT then
      enqueue_root_error(node, value)
      schedule.schedule_update_on_fiber(node)
      return
    end
    node = node.parent
  end
  -- The fiber is detached from any root. Nothing can handle the error.
  error(value, 0)
end

return M
