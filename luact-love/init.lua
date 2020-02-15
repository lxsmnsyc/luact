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
local luact = require "luact"
local Love = require "luact-love.reconciler"
local draw_all = require "luact-love.draw_all"
local layers = require "luact-love.layers"
local events = require "luact-love.events"
local logs = require "luact.utils.logs"

function love.run()
  if love.load then
    love.load(love.arg.parseGameArguments(arg), arg)
  end

	-- We don't want the first frame's dt to include time taken by love.load.
  if love.timer then
    love.timer.step()
  end

	local dt = 0

	-- Main loop time.
	return function()
		-- Process events.
		if love.event then
			love.event.pump()
      for name, a,b,c,d,e,f in love.event.poll() do
        events[name]:emit(a,b,c,d,e,f)
				if name == "quit" then
					return 0
        end
			end
		end

		-- Update dt, as we'll be passing it to update
    if love.timer then
      dt = love.timer.step()
    end

    -- Call update and draw
    local start = love.timer.getTime()
    luact.update_frame(dt)
    events.update:emit(dt)

		if love.graphics and love.graphics.isActive() then
			love.graphics.origin()
			love.graphics.clear(love.graphics.getBackgroundColor())

      draw_all()

			love.graphics.present()
    end

    Love.work_loop(function ()
      return (love.timer.getTime() - start) * 1000
    end)

    if love.timer then
      love.timer.sleep(0.001)
    end
  end
end

return {
  init = function (element)
    Love.render(element, layers)
  end,
}