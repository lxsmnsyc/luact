-- Marks a fiber as having pending work and asks its root to render.
--
-- The flags are set on both the fiber and its alternate, so the update is not
-- lost whichever copy ends up committed. Every ancestor gets
-- `child_pending_work` so the render can find the fiber without visiting
-- unrelated subtrees.

local HOST_ROOT = require("luact.reconciler.tags").work.HOST_ROOT

local M = {}

local function mark_update_from_fiber_to_root(fiber)
  fiber.pending_work = true
  local alternate = fiber.alternate
  if alternate ~= nil then
    alternate.pending_work = true
  end

  local node = fiber
  local parent = fiber.parent
  while parent ~= nil do
    parent.child_pending_work = true
    alternate = parent.alternate
    if alternate ~= nil then
      alternate.child_pending_work = true
    end
    node = parent
    parent = parent.parent
  end

  if node.tag == HOST_ROOT then
    return node.state_node
  end
  -- the fiber is not mounted anymore
  return nil
end

M.mark_update_from_fiber_to_root = mark_update_from_fiber_to_root

-- Returns the root that got scheduled, or nil if the fiber is unmounted.
function M.schedule_update_on_fiber(fiber)
  local root = mark_update_from_fiber_to_root(fiber)
  if root ~= nil then
    root.ensure_scheduled(root)
  end
  return root
end

-- Marks the ancestors of `parent` (inclusive) as having work in their subtree.
function M.schedule_work_on_parent_path(parent)
  local node = parent
  while node ~= nil do
    local alternate = node.alternate
    if node.child_pending_work and (alternate == nil or alternate.child_pending_work) then
      return
    end
    node.child_pending_work = true
    if alternate ~= nil then
      alternate.child_pending_work = true
    end
    node = node.parent
  end
end

return M
