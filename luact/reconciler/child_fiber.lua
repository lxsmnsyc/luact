-- Child reconciliation: diffs new children against the current child fibers
-- and produces the work-in-progress child list.
--
-- This follows React 16.8's ReactChildFiber. Children are matched by key, or
-- by position when there is no key. Arrays go through a two-pass algorithm:
-- first walk both lists while the slots match, then put the remaining old
-- fibers in a map and look up each new child in it.
--
-- Indexes are 1-based. In arrays, use `false` instead of nil for empty slots
-- so positions stay stable.

local symbols = require "luact.symbols"
local tags = require "luact.reconciler.tags"
local fiber_module = require "luact.reconciler.fiber"

local WORK = tags.work
local EFFECT = tags.effect

local ELEMENT = symbols.ELEMENT
local PORTAL = symbols.PORTAL
local FRAGMENT = symbols.FRAGMENT

local create_work_in_progress = fiber_module.create_work_in_progress
local create_fiber_from_element = fiber_module.create_fiber_from_element
local create_fiber_from_fragment = fiber_module.create_fiber_from_fragment
local create_fiber_from_text = fiber_module.create_fiber_from_text
local create_fiber_from_portal = fiber_module.create_fiber_from_portal

local function map_key(key, index)
  if key ~= nil then
    return "k:" .. key
  end
  return index
end

local function is_text(value)
  local kind = type(value)
  return kind == "string" or kind == "number"
end

local function invalid_child(value)
  if type(value) == "function" then
    error(
      "Functions are not valid as a child. Did you mean to call "
        .. "create_element with this component?",
      0
    )
  end
  error("Objects are not valid as a child (found: " .. tostring(value) .. ")", 0)
end

