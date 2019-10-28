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

local typeFunction = require "luact.src.types.func"
local typeTable = require "luact.src.types.table"
local typeOptional = require "luact.src.types.optional"

local optionalTable = typeOptional(typeTable)

local Equatable = require "luact.src.utils.equatable"

return function (callback, dependencies)
  assert(renderContext.isActive(), "useMemo: illegal lifecycle access")
  assert(typeFunction(callback), "useMemo: callback must be a function.")
  assert(optionalTable(dependencies), "useMemo: dependencies must be a table.")

  local context = renderContext.getContext()
  
  local node = context.node
  local root = context.root
  local parent = context.parent

  local state = context.state
  
  local depIndex = context.index + 1
  local memoIndex = context.index + 2
  context.index = memoIndex

  local dep = state[depIndex]
  local memo = state[memoIndex]
  
  dependencies = Equatable(dependencies)

  if (dep ~= dependencies) then
    state[depIndex] = dependencies
    
    memo = callback()
    state[memoIndex] = memo
  end
  
  return memo
end