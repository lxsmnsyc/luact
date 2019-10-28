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

local ContextProvider = require "luact.src.components.context.provider"

local typeElementOfType = require "luact.src.types.elementOfType"
local typeContext = require "luact.src.components.context.type"
local typeContextProvider = typeElementOfType(ContextProvider)

local defaultValues = require "luact.src.components.context.defaultValues"

local PARENT = require "luact.src.meta.PARENT"

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

local function contextFilter(context)
  return function (node)
    return typeContextProvider(node) and node.props.context == context
  end
end

return function (ctx)
  assert(typeContext(ctx), "Context.use: ctx must be a Context.") 
  local context = renderContext.getContext()
  
  local parent = findParent(context.node, context.root, contextFilter(ctx))

  if (parent) then
    return parent.props.value
  end
  return defaultValues[ctx]
end