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
local typeElement = require "luact.src.types.element"
local typeTable = require "luact.src.types.table"

local ELEMENT = require "luact.src.meta.ELEMENT"
local NAMES = require "luact.src.meta.NAMES"

local function log(node, level)
	local s = "{"

	for k, v in pairs(node) do
		local result = ""
		if (typeTable(v)) then
      if (typeElement(v)) then
        result = NAMES[ELEMENT[v]]
      end
			result = result..log(v, level + 1)
    else
			result = type(v).."("..tostring(v)..")"
		end
		s = s.."\n"..string.rep("  ", level + 1)..tostring(k)..": "..result..","
	end
	s = s.."\n"..string.rep("  ", level).."}"
	return s
end

return function (node)
  return log(node, 0)
end