-- Hooks.
--
-- A function component keeps its hooks in a linked list stored in
-- `fiber.memoized_state`. Each render walks the list of the current fiber in
-- call order and builds a new list for the work-in-progress fiber. Update
-- queues are shared between both copies of a hook, so updates dispatched
-- while a render is in progress are not lost.
--
-- Effects are collected in `fiber.update_queue.effects` and run by the commit
-- phase.

local tags = require "luact.reconciler.tags"
local utils = require "luact.utils"
local render_state = require "luact.reconciler.render_state"
local schedule = require "luact.reconciler.schedule"
local context_module = require "luact.reconciler.context"

local EFFECT = tags.effect
local HOOK = tags.hook
local add_flag = tags.add
local remove_flag = tags.remove

local object_is = utils.object_is
local shallow_equal = utils.shallow_equal

local RE_RENDER_LIMIT = 25

local M = {}

-- The fiber being rendered, and its current counterpart.
local rendering_fiber = nil
local current_fiber = nil
-- Last hook visited in the current list, and last hook of the new list.
local current_hook = nil
local wip_hook = nil
-- Set when a component updates its own state while rendering.
local did_schedule_render_phase_update = false
local is_rerender = false

local function invalid_hook_call(level)
  error(
    "Invalid hook call. Hooks can only be called inside the body of a function "
      .. "component, and in the same order on every render.",
    level + 1
  )
end

-- Moves to the next hook, cloning it from the current fiber or creating it.
-- Returns the work-in-progress hook and the matching current hook (nil on
-- mount).
local function next_hook(kind)
  if rendering_fiber == nil then
    invalid_hook_call(3)
  end

  local next_current = nil
  if current_fiber ~= nil and current_fiber.memoized_state ~= nil then
    if current_hook == nil then
      next_current = current_fiber.memoized_state
    else
      next_current = current_hook.next
    end
  end

  local hook = nil
  if is_rerender then
    -- reuse the hooks built by the previous pass of this render
    if wip_hook == nil then
      hook = rendering_fiber.memoized_state
    else
      hook = wip_hook.next
    end
  end

  if hook == nil then
    if next_current ~= nil then
      hook = {
        kind = next_current.kind,
        memoized_state = next_current.memoized_state,
        queue = next_current.queue,
        next = nil,
      }
    elseif current_fiber ~= nil and current_fiber.memoized_state ~= nil then
      error("Rendered more hooks than during the previous render.", 3)
    else
      hook = { kind = kind, next = nil }
    end

    if wip_hook == nil then
      rendering_fiber.memoized_state = hook
    else
      wip_hook.next = hook
    end
  end

  if hook.kind ~= kind then
    error(
      "Hook order changed: expected " .. hook.kind .. " but got " .. kind
        .. ". Hooks must be called in the same order on every render.",
      3
    )
  end

  current_hook = next_current
  wip_hook = hook
  return hook, next_current
end

local function reset_cursors()
  current_hook = nil
  wip_hook = nil
end

-- Renders a function component. Handles updates that the component
-- dispatches to itself during render by rendering it again.
function M.render_with_hooks(current, wip, component, props)
  rendering_fiber = wip
  current_fiber = current
  reset_cursors()
  did_schedule_render_phase_update = false
  is_rerender = false

  wip.memoized_state = nil
  wip.update_queue = nil

  local children = component(props)

  local passes = 0
  while did_schedule_render_phase_update do
    did_schedule_render_phase_update = false
    passes = passes + 1
    if passes >= RE_RENDER_LIMIT then
      error(
        "Too many re-renders. A component updates its own state on every "
          .. "render, which causes an infinite loop.",
        0
      )
    end
    is_rerender = true
    reset_cursors()
    wip.update_queue = nil
    children = component(props)
  end

  local missing = false
  if current_fiber ~= nil and current_fiber.memoized_state ~= nil then
    if current_hook == nil or current_hook.next ~= nil then
      missing = true
    end
  end

  rendering_fiber = nil
  current_fiber = nil
  is_rerender = false
  reset_cursors()

  if missing then
    error("Rendered fewer hooks than expected. This may be caused by an early return.", 0)
  end

  return children
end

-- Called when a component rendered but nothing changed. Keeps the effects of
-- the current fiber so they are not run again.
function M.bailout_hooks(current, wip)
  wip.update_queue = current.update_queue
  wip.effect_tag = remove_flag(remove_flag(wip.effect_tag, EFFECT.PASSIVE), EFFECT.UPDATE)
  current.pending_work = false
