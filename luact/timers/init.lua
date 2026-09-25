-- Frame and timeout helpers driven by the host's clock.

local frame = require "luact.timers.frame"
local timeout = require "luact.timers.timeout"

return {
  frame = frame,
  timeout = timeout,
  -- Advances both timers. Call it once per frame with the frame time in
  -- seconds.
  update = function (dt)
    frame.update(dt)
    timeout.update(dt)
  end,
}
