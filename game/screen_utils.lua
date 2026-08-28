local screen_utils = {}
local Settings = require("settings")
local Text = require("text")
local Colors = require("colors")
local ARROW_HITBOX_PADDING_RATIO = 0.75

local function get_arrow_points(direction, x, y, size)
  if direction == "right" then
    return { x - size / 2, y - size, x + size, y, x - size / 2, y + size }
  elseif direction == "left" then
    return { x + size / 2, y - size, x - size, y, x + size / 2, y + size }
  elseif direction == "up" then
    return { x - size, y + size / 2, x, y - size, x + size, y + size / 2 }
  elseif direction == "down" then
    return { x - size, y - size / 2, x, y + size, x + size, y - size / 2 }
  end
end

local function is_point_in_arrow_hitbox(x, y, points, size, point_x, point_y)
  local min_x = math.min(points[1], points[3], points[5])
  local max_x = math.max(points[1], points[3], points[5])
  local min_y = math.min(points[2], points[4], points[6])
  local max_y = math.max(points[2], points[4], points[6])
  local padding = size * ARROW_HITBOX_PADDING_RATIO
  local side = math.max(max_x - min_x, max_y - min_y) + padding * 2
  local half_side = side / 2

  return point_x >= x - half_side and point_x <= x + half_side and point_y >= y - half_side and point_y <= y + half_side
end

function screen_utils.draw_arrow(direction, x, y, size, color)
  local points = get_arrow_points(direction, x, y, size)
  if not points then
    return
  end

  love.graphics.setColor(color)
  love.graphics.polygon("fill", points)
end

function screen_utils.is_hovering_arrow(direction, x, y, size)
  local mx, my = love.mouse.getPosition()
  return screen_utils.is_point_in_arrow(direction, x, y, size, mx, my)
end

function screen_utils.is_point_in_arrow(direction, x, y, size, point_x, point_y)
  local points = get_arrow_points(direction, x, y, size)
  if not points then
    return false
  end

  return is_point_in_arrow_hitbox(x, y, points, size, point_x, point_y)
end

local function get_return_arrow_layout(text, y, width_percentage, size)
  local scale = Text.calculate_scale_for_width(text, width_percentage)
  local text_width = Text.get_text_width(text, scale)
  local text_height = Text.get_text_height(scale)
  local text_x = (Settings.WINDOW_WIDTH - text_width) / 2

  return text_x - size * 2.5, y + text_height / 2
end

function screen_utils.is_return_control_clicked(text, y, width_percentage, x, point_y)
  local arrow_size = screen_utils.get_arrow_size()
  local arrow_x, arrow_y = get_return_arrow_layout(text, y, width_percentage, arrow_size)
  return screen_utils.is_point_in_arrow("left", arrow_x, arrow_y, arrow_size, x, point_y)
end

function screen_utils.draw_return_control(text, y, width_percentage)
  local arrow_size = screen_utils.get_arrow_size()
  local arrow_x, arrow_y = get_return_arrow_layout(text, y, width_percentage, arrow_size)
  love.graphics.setColor(Colors.white)
  Text.draw_centered_text(text, y, width_percentage)
  local color = screen_utils.is_hovering_arrow("left", arrow_x, arrow_y, arrow_size) and Colors.neon_lime_splash
    or Colors.crimson
  screen_utils.draw_arrow("left", arrow_x, arrow_y, arrow_size, color)
end

function screen_utils.get_return_prompt()
  if Settings.IS_MOBILE then
    return "PRESS BACK OR TAP RED ARROW TO RETURN"
  end
  return "PRESS ESC OR CLICK RED ARROW TO RETURN"
end

function screen_utils.get_arrow_size()
  return 12 * (Settings.WINDOW_HEIGHT / 800)
end

function screen_utils.get_return_width_percentage()
  return Settings.IS_MOBILE and 0.65 or 0.6
end

return screen_utils
