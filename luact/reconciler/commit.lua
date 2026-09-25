-- The commit phase: applies a finished work-in-progress tree to the host.
--
-- The effect list built while completing fibers is walked twice:
--   1. mutation: detach old refs, insert, update and remove host nodes, run
--      insertion effects and the cleanup of layout effects that changed.
--   2. layout: run layout effects, attach refs, call error boundary callbacks.
-- Passive effects (use_effect) are collected and run later by
-- `flush_passive_effects`.

local tags = require "luact.reconciler.tags"
local throw = require "luact.reconciler.throw"

local WORK = tags.work
local EFFECT = tags.effect
local HOOK = tags.hook
local has_flag = tags.has
local remove_flag = tags.remove

-- First error that no boundary or root could take. It is raised once the
-- commit or the passive effects are done, so the tree stays consistent.
local unhandled_error = nil
local has_unhandled_error = false

local function capture_commit_phase_error(source_fiber, value, start)
  local ok, err = pcall(throw.capture_commit_phase_error, source_fiber, value, start)
  if not ok and not has_unhandled_error then
    has_unhandled_error = true
    unhandled_error = err
  end
end

local function raise_unhandled_error()
  if has_unhandled_error then
    local err = unhandled_error
    has_unhandled_error = false
    unhandled_error = nil
    error(err, 0)
  end
end

local M = {}

local function is_function_component(fiber)
  return fiber.tag == WORK.FUNCTION_COMPONENT or fiber.tag == WORK.MEMO_COMPONENT
end

local function call_destroy(fiber, destroy, ancestor)
  local ok, err = pcall(destroy)
  if not ok then
    capture_commit_phase_error(fiber, err, ancestor)
  end
end

-- Runs the cleanup of the effects of `fiber` whose tag is `flags`.
local function commit_hook_effects_unmount(flags, fiber)
  local queue = fiber.update_queue
  if queue == nil then
    return
  end
  local effects = queue.effects
  for i = 1, #effects do
    local effect = effects[i]
    if effect.tag == flags then
      local inst = effect.inst
      local destroy = inst.destroy
      if destroy ~= nil then
        inst.destroy = nil
        call_destroy(fiber, destroy)
      end
    end
  end
end

-- Runs the effects of `fiber` whose tag is `flags`.
local function commit_hook_effects_mount(flags, fiber)
  local queue = fiber.update_queue
  if queue == nil then
    return
  end
  local effects = queue.effects
  for i = 1, #effects do
    local effect = effects[i]
    if effect.tag == flags then
      local ok, destroy = pcall(effect.create)
      if not ok then
        capture_commit_phase_error(fiber, destroy)
      elseif destroy ~= nil and type(destroy) ~= "function" then
        capture_commit_phase_error(
          fiber,
          "An effect function must return nothing or a cleanup function, got: "
            .. tostring(destroy)
        )
      else
        effect.inst.destroy = destroy
      end
    end
  end
end

local HAS_INSERTION = HOOK.HAS_EFFECT + HOOK.INSERTION
local HAS_LAYOUT = HOOK.HAS_EFFECT + HOOK.LAYOUT
local HAS_PASSIVE = HOOK.HAS_EFFECT + HOOK.PASSIVE

-- Refs

local function commit_attach_ref(host, fiber)
  local ref = fiber.ref
  if ref == nil then
    return
  end
  local instance = host.get_public_instance(fiber.state_node)
  local cleanup = nil
  if type(ref) == "function" then
    cleanup = ref(instance)
    if type(cleanup) ~= "function" then
      cleanup = nil
    end
  else
    ref.current = instance
  end
  -- both copies keep the cleanup, since either may be current at detach
  fiber.ref_cleanup = cleanup
  if fiber.alternate ~= nil then
    fiber.alternate.ref_cleanup = cleanup
  end
end

local function commit_detach_ref(fiber)
  local ref = fiber.ref
  if ref == nil then
    return
  end
  local cleanup = fiber.ref_cleanup
  if cleanup ~= nil then
    fiber.ref_cleanup = nil
    if fiber.alternate ~= nil then
      fiber.alternate.ref_cleanup = nil
    end
    cleanup()
  elseif type(ref) == "function" then
    ref(nil)
  else
    ref.current = nil
  end
end

local function safely_detach_ref(fiber, ancestor)
  local ok, err = pcall(commit_detach_ref, fiber)
  if not ok then
    capture_commit_phase_error(fiber, err, ancestor)
  end
