local Component = require "luact.src.component"

local typeNumber = require "luact.src.types.number"
local typeOptional = require "luact.src.types.optional"

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
local Context = require "luact.src.components.context"

local typeNumber = require "luact.src.types.number"
local typeOptional = require "luact.src.types.optional"

local RotateContext = Context.new(0)

local function Rotate(props)
  local value = props.value

  local parentValue = RotateContext:use()
  
  return {
    beforeDraw = function ()
      love.graphics.rotate(value)
    end,
    Context.Provider {
      context = RotateContext,
      value = value,
      children = props.children,
    },
    afterDraw = function ()
      love.graphics.rotate(parentValue)
    end
  }
end

local optionalNumber = typeOptional(typeNumber)

local propTypes = {
  value = optionalNumber
}

local defaultProps = {
  value = 0
}

return Component("love.Rotate", Rotate, propTypes, defaultProps)