-- math_utils.lua

local MathUtils = {}

-- Genera un número aleatorio decimal en el rango [a, b).
function MathUtils.rnd(a, b)
  if b == nil then
    b = a
    a = 0
  end
  return love.math.random() * (b - a) + a
end

-- Genera un número aleatorio entero en el rango [a, b].
function MathUtils.rndi(a, b)
  return love.math.random(a, b)
end

-- Genera un número aleatorio en un rango simétrico [-a, a] o [a, b).
function MathUtils.rnds(a, b)
  if b == nil then
    return love.math.random() * (2 * a) - a
  else
    return love.math.random() * (b - a) + a
  end
end

return MathUtils
