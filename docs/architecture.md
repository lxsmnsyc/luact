# How the reconciler works

The reconciler follows React 16.8. The code is in `luact/reconciler`. This page maps each part to its file.

## Fibers

A fiber is the unit of work. There is one fiber per element in the tree ([fiber.lua](../luact/reconciler/fiber.lua)).

- `child`, `sibling` and `parent` link fibers into a tree. `parent` is React's `return` field, which is a reserved word in Lua.
- `pending_props` are the props of this render. `memoized_props` are the props of the last render.
- `memoized_state` holds the hook list of a function component, the element of the root, or the state of an error boundary.
- `update_queue` holds the effects of a function component, the update payload of a host node, or the updates of a root or boundary.
- `state_node` is the host instance, the root, the portal container or the boundary instance.
- `effect_tag` holds the effect flags from [tags.lua](../luact/reconciler/tags.lua). Lua 5.1 has no bit operators, so flags use arithmetic helpers.

Each mounted element has up to two fibers. `current` matches the host tree. Its `alternate` is the work-in-progress copy. `create_work_in_progress` reuses the alternate, so a render allocates few tables. After a commit the work-in-progress tree becomes the current tree.

## Scheduling

Updates set `pending_work` on the fiber and `child_pending_work` on every ancestor, on both copies ([schedule.lua](../luact/reconciler/schedule.lua)). The root is then added to the renderer's list of scheduled roots.

These two flags replace React's expiration times. Luact has a single priority, so a boolean is enough.

## Work loop

`renderer.work_loop(deadline)` in [init.lua](../luact/reconciler/init.lua) processes one root at a time.

1. It runs the passive effects left from the last commit.
2. It creates the work-in-progress root and runs units of work until the tree is complete or `deadline()` drops below 1.
3. When the tree is complete, it commits it.
4. If a layout effect scheduled an update during the commit, it renders again right away, ignoring the deadline.

A render that stops at the deadline continues on the next call. It is not restarted. Updates dispatched in the meantime are kept in their queues and either get processed by this render or leave pending work for the next one.

## Begin work

`begin_work` ([begin_work.lua](../luact/reconciler/begin_work.lua)) renders one fiber and returns its first child.

- If the props are the same table and the fiber has no pending work, it bails out. The children are cloned only if one of them has pending work. Otherwise the whole subtree is skipped.
- Function components run through `render_with_hooks`. If no state, props or context changed, the output is discarded and the fiber bails out.
- `memo` components compare props first and skip the render when they are equal.
- Context providers compare the new value with `==` (NaN equals NaN). When it changed, `propagate_context_change` marks every fiber below that read the context.

Context values are found by walking up `parent` pointers to the nearest provider ([context.lua](../luact/reconciler/context.lua)). React uses a global stack instead. Walking up keeps several roots rendering at the same time safe.

## Child reconciliation

[child_fiber.lua](../luact/reconciler/child_fiber.lua) is a port of React's `ReactChildFiber`.

- A single child is matched by key and type.
- An array first walks old and new children in order while the keys match. The remaining old children go in a map by key, or by index when unkeyed. Each new child looks up its match there.
- `last_placed_index` decides which reused children move. A child moves when its old index is lower than the last placed index.
- Deleted fibers are added to the parent's effect list right away.

## Complete work

When a fiber has no child left to visit, `complete_work` ([complete_work.lua](../luact/reconciler/complete_work.lua)) runs on it and its ancestors.

- New host fibers create their host instance and append their host children.
- Updated host fibers call `prepare_update` and keep the payload.
- The fiber's effect list and the fiber itself are appended to the parent's effect list. At the root, this list contains every fiber with an effect, children before parents.

## Commit

[commit.lua](../luact/reconciler/commit.lua) walks the effect list twice. The commit cannot be interrupted.

1. Mutation. Old refs are detached. Host nodes are inserted, updated and removed. Insertion effects run, and cleanups of changed layout effects run.
2. Layout. Layout effects run, refs are attached, `commit_mount` runs, and error boundaries call `on_error`.

Passive effects are collected and run later by `flush_passive_effects`. All cleanups run before any effect.

Deleting a subtree removes only its top host nodes from the host. Then every fiber below runs its cleanups. Layout cleanups run at once. Passive cleanups wait for the passive phase. Finally the deleted fibers are unlinked so they can be garbage collected and later updates cannot reach the root.

## Errors

[throw.lua](../luact/reconciler/throw.lua) handles errors.

- When a fiber throws during render, the nearest `ErrorBoundary` gets a capture update and the `SHOULD_CAPTURE` flag. The failed fibers are completed as `INCOMPLETE` up to the boundary, which renders again with its fallback. Its old children are all deleted.
- Errors in effects, refs and host calls during the commit schedule a capture update on the nearest boundary.
- When no boundary catches the error, the root renders `nil` and the work loop raises the error after the commit.

## Hooks

[hooks.lua](../luact/reconciler/hooks.lua) keeps hooks in a linked list in `memoized_state`.

- Each render clones the current hook list in call order. A hook of a different kind in the same slot raises an error.
- State queues are shared by both copies of a hook. An update dispatched while a render is in progress is not lost.
- When the queue is empty, `set_state` computes the next state right away. If it did not change, nothing is scheduled.
- Updates a component makes to itself during render are handled by rendering it again, up to 25 times.

## Differences from React 16.8

- The public API follows React 18/19. There are no class components and no `forwardRef`. `ref` is a normal prop.
- `ErrorBoundary` is a built-in component with `fallback` and `on_error` props, since there are no classes.
- There is a single priority. There are no lanes, transitions or concurrent features.
- Passive effect cleanups of deleted components run in the passive phase, and all cleanups run before any effect. This is the React 17 behavior.
- There is no Suspense, `lazy`, `StrictMode` or `Profiler`.
