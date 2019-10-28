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

local Draw = require "luact.src.extensions.love-2d.components.Draw"

local useCallback = require "luact.src.hooks.useCallback"

local typeNumber = require "luact.src.types.number"
local typeOptional = require "luact.src.types.optional"
local typeDrawMode = require "luact.src.extensions.love-2d.types.drawmode"

local function Circle(props)
  local mode = props.mode
  local radius = props.radius
  local x = props.x
  local y = props.y
  local segments = props.segments
  
  local draw = useCallback(function ()
    love.graphics.circle(mode, x, y, radius, segments)
  end, { mode, x, y, radius, segments })

  return Draw { on = draw }
end

local propTypes = {
  mode = typeDrawMode,
  radius = typeNumber,
  x = typeNumber,
  y = typeNumber,
  segments = typeOptional(typeNumber),
}

local defaultProps = {}

return Component("love.Circle", Circle, propTypes, defaultProps)
