# Getting started

This guide renders a small app with the in-memory test renderer. The same code works with any renderer.

## Elements

An element describes what to show. Create one with `create_element(type, props, ...children)`.

```lua
local luact = require "luact"
local h = luact.create_element

local element = h("box", { id = "main" },
  h("label", nil, "Hello"),
  h("label", nil, "World")
)
```

- A string type is a host component. The renderer decides what it means.
- A function type is a function component.
- Children can be elements, strings, numbers, arrays of children, `nil` or booleans. `nil`, `true` and `false` render nothing.
- In arrays, use `false` for an empty slot. Lua arrays cannot hold `nil` in the middle.

## Components

A function component takes props and returns children.

```lua
local function Greeting(props)
  return h("label", nil, "Hello, ", props.name)
end

local element = h(Greeting, { name = "Lua" })
```

Children passed to `create_element` arrive in `props.children`.

## State and effects

Hooks give a component state and side effects. Call them at the top of the component, in the same order on every render.

```lua
local function Timer()
  local seconds, set_seconds = luact.use_state(0)

  luact.use_effect(function ()
    local id = start_interval(function ()
      set_seconds(function (s) return s + 1 end)
    end, 1000)
    -- the returned function runs on unmount
    return function () stop_interval(id) end
  end, {})

  return h("label", nil, seconds, " seconds")
end
```

See the [API reference](api.md) for every hook.

## Rendering

A renderer turns elements into host nodes. Create a root on a container and render into it.

```lua
local test_renderer = require "luact.test_renderer"

local renderer = test_renderer.renderer
local container = test_renderer.create_container()
local root = renderer.create_root(container)

root:render(h(Greeting, { name = "Lua" }))
```

`root:render` only schedules the work. The host runs it with the work loop, usually once per frame:

```lua
-- Render for at most 8 milliseconds this frame.
local start = os.clock()
renderer.work_loop(function ()
  return 8 - (os.clock() - start) * 1000
end)
```

- Call `renderer.work_loop()` with no deadline to finish all work.
- Call `renderer.flush_sync(fn)` to run `fn` and render its updates right away.
- Call `root:unmount()` to remove the tree and run every cleanup.

## Lists and keys

Give each item in a list a `key`. Luact uses keys to keep state and host nodes with the right item when the list changes.

```lua
local function TodoList(props)
  local items = {}
  for i, todo in ipairs(props.todos) do
    items[i] = h("item", { key = todo.id }, todo.title)
  end
  return h("list", nil, items)
end
```

## Testing

`luact.test_renderer` renders to plain tables and has helpers for tests.

```lua
local instance = test_renderer.create(h(Greeting, { name = "Lua" }))
assert(instance:to_string() == "<label>Hello, Lua</label>")

test_renderer.act(function ()
  -- dispatch updates here
end)
```

`act` runs the function, then renders and runs effects until nothing is left.

## Next steps

- [LÖVE renderer](love.md) to draw with LÖVE.
- [Writing a renderer](renderers.md) to target another host.
