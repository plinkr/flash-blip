-- game.lua

local Game = {}

local Vector = require("lib.vector")
local settings = require("settings")
local Powerups = require("powerups")
local Sound = require("sound")
local colors = require("colors")

local MathUtils = require("math_utils")
local circles
local particles
local circleAddDist
local lastCircle
local playerCircle
local ticks
local difficulty
local baseDifficulty
local baseScrollSpeed = 0.08
local attractMode = false
local minCircleDist = settings.INTERNAL_HEIGHT / 4

local function vec(x, y)
  return Vector:new(x, y)
end

local function remove(tbl, predicate)
  local i = #tbl
  while i >= 1 do
    if predicate(tbl[i]) then
      table.remove(tbl, i)
    end
    i = i - 1
  end
end

function Game.init(is_attract_mode, initial_difficulty)
  circles = {}
  particles = {}
  circleAddDist = 0
  lastCircle = nil
  playerCircle = nil
  ticks = 0
  difficulty = initial_difficulty or 1
  baseDifficulty = initial_difficulty or 1
  attractMode = is_attract_mode
end

function Game.get_circles()
  return circles
end

function Game.get_particles()
  return particles
end

function Game.get_player_circle()
  return playerCircle
end

function Game.set_player_circle(circle)
  playerCircle = circle
end

local function addCircle(isSlowed)
  local radius = MathUtils.rnd(20, 30)

  -- Asegura una distancia mínima con el círculo del jugador.
  local yPos = -radius
  if playerCircle then
    yPos = math.min(yPos, playerCircle.position.y - minCircleDist)
  end

  local newCircle = {
    position = vec(MathUtils.rnd(20, settings.INTERNAL_WIDTH - 20), yPos),
    radius = radius,
    obstacleCount = MathUtils.rndi(1, 3), -- 1, 2, o 3 obstáculos girando alrededor de los puntos.
    angle = MathUtils.rnd(math.pi * 2),
    angularVelocity = MathUtils.rnds(0.005, 0.015) * difficulty, -- Velocidad de rotación.
    obstacleLength = MathUtils.rnd(15, 25),
    next = nil,
    isPassed = false, -- Estado para saber si el jugador ha pasado por este círculo
  }

  if isSlowed then
    newCircle.angularVelocity = MathUtils.rnds(0.005, 0.015) -- Velocidad angular base fija.
    newCircle.obstacleLength = newCircle.obstacleLength * 0.5 -- Tamaño reducido.
  end

  if lastCircle ~= nil then
    lastCircle.next = newCircle
  end
  if playerCircle == nil then
    playerCircle = newCircle
  end
  lastCircle = newCircle
  table.insert(circles, newCircle)
end

local function updateDifficulty()
  local ticksPerUnit = 3600 -- 3600 ticks = 1 minuto a 60 FPS
  local exponent = 1.25 -- Si es 1, la curva es lineal. Si es > 1, la curva se empina
  local scaleFactor = 1.5 -- Multiplicador general para controlar la intensidad.

  -- Calculamos cuántas "unidades de tiempo" han pasado.
  local timeUnits = ticks / ticksPerUnit

  -- La fórmula aplica el exponente a las unidades de tiempo.
  difficulty = baseDifficulty + (timeUnits ^ exponent) * scaleFactor
end

