-- Luact + LÖVE demo: an animated grid of boxes.
--
-- Run from the repository root:
--   love examples/love
--
-- Space pauses the animation, up and down change the grid size.

-- load luact from the repository root (works when running the folder,
-- not a packaged .love file)
local source = love.filesystem.getSource()
package.path = source .. "/../../?.lua;" .. source .. "/../../?/init.lua;" .. package.path

local luact = require "luact"
local luact_love = require "luact-love"
local frame = require("luact.timers").frame

local h = luact.create_element

local Time = luact.create_context(0)

-- A box whose color follows the shared time. It is memoized, so only the
-- context change makes it render again.
local Box = luact.memo(function (props)
  local time = luact.use_context(Time)
  local wave = (math.sin(time * 2 + props.x * 0.3 + props.y * 0.2) + 1) / 2
  return h("rectangle", {
    x = props.x * 12,
    y = props.y * 12,
    width = 10,
    height = 10,
    color = { wave, props.x / props.size, props.y / props.size },
  })
end)

local Grid = luact.memo(function (props)
  local boxes = {}
  for x = 1, props.size do
    for y = 1, props.size do
      boxes[#boxes + 1] = h(Box, { key = x .. ":" .. y, x = x, y = y, size = props.size })
    end
  end
  return h("group", { x = 40, y = 60 }, boxes)
end)

-- Advances the time on every frame while `running` is true.
local function use_clock(running)
  local time, set_time = luact.use_state(0)
  luact.use_effect(function ()
    if not running then
      return nil
    end
    local id
    local function tick(dt)
      set_time(function (current)
        return current + dt / 1000
      end)
      id = frame.request(tick)
    end
    id = frame.request(tick)
    return function ()
      frame.clear(id)
    end
  end, { running })
  return time
end

local function App()
  local running, set_running = luact.use_state(true)
  local size, set_size = luact.use_state(16)
  local time = use_clock(running)

  luact_love.use_event("keypressed", function (key)
    if key == "space" then
      set_running(function (value)
        return not value
      end)
    elseif key == "up" then
      set_size(function (value)
        return math.min(value + 2, 40)
      end)
    elseif key == "down" then
      set_size(function (value)
        return math.max(value - 2, 2)
      end)
    end
  end)

  local status = running and "running" or "paused"
  return h(luact.Fragment, nil,
    h("text", { x = 40, y = 20 }, "Luact demo: ", size * size, " boxes, ", status,
      " (space, up, down)"),
    h(Time, { value = time }, h(Grid, { size = size }))
  )
end

function love.load()
  luact_love.install(h(App))
end
