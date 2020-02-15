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

local update_basic = require "luact.fiber.begin_work.update_basic"
local update_component = require "luact.fiber.begin_work.update_component"
local update_fragment = require "luact.fiber.begin_work.update_fragment"
local update_host = require "luact.fiber.begin_work.update_host"
local update_memo = require "luact.fiber.begin_work.update_memo"
local update_memo_basic = require "luact.fiber.begin_work.update_memo_basic"
local update_root = require "luact.fiber.begin_work.update_root"
local update_meta = require "luact.fiber.begin_work.update_meta"

return function (current, work_in_progress)
  if (work_in_progress.type == tags.type.BASIC) then
    return update_basic(current, work_in_progress)
  end
  if (work_in_progress.type == tags.type.COMPONENT) then
    return update_component(current, work_in_progress)
  end
  if (work_in_progress.type == tags.type.FRAGMENT) then
    return update_fragment(current, work_in_progress)
  end
  if (work_in_progress.type == tags.type.HOST) then
    return update_host(current, work_in_progress)
  end
  if (work_in_progress.type == tags.type.MEMO) then
    return update_memo(current, work_in_progress)
  end
  if (work_in_progress.type == tags.type.MEMO_BASIC) then
    return update_memo_basic(current, work_in_progress)
  end
  if (work_in_progress.type == tags.type.ROOT) then
    return update_root(current, work_in_progress)
  end
  if (work_in_progress.type == tags.type.META) then
    return update_meta(current, work_in_progress)
  end
  return nil
end