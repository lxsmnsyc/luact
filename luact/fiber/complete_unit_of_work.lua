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
return function (work_in_progress)
  -- check for the availability of the fiber
  while (work_in_progress) do
    -- check if there are any sibling fibers
    if (work_in_progress.sibling) then
      -- set the sibling as the next unit of work
      return work_in_progress.sibling
    end
    -- no siblings, try the parent
    work_in_progress = work_in_progress.parent
  end
  return nil
end