function Game.update(dt, PowerupsManager, endGame, addScore)
  ticks = ticks + 1
  updateDifficulty()

  if ticks == 1 then
    addCircle(PowerupsManager.isSlowed)
  end

  if circleAddDist <= 0 then
    addCircle(PowerupsManager.isSlowed)
    circleAddDist = circleAddDist + MathUtils.rnd(settings.INTERNAL_HEIGHT * 0.25, settings.INTERNAL_HEIGHT * 0.45)
  end

  -- La velocidad de desplazamiento aumenta con la dificultad.
  local baseSpeedForScore = difficulty * baseScrollSpeed
  if playerCircle then
    local playerY = playerCircle.position.y
    if playerY < (settings.INTERNAL_HEIGHT / 2) then
      -- El desplazamiento es más rápido cuando el jugador está cerca de la parte superior.
      baseSpeedForScore = baseSpeedForScore + ((settings.INTERNAL_HEIGHT / 2) - playerY) * 0.02
    end
  end

  -- Esta es la velocidad real (teniendo en cuenta el powerup de slowDown)
  local scrollSpeed = baseSpeedForScore

  -- Aplica el efecto de ralentización del power-up del reloj
  if PowerupsManager.isSlowed then
    local playerY = playerCircle and playerCircle.position.y or 0
    -- Parte superior (0% - 20%): aceleración del juego normal
    if playerY < (settings.INTERNAL_HEIGHT * 0.2) then
      -- El desplazamiento es más rápido cuando el jugador está cerca de la parte superior
      scrollSpeed = baseScrollSpeed + ((settings.INTERNAL_HEIGHT / 2) - playerY) * 0.02

    -- Parte media (20% - 50%): mantener velocidad base (nivel 1)
    elseif playerY > (settings.INTERNAL_HEIGHT * 0.5) and playerY < (settings.INTERNAL_HEIGHT * 0.8) then
      scrollSpeed = baseScrollSpeed

    -- Parte inferior (80% - 100%) scroll lento, 10% de la velocidad normal
    elseif playerY >= (settings.INTERNAL_HEIGHT * 0.8) then
      scrollSpeed = baseScrollSpeed * 0.10
    end
  end

  circleAddDist = circleAddDist - scrollSpeed
  addScore(baseSpeedForScore)

  -- Si el player se va del límite inferior de la pantalla, es game over
  if playerCircle and playerCircle.position.y > settings.INTERNAL_HEIGHT - 1 then
    if not attractMode then
      if PowerupsManager.isBoltActive and playerCircle.next then
        if Powerups.checkLightningCollision(playerCircle) then
          Sound.play("teleport")
          particle(playerCircle.position, 20, 3, 0, math.pi * 2, colors.yellow) -- Origen
          particle(playerCircle.next.position, 20, 3, 0, math.pi * 2, colors.yellow) -- Destino
          playerCircle.isPassed = true
          playerCircle = playerCircle.next
          return -- Evita el game over
        end
      end
      Sound.play("explosion")
    end
    endGame()
    return
  end

  if PowerupsManager.isBoltActive and playerCircle and playerCircle.next then
    if Powerups.checkLightningCollision(playerCircle) then
      if not attractMode then
        Sound.play("teleport")
      end
      particle(playerCircle.position, 20, 3, 0, math.pi * 2, colors.yellow)
      particle(playerCircle.next.position, 20, 3, 0, math.pi * 2, colors.yellow)
      playerCircle.isPassed = true
      playerCircle = playerCircle.next
    end
  end

  local obstacles = {}
  remove(circles, function(circle)
    circle.position.y = circle.position.y + scrollSpeed
    if circle.position.y > settings.INTERNAL_HEIGHT + circle.radius then
      return true
    end
    circle.angle = circle.angle + circle.angularVelocity

    for i = 1, circle.obstacleCount do
      local obstacleAngle = circle.angle + (i * math.pi * 2) / circle.obstacleCount
      local rectCenter = vec(circle.position.x, circle.position.y):addWithAngle(obstacleAngle, circle.radius)
      table.insert(obstacles, {
        center = rectCenter,
        width = circle.obstacleLength,
        height = 3,
        angle = obstacleAngle + math.pi / 2,
      })
    end
    return false
  end)

  remove(particles, function(p)
    p.pos:add(p.vel)
    p.life = p.life - 0.4
    return p.life <= 0
  end)

  return obstacles
end
function Game.lineAABBIntersect(x1, y1, x2, y2, minX, minY, maxX, maxY)
  local dx = x2 - x1
  local dy = y2 - y1

  if math.abs(dx) < 1e-8 and math.abs(dy) < 1e-8 then
    return x1 >= minX and x1 <= maxX and y1 >= minY and y1 <= maxY
  end

  local t1, t2 = 0, 1

  if math.abs(dx) > 1e-8 then
    local invDx = 1 / dx
    local tx1 = (minX - x1) * invDx
    local tx2 = (maxX - x1) * invDx
    t1 = math.max(t1, math.min(tx1, tx2))
    t2 = math.min(t2, math.max(tx1, tx2))
  else
    if x1 < minX or x1 > maxX then
      return false
    end
  end

  if math.abs(dy) > 1e-8 then
    local invDy = 1 / dy
    local ty1 = (minY - y1) * invDy
    local ty2 = (maxY - y1) * invDy
    t1 = math.max(t1, math.min(ty1, ty2))
    t2 = math.min(t2, math.max(ty1, ty2))
  else
    if y1 < minY or y1 > maxY then
      return false
    end
  end

  return t1 <= t2
end

function Game.checkLineRotatedRectCollision(lineP1, lineP2, rectCenter, rectWidth, rectHeight, rectAngle)
  -- Transforma la línea al sistema de coordenadas local del rectángulo.
  local cosAngle = math.cos(-rectAngle)
  local sinAngle = math.sin(-rectAngle)

  local localP1x = (lineP1.x - rectCenter.x) * cosAngle - (lineP1.y - rectCenter.y) * sinAngle
  local localP1y = (lineP1.x - rectCenter.x) * sinAngle + (lineP1.y - rectCenter.y) * cosAngle
  local localP2x = (lineP2.x - rectCenter.x) * cosAngle - (lineP2.y - rectCenter.y) * sinAngle
  local localP2y = (lineP2.x - rectCenter.x) * sinAngle + (lineP2.y - rectCenter.y) * cosAngle

  -- Comprueba la colisión con un rectángulo alineado con los ejes (AABB).
  local halfW = rectWidth / 2
  local halfH = rectHeight / 2

  return Game.lineAABBIntersect(localP1x, localP1y, localP2x, localP2y, -halfW, -halfH, halfW, halfH)
end

return Game
