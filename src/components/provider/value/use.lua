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
local ValueProvider = require "luact.src.components.provider.value.provider"

local PARENT = require "luact.src.meta.PARENT"

local renderContext = require "luact.src.renderer.context"

local typeElementOfType = require "luact.src.types.elementOfType"
local typeFunction = require "luact.src.types.func"

local typeValueProvider = typeElementOfType(ValueProvider)

local function findParent(node, root, filter)
  local parent = PARENT[node]
  if (parent == root) then
    return nil
  end
  if (filter(parent)) then
    return parent
  end
  return findParent(parent, root, filter)
end

local function contextFilter(filter)
  return function (node)
    return typeValueProvider(node) and filter(node.props.value)
  end
end

return function (filter)
  assert(typeFunction(filter), "luact.Provider.useValue: filter must be a function.")
  local context = renderContext.getContext()
  local parent = findParent(context.node, context.root, contextFilter(filter))
  
  if (parent) then
    return parent.props.value
  end
  return nil
end