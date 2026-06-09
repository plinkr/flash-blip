local Vector = require("lib.vector")

local MathUtils = {}

-- Generates a decimal random number in the range [a, b).
function MathUtils.rnd(a, b)
  if b == nil then
    b = a
    a = 0
  end
  return love.math.random() * (b - a) + a
end

-- Generates an integer random number in the range [a, b].
function MathUtils.rndi(a, b)
  return love.math.random(a, b)
end

-- Generates a random number in a symmetric range [-a, a] or [a, b).
function MathUtils.rnds(a, b)
  if b == nil then
    return love.math.random() * (2 * a) - a
  else
    return love.math.random() * (b - a) + a
  end
end

-- Checks collision between two circles.
function MathUtils.circle_collision(x1, y1, r1, x2, y2, r2)
  local dx = x1 - x2
  local dy = y1 - y2
  local distance = math.sqrt(dx * dx + dy * dy)
  return distance < (r1 + r2)
end

-- Checks collision between a line segment and a circle.
function MathUtils.line_circle_collision(p1, p2, circle_center, circle_radius)
  local d = Vector:new(p2.x, p2.y):sub(p1)
  local f = Vector:new(p1.x, p1.y):sub(circle_center)

  local a = d:dot(d)
  local b = 2 * f:dot(d)
  local c = f:dot(f) - circle_radius * circle_radius

  local discriminant = b * b - 4 * a * c
  if discriminant < 0 then
    return false
  else
    discriminant = math.sqrt(discriminant)
    local t1 = (-b - discriminant) / (2 * a)
    local t2 = (-b + discriminant) / (2 * a)

    if (t1 >= 0 and t1 <= 1) or (t2 >= 0 and t2 <= 1) then
      return true
    end

    if f:dot(f) < circle_radius * circle_radius then
      return true
    end

    return false
  end
end

local trig_cache = {}
local TRIG_CACHE_SIZE = 3600

local function get_cached_trig(angle)
  local normalized_angle = angle % (math.pi * 2)
  if normalized_angle < 0 then
    normalized_angle = normalized_angle + (math.pi * 2)
  end

  local key = math.floor(normalized_angle * TRIG_CACHE_SIZE / (math.pi * 2))

  if not trig_cache[key] then
    trig_cache[key] = {
      cos = math.cos(angle),
      sin = math.sin(angle),
    }
  end

  return trig_cache[key]
end

-- Checks intersection between a line segment and an Axis-Aligned Bounding Box (AABB).
function MathUtils.line_aabb_intersect(x1, y1, x2, y2, min_x, min_y, max_x, max_y)
  local dx = x2 - x1
  local dy = y2 - y1

  if math.abs(dx) < 1e-8 and math.abs(dy) < 1e-8 then
    return x1 >= min_x and x1 <= max_x and y1 >= min_y and y1 <= max_y
  end

  local t1, t2 = 0, 1

  if math.abs(dx) > 1e-8 then
    local inv_dx = 1 / dx
    local tx1 = (min_x - x1) * inv_dx
    local tx2 = (max_x - x1) * inv_dx
    t1 = math.max(t1, math.min(tx1, tx2))
    t2 = math.min(t2, math.max(tx1, tx2))
  else
    if x1 < min_x or x1 > max_x then
      return false
    end
  end

  if math.abs(dy) > 1e-8 then
    local inv_dy = 1 / dy
    local ty1 = (min_y - y1) * inv_dy
    local ty2 = (max_y - y1) * inv_dy
    t1 = math.max(t1, math.min(ty1, ty2))
    t2 = math.min(t2, math.max(ty1, ty2))
  else
    if y1 < min_y or y1 > max_y then
      return false
    end
  end

  return t1 <= t2
end

-- Checks collision between a line segment and a rotated rectangle.
function MathUtils.check_line_rotated_rect_collision(line_p1, line_p2, rect_center, rect_width, rect_height, rect_angle)
  local trig = get_cached_trig(-rect_angle)
  local cos_angle = trig.cos
  local sin_angle = trig.sin

  local dx1 = line_p1.x - rect_center.x
  local dy1 = line_p1.y - rect_center.y
  local dx2 = line_p2.x - rect_center.x
  local dy2 = line_p2.y - rect_center.y

  local local_p1_x = dx1 * cos_angle - dy1 * sin_angle
  local local_p1_y = dx1 * sin_angle + dy1 * cos_angle
  local local_p2_x = dx2 * cos_angle - dy2 * sin_angle
  local local_p2_y = dx2 * sin_angle + dy2 * cos_angle

  local half_w = rect_width * 0.5
  local half_h = rect_height * 0.5

  return MathUtils.line_aabb_intersect(local_p1_x, local_p1_y, local_p2_x, local_p2_y, -half_w, -half_h, half_w, half_h)
end

return MathUtils
