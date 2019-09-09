local Event = require "luact.src.event"

local Store = {}
Store.__index = Store

function Store.new(reducer, initialValue)
  assert(type(reducer) == "function", "Store.new: reducer must be a function")
  return setmetatable({
    event = Event.new(),
    reducer = reducer,
    value = initialValue,
  }, Store)
end

function Store:dispatch(action)
  self.value = self.reducer(self.value, action)
  self.event:dispatch(self.value)
end

function Store:subscribe(listener)
  self.event:addListener(listener)
end

function Store:unsubscribe(listener)
  self.event:removeListener(listener)
end

return Store
