local luact = require "luact"
local test_renderer = require "luact.test_renderer"

local h = luact.create_element
local act = test_renderer.act

describe("bailouts", function ()
  it("only renders the component that updated", function ()
    local renders = {}
    local set_value

    local function Leaf(props)
      renders[#renders + 1] = props.name
      return nil
    end

    local function Stateful()
      local value, set = luact.use_state(0)
      set_value = set
      renders[#renders + 1] = "stateful"
      return h("v", { value = value }, h(Leaf, { name = "inner" }))
    end

    local function App()
      renders[#renders + 1] = "app"
      return h(luact.Fragment, nil, h(Stateful), h(Leaf, { name = "sibling" }))
    end

    test_renderer.create(h(App))
    renders = {}
    act(function ()
      set_value(1)
    end)
    -- the inner leaf gets new props, the sibling and the app are skipped
    assert.are.same({ "stateful", "inner" }, renders)
  end)

  it("skips children passed from above when the parent re-renders", function ()
    local renders = 0
    local set_value

    local function Child()
      renders = renders + 1
      return nil
    end

    local function Wrapper(props)
      local value, set = luact.use_state(0)
      set_value = set
      return h("v", { value = value }, props.children)
    end

    test_renderer.create(h(Wrapper, nil, h(Child)))
    renders = 0
    act(function ()
      set_value(1)
    end)
    assert.are.equal(0, renders)
  end)

  it("keeps a component when its state is set back to the same value", function ()
    local renders = 0
    local set_value
    local function App()
      local value, set = luact.use_state(0)
      set_value = set
      renders = renders + 1
      return h("v", { value = value })
    end
    local instance = test_renderer.create(h(App))
    act(function ()
      set_value(1)
      set_value(0)
    end)
    assert.are.equal("<v value=0 />", instance:to_string())
  end)
end)

describe("memo", function ()
  it("skips rendering when props are shallowly equal", function ()
    local renders = 0
    local Item = luact.memo(function (props)
      renders = renders + 1
      return h("item", { label = props.label })
    end)
    local instance = test_renderer.create(h(Item, { label = "a" }))
    instance:update(h(Item, { label = "a" }))
    assert.are.equal(1, renders)
    instance:update(h(Item, { label = "b" }))
    assert.are.equal(2, renders)
    assert.are.equal('<item label="b" />', instance:to_string())
  end)

  it("uses a custom compare", function ()
    local renders = 0
    local Item = luact.memo(function ()
      renders = renders + 1
      return nil
    end, function (old_props, new_props)
      return old_props.id == new_props.id
    end)
    local instance = test_renderer.create(h(Item, { id = 1, other = 1 }))
    instance:update(h(Item, { id = 1, other = 2 }))
    assert.are.equal(1, renders)
    instance:update(h(Item, { id = 2, other = 2 }))
    assert.are.equal(2, renders)
  end)

  it("still renders on its own state updates", function ()
    local set_value
    local Item = luact.memo(function ()
      local value, set = luact.use_state(0)
      set_value = set
      return h("v", { value = value })
    end)
    local instance = test_renderer.create(h(Item))
    act(function ()
      set_value(3)
    end)
    assert.are.equal("<v value=3 />", instance:to_string())
  end)

  it("can hold hooks and effects", function ()
    local log = {}
    local Item = luact.memo(function (props)
      luact.use_effect(function ()
        log[#log + 1] = "effect " .. props.id
        return function ()
          log[#log + 1] = "cleanup " .. props.id
        end
      end, { props.id })
      return nil
    end)
    local instance = test_renderer.create(h(Item, { id = 1 }))
    instance:update(h(Item, { id = 1 }))
    instance:update(h(Item, { id = 2 }))
    instance:unmount()
    assert.are.same({ "effect 1", "cleanup 1", "effect 2", "cleanup 2" }, log)
  end)
end)

describe("context", function ()
  it("reads the default value without a provider", function ()
    local Theme = luact.create_context("light")
    local function App()
      return h("v", { theme = luact.use_context(Theme) })
    end
    local instance = test_renderer.create(h(App))
    assert.are.equal('<v theme="light" />', instance:to_string())
  end)

  it("reads the nearest provider", function ()
    local Theme = luact.create_context("light")
    local function Label()
      return h("v", { theme = luact.use_context(Theme) })
    end
    local instance = test_renderer.create(
      h(Theme, { value = "dark" },
        h(Label),
        h(Theme.Provider, { value = "blue" }, h(Label))
      )
    )
    assert.are.equal('<v theme="dark" /><v theme="blue" />', instance:to_string())
  end)

  it("updates consumers below a memo component that bails out", function ()
    local Theme = luact.create_context("light")
    local renders = 0
    local set_theme

    local function Label()
      return h("v", { theme = luact.use_context(Theme) })
    end

    local Blocker = luact.memo(function ()
      renders = renders + 1
      return h(Label)
    end)

    local function App()
      local theme, set = luact.use_state("dark")
      set_theme = set
      return h(Theme, { value = theme }, h(Blocker))
    end

    local instance = test_renderer.create(h(App))
    act(function ()
      set_theme("blue")
    end)
    assert.are.equal('<v theme="blue" />', instance:to_string())
    assert.are.equal(1, renders)
  end)

  it("updates consumers of a memo component that reads the context", function ()
    local Theme = luact.create_context("light")
    local set_theme

    local Label = luact.memo(function ()
      return h("v", { theme = luact.use_context(Theme) })
    end)

    local function App()
      local theme, set = luact.use_state("dark")
      set_theme = set
      return h(Theme, { value = theme }, h(Label))
    end

    local instance = test_renderer.create(h(App))
    act(function ()
      set_theme("blue")
    end)
    assert.are.equal('<v theme="blue" />', instance:to_string())
  end)

  it("does not update consumers of a shadowed context", function ()
    local Theme = luact.create_context("light")
    local renders = 0
    local set_theme

    local Label = luact.memo(function ()
      renders = renders + 1
      return h("v", { theme = luact.use_context(Theme) })
    end)

    local Inner = luact.memo(function ()
      return h(Theme, { value = "fixed" }, h(Label))
    end)

    local function App()
      local theme, set = luact.use_state("dark")
      set_theme = set
      return h(Theme, { value = theme }, h(Inner))
    end

    local instance = test_renderer.create(h(App))
    act(function ()
      set_theme("blue")
    end)
    assert.are.equal('<v theme="fixed" />', instance:to_string())
    assert.are.equal(1, renders)
  end)

  it("supports Consumer with a render function", function ()
    local Theme = luact.create_context("light")
    local instance = test_renderer.create(
      h(Theme, { value = "dark" },
        h(Theme.Consumer, nil, function (theme)
          return h("v", { theme = theme })
        end)
      )
    )
    assert.are.equal('<v theme="dark" />', instance:to_string())
  end)
end)
