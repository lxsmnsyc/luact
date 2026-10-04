-- State, effects and context with the test renderer, driven by a fake clock.
--
-- Run from the repository root:
--   lua examples/console/counter.lua

package.path = "./?.lua;./?/init.lua;" .. package.path

local luact = require "luact"
local timers = require "luact.timers"
local test_renderer = require "luact.test_renderer"

local h = luact.create_element

local Step = luact.create_context(1)

-- Counts up every `interval` milliseconds by the step from context.
local function Counter(props)
  local count, set_count = luact.use_state(0)
  local step = luact.use_context(Step)

  luact.use_effect(function ()
    local id
    local function tick()
      set_count(function (current)
        return current + step
      end)
      id = timers.timeout.request(tick, props.interval)
    end
    id = timers.timeout.request(tick, props.interval)
    -- stop the timer when the component unmounts or the step changes
    return function ()
      timers.timeout.clear(id)
    end
  end, { step, props.interval })

  return h("counter", { label = props.label, count = count })
end

local function App(props)
  return h(Step, { value = props.step },
    h(Counter, { label = "fast", interval = 100 }),
    h(Counter, { label = "slow", interval = 300 })
  )
end

local instance = test_renderer.create(h(App, { step = 1 }))

-- Simulates `seconds` of time at 60 frames per second.
local function advance(seconds)
  local frames = math.floor(seconds * 60)
  for _ = 1, frames do
    test_renderer.act(function ()
      timers.update(1 / 60)
    end)
  end
end

print(instance:to_string())
advance(1)
print(instance:to_string())

instance:update(h(App, { step = 10 }))
advance(1)
print(instance:to_string())

instance:unmount()
