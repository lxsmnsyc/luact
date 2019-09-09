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
local VALID = require "luact.src.meta.VALID"
local NAMES = require "luact.src.meta.NAMES"
local ELEMENT = require "luact.src.meta.ELEMENT"
local RENDERER = require "luact.src.meta.RENDERER"
local COMPONENT = require "luact.src.meta.COMPONENT"

local typeOptional = require "luact.src.types.optional"
local typeFunction = require "luact.src.types.func"
local typeString = require "luact.src.types.string"
local typeTable = require "luact.src.types.table"
local typeTableOf = require "luact.src.types.tableOf"

local optionalTable = typeOptional(typeTable)
local optionalFuncTable = typeOptional(typeTableOf(typeFunction))

return function (name, renderer, propTypes, defaultProps)
  assert(typeString(name), "luact.component: name must be a string.")
  assert(typeFunction(renderer), "luact.component: renderer must be a function.")
  assert(optionalFuncTable(propTypes), "luact.component: propTypes must be a table.")
  assert(optionalTable(defaultProps), "luact.component: defaultProps must be a table.")
  
  local function component(props)
    assert(optionalTable(props), "luact.component."..name..": props must be a table.")
  
    --[[
      Validate prop types
    --]]
    if (propTypes) then
      for k, v in pairs(propTypes) do
        --[[
          lookup type descriptor
        --]]
        local descriptor = propTypes[k]
        --[[
          check if descriptor exists
        --]]
        if (descriptor) then
          --[[
            get property value
          --]]
          local value = props[k]
          --[[
            type check for value
          --]]
          assert(descriptor(props[k]), "luact.component."..name..": property mismatch (\""..k.."\")")
          --[[
            assign default property value
          --]]
          if (value == nil) then
            props[k] = defaultProps[k]
          end
        end
      end
    end

    --[[
      Create a node associated with a renderer
      and its props
    --]]
    local node = {
      props = props or {},
    }
    
    --[[
      Mark node as a valid element
    --]]
    ELEMENT[node] = component
    return node
  end

  --[[
    Mark the component function as a valid component
  --]]
  COMPONENT[component] = VALID
  --[[
    Mark the component's name
  --]]
  NAMES[component] = name
  --[[
    Mark the renderer function as the component's renderer
  --]]
  RENDERER[component] = renderer
  
  return component
end