local tags = require "luact.tags"

local create_fiber = require "luact.fiber.create"

return function (reconciler)
  local current = reconciler.current_root
  local fiber = create_fiber(reconciler, tags.type.ROOT, current.props)

  fiber.instance = current.instance
  fiber.alternate = current

  reconciler.wip_root = fiber
  reconciler.next_unit_of_work = fiber
end