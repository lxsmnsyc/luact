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

local useDraw = require "luact.src.extensions.love-2d.hooks.useDraw"

local typeOptional = require "luact.src.types.optional"
local typeNumber = require "luact.src.types.number"
local typeString = require "luact.src.types.string"

local useMount = require "luact.src.hooks.useMount"
local useUpdate = require "luact.src.hooks.useUpdate"
local useUnmount = require "luact.src.hooks.useUnmount"
local useWhyDidYouUpdate = require "luact.src.hooks.useWhyDidYouUpdate"

local function Text(props, children)
  local text = props.text
  local x = props.x
  local y = props.y
  local r = props.angle
  local sx = props.scaleX
  local sy = props.scaleY
  local ox = props.originX
  local oy = props.originY
  local kx = props.shearX
  local ky = props.shearY

  return {
    draw = function ()
      love.graphics.print(text, x, y, r, sx, sy, ox, oy, kx, ky)
    end,
  }
end

local optionalNumber = typeOptional(typeNumber)

local propTypes = {
  text = typeOptional(typeString),
  x = optionalNumber,
  y = optionalNumber,
  angle = optionalNumber,
  scaleX = optionalNumber,
  scaleY = optionalNumber,
  originX = optionalNumber,
  originY = optionalNumber,
  shearX = optionalNumber,
  shearY = optionalNumber,
}

local defaultProps = {
  text = "",
  x = 0,
  y = 0,
  angle = 0,
  scaleX = 1,
  scaleY = nil,
  originX = 0,
  originY = 0,
  shearX = 0,
  shearY = 0,
}

return Component("love.Text", Text, propTypes, defaultProps)
