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

local update_with_constructor = require "luact.fiber.reconcile_children.update_with_constructor"
local update_without_constructor = require "luact.fiber.reconcile_children.update_without_constructor"
local delete_fiber = require "luact.fiber.reconcile_children.delete_fiber"

return function (parent, old_fiber, element)
  local new_type = element.type
  if (
    new_type == tags.type.BASIC
    or new_type == tags.type.COMPONENT
    or new_type == tags.type.HOST
    or new_type == tags.type.MEMO
    or new_type == tags.type.MEMO_BASIC
  ) then
    return update_with_constructor(parent, old_fiber, element)
  end
  if (new_type == tags.type.FRAGMENT or new_type == tags.type.ROOT) then
    return update_without_constructor(parent, old_fiber, element)
  end
  if (old_fiber) then
    return delete_fiber(parent, old_fiber)
  end
  return nil
end