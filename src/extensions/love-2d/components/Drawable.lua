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

local typeDrawable = require "luact.src.extensions.love-2d.types.drawable"
local typeNumber = require "luact.src.types.number"
local typeOptional = require "luact.src.types.optional"

local function Drawable(props)
  local value = props.value
  local x = props.x
  local y = props.y
  local orientation = props.orientation
  local scaleX = props.scaleX
  local scaleY = props.scaleY
  local originX = props.originX
  local originY = props.originY
  local shearX = props.shearX
  local shearY = props.shearY
  
  local draw = useCallback(function ()
      love.graphics.draw(value, x, y, orientation, scaleX, scaleY, originX, originY, shearX, shearY)
    end, { value, x, y, orientation, scaleX, scaleY, originX, originY, shearX, shearY })

  return Draw { on = draw }
end

local optionalNumber = typeOptional(typeNumber)

local propTypes = {
  value = typeDrawable,
  x = optionalNumber,
  y = optionalNumber,
  orientation = optionalNumber,
  scaleX = optionalNumber,
  scaleY = optionalNumber,
  originX = optionalNumber,
  originY = optionalNumber,
  shearX = optionalNumber,
  shearY = optionalNumber,
}

local defaultProps = {
  x = 0,
  y = 0,
  orientation = 1,
  scaleX = 1,
  scaleY = nil,
  originX = 0,
  originY = 0,
  shearX = 0,
  shearY = 0,
}

return Component("love.Drawable", Drawable, propTypes, defaultProps)