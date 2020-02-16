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
local hooks = require "luact.hooks.context"
local safely_render = require "luact.fiber.begin_work.safely_render"
local read_context = require "luact.context.read"

local weakmap = require "luact.utils.weakmap"

local CHILDREN = weakmap()

local function initial_render(current, work_in_progress)
  hooks.render(current, work_in_progress)

  local result = safely_render(work_in_progress, function ()
    return work_in_progress.constructor(work_in_progress.props)
  end)

  hooks.end_render()

  if (result) then
    local children = { result }
    CHILDREN[work_in_progress] = children
    reconcile_children(current, work_in_progress, children)
    return work_in_progress.child
  end
  return nil
end

return function (current, work_in_progress)
  if (current) then
    local should_update = current.should_update

    if (not should_update) then
      local deps = current.dependencies
      for context_type in pairs(deps) do
        local instance = read_context(work_in_progress, context_type)

        if (instance.should_update) then
          should_update = true
          break
        end
      end
    end
    -- Check if props is not equal
    if (should_update or not shallow_equal(work_in_progress.props, current.props)) then
      initial_render(current, work_in_progress)
    else
      local children = CHILDREN[current]
      CHILDREN[work_in_progress] = children
      -- render with old children
      reconcile_children(current, work_in_progress, children)
    end
  else
    initial_render(current, work_in_progress)
  end
  return work_in_progress.child
end