end

-- Placement

local function is_host_parent(fiber)
  local tag = fiber.tag
  return tag == WORK.HOST_COMPONENT or tag == WORK.HOST_ROOT or tag == WORK.HOST_PORTAL
end

local function get_host_parent_fiber(fiber)
  local parent = fiber.parent
  while parent ~= nil do
    if is_host_parent(parent) then
      return parent
    end
    parent = parent.parent
  end
  error("Expected to find a host parent.", 0)
end

-- Finds the host node that the nodes of `fiber` must be inserted before, or
-- nil to append them. Siblings that are being placed in this commit are
-- skipped because they are not in the host tree yet.
local function get_host_sibling(fiber)
  local node = fiber
  while true do
    while node.sibling == nil do
      if node.parent == nil or is_host_parent(node.parent) then
        return nil
      end
      node = node.parent
    end
    node.sibling.parent = node.parent
    node = node.sibling

    local skip = false
    while node.tag ~= WORK.HOST_COMPONENT and node.tag ~= WORK.HOST_TEXT do
      if
        has_flag(node.effect_tag, EFFECT.PLACEMENT)
        or node.child == nil
        or node.tag == WORK.HOST_PORTAL
      then
        skip = true
        break
      end
      node.child.parent = node
      node = node.child
    end

    if not skip and not has_flag(node.effect_tag, EFFECT.PLACEMENT) then
      return node.state_node
    end
  end
end

local function commit_placement(host, finished_work)
  local parent_fiber = get_host_parent_fiber(finished_work)
  local parent, is_container
  if parent_fiber.tag == WORK.HOST_COMPONENT then
    parent = parent_fiber.state_node
    is_container = false
  else
    parent = parent_fiber.state_node.container_info
    is_container = true
  end

  local before = get_host_sibling(finished_work)

  -- insert every top-level host node of the subtree
  local node = finished_work
  while true do
    local descended = false
    if node.tag == WORK.HOST_COMPONENT or node.tag == WORK.HOST_TEXT then
      local instance = node.state_node
      if before ~= nil then
        if is_container then
          host.insert_in_container_before(parent, instance, before)
        else
          host.insert_before(parent, instance, before)
        end
      elseif is_container then
        host.append_child_to_container(parent, instance)
      else
        host.append_child(parent, instance)
      end
    elseif node.tag ~= WORK.HOST_PORTAL and node.child ~= nil then
      -- portals place their own children
      node.child.parent = node
      node = node.child
      descended = true
    end

    if not descended then
      if node == finished_work then
        return
      end
      while node.sibling == nil do
        if node.parent == nil or node.parent == finished_work then
          return
        end
        node = node.parent
      end
      node.sibling.parent = node.parent
      node = node.sibling
    end
  end
end

-- Deletion

-- Nearest mounted ancestor of the fiber being deleted, used to report errors
-- thrown by cleanups.
local deletion_ancestor = nil

local unmount_host_components

local function commit_unmount(root, host, fiber)
  local tag = fiber.tag
  if tag == WORK.FUNCTION_COMPONENT or tag == WORK.MEMO_COMPONENT then
    local queue = fiber.update_queue
    if queue ~= nil then
      local effects = queue.effects
      for i = 1, #effects do
        local effect = effects[i]
        local inst = effect.inst
        local destroy = inst.destroy
        if destroy ~= nil then
          inst.destroy = nil
          if has_flag(effect.tag, HOOK.PASSIVE) then
            local unmounts = root.pending_passive_unmounts
            unmounts[#unmounts + 1] = {
              destroy = destroy,
              fiber = fiber,
              ancestor = deletion_ancestor,
            }
          else
            call_destroy(fiber, destroy, deletion_ancestor)
          end
        end
      end
    end
  elseif tag == WORK.HOST_COMPONENT then
    safely_detach_ref(fiber, deletion_ancestor)
  elseif tag == WORK.HOST_PORTAL then
    unmount_host_components(root, host, fiber)
  end
end

-- Unmounts every fiber of the subtree without removing host nodes. Used
-- below a host node that gets removed as a whole.
local function commit_nested_unmounts(root, host, subtree_root)
  local node = subtree_root
  while true do
    commit_unmount(root, host, node)
    if node.child ~= nil and node.tag ~= WORK.HOST_PORTAL then
      node.child.parent = node
      node = node.child
    else
      if node == subtree_root then
        return
      end
      while node.sibling == nil do
        if node.parent == nil or node.parent == subtree_root then
          return
        end
        node = node.parent
      end
      node.sibling.parent = node.parent
      node = node.sibling
    end
  end
