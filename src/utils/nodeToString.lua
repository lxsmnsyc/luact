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