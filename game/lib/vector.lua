-- Define a Vector object with useful methods.
local Vector = {}
Vector.__index = Vector

-- Creates a new Vector instance.
function Vector:new(x, y)
  return setmetatable({ x = x, y = y }, self)
end

-- Returns a copy of the vector.
function Vector:copy()
  return Vector:new(self.x, self.y)
end

-- Adds another vector to the current vector.
function Vector:add(otherVector)
  self.x = self.x + otherVector.x
  self.y = self.y + otherVector.y
  return self
end

-- Adds a vector defined by an angle and length.
function Vector:addWithAngle(angle, length)
  self.x = self.x + math.cos(angle) * length
  self.y = self.y + math.sin(angle) * length
  return self
end

-- Rotates the vector by a given angle.
function Vector:rotate(angle)
  local cosAngle = math.cos(angle)
  local sinAngle = math.sin(angle)
  local newX = self.x * cosAngle - self.y * sinAngle
  local newY = self.x * sinAngle + self.y * cosAngle
  self.x = newX
  self.y = newY
  return self
end

-- Normalizes the vector (makes it a unit vector).
function Vector:normalize()
  local len = math.sqrt(self.x * self.x + self.y * self.y)
  if len > 0 then
    self.x = self.x / len
    self.y = self.y / len
  end
  return self
end

-- Multiplies the vector by a scalar.
function Vector:mul(scalar)
  self.x = self.x * scalar
  self.y = self.y * scalar
  return self
end

-- Subtracts another vector and returns the result as a new vector.
function Vector:sub(otherVector)
  return Vector:new(self.x - otherVector.x, self.y - otherVector.y)
end

-- Divides the vector by a scalar and returns the result as a new vector.
function Vector:div(scalar)
  if scalar ~= 0 then
    return Vector:new(self.x / scalar, self.y / scalar)
  else
    return Vector:new(self.x, self.y) -- Returns a copy to avoid division by zero.
  end
end

-- Returns the length (magnitude) of the vector.
function Vector:length()
  return math.sqrt(self.x * self.x + self.y * self.y)
end

-- Returns the distance to another vector.
function Vector:distance(other)
  local dx = self.x - other.x
  local dy = self.y - other.y
  return math.sqrt(dx * dx + dy * dy)
end

-- Returns the angle of the vector in radians.
function Vector:angle()
  return math.atan2(self.y, self.x)
end

-- Returns the dot product of two vectors.
function Vector:dot(other)
  return self.x * other.x + self.y * other.y
end

return Vector
