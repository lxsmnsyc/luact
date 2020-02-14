local tags = require "luact.tags"

return function (reconciler, element, container)
  reconciler.wip_root = {
    type = tags.type.ROOT,
    reconciler = reconciler,
    instance = container,
    props = {
      children = { element },
    },
    alternate = reconciler.current_root,
  }
  reconciler.next_unit_of_work = reconciler.wip_root
end
