-- Regression tests for bugs found in review.

local luact = require "luact"
local test_renderer = require "luact.test_renderer"

local h = luact.create_element

describe("callback ref cleanups", function ()
  it("survive re-renders", function ()
    local log = {}
    local function ref(node)
      log[#log + 1] = node and "attach" or "nil"
      return function ()
        log[#log + 1] = "cleanup"
      end
    end
    local function App(props)
      return h("box", { ref = ref, n = props.n })
    end
    local instance = test_renderer.create(h(App, { n = 1 }))
    instance:update(h(App, { n = 2 }))
    instance:unmount()
    assert.are.same({ "attach", "cleanup" }, log)
  end)

  it("are not used for the next ref", function ()
    local log = {}
    local function ref_a(node)
      log[#log + 1] = node and "A attach" or "A nil"
      return function ()
        log[#log + 1] = "A cleanup"
      end
    end
    local function ref_b(node)
      log[#log + 1] = node and "B attach" or "B nil"
    end
    local function App(props)
      return h("box", { ref = props.r, n = props.n })
    end
    local instance = test_renderer.create(h(App, { r = ref_a, n = 1 }))
    instance:update(h(App, { r = ref_a, n = 2 }))
    instance:update(h(App, { r = ref_b, n = 3 }))
    instance:unmount()
    assert.are.same({ "A attach", "A cleanup", "B attach", "B nil" }, log)
  end)
end)

describe("error boundaries showing their fallback", function ()
  it("pass later errors to the next boundary", function ()
    local inner_errors, outer_errors = {}, {}
    local function Thrower()
      luact.use_effect(function ()
        error("create", 0)
      end, {})
      return h("t")
    end
    local function CleanupThrower()
      luact.use_effect(function ()
        return function ()
          error("cleanup", 0)
        end
      end, {})
      return h("d")
    end
    local function App(props)
      return h(luact.ErrorBoundary, {
        fallback = "outer",
        on_error = function (err)
          outer_errors[#outer_errors + 1] = err
        end,
      }, h(luact.ErrorBoundary, {
        fallback = "inner",
        on_error = function (err)
          inner_errors[#inner_errors + 1] = err
        end,
      }, h(CleanupThrower), props.t and h(Thrower) or false))
    end
    local instance = test_renderer.create(h(App, { t = false }))
    instance:update(h(App, { t = true }))
    assert.are.same({ "create" }, inner_errors)
    assert.are.same({ "cleanup" }, outer_errors)
  end)
end)

describe("host errors during commit", function ()
  it("leave the root usable", function ()
    local fail = false
    local config = {}
    for k, v in pairs(test_renderer.host_config) do
      config[k] = v
    end
    config.reset_after_commit = function ()
      if fail then
        fail = false
        error("host fail", 0)
      end
    end
    local renderer = luact.create_renderer(config)
    local container = test_renderer.create_container()
    local root = renderer.create_root(container)
    renderer.act(function ()
      root:render(h("a", { id = 1 }))
    end)
    fail = true
    local ok, err = pcall(renderer.act, function ()
      root:render(h("b", { id = 2 }))
    end)
    assert.is_false(ok)
    assert.are.equal("host fail", err)
    renderer.act(function ()
      root:render(h("c", { id = 3 }))
    end)
    assert.are.equal("<c id=3 />", test_renderer.to_string(container.children))
  end)
end)

describe("several roots", function ()
  it("all make progress when each call only fits one root", function ()
    local renderer = test_renderer.renderer
    local a_container = test_renderer.create_container()
    local b_container = test_renderer.create_container()
    local a = renderer.create_root(a_container)
    local b = renderer.create_root(b_container)
    local items = {}
    for i = 1, 30 do
      items[i] = h("item", { key = i })
    end
    a:render(h("list", nil, items))
    b:render(h("single"))
    local function exhausted()
      return 0
    end
    for _ = 1, 10 do
      renderer.work_loop(exhausted)
    end
    assert.are.equal(1, #b_container.children)
    renderer.act()
    a:unmount()
    b:unmount()
  end)
end)
