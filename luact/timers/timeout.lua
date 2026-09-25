-- Timeouts, like setTimeout.
--
-- Time only moves forward when `update(dt)` is called, so timeouts follow
-- the game clock.

local M = {}

local timers = {}
local entries = {}
local next_id = 0

-- Calls `callback` once `delay` milliseconds have passed. Returns an id for
-- `clear`.
function M.request(callback, delay)
  next_id = next_id + 1
  local entry = { id = next_id, callback = callback, remaining = (delay or 0) / 1000 }
  timers[#timers + 1] = entry
  entries[next_id] = entry
  return next_id
end

function M.clear(id)
  local entry = entries[id]
  if entry ~= nil then
    entry.callback = nil
    entries[id] = nil
  end
end

-- Advances time by `dt` seconds and runs the timeouts that are due, in the
-- order they were requested.
function M.update(dt)
  local current = timers
  timers = {}
  local due = {}
  for i = 1, #current do
    local entry = current[i]
    if entry.callback ~= nil then
      entry.remaining = entry.remaining - dt
      if entry.remaining <= 0 then
        due[#due + 1] = entry
      else
        timers[#timers + 1] = entry
      end
    end
  end
  for i = 1, #due do
    local entry = due[i]
    local callback = entry.callback
    if callback ~= nil then
      entry.callback = nil
      entries[entry.id] = nil
      callback()
    end
  end
end

return M
