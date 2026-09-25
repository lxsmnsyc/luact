local luact = require "luact"
local test_renderer = require "luact.test_renderer"

local h = luact.create_element
local renderer = test_renderer.renderer

-- A deadline that allows `units` calls before running out.
local function budget(units)
  return function ()
    units = units - 1
    if units > 0 then
      return 10
    end
    return 0
  end
end

local function wide_tree(count)
  local items = {}
  for i = 1, count do
    items[i] = h("item", { key = i, id = i })
  end
  return h("list", nil, items)
end

describe("work loop", function ()
  it("splits rendering across calls and commits once", function ()
    local container = test_renderer.create_container()
    local root = renderer.create_root(container)
    root:render(wide_tree(20))

    local calls = 0
    while renderer.work_loop(budget(5)) do
      calls = calls + 1
      if #container.children == 0 then
        -- nothing is committed before the whole tree is done
        assert.is_true(calls < 100)
      end
    end
    assert.is_true(calls > 1)
    assert.are.equal(20, #container.children[1].children)
    root:unmount()
  end)

  it("keeps updates dispatched while rendering", function ()
    local set_value
    local rendered = {}
    local function Stateful()
      local value, set = luact.use_state(0)
      set_value = set
      rendered[#rendered + 1] = value
      return h("v", { value = value })
    end
    local container = test_renderer.create_container()
    local root = renderer.create_root(container)
    root:render(h("box", nil, h(Stateful), wide_tree(10)))
    renderer.flush_sync()

    root:render(h("box", nil, h(Stateful), wide_tree(12)))
    -- start rendering, then update a component that was already visited
    renderer.work_loop(budget(4))
    set_value(7)
    while renderer.work_loop() do
    end
    assert.are.equal(7, rendered[#rendered])
    assert.are.equal("<v value=7 />", test_renderer.to_string(container.children[1].children[1]))
    root:unmount()
  end)

  it("rejects flush_sync while rendering", function ()
    local function App()
      renderer.flush_sync()
      return nil
    end
    local ok = pcall(test_renderer.create, h(App))
    assert.is_false(ok)
  end)

  it("reports whether work is pending", function ()
    local container = test_renderer.create_container()
    local root = renderer.create_root(container)
    assert.is_false(renderer.has_pending_work())
    root:render(h("box"))
    assert.is_true(renderer.has_pending_work())
    renderer.act()
    assert.is_false(renderer.has_pending_work())
    root:unmount()
  end)

  it("renders several roots", function ()
    local a = test_renderer.create(h("a"))
    local b = test_renderer.create(h("b"))
    assert.are.equal("<a />", a:to_string())
    assert.are.equal("<b />", b:to_string())
    a:unmount()
    b:unmount()
  end)
end)

describe("create_renderer", function ()
  it("requires the core host functions", function ()
    assert.has_error(function ()
      luact.create_renderer({})
    end)
  end)

  it("calls schedule_work when work is scheduled", function ()
    local scheduled = 0
    local config = {}
    for k, v in pairs(test_renderer.host_config) do
      config[k] = v
    end
    config.schedule_work = function ()
      scheduled = scheduled + 1
    end
    local custom = luact.create_renderer(config)
    local root = custom.create_root(test_renderer.create_container())
    root:render(h("box"))
    assert.are.equal(1, scheduled)
    custom.act()
    root:unmount()
  end)
end)
