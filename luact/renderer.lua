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
local Fiber = require "luact.fiber"
local tags = require "luact.tags"

return function (reconciler)
  local deletion
  local function push_for_deletion(fiber)
    table.insert(deletion, fiber)
  end

  local wip_root
  local current_root

  local function commit_root()
    for _, fiber in ipairs(deletion) do
      fiber:commit_work()
    end
    if (wip_root.child) then
      wip_root.child:commit_work()
    end
    current_root = wip_root
    wip_root = nil
  end

  local next_unit_of_work
  local function work_loop(deadline)
    local should_yield = false

    while (next_unit_of_work and not should_yield) do
      next_unit_of_work = next_unit_of_work:perform_unit_of_work()

      should_yield = deadline < 1
    end

    if ((not next_unit_of_work) and wip_root) then
      commit_root()
    end

    reconciler:schedule(work_loop)
  end

  local function render(element, container)
    wip_root = Fiber.new {
      type = tags.type.ROOT,
      reconciler = reconciler,
      instance = container,
      props = {
        children = { element },
      },
      alternate = current_root,
    }
    deletion = {}
    next_unit_of_work = wip_root
  end

  local function update()
    wip_root = Fiber.new {
      type = tags.type.ROOT,
      reconciler = reconciler,
      instance = current_root.instance,
      props = current_root.props,
      alternate = current_root,
    }
    deletion = {}
    next_unit_of_work = wip_root
  end

  reconciler:schedule(work_loop)

  reconciler.render = render
  reconciler.update = update
  reconciler.push_for_deletion = push_for_deletion
end