end

-- Removes the top-level host nodes of the subtree of `current` from their
-- host parent, and unmounts every fiber.
unmount_host_components = function (root, host, current)
  local node = current
  local parent_found = false
  local parent, is_container

  while true do
    if not parent_found then
      local parent_fiber = get_host_parent_fiber(node)
      if parent_fiber.tag == WORK.HOST_COMPONENT then
        parent = parent_fiber.state_node
        is_container = false
      else
        parent = parent_fiber.state_node.container_info
        is_container = true
      end
      parent_found = true
    end

    local descended = false
    if node.tag == WORK.HOST_COMPONENT or node.tag == WORK.HOST_TEXT then
      commit_nested_unmounts(root, host, node)
      if is_container then
        host.remove_child_from_container(parent, node.state_node)
      else
        host.remove_child(parent, node.state_node)
      end
    elseif node.tag == WORK.HOST_PORTAL then
      if node.child ~= nil then
        -- the children of a portal live in the portal container
        parent = node.state_node.container_info
        is_container = true
        node.child.parent = node
        node = node.child
        descended = true
      end
    else
      commit_unmount(root, host, node)
      if node.child ~= nil then
        node.child.parent = node
        node = node.child
        descended = true
      end
    end

    if not descended then
      if node == current then
        return
      end
      while node.sibling == nil do
        if node.parent == nil or node.parent == current then
          return
        end
        node = node.parent
        if node.tag == WORK.HOST_PORTAL then
          -- back out of a portal: find the host parent again
          parent_found = false
        end
      end
      node.sibling.parent = node.parent
      node = node.sibling
    end
  end
end

