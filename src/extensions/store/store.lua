local Event = require "luact.src.event"

local Store = {}
Store.__index = Store

function Store.new(reducer, initialValue)
  assert(type(reducer) == "function", "STo
end

