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

local typeLineStyle = require "luact.src.extensions.love-2d.types.linestyle"
local typeOptional = require "luact.src.types.optional"

local LineStyleContext = Context.new("smooth")

local function LineStyle(props)
  local value = props.value

  local parentValue = LineStyleContext:use()
  
  return {
    beforeDraw = function ()
      love.graphics.setLineStyle(value)
    end,
    Context.Provider {
      context = LineStyleContext,
      value = value,
      children = props.children,
    },
    afterDraw = function ()
      love.graphics.setLineStyle(parentValue)
    end
  }
end

local optionalLineStyle = typeOptional(typeLineStyle)

local propTypes = {
  value = optionalLineStyle
}

local defaultProps = {
  value = "smooth"
}

return Component("love.LineStyle", LineStyle, propTypes, defaultProps)