local function create_child_reconciler(should_track_side_effects)
  local function delete_child(return_fiber, child_to_delete)
    if not should_track_side_effects then
      return
    end
    -- Deletions are added to the parent's effect list right away because
    -- deleted fibers are not part of the new tree and never complete.
    local last = return_fiber.last_effect
    if last ~= nil then
      last.next_effect = child_to_delete
      return_fiber.last_effect = child_to_delete
    else
      return_fiber.first_effect = child_to_delete
      return_fiber.last_effect = child_to_delete
    end
    child_to_delete.next_effect = nil
    child_to_delete.effect_tag = EFFECT.DELETION
  end

  local function delete_remaining_children(return_fiber, current_first_child)
    if not should_track_side_effects then
      return nil
    end
    local child = current_first_child
    while child ~= nil do
      delete_child(return_fiber, child)
      child = child.sibling
    end
    return nil
  end

  local function map_remaining_children(current_first_child)
    local existing = {}
    local child = current_first_child
    while child ~= nil do
      existing[map_key(child.key, child.index)] = child
      child = child.sibling
    end
    return existing
  end

  local function use_fiber(fiber, pending_props)
    local clone = create_work_in_progress(fiber, pending_props)
    clone.index = 1
    clone.sibling = nil
    return clone
  end

  local function place_child(new_fiber, last_placed_index, new_index)
    new_fiber.index = new_index
    if not should_track_side_effects then
      return last_placed_index
    end
    local current = new_fiber.alternate
    if current ~= nil then
      local old_index = current.index
      if old_index < last_placed_index then
        -- this is a move
        new_fiber.effect_tag = EFFECT.PLACEMENT
        return last_placed_index
      end
      -- this item can stay in place
      return old_index
    end
    -- this is an insertion
    new_fiber.effect_tag = EFFECT.PLACEMENT
    return last_placed_index
  end

  local function place_single_child(new_fiber)
    if should_track_side_effects and new_fiber.alternate == nil then
      new_fiber.effect_tag = EFFECT.PLACEMENT
    end
    return new_fiber
  end

  local function update_text_node(return_fiber, current, text)
    local fiber
    if current == nil or current.tag ~= WORK.HOST_TEXT then
      fiber = create_fiber_from_text(text)
    else
      fiber = use_fiber(current, text)
    end
    fiber.parent = return_fiber
    return fiber
  end

  local function update_element(return_fiber, current, element)
    local fiber
    if current ~= nil and current.element_type == element.type then
      fiber = use_fiber(current, element.props)
    else
      fiber = create_fiber_from_element(element)
    end
    fiber.ref = element.ref
    fiber.parent = return_fiber
    return fiber
  end

  local function update_portal(return_fiber, current, portal)
    local fiber
    if
      current == nil
      or current.tag ~= WORK.HOST_PORTAL
      or current.state_node.container_info ~= portal.container_info
    then
      fiber = create_fiber_from_portal(portal)
    else
      fiber = use_fiber(current, portal.children)
    end
    fiber.parent = return_fiber
    return fiber
  end

  local function update_fragment(return_fiber, current, fragment_children, key)
    local fiber
    if current == nil or current.tag ~= WORK.FRAGMENT then
      fiber = create_fiber_from_fragment(fragment_children, key)
    else
      fiber = use_fiber(current, fragment_children)
    end
    fiber.parent = return_fiber
    return fiber
  end

  local function create_child(return_fiber, new_child)
    local fiber
    if is_text(new_child) then
      fiber = create_fiber_from_text(tostring(new_child))
    elseif type(new_child) == "table" then
      local typeof = new_child["$$typeof"]
      if typeof == ELEMENT then
        if new_child.type == FRAGMENT then
          fiber = create_fiber_from_fragment(new_child.props.children, new_child.key)
        else
          fiber = create_fiber_from_element(new_child)
          fiber.ref = new_child.ref
        end
      elseif typeof == PORTAL then
        fiber = create_fiber_from_portal(new_child)
      elseif typeof == nil then
        fiber = create_fiber_from_fragment(new_child, nil)
      else
        invalid_child(new_child)
      end
    elseif new_child ~= nil and type(new_child) ~= "boolean" then
      invalid_child(new_child)
    end
    if fiber ~= nil then
      fiber.parent = return_fiber
    end
    return fiber
  end

  -- Updates the fiber in the slot if the keys match, or returns nil.
  local function update_slot(return_fiber, old_fiber, new_child)
    local key = old_fiber and old_fiber.key

    if is_text(new_child) then
      -- text nodes have no keys
      if key ~= nil then
        return nil
      end
      return update_text_node(return_fiber, old_fiber, tostring(new_child))
    end

    if type(new_child) == "table" then
      local typeof = new_child["$$typeof"]
      if typeof == ELEMENT then
        if new_child.key ~= key then
          return nil
        end
        if new_child.type == FRAGMENT then
          return update_fragment(return_fiber, old_fiber, new_child.props.children, key)
        end
        return update_element(return_fiber, old_fiber, new_child)
      end
      if typeof == PORTAL then
        if new_child.key ~= key then
          return nil
        end
        return update_portal(return_fiber, old_fiber, new_child)
      end
      if typeof == nil then
        if key ~= nil then
          return nil
        end
        return update_fragment(return_fiber, old_fiber, new_child, nil)
      end
      invalid_child(new_child)
    end

    if new_child ~= nil and type(new_child) ~= "boolean" then
      invalid_child(new_child)
    end
    return nil
  end

  local function update_from_map(existing, return_fiber, new_index, new_child)
    if is_text(new_child) then
      return update_text_node(return_fiber, existing[new_index], tostring(new_child))
    end

    if type(new_child) == "table" then
      local typeof = new_child["$$typeof"]
      if typeof == ELEMENT then
        local matched = existing[map_key(new_child.key, new_index)]
        if new_child.type == FRAGMENT then
          return update_fragment(return_fiber, matched, new_child.props.children, new_child.key)
        end
        return update_element(return_fiber, matched, new_child)
      end
      if typeof == PORTAL then
        local matched = existing[map_key(new_child.key, new_index)]
        return update_portal(return_fiber, matched, new_child)
      end
      if typeof == nil then
        return update_fragment(return_fiber, existing[new_index], new_child, nil)
      end
      invalid_child(new_child)
    end

    if new_child ~= nil and type(new_child) ~= "boolean" then
      invalid_child(new_child)
    end
    return nil
  end

  local function reconcile_children_array(return_fiber, current_first_child, new_children)
    local count = #new_children

    local result_first = nil
    local previous_new = nil

    local old_fiber = current_first_child
    local last_placed_index = 0
    local new_index = 1
    local next_old_fiber

    -- First pass: walk both lists while the slots match.
    while old_fiber ~= nil and new_index <= count do
      if old_fiber.index > new_index then
        next_old_fiber = old_fiber
        old_fiber = nil
      else
        next_old_fiber = old_fiber.sibling
      end

      local new_fiber = update_slot(return_fiber, old_fiber, new_children[new_index])
      if new_fiber == nil then
        if old_fiber == nil then
          old_fiber = next_old_fiber
        end
        break
      end

      if should_track_side_effects and old_fiber ~= nil and new_fiber.alternate == nil then
        -- the slot matched but the fiber could not be reused
        delete_child(return_fiber, old_fiber)
      end

      last_placed_index = place_child(new_fiber, last_placed_index, new_index)
      if previous_new == nil then
        result_first = new_fiber
      else
        previous_new.sibling = new_fiber
      end
      previous_new = new_fiber
      old_fiber = next_old_fiber
      new_index = new_index + 1
    end

    if new_index > count then
      -- reached the end of the new children
      delete_remaining_children(return_fiber, old_fiber)
      return result_first
    end

    if old_fiber == nil then
      -- no more existing children, the rest are insertions
      for i = new_index, count do
        local new_fiber = create_child(return_fiber, new_children[i])
        if new_fiber ~= nil then
          last_placed_index = place_child(new_fiber, last_placed_index, i)
          if previous_new == nil then
            result_first = new_fiber
          else
            previous_new.sibling = new_fiber
          end
          previous_new = new_fiber
        end
      end
      return result_first
    end

    -- Second pass: match the remaining children by key or index.
    local first_remaining = old_fiber
    local existing = map_remaining_children(old_fiber)

    for i = new_index, count do
      local new_fiber = update_from_map(existing, return_fiber, i, new_children[i])
      if new_fiber ~= nil then
        local reused = new_fiber.alternate
        if should_track_side_effects and reused ~= nil then
          existing[map_key(reused.key, reused.index)] = nil
        end
        last_placed_index = place_child(new_fiber, last_placed_index, i)
        if previous_new == nil then
          result_first = new_fiber
        else
          previous_new.sibling = new_fiber
        end
        previous_new = new_fiber
      end
    end

    if should_track_side_effects then
      -- delete the fibers that were not reused, in their original order
      local child = first_remaining
      while child ~= nil do
        local next_child = child.sibling
        local slot = map_key(child.key, child.index)
        if existing[slot] == child then
          delete_child(return_fiber, child)
        end
        child = next_child
      end
    end

    return result_first
  end

  local function reconcile_single_text_node(return_fiber, current_first_child, text)
    if current_first_child ~= nil and current_first_child.tag == WORK.HOST_TEXT then
      delete_remaining_children(return_fiber, current_first_child.sibling)
      local existing = use_fiber(current_first_child, text)
      existing.parent = return_fiber
      return existing
    end
    delete_remaining_children(return_fiber, current_first_child)
    local created = create_fiber_from_text(text)
    created.parent = return_fiber
    return created
  end

  local function reconcile_single_element(return_fiber, current_first_child, element)
    local key = element.key
    local is_fragment = element.type == FRAGMENT
    local child = current_first_child

    while child ~= nil do
      if child.key == key then
        if child.element_type == element.type then
          delete_remaining_children(return_fiber, child.sibling)
          local props
          if is_fragment then
            props = element.props.children
          else
            props = element.props
          end
          local existing = use_fiber(child, props)
          existing.ref = element.ref
          existing.parent = return_fiber
          return existing
        end
        delete_remaining_children(return_fiber, child)
        break
      end
      delete_child(return_fiber, child)
      child = child.sibling
    end

    local created
    if is_fragment then
      created = create_fiber_from_fragment(element.props.children, key)
    else
      created = create_fiber_from_element(element)
      created.ref = element.ref
    end
    created.parent = return_fiber
    return created
  end

  local function reconcile_single_portal(return_fiber, current_first_child, portal)
    local key = portal.key
    local child = current_first_child

    while child ~= nil do
      if child.key == key then
        if
          child.tag == WORK.HOST_PORTAL
          and child.state_node.container_info == portal.container_info
        then
          delete_remaining_children(return_fiber, child.sibling)
          local existing = use_fiber(child, portal.children)
          existing.parent = return_fiber
          return existing
        end
        delete_remaining_children(return_fiber, child)
        break
      end
      delete_child(return_fiber, child)
      child = child.sibling
    end

    local created = create_fiber_from_portal(portal)
    created.parent = return_fiber
    return created
  end

  return function (return_fiber, current_first_child, new_child)
    -- An unkeyed fragment at the top level is treated as its children.
    if
      type(new_child) == "table"
      and new_child["$$typeof"] == ELEMENT
      and new_child.type == FRAGMENT
      and new_child.key == nil
    then
      new_child = new_child.props.children
    end

    if type(new_child) == "table" then
      local typeof = new_child["$$typeof"]
      if typeof == ELEMENT then
        return place_single_child(
          reconcile_single_element(return_fiber, current_first_child, new_child)
        )
      end
      if typeof == PORTAL then
        return place_single_child(
          reconcile_single_portal(return_fiber, current_first_child, new_child)
        )
      end
      if typeof == nil then
        return reconcile_children_array(return_fiber, current_first_child, new_child)
      end
      invalid_child(new_child)
    end

    if is_text(new_child) then
      return place_single_child(
        reconcile_single_text_node(return_fiber, current_first_child, tostring(new_child))
      )
    end

    if new_child ~= nil and type(new_child) ~= "boolean" then
      invalid_child(new_child)
    end

    -- remaining cases are all treated as empty
    return delete_remaining_children(return_fiber, current_first_child)
  end
end

local M = {}

-- Used for updates: records placements and deletions.
M.reconcile_child_fibers = create_child_reconciler(true)
-- Used for the first mount of a subtree: the parent gets placed as a whole,
-- so its children need no individual effects.
M.mount_child_fibers = create_child_reconciler(false)

-- Duplicates the current child fibers into work-in-progress fibers.
function M.clone_child_fibers(wip)
  local current_child = wip.child
  if current_child == nil then
    return
  end
  local new_child = create_work_in_progress(current_child, current_child.pending_props)
  wip.child = new_child
  new_child.parent = wip
  while current_child.sibling ~= nil do
    current_child = current_child.sibling
    new_child.sibling = create_work_in_progress(current_child, current_child.pending_props)
    new_child = new_child.sibling
    new_child.parent = wip
  end
  new_child.sibling = nil
end

return M
