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

return MathUtils
