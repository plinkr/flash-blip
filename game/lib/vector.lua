-- lib/vector.lua

-- Definir un objeto Vector con métodos útiles.
local Vector = {}
Vector.__index = Vector

-- Crea una nueva instancia de Vector.
function Vector:new(x, y)
  return setmetatable({ x = x, y = y }, self)
end

-- Devuelve una copia del vector.
function Vector:copy()
  return Vector:new(self.x, self.y)
end

-- Suma otro vector al vector actual.
function Vector:add(otherVector)
  self.x = self.x + otherVector.x
  self.y = self.y + otherVector.y
  return self
end

-- Añade un vector definido por un ángulo y una longitud.
function Vector:addWithAngle(angle, length)
  self.x = self.x + math.cos(angle) * length
  self.y = self.y + math.sin(angle) * length
  return self
end

-- Rota el vector por un ángulo dado.
function Vector:rotate(angle)
  local cosAngle = math.cos(angle)
  local sinAngle = math.sin(angle)
  local newX = self.x * cosAngle - self.y * sinAngle
  local newY = self.x * sinAngle + self.y * cosAngle
  self.x = newX
  self.y = newY
  return self
end

-- Normaliza el vector (lo convierte en un vector unitario).
function Vector:normalize()
  local len = math.sqrt(self.x * self.x + self.y * self.y)
  if len > 0 then
    self.x = self.x / len
    self.y = self.y / len
  end
  return self
end

-- Multiplica el vector por un escalar.
function Vector:mul(scalar)
  self.x = self.x * scalar
  self.y = self.y * scalar
  return self
end

-- Resta otro vector y devuelve el resultado como un nuevo vector.
function Vector:sub(otherVector)
  return Vector:new(self.x - otherVector.x, self.y - otherVector.y)
end

-- Divide el vector por un escalar y devuelve el resultado como un nuevo vector.
function Vector:div(scalar)
  if scalar ~= 0 then
    return Vector:new(self.x / scalar, self.y / scalar)
  else
    return Vector:new(self.x, self.y) -- Devuelve una copia para evitar la división por cero.
  end
end

-- Devuelve la longitud (magnitud) del vector.
function Vector:length()
  return math.sqrt(self.x * self.x + self.y * self.y)
end

-- Devuelve la distancia a otro vector.
function Vector:distance(other)
  local dx = self.x - other.x
  local dy = self.y - other.y
  return math.sqrt(dx * dx + dy * dy)
end

-- Devuelve el ángulo del vector en radianes.
function Vector:angle()
  return math.atan2(self.y, self.x)
end

-- Devuelve el producto punto de dos vectores.
function Vector:dot(other)
  return self.x * other.x + self.y * other.y
end

return Vector
