local luact = require "luact.src"

local container = {}

local DraggableBox = luact.component("DraggableBox", function (props)
  local inside, setInside = luact.hooks.useState(false)
  local offsX, setOffsX = luact.hooks.useState(0)
  local offsY, setOffsY = luact.hooks.useState(0)
  local down, setDown = luact.hooks.useState(false)

  return {
    luact.love.components.RectangularSensor {
      x = offsX + props.x,
      y = offsY + props.y,
      width = 100,
      height = 100,
      onMousePressed = function ()
        setDown(true)
      end,
      onMouseReleased = function ()
        setDown(false)
      end,
      onMouseMoved = function (x, y, dx, dy)
        if (down) then
          setOffsX(offsX + dx)
          setOffsY(offsY + dy)
        end
      end,
    },
    luact.love.components.Rectangle {
      mode = "fill",
      x = offsX + props.x,
      y = offsY + props.y,
      width = 100,
      height = 100
    }
  }
end)

local TwoBox = luact.component("TwoBox", function ()
  return {
    luact.love.components.Color {
      value = 0x00FF00FF,
      children = DraggableBox {
        x = 100,
        y = 100,
      }
    },
    luact.love.components.Color {
      value = 0xFF0000FF,
      children = DraggableBox {
        x = 300,
        y = 300,
      }
    },
  }
end)

local LineTest = luact.component("LineTest", function ()
  return {
    luact.love.components.LineStyle {
      value = "rough",
      children = {
        luact.love.components.Line {
          points = {
            { x = 300, y = 300 },
            { x = 400, y = 300 },
            { x = 400, y = 400 },
            { x = 300, y = 400 },
          }
        },
        luact.love.components.LineWidth {
          value = 10,
          children = luact.love.components.Line {
            points = {
              { x = 0, y = 0 },
              { x = 100, y = 0 },
              { x = 100, y = 100 },
              { x = 0, y = 100 },
            }
          }
        },
        luact.love.components.Line {
          points = {
            { x = 100, y = 100 },
            { x = 200, y = 100 },
            { x = 200, y = 200 },
            { x = 100, y = 200 },
          }
        }
      }
    }
  }
end)

local App = luact.component("App", function ()
  return TwoBox()
end)


luact.render(App(), container)

luact.love.start(container)