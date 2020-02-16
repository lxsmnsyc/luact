
local function log(node, level)
	local s = "{"

  for k, v in pairs(node) do
		local result = ""
		if (k == "reconciler") then
			result = "[[RECONCILER]]"
		else
      result = type(v).."("..tostring(v)..")"
		end
		s = s.."\n"..string.rep("  ", level + 1)..tostring(k)..": "..result..","
	end
	s = s.."\n"..string.rep("  ", level).."}"
	return s
end

return log