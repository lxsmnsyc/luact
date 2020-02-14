--[[
  @license
  MIT License

  Copyright (c) 2020 Alexis Munsayac
  Permission is hereby granted, free of charge, to any person obtaining a copy
  of this software and associated documentation files (the "Software"), to deal
  in the Software without restriction, including without limitation the rights
  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
  copies of the Software, and to permit persons to whom the Software is
  furnished to do so, subject to the following conditions:

  The above copyright notice and this permission notice shall be included in all
  copies or substantial portions of the Software.

  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
  SOFTWARE.


  @author Alexis Munsayac <alexis.munsayac@gmail.com>
  @copyright Alexis Munsayac 2020
--]]
local timeout = require "luact.timers.timeout"
local frame = require "luact.timers.frame"

local schedule_start, throttle_delay, lazy_timer, lazy_frame
local run_attempts = 0
local is_running = false
local remaining_time = 7
local min_throttle = 35
local throttle = 125
local task_start = 0
local task_size = 0
local tasks = {}
local index = 0

local idle_deadline = {
  did_timeout = false,
  time_remaining = function ()
    local time_remaining = remaining_time - ((os.clock() * 1000) - task_start)

    if (time_remaining < 0) then
      return 0
    end
    return time_remaining
  end,
}

local function debounce(fn)
  local id, timestamp
  local wait = 99
  local function check()
    local last = (os.clock() * 1000) - timestamp

    if (last < wait) then
      id = timeout.request(check, wait - last)
    else
      id = nil
      fn()
    end
  end
  return function()
    timestamp = os.clock()
    if(not id) then
      id = timeout.request(check, wait)
    end
  end
end

local set_inactive = debounce(function ()
  remaining_time = 22
  throttle = 66
  min_throttle = 0
end)


local function abort_running()
  if(is_running) then
    if(lazy_frame) then
      frame.clear(lazy_frame)
    end
    if(lazy_timer) then
      timeout.clear(lazy_timer)
    end
    is_running = false
  end
end

local schedule_lazy

local function prevent()
  if(throttle ~= 125) then
    remaining_time = 7
    throttle = 125
    min_throttle = 35

    if(is_running) then
      abort_running()
      schedule_lazy()
    end
  end
  set_inactive()
end

local function run_tasks()
  local task
  local time_threshold

  if (remaining_time > 9) then
    time_threshold = 9
  else
    time_threshold = 1
  end

  task_start = (os.clock() * 1000)
  is_running = false

  lazy_timer = nil

  if (run_attempts > 2 or task_start - throttle_delay - 50 < schedule_start) then
    local i = 0
    local len = #tasks

    while (i <= len and idle_deadline.time_remaining() > time_threshold) do
      task = table.remove(tasks, i)
      task_size = task_size + 1
      if (task) then
        task(idle_deadline)
      end
      i = i + 1
    end
  end

  if (#tasks) then
    schedule_lazy()
  else
    run_attempts = 0
  end
end

local function schedule_after_frame()
  lazy_frame = nil
  lazy_timer = timeout.request(run_tasks, 0)
end

local function schedule_raf()
  lazy_timer = nil
  frame.request(schedule_after_frame)
end

schedule_lazy = function ()
  if(is_running) then
    return
  end
  throttle_delay = throttle - ((os.clock() * 1000) - task_start)

  schedule_start = (os.clock() * 1000)

  is_running = true

  if(min_throttle and throttle_delay < min_throttle) then
    throttle_delay = min_throttle
  end

  if(throttle_delay > 9) then
    lazy_timer = timeout.request(schedule_raf, throttle_delay)
  else
    throttle_delay = 0
    schedule_raf()
  end
end

local function request(task)
  index = index + 1
  table.insert(tasks, task)
  schedule_lazy()
  return index
end

local function cancel(id)
  index = id - 1 - task_size
  if (tasks[index]) then
    tasks[index] = nil
  end
end

return {
  request = request,
  cancel = cancel,
  prevent = prevent,
}
