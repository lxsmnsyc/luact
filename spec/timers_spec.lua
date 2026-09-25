local timers = require "luact.timers"

local frame = timers.frame
local timeout = timers.timeout

describe("frame", function ()
  it("runs a callback once on the next update", function ()
    local calls = {}
    frame.request(function (dt)
      calls[#calls + 1] = dt
    end)
    frame.update(0.016)
    frame.update(0.016)
    assert.are.same({ 16 }, calls)
  end)

  it("runs callbacks requested during update on the next update", function ()
    local count = 0
    local function tick()
      count = count + 1
      frame.request(tick)
    end
    frame.request(tick)
    frame.update(0.016)
    frame.update(0.016)
    assert.are.equal(2, count)
    frame.update(0)
  end)

  it("can be cleared", function ()
    local called = false
    local id = frame.request(function ()
      called = true
    end)
    frame.clear(id)
    frame.update(0.016)
    assert.is_false(called)
  end)
end)

describe("timeout", function ()
  it("runs after the delay", function ()
    local called = 0
    timeout.request(function ()
      called = called + 1
    end, 100)
    timeout.update(0.05)
    assert.are.equal(0, called)
    timeout.update(0.05)
    assert.are.equal(1, called)
    timeout.update(1)
    assert.are.equal(1, called)
  end)

  it("runs due timeouts in request order", function ()
    local order = {}
    timeout.request(function () order[#order + 1] = "a" end, 20)
    timeout.request(function () order[#order + 1] = "b" end, 10)
    timeout.update(0.1)
    assert.are.same({ "a", "b" }, order)
  end)

  it("can be cleared", function ()
    local called = false
    local id = timeout.request(function ()
      called = true
    end, 10)
    timeout.clear(id)
    timeout.update(1)
    assert.is_false(called)
  end)
end)
