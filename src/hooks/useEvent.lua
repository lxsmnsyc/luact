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
local renderContext = require "luact.src.renderer.context"

local Event = require "luact.src.event"

local useRef = require "luact.src.hooks.useRef"
local useMount = require "luact.src.hooks.useMount"
local useUpdate = require "luact.src.hooks.useUpdate"
local useUnmount = require "luact.src.hooks.useUnmount"

local typeFunction = require "luact.src.types.func"
local typeTable = require "luact.src.types.table"
local typeOptional = require "luact.src.types.optional"

local optionalTable = typeOptional(typeTable)

return function (ev, callback, dependencies)
  assert(renderContext.isActive(), "useEvent: illegal access")
  assert(getmetatable(ev) == Event, "useEvent: event must be an Event instance.")
  assert(typeFunction(callback), "useEvent: callback must be a function.")
  assert(optionalTable(dependencies), "useEvent: dependencies must be a table.")

  local ref = useRef(callback)
  
  local node = renderContext.getContext().node
  
  useMount(function ()
    ev:addListener(ref.current)
  end)

  useUpdate(function ()
    ev:swapListener(ref.current, callback)
    ref.current = callback
  end, { callback, unpack(dependencies) })

  useUnmount(function ()
    ev:removeListener(ref.current)
  end)
end