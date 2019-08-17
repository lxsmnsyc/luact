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
local is = require "luact.src.is"
local isCleanup = require "luact.src.hooks.isCleanup"


--[[
	Unmounts a Luact node from its parent
--]]
local function unmount(node, parent, key)
	assert(is(node), ".unmount: node must be a Luact element")
	assert(is(parent), ".unmount: parent must be a Luact element")
	--[[
		Call all cleanup functions
	--]]
	local states = node.states
	for i = 1, #states do
		local state = states[i]
		if (isCleanup(state)) then
			state.call()
		end
	end
	--[[
		Unmount each children
	--]]
	for i = 1, #children do
		unmount(children[i], node)
	end
	
	table.remove(parent.nodes, key)
	node.mounted = false
end

return unmount
