# API reference

Everything below is a field of `require "luact"`.

## Elements

### `create_element(type, props, ...)`

Returns an element.

- `type` is a string (host component), a function component, `Fragment`, `ErrorBoundary`, a `memo` type, a context or a context `Consumer`.
- `props` is a table or `nil`. It is copied, not modified.
- `props.key` becomes the element key and is removed from props. Keys are converted to strings.
- `props.ref` stays in props. Host components attach it to their instance. Function components receive it as a normal prop.
- Extra arguments become `props.children`. One child is stored as is. Several children become an array, with `nil` replaced by `false`.

### `clone_element(element, props, ...)`

Returns a copy of `element` with `props` merged in. A `key` in `props` replaces the key. Extra arguments replace the children.

### `is_valid_element(value)`

Returns true if `value` is an element.

### `children`

Helpers for `props.children`, which can be a single child, an array or nested arrays.

- `children.to_array(value)` flattens nested arrays and drops `nil`, `true` and `false`.
- `children.count(value)` returns the number of children after flattening.
- `children.map(value, fn)` calls `fn(child, index)` on each child and returns the results.
- `children.for_each(value, fn)` calls `fn(child, index)` on each child.
- `children.only(value)` returns the child if it is a single element, or raises an error.

## Special types

### `Fragment`

Groups children without a host node.

```lua
h(luact.Fragment, nil, h("a"), h("b"))
```

A plain array of children does the same. Use `Fragment` with a `key` when a group is an item of a list.

### `memo(component, compare)`

Returns a component type that skips rendering when its props did not change.

- `compare(old_props, new_props)` returns true when the props are equal. The default compares keys and values one level deep.
- The component still renders when its own state changes or a context it reads changes.

### `create_context(default_value)`

Returns a context. A component reads it with `use_context`.

- The context is its own provider: `h(Context, { value = v }, ...)`. `Context.Provider` is the same object.
- Without a provider above, `use_context` returns `default_value`.
- `Context.Consumer` takes a function as its only child: `h(Context.Consumer, nil, function (value) ... end)`.
- When a provider's value changes, every component that reads it renders again, even below a `memo` that bails out.

### `create_portal(children, container, key)`

Returns a child that renders `children` into another host container. Context and error boundaries still work through the portal.

### `create_ref(initial_value)`

Returns `{ current = initial_value }`. Pass it as `ref` to a host component to receive its instance.

- Refs are set before layout effects run and cleared on unmount.
- A function ref is called with the instance, then with `nil`. If it returns a function, that function is called instead of `ref(nil)`.

### `ErrorBoundary`

Catches errors thrown by its children while rendering, in effects and in host calls.

```lua
h(luact.ErrorBoundary, {
  fallback = function (err, reset)
    return h("label", nil, "Something went wrong: ", tostring(err))
  end,
  on_error = function (err, info)
    print(err, info.component_stack)
  end,
}, h(App))
```

- `fallback` is an element, or a function `fallback(error, reset)` that returns children. Calling `reset()` renders the children again.
- `on_error(error, info)` runs after the fallback is committed. `info.component_stack` lists the components above the error.
- Errors thrown by the fallback go to the next boundary.
- When no boundary catches an error, the root unmounts its tree and the work loop raises the error.

## Hooks

Call hooks only at the top level of a function component, in the same order on every render. Luact raises an error when the order changes.

### `use_state(initial_state)`

Returns `state, set_state`.

- `initial_state` can be a function. It is called once to compute the first state.
- `set_state(value)` or `set_state(function (previous) return next end)` schedules an update.
- Setting the same value (compared with `==`) does not render again.
- `set_state` keeps the same identity for the life of the component.
- Calling `set_state` during render renders the component again before its children.

### `use_reducer(reducer, initial_arg, init)`

Returns `state, dispatch`. `dispatch(action)` computes the next state with `reducer(state, action)`. If `init` is given, the first state is `init(initial_arg)`.

### `use_effect(create, deps)`

Runs `create` after the commit, before the next render or on the next work loop call.

- `create` may return a cleanup function. The cleanup runs before the effect runs again and on unmount.
- `deps` is an array of values. The effect runs again when one of them changes. `{}` runs it once. `nil` runs it after every render.
- Dependencies are compared by key, so `nil` values in `deps` work.

### `use_layout_effect(create, deps)`

Like `use_effect`, but runs right after the host tree is updated. State updates made here are rendered before the work loop returns, so the host never shows the intermediate state.

### `use_insertion_effect(create, deps)`

Like `use_layout_effect`, but runs before layout effects and before refs are set.

### `use_memo(create, deps)`

Returns `create()`, computed again only when `deps` change.

### `use_callback(callback, deps)`

Returns `callback`, keeping the previous function while `deps` do not change.

### `use_ref(initial_value)`

Returns a table `{ current = initial_value }` that stays the same for the life of the component. Changing `current` does not render again.

### `use_context(context)`

Returns the value of the nearest provider of `context`, or its default value.

### `use_imperative_handle(ref, create, deps)`

Sets `ref` to the value returned by `create()`. `ref` can be a ref table or a function. It is cleared on unmount.

### `use_id()`

Returns a unique string that stays the same for the life of the component.

### `use_sync_external_store(subscribe, get_snapshot)`

Reads a value from a store outside Luact and renders again when it changes.

- `subscribe(on_change)` starts listening and returns an unsubscribe function.
- `get_snapshot()` returns the current value. It must return the same value while the store did not change.

### `use_debug_value(value)`

Does nothing. It exists for compatibility with React code.

## Renderers

### `create_renderer(host_config)`

Returns a renderer for a host. See [Writing a renderer](renderers.md) for the config.

The renderer has these functions:

- `renderer.create_root(container)` returns a root.
- `renderer.work_loop(deadline)` renders scheduled work. `deadline()` returns the milliseconds left, and the loop stops when it drops below 1. Without a deadline, it finishes all work. Returns true if work is left.
- `renderer.flush_sync(fn)` calls `fn`, then renders all scheduled work right away. Passive effects of the last commit stay pending.
- `renderer.act(fn)` calls `fn`, then renders and runs effects until nothing is left. Use it in tests.
- `renderer.has_pending_work()` returns true if any root has work left.

A root has these methods:

- `root:render(element)` schedules a render of `element`.
- `root:unmount()` removes the tree right away and runs every cleanup.

## Timers

`require "luact.timers"` has timers driven by your frame clock. They are not tied to a renderer.

- `timers.update(dt)` advances both timers. `dt` is in seconds.
- `timers.frame.request(fn)` calls `fn(dt_ms)` on the next update. `timers.frame.clear(id)` cancels it.
- `timers.timeout.request(fn, delay_ms)` calls `fn` after the delay. `timers.timeout.clear(id)` cancels it.

## Test renderer

`require "luact.test_renderer"` renders to plain tables.

- `test_renderer.create(element)` renders inside `act` and returns an instance.
- `instance:update(element)`, `instance:unmount()`, `instance:to_string()`, `instance:nodes()` and `instance:find_all(type)` inspect and change it.
- `test_renderer.act(fn)` runs `fn` and flushes all work.
- `test_renderer.operations` lists the host operations since `test_renderer.clear_operations()`.
- `test_renderer.to_string(node_or_list)` serializes host nodes.
