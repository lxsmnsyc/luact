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

return function (current, work_in_progress, new_children)
  -- get the old fiber's child
  local old_fiber = current and current.child

  -- pointer to previous sibling
  local prev

  if (new_children) then
    -- iterate while index is below children or there is still more old child
    for i = 1, #new_children do
      local element = new_children[i]

      -- pointer to the new fiber
      local new_fiber = update_element(work_in_progress, old_fiber, element)

      -- If old fiber exists, get the next sibling
      if (old_fiber) then
        old_fiber = old_fiber.sibling
      end

      if (new_fiber) then
        if (not work_in_progress.child) then
          work_in_progress.child = new_fiber
        elseif (element) then
          prev.sibling = new_fiber
        end

        prev = new_fiber
      end
    end
  end

  while (old_fiber) do
    -- Mark old fiber as a deletion
    local new_fiber = delete_fiber(work_in_progress, old_fiber)
    if (not work_in_progress.child) then
      work_in_progress.child = new_fiber
    else
      prev.sibling = new_fiber
    end
    prev = new_fiber
    old_fiber = old_fiber.sibling
  end
end