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

local typePoints = require "luact.src.extensions.love-2d.types.points"

local typeIntersect = require "luact.src.types.intersect"
local typeTableOf = require "luact.src.types.tableOf"
local typeNumber = require "luact.src.types.number"
local typeTableLength = require "luact.src.types.tableLength"
local typeExact = require "luact.src.types.exact"
local typeEither = require "luact.src.types.either"

local typePoint1 = typeIntersect(typeTableOf(typeNumber), typeTableLength(2))

local typePoint2 = typeExact({
  x = typeNumber, y = typeNumber,  
})

local function flatten(points)
  local result = {}
  
  local index = 0
  
  for i = 1, #points do
    local point = points[i]
    
    if (typePoint1(point)) then
      index = index + 1
      result[index * 2 - 1] = point[1]
      result[index * 2] = point[2]
    elseif (typePoint2(point)) then
      index = index + 1
      result[index * 2 - 1] = point.x
      result[index * 2] = point.y
    end
  end
  
  return result
end

local function Line(props)
  local points = flatten(props.points)
  
  return {
    draw = function ()
      love.graphics.line(points)
    end
  }
end

local propTypes = {
  points = typePoints,
}

return Component("love.Line", Line, propTypes)
