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

local Context = require "luact.src.components.context"
local Equatable = require "luact.src.utils.equatable"

local Draw = require "luact.src.extensions.love-2d.components.Draw"

local useCallback = require "luact.src.hooks.useCallback"

local typeEither = require "luact.src.types.either"
local typeExact = require "luact.src.types.exact"
local typeNumber = require "luact.src.types.number"
local typeOptional = require "luact.src.types.optional"
local typeElement = require "luact.src.types.element"
local typeChildren = require "luact.src.types.children"

local hexCode = require "luact.src.extensions.love-2d.utils.hexCode"

local ColorContext = Context.new({ r = 0, g = 0, b = 0, a = 1 })

local arrayColor = typeExact({
  typeNumber,
  typeNumber,
  typeNumber,
  typeNumber,
})

local objectColor = typeExact({
  r = typeNumber,
  g = typeNumber,
  b = typeNumber,
  a = typeNumber,
})

local function Color(props)
  local value = props.value

  local parentColor = Context.use(ColorContext)
  
  local pr, pg, pb, pa = parentColor.r, parentColor.g, parentColor.b, parentColor.a
  local r, g, b, a = pr, pg, pb, pa
  
  if (typeNumber(value)) then
    r, g, b, a = hexCode(value)
  elseif (arrayColor(value)) then
    r, g, b, a = unpack(value)
  elseif (objectColor(value)) then
    r = value.r
    g = value.g
    b = value.b
    a = value.a
  end
  
  local drawBefore = useCallback(function ()
    love.graphics.setColor(r, g, b, a)
  end, { r, g, b, a })

  local drawAfter = useCallback(function ()
    love.graphics.setColor(pr, pg, pb, pa)
  end, { pr, pg, pb, pa })

  return Draw {
    before = drawBefore,
    after = drawAfter,
    child = Context.Provider {
      context = ColorContext,
      value = Equatable { r = r, g = g, b = b, a = a },
      children = props.children,
      child = props.child,
    },
  }
end

local optionalNumber = typeOptional(typeNumber)

local propTypes = {
  value = typeOptional(typeEither(
    typeNumber,
    arrayColor,
    objectColor
  )),
  children = typeOptional(typeChildren),
  child = typeOptional(typeElement),
}

local defaultProps = {
  value = 0x000000FF
}

return Component("love.Color", Color, propTypes, defaultProps)