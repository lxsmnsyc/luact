--[[
    Luact
	
    MIT License
    Copyright (c) 2019 Alexis Munsayac
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
--]]
local Equatable = require "luact.src.utils.equatable"

local useState = require "luact.src.hooks.useState"
local useFrameUpdate = require "luact.src.extensions.love-2d.hooks.useFrameUpdate"

local typeOptional = require "luact.src.types.optional"
local typeNumber = require "luact.src.types.number"
local typeEitherValues = require "luact.src.types.eitherValues"

local optionalNumber = typeOptional(typeNumber)

return function (easing, duration, delay)
  assert(optionalNumber(duration), "love.useTween: duration must be a number.")
  assert(optionalNumber(delay), "love.useTween: delay must be a number.")
  
  duration = duration or 0
  delay = delay or 0

  local state, setState = useState(Equatable {
    phase = 0,
    finished = false,
    progress = 0,
  })

  local phase = state.phase
  local finished = state.finished
  local progress = state.progress

  useFrameUpdate(function (dt)
    if (phase == 0) then
      if (progress >= delay) then
        setState(Equatable {
          phase = 1,
          progress = 0,
        })
      else
        setState(Equatable {
          phase = 0,
          progress = progress + dt,
        })
      end
      return
    end

    if (phase == 1) then
      if (progress >= duration) then
        setState(Equatable {
          finished = true,
        })
      else
        setState(Equatable {
          phase = 1,
          progress = progress + dt,
        })
      end
    end
  end, { state }, not finished)
  
  if (phase == 0) then
    return 0
  end
  if (finished) then
    return 1
  end
  return progress / duration 
end