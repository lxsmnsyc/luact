# Writing a renderer

A renderer connects Luact to a host, such as a game engine, a terminal or a GUI toolkit. You write a host config: a table of plain functions that create and change host nodes. Luact calls them with plain function calls, not method calls.

```lua
local renderer = luact.create_renderer(host_config)
local root = renderer.create_root(container)
```

See `examples/console/custom_renderer.lua` for a complete example.

## Required functions

- `create_instance(type, props, container)` creates a host node for a host element. `type` is the string passed to `create_element`. `props` includes `children` and `ref`.
- `append_child(parent, child)` adds `child` as the last child of `parent`.
- `remove_child(parent, child)` removes `child` from `parent`.

## Optional functions

- `create_text_instance(text, container)` creates a node for a string or number child. Without it, text children raise an error.
- `insert_before(parent, child, before)` inserts `child` before `before`. It is needed as soon as children are inserted or moved in the middle of a list.
- `append_initial_child(parent, child)` adds a child to a node that is not in the host tree yet. Defaults to `append_child`.
- `append_child_to_container`, `insert_in_container_before` and `remove_child_from_container` do the same for the root container and portal containers. They default to the non-container versions.
- `prepare_update(instance, type, old_props, new_props)` returns an update payload, or `nil` when nothing changed. The default returns `true`.
- `commit_update(instance, payload, type, old_props, new_props)` applies the payload.
- `commit_text_update(text_instance, old_text, new_text)` changes a text node.
- `finalize_initial_children(instance, type, props, container)` runs after the children of a new node are appended. Return true to get a `commit_mount` call.
- `commit_mount(instance, type, props)` runs in the layout phase for new nodes that asked for it.
- `prepare_for_commit(container)` and `reset_after_commit(container)` run before and after the host tree is changed.
- `get_public_instance(instance)` returns what refs receive. Defaults to the instance.
- `schedule_work()` is called when work gets scheduled. Use it to wake your loop up.

## When each function runs

Rendering has two phases.

1. The render phase runs components and computes changes. It can be split across frames. It only calls `create_instance`, `create_text_instance`, `append_initial_child`, `finalize_initial_children` and `prepare_update`. Nodes created here are not attached to the host tree yet.
2. The commit phase applies the changes in one go. It calls the insert, append, remove and commit functions.

Do not change what the user sees during the render phase.

## Driving the work loop

Call `renderer.work_loop(deadline)` regularly, for example once per frame. `deadline()` returns the milliseconds left in the frame.

```lua
function on_frame()
  local start = now_ms()
  renderer.work_loop(function ()
    return 8 - (now_ms() - start)
  end)
end
```

Updates do nothing until the work loop runs. Several updates made before a call are rendered together.
