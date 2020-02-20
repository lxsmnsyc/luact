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
local reconcile_children = require "luact.fiber.reconcile_children"
local shallow_equal = require "luact.utils.shallow_equal"
local safely_render = require "luact.fiber.begin_work.safely_render"

local weakmap = require "luact.utils.weakmap"

local CHILDREN = weakmap()

local function initial_render(current, work_in_progress)
  local result = safely_render(work_in_progress, function ()
    return work_in_progress.constructor(work_in_progress.props)
  end)

  if (result) then
    local children = { result }
    CHILDREN[work_in_progress] = children
    return reconcile_children(current, work_in_progress, children)
  end
  return nil
end

return function (current, work_in_progress)
  if (current) then
    -- Check if props is not equal
    if (not shallow_equal(work_in_progress.props, current.props)) then
      return initial_render(current, work_in_progress)
    else
      local children = CHILDREN[current]
      CHILDREN[work_in_progress] = children
      CHILDREN[current] = nil
      -- render with old children
      return reconcile_children(current, work_in_progress, children)
    end
  end
  return initial_render(current, work_in_progress)
end
