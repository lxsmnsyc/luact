-- The second half of a unit of work, run once all children of a fiber are
-- done. Creates host instances on mount and computes host updates.

local tags = require "luact.reconciler.tags"

local WORK = tags.work
local EFFECT = tags.effect
local add_flag = tags.add

-- Finds the container that host instances of this fiber will live in.
local function get_root_container(fiber)
  local node = fiber.parent
  while node ~= nil do
    if node.tag == WORK.HOST_ROOT then
      return node.state_node.container_info
    end
    if node.tag == WORK.HOST_PORTAL then
      return node.state_node.container_info
    end
    node = node.parent
  end
  return nil
end

-- Appends the top-level host nodes of the subtree of `wip` to `parent`.
local function append_all_children(host, parent, wip)
  local node = wip.child
  while node ~= nil do
    local descend = false
    if node.tag == WORK.HOST_COMPONENT or node.tag == WORK.HOST_TEXT then
      host.append_initial_child(parent, node.state_node)
    elseif node.tag ~= WORK.HOST_PORTAL and node.child ~= nil then
      node.child.parent = node
      node = node.child
      descend = true
    end

    if not descend then
      if node == wip then
        return
      end
      while node.sibling == nil do
        if node.parent == nil or node.parent == wip then
          return
        end
        node = node.parent
      end
      node.sibling.parent = node.parent
      node = node.sibling
    end
  end
end

return function (host, current, wip)
  local new_props = wip.pending_props
  local tag = wip.tag

  if tag == WORK.HOST_COMPONENT then
    local element_type = wip.type
    if current ~= nil and wip.state_node ~= nil then
      local old_props = current.memoized_props
      if old_props ~= new_props then
        local payload = host.prepare_update(wip.state_node, element_type, old_props, new_props)
        wip.update_queue = payload
        if payload ~= nil then
          wip.effect_tag = add_flag(wip.effect_tag, EFFECT.UPDATE)
        end
      end
    else
      local container = get_root_container(wip)
      local instance = host.create_instance(element_type, new_props, container)
      append_all_children(host, instance, wip)
      wip.state_node = instance
      if host.finalize_initial_children(instance, element_type, new_props, container) then
        -- commit_mount runs during the layout phase
        wip.effect_tag = add_flag(wip.effect_tag, EFFECT.UPDATE)
      end
    end
  elseif tag == WORK.HOST_TEXT then
    if current ~= nil and wip.state_node ~= nil then
      if current.memoized_props ~= new_props then
        wip.effect_tag = add_flag(wip.effect_tag, EFFECT.UPDATE)
      end
    else
      wip.state_node = host.create_text_instance(new_props, get_root_container(wip))
    end
  end

  return nil
end
