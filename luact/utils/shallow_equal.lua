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
local function key_set(obj)
  local result = {}

  for k in pairs(obj) do
    result[k] = true
  end

  return result
end

local function keys(obj)
  local result = {}
  local count = 0

  for k in pairs(obj) do
    count = count + 1
    result[count] = k
  end

  return result
end

local function shallow_equal(a, b)
  -- Check if both values are tables
  if (type(a) ~= "table" or type(b) ~= "table") then
    if (type(a) == type(b)) then
      return a == b
    end
    return false
  end
  -- Check if both tables have the same amount of keys
  local a_keys = keys(a)
  local b_keys = keys(b)

  if (#a_keys ~= #b_keys) then
    return false
  end

  -- Get keyset
  local a_kset = key_set(a)
  local b_kset = key_set(b)
  local visited = {}

  -- Iterate keys
  for i = 1, #a_keys do
    local a_key = a_keys[i]
    local b_key = b_keys[i]

    -- Check if key is visited
    if (not visited[a_key]) then
      -- Check if key from a exists in b
      if (not b_kset[a_key]) then
        return false
      end
      -- Check if value of the same key is equal
      if (b[a_key] ~= a[a_key]) then
        return false
      end
      visited[a_key] = true
    end

    -- Check if key is visited
    if (not visited[b_key]) then
      -- Check if key from a exists in b
      if (not a_kset[b_key]) then
        return false
      end
      -- Check if value of the same key is equal
      if (b[b_key] ~= a[b_key]) then
        return false
      end
      visited[b_key] = true
    end
  end

  return true
end

return shallow_equal