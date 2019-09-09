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
local Event = require "luact.src.event"
return {
  DirectoryDropped = Event.new(),
  Draw = Event.new(),
  -- ErrHand = Event.new(),
  FileDropped = Event.new(),
  Focus = Event.new(),
  GamepadAxis = Event.new(),
  GamepadPressed = Event.new(),
  GamepadReleased = Event.new(),
  JoystickAdded = Event.new(),
  JoystickAxis = Event.new(),
  JoystickHat = Event.new(),
  JoystickPressed = Event.new(),
  JoystickReleased = Event.new(),
  JoystickRemoved = Event.new(),
  KeyPressed = Event.new(),
  KeyReleased = Event.new(),
  Load = Event.new(),
  LowMemory = Event.new(),
  MouseFocus = Event.new(),
  MouseMoved = Event.new(),
  MousePressed = Event.new(),
  MouseReleased = Event.new(),
  Quit = Event.new(),
  Resize = Event.new(),
  TextEdited = Event.new(),
  TextInput = Event.new(),
  ThreadError = Event.new(),
  TouchMoved = Event.new(),
  TouchPressed = Event.new(),
  TouchReleased = Event.new(),
  Update = Event.new(),
  Visible = Event.new(),
  WheelMoved = Event.new(),
}