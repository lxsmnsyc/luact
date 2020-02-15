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
local weakmap = require "luact.utils.weakmap"

local ERRORS = weakmap()

local function find_nearest_boundary(work_in_progress)
  local parent = work_in_progress.parent

  while (parent) do
    if (parent.type == tags.type.ERROR_BOUNDARY) then
      return parent
    end
    if (parent.type == tags.type.META) then
      return parent
    end
    parent = parent.parent
  end
  return nil
end

local function capture_error(work_in_progress, err)
  local parent = find_nearest_boundary(work_in_progress)

  if (parent) then
    local errors = ERRORS[parent] or {}
    table.insert(errors, err)
    ERRORS[parent] = errors
  else
    error(err)
  end
end

local function get_errors(work_in_progress)
  return ERRORS[work_in_progress]
end

return {
  capture = capture_error,
  get = get_errors,
  find_nearest_boundary = find_nearest_boundary,
}