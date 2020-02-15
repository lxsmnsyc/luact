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
local tags = require "luact.tags"
local logs = require "luact.utils.logs"

local weakmap = require "luact.utils.weakmap"

local HOOKS = weakmap()

local wip_fiber
local wip_hooks

local function render(current, work_in_progress)
  wip_fiber = work_in_progress
  wip_hooks = 0

  if (current) then
    HOOKS[work_in_progress] = HOOKS[current]
  else
    HOOKS[work_in_progress] = {}
  end
end

local function end_render()
  wip_fiber = nil
  wip_hooks = 0
end

local function create_hook(tag)
  assert(wip_fiber ~= nil, "Hook called outside Luact component.")

  wip_hooks = wip_hooks + 1

  local slot = HOOKS[wip_fiber][wip_hooks]

  if (slot) then
    assert(slot.type == tag, "Hook has an incompatible slot.")
  else
    slot = {
      type = tag,
    }
    HOOKS[wip_fiber][wip_hooks] = slot
  end

  return slot
end

local function current_fiber()
  return wip_fiber
end

local function for_each(work_in_progress, handler)
  local slot = HOOKS[work_in_progress]

  if (slot) then
    for i = 1, #slot do
      handler(slot[i])
    end
  end
end

return {
  render = render,
  end_render = end_render,
  create_hook = create_hook,
  current_fiber = current_fiber,
  for_each = for_each
}