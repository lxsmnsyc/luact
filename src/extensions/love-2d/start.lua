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

local Future = require "luact.src.future"
local LoveEvent = require "luact.src.extensions.love-2d.event"
local nodeToString = require "luact.src.utils.nodeToString"
local evaluate = require "luact.src.utils.evaluate"
local typeTable = require "luact.src.types.table"
local typeFunction = require "luact.src.types.func"

local started = false
return function (container)
  if (started) then
    return
  end
  started = true
  Future.drain()
  
  --[[
    Callback function triggered when a directory is dragged
    and dropped onto the window.
  --]]
  local DirectoryDropped = LoveEvent.DirectoryDropped
  function love.directorydropped(path)
    DirectoryDropped:dispatch(path)
    Future.drain()
  end

  --[[
    Callback function used to draw on the screen every frame.
  --]]
  local Draw = LoveEvent.Draw
  function love.draw()
    Draw:dispatch()
    evaluate(
      container,
      function (node)
        if (typeTable(node.nodes)) then
          node = node.nodes
          if (typeFunction(node.beforeDraw)) then
            node.beforeDraw()
          end
          if (typeFunction(node.draw)) then
            node.draw()
          end
        end
      end,
      function (node)
        if (typeTable(node.nodes)) then
          node = node.nodes
          if (typeFunction(node.afterDraw)) then
            node.afterDraw()
          end
        end
      end
    )
    Future.drain()
  end
  
  --[[
  function love.draw()
    love.graphics.print(nodeToString(container))
  end
  --]]
  
  --[[
    The error handler, used to display error messages.
  local ErrHand = LoveEvent.ErrHand
  function love.errhand(msg)
    ErrHand:dispatch(msg)
    Future.drain()
  end
  
  --]]
  --[[
    Callback function triggered when a file is dragged and
    dropped onto the window.
  --]]
  local FileDropped = LoveEvent.FileDropped
  function love.filedropped(file)
    FileDropped:dispatch(file)
    Future.drain()
  end

  --[[
    Callback function triggered when window receives or
    loses focus.
  --]]
  local Focus = LoveEvent.Focus
  function love.focus(focus)
    Focus:dispatch(focus)
    Future.drain()
  end

  --[[
    Called when a Joystick's virtual gamepad axis is moved.
  --]]
  local GamepadAxis = LoveEvent.GamepadAxis
  function love.gamepadaxis(joystick, axis, value)
    GamepadAxis:dispatch(joystick, axis, value)
    Future.drain()
  end

  --[[
    Called when a Joystick's virtual gamepad button is pressed.
  --]]
  local GamepadPressed = LoveEvent.GamepadPressed
  function love.gamepadpressed(joystick, button)
    GamePressed:dispatch(joystick, button)
    Future.drain()
  end

  --[[
    Called when a Joystick's virtual gamepad button is released.
  --]]
  local GamepadReleased = LoveEvent.GamepadReleased
  function love.gamepadreleased(joystick, button)
    GamepadReleased:dispatch(joystick, button)
    Future.drain()
  end

  --[[
    Called when a Joystick is connected.
  --]]
  local JoystickAdded = LoveEvent.JoystickAdded
  function love.joystickadded(joystick)
    JoystickAdded:dispatch(joystick)
    Future.drain()
  end

  --[[
    Called when a joystick axis moves.
  --]]
  local JoystickAxis = LoveEvent.JoystickAxis
  function love.joystickaxis(joystick, axis, value)
    JoystickAxis:dispatch(joystick, axis, value)
    Future.drain()
  end

  --[[
    Called when a joystick hat direction changes.
  --]]
  local JoystickHat = LoveEvent.JoystickHat
  function love.joystickhat(joystick, hat, direction)
    JoystickHat:dispatch(joystick, hat, direction)
    Future.drain()
  end

  --[[
    Called when a joystick button is pressed.
  --]]
  local JoystickPressed = LoveEvent.JoystickPressed
  function love.joystickpressed(joystick, button)
    JoystickPressed:dispatch(joystick, button)
    Future.drain()
  end

  --[[
    Called when a joystick button is released.
  --]]
  local JoystickReleased = LoveEvent.JoystickReleased
  function love.joystickreleased(joystick, button)
    JoystickReleased:dispatch(joystick, button)
    Future.drain()
  end

  --[[
    Called when a Joystick is disconnected.
  --]]
  local JoystickRemoved = LoveEvent.JoystickRemoved
  function love.joystickremoved(joystick)
    JoystickRemoved:dispatch(joystick)
    Future.drain()
  end

  --[[
    Callback function triggered when a key is pressed.
  --]]
  local KeyPressed = LoveEvent.KeyPressed
  function love.keypressed(key, scancode, isrepeat)
    KeyPressed:dispatch(key, scancode, isrepeat)
    Future.drain()
  end

  --[[
    Callback function triggered when a keyboard key is released.
  --]]
  local KeyReleased = LoveEvent.KeyReleased
  function love.keyreleased(key)
    KeyReleased:dispatch(key)
    Future.drain()
  end

  --[[
    This function is called exactly once at the beginning of the game.
  --]]
  local Load = LoveEvent.Load
  function love.load(arg)
    Load:dispatch(arg)
    Future.drain()
  end

  --[[
    Callback function triggered when the system is running out of
    memory on mobile devices.

    Mobile operating systems may forcefully kill the game if it uses
    too much memory, so any non-critical resource should be removed
    if possible (by setting all variables referencing the resources
    to nil, and calling collectgarbage()), when this event is triggered.
    Sounds and images in particular tend to use the most memory.
  --]]
  local LowMemory = LoveEvent.LowMemory
  function love.lowmemory()
    LowMemory:dispatch()
    Future.drain()
  end

  --[[
    Callback function triggered when window receives or loses mouse focus.
  --]]
  local MouseFocus = LoveEvent.MouseFocus
  function love.mousefocus(focus)
    MouseFocus:dispatch(focus)
    Future.drain()
  end

  --[[
    Callback function triggered when the mouse is moved.
  --]]
  local MouseMoved = LoveEvent.MouseMoved
  function love.mousemoved(x, y, dx, dy, istouch)
    MouseMoved:dispatch(x, y, dx, dy, istouch)
    Future.drain()
  end

  --[[
    Callback function triggered when a mouse button is pressed.
  --]]
  local MousePressed = LoveEvent.MousePressed
  function love.mousepressed(x, y, button, istouch)
    MousePressed:dispatch(x, y, button, istouch)
    Future.drain()
  end

  --[[
    Callback function triggered when a mouse button is released.
  --]]
  local MouseReleased = LoveEvent.MouseReleased
  function love.mousereleased(x, y, button, istouch)
    MouseReleased:dispatch(x, y, button, istouch)
    Future.drain()
  end

  --[[
    Callback function triggered when the game is closed.
  --]]
  local Quit = LoveEvent.Quit
  function love.quit()
    local aborted = false
    Quit:dispatch(function ()
      aborted = true
    end)
    Future.drain()
    return aborted
  end

  --[[
    Called when the window is resized, for example if the
    user resizes the window, or if love.window.setMode is
    called with an unsupported width or height in fullscreen
    and the window chooses the closest appropriate size.
  --]]
  local Resize = LoveEvent.Resize
  function love.resize(w, h)
    Resize:dispatch(w, h)
    Future.drain()
  end

  --[[
    Called when the candidate text for an IME (Input Method Editor)
    has changed.

    The candidate text is not the final text that the user will
    eventually choose. Use love.textinput for that.
  --]]
  local TextEdited = LoveEvent.TextEdited
  function love.textedited(text, start, length)
    TextEdited:dispatch(text, start, length)
    Future.drain()
  end

  --[[
    Called when text has been entered by the user. For example if
    shift-2 is pressed on an American keyboard layout, the text "@"
    will be generated.
  --]]
  local TextInput = LoveEvent.TextInput
  function love.textinput(text)
    TextInput:dispatch(text)
    Future.drain()
  end

  --[[
    Callback function triggered when a Thread encounters an error.
  --]]
  local ThreadError = LoveEvent.ThreadError
  function love.threaderror(thread, errorstr)
    ThreadError:dispatch(thread, errorstr)
    Future.drain()
  end

  --[[
    Callback function triggered when a touch press moves inside
    the touch screen.
  --]]
  local TouchMoved = LoveEvent.TouchMoved
  function love.touchmoved(id, x, y, dx, dy, pressure)
    TouchMoved:dispatch(id, x, y, dx, dy, pressure)
    Future.drain()
  end

  --[[
    Callback function triggered when the touch screen is touched.
  --]]
  local TouchPressed = LoveEvent.TouchPressed
  function love.touchpressed(id, x, y, dx, dy, pressure)
    TouchPressed:dispatch(id, x, y, dx, dy, pressure)
    Future.drain()
  end

  --[[
    Callback function triggered when the touch screen stops being touched.
  --]]
  local TouchReleased = LoveEvent.TouchReleased
  function love.touchreleased(id, x, y, dx, dy, pressure)
    TouchReleased:dispatch(id, x, y, dx, dy, pressure)
    Future.drain()
  end

  --[[
    Callback function used to update the state of the game every frame.
  --]]
  local Update = LoveEvent.Update
  function love.update(dt)
    Update:dispatch(dt)
    Future.drain()
  end

  --[[
    Callback function triggered when window is minimized/hidden or unminimized by the user.
  --]]
  local Visible = LoveEvent.Visible
  function love.visible(visible)
    Visible:dispatch(visible)
    Future.drain()
  end

  --[[
    Callback function triggered when the mouse wheel is moved.
  --]]
  local WheelMoved = LoveEvent.WheelMoved
  function love.wheelmoved(x, y)
    WheelMoved:dispatch(x, y)
    Future.drain()
  end
end