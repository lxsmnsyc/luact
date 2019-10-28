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
local directory = "luact.src.extensions.love-2d.components"

local function load(hook)
  return require(directory.."."..hook)
end

return {
  Arc = load("Arc"),
  Circle = load("Circle"),
  Color = load("Color"),
  Draw = load("Draw"),
  Drawable = load("Drawable"),
  Ellipse = load("Ellipse"),
  Line = load("Line"),
  LineJoin = load("LineJoin"),
  LineStyle = load("LineStyle"),
  LineWidth = load("LineWidth"),
  MediaQuery = load("MediaQuery"),
  Rectangle = load("Rectangle"),
  RectangularSensor = load("RectangularSensor"),
  Rotate = load("Rotate"),
  Scale = load("Scale"),
  Scissor = load("Scissor"),
  Shear = load("Shear"),
  Text = load("Text"),
  Translate = load("Translate"),
}