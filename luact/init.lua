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
local renderer = require "luact.renderer"

local function init(reconciler)
  reconciler = setmetatable(reconciler, Reconciler)

  local function Fragment(props)
    return {
      type = tags.type.FRAGMENT,
      props = props,
    }
  end

  local function component(renderer, config)
    return function (props)
      return {
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
        type = tags.type.MEMO_BASIC,
        constructor = renderer,
        props = props,
        config = config,
      }
    end
  end

  local function Element(constructor, props)
    return {
      type = tags.type.HOST,
      constructor = constructor,
      props = props,
    }
  end

  renderer(reconciler)

  local function render(element, container)
    reconciler.render(element, container)
  end

  return {
    Fragment = Fragment,
    component = component,
    basic = basic,
    memo = memo,
    memo_basic = memo_basic,
    Element = Element,
    render = render,
  }
end

return {
  init = init,

  use_state = require "luact.hooks.use_state",
}