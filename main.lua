local LuactLove = require "luact-love"
local Love = require "luact-love.reconciler"
local Luact = require "luact"
local frame = require "luact.timers.frame"

local Rectangle = require "luact-love.components.rectangle"
local Color = require "luact-love.components.color"
local Translate = require "luact-love.components.translate"

local ColorBox = Love.component(function (props)
  local state, set_state = Luact.use_state(0)

  Luact.use_layout_effect(function ()
    local request

    local function animate(dt)
      set_state(function (current)
        if (current < 1000) then
          return current + dt
        end
        return dt
      end)
      request = frame.request(animate)
    end

    request = frame.request(animate)

    return function ()
      frame.clear(request)
    end
  end, {})

  return Color {
    r = state / 1000,
    g = props.x / 100,
    b = props.y / 100,
    children = {
      Rectangle {
        mode = "fill",
        x = props.x,
        y = props.y,
        width = 10,
        height = 10,
      },
    }
  }
end)

local ColorColumn = Love.basic(function (props)
  return Love.Fragment {
    ColorBox { x = props.x, y = 10 },
    ColorBox { x = props.x, y = 20 },
    ColorBox { x = props.x, y = 30 },
    ColorBox { x = props.x, y = 40 },
    ColorBox { x = props.x, y = 50 },
    ColorBox { x = props.x, y = 60 },
    ColorBox { x = props.x, y = 70 },
    ColorBox { x = props.x, y = 80 },
    ColorBox { x = props.x, y = 90 },
    ColorBox { x = props.x, y = 100 },
  }
end)

local App = Love.basic(function (props)
  return Translate {
    x = props.x,
    y = props.y,
    children = {
      ColorColumn { x = 10 },
      ColorColumn { x = 20 },
      ColorColumn { x = 30 },
      ColorColumn { x = 40 },
      ColorColumn { x = 50 },
      ColorColumn { x = 60 },
      ColorColumn { x = 70 },
      ColorColumn { x = 80 },
      ColorColumn { x = 90 },
      ColorColumn { x = 100 },
    }
  }
end)

LuactLove.init(Love.Fragment {
  App { x = 500, y = 0 },
  App { x = 600, y = 0 },
  App { x = 500, y = 100 },
  App { x = 600, y = 100 },
})