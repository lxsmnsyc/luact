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
local hooks = require "luact.hooks.context"
local shallow_equal = require "luact.utils.shallow_equal"

local Fiber = {}
Fiber.__index = Fiber

function Fiber.new(instance)
  return setmetatable(instance, Fiber)
end

local function create_fiber(fiber, fiber_type, props, constructor, config)
  return Fiber.new {
    reconciler = fiber.reconciler,
    type = fiber_type,
    constructor = constructor,
    props = props,
    parent = fiber,
    work_tag = tags.work.PLACEMENT,
    config = config,
  }
end

local function update_fiber(fiber, props, alternate)
  return Fiber.new {
    reconciler = alternate.reconciler,
    type = alternate.type,
    constructor = alternate.constructor,
    instance = alternate.instance,
    props = props,
    parent = fiber,
    work_tag = tags.work.UPDATE,
    alternate = alternate,
    config = alternate.config,
  }
end

local function reconcile_children(fiber, elements)
  local old_fiber = fiber.alternate and fiber.alternate.child
  local prev

  if (not elements) then
    return
  end
  local index = 1

  while (index <= #elements or old_fiber ~= nil) do
    -- get the element
    local element = elements[index]

    -- pointer to the new fiber
    local new_fiber

    -- compare types
    local same_type = old_fiber and element and element.type == old_fiber.type

    -- if they are of the same type, perform the reconcilation
    if (same_type) then
      local el_type = element.type
      -- Fragments should always update
      if (el_type == tags.type.FRAGMENT) then
        new_fiber = update_fiber(fiber, element.props, old_fiber)
      end

      -- Perform update logic for components
      if (
        el_type == tags.type.COMPONENT
        or el_type == tags.type.BASIC
        or el_type == tags.type.HOST
      ) then
        local same_constructor = element.constructor == old_fiber.constructor
        -- Components should have the same constructors
        if (same_constructor) then
          -- If constructors are the same, perform a shallow prop comparison
          new_fiber = update_fiber(fiber, element.props, old_fiber)
        else
          if (element) then
            new_fiber = create_fiber(fiber, element.type, element.props, element.constructor, element.config)
          end
          if (old_fiber) then
            -- Unmount element
            old_fiber.work_tag = tags.work.DELETE
            old_fiber.reconciler.push_for_deletion(old_fiber)
          end
        end
      end
    else
      if (element) then
        new_fiber = create_fiber(fiber, element.type, element.props, element.constructor, element.config)
      end
      if (old_fiber) then
        -- Unmount element
        old_fiber.work_tag = tags.work.DELETE
        old_fiber.reconciler.push_for_deletion(old_fiber)
      end
    end

    if (old_fiber) then
      old_fiber = old_fiber.sibling
    end

    if (index == 1) then
      fiber.child = new_fiber
    elseif (element) then
      prev.sibling = new_fiber
    end

    prev = new_fiber

    index = index + 1
  end
end

-- Work classification for components
local WORK = {
  [tags.type.COMPONENT] = function (fiber)
    hooks.render_with_hooks(fiber)
    local children = { fiber.constructor(fiber.props) }
    reconcile_children(fiber, children)
  end,
  [tags.type.HOST] = function (fiber)
    if (not fiber.instance) then
      fiber.instance = fiber.reconciler:create_instance(fiber.constructor, fiber.props)
    end
    reconcile_children(fiber, fiber.props.children)
  end,
  [tags.type.ROOT] = function (fiber)
    reconcile_children(fiber, fiber.props.children)
  end,
  [tags.type.FRAGMENT] = function (fiber)
    reconcile_children(fiber, fiber.props)
  end,
  [tags.type.BASIC] = function (fiber)
    local children = { fiber.constructor(fiber.props) }
    reconcile_children(fiber, children)
  end,
  [tags.type.MEMO] = function (fiber)
    if (not shallow_equal(fiber.props, fiber.alternate.props)) then
      hooks.render_with_hooks(fiber)
      local children = { fiber.constructor(fiber.props) }
      reconcile_children(fiber, children)
    end
  end,
  [tags.type.MEMO_BASIC] = function (fiber)
    if (not shallow_equal(fiber.props, fiber.alternate.props)) then
      local children = { fiber.constructor(fiber.props) }
      reconcile_children(fiber, children)
    end
  end,
}

function Fiber:perform_unit_of_work()
  if (WORK[self.type]) then
    WORK[self.type](self)
  end

  -- If there is a child fiber, set that
  -- as the next unit of work
  if (self.child) then
    return self.child
  end

  -- get the current fiber
  local next_fiber = self

  -- check for the availability of the fiber
  while (next_fiber) do
    -- check if there are any sibling fibers
    if (next_fiber.sibling) then
      -- set the sibling as the next unit of work
      return next_fiber.sibling
    end
    -- no siblings, try the parent
    next_fiber = next_fiber.parent
  end
end

function Fiber:commit_deletion(parent)
  if (self.instance ~= nil) then
    self.reconciler:remove_child(parent, self.instance)
  else
    self.child:commit_deletion(self)
  end
end

function Fiber:commit_work()
  -- get the current parent Fiber
  local parent_fiber = self.parent

  -- try to find the Fiber with an actual instance
  while (not parent_fiber.instance) do
    parent_fiber = parent_fiber.parent
  end

  -- get the parent instance
  local parent = parent_fiber.instance

  -- commit placement work
  if (self.work_tag == tags.work.PLACEMENT and self.instance ~= nil) then
    self.reconciler:append_child(parent, self.instance)
  end

  -- commit update work
  if (self.work_tag == tags.work.UPDATE and self.instance ~= nil) then
    self.reconciler:commit_update(self.instance, self.alternate.props, self.props)
  end

  -- commit deletion work
  if (self.work_tag == tags.work.DELETION) then
    self:commit_deletion(parent)
    return
  end

  if (self.child) then
    self.child:commit_work()
  end
  if (self.sibling) then
    self.sibling:commit_work()
  end
end

return Fiber
