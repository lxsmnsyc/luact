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
local alloc, free = require("luact.timers.recycler")()

local next_node = {}
local prev_node = {}

local callbacks = {}
local next_pass = {}

local function request(callback)
  local id = alloc()

  local prev = prev_node[0] or 0
  next_node[id] = nil
  prev_node[id] = prev
  next_node[prev] = id
  prev_node[0] = id

  next_pass[id] = true
  callbacks[id] = callback

  return id
end

local function clear(id)
  if (free(id)) then
    next_node[prev_node[id] or 0] = next_node[id]
    prev_node[next_node[id] or 0] = prev_node[id]

    callbacks[id] = nil
  end
end

local function update(dt)
  local node = next_node[0]

  while (node) do
    if (not next_pass[node]) then
      callbacks[node](dt * 1000)
      clear(node)
    end
    node = next_node[node]
  end
  node = next_node[0]
  while (node) do
    if (next_pass[node]) then
      next_pass[node] = false
    end
    node = next_node[node]
  end
end

return {
  request = request,
  clear = clear,
  update = update
}