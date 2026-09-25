local luact = require "luact"
local test_renderer = require "luact.test_renderer"

local h = luact.create_element
local act = test_renderer.act

describe("portals", function ()
  it("renders children into another container", function ()
    local modal = test_renderer.create_container()
    local instance = test_renderer.create(
      h("app", nil, h("main"), luact.create_portal(h("dialog", nil, "hi"), modal))
    )
    assert.are.equal("<app><main /></app>", instance:to_string())
    assert.are.equal("<dialog>hi</dialog>", test_renderer.to_string(modal.children))

    instance:update(h("app", nil, h("main")))
    assert.are.equal(0, #modal.children)
  end)

  it("passes context through the portal", function ()
    local Theme = luact.create_context("light")
    local modal = test_renderer.create_container()
    local function Label()
      return h("v", { theme = luact.use_context(Theme) })
    end
    test_renderer.create(h(Theme, { value = "dark" }, luact.create_portal(h(Label), modal)))
    assert.are.equal('<v theme="dark" />', test_renderer.to_string(modal.children))
  end)

  it("removes portal children when an ancestor host node is removed", function ()
    local modal = test_renderer.create_container()
    local instance = test_renderer.create(
      h("app", nil, h("wrapper", nil, luact.create_portal(h("dialog"), modal)))
    )
    assert.are.equal(1, #modal.children)
    instance:update(h("app"))
    assert.are.equal(0, #modal.children)
  end)

  it("keeps host siblings in order around a portal", function ()
    local modal = test_renderer.create_container()
    local function App(props)
      return h("app", nil,
        props.first and h("first") or false,
        luact.create_portal(h("dialog"), modal),
        h("last")
      )
    end
    local instance = test_renderer.create(h(App, { first = false }))
    instance:update(h(App, { first = true }))
    assert.are.equal("<app><first /><last /></app>", instance:to_string())
  end)
end)

describe("refs", function ()
  it("attaches host instances to ref objects", function ()
    local ref = luact.create_ref()
    local instance = test_renderer.create(h("box", { ref = ref }))
    assert.are.equal(instance:nodes()[1], ref.current)
    instance:unmount()
    assert.is_nil(ref.current)
  end)

  it("works with use_ref", function ()
    local seen
    local function App()
      local ref = luact.use_ref()
      luact.use_layout_effect(function ()
        seen = ref.current
      end, {})
      return h("box", { ref = ref })
    end
    local instance = test_renderer.create(h(App))
    assert.are.equal(instance:nodes()[1], seen)
  end)

  it("calls callback refs with the instance and nil", function ()
    local calls = {}
    local function callback(node)
      calls[#calls + 1] = node and node.type or "nil"
    end
    local instance = test_renderer.create(h("box", { ref = callback }))
    instance:update(h("box", { ref = callback }))
    assert.are.same({ "box" }, calls)
    instance:unmount()
    assert.are.same({ "box", "nil" }, calls)
  end)

  it("uses the cleanup returned by a callback ref", function ()
    local calls = {}
    local instance = test_renderer.create(h("box", {
      ref = function ()
        calls[#calls + 1] = "attach"
        return function ()
          calls[#calls + 1] = "cleanup"
        end
      end,
    }))
    instance:unmount()
    assert.are.same({ "attach", "cleanup" }, calls)
  end)

  it("moves the ref when it changes", function ()
    local a, b = luact.create_ref(), luact.create_ref()
    local instance = test_renderer.create(h("box", { ref = a }))
    local node = instance:nodes()[1]
    instance:update(h("box", { ref = b }))
    assert.is_nil(a.current)
    assert.are.equal(node, b.current)
  end)

  it("passes ref as a regular prop to function components", function ()
    local ref = luact.create_ref()
    local function Input(props)
      return h("input", { ref = props.ref })
    end
    local instance = test_renderer.create(h(Input, { ref = ref }))
    assert.are.equal(instance:nodes()[1], ref.current)
  end)

  it("sets refs before layout effects of parents run", function ()
    local seen
    local function Child(props)
      return h("child", { ref = props.child_ref })
    end
    local function Parent()
      local ref = luact.use_ref()
      luact.use_layout_effect(function ()
        seen = ref.current and ref.current.type
      end, {})
      return h(Child, { child_ref = ref })
    end
    act(function ()
      test_renderer.create(h(Parent))
    end)
    assert.are.equal("child", seen)
  end)
end)
