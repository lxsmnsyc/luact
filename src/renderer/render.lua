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
local unmount = require "luact.src.renderer.unmount"

local states = require "luact.src.state"

local ELEMENT = require "luact.src.meta.ELEMENT"

local typeOptional = require "luact.src.types.optional"
local typeExcept = require "luact.src.types.except"
local typeTable = require "luact.src.types.table"
local typeElement = require "luact.src.types.element"

local exceptTable = typeExcept(typeTable)
local optionalTable = typeOptional(typeTable)

local function compareComponent(old, new)
  if (typeElement(old)) then
    if (typeElement(new)) then
      return ELEMENT[old] ~= ELEMENT[new]
    end
  end
  return true
end

local function compareProps(old, new)
	local oldProps = old.props
	local newProps = new.props
	--[[
		Compare new properties to old one
	--]]
	for k, v in pairs(newProps) do
		--[[
			check if attribute does not exist from old props
		--]]
		if (oldProps[k] ~= v) then
			return true
		end
	end
	return false
end

return function (node, parent, index, root)
	assert(typeElement(node), "luact.render: node must be a Luact element")
  assert(optionalTable(parent), "luact.render: parent must be a Luact element or a table")
  assert(optionalTable(root), "luact.render: root must be a table.")
	root = root or parent
	--[[
		Deconstruct node
	--]]
  local props = node.props
	
	--[[
		Determine node indentifier
	--]]
	local key = props.key or index or 1
	props.key = key
	
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
        Initialize state
      --]]
      states.new(node)
      return requestRender(node, parent, root)
    end
		
    if (typeElement(renderedNode)) then
      if (compareComponent(renderedNode, node)) then
        --[[
          Unmount rendered node
        --]]
        unmount(renderedNode, parent, key)
        --[[
          Initialize state
        --]]
        states.new(node)
        --[[
          Request a re-render
        --]]
        return requestRender(node, parent, root)
      end

      if (compareProps(renderedNode, node)) then
        --[[
          Initialize state
        --]]
        states.share(renderedNode, node)
        --[[
          Request a re-render
        --]]
        return requestRender(node, parent, root)
      end
    end
	else
		--[[
			Initialize nodes
		--]]
		parent.nodes = { [key] = node }
		--[[
			Initialize state
		--]]
		states.new(node)
		return requestRender(node, parent, root)
	end
end