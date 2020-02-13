--[[
  @license
  MIT License

  Copyright (c) 2020 Alexis Munsayac
  Permission is hereby granted, free of charge, to any person obtaining a copy
  of this software and associated documentation files (the "Software"), to deal
  in the Software without restriction, including without limitation the rights
  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
  copies of the Software, and to permit persons to whom the Software is
  furnished to do so, subject to the following conditions:

  The above copyright notice and this permission notice shall be included in all
  copies or substantial portions of the Software.

  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
  SOFTWARE.


  @author Alexis Munsayac <alexis.munsayac@gmail.com>
  @copyright Alexis Munsayac 2020
--]]
local tags = require "luact.tags"
local Reconciler = require "luact.reconciler"
local render = require "luact.fiber.render"
local work_loop = require "luact.fiber.work_loop"

local function init(reconciler)
  reconciler = setmetatable(reconciler, Reconciler)

  local function Fragment(props)
    return {
      reconciler = reconciler,
      type = tags.type.FRAGMENT,
      props = props,
    }
  end

  local function component(renderer, config)
    return function (props)
      return {
        reconciler = reconciler,
        type = tags.type.COMPONENT,
        constructor = renderer,
        props = props,
        config = config,
      }
    end
  end

  local function basic(renderer, config)
    return function (props)
      return {
        reconciler = reconciler,
        type = tags.type.BASIC,
        constructor = renderer,
        props = props,
        config = config,
      }
    end
  end

  local function memo(renderer, config)
    return function (props)
      return {
        reconciler = reconciler,
        type = tags.type.MEMO,
        constructor = renderer,
        props = props,
        config = config,
      }
    end
  end

  local function memo_basic(renderer, config)
    return function (props)
      return {
        reconciler = reconciler,
        type = tags.type.MEMO_BASIC,
        constructor = renderer,
        props = props,
        config = config,
      }
    end
  end

  local function Element(constructor, props)
    return {
      reconciler = reconciler,
      type = tags.type.HOST,
      constructor = constructor,
      props = props,
    }
  end

  work_loop(reconciler)

  return {
    Fragment = Fragment,
    component = component,
    basic = basic,
    memo = memo,
    memo_basic = memo_basic,
    Element = Element,
    render = function (element, container)
      render(reconciler, element, container)
    end,
  }
end

return {
  init = init,

  use_callback = require "luact.hooks.use_callback",
  use_constant = require "luact.hooks.use_constant",
  use_force_update = require "luact.hooks.use_force_update",
  use_layout_effect = require "luact.hooks.use_layout_effect",
  use_memo = require "luact.hooks.use_memo",
  use_reducer = require "luact.hooks.use_reducer",
  use_ref = require "luact.hooks.use_ref",
  use_state = require "luact.hooks.use_state",
}