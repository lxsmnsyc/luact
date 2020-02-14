local tags = require "luact.tags"

return function (reconciler)
  reconciler.wip_root = {
    type = tags.type.ROOT,
    reconciler = reconciler,
    instance = reconciler.current_root.instance,
    props = reconciler.current_root.props,
    alternate = reconciler.current_root,
  }
  reconciler.next_unit_of_work = reconciler.wip_root
end