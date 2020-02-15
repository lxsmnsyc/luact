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

local commit_placement = require "luact.fiber.commit_placement"
local commit_update = require "luact.fiber.commit_update"
local commit_delete = require "luact.fiber.commit_delete"

local error_registry = require "luact.fiber.error_registry"

local function safely_commit(work_in_progress, commit, alternate)
  local status, result = pcall(commit, alternate or work_in_progress)

  if (status) then
    return true
  end
  error_registry.capture(work_in_progress, result)
  return false
end

local function commit_work(work_in_progress)
  if (work_in_progress) then
    local commit_on_child = true
    if (work_in_progress.work == tags.work.PLACEMENT) then
      safely_commit(work_in_progress, commit_placement)
    end
    if (work_in_progress.work == tags.work.UPDATE) then
      safely_commit(work_in_progress, commit_update)
    end
    if (work_in_progress.work == tags.work.DELETE) then
      safely_commit(work_in_progress, commit_delete)
      commit_on_child = false
    end
    if (work_in_progress.work == tags.work.REPLACEMENT) then
      safely_commit(work_in_progress, commit_delete, work_in_progress.alternate)
      safely_commit(work_in_progress, commit_placement)
    end

    if (commit_on_child) then
      commit_work(work_in_progress.child)
    end

    commit_work(work_in_progress.sibling)
  end
end

return commit_work
