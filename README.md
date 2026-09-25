# luact

Luact is a React-like UI library for Lua. You describe the UI with function components and hooks. Luact updates your host tree with the smallest set of changes.

- The API follows React 18/19 function components: `create_element`, hooks, `memo`, context, portals and refs as props.
- The reconciler follows React 16.8: fibers with alternates, an effect list, bailouts and time-sliced rendering.
- It works with any host through a renderer config. `luact-love` renders to [LÖVE](https://love2d.org).
- It runs on Lua 5.1 to 5.5 and LuaJIT.

```lua
local luact = require "luact"
local h = luact.create_element

local function Counter(props)
  local count, set_count = luact.use_state(0)

  luact.use_effect(function ()
    print("count is now " .. count)
  end, { count })

  return h("button", { on_press = function () set_count(count + 1) end },
    props.label, ": ", count)
end
```

## Install

Copy the `luact` folder into your project, or add the repository to your `package.path`. For LÖVE, also copy `luact-love`.

## Documentation

- [Getting started](docs/getting-started.md)
- [API reference](docs/api.md)
- [Writing a renderer](docs/renderers.md)
- [LÖVE renderer](docs/love.md)
- [How the reconciler works](docs/architecture.md)
- [Migrating from the old API](docs/migration.md)

## Examples

Run these from the repository root.

- `lua examples/console/custom_renderer.lua` builds a renderer that prints text.
- `lua examples/console/counter.lua` shows state, effects, context and timers.
- `love examples/love` runs an animated grid with keyboard input.

## Development

The tests use [busted](https://lunarmodules.github.io/busted/) and the linter is [luacheck](https://github.com/lunarmodules/luacheck).

```sh
luarocks install busted
luarocks install luacheck

busted          # run the tests
luacheck .      # lint
```

## Credits

- The React team, for React and its reconciler.
- Maxim Koretskyi, for his articles on the Fiber architecture.
- [Rodrigo Pombo](https://github.com/pomber), for [Didact](https://github.com/pomber/didact).

## License

MIT. See [LICENSE](LICENSE).
