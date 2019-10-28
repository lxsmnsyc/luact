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
local weakmap = require "luact.src.utils.weakmap"

local Event = {}
Event.__index = Event

function Event.new()
  return setmetatable({
    listeners = {},
  }, Event)
end

local function findIndex(list, item)
  for k, v in pairs(list) do
    if (v == item) then
      return k
    end
  end
end

function Event:addListener(listener)
  local list = self.listeners

  local index = #list + 1
  list[index] = listener
end

function Event:swapListener(oldListener, newListener)
  local list = self.listeners
  
  local index = findIndex(list, oldListener) or (#list + 1)
  
  list[index] = newListener
end

function Event:removeListener(listener)
  local list = self.listeners
  
  local base = findIndex(list, listener)

  if (base) then
    table.remove(list, base)
  end
end

function Event:dispatch(...)
  local list = self.listeners
  
  for i = 1, #list do
    local listener = list[i]
    
    if (type(listener) == "function") then
      listener(...)
    end
  end
end

function Event:getListenersCount()
  return #self.listeners
end

return Event