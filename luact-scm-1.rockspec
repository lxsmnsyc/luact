package = "luact"
version = "scm-1"
source = {
  url = "git+https://github.com/lxsmnsyc/luact.git",
}
description = {
  summary = "A React-like UI library for Lua",
  detailed = "Function components, hooks and a fiber reconciler for any host.",
  license = "MIT",
}
dependencies = {
  "lua >= 5.1",
}
build = {
  type = "builtin",
  modules = {
    ["luact"] = "luact/init.lua",
    ["luact.element"] = "luact/element.lua",
    ["luact.symbols"] = "luact/symbols.lua",
    ["luact.utils"] = "luact/utils.lua",
    ["luact.test_renderer"] = "luact/test_renderer.lua",
    ["luact.reconciler"] = "luact/reconciler/init.lua",
    ["luact.reconciler.begin_work"] = "luact/reconciler/begin_work.lua",
    ["luact.reconciler.child_fiber"] = "luact/reconciler/child_fiber.lua",
    ["luact.reconciler.commit"] = "luact/reconciler/commit.lua",
    ["luact.reconciler.complete_work"] = "luact/reconciler/complete_work.lua",
    ["luact.reconciler.context"] = "luact/reconciler/context.lua",
    ["luact.reconciler.fiber"] = "luact/reconciler/fiber.lua",
    ["luact.reconciler.hooks"] = "luact/reconciler/hooks.lua",
    ["luact.reconciler.render_state"] = "luact/reconciler/render_state.lua",
    ["luact.reconciler.schedule"] = "luact/reconciler/schedule.lua",
    ["luact.reconciler.tags"] = "luact/reconciler/tags.lua",
    ["luact.reconciler.throw"] = "luact/reconciler/throw.lua",
    ["luact.timers"] = "luact/timers/init.lua",
    ["luact.timers.frame"] = "luact/timers/frame.lua",
    ["luact.timers.timeout"] = "luact/timers/timeout.lua",
  },
}
