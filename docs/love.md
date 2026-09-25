# LÖVE renderer

`luact-love` renders Luact elements with LÖVE 11.

```lua
local luact = require "luact"
local luact_love = require "luact-love"
local h = luact.create_element

local function App()
  return h("group", { x = 100, y = 100 },
    h("rectangle", { width = 50, height = 50, color = { 1, 0, 0 } }),
    h("text", { y = 60 }, "Hello")
  )
end

function love.load()
  luact_love.install(h(App))
end
```

`install` sets `love.update`, `love.draw` and the input callbacks. To keep your own callbacks, call these instead:

- `luact_love.render(element)` renders into the stage.
- `luact_love.update(dt)` advances `luact.timers` and renders pending updates. It spends at most `luact_love.frame_budget` milliseconds (8 by default).
- `luact_love.draw()` draws the stage.
- `luact_love.emit(name, ...)` sends a LÖVE event to `use_event` handlers.

## Host components

Colors are tables `{ r, g, b, a }` with values from 0 to 1. A color applies to the node, then the previous color is restored.

- `group` moves, rotates and scales its children. Props: `x`, `y`, `rotation`, `sx`, `sy`, `color`.
- `rectangle` props: `mode` (`"fill"` or `"line"`), `x`, `y`, `width`, `height`, `rx`, `ry`, `color`.
- `circle` props: `mode`, `x`, `y`, `radius`, `segments`, `color`.
- `text` draws its string children. Props: `x`, `y`, `font`, `limit`, `align`, `color`. With `limit`, it uses `love.graphics.printf`.
- `image` draws a Drawable. Props: `image`, `x`, `y`, `rotation`, `sx`, `sy`, `ox`, `oy`, `color`.
- `draw` calls `props.draw(node)`, then draws its children.

Add a type by adding a painter:

```lua
luact_love.painters.polygon = function (node, draw_children)
  love.graphics.polygon(node.props.mode or "fill", node.props.points)
  draw_children(node)
end
```

## Events

`use_event(name, handler)` calls `handler` for each LÖVE event `name` while the component is mounted.

```lua
local function Player()
  local x, set_x = luact.use_state(0)
  luact_love.use_event("keypressed", function (key)
    if key == "right" then set_x(x + 10) end
  end)
  return h("rectangle", { x = x, width = 10, height = 10 })
end
```

The `"update"` event receives `dt` every frame.
