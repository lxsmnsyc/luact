--[[
    Luact
	
    MIT License
    Copyright (c) 2019 Alexis Munsayac
    Permission is hereby granted, free of charge, to any person obtaining a copy
    of this software and associated documentation files (the "Software"), to deal
    in the Software without restriction, including without limitation the rights
    to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
    copies of the Software, and to permit persons to whom the Software is
    furnished to do so, subject to the following conditions:
    The above copyright notice and this permission notice shall be included in all
    copies or substantial portions of the Software.
    THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
    IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
    FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
    AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
    LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
    OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
    SOFTWARE.
--]]
local Component = require "luact.src.component"

local useCallback = require "luact.src.hooks.useCallback"
local useState = require "luact.src.hooks.useState"

local useMouseMoved = require "luact.src.extensions.love-2d.hooks.useMouseMoved"
local useMousePressed = require "luact.src.extensions.love-2d.hooks.useMousePressed"
local useMouseReleased = require "luact.src.extensions.love-2d.hooks.useMouseReleased"
local useTouchMoved = require "luact.src.extensions.love-2d.hooks.useMouseMoved"
local useTouchPressed = require "luact.src.extensions.love-2d.hooks.useMousePressed"
local useTouchReleased = require "luact.src.extensions.love-2d.hooks.useMouseReleased"

local typeNumber = require "luact.src.types.number"
local typeFunction = require "luact.src.types.func"
local typeOptional = require "luact.src.types.optional"

local function RectangularSensor(props)
  local x = props.x
  local y = props.y
  local width = props.width
  local height = props.height
  
  local onMouseMoved = props.onMouseMoved
  local onMouseEnter = props.onMouseEnter
  local onMouseLeave = props.onMouseLeave
  local onMousePressed = props.onMousePressed
  local onMouseReleased = props.onMouseReleased
  local onTouchMoved = props.onTouchMoved
  local onTouchPressed = props.onTouchPressed
  local onTouchReleased = props.onTouchReleased
  
  local insideState, setInsideState = useState(false)
  local downState, setDownState = useState(false)
  
  local check = useCallback(function (cx, cy)
    return (x <= cx and cx <= (x + width))
      and (y <= cy and cy <= (y + height))
  end, { x, y, width, height })

  useMouseMoved(function (nx, ny, dx, dy, istouch)
    if (check(nx, ny)) then
      onMouseMoved(nx, ny, dx, dy, istouch)
      if (not insideState) then
        setInsideState(true)
        onMouseEnter(nx, ny, dx, dy, istouch)
      end
    elseif insideState then
      setInsideState(false)
      onMouseLeave(nx, ny, dx, dy, istouch)
    end
  end, { check, insideState, onMouseMoved, onMouseEnter, onMouseLeave })

  useMousePressed(function (nx, ny, button, istouch)
    if (insideState or check(nx, ny)) then
      onMousePressed(nx, ny, button, istouch)
    end
  end, { check, insideState, onMousePressed })

  useMouseReleased(function (nx, ny, button, istouch)
    if (insideState or check(nx, ny)) then
      onMouseReleased(nx, ny, button, istouch)
    end
  end, { check, insideState, onMouseReleased })

  useTouchMoved(function (id, nx, ny, dx, dy, pressure)
    if (insideState or check(nx, ny)) then
      onTouchMoved(id, nx, ny, dx, dy, pressure)
      setInsideState(true)
    elseif insideState then
      setInsideState(false)
    end
  end, { check, insideState, onTouchMoved })

  useTouchPressed(function (id, nx, ny, dx, dy, pressure)
    if (insideState or check(nx, ny)) then
      onTouchPressed(id, nx, ny, dx, dy, pressure)
      setInsideState(true)
    elseif insideState then
      setInsideState(false)
    end
  end, { check, insideState, onTouchPressed })

  useTouchReleased(function (id, nx, ny, dx, dy, pressure)
    if (insideState or check(nx, ny)) then
      onTouchReleased(id, nx, ny, dx, dy, pressure)
      setInsideState(true)
    elseif insideState then
      setInsideState(false)
    end
  end, { check, insideState, onTouchReleased })

  return props.children
end

local optionalNumber = typeOptional(typeNumber)
local optionalFunc = typeOptional(typeFunction)

local propTypes=  {
  x = optionalNumber,
  y = optionalNumber,
  width = optionalNumber,
  height = optionalNumber,
  onMouseMoved = optionalFunc,
  onMouseEnter = optionalFunc,
  onMouseLeave = optionalFunc,
  onMousePressed = optionalFunc,
  onMouseReleased = optionalFunc,
  onTouchMoved = optionalFunc,
  onTouchPressed = optionalFunc,
  onTouchReleased = optionalFunc,
}

local function defaultFunc() end

local defaultProps = {
  x = 0,
  y = 0,
  width = 0,
  height = 0,
  onMouseMoved = defaultFunc,
  onMouseEnter = defaultFunc,
  onMouseLeave = defaultFunc,
  onMousePressed = defaultFunc,
  onMouseReleased = defaultFunc,
  onTouchMoved = defaultFunc,
  onTouchPressed = defaultFunc,
  onTouchReleased = defaultFunc,
}


return Component("love.RectangularSensor", RectangularSensor, propTypes, defaultProps)