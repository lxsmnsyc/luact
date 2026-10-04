-- Luact: a React-like UI library for Lua.

local element = require "luact.element"
local hooks = require "luact.reconciler.hooks"
local create_renderer = require "luact.reconciler"

return {
  -- elements
  create_element = element.create_element,
  clone_element = element.clone_element,
  is_valid_element = element.is_valid_element,
  children = element.children,

  -- special types
  Fragment = element.Fragment,
  ErrorBoundary = element.ErrorBoundary,
  memo = element.memo,
  create_context = element.create_context,
  create_portal = element.create_portal,
  create_ref = element.create_ref,

  -- hooks
  use_state = hooks.use_state,
  use_reducer = hooks.use_reducer,
  use_effect = hooks.use_effect,
  use_layout_effect = hooks.use_layout_effect,
  use_insertion_effect = hooks.use_insertion_effect,
  use_memo = hooks.use_memo,
  use_callback = hooks.use_callback,
  use_ref = hooks.use_ref,
  use_context = hooks.use_context,
  use_imperative_handle = hooks.use_imperative_handle,
  use_debug_value = hooks.use_debug_value,
  use_id = hooks.use_id,
  use_sync_external_store = hooks.use_sync_external_store,

  -- renderers
  create_renderer = create_renderer,
}
