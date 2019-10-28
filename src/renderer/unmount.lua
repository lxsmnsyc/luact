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
local typeElement = require "luact.src.types.element"
local typeFunction = require "luact.src.types.func"

local PARENT = require "luact.src.meta.PARENT"
local CLEANUP = require "luact.src.meta.CLEANUP"
local VALID = require "luact.src.meta.VALID"

local states = require "luact.src.state"

local function checkCleanupCall(state)
  local callable = state.call
  if (state and CLEANUP[state] == VALID and typeFunction(callable)) then
    callable()
  end
end
--[[
	Unmounts a Luact node from its parent
--]]
local function unmount(node, parent, key)
	assert(typeElement(node), "luact.unmount: node must be a Luact element")
	--[[
		Call all cleanup functions
	--]]
	local state = states.get(node)
	for i = 1, #state do
		checkCleanupCall(state[i])
	end
  states.new(node)
	--[[
		Unmount each children
	--]]
  local children = node.nodes
	for k, v in pairs(children) do
    if (typeElement(v)) then
      unmount(v, node)
    end
	end
	
  parent.nodes[key or node.props.key or 1] = nil
  PARENT[node] = nil
end

return unmount
