-- The first half of a unit of work: renders a fiber and reconciles its
-- children. Returns the next fiber to work on, or nil when the fiber has no
-- children to visit.

local tags = require "luact.reconciler.tags"
local utils = require "luact.utils"
local child_fiber = require "luact.reconciler.child_fiber"
local context_module = require "luact.reconciler.context"
local hooks = require "luact.reconciler.hooks"
local render_state = require "luact.reconciler.render_state"
local schedule = require "luact.reconciler.schedule"

local WORK = tags.work
local EFFECT = tags.effect
local has_flag = tags.has
local add_flag = tags.add

local reconcile_child_fibers = child_fiber.reconcile_child_fibers
local mount_child_fibers = child_fiber.mount_child_fibers

local function reconcile_children(current, wip, next_children)
  if current == nil then
    wip.child = mount_child_fibers(wip, nil, next_children)
  else
    wip.child = reconcile_child_fibers(wip, current.child, next_children)
  end
end

-- Skips rendering a fiber whose inputs did not change. Its children are
-- still visited if one of them has pending work.
local function bailout_on_already_finished_work(current, wip)
  if current ~= nil then
    wip.dependencies = current.dependencies
  end
  if not wip.child_pending_work then
    -- nothing to do in this subtree
    return nil
  end
  child_fiber.clone_child_fibers(wip)
  return wip.child
end

local function update_function_component(current, wip, component, next_props)
  context_module.prepare_to_read_context(wip)
  local next_children = hooks.render_with_hooks(current, wip, component, next_props)

  if current ~= nil and not render_state.did_receive_update then
    hooks.bailout_hooks(current, wip)
    return bailout_on_already_finished_work(current, wip)
  end

  wip.effect_tag = add_flag(wip.effect_tag, EFFECT.PERFORMED_WORK)
  reconcile_children(current, wip, next_children)
  return wip.child
end

local function update_memo_component(current, wip, has_update)
  local memo_type = wip.type
  local next_props = wip.pending_props
  if current ~= nil and not has_update then
    local compare = memo_type.compare or utils.shallow_equal
    if compare(current.memoized_props, next_props) then
      render_state.did_receive_update = false
      return bailout_on_already_finished_work(current, wip)
    end
  end
  return update_function_component(current, wip, memo_type.type, next_props)
end

local function update_host_root(current, wip)
  local queue = wip.update_queue
  local prev_state = wip.memoized_state
  local state = prev_state

  local update = queue.first
  if update ~= nil then
    queue.first = nil
    queue.last = nil
    state = { element = prev_state.element }
    while update ~= nil do
      if update.kind == "error" then
        -- no error boundary caught the error: unmount everything and rethrow
        -- after the commit
        state.element = nil
        wip.state_node.uncaught_error = update.error
        wip.state_node.has_uncaught_error = true
      else
        state.element = update.element
      end
      update = update.next
    end
    wip.memoized_state = state
  end

  local next_children = state.element
  if current ~= nil and next_children == prev_state.element then
    return bailout_on_already_finished_work(current, wip)
  end
  reconcile_children(current, wip, next_children)
  return wip.child
end

local function update_host_component(current, wip)
  local next_props = wip.pending_props
  local ref = wip.ref
  if (current == nil and ref ~= nil) or (current ~= nil and current.ref ~= ref) then
    wip.effect_tag = add_flag(wip.effect_tag, EFFECT.REF)
  end
  reconcile_children(current, wip, next_props.children)
  return wip.child
end

local function update_portal(current, wip)
  local next_children = wip.pending_props
  if current == nil then
    -- The portal itself is not a host node, so its children must be placed
    -- individually into the portal container.
    wip.child = reconcile_child_fibers(wip, nil, next_children)
  else
    reconcile_children(current, wip, next_children)
  end
  return wip.child
end

local function update_fragment(current, wip)
  reconcile_children(current, wip, wip.pending_props)
  return wip.child
end

local function update_context_provider(current, wip)
  local context = wip.type
  local new_props = wip.pending_props
  local old_props = wip.memoized_props

  if old_props ~= nil then
    if utils.object_is(old_props.value, new_props.value) then
      if old_props.children == new_props.children then
        return bailout_on_already_finished_work(current, wip)
      end
    else
      context_module.propagate_context_change(wip, context)
    end
  end

  reconcile_children(current, wip, new_props.children)
  return wip.child
