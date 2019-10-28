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

local useMemo = require "luact.src.hooks.useMemo"
local useValueProvider = require "luact.src.components.provider.value.use"

local typeFunction = require "luact.src.types.func"
local typeElement = require "luact.src.types.element"
local typeOptional = require "luact.src.types.optional"

local function Selector(props)
  local selector = props.selector
  local builder = props.builder
  local child = props.child
  
  local value = useValueProvider(of)
  
  local selected = selector(value)

  return useMemo(function ()
    return builder(selected, child)
  end, { selected, child })
end

local propTypes = {
  of = typeFunction,
  selector = typeFunction,
  builder = typeFunction,
  child = typeOptional(typeElement),
}

return Component("Value.Selector", Selector, propTypes)