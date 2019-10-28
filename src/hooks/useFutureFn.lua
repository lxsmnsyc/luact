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

local useState = require "luact.src.hooks.useState"
local useCallback = require "luact.src.hooks.useCallback"
local useRefMounted = require "luact.src.hooks.useRefMounted"

local Future = require "luact.src.future"

local typeFunction = require "luact.src.types.func"
local typeTable = require "luact.src.types.table"
local typeOptional = require "luact.src.types.optional"

local optionalTable = typeOptional(typeTable)

return function (callback, dependencies, initialState)
  assert(renderContext.isActive(), "useFutureFn: illegal lifecycle access")
  assert(typeFunction(callback), "useFutureFn: callback must be a function.")
  assert(optionalTable(dependencies), "useFutureFn: dependencies must be a table.")
  
  local state, setState = useState(initialState or { loading = false })
  
  local mounted = useRefMounted()
  
  local futureCallback = useCallback(function (...)
    setState({ loading = true })
    
    local futureResult = callback(...)
    
    assert(getmetatable(futureResult) == Future, "useFutureFn: callback must return a Future.")
    
    local function onResolve(value)
      if (mounted.current) then
        setState({ value = value, loading = false })
      end
      return value
    end

    local function onReject(value)
      if (mounted.current) then
        setState({ err = value, loading = false })
      end
      return value
    end

    return futureResult:andThen(onResolve, onReject)
  end, dependencies)

  return state, futureCallback
end