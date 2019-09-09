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
local RENDERER = require "luact.src.meta.RENDERER"
local ELEMENT = require "luact.src.meta.ELEMENT"
local LAYOUT_EFFECT = require "luact.src.meta.LAYOUT_EFFECT"
local VALID = require "luact.src.meta.VALID"

local NAMES = require "luact.src.meta.NAMES"

local context = require "luact.src.renderer.context"
local unmount = require "luact.src.renderer.unmount"

local typeElement = require "luact.src.types.element"
local typeTable = require "luact.src.types.table"

local states = require "luact.src.state"

local render

--[[
	Request a forceful render of the node
--]]
return function (node, parent, root)
	assert(typeElement(node), "luact.requestRender: node must be a Luact element")
	assert(typeTable(parent), "luact.requestRender: parent must be a Luact element")
	assert(typeTable(root), "luact.requestRender: root must be a table")
	--[[
		Lazy load render
	--]]
	render = render or require "luact.src.renderer.render"
  
  local state = states.get(node)

	--[[
		Set global context for the hooks
	--]]
	context.setContext({
		node = node,
		parent = parent,
		root = root,
		index = 0,
    state = state,
	})
	
	--[[
		Render the component
	--]]
  
	local childNode = RENDERER[ELEMENT[node]](node.props)
	--[[
		Reset global context
	--]]
	context.resetContext()

  local nodes = node.nodes or {}
  node.nodes = nodes

	--[[
		Render the child node if it is a valid Luact component,
		otherwise, add the result node to the child nodes.
	--]]
	if (typeTable(childNode)) then
    if (typeElement(childNode)) then
      render(childNode, node, nil, root)
    else
      for k, v in pairs(childNode) do
        if (typeElement(v)) then
          render(v, node, k, root)
        else
          nodes[k] = v
        end
      end
    end
  else
    for k, v in pairs(nodes) do
      if (typeElement(v)) then
        unmount(v, node, k)
      end
    end
    node.nodes = { childNode }
  end

	parent.nodes[node.props.key] = node
  
  --[[
    Start effects
  --]]
  for i = 1, #state do
    local st = state[i]
    if (st and LAYOUT_EFFECT[st] == VALID) then
      st()
    end
  end
end