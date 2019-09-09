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

local typeEither = require "luact.src.types.either"
local typeTableOf = require "luact.src.types.tableOf"
local typeExact = require "luact.src.types.exact"
local typeIntersect = require "luact.src.types.intersect"
local typeTableLength = require "luact.src.types.tableLength"
local typeNumber = require "luact.src.types.number"
local typeOptional = require "luact.src.types.optional"

local hexCode = require "luact.src.extensions.love-2d.utils.hexCode"

local ColorContext = Context.new({ r = 0, g = 0, b = 0, 255 })

local arrayColor = typeIntersect(typeTableOf(typeNumber), typeTableLength(4))
local objectColor = typeExact({
  r = typeNumber,
  g = typeNumber,
  b = typeNumber,
  a = typeNumber,
})

local function Color(props)
  local value = props.value

  local parentColor = ColorContext:use()
  
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
  
  return {
    beforeDraw = function ()
      love.graphics.setColor(r, g, b, a)
    end,
    Context.Provider {
      context = ColorContext,
      value = { r = r, g = g, b = b, a = a },
      children = props.children,
    },
    afterDraw = function ()
      love.graphics.setColor(pr, pg, pb, pa)
    end
  }
end

local optionalNumber = typeOptional(typeNumber)

local propTypes = {
  value = typeOptional(typeEither(
    typeNumber,
    arrayColor,
    objectColor
  ))
}

local defaultProps = {
  value = 0x000000FF
}

return Component("love.Color", Color, propTypes, defaultProps)