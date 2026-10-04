local M = {}

-- Same-value equality. Like `==`, except NaN equals NaN.
function M.object_is(a, b)
  if a == b then
    return true
  end
  -- NaN is the only value not equal to itself
  return a ~= a and b ~= b
end

-- Compares the keys and values of two tables, one level deep.
-- Keys holding nil are absent from both tables, so `{ nil, 1 }` and `{ 2, 1 }`
-- are different while `{ nil, 1 }` and `{ [2] = 1 }` are equal.
function M.shallow_equal(a, b)
  if M.object_is(a, b) then
    return true
  end
  if type(a) ~= "table" or type(b) ~= "table" then
    return false
  end
  for k, v in pairs(a) do
    if not M.object_is(v, b[k]) then
      return false
    end
  end
  for k in pairs(b) do
    if a[k] == nil then
      return false
    end
  end
  return true
end

return M
