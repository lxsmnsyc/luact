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

local typeOptional = require "luact.src.types.optional"
local typeFunction = require "luact.src.types.func"
local typeChildren = require "luact.src.types.children"
local typeElement = require "luact.src.types.element"

local Equatable = require "luact.src.utils.equatable"

local function Draw(props)
  local children = props.children
  if (children) then
    return children
  end
  local child = props.child
  if (child) then
    return child
  end
end

local optionalFunction = typeOptional(typeFunction)

local propTypes = {
  before = optionalFunction,
  on = optionalFunction,
  after = optionalFunction,
  children = typeOptional(typeChildren),
  child = typeOptional(typeElement),
}

local function defaultFunc() end

local defaultProps = {
  before = defaultFunc,
  on = defaultFunc,
  after = defaultFunc,
}

return Component("love.Draw", Draw, propTypes, defaultProps)