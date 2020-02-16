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
local update_element = require "luact.fiber.reconcile_children.update_element"
local delete_fiber = require "luact.fiber.reconcile_children.delete_fiber"

local weakmap = require "luact.utils.weakmap"

local function get_matching_fiber(current, index)
  if (current) then
    return current.map[index]
  end
  return nil
end

return function (current, work_in_progress, new_children)

  -- pointer to previous sibling
  local prev

  local function link_fiber(new_fiber, element)
    -- start linking the new fiber to the work
    -- in progress fiber (if it is the first child),
    -- or the previously created fiber.
    if (not work_in_progress.child) then
      work_in_progress.child = new_fiber
    elseif (element) then
      prev.sibling = new_fiber
    end

    prev = new_fiber
  end

  local marked = weakmap()

  if (new_children) then
    for index = 1, #new_children do
      -- get the current element
      local element = new_children[index]

      -- pointer
      local key
      if (element) then
        key = element.key
      end

      -- pointer to the new fiber
      local old_fiber = get_matching_fiber(current, key or index)
      local new_fiber = update_element(
        work_in_progress,
        old_fiber,
        element,
        index,
        key
      )

      if (old_fiber) then
        marked[old_fiber] = true
      end

      -- link resulting fiber
      link_fiber(new_fiber, element)
    end
  end

  -- delete remaining fiber
  if (current) then
    local old_fiber = current.child

    while (old_fiber) do
      if (not marked[old_fiber]) then
        local new_fiber = delete_fiber(
          work_in_progress,
          old_fiber,
          nil,
          old_fiber.index,
          old_fiber.key
        )
        link_fiber(new_fiber)
      end
      old_fiber = old_fiber.sibling
    end
  end
end