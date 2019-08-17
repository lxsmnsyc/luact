local el = require "luact.src.el"

local render = require "luact.src.renderer.render"
local useState = require "luact.src.hooks.useState"
local scheduler = require "luact.src.scheduler"

local function div(props, children)
	return {
		element = "div",
		props = props,
		children = children,
	}
end

local function App(props, children)
	local counter, setCounter = useState(0)
	setCounter(1)
	setCounter(2)
	setCounter(3)
	setCounter(4)
	
	print(counter)
	return {
		el(div, {}, "Counter value: "..counter),
		el(div, {}, "Next value: "..(counter + 1)),
	}
end

local function Container()
	return {}
end

local container = el(Container, {}, {})
render(el(App, {}, {}), container)


local function logTable(tbl, lvl)
	local s = "{"
	for k, v in pairs(tbl) do
		local result
		if (type(v) == "table") then
			result = logTable(v, lvl + 1)
		else
			result = tostring(v)
		end
		s = s.."\n"..string.rep("  ", lvl + 1)..k..": "..result..","
	end
	s = s.."\n"..string.rep("  ", lvl).."}"
	return s
end

print(logTable(container, 0))
scheduler.drain()
print(logTable(container, 0))

