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
local read_context = require "luact.context.read"
local safely_render = require "luact.fiber.begin_work.safely_render"

local weakmap = require "luact.utils.weakmap"

local CHILDREN = weakmap()

return function (current, work_in_progress)
  local props = work_in_progress.props

  local result = safely_render(work_in_progress, function ()
    local context = read_context(work_in_progress, props.owner)

    local children
    if (context.should_update) then
      children = props.consume(context.value)
    else
      children = CHILDREN[current]
    end

    CHILDREN[work_in_progress] = children

    return children
  end)

  if (result) then
    reconcile_children(current, work_in_progress, { result })
    return work_in_progress.child
  end
  return nil
end
