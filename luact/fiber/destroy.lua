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
local error_registry = require "luact.fiber.error_registry"
local hooks = require "luact.hooks.context"

local function destroy(fiber)
  if (not fiber) then
    return
  end
  local alternate = fiber.alternate
  local child = fiber.child
  local sibling = fiber.sibling

  error_registry.clear_errors(fiber)
  hooks.clear_hooks(fiber)

  fiber.reconciler = nil
  fiber.constructor = nil
  fiber.type = nil
  fiber.props = nil
  fiber.parent = nil
  fiber.work = nil
  fiber.alternate = nil
  fiber.instance = nil
  fiber.index = nil
  fiber.key = nil
  fiber.map = nil
  fiber.dependencies = nil
  fiber.child = nil
  
  destroy(alternate)
  destroy(child)
  destroy(sibling)
end

return destroy