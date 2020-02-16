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

local create_fiber = require "luact.fiber.create"

return function (parent, old_fiber, element, index, key)
  local fiber

  if (element) then
    fiber = create_fiber(element.reconciler, element.type, element.props)

    fiber.constructor = element.constructor
    fiber.work = tags.work.REPLACEMENT
  else
    fiber = create_fiber(old_fiber.reconciler, old_fiber.type, old_fiber.props)

    fiber.constructor = old_fiber.constructor
    fiber.work = tags.work.DELETE
    fiber.instance = old_fiber.instance
  end

  fiber.parent = parent
  fiber.alternate = old_fiber
  fiber.index = index
  fiber.key = key

  parent.map[key or index] = fiber

  return fiber
end