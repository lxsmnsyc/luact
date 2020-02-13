local luact = require "luact"
local timeout = require "timers.timeout"
local frame = require "timers.frame"
local idle = require "timers.init"
local logs = require "luact.utils.logs"

-- Render/Reconciler engine
local System = luact.init({
  create_instance = function (self, constructor, props)
    return {
      constructor = constructor,
      props = props,
      children = {},
    }
  end,
  append_child = function (self, parent, child)
    table.insert(parent.children, child)
  end,
  commit_update = function (self, instance, old_props, new_props)
    instance.props = new_props
  end,
  remove_child = function (self, parent, child)
    for k, v in pairs(parent.children) do
      if (v == child) then
        table.remove(parent.children, k)
      end
    end
  end,
  schedule = function (self, callback)
    idle.request(function (deadline)
      callback(deadline.timeRemaining)
    end)
  end,
})

function love.update(dt)
  timeout.update(dt)
  frame.update(dt)
end

local test = { children = { }}

local LifecycleDemo = System.component(function ()
  luact.use_layout_effect(function ()
    return function ()
      error("Unmounted!")
    end
  end, {})

  return System.Element("Hello World", { })
end)

local Example = System.component(function ()
  local state, set_state = luact.use_state(true)

  timeout.request(function ()
    set_state(false)
  end, 1000 + 1000 * math.random())

  if (state) then
    return LifecycleDemo {}
  end
  return nil
end)

local App = System.basic(function ()
  return System.Fragment {
    Example {},
    Example {},
    Example {},
    Example {},
  }
end)

System.render(App {}, test)

function love.draw()
  love.graphics.print(logs(test, 0))
end
