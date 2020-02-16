local LuactLove = require "luact-love"
local Love = require "luact-love.reconciler"
local Luact = require "luact"
local frame = require "luact.timers.frame"
local logs = require "luact.utils.logs"

local Rectangle = require "luact-love.components.rectangle"
local Color = require "luact-love.components.color"
local Translate = require "luact-love.components.translate"

local OffsetContext = Love.create_context()
local GradeContext = Love.create_context()

local ColorBox = Love.component(function (props)
  local state = Luact.use_context(GradeContext)
  local x = Luact.use_context(OffsetContext)

  return Color {
    r = state / 1000,
    g = x / 100,
    b = props.y / 100,
    children = {
      Rectangle {
        mode = "fill",
        x = x,
        y = props.y,
        width = 10,
        height = 10,
      },
    }
  }
end)

local ColorColumn = Love.basic(function (props)
  return OffsetContext.Provider {
    value = props.x,
    children = {
      ColorBox { y = 10 },
      ColorBox { y = 20 },
      ColorBox { y = 30 },
      ColorBox { y = 40 },
      ColorBox { y = 50 },
      ColorBox { y = 60 },
      ColorBox { y = 70 },
      ColorBox { y = 80 },
      ColorBox { y = 90 },
      ColorBox { y = 100 },
    },
  } 
end)

local App = Love.component(function (props)
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

  return GradeContext.Provider {
    value = state,
    children = {
      Translate {
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
    }
  }
end)

local Main = Love.create_meta(function (class)
  function class:component_did_catch(errors)
    -- error(logs(errors, 0))
  end

  function class:render()
    return Love.Fragment {
      children = {
        App { x = 500, y = 0 },
        App { x = 600, y = 0 },
        App { x = 500, y = 100 },
        App { x = 600, y = 100 },
      }
    }
  end
end)
LuactLove.init(Main {})