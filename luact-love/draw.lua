-- Draws a tree of LÖVE host nodes.
--
-- Each host type has a painter: `painter(node, draw_children)`. Painters for
-- the built-in types are in `painters`. Add an entry to support a new type.

local M = {}

local painters = {}
M.painters = painters

local function draw_children(node)
  local children = node.children
  for i = 1, #children do
    local child = children[i]
    if child.type ~= nil then
      M.draw_node(child)
    end
  end
end

-- Runs `fn` with `color` set, then restores the previous color.
local function with_color(color, fn, ...)
  if color == nil then
    fn(...)
    return
  end
  local graphics = love.graphics
  local r, g, b, a = graphics.getColor()
  graphics.setColor(color[1] or color.r or 1, color[2] or color.g or 1,
    color[3] or color.b or 1, color[4] or color.a or 1)
  fn(...)
  graphics.setColor(r, g, b, a)
end

local function text_content(node)
  local parts = {}
  local children = node.children
  for i = 1, #children do
    if children[i].text ~= nil then
      parts[#parts + 1] = children[i].text
    end
  end
  return table.concat(parts)
end

-- Moves, rotates and scales its children. Props: x, y, rotation, sx, sy,
-- color.
function painters.group(node, draw_node_children)
  local props = node.props
  local graphics = love.graphics
  graphics.push()
  graphics.translate(props.x or 0, props.y or 0)
  if props.rotation ~= nil then
    graphics.rotate(props.rotation)
  end
  if props.sx ~= nil or props.sy ~= nil then
    graphics.scale(props.sx or 1, props.sy or props.sx or 1)
  end
  with_color(props.color, draw_node_children, node)
  graphics.pop()
end

-- Props: mode ("fill" or "line"), x, y, width, height, rx, ry, color.
function painters.rectangle(node, draw_node_children)
  local props = node.props
  with_color(props.color, love.graphics.rectangle, props.mode or "fill",
    props.x or 0, props.y or 0, props.width or 0, props.height or 0, props.rx, props.ry)
  draw_node_children(node)
end

-- Props: mode, x, y, radius, segments, color.
function painters.circle(node, draw_node_children)
  local props = node.props
  with_color(props.color, love.graphics.circle, props.mode or "fill",
    props.x or 0, props.y or 0, props.radius or 0, props.segments)
  draw_node_children(node)
end

-- Draws its text children. Props: x, y, font, limit, align, color.
function painters.text(node)
  local props = node.props
  local graphics = love.graphics
  local content = text_content(node)
  local previous_font = nil
  if props.font ~= nil then
    previous_font = graphics.getFont()
    graphics.setFont(props.font)
  end
  if props.limit ~= nil then
    with_color(props.color, graphics.printf, content, props.x or 0, props.y or 0,
      props.limit, props.align or "left")
  else
    with_color(props.color, graphics.print, content, props.x or 0, props.y or 0)
  end
  if previous_font ~= nil then
    graphics.setFont(previous_font)
  end
end

-- Draws a Drawable. Props: image, x, y, rotation, sx, sy, ox, oy, color.
function painters.image(node, draw_node_children)
  local props = node.props
  if props.image ~= nil then
    with_color(props.color, love.graphics.draw, props.image, props.x or 0, props.y or 0,
      props.rotation or 0, props.sx or 1, props.sy or props.sx or 1, props.ox or 0, props.oy or 0)
  end
  draw_node_children(node)
end

-- Calls `props.draw(node)`, then draws the children. An escape hatch for
-- anything the built-in types do not cover.
function painters.draw(node, draw_node_children)
  local draw = node.props.draw
  if draw ~= nil then
    draw(node)
  end
  draw_node_children(node)
end

function M.draw_node(node)
  local painter = painters[node.type]
  if painter == nil then
    error("luact-love: no painter for host type \"" .. tostring(node.type) .. "\"", 0)
  end
  painter(node, draw_children)
end

-- Draws every node in `container`.
function M.draw_container(container)
  draw_children(container)
end

return M
