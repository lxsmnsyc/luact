-- Frame callbacks, like requestAnimationFrame.
--
-- A callback requested with `request` runs once, on the next call to
-- `update`. Callbacks requested while `update` runs wait for the next call.

local M = {}

local pending = {}
local entries = {}
local next_id = 0

-- Schedules `callback(dt_ms)` for the next frame. Returns an id for `clear`.
function M.request(callback)
  next_id = next_id + 1
  local entry = { id = next_id, callback = callback }
  pending[#pending + 1] = entry
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

-- Runs the callbacks requested before this call. `dt` is in seconds.
function M.update(dt)
  local batch = pending
  pending = {}
  local dt_ms = dt * 1000
  for i = 1, #batch do
    local entry = batch[i]
    local callback = entry.callback
    if callback ~= nil then
      entries[entry.id] = nil
      callback(dt_ms)
    end
  end
end

return M
