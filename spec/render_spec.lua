local luact = require "luact"
local test_renderer = require "luact.test_renderer"

local h = luact.create_element
local act = test_renderer.act

describe("rendering", function ()
  before_each(function ()
    test_renderer.clear_operations()
  end)

  it("mounts host components and text", function ()
    local instance = test_renderer.create(h("box", { id = 1 }, h("label", nil, "hello"), 42))
    assert.are.equal('<box id=1><label>hello</label>42</box>', instance:to_string())
  end)

  it("renders function components", function ()
    local function Greeting(props)
      return h("text", nil, "Hello, ", props.name)
    end
    local instance = test_renderer.create(h(Greeting, { name = "Lua" }))
    assert.are.equal("<text>Hello, Lua</text>", instance:to_string())
  end)

  it("renders fragments, nested arrays and skips empty values", function ()
    local function App()
      return h(luact.Fragment, nil,
        h("a"),
        false,
        { h("b", { key = "b" }), { h("c", { key = "c" }) } },
        nil,
        true,
        h("d")
      )
    end
    local instance = test_renderer.create(h(App))
    assert.are.equal("<a /><b /><c /><d />", instance:to_string())
  end)

  it("renders nothing for nil", function ()
    local function Empty()
      return nil
    end
    local instance = test_renderer.create(h("box", nil, h(Empty)))
    assert.are.equal("<box />", instance:to_string())
  end)

  it("does not render before the work loop runs", function ()
    local container = test_renderer.create_container()
    local root = test_renderer.renderer.create_root(container)
    root:render(h("box"))
    assert.are.equal(0, #container.children)
    test_renderer.renderer.work_loop()
    assert.are.equal(1, #container.children)
    root:unmount()
  end)

  it("updates host props in place", function ()
    local instance = test_renderer.create(h("box", { id = 1, color = "red" }))
    local node = instance:nodes()[1]
    test_renderer.clear_operations()
    instance:update(h("box", { id = 1, color = "blue" }))
    assert.are.equal(node, instance:nodes()[1])
    assert.are.equal("blue", node.props.color)
    assert.are.same({ "update box#1" }, test_renderer.operations)
  end)

  it("updates text in place", function ()
    local instance = test_renderer.create(h("box", nil, "a"))
    test_renderer.clear_operations()
    instance:update(h("box", nil, "b"))
    assert.are.equal("<box>b</box>", instance:to_string())
    assert.are.same({ 'update text "b"' }, test_renderer.operations)
  end)

  it("replaces a node when the type changes", function ()
    local instance = test_renderer.create(h("box", { id = 1 }, h("a")))
    test_renderer.clear_operations()
    instance:update(h("box", { id = 1 }, h("b")))
    assert.are.equal("<box id=1><b /></box>", instance:to_string())
    assert.are.same({ "remove a from box#1", "append b to box#1" }, test_renderer.operations)
  end)

  it("replaces a component when the component type changes", function ()
    local function A() return h("a") end
    local function B() return h("b") end
    local instance = test_renderer.create(h(A))
    instance:update(h(B))
    assert.are.equal("<b />", instance:to_string())
  end)

  it("unmounts everything", function ()
    local instance = test_renderer.create(h("box", nil, h("a"), h("b")))
    test_renderer.clear_operations()
    instance:unmount()
    assert.are.equal("", instance:to_string())
    assert.are.same({ "remove box from root" }, test_renderer.operations)
  end)

  it("raises an error for invalid children", function ()
    assert.has_error(function ()
      test_renderer.create(h("box", nil, function () end))
    end)
  end)

  it("raises an error for an invalid element type", function ()
    assert.has_error(function ()
      test_renderer.create(h(42))
    end)
  end)
end)

describe("keyed children", function ()
  local function List(props)
    local items = {}
    for i, key in ipairs(props.keys) do
      items[i] = h("item", { key = key, id = key })
    end
    return h("list", nil, items)
  end

  local function ids(instance)
    local result = {}
    for i, node in ipairs(instance:find_all("item")) do
      result[i] = node.props.id
    end
    return table.concat(result, ",")
  end

  local cases = {
    { from = { "a", "b", "c" }, to = { "c", "b", "a" } },
    { from = { "a", "b", "c", "d" }, to = { "d", "a", "c", "e" } },
    { from = { "a", "b" }, to = { "x", "a", "y", "b", "z" } },
    { from = { "a", "b", "c", "d", "e" }, to = { "e" } },
    { from = {}, to = { "a", "b" } },
    { from = { "a", "b" }, to = {} },
    { from = { "a", "b", "c", "d" }, to = { "b", "d", "a", "c" } },
  }

  for _, case in ipairs(cases) do
    local name = table.concat(case.from, ",") .. " -> " .. table.concat(case.to, ",")
    it("reorders " .. name, function ()
      local instance = test_renderer.create(h(List, { keys = case.from }))
      local nodes = {}
      for _, node in ipairs(instance:find_all("item")) do
        nodes[node.props.id] = node
      end
      instance:update(h(List, { keys = case.to }))
      assert.are.equal(table.concat(case.to, ","), ids(instance))
      -- kept items reuse their host node
      for _, node in ipairs(instance:find_all("item")) do
        if nodes[node.props.id] ~= nil then
          assert.are.equal(nodes[node.props.id], node)
        end
      end
    end)
  end

  it("moves with the minimum of host operations for a single move", function ()
    local instance = test_renderer.create(h(List, { keys = { "a", "b", "c" } }))
    test_renderer.clear_operations()
    instance:update(h(List, { keys = { "b", "c", "a" } }))
    assert.are.same({ "append item#a to list" }, test_renderer.operations)
  end)

  it("inserts in the middle with insert_before", function ()
    local instance = test_renderer.create(h(List, { keys = { "a", "c" } }))
    test_renderer.clear_operations()
    instance:update(h(List, { keys = { "a", "b", "c" } }))
    assert.are.same({ "insert item#b before item#c" }, test_renderer.operations)
  end)

  it("keeps state with the key", function ()
    local setters = {}
    local function Item(props)
      local value, set_value = luact.use_state(props.id)
      setters[props.id] = set_value
      return h("item", { id = value })
    end
    local function Items(props)
      local items = {}
      for i, key in ipairs(props.keys) do
        items[i] = h(Item, { key = key, id = key })
      end
      return h("list", nil, items)
    end
    local instance = test_renderer.create(h(Items, { keys = { "a", "b" } }))
    act(function ()
      setters.a("A")
    end)
    instance:update(h(Items, { keys = { "b", "a" } }))
    assert.are.equal('<list><item id="b" /><item id="A" /></list>', instance:to_string())
  end)

  it("keeps positions stable with false holes", function ()
    local renders = 0
    local function Counter()
      local value = luact.use_ref(0)
      renders = renders + 1
      value.current = value.current + 1
      return h("counter", { mounts = value.current })
    end
    local function App(props)
      return h("box", nil, props.show and h("first") or false, h(Counter))
    end
    local instance = test_renderer.create(h(App, { show = true }))
    instance:update(h(App, { show = false }))
    instance:update(h(App, { show = true }))
    -- the counter kept its fiber, so its ref was not reset
    assert.are.equal("<box><first /><counter mounts=3 /></box>", instance:to_string())
  end)
end)
