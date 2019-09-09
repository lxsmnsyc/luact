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

local typeNumber = require "luact.src.types.number"
local typeOptional = require "luact.src.types.optional"

local TranslateContext = Context.new({ x = 0, y = 0 })

local function Translate(props)
  local x = props.y
  local y = props.y

  local parent = TranslateContext:use()
  local px = parent.x
  local py = parent.y
  
  return {
    beforeDraw = function ()
      love.graphics.translate(x, y)
    end,
    Context.Provider {
      context = TranslateContext,
      value = { x = x, y = y },
      children = props.children,
    },
    afterDraw = function ()
      love.graphics.translate(px, py)
    end
  }
end

local optionalNumber = typeOptional(typeNumber)

local propTypes = {
  x = optionalNumber,
  y = optionalNumber,
}

local defaultProps = {
  x = 0,
  y = 0,
}

return Component("love.Translate", Translate, propTypes, defaultProps)