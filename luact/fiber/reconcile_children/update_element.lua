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

local delete_fiber = require "luact.fiber.reconcile_children.delete_fiber"

local create_fiber = require "luact.fiber.create"
local destroy_fiber = require "luact.fiber.destroy"

local function update_fiber_from_element(parent, old_fiber, element, index, key)
  local fiber = create_fiber(old_fiber.reconciler, old_fiber.type, element.props)

  fiber.constructor = old_fiber.constructor
  fiber.parent = parent
  destroy_fiber(old_fiber.alternate)
  old_fiber.alternate = nil
  fiber.alternate = old_fiber
  fiber.work = tags.work.UPDATE
  fiber.instance = old_fiber.instance
  fiber.index = index
  fiber.key = key

  parent.map[key or index] = fiber
  return fiber
end

local function create_fiber_from_element(parent, element, index, key)
  local fiber = create_fiber(element.reconciler, element.type, element.props)

  fiber.constructor = element.constructor
  fiber.parent = parent
  fiber.work = tags.work.PLACEMENT
  fiber.index = index
  fiber.key = key

  parent.map[key or index] = fiber
  return fiber
end

return function (parent, old_fiber, element, index, key)
  if (old_fiber) then
    if (old_fiber.work == tags.work.DELETE and element) then
      return create_fiber_from_element(parent, element, index, key)
    end
    if (not element) then
      return delete_fiber(parent, old_fiber, element, index, key)
    end
    if (element.type ~= old_fiber.type) then
      return delete_fiber(parent, old_fiber, element, index, key)
    end
    if (element.constructor ~= old_fiber.constructor) then
      return delete_fiber(parent, old_fiber, element, index, key)
    end
    return update_fiber_from_element(parent, old_fiber, element, index, key)
  end
  if (element) then
    return create_fiber_from_element(parent, element, index, key)
  end
  return nil
end