local function commit_deletion(root, host, current)
  -- detach the subtree even if unmounting fails
  local deletions = root.deletions
  deletions[#deletions + 1] = current
  deletion_ancestor = current.parent
  local ok, err = pcall(unmount_host_components, root, host, current)
  deletion_ancestor = nil
  if not ok then
    error(err, 0)
  end
end

local function detach_fiber(fiber)
  fiber.parent = nil
  fiber.child = nil
  fiber.sibling = nil
  fiber.alternate = nil
  fiber.state_node = nil
  fiber.memoized_state = nil
  fiber.memoized_props = nil
  fiber.pending_props = nil
  fiber.update_queue = nil
  fiber.dependencies = nil
  fiber.ref = nil
  fiber.ref_cleanup = nil
  fiber.next_effect = nil
  fiber.first_effect = nil
  fiber.last_effect = nil
end

-- Breaks the links of a deleted subtree so it can be garbage collected, and
-- so that updates dispatched to it later cannot reach the root.
local function detach_deleted_subtree(fiber)
  local stack = { fiber }
  while #stack > 0 do
    local node = stack[#stack]
    stack[#stack] = nil
    local child = node.child
    while child ~= nil do
      stack[#stack + 1] = child
      child = child.sibling
    end
    local alternate = node.alternate
    detach_fiber(node)
    if alternate ~= nil then
      detach_fiber(alternate)
    end
  end
end

-- Mutation phase

local function commit_work(host, current, finished_work)
  local tag = finished_work.tag
  if is_function_component(finished_work) then
    commit_hook_effects_unmount(HAS_INSERTION, finished_work)
    commit_hook_effects_mount(HAS_INSERTION, finished_work)
    commit_hook_effects_unmount(HAS_LAYOUT, finished_work)
  elseif tag == WORK.HOST_COMPONENT then
    local payload = finished_work.update_queue
    finished_work.update_queue = nil
    local instance = finished_work.state_node
    if payload ~= nil and instance ~= nil and current ~= nil then
      host.commit_update(
        instance,
        payload,
        finished_work.type,
        current.memoized_props,
        finished_work.memoized_props
      )
    end
  elseif tag == WORK.HOST_TEXT then
    if current ~= nil then
      host.commit_text_update(
        finished_work.state_node,
        current.memoized_props,
        finished_work.memoized_props
      )
    end
  end
end

local function commit_mutation_effect(root, host, fiber)
  local flags = fiber.effect_tag

  if has_flag(flags, EFFECT.REF) then
    local current = fiber.alternate
    if current ~= nil then
      commit_detach_ref(current)
    end
  end

  if has_flag(flags, EFFECT.DELETION) then
    commit_deletion(root, host, fiber)
    return
  end

  if has_flag(flags, EFFECT.PLACEMENT) then
    commit_placement(host, fiber)
    -- later placements look for siblings without this flag
    fiber.effect_tag = remove_flag(fiber.effect_tag, EFFECT.PLACEMENT)
  end

  if has_flag(flags, EFFECT.UPDATE) then
    commit_work(host, fiber.alternate, fiber)
  end
end

-- Layout phase

local function commit_layout_effect(root, host, fiber)
  local flags = fiber.effect_tag
  local tag = fiber.tag

  if has_flag(flags, EFFECT.UPDATE) then
    if is_function_component(fiber) then
      commit_hook_effects_mount(HAS_LAYOUT, fiber)
    elseif tag == WORK.HOST_COMPONENT and fiber.alternate == nil then
      host.commit_mount(fiber.state_node, fiber.type, fiber.memoized_props)
    end
  end

  if has_flag(flags, EFFECT.CALLBACK) and tag == WORK.ERROR_BOUNDARY then
    local queue = fiber.update_queue
    local captured = queue.captured
    queue.captured = nil
    local on_error = fiber.memoized_props.on_error
    if captured ~= nil and on_error ~= nil then
      for i = 1, #captured do
        on_error(captured[i].error, captured[i].info)
      end
    end
  end

  if has_flag(flags, EFFECT.REF) then
    commit_attach_ref(host, fiber)
  end

  if has_flag(flags, EFFECT.PASSIVE) then
    local effects = root.pending_passive_effects
    effects[#effects + 1] = fiber
  end
end

function M.commit_root(root, finished_work)
  local host = root.host

  -- the root fiber goes at the end of its own effect list
  local first_effect
  if finished_work.effect_tag > EFFECT.PERFORMED_WORK then
    if finished_work.last_effect ~= nil then
      finished_work.last_effect.next_effect = finished_work
      first_effect = finished_work.first_effect
    else
      first_effect = finished_work
    end
  else
    first_effect = finished_work.first_effect
  end

  root.is_committing = true
  local ok, err = pcall(host.prepare_for_commit, root.container_info)
  if not ok then
    capture_commit_phase_error(finished_work, err, finished_work)
  end

  local effect = first_effect
  while effect ~= nil do
    ok, err = pcall(commit_mutation_effect, root, host, effect)
    if not ok then
      capture_commit_phase_error(effect, err)
    end
    effect = effect.next_effect
  end

  -- the work-in-progress tree is now the current tree
  root.current = finished_work

  ok, err = pcall(host.reset_after_commit, root.container_info)
  if not ok then
    capture_commit_phase_error(finished_work, err, finished_work)
  end

  effect = first_effect
  while effect ~= nil do
    local next_effect = effect.next_effect
    if not has_flag(effect.effect_tag, EFFECT.DELETION) then
      ok, err = pcall(commit_layout_effect, root, host, effect)
      if not ok then
        capture_commit_phase_error(effect, err)
      end
    end
    -- drop the link so the fibers can be collected
    effect.next_effect = nil
    effect = next_effect
  end

  finished_work.first_effect = nil
  finished_work.last_effect = nil

  local deletions = root.deletions
  for i = 1, #deletions do
    detach_deleted_subtree(deletions[i])
    deletions[i] = nil
  end

  root.is_committing = false
  raise_unhandled_error()
end

function M.has_pending_passive_effects(root)
  return #root.pending_passive_effects > 0 or #root.pending_passive_unmounts > 0
end

-- Runs the passive effects of the last commit: first every cleanup, then
-- every effect. Returns true if there was anything to run.
function M.flush_passive_effects(root)
  local unmounts = root.pending_passive_unmounts
  local fibers = root.pending_passive_effects
  if #unmounts == 0 and #fibers == 0 then
    return false
  end
  root.pending_passive_unmounts = {}
  root.pending_passive_effects = {}

  for i = 1, #unmounts do
    local unmount = unmounts[i]
    call_destroy(unmount.fiber, unmount.destroy, unmount.ancestor)
  end
  for i = 1, #fibers do
    commit_hook_effects_unmount(HAS_PASSIVE, fibers[i])
  end
  for i = 1, #fibers do
    commit_hook_effects_mount(HAS_PASSIVE, fibers[i])
  end
  raise_unhandled_error()
  return true
end

return M
