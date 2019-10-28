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
local requestRender = require "luact.src.renderer.requestRender"
local renderContext = require "luact.src.renderer.context"
local Future = require "luact.src.future"

local useCallback = require "luact.src.hooks.useCallback"

return function (initialValue)
  assert(renderContext.isActive(), "useState: illegal state access")
  local context = renderContext.getContext()
  
  local node = context.node
  local root = context.root
  local parent = context.parent
  
  local state = context.state
  local index = context.index + 1
  local init = context.index + 2
  context.index = init
  
  local isInit = state[init]

  if (not isInit) then
    state[init] = true
    state[index] = initialValue
  end

  local value = state[index]
  
  local setState = useCallback(function (newValue)
    if (newValue ~= value) then
      state[index] = newValue
      
      Future.new(function ()
        if (newValue ~= state[index] or value ~= state[index]) then
          requestRender(node, parent, root)
        end
      end)
    end
  end, { value })

  return value, setState
end