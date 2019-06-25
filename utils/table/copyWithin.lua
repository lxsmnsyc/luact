local is = require "luact.utils.is"

local isTable = is.table
local isNumber = is.number

return function (self, target, lo, hi)
  assert(isTable(self), "bad argument #1 for copyWithin")
end