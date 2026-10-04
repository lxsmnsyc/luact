-- Fiber creation.
--
-- A fiber is the unit of work of the reconciler. Each mounted component has
-- up to two fibers: `current`, which matches what is on screen, and its
-- `alternate`, the work-in-progress copy used while rendering. After a commit
-- the two swap roles, so fibers are reused between renders.
--
-- `parent` is React's `return` pointer, which is a reserved word in Lua.

local symbols = require "luact.symbols"
local tags = require "luact.reconciler.tags"

local WORK = tags.work
local NO_EFFECT = tags.effect.NO_EFFECT

local M = {}

local function create_fiber(tag, pending_props, key)
  return {
    tag = tag,
    key = key,
    -- the element type as written by the user
    element_type = nil,
    -- the resolved type (same as element_type, kept separate like React)
    type = nil,
    -- host instance, root, portal container or boundary instance
    state_node = nil,

    parent = nil,
    child = nil,
    sibling = nil,
    index = 1,

    ref = nil,
    -- cleanup returned by a callback ref
    ref_cleanup = nil,

    pending_props = pending_props,
    memoized_props = nil,
    -- hook effects, host update payload or root/boundary update queue
    update_queue = nil,
    -- hook list, root state or boundary state
    memoized_state = nil,
    -- contexts read during the last render
    dependencies = nil,

    effect_tag = NO_EFFECT,
    next_effect = nil,
    first_effect = nil,
    last_effect = nil,

    -- true when this fiber has an update to process
    pending_work = false,
    -- true when some fiber in the subtree has an update to process
    child_pending_work = false,

    alternate = nil,
  }
end

M.create_fiber = create_fiber

-- Creates or reuses the alternate of `current` to hold new work.
function M.create_work_in_progress(current, pending_props)
  local wip = current.alternate
  if wip == nil then
    wip = create_fiber(current.tag, pending_props, current.key)
    wip.element_type = current.element_type
    wip.type = current.type
    wip.state_node = current.state_node

    wip.alternate = current
    current.alternate = wip
  else
    wip.pending_props = pending_props
    wip.effect_tag = NO_EFFECT
    wip.next_effect = nil
    wip.first_effect = nil
    wip.last_effect = nil
  end

  wip.pending_work = current.pending_work
  wip.child_pending_work = current.child_pending_work

  wip.child = current.child
  wip.memoized_props = current.memoized_props
  wip.memoized_state = current.memoized_state
  wip.update_queue = current.update_queue
  wip.dependencies = current.dependencies

  wip.sibling = current.sibling
  wip.index = current.index
  wip.ref = current.ref
  wip.ref_cleanup = current.ref_cleanup

  return wip
end

function M.create_host_root_fiber(root)
  local fiber = create_fiber(WORK.HOST_ROOT, nil, nil)
  fiber.state_node = root
  fiber.memoized_state = { element = nil }
  fiber.update_queue = { first = nil, last = nil }
  return fiber
end

local function tag_from_type(element_type)
  local kind = type(element_type)
  if kind == "string" then
    return WORK.HOST_COMPONENT
  end
  if kind == "function" then
    return WORK.FUNCTION_COMPONENT
  end
  if element_type == symbols.ERROR_BOUNDARY then
    return WORK.ERROR_BOUNDARY
  end
  if kind == "table" then
    local typeof = element_type["$$typeof"]
    if typeof == symbols.CONTEXT then
      return WORK.CONTEXT_PROVIDER
    end
    if typeof == symbols.CONSUMER then
      return WORK.CONTEXT_CONSUMER
    end
    if typeof == symbols.MEMO then
      return WORK.MEMO_COMPONENT
    end
  end
  error(
    "Element type is invalid: expected a string (for host components) or a "
      .. "function (for components) but got: " .. tostring(element_type),
    0
  )
end

function M.create_fiber_from_element(element)
  local element_type = element.type
  local fiber = create_fiber(tag_from_type(element_type), element.props, element.key)
  fiber.element_type = element_type
  fiber.type = element_type
  return fiber
end

-- A fragment fiber holds its children directly as pending props.
function M.create_fiber_from_fragment(children, key)
  local fiber = create_fiber(WORK.FRAGMENT, children, key)
  fiber.element_type = symbols.FRAGMENT
  fiber.type = symbols.FRAGMENT
  return fiber
end

function M.create_fiber_from_text(text)
  return create_fiber(WORK.HOST_TEXT, text, nil)
end

function M.create_fiber_from_portal(portal)
  local fiber = create_fiber(WORK.HOST_PORTAL, portal.children, portal.key)
  fiber.state_node = {
    container_info = portal.container_info,
  }
  return fiber
end

return M
