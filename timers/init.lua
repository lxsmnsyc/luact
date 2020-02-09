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
local alloc, free = require("timers.recycler")()
local timeout = require "timers.timeout"
local frame = require "timers.frame"

local scheduleStart, throttleDelay, lazytimer, lazyraf
local runAttempts = 0
local isRunning = false
local remainingTime = 7
local minThrottle = 35
local throttle = 125
local taskStart = 0
local tasklength = 0
local tasks = {}
local index = 0

local IdleDeadline = {
  didTimeout = false,
  timeRemaining = function ()
    local timeRemaining = remainingTime - (os.clock() - taskStart)

    if (timeRemaining < 0) then
      return 0
    end
    return timeRemaining
  end,
}

local function debounce(fn)
  local id, timestamp
  local wait = 99
  local function check()
    local last = os.clock() - timestamp

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

local setInactive = debounce(function ()
  remainingTime = 22
  throttle = 66
  minThrottle = 0
end)


local function abortRunning()
  if(isRunning) then
    if(lazyraf) then
      frame.clear(lazyraf)
    end
    if(lazytimer) then
      timeout.clear(lazytimer)
    end
    isRunning = false
  end
end

local scheduleLazy

local function onInputorMutation()
  if(throttle ~= 125) then
    remainingTime = 7
    throttle = 125
    minThrottle = 35

    if(isRunning) then
      abortRunning()
      scheduleLazy()
    end
  end
  setInactive()
end

local function runTasks()
  local task
  local timeThreshold

  if (remainingTime > 9) then
    timeThreshold = 9
  else
    timeThreshold = 1
  end

  taskStart = os.clock()
  isRunning = false

  lazytimer = nil

  if (runAttempts > 2 or taskStart - throttleDelay - 50 < scheduleStart) then
    local i = 0
    local len = #tasks

    while (i <= len and IdleDeadline.timeRemaining() > timeThreshold) do
      task = table.remove(tasks, i)
      tasklength = tasklength + 1
      if (task) then
        task(IdleDeadline)
      end
      i = i + 1
    end
  end

  if (#tasks) then
    scheduleLazy()
  else
    runAttempts = 0
  end
end

local function scheduleAfterRaf()
  lazyraf = nil
  lazytimer = timeout.request(runTasks, 0)
end

local function scheduleRaf()
  lazytimer = nil
  frame.request(scheduleAfterRaf)
end

scheduleLazy = function ()
  if(isRunning) then
    return
  end
  throttleDelay = throttle - (os.clock() - taskStart)

  scheduleStart = os.clock()

  isRunning = true

  if(minThrottle and throttleDelay < minThrottle) then
    throttleDelay = minThrottle
  end

  if(throttleDelay > 9) then
    lazytimer = timeout.request(scheduleRaf, throttleDelay)
  else
    throttleDelay = 0
    scheduleRaf()
  end
end

local function request(task)
  index = index + 1
  table.insert(tasks, task)
  scheduleLazy()
  return index
end

local function cancel(id)
  index = id - 1 - tasklength
  if (tasks[index]) then
    tasks[index] = nil
  end
end

return {
  request = request,
  cancel = cancel,
  on_input = onInputorMutation,
}