end

-- Clears the render state after a component throws.
function M.reset_after_throw()
  rendering_fiber = nil
  current_fiber = nil
  did_schedule_render_phase_update = false
  is_rerender = false
  reset_cursors()
end

function M.get_rendering_fiber()
  return rendering_fiber
end

-- State and reducer

local function append_update(queue, update)
  local last = queue.last
  if last == nil then
    queue.first = update
  else
    last.next = update
  end
  queue.last = update
end

local function dispatch_action(fiber, queue, action)
  local update = { action = action, next = nil }
  local alternate = fiber.alternate

  if fiber == rendering_fiber or (alternate ~= nil and alternate == rendering_fiber) then
    -- The component updated itself during render. Render it again right
    -- away instead of scheduling.
    did_schedule_render_phase_update = true
    append_update(queue, update)
    return
  end

  if not fiber.pending_work and (alternate == nil or not alternate.pending_work) then
    -- The queue is empty, so the next state can be computed now. If it is
    -- the same as the current state, there is no need to render.
    local reducer = queue.last_rendered_reducer
    if reducer ~= nil then
      local ok, eager_state = pcall(reducer, queue.last_rendered_state, action)
      if ok then
        update.eager_reducer = reducer
        update.eager_state = eager_state
        if object_is(eager_state, queue.last_rendered_state) then
          append_update(queue, update)
          return
        end
      end
    end
  end

  append_update(queue, update)
  schedule.schedule_update_on_fiber(fiber)
end

local function basic_state_reducer(state, action)
  if type(action) == "function" then
    return action(state)
  end
  return action
end

local function use_reducer_impl(kind, reducer, initial_arg, init)
  local hook = next_hook(kind)
  local queue = hook.queue

  if queue == nil then
    local initial_state
    if init ~= nil then
      initial_state = init(initial_arg)
    else
      initial_state = initial_arg
    end
    hook.memoized_state = initial_state
    queue = {
      first = nil,
      last = nil,
      last_rendered_reducer = reducer,
      last_rendered_state = initial_state,
      dispatch = nil,
    }
    local fiber = rendering_fiber
    queue.dispatch = function (action)
      dispatch_action(fiber, queue, action)
    end
    hook.queue = queue
  end

  local state = hook.memoized_state
  local update = queue.first
  queue.first = nil
  queue.last = nil
  while update ~= nil do
    if update.eager_reducer == reducer then
      state = update.eager_state
    else
      state = reducer(state, update.action)
    end
    update = update.next
  end

  if not object_is(state, hook.memoized_state) then
    render_state.did_receive_update = true
  end

  hook.memoized_state = state
  queue.last_rendered_reducer = reducer
  queue.last_rendered_state = state

  return state, queue.dispatch
end

-- Returns the current state and a function to update it. The setter accepts
-- a value or a function that receives the previous state.
function M.use_state(initial_state)
  if type(initial_state) == "function" then
    -- lazy initial state
    return use_reducer_impl("state", basic_state_reducer, nil, initial_state)
  end
  return use_reducer_impl("state", basic_state_reducer, initial_state, nil)
end

-- Like use_state, with the next state computed by `reducer(state, action)`.
-- `init(initial_arg)` computes the initial state when given.
function M.use_reducer(reducer, initial_arg, init)
  return use_reducer_impl("reducer", reducer, initial_arg, init)
end

-- Effects

