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
local Component = require "luact.src.component"


local weakmap = require "luact.src.utils.weakmap"

local values = weakmap()

local Context = {}
Context.__index = Context

function Context.new(default)
  local instance = setmetatable({}, Context)
  values[instance] = default
  return instance
end
--[[
  ContextProvider
  
  Injects the value down the ContextProvider's tree
--]]
local useLayoutEffect = require "luact.src.hooks.useLayoutEffect"

local typeMetatable = require "luact.src.types.metatable"
local typeFunction = require "luact.src.types.func"

Context.Provider = Component(
  "Context.Provider",
  function (props)
    local context = props.context
    local value = props.value
    
    local prevValue = values[context]
    
    values[context] = value
    
    useLayoutEffect(function ()
      values[context] = prevValue
    end, { context, value })

    return props.children
  end,
  {
    context = typeMetatable(Context),
  }
)

--[[
  Context.use
  
  allows to access the context's injected value
  
  re-renders the component if the value updates
--]]
local useState = require "luact.src.hooks.useState"
function Context:use()
  local current = values[self]
  local state, setState = useState(current)
  setState(current)
  return state
end

--[[
  ContextConsumer
  
  Consumes the context's injected value
--]]

Context.Consumer = Component(
  "Context.Consumer",
  function (props)
    local context = props.context
    local builder = props.builder
    
    local value = context:use()
    
    return builder(value)
  end,
  {
    context = typeMetatable(Context),
    builder = typeFunction,
  }
)

return Context