local luact = require "luact"
local timeout = require "luact.timers.timeout"
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
  append_child = function (self, parent, child, index)
    parent.children[index] = child
  end,
  commit_update = function (self, instance, old_props, new_props)
    instance.props = new_props
  end,
  remove_child = function (self, parent, child, index)
    parent.children[index] = nil
  end,
})

function love.update(dt)
  luact.update_frame(dt)
end

local test = { children = { }}

local LifecycleDemo = System.component(function (props)
  return System.Element("Hello World", {
    key = props.key,
    lifetime = props.lifetime,
  })
end)


local Example = System.component(function (props)
  local state, set_state = luact.use_state(true)

  local lifetime = 1000 + 1000 * math.random()

  luact.use_layout_effect(function ()
    timeout.request(function ()
      set_state(not state)
    end, lifetime)
  end, {state})

  if (state) then
    return LifecycleDemo {
      key = props.key,
      lifetime = lifetime,
    }
  end
  return nil
end)

local App = System.basic(function ()
  return System.Fragment {
    Example { key = 1 },
    Example { key = 2 },
    Example { key = 3 },
    Example { key = 4 },
    Example { key = 5 },
    Example { key = 6 },
    Example { key = 7 },
  }
end)

System.render(App {}, test)

function love.draw()
  love.graphics.print(logs(test, 0))
end
