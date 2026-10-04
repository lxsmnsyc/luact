-- Writing a renderer: a host config that turns elements into lines of text.
--
-- Run from the repository root:
--   lua examples/console/custom_renderer.lua

package.path = "./?.lua;./?/init.lua;" .. package.path

local luact = require "luact"

local h = luact.create_element

-- Host nodes. "line" nodes print their text children on one line, "indent"
-- nodes indent their children.
local host_config = {
  create_instance = function (element_type, props)
    return { type = element_type, props = props, children = {} }
  end,

  create_text_instance = function (text)
    return { text = text }
  end,

  append_child = function (parent, child)
    parent.children[#parent.children + 1] = child
  end,

  insert_before = function (parent, child, before)
    for i = 1, #parent.children do
      if parent.children[i] == before then
        table.insert(parent.children, i, child)
        return
      end
    end
  end,

  remove_child = function (parent, child)
    for i = 1, #parent.children do
      if parent.children[i] == child then
        table.remove(parent.children, i)
        return
      end
    end
  end,

  commit_update = function (instance, _, _, _, new_props)
    instance.props = new_props
  end,

  commit_text_update = function (text_instance, _, new_text)
    text_instance.text = new_text
  end,
}

local renderer = luact.create_renderer(host_config)

local function print_tree(node, indent)
  for _, child in ipairs(node.children) do
    if child.type == "line" then
      local parts = {}
      for _, text in ipairs(child.children) do
        parts[#parts + 1] = text.text
      end
      print(indent .. table.concat(parts))
    elseif child.type == "indent" then
      print_tree(child, indent .. "  ")
    end
  end
end

-- Components

local function Task(props)
  local mark = props.done and "[x] " or "[ ] "
  return h("line", nil, mark, props.title)
end

local function Section(props)
  local items = {}
  for i, task in ipairs(props.tasks) do
    items[i] = h(Task, { key = task.title, title = task.title, done = task.done })
  end
  return h(luact.Fragment, nil,
    h("line", nil, props.title, " (", #props.tasks, ")"),
    h("indent", nil, items)
  )
end

-- Rendering

local container = { children = {} }
local root = renderer.create_root(container)

local tasks = {
  { title = "Write the host config", done = true },
  { title = "Render a tree", done = false },
}

local function show(label)
  root:render(h(Section, { title = "Tasks", tasks = tasks }))
  -- run the work loop until everything is rendered
  renderer.flush_sync()
  print("-- " .. label)
  print_tree(container, "")
end

show("first render")

tasks[2] = { title = "Render a tree", done = true }
tasks[3] = { title = "Update it", done = false }
show("after an update")

root:unmount()
