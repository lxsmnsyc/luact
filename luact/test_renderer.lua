-- An in-memory renderer for tests and examples.
--
-- Host nodes are plain tables: `{ type, props, children, parent }` for
-- elements and `{ text, parent }` for text. Every host operation is recorded
-- in `operations` so tests can check what the reconciler did.
--
--   local test_renderer = require "luact.test_renderer"
--   local instance = test_renderer.create(create_element(App))
--   print(instance:to_string())

local luact = require "luact"

local M = {}

M.operations = {}

local function log(operation)
  local operations = M.operations
  operations[#operations + 1] = operation
end

function M.clear_operations()
  M.operations = {}
end

local function describe(node)
  if node.text ~= nil then
    return '"' .. node.text .. '"'
  end
  if node.props ~= nil and node.props.id ~= nil then
    return node.type .. "#" .. tostring(node.props.id)
  end
  return tostring(node.type)
end

local function copy_props(props)
  local result = {}
  for k, v in pairs(props) do
    if k ~= "children" then
      result[k] = v
    end
  end
  return result
end

local function index_of(list, value)
  for i = 1, #list do
    if list[i] == value then
      return i
    end
  end
  return nil
end

local function detach(parent, child)
  local index = index_of(parent.children, child)
  if index ~= nil then
    table.remove(parent.children, index)
  end
end

M.host_config = {
  create_instance = function (element_type, props)
    return {
      type = element_type,
      props = copy_props(props),
      children = {},
      parent = nil,
    }
  end,

  create_text_instance = function (text)
    return { text = text, parent = nil }
  end,

  append_initial_child = function (parent, child)
    parent.children[#parent.children + 1] = child
    child.parent = parent
  end,

  append_child = function (parent, child)
    detach(parent, child)
    parent.children[#parent.children + 1] = child
    child.parent = parent
    log("append " .. describe(child) .. " to " .. describe(parent))
  end,

  insert_before = function (parent, child, before)
    detach(parent, child)
    local index = index_of(parent.children, before)
    if index == nil then
      error("insert_before: reference node is not a child of the parent")
    end
    table.insert(parent.children, index, child)
    child.parent = parent
    log("insert " .. describe(child) .. " before " .. describe(before))
  end,

  remove_child = function (parent, child)
    detach(parent, child)
    child.parent = nil
    log("remove " .. describe(child) .. " from " .. describe(parent))
  end,

  -- skip the update when only the children changed
  prepare_update = function (_, _, old_props, new_props)
    for k, v in pairs(old_props) do
      if k ~= "children" and new_props[k] ~= v then
        return true
      end
    end
    for k, v in pairs(new_props) do
      if k ~= "children" and old_props[k] ~= v then
        return true
      end
    end
    return nil
  end,

  commit_update = function (instance, _, _, _, new_props)
    instance.props = copy_props(new_props)
    log("update " .. describe(instance))
  end,

  commit_text_update = function (text_instance, _, new_text)
    text_instance.text = new_text
    log("update text " .. describe(text_instance))
  end,
}

M.renderer = luact.create_renderer(M.host_config)

-- Runs `fn`, then flushes every scheduled render and effect.
M.act = M.renderer.act

local function sorted_keys(props)
  local keys = {}
  for k in pairs(props) do
    keys[#keys + 1] = k
  end
  table.sort(keys, function (a, b)
    return tostring(a) < tostring(b)
  end)
  return keys
end

local function format_value(value)
  local kind = type(value)
  if kind == "string" then
    return '"' .. value .. '"'
  end
  if kind == "number" or kind == "boolean" then
    return tostring(value)
  end
  return "{" .. kind .. "}"
end

-- Serializes a host node, or a list of host nodes, to an XML-like string.
-- Function and table props are shown as `{function}` and `{table}`.
function M.to_string(node)
  if node == nil then
    return ""
  end
  if node.text ~= nil then
    return node.text
  end
  if node.type == nil then
    -- a list of nodes
    local parts = {}
    for i = 1, #node do
      parts[i] = M.to_string(node[i])
    end
    return table.concat(parts)
  end

  local parts = { "<", node.type }
  local props = node.props or {}
  local keys = sorted_keys(props)
  for i = 1, #keys do
    local k = keys[i]
    if k ~= "ref" then
      parts[#parts + 1] = " " .. tostring(k) .. "=" .. format_value(props[k])
    end
  end
  if #node.children == 0 then
    parts[#parts + 1] = " />"
    return table.concat(parts)
  end
  parts[#parts + 1] = ">"
  for i = 1, #node.children do
    parts[#parts + 1] = M.to_string(node.children[i])
  end
  parts[#parts + 1] = "</" .. node.type .. ">"
  return table.concat(parts)
end

local Instance = {}
Instance.__index = Instance

function Instance:update(element)
  M.act(function ()
    self.root:render(element)
  end)
end

function Instance:unmount()
  M.act(function ()
    self.root:unmount()
  end)
end

-- The host nodes at the top of the tree.
function Instance:nodes()
  return self.container.children
end

function Instance:to_string()
  return M.to_string(self.container.children)
end

-- Returns every host node of the given type, in tree order.
function Instance:find_all(element_type)
  local result = {}
  local function visit(node)
    if node.type == element_type then
      result[#result + 1] = node
    end
    if node.children ~= nil then
      for i = 1, #node.children do
        visit(node.children[i])
      end
    end
  end
  for i = 1, #self.container.children do
    visit(self.container.children[i])
  end
  return result
end

function M.create_container()
  return { type = "root", children = {} }
end

-- Creates a root, renders `element` into it inside `act`, and returns an
-- instance with `update`, `unmount`, `to_string` and `find_all`.
function M.create(element)
  local container = M.create_container()
  local instance = setmetatable({
    container = container,
    root = M.renderer.create_root(container),
  }, Instance)
  if element ~= nil then
    instance:update(element)
  end
  return instance
end

return M
