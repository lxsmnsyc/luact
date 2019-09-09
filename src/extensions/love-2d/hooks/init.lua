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
local directory = "luact.src.extensions.love-2d.hooks"

local function load(hook)
  return require(directory.."."..hook)
end

return {
  useDirectoryDropped = load("useDirectoryDropped"),
  useDraw = load("useDraw"),
  useErrorHandler = load("useErrorHandler"),
  useFileDropped = load("useFileDropped"),
  useFocus = load("useFocus"),
  useFrameUpdate = load("useFrameUpdate"),
  useGamepadAxis = load("useGamepadAxis"),
  useGamepadPressed = load("useGamepadPressed"),
  useGamepadReleased = load("useGamepadReleased"),
  useJoystickAdded = load("useJoystickAdded"),
  useJoystickAxis = load("useJoystickAxis"),
  useJoystickHat = load("useJoystickHat"),
  useJoystickPressed = load("useJoystickPressed"),
  useJoystickReleased = load("useJoystickReleased"),
  useJoystickRemoved = load("useJoystickRemoved"),
  useKeyPressed = load("useKeyPressed"),
  useKeyReleased = load("useKeyReleased"),
  useLoad = load("useLoad"),
  useLowMemory = load("useLowMemory"),
  useMouseFocus = load("useMouseFocus"),
  useMouseMoved = load("useMouseMoved"),
  useMousePressed = load("useMousePressed"),
  useMouseReleased = load("useMouseReleased"),
  useQuit = load("useQuit"),
  useResize = load("useResize"),
  useTextEdited = load("useTextEdited"),
  useTextInput = load("useTextInput"),
  useThreadError = load("useThreadError"),
  useTouchMoved = load("useTouchMoved"),
  useTouchPressed = load("useTouchPressed"),
  useVisible = load("useVisible"),
  useWheelMoved = load("useWheelMoved"),
  useWindowSize = load("useWindowSize"),
}