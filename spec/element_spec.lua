local luact = require "luact"

local h = luact.create_element

describe("create_element", function ()
  it("creates an element with type, props and key", function ()
    local element = h("box", { key = 1, id = "a" })
    assert.are.equal("box", element.type)
    assert.are.equal("1", element.key)
    assert.are.equal("a", element.props.id)
    assert.is_nil(element.props.key)
    assert.is_true(luact.is_valid_element(element))
  end)

  it("does not modify the props table", function ()
    local config = { key = "k", id = "a" }
    h("box", config)
    assert.are.equal("k", config.key)
  end)

  it("keeps ref in props and on the element", function ()
    local ref = luact.create_ref()
    local element = h("box", { ref = ref })
    assert.are.equal(ref, element.ref)
    assert.are.equal(ref, element.props.ref)
  end)

  it("stores a single child as is", function ()
    local element = h("box", nil, "text")
    assert.are.equal("text", element.props.children)
  end)

  it("stores several children as an array with false for nil", function ()
    local element = h("box", nil, "a", nil, "c")
    assert.are.same({ "a", false, "c" }, element.props.children)
  end)

  it("overrides props.children with varargs", function ()
    local element = h("box", { children = "old" }, "new")
    assert.are.equal("new", element.props.children)
  end)

  it("rejects a nil type", function ()
    assert.has_error(function ()
      h(nil)
    end)
  end)
end)

describe("clone_element", function ()
  it("merges props and keeps the key", function ()
    local element = h("box", { key = "k", a = 1, b = 2 })
    local clone = luact.clone_element(element, { b = 3 })
    assert.are.equal("k", clone.key)
    assert.are.same({ a = 1, b = 3 }, clone.props)
  end)

  it("replaces the key and children", function ()
    local element = h("box", { key = "k" }, "a")
    local clone = luact.clone_element(element, { key = "z" }, "b")
    assert.are.equal("z", clone.key)
    assert.are.equal("b", clone.props.children)
  end)
end)

describe("children helpers", function ()
  local children = luact.children

  it("flattens and drops empty values", function ()
    local a, b, c = h("a"), h("b"), h("c")
    assert.are.same({ a, b, "x", c }, children.to_array({ a, false, { b, true, "x" }, c }))
    assert.are.equal(4, children.count({ a, false, { b, "x" }, c }))
  end)

  it("maps with the index", function ()
    local result = children.map({ "a", "b" }, function (child, i)
      return child .. i
    end)
    assert.are.same({ "a1", "b2" }, result)
  end)

  it("only accepts a single element", function ()
    local a = h("a")
    assert.are.equal(a, children.only(a))
    assert.has_error(function ()
      children.only({ a, a })
    end)
  end)
end)

describe("memo", function ()
  it("rejects non-functions", function ()
    assert.has_error(function ()
      luact.memo("box")
    end)
  end)
end)

describe("create_context", function ()
  it("is its own provider", function ()
    local context = luact.create_context(1)
    assert.are.equal(context, context.Provider)
    assert.are.equal(1, context.default_value)
    assert.are.equal(context, context.Consumer.context)
  end)
end)
