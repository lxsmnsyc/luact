-- Luact renderer for LÖVE (11.x).
--
--   local luact = require "luact"
--   local luact_love = require "luact-love"
--
--   function love.load()
--     luact_love.install(luact.create_element(App))
--   end
--
-- `install` takes over love.update, love.draw and the input callbacks. To
-- keep your own callbacks, call `update`, `draw` and `emit` from them
-- instead.

local luact = require "luact"
local timers = require "luact.timers"
local host = require "luact-love.host"
local draw = require "luact-love.draw"

local M = {}

M.renderer = luact.create_renderer(host)
M.painters = draw.painters

-- The container of the default root.
M.stage = { type = "stage", children = {} }

-- Milliseconds of each frame spent rendering, at most.
M.frame_budget = 8

local root = nil

-- Returns the root that renders into `stage`.
function M.get_root()
  if root == nil then
    root = M.renderer.create_root(M.stage)
  end
  return root
end

function M.render(element)
  M.get_root():render(element)
end

-- Event listeners

local listeners = {}

function M.subscribe(name, listener)
  local set = listeners[name]
  if set == nil then
    set = {}
    listeners[name] = set
  end
  set[listener] = true
  return function ()
    set[listener] = nil
  end
end

-- Sends a LÖVE event (such as "keypressed") to every subscribed listener.
function M.emit(name, ...)
  local set = listeners[name]
  if set == nil then
    return
  end
  local snapshot = {}
  for listener in pairs(set) do
    snapshot[#snapshot + 1] = listener
  end
  for i = 1, #snapshot do
    if set[snapshot[i]] then
      snapshot[i](...)
    end
  end
end

-- Calls `handler(...)` for each LÖVE event `name` while the component is
-- mounted. The handler can change between renders.
function M.use_event(name, handler)
  local latest = luact.use_ref(handler)
  luact.use_layout_effect(function ()
    latest.current = handler
  end)
  luact.use_effect(function ()
    return M.subscribe(name, function (...)
      latest.current(...)
    end)
  end, { name })
end

-- Frame loop

-- Advances timers and renders pending updates within `frame_budget`.
function M.update(dt)
  timers.update(dt)
  M.emit("update", dt)
  local get_time = love.timer.getTime
  local start = get_time()
  M.renderer.work_loop(function ()
    return M.frame_budget - (get_time() - start) * 1000
  end)
end

function M.draw()
  draw.draw_container(M.stage)
end

M.EVENTS = {
  "keypressed", "keyreleased", "textinput", "textedited",
  "mousemoved", "mousepressed", "mousereleased", "wheelmoved",
  "touchpressed", "touchreleased", "touchmoved",
  "gamepadpressed", "gamepadreleased", "gamepadaxis",
  "joystickpressed", "joystickreleased", "joystickaxis", "joystickhat",
  "joystickadded", "joystickremoved",
  "focus", "mousefocus", "visible", "resize",
  "filedropped", "directorydropped",
}

-- Renders `element` and sets love.update, love.draw and the input
-- callbacks to drive Luact.
function M.install(element)
  love.update = M.update
  love.draw = M.draw
  for i = 1, #M.EVENTS do
    local name = M.EVENTS[i]
    love[name] = function (...)
      M.emit(name, ...)
    end
  end
  M.render(element)
  return M.get_root()
end

return M
