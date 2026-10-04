local luact = require "luact"
local test_renderer = require "luact.test_renderer"

local h = luact.create_element
local act = test_renderer.act

describe("use_state", function ()
  it("updates state and re-renders", function ()
    local set_count
    local function Counter()
      local count, set = luact.use_state(0)
      set_count = set
      return h("count", { value = count })
    end
    local instance = test_renderer.create(h(Counter))
    act(function ()
      set_count(1)
    end)
    assert.are.equal("<count value=1 />", instance:to_string())
    act(function ()
      set_count(function (n)
        return n + 10
      end)
    end)
    assert.are.equal("<count value=11 />", instance:to_string())
  end)

  it("supports a lazy initial state", function ()
    local calls = 0
    local set_value
    local function App()
      local value, set = luact.use_state(function ()
        calls = calls + 1
        return "init"
      end)
      set_value = set
      return h("v", { value = value })
    end
    local instance = test_renderer.create(h(App))
    act(function ()
      set_value("next")
    end)
    assert.are.equal(1, calls)
    assert.are.equal('<v value="next" />', instance:to_string())
  end)

  it("batches updates", function ()
    local renders = 0
    local set_a, set_b
    local function App()
      local a, sa = luact.use_state(0)
      local b, sb = luact.use_state(0)
      set_a, set_b = sa, sb
      renders = renders + 1
      return h("v", { a = a, b = b })
    end
    local instance = test_renderer.create(h(App))
    act(function ()
      set_a(1)
      set_b(2)
      set_a(function (n)
        return n + 1
      end)
    end)
    assert.are.equal(2, renders)
    assert.are.equal("<v a=2 b=2 />", instance:to_string())
  end)

  it("does not render when setting the same value", function ()
    local renders = 0
    local set_value
    local function App()
      local value, set = luact.use_state("same")
      set_value = set
      renders = renders + 1
      return h("v", { value = value })
    end
    test_renderer.create(h(App))
    act(function ()
      set_value("same")
    end)
    assert.are.equal(1, renders)
  end)

  it("keeps the setter identity", function ()
    local setters = {}
    local set_value
    local function App()
      local _, set = luact.use_state(0)
      setters[#setters + 1] = set
      set_value = set
      return nil
    end
    test_renderer.create(h(App))
    act(function ()
      set_value(1)
    end)
    assert.are.equal(2, #setters)
    assert.are.equal(setters[1], setters[2])
  end)

  it("renders again when a component updates itself during render", function ()
    local renders = 0
    local function App(props)
      local previous, set_previous = luact.use_state(props.value)
      local changed, set_changed = luact.use_state(false)
      renders = renders + 1
      if previous ~= props.value then
        set_previous(props.value)
        set_changed(true)
      end
      return h("v", { changed = changed })
    end
    local instance = test_renderer.create(h(App, { value = 1 }))
    renders = 0
    instance:update(h(App, { value = 2 }))
    assert.are.equal(2, renders)
    assert.are.equal("<v changed=true />", instance:to_string())
  end)

  it("stops infinite render loops", function ()
    local function App()
      local value, set_value = luact.use_state(0)
      set_value(value + 1)
      return nil
    end
    assert.has_error(function ()
      test_renderer.create(h(App))
    end)
  end)

  it("ignores updates on unmounted components", function ()
    local set_value
    local function App()
      local _, set = luact.use_state(0)
      set_value = set
      return nil
    end
    local instance = test_renderer.create(h(App))
    instance:unmount()
    act(function ()
      set_value(1)
    end)
    assert.is_false(test_renderer.renderer.has_pending_work())
  end)
end)

describe("use_reducer", function ()
  it("reduces actions", function ()
    local function reducer(state, action)
      if action.type == "add" then
        return state + action.amount
      end
      return state
    end
    local dispatch
    local function App()
      local total, d = luact.use_reducer(reducer, 10)
      dispatch = d
      return h("total", { value = total })
    end
    local instance = test_renderer.create(h(App))
    act(function ()
      dispatch({ type = "add", amount = 5 })
      dispatch({ type = "add", amount = 1 })
    end)
    assert.are.equal("<total value=16 />", instance:to_string())
  end)

  it("uses init to compute the initial state", function ()
    local function App()
      local state = luact.use_reducer(function (s) return s end, 3, function (n)
        return n * 2
      end)
      return h("v", { value = state })
    end
    local instance = test_renderer.create(h(App))
    assert.are.equal("<v value=6 />", instance:to_string())
  end)
end)

describe("effects", function ()
  local log

  before_each(function ()
    log = {}
  end)

  local function Child(props)
    luact.use_layout_effect(function ()
      log[#log + 1] = "layout " .. props.name
      return function ()
        log[#log + 1] = "layout cleanup " .. props.name
      end
    end)
    luact.use_effect(function ()
      log[#log + 1] = "effect " .. props.name
      return function ()
        log[#log + 1] = "effect cleanup " .. props.name
      end
    end)
    return nil
  end

  it("runs layout effects before passive effects, children first", function ()
    local function Parent()
      luact.use_effect(function ()
        log[#log + 1] = "effect parent"
      end)
      luact.use_layout_effect(function ()
        log[#log + 1] = "layout parent"
      end)
      return h(luact.Fragment, nil, h(Child, { name = "a" }), h(Child, { name = "b" }))
    end
    test_renderer.create(h(Parent))
    assert.are.same({
      "layout a",
      "layout b",
      "layout parent",
      "effect a",
      "effect b",
      "effect parent",
    }, log)
  end)

  it("runs every cleanup before the next effects", function ()
    local instance = test_renderer.create(h(luact.Fragment, nil,
      h(Child, { name = "a" }),
      h(Child, { name = "b" })
    ))
    log = {}
    instance:update(h(luact.Fragment, nil,
      h(Child, { name = "a" }),
      h(Child, { name = "b" })
    ))
    assert.are.same({
      "layout cleanup a",
      "layout cleanup b",
      "layout a",
      "layout b",
      "effect cleanup a",
      "effect cleanup b",
      "effect a",
      "effect b",
    }, log)
  end)

  it("runs cleanups on unmount", function ()
    local instance = test_renderer.create(h(Child, { name = "a" }))
    log = {}
    instance:unmount()
    assert.are.same({ "layout cleanup a", "effect cleanup a" }, log)
  end)

  it("does not run passive effects until the work loop runs again", function ()
    local container = test_renderer.create_container()
    local root = test_renderer.renderer.create_root(container)
    root:render(h(Child, { name = "a" }))
    test_renderer.renderer.flush_sync()
    assert.are.same({ "layout a" }, log)
    test_renderer.renderer.work_loop()
    assert.are.same({ "layout a", "effect a" }, log)
    root:unmount()
  end)

  it("only runs again when dependencies change", function ()
    local function App(props)
      luact.use_effect(function ()
        log[#log + 1] = "effect " .. tostring(props.a)
      end, { props.a })
      return nil
    end
    local instance = test_renderer.create(h(App, { a = 1, b = 1 }))
    instance:update(h(App, { a = 1, b = 2 }))
    instance:update(h(App, { a = 2, b = 2 }))
    assert.are.same({ "effect 1", "effect 2" }, log)
  end)

  it("treats nil dependencies correctly", function ()
    local function App(props)
      luact.use_effect(function ()
        log[#log + 1] = "effect"
      end, { props.a, props.b })
      return nil
    end
    local instance = test_renderer.create(h(App, { a = nil, b = 1 }))
    instance:update(h(App, { a = nil, b = 1 }))
    instance:update(h(App, { a = 1, b = 1 }))
    assert.are.same({ "effect", "effect" }, log)
  end)

  it("runs once with empty dependencies", function ()
    local function App(props)
      luact.use_effect(function ()
        log[#log + 1] = "effect"
      end, {})
      return h("v", { value = props.value })
    end
    local instance = test_renderer.create(h(App, { value = 1 }))
    instance:update(h(App, { value = 2 }))
    assert.are.same({ "effect" }, log)
  end)

  it("renders layout effect updates before returning", function ()
    local function App()
      local width, set_width = luact.use_state(0)
      luact.use_layout_effect(function ()
        set_width(100)
      end, {})
      return h("v", { width = width })
    end
    local container = test_renderer.create_container()
    local root = test_renderer.renderer.create_root(container)
    root:render(h(App))
    -- With a deadline that is always reached, each call does one unit of
    -- work. The call that commits also renders the layout effect update.
    local function exhausted()
      return 0
    end
    while #container.children == 0 do
      test_renderer.renderer.work_loop(exhausted)
    end
    assert.are.equal("<v width=100 />", test_renderer.to_string(container.children))
    root:unmount()
  end)

  it("runs insertion effects before layout effects", function ()
    local function App()
      luact.use_layout_effect(function ()
        log[#log + 1] = "layout"
      end)
      luact.use_insertion_effect(function ()
        log[#log + 1] = "insertion"
      end)
      return nil
    end
    test_renderer.create(h(App))
    assert.are.same({ "insertion", "layout" }, log)
  end)

  it("rejects effects returning a non-function", function ()
    local function App()
      luact.use_effect(function ()
        return 1
      end)
      return nil
    end
    assert.has_error(function ()
      test_renderer.create(h(App))
    end)
  end)
end)

describe("use_memo and use_callback", function ()
  it("recomputes only when dependencies change", function ()
    local computations = 0
    local function App(props)
      local value = luact.use_memo(function ()
        computations = computations + 1
        return props.a * 2
      end, { props.a })
      return h("v", { value = value })
    end
    local instance = test_renderer.create(h(App, { a = 1, b = 1 }))
    instance:update(h(App, { a = 1, b = 2 }))
    assert.are.equal(1, computations)
    instance:update(h(App, { a = 2, b = 2 }))
    assert.are.equal(2, computations)
    assert.are.equal("<v value=4 />", instance:to_string())
  end)

  it("keeps the callback identity", function ()
    local callbacks = {}
    local function App(props)
      callbacks[#callbacks + 1] = luact.use_callback(function () end, { props.a })
      return nil
    end
    local instance = test_renderer.create(h(App, { a = 1 }))
    instance:update(h(App, { a = 1 }))
    instance:update(h(App, { a = 2 }))
    assert.are.equal(callbacks[1], callbacks[2])
    assert.are_not.equal(callbacks[2], callbacks[3])
  end)
end)

describe("use_ref", function ()
  it("keeps the same table", function ()
    local refs = {}
    local function App(props)
      refs[#refs + 1] = luact.use_ref(props.value)
      return nil
    end
    local instance = test_renderer.create(h(App, { value = 1 }))
    instance:update(h(App, { value = 2 }))
    assert.are.equal(refs[1], refs[2])
    assert.are.equal(1, refs[2].current)
  end)
end)

describe("use_imperative_handle", function ()
  it("sets the ref and clears it on unmount", function ()
    local ref = luact.create_ref()
    local function Input(props)
      luact.use_imperative_handle(props.ref, function ()
        return { focus = "focused" }
      end, {})
      return nil
    end
    local instance = test_renderer.create(h(Input, { ref = ref }))
    assert.are.equal("focused", ref.current.focus)
    instance:unmount()
    assert.is_nil(ref.current)
  end)
end)

describe("use_id", function ()
  it("is stable and unique", function ()
    local ids = {}
    local function App(props)
      ids[#ids + 1] = luact.use_id()
      return h("v", { value = props.value })
    end
    local instance = test_renderer.create(h(luact.Fragment, nil, h(App), h(App)))
    instance:update(h(luact.Fragment, nil, h(App, { value = 1 }), h(App, { value = 1 })))
    assert.are.equal(ids[1], ids[3])
    assert.are.equal(ids[2], ids[4])
    assert.are_not.equal(ids[1], ids[2])
  end)
end)

describe("use_sync_external_store", function ()
  local function create_store(value)
    local listeners = {}
    local store = {}
    function store.get()
      return value
    end
    function store.set(next_value)
      value = next_value
      for listener in pairs(listeners) do
        listener()
      end
    end
    function store.subscribe(listener)
      listeners[listener] = true
      return function ()
        listeners[listener] = nil
      end
    end
    function store.listener_count()
      local count = 0
      for _ in pairs(listeners) do
        count = count + 1
      end
      return count
    end
    return store
  end

  it("renders the store value and follows changes", function ()
    local store = create_store(1)
    local function App()
      local value = luact.use_sync_external_store(store.subscribe, store.get)
      return h("v", { value = value })
    end
    local instance = test_renderer.create(h(App))
    assert.are.equal("<v value=1 />", instance:to_string())
    act(function ()
      store.set(2)
    end)
    assert.are.equal("<v value=2 />", instance:to_string())
    instance:unmount()
    assert.are.equal(0, store.listener_count())
  end)
end)

describe("rules of hooks", function ()
  it("rejects hooks outside components", function ()
    assert.has_error(function ()
      luact.use_state(0)
    end)
  end)

  it("rejects a changed hook order", function ()
    local function App(props)
      if props.flag then
        luact.use_ref()
      else
        luact.use_state()
      end
      return nil
    end
    local instance = test_renderer.create(h(App, { flag = true }))
    assert.has_error(function ()
      instance:update(h(App, { flag = false }))
    end)
  end)

  it("rejects fewer hooks than before", function ()
    local function App(props)
      luact.use_ref()
      if props.flag then
        luact.use_ref()
      end
      return nil
    end
    local instance = test_renderer.create(h(App, { flag = true }))
    assert.has_error(function ()
      instance:update(h(App, { flag = false }))
    end)
  end)

  it("rejects more hooks than before", function ()
    local function App(props)
      luact.use_ref()
      if props.flag then
        luact.use_ref()
      end
      return nil
    end
    local instance = test_renderer.create(h(App, { flag = false }))
    assert.has_error(function ()
      instance:update(h(App, { flag = true }))
    end)
  end)
end)
