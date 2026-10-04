local luact = require "luact"
local test_renderer = require "luact.test_renderer"

local h = luact.create_element
local act = test_renderer.act

local function Thrower(props)
  if props.fail then
    error("boom", 0)
  end
  return h("ok")
end

local function fallback(err)
  return h("fallback", { message = tostring(err) })
end

describe("ErrorBoundary", function ()
  it("renders the fallback when a child throws while rendering", function ()
    local instance = test_renderer.create(
      h(luact.ErrorBoundary, { fallback = fallback },
        h("before"),
        h(Thrower, { fail = true })
      )
    )
    assert.are.equal('<fallback message="boom" />', instance:to_string())
  end)

  it("accepts an element as fallback", function ()
    local instance = test_renderer.create(
      h(luact.ErrorBoundary, { fallback = h("oops") }, h(Thrower, { fail = true }))
    )
    assert.are.equal("<oops />", instance:to_string())
  end)

  it("keeps siblings of the boundary", function ()
    local instance = test_renderer.create(h("box", nil,
      h("left"),
      h(luact.ErrorBoundary, { fallback = fallback }, h(Thrower, { fail = true })),
      h("right")
    ))
    assert.are.equal(
      '<box><left /><fallback message="boom" /><right /></box>',
      instance:to_string()
    )
  end)

  it("catches errors thrown on update and removes the broken children", function ()
    local log = {}
    local function Tracked()
      luact.use_layout_effect(function ()
        return function ()
          log[#log + 1] = "cleanup"
        end
      end, {})
      return h("tracked")
    end
    local function App(props)
      return h(luact.ErrorBoundary, { fallback = fallback },
        h(Tracked),
        h(Thrower, { fail = props.fail })
      )
    end
    local instance = test_renderer.create(h(App, { fail = false }))
    assert.are.equal("<tracked /><ok />", instance:to_string())
    instance:update(h(App, { fail = true }))
    assert.are.equal('<fallback message="boom" />', instance:to_string())
    assert.are.same({ "cleanup" }, log)
  end)

  it("calls on_error with the error and a component stack", function ()
    local caught = {}
    test_renderer.create(
      h(luact.ErrorBoundary, {
        fallback = fallback,
        on_error = function (err, info)
          caught[#caught + 1] = { err = err, info = info }
        end,
      }, h(Thrower, { fail = true }))
    )
    assert.are.equal(1, #caught)
    assert.are.equal("boom", caught[1].err)
    assert.is_truthy(caught[1].info.component_stack:find("ErrorBoundary", 1, true))
  end)

  it("resets with the function given to the fallback", function ()
    local reset
    local should_fail = true
    local function Flaky()
      if should_fail then
        error("flaky", 0)
      end
      return h("recovered")
    end
    local instance = test_renderer.create(
      h(luact.ErrorBoundary, {
        fallback = function (_, reset_boundary)
          reset = reset_boundary
          return h("fallback")
        end,
      }, h(Flaky))
    )
    assert.are.equal("<fallback />", instance:to_string())
    should_fail = false
    act(function ()
      reset()
    end)
    assert.are.equal("<recovered />", instance:to_string())
  end)

  it("passes errors of the fallback to the next boundary", function ()
    local instance = test_renderer.create(
      h(luact.ErrorBoundary, { fallback = h("outer") },
        h(luact.ErrorBoundary, {
          fallback = function ()
            error("fallback failed", 0)
          end,
        }, h(Thrower, { fail = true }))
      )
    )
    assert.are.equal("<outer />", instance:to_string())
  end)

  it("catches errors thrown by effects", function ()
    local function Broken()
      luact.use_effect(function ()
        error("effect failed", 0)
      end, {})
      return h("broken")
    end
    local instance = test_renderer.create(
      h(luact.ErrorBoundary, { fallback = fallback }, h(Broken))
    )
    assert.are.equal('<fallback message="effect failed" />', instance:to_string())
  end)

  it("catches errors thrown by layout effects", function ()
    local function Broken()
      luact.use_layout_effect(function ()
        error("layout failed", 0)
      end, {})
      return h("broken")
    end
    local instance = test_renderer.create(
      h(luact.ErrorBoundary, { fallback = fallback }, h(Broken))
    )
    assert.are.equal('<fallback message="layout failed" />', instance:to_string())
  end)

  it("catches errors thrown by host instance creation", function ()
    local config = {}
    for k, v in pairs(test_renderer.host_config) do
      config[k] = v
    end
    config.create_instance = function (element_type, props)
      if element_type == "bad" then
        error("cannot create", 0)
      end
      return test_renderer.host_config.create_instance(element_type, props)
    end
    local renderer = luact.create_renderer(config)
    local container = test_renderer.create_container()
    local root = renderer.create_root(container)
    renderer.act(function ()
      root:render(h(luact.ErrorBoundary, { fallback = fallback }, h("box", nil, h("bad"))))
    end)
    assert.are.equal(
      '<fallback message="cannot create" />',
      test_renderer.to_string(container.children)
    )
    root:unmount()
  end)

  it("raises an error for invalid children to the boundary", function ()
    local instance = test_renderer.create(
      h(luact.ErrorBoundary, { fallback = h("oops") }, h("box", nil, function () end))
    )
    assert.are.equal("<oops />", instance:to_string())
  end)
end)

describe("uncaught errors", function ()
  it("unmount the root and raise the error", function ()
    local instance = test_renderer.create(h("box"))
    local ok, err = pcall(function ()
      instance:update(h(Thrower, { fail = true }))
    end)
    assert.is_false(ok)
    assert.are.equal("boom", err)
    assert.are.equal("", instance:to_string())
    assert.is_false(test_renderer.renderer.has_pending_work())

    -- the root can render again
    instance:update(h("box"))
    assert.are.equal("<box />", instance:to_string())
  end)
end)
