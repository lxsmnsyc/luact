local luact = require "luact"
local timeout = require "timers.timeout"
local frame = require "timers.frame"
local idle = require "timers.init"

local System = luact.init({
  create_instance = function (self, constructor, props)
    return {
      constructor = constructor,
      props = props
    }
  end,
  append_child = function (self, parent, child)
    table.insert(parent, child)
  end,
  commit_update = function (self, instance, old_props, new_props)
    instance.props = new_props
  end,
  schedule = function (self, callback)
    idle.request(function (deadline)
      callback(deadline.timeRemaining())
    end)
  end,
})

function love.update(dt)
  timeout.update(dt)
  frame.update(dt)
end

local test = {}

local App = System.component(function ()
  local state, set_state = luact.use_state("Loading")

  timeout.request(function ()
    set_state("Success")
  end, 1000)

  return System.Fragment {
    System.Element("Hello", { test = state }),
    System.Element("Hello", { test = state }),
    System.Element("Hello", { test = state }),
    System.Element("Hello", { test = state }),
    System.Element("Hello", { test = state }),
    System.Element("Hello", { test = state }),
    System.Element("Hello", { test = state }),
  }
end)
System.render(App {}, test)

local function log(node, level)
	local s = "{"

  for k, v in pairs(node) do
		local result = ""
		if (type(v) == "table") then
			result = result..log(v, level + 1)
    else
			result = type(v).."("..tostring(v)..")"
		end
		s = s.."\n"..string.rep("  ", level + 1)..tostring(k)..": "..result..","
	end
	s = s.."\n"..string.rep("  ", level).."}"
	return s
end

function love.draw()
  love.graphics.print(log(test, 0))
end