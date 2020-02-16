# luact

> React in Lua. Renderer-agnostic framework for Lua platforms.

## Features

### Fiber Architecture

Luact integrates a simple implementation of React's Fiber Architecture, which allows us to have a consistent 16ms frame.

### Reconciler

Luact aims to be renderer-agnostic, and so a custom Reconciler allows us to do so, which defines the UI tree.

### Hooks

Luact has yet to implement class-based components, and since Luact only has functional components for now, hooks (inspired from React hooks) is a good way to have access to lifecycles and turn these components into stateful ones.

### Timers

Luact has built-in timers inspired from the Web API.

## Usage

### Reconciler

Reconciler defines the way to create our custom UI tree. This table has methods dedicated to manipulating the UI tree.

Reconciler must have the following functions:
* `create_instance` - constructs the UI node.
  ```lua
    create_instance = function (self, constructor, props)
  ```
  - `constructor` is the tag for the given host component (a component defined with `Element`).
  - `props` is the element's properties.
* `append_child` - inserts the UI node to a parent UI node.
  ```lua
  append_child = function (self, parent, child, index)
  ```
  - `parent` is the nearest UI node instance in the tree. This will serve as the UI node's parent.
  - `child` is the child UI node instance in the tree.
  - `index` indicates that the `child` is the nth child from the `parent`.
* `commit_update` - updates the given UI node.
  ```lua
  commit_update = function (self, instance, old_props, new_props)
  ```
  - `instance` is the UI node instance to be updated.
  - `old_props` is the UI node's previous props.
  - `new_props` is the UI node's commited props.
* `remove_child` - removes the UI node from the parent
  ```lua
  remove_child = function (self, parent, child, index)
  ```
  - `parent` is the parent UI node.
  - `child` is the child UI node to be removed from the parent.
  - `index` indicates that the `child` is the nth child from the `parent`.

Once a reconciler has been defined, the function `Luact.init` can be called to initialize the render system. This function returns a table with the following properties:
- `Fragment` - Luact component for adapting multiple children.
- `ErrorBoundary` - Luact component for setting up error boundaries for render and commit phase.
- `component` - Function for constructing a Luact component. Receives a `render` function.
- `basic` - Similar to `component` except that this is strictly for stateless components.
- `memo` - Memoized version of the `component`.
- `memo_basic` - Memoized version of the `basic`.
- `Element` - Luact component for constructing host components (the components the Reconciler interacts with.). Host components represents the UI tree.
- `render` - Renders the UI tree with the top level element. Receives the `element` which is the top-level element from the UI tree and the `container` which is the root and the container of the UI tree. Usually called only once.
- `work_loop` - function that runs the Fiber workloop. Receives a function that returns the time remaining before the next frame step (in milliseconds). This function must be called periodically (ideally per frame) and during idle process.

An example reconciler can be found in `luact-love` directory.

### Components

Component is what builds your UI. In Luact, we have different kinds of components, and each one of them has different use cases.

- `basic` is the simplest form of a Luact component. This function receives a function which defines how we render the chunk of UI it represents. The elements created by `basic` are stateless and has no access to hooks, doing so can yield errors.
```lua
local MyBasicComponent = MyRenderer.basic(function (props)
  return MyRenderer.Element('h1', {
    content = props.content
  })
end)

local element = MyBasicComponent {
  content = "Hello World"
}
```

- `component` is similar to `basic` but has access to hooks.

```lua
local Counter = MyRenderer.component(function (props)
  local count, set_count = Luact.use_state(0)

  Luact.use_layout_effect(function ()
    local function animate()
      set_count(function (current)
        return current + 1
      end)

      frame.request(animate)
    end

    frame.request(animate)
  end, {})

  return MyRenderer.Element('h1', {
    content = "Count: "..count
  })
end)
```

- `memo` is a special kind of component constructor similar to `component` but allows the memoization process by skipping the render process if the old props and the new props are similar in shallow level.
- `memo_basic` is the same as `basic` with the memoization process.

- `Fragment` is a kind of component that allows render functions to return multiple components.
```lua
local List = Renderer.basic(function (props)
  return Renderer.Fragment {
    ListItem { value = props.values[1] },
    ListItem { value = props.values[2] },
    ListItem { value = props.values[3] },
  }
end)
```

- `ErrorBoundary` is a kind of component that accumulates render and commit phase errors from within its tree. `ErrorBoundary` tries to render every possible child inside the tree until all trees has been covered. If `ErrorBoundary` catches an error, the error is pushed to the accumulated table of errors, and once the lifecycle phase begins, runs the `catch` prop to receive the errors.

Example below yields an error for using hooks inside a `basic` component.

```lua
local B = Love.basic(function ()
  Luact.use_constant(function ()
    return "Wtf"
  end)

  return Love.Element("Hello", { message = "World" })
end)

local A = Love.component(function ()
  return Love.ErrorBoundary {
    catch = function (errors)
      error(logs(errors, 0))
    end,
    children = {
      B {},
      B {},
    }
  }
end)
```

- `Meta` is a kind of component constructor similar to React Class Components. `Meta` is also a cross of stateful component and error boundary.

- `Element` is what represents your UI in your container and are the elements that are processed by your custom Reconciler. In React, this is similar to HTML elements.

### Hooks

Hooks are a special set of functions that deals with the internal workings of Luact and work with the components. Hooks allows to turn your components into stateful components and allows them to have access to component lifecycles.

* `use_callback` memoizes a function's reference. Useful for dependencies and component props.
* `use_constant` creates a component-level constant.
* `use_effect` allows to run side-effects for the component whenever the given set of dependencies changes. The function side-effect can return a function which is called between re-runs, useful for cleanup logic.
* `use_force_update` returns a function that, when called, re-renders a component.
* `use_layout_effect` is similar to `use_effect` except that side-effects are run before UI mutations.
* `use_memo` allows to memoize synchronous process in the render logic.
* `use_reducer`
* `use_ref` creates a component-level mutable reference that remains the same throughout the lifecycle. Useful for data persistence that do not need re-renders.
* `use_state` creates a component-level that state that when updated, re-renders the component.

Hooks follow two rules:
- They can only be called inside `component` and `memo`.
- They should be called on top-level and outside branching logic.

You can read more info about it in the official React documentation: https://reactjs.org/docs/hooks-intro.html

## Bindings

- `luact-love` is a Luact engine for the LOVE 11.3 framework. (WIP)

## Future goals

Some features from React that will be implemented soon:
* Portal API
* `should_update`, `get_derived_state_from_props`, `get_derived_state_from_error`, `get_derived_state_from_context` Meta methods
* Refs
* Component Stack Trace

Other goals:
* 

## Credits

* Maxim Koretskyi for his in-depth analysis of the React Fiber architecture. Links to his articles:
  * https://indepth.dev/inside-fiber-in-depth-overview-of-the-new-reconciliation-algorithm-in-react/
  * https://indepth.dev/the-how-and-why-on-reacts-usage-of-linked-list-in-fiber-to-walk-the-components-tree/
  * https://indepth.dev/in-depth-explanation-of-state-and-props-update-in-react/
* [Rodrigo Pombo](https://github.com/pomber) for his [Didact](https://github.com/pomber/didact), a DIY React project.
* The React Team for their wonderful work with the React project.
* Flutter's Widget declaration which Luact to inspiration from.

## License

This project is licensed under the MIT license. See the [LICENSE file](LICENSE)