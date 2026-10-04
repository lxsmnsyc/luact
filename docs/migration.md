# Migrating from the old API

The old API created components through `luact.init(reconciler)`. The new API follows React 18/19. Every component is a plain function, and elements are made with `create_element`.

## Creating a renderer

Old:

```lua
local Renderer = luact.init({
  create_instance = function (self, constructor, props) ... end,
  append_child = function (self, parent, child, index) ... end,
  commit_update = function (self, instance, old_props, new_props) ... end,
  remove_child = function (self, parent, child, index) ... end,
})
Renderer.render(App {}, container)
Renderer.work_loop(deadline)
```

New:

```lua
local renderer = luact.create_renderer({
  create_instance = function (type, props, container) ... end,
  append_child = function (parent, child) ... end,
  insert_before = function (parent, child, before) ... end,
  remove_child = function (parent, child) ... end,
  commit_update = function (instance, payload, type, old_props, new_props) ... end,
})
local root = renderer.create_root(container)
root:render(h(App))
renderer.work_loop(deadline)
```

- Host functions are plain functions. They no longer receive `self`.
- `append_child` and `remove_child` no longer receive an index. Use `insert_before` to place a node in the middle.
- `commit_update` receives a payload from the optional `prepare_update`.
- `deadline()` must return the milliseconds left, not the time spent.

## Components

| Old | New |
| --- | --- |
| `Renderer.component(fn)` | `fn` |
| `Renderer.basic(fn)` | `fn` |
| `Renderer.memo(fn)` | `luact.memo(fn)` |
| `Renderer.memo_basic(fn)` | `luact.memo(fn)` |
| `Renderer.Element("type", props)` | `h("type", props)` |
| `Renderer.Fragment { ... }` | `h(luact.Fragment, nil, ...)` |
| `Renderer.ErrorBoundary { catch = fn }` | `h(luact.ErrorBoundary, { fallback = ..., on_error = fn })` |
| `Renderer.create_context()` | `luact.create_context(default)` |
| `Context.Consumer { consume = fn }` | `h(Context.Consumer, nil, fn)` |
| `Renderer.create_meta(...)` | a function component with hooks |

Calls like `App { x = 1 }` become `h(App, { x = 1 })`, where `h` is `luact.create_element`.

## Hooks

- `use_constant(fn)` becomes `use_memo(fn, {})` or `use_state(fn)`.
- `use_force_update()` becomes `use_reducer(function (n) return n + 1 end, 0)`.
- `use_render_count()` was removed. Count renders with `use_ref`.
- Hooks now raise an error when their order changes between renders.

## Timers

`luact.update_frame(dt)` becomes `require("luact.timers").update(dt)`. `luact.prevent_idle` and the idle timer were removed.

## LÖVE

`luact-love` no longer replaces `love.run` when required. Call `luact_love.install(element)` in `love.load`. The `draw` host type with `before` and `after` callbacks is replaced by `group`, `rectangle`, `circle`, `text`, `image` and `draw` host types. See [LÖVE renderer](love.md).
