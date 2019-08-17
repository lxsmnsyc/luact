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

local requestRender = require "luact.src.renderer.requestRender"
local unmount = require "luact.src.renderer.unmount"
local forceUnmount = require "luact.src.renderer.forceUnmount"

return function (node, parent, index, root)
	assert(is(node), ".render: node must be a Luact element")
	root = root or parent
	--[[
		Deconstruct node
	--]]
	local renderer = node.renderer
	local props = node.props or {}
	local children = node.children or {}
	
	--[[
		Determine node indentifier
	--]]
	local key = props.key or index or 1
	props.key = key
	--[[
		Check if parent has nodes
	--]]
	local nodes = parent.nodes
	
	--[[
		Check if parent has nodes already
	--]]
	if nodes then
		--[[
			Get the corresponding rendered node
		--]]
		local renderedNode = nodes[key]
		if (renderedNode == nil) then
			--[[
				Request a re-render
			--]]
			return requestRender(node, parent, root)
		end
			
		--[[
			Check if node has the same renderer
		--]]
		if (renderedNode.renderer == renderer) then
			--[[
				Get properties
			--]]
			local renderedProps = renderedNode.props
			local renderedChildren = renderedNode.children
			
			--[[
				Compare new properties to old one
			--]]
			for k, v in pairs(props) do
				--[[
					check if attribute does not exist from old props
				--]]
				if (renderedProps[k] ~= v) then
					--[[
						Request a re-render
					--]]
					return requestRender(node, parent, root)
				end
			end
			
			--[[
				Compare children
			--]]
			local function compare(old, new)
				--[[
					Check if left is a new child
				--]]
				if (old == nil) then
					return true
				end
				--[[
					Check if both child has different renderer
				--]]
				if (new.renderer ~= old.renderer) then
					return true
				end
				--[[
					Check if both child has different keys
				--]]
				local oldProps = old.props
				local newProps = new.props
				if (oldProps == nil) then
					return true
				end
				if (newProps.key ~= oldProps.key) then
					return true
				end
			end
			
			--[[
				Check if the old node is a string
			--]]
			if (type(renderedChildren) == "string") then
				--[[
					Check if the new node is a string
				--]]
				if (type(children) == "string") then
					if (renderedChildren ~= children) then
						return requestRender(node, parent, root)
					end
				else
					return requestRender(node, parent, root)
				end
			end
			--[[
				Check if children is a node
			--]]
			if (is(renderedChildren)) then
				--[[
					Check if the new children is a node
				--]]
				if (is(children)) then
					if (compare(renderedChildren, children)) then
						forceUnmount(renderedChildren, root)
						return requestRender(node, parent, root)
					end
				else
					forceUnmount(renderedChildren, root)
					return requestRender(node, parent, root)
				end
			end
			--[[
				Check if children is a node list
			--]]
			if (type(renderedChildren) == "table") then
				--[[
					Check if the new children is a node list
				--]]
				if (type(children) == "table") then
					for i = 1, #children do
						local new = children[i]
						local old = renderedChildren[i]
						if (compare(old, new)) then
							forceUnmount(old, root)
							return requestRender(node, parent, root)
						end
					end
				else
					return requestRender(node, parent, root)
				end
			end
			
			return requestRender(node, parent, root)
		else
			--[[
				Unmount rendered node
			--]]
			unmount(renderedNode, parent, key)
			--[[
				Request a re-render
			--]]
			return requestRender(node, parent, root)
		end
	else
		--[[
			Initialize nodes
		--]]
		parent.nodes = { [key] = node }
		--[[
			Initialize state
		--]]
		node.state = {}
		return requestRender(node, parent, root)
	end
end