local function push_effect(tag, create, inst, deps)
  local effect = {
    tag = tag,
    create = create,
    inst = inst,
    deps = deps,
  }
  local queue = rendering_fiber.update_queue
  if queue == nil then
    queue = { effects = {} }
    rendering_fiber.update_queue = queue
  end
  local effects = queue.effects
  effects[#effects + 1] = effect
  return effect
end

local function use_effect_impl(kind, fiber_flag, hook_flag, create, deps)
  local hook, current = next_hook(kind)

  if current ~= nil then
    local prev_effect = current.memoized_state
    local inst = prev_effect.inst
    if deps ~= nil and prev_effect.deps ~= nil and shallow_equal(deps, prev_effect.deps) then
      hook.memoized_state = push_effect(hook_flag, create, inst, deps)
      return
    end
    rendering_fiber.effect_tag = add_flag(rendering_fiber.effect_tag, fiber_flag)
    hook.memoized_state = push_effect(HOOK.HAS_EFFECT + hook_flag, create, inst, deps)
    return
  end

  -- mount, or a re-render pass of a mount: reuse the instance if the
  -- previous pass created one
  local inst
  if hook.memoized_state ~= nil then
    inst = hook.memoized_state.inst
  else
    inst = { destroy = nil }
  end
  rendering_fiber.effect_tag = add_flag(rendering_fiber.effect_tag, fiber_flag)
  hook.memoized_state = push_effect(HOOK.HAS_EFFECT + hook_flag, create, inst, deps)
end

-- Runs `create` after the commit, once the host tree is updated. `create`
-- may return a cleanup function. The effect runs again when a value in
-- `deps` changes, or after every render when `deps` is nil.
function M.use_effect(create, deps)
  use_effect_impl("effect", EFFECT.PASSIVE, HOOK.PASSIVE, create, deps)
end

-- Like use_effect, but runs synchronously right after the host tree is
-- updated, before the frame is drawn.
function M.use_layout_effect(create, deps)
  use_effect_impl("layout_effect", EFFECT.UPDATE, HOOK.LAYOUT, create, deps)
end

-- Like use_layout_effect, but runs before the host tree is updated.
function M.use_insertion_effect(create, deps)
  use_effect_impl("insertion_effect", EFFECT.UPDATE, HOOK.INSERTION, create, deps)
end

-- Memoization

function M.use_memo(create, deps)
  local hook = next_hook("memo")
  local prev = hook.memoized_state
  if prev ~= nil and deps ~= nil and prev.deps ~= nil and shallow_equal(deps, prev.deps) then
    return prev.value
  end
  local value = create()
  hook.memoized_state = { value = value, deps = deps }
  return value
end

function M.use_callback(callback, deps)
  local hook = next_hook("callback")
  local prev = hook.memoized_state
  if prev ~= nil and deps ~= nil and prev.deps ~= nil and shallow_equal(deps, prev.deps) then
    return prev.value
  end
  hook.memoized_state = { value = callback, deps = deps }
  return callback
end

-- Returns a table `{ current = initial_value }` that stays the same for the
-- lifetime of the component.
function M.use_ref(initial_value)
  local hook = next_hook("ref")
  local ref = hook.memoized_state
  if ref == nil then
    ref = { current = initial_value }
    hook.memoized_state = ref
  end
  return ref
end

function M.use_context(context)
  if rendering_fiber == nil then
    invalid_hook_call(2)
  end
  return context_module.read_context(rendering_fiber, context)
end

-- Sets `ref` to the value returned by `create`. `ref` can be a ref table or
-- a callback.
function M.use_imperative_handle(ref, create, deps)
  local effect_deps = nil
  if deps ~= nil then
    effect_deps = {}
    for k, v in pairs(deps) do
      effect_deps[k] = v
    end
    effect_deps.ref = ref
  end
  use_effect_impl("imperative_handle", EFFECT.UPDATE, HOOK.LAYOUT, function ()
    if type(ref) == "function" then
      ref(create())
      return function ()
        ref(nil)
      end
    elseif ref ~= nil then
      ref.current = create()
      return function ()
        ref.current = nil
      end
    end
  end, effect_deps)
end

function M.use_debug_value()
end

local id_counter = 0

-- Returns a unique string that stays the same for the lifetime of the
-- component.
function M.use_id()
  local hook = next_hook("id")
  local id = hook.memoized_state
  if id == nil then
    id_counter = id_counter + 1
    id = "luact-" .. id_counter
    hook.memoized_state = id
  end
  return id
end

local function force_reducer(count)
  return count + 1
end

-- Reads a value from an external store and re-renders when it changes.
--   subscribe(on_change): starts listening and returns an unsubscribe function.
--   get_snapshot(): returns the current value. It must return the same value
--     while the store did not change.
function M.use_sync_external_store(subscribe, get_snapshot)
  local value = get_snapshot()
  local _, force_update = M.use_reducer(force_reducer, 0)
  local inst = M.use_ref(nil)
  if inst.current == nil then
    inst.current = { value = value, get_snapshot = get_snapshot }
  end
  local store = inst.current

  local function check_for_update()
    local ok, next_value = pcall(store.get_snapshot)
    if not ok or not object_is(store.value, next_value) then
      force_update()
    end
  end

  M.use_layout_effect(function ()
    store.value = value
    store.get_snapshot = get_snapshot
    check_for_update()
  end, { subscribe, value, get_snapshot })

  M.use_effect(function ()
    check_for_update()
    return subscribe(check_for_update)
  end, { subscribe })

  return value
end

return M
