-- Runs luact-love against a fake `love` global that records draw calls.

local calls
local color

local function record(name)
  return function (...)
    calls[#calls + 1] = { name, ... }
  end
end

local fake_love = {
  timer = {
    getTime = function ()
      return 0
    end,
  },
  graphics = {
    push = record("push"),
    pop = record("pop"),
    translate = record("translate"),
    rotate = record("rotate"),
    scale = record("scale"),
    rectangle = record("rectangle"),
    circle = record("circle"),
    print = record("print"),
    printf = record("printf"),
    draw = record("draw"),
    getColor = function ()
      return color[1], color[2], color[3], color[4]
    end,
    setColor = function (r, g, b, a)
      color = { r, g, b, a }
      calls[#calls + 1] = { "setColor", r, g, b, a }
    end,
    getFont = function ()
      return "default font"
    end,
    setFont = record("setFont"),
  },
}

describe("luact-love", function ()
  local luact, luact_love, h

  setup(function ()
    _G.love = fake_love
    luact = require "luact"
    luact_love = require "luact-love"
    h = luact.create_element
  end)

  teardown(function ()
    luact_love.get_root():unmount()
    _G.love = nil
  end)

  before_each(function ()
    calls = {}
    color = { 1, 1, 1, 1 }
  end)

  local function render(element)
    luact_love.render(element)
    luact_love.renderer.act()
    calls = {}
  end

  it("draws primitives inside groups", function ()
    render(h("group", { x = 10, y = 20 },
      h("rectangle", { x = 1, y = 2, width = 3, height = 4, color = { 1, 0, 0 } }),
      h("circle", { mode = "line", radius = 5 })
    ))
    luact_love.draw()
    assert.are.same({
      { "push" },
      { "translate", 10, 20 },
      { "setColor", 1, 0, 0, 1 },
      { "rectangle", "fill", 1, 2, 3, 4 },
      { "setColor", 1, 1, 1, 1 },
      { "circle", "line", 0, 0, 5 },
      { "pop" },
    }, calls)
  end)

  it("draws text children", function ()
    render(h("text", { x = 5, y = 6 }, "Score: ", 10))
    luact_love.draw()
    assert.are.same({ { "print", "Score: 10", 5, 6 } }, calls)
  end)

  it("calls custom draw functions", function ()
    local drawn
    render(h("draw", {
      draw = function (node)
        drawn = node.type
      end,
    }))
    luact_love.draw()
    assert.are.equal("draw", drawn)
  end)

  it("rejects unknown host types when drawing", function ()
    render(h("unknown"))
    assert.has_error(function ()
      luact_love.draw()
    end)
    render(nil)
  end)

  it("delivers events to use_event handlers", function ()
    local pressed = {}
    local function App()
      luact_love.use_event("keypressed", function (key)
        pressed[#pressed + 1] = key
      end)
      return nil
    end
    render(h(App))
    luact_love.emit("keypressed", "space")
    render(nil)
    luact_love.emit("keypressed", "escape")
    assert.are.same({ "space" }, pressed)
  end)

  it("renders updates from update()", function ()
    local set_value
    local function App()
      local value, set = luact.use_state(1)
      set_value = set
      return h("text", nil, value)
    end
    render(h(App))
    set_value(2)
    luact_love.update(0.016)
    assert.are.equal("2", luact_love.stage.children[1].children[1].text)
  end)
end)
