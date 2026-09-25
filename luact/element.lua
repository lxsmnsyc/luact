-- Element creation and the special component types.

local symbols = require "luact.symbols"

local ELEMENT = symbols.ELEMENT

local M = {}

M.Fragment = symbols.FRAGMENT
M.ErrorBoundary = symbols.ERROR_BOUNDARY

-- Packs varargs into a children value. A single child stays as is. Several
-- children become an array where nil holes are replaced by false, so the
-- position of every child is kept.
local function pack_children(...)
  local count = select("#", ...)
  if count == 0 then
    return nil, false
  end
  if count == 1 then
    return (...), true
  end
  local children = {}
  for i = 1, count do
    local child = select(i, ...)
    if child == nil then
      child = false
    end
    children[i] = child
  end
  return children, true
end

local function make_element(element_type, key, props)
  local element = {
    type = element_type,
    key = key,
    ref = props.ref,
    props = props,
  }
  element["$$typeof"] = ELEMENT
  return element
end

-- Creates an element.
--   element_type: a host type (string), a function component, Fragment,
--     ErrorBoundary, a memo component, a context or a context consumer.
--   config: the props table. `key` is taken out of it. It is not modified.
--   ...: optional children. They override `config.children`.
function M.create_element(element_type, config, ...)
  if element_type == nil then
    error("create_element: element type is nil. Did you forget to require a component?", 2)
  end

  local props = {}
  local key
  if config ~= nil then
    for k, v in pairs(config) do
      if k == "key" then
        key = v
      else
        props[k] = v
      end
    end
  end
  if key ~= nil then
    key = tostring(key)
  end

  local children, has_children = pack_children(...)
  if has_children then
    props.children = children
  end

  return make_element(element_type, key, props)
end

-- Copies an element, merging `config` into its props. `key` in `config`
-- replaces the key, and extra arguments replace the children.
function M.clone_element(element, config, ...)
  if not M.is_valid_element(element) then
    error("clone_element: argument is not an element", 2)
  end

  local props = {}
  for k, v in pairs(element.props) do
    props[k] = v
  end
  local key = element.key
  if config ~= nil then
    for k, v in pairs(config) do
      if k == "key" then
        key = tostring(v)
      else
        props[k] = v
      end
    end
  end

  local children, has_children = pack_children(...)
  if has_children then
    props.children = children
  end

  return make_element(element.type, key, props)
end

function M.is_valid_element(value)
  return type(value) == "table" and value["$$typeof"] == ELEMENT
end

-- Renders `children` into `container`, a host container outside of the
-- parent's host tree. Context and error boundaries still work through
-- portals.
function M.create_portal(children, container, key)
  if container == nil then
    error("create_portal: container is nil", 2)
  end
  local portal = {
    key = key ~= nil and tostring(key) or nil,
    children = children,
    container_info = container,
  }
  portal["$$typeof"] = symbols.PORTAL
  return portal
end

-- Wraps a function component so it skips rendering when its props did not
-- change. `compare(old_props, new_props)` returns true when the props are
-- equal. The default compare is a shallow comparison.
function M.memo(component, compare)
  if type(component) ~= "function" then
    error("memo: expected a function component, got " .. type(component), 2)
  end
  local memo_type = {
    type = component,
    compare = compare,
  }
  memo_type["$$typeof"] = symbols.MEMO
  return memo_type
end

-- Creates a context. The context itself is a provider type:
-- `create_element(Context, { value = v }, ...)`. `Context.Provider` is the
-- same object. `Context.Consumer` takes a function as its only child.
function M.create_context(default_value)
  local context = {
    default_value = default_value,
  }
  context["$$typeof"] = symbols.CONTEXT
  context.Provider = context

  local consumer = { context = context }
  consumer["$$typeof"] = symbols.CONSUMER
  context.Consumer = consumer

  return context
end

function M.create_ref(initial_value)
  return { current = initial_value }
end

-- Helpers for working with the opaque `props.children` value.
local children = {}
M.children = children

local function is_array(value)
  return type(value) == "table" and value["$$typeof"] == nil
end

local function flatten(value, result)
  if value == nil or type(value) == "boolean" then
    return result
  end
  if is_array(value) then
    local count = #value
    for i = 1, count do
      flatten(value[i], result)
    end
    return result
  end
  result[#result + 1] = value
  return result
end

-- Flattens nested arrays and drops nil, true and false.
function children.to_array(value)
  return flatten(value, {})
end

function children.count(value)
  return #flatten(value, {})
end

function children.map(value, fn)
  local items = flatten(value, {})
  local result = {}
  for i = 1, #items do
    local mapped = fn(items[i], i)
    if mapped == nil then
      mapped = false
    end
    result[i] = mapped
  end
  return result
end

function children.for_each(value, fn)
  local items = flatten(value, {})
  for i = 1, #items do
    fn(items[i], i)
  end
end

-- Returns the only child, or raises an error when there is not exactly one
-- element.
function children.only(value)
  if not M.is_valid_element(value) then
    error("children.only: expected a single element", 2)
  end
  return value
end

return M
