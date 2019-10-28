--[[
    Luact
	
    MIT License
    Copyright (c) 2019 Alexis Munsayac
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
--]]
local weakmap = require "luact.src.utils.weakmap"

--[[
  Maximum time to finish all futures
  
  Futures who are pass the DEADLINE mark is deferred
  to the next cycle.
--]]
local DEADLINE = 1./60.

local Future = {}
Future.__index = Future

local properties = weakmap()

local tasksCount = 0
local tasks = {}

local PENDING = 0
local FULFILLED = 1
local REJECTED = 2

local function newTask(task)
  tasksCount = tasksCount + 1
  tasks[tasksCount] = task
end

function Future.new(supplier)
  local task = setmetatable({}, Future)
  
  local property = {}
  properties[task] = property

  property.state = PENDING
  property.value = nil
  
  local onFulfill = {}
  local onReject = {}
  
  property.onFulfill = onFulfill
  property.onReject = onReject
  
  local function forcedResolve(val)
    property.state = FULFILLED
    property.value = val
    
    for i = 1, #onFulfill do
      newTask(function ()
        onFulfill[i](val)
      end)
    end
  end

  local function forcedReject(val)
    property.state = REJECTED
    property.value = val
    
    if (#onReject == 0) then
      error(val)
    end

    for i = 1, #onReject do
      newTask(function ()
        onReject[i](val)
      end)
    end
  end
  
  local function resolve(value)
    if (property.state == PENDING) then
      if (getmetatable(value) == Future) then
        value:andThen(forcedResolve, forcedReject)
      else
        forcedResolve(value)
      end
    end
  end
  
  local function reject(value)
    if (property.state == PENDING) then
      if (getmetatable(value) == Future) then
        value:andThen(forcedReject, forcedReject)
      else
        forcedReject(value)
      end
    end
  end
  
  newTask(function ()
    local status, result = pcall(supplier, resolve, reject)
    
    if (status) then
      if (result ~= nil) then
        resolve(result)
      end
    else
      reject(result)
    end
  end)
  
  return task
end

function Future.resolved(value)
  return Future.new(function ()
    return value
  end)
end

function Future.rejected(value)
  return Future.new(function ()
    error(value)
  end)
end

function Future:andThen(onFulfill, onReject)
  local property = properties[self]

  local validOnFulfill = type(onFulfill) == "function"
  local validOnReject = type(onReject) == "function"
  
  if (property.state == FULFILLED) then
    return Future.new(function ()
      if (validOnFulfill) then
        return onFulfill(property.value)
      end
      return property.value
    end)
  end
  if (property.state == REJECTED) then
    return Future.new(function ()
      if (validOnReject) then
        return onReject(property.value)
      end
      error(property.value)
    end)
  end
  if (property.state == PENDING) then
    local fstack = property.onFulfill
    local rstack = property.onReject
    
    local deferred = {}
    
    fstack[#fstack + 1] = function (value)
      if (validOnFulfill) then
        deferred.resolve(onFulfill(value))
      else
        deferred.resolve(value)
      end
    end
    rstack[#rstack + 1] = function (value)
      if (validOnReject) then
        deferred.reject(onReject(value))
      else
        deferred.reject(value)
      end
    end
    return Future.new(function (resolve, reject)
      deferred.resolve = resolve
      deferred.reject = reject
    end)
  end
end

local lastIndex = 1

local function resetTasks()
  tasks = {}
  tasksCount = 0
  lastIndex = 1
end

local function type1Drain()
  local i = 1
  while (i <= tasksCount) do
    tasks[i]()
    i = i + 1
  end
  resetTasks()
end

local function type2Drain(deadline)
  local start = os.clock()
  deadline = deadline or DEADLINE
  local i = lastIndex
  while (i <= tasksCount) do
    tasks[i]()
    i = i + 1
    if ((os.clock() - start) >= deadline and i <= tasksCount) then
      lastIndex = i
      return
    end
  end
  resetTasks()
end

function Future.drain(deadline, typeDrain)
  typeDrain = typeDrain or 1
  if (typeDrain == 1) then
    type1Drain()
  end
  if (typeDrain == 2) then
    type2Drain(deadline)
  end
end

Future.DEADLINE = DEADLINE

return Future
