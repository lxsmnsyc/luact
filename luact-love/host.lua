-- Host config for LÖVE. Host nodes form a retained tree that `draw` walks
-- every frame.
--
-- Nodes are tables: `{ type, props, children, parent }`. Text instances are
-- `{ text, parent }` and only make sense inside a "text" node.

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

local function append_child(parent, child)
  detach(parent, child)
  parent.children[#parent.children + 1] = child
  child.parent = parent
end

return {
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

  append_child = append_child,

  insert_before = function (parent, child, before)
    detach(parent, child)
    local index = index_of(parent.children, before) or (#parent.children + 1)
    table.insert(parent.children, index, child)
    child.parent = parent
  end,

  remove_child = function (parent, child)
    detach(parent, child)
    child.parent = nil
  end,

  commit_update = function (instance, _, _, _, new_props)
    instance.props = copy_props(new_props)
  end,

  commit_text_update = function (text_instance, _, new_text)
    text_instance.text = new_text
  end,
}
