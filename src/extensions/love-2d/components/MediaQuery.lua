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

local useWindowSize = require "luact.src.extensions.love-2d.hooks.useWindowSize"

local typeNumber = require "luact.src.types.number"
local typeOptional = require "luact.src.types.optional"
local typeEitherValues = require "luact.src.types.eitherValues"
local typeChildren = require "luact.src.types.children"
local typeElement = require "luact.src.types.element"

function MediaQuery(props)
  local minWidth = props.minWidth
  local minHeight = props.minHeight
  local maxWidth = props.maxWidth
  local maxHeight = props.maxHeight
  local orientation = props.orientation
  
  local w, h = useWindowSize()

  local passWidth = (minWidth <= w) and (w <= maxWidth)
  local passHeight = (minHeight <= h) and (h <= maxHeight)
  
  local passAll = passWidth and passHeight
  
  local currentOrientation = w < h and "portrait" or "landscape"
  
  if (orientation) then
    passAll = passAll and currentOrientation == orientation
  end
  
  if (passAll) then
    return props.children
  end
end

local optionalNumber = typeOptional(typeNumber)

local propTypes = {
  minWidth = optionalNumber,
  minHeight = optionalNumber,
  maxWidth = optionalNumber,
  maxHeight = optionalNumber,
  orientation = typeOptional(typeEitherValues("landscape", "portrait")),
  children = typeOptional(typeChildren),
  child = typeOptional(typeElement),
}

local defaultProps = {
  minWidth = 0,
  minHeight = 0,
  maxWidth = 2147483647,
  maxHeight = 2147483647,
}

return Component("love.MediaQuery", MediaQuery, propTypes, defaultProps)