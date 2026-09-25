-- Context reading and change propagation.
--
-- A context value is found by walking up the parent chain to the nearest
-- provider. During render the parent chain points into the work-in-progress
-- tree, so the provider's props are already the new ones. This avoids the
-- global value stack React uses, which keeps several roots rendering at once
-- safe.

local tags = require "luact.reconciler.tags"
local render_state = require "luact.reconciler.render_state"
local schedule = require "luact.reconciler.schedule"

local WORK = tags.work

local M = {}

-- Called before a fiber renders. Resets the context dependencies, which get
-- collected again while rendering.
function M.prepare_to_read_context(wip)
  local dependencies = wip.dependencies
  if dependencies ~= nil and dependencies.has_change then
    render_state.did_receive_update = true
  end
  wip.dependencies = nil
end

function M.read_context(fiber, context)
  local dependencies = fiber.dependencies
  if dependencies == nil then
    dependencies = { contexts = {}, has_change = false }
    fiber.dependencies = dependencies
  end
  dependencies.contexts[context] = true

  local node = fiber.parent
  while node ~= nil do
    if node.tag == WORK.CONTEXT_PROVIDER and node.type == context then
      return node.memoized_props.value
    end
    node = node.parent
  end
  return context.default_value
end

-- Called when a provider's value changes. Marks every fiber below the provider
-- that read this context, so it re-renders even if its parent bails out.
function M.propagate_context_change(wip, context)
  local fiber = wip.child
  if fiber ~= nil then
    fiber.parent = wip
  end

  while fiber ~= nil do
    local next_fiber
    local dependencies = fiber.dependencies

    if dependencies ~= nil then
      next_fiber = fiber.child
      if dependencies.contexts[context] then
        dependencies.has_change = true
        fiber.pending_work = true
        local alternate = fiber.alternate
        if alternate ~= nil then
          alternate.pending_work = true
        end
        schedule.schedule_work_on_parent_path(fiber.parent)
      end
    elseif fiber.tag == WORK.CONTEXT_PROVIDER and fiber.type == context then
      -- a nested provider of the same context shadows this one
      next_fiber = nil
    else
      next_fiber = fiber.child
    end

    if next_fiber ~= nil then
      next_fiber.parent = fiber
    else
      -- no child, move to the next sibling or back up
      next_fiber = fiber
      while next_fiber ~= nil do
        if next_fiber == wip then
          next_fiber = nil
          break
        end
        local sibling = next_fiber.sibling
        if sibling ~= nil then
          sibling.parent = next_fiber.parent
          next_fiber = sibling
          break
        end
        next_fiber = next_fiber.parent
      end
    end

    fiber = next_fiber
  end
end

return M
