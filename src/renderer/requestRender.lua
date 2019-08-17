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
local dispatcher = require "luact.src.dispatcher"
local is = require "luact.src.is"

local render

--[[
	Request a forceful render of the node
--]]
return function (node, parent, root)
	assert(is(node), ".requestRender: node must be a Luact element")
	assert(is(parent), ".requestRender: parent must be a Luact element")
	assert(type(root) == "table", ".requestRender: root must be a table")
	--[[
		Lazy load render
	--]]
	render = render or require "luact.src.renderer.render"
	
	--[[
		Set global context for the hooks
	--]]
	dispatcher.setContext({
		node = node,
		parent = parent,
		root = root,
		index = 0,
	})
	
	--[[
		Render the component
	--]]
	node.mounted = true
	local childNode = node.renderer(node.props, node.children)

	--[[
		Render the child node if it is a valid Luact component,
		otherwise, add the result node to the child nodes.
	--]]
	if (is(childNode)) then
		render(childNode, node, 1, root)
	elseif (type(childNode) == "table") then
		node.nodes = node.nodes or {}
		for i = 1, #childNode do
			if (is(childNode[i])) then
				render(childNode[i], node, i, root)
			else
				node.nodes[i] = childNode[i]
			end
		end
	else
		node.nodes = { childNode }
	end

	parent.nodes = parent.nodes or {}
	parent.nodes[node.props.key] = node
	--[[
		Reset global context
	--]]
	dispatcher.resetContext()
end