end

local function update_context_consumer(current, wip)
  local context = wip.type.context
  local render = wip.pending_props.children
  if type(render) ~= "function" then
    error("A context Consumer expects a function as its only child.", 0)
  end

  context_module.prepare_to_read_context(wip)
  local value = context_module.read_context(wip, context)
  local next_children = render(value)

  wip.effect_tag = add_flag(wip.effect_tag, EFFECT.PERFORMED_WORK)
  reconcile_children(current, wip, next_children)
  return wip.child
end

local function create_boundary_instance(wip)
  local instance = { fiber = wip }
  local queue = { first = nil, last = nil, captured = nil }

  function instance.reset()
    local update = { kind = "reset", next = nil }
    if queue.last == nil then
      queue.first = update
    else
      queue.last.next = update
    end
    queue.last = update
    schedule.schedule_update_on_fiber(instance.fiber)
  end

  wip.state_node = instance
  wip.update_queue = queue
  wip.memoized_state = { has_error = false, error = nil }
end

local function update_error_boundary(current, wip)
  if wip.state_node == nil then
    create_boundary_instance(wip)
  end

  local queue = wip.update_queue
  local state = wip.memoized_state

  local update = queue.first
  if update ~= nil then
    queue.first = nil
    queue.last = nil
    state = { has_error = state.has_error, error = state.error }
    while update ~= nil do
      if update.kind == "capture" then
        state.has_error = true
        state.error = update.error
        local captured = queue.captured
        if captured == nil then
          captured = {}
          queue.captured = captured
        end
        captured[#captured + 1] = { error = update.error, info = update.info }
        wip.effect_tag = add_flag(wip.effect_tag, EFFECT.CALLBACK)
      else
        state.has_error = false
        state.error = nil
      end
      update = update.next
    end
    wip.memoized_state = state
  end

  local props = wip.pending_props
  local next_children
  if state.has_error then
    local fallback = props.fallback
    if type(fallback) == "function" then
      next_children = fallback(state.error, wip.state_node.reset)
    else
      next_children = fallback
    end
  else
    next_children = props.children
  end

  if current ~= nil and has_flag(wip.effect_tag, EFFECT.DID_CAPTURE) then
    -- The current children may be broken. Remove all of them and mount the
    -- fallback from scratch instead of trying to reuse fibers.
    wip.child = reconcile_child_fibers(wip, current.child, nil)
    wip.child = reconcile_child_fibers(wip, nil, next_children)
  else
    reconcile_children(current, wip, next_children)
  end
  return wip.child
end

return function (current, wip)
  local has_update = wip.pending_work

  if current ~= nil then
    if current.memoized_props ~= wip.pending_props then
      render_state.did_receive_update = true
    elseif not has_update then
      -- same props and no pending update: nothing to render
      render_state.did_receive_update = false
      return bailout_on_already_finished_work(current, wip)
    else
      render_state.did_receive_update = false
    end
  else
    render_state.did_receive_update = false
  end

  -- every queued update of this fiber gets processed below
  wip.pending_work = false
  if current ~= nil then
    current.pending_work = false
  end

  local tag = wip.tag
  if tag == WORK.FUNCTION_COMPONENT then
    return update_function_component(current, wip, wip.type, wip.pending_props)
  elseif tag == WORK.HOST_COMPONENT then
    return update_host_component(current, wip)
  elseif tag == WORK.HOST_TEXT then
    return nil
  elseif tag == WORK.FRAGMENT then
    return update_fragment(current, wip)
  elseif tag == WORK.MEMO_COMPONENT then
    return update_memo_component(current, wip, has_update)
  elseif tag == WORK.CONTEXT_PROVIDER then
    return update_context_provider(current, wip)
  elseif tag == WORK.CONTEXT_CONSUMER then
    return update_context_consumer(current, wip)
  elseif tag == WORK.ERROR_BOUNDARY then
    return update_error_boundary(current, wip)
  elseif tag == WORK.HOST_PORTAL then
    return update_portal(current, wip)
  elseif tag == WORK.HOST_ROOT then
    return update_host_root(current, wip)
  end
  error("Unknown fiber tag: " .. tostring(tag), 0)
end
