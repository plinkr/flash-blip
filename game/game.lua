local Game = {}

local Vector = require("lib.vector")
local Settings = require("settings")
local Powerups = require("powerups")
local Sound = require("sound")
local Colors = require("colors")
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
local minCircleDist = Settings.INTERNAL_HEIGHT / 4

local trigCache = {}
local TRIG_CACHE_SIZE = 3600

local function getCachedTrig(angle)
  local normalizedAngle = angle % (math.pi * 2)
  if normalizedAngle < 0 then
    normalizedAngle = normalizedAngle + (math.pi * 2)
  end

  local key = math.floor(normalizedAngle * TRIG_CACHE_SIZE / (math.pi * 2))

  if not trigCache[key] then
    trigCache[key] = {
      cos = math.cos(angle),
      sin = math.sin(angle),
    }
  end

  return trigCache[key]
end

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

  local yPos = -radius
  if playerCircle then
    yPos = math.min(yPos, playerCircle.position.y - minCircleDist)
  end

  local newCircle = {
    position = vec(MathUtils.rnd(20, Settings.INTERNAL_WIDTH - 20), yPos),
    radius = radius,
    obstacleCount = MathUtils.rndi(1, 3),
    angle = MathUtils.rnd(math.pi * 2),
    angularVelocity = MathUtils.rnds(0.005, 0.015) * difficulty,
    obstacleLength = MathUtils.rnd(15, 25),
    next = nil,
    isPassed = false,
  }

  if isSlowed then
    newCircle.angularVelocity = MathUtils.rnds(0.005, 0.015)
    newCircle.obstacleLength = newCircle.obstacleLength * 0.5
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
  local ticksPerUnit = 3600
  local exponent = 1.25
  local scaleFactor = 1.5

  local timeUnits = ticks / ticksPerUnit

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
    circleAddDist = circleAddDist + MathUtils.rnd(Settings.INTERNAL_HEIGHT * 0.25, Settings.INTERNAL_HEIGHT * 0.45)
  end

  local baseSpeedForScore = difficulty * baseScrollSpeed
  if playerCircle then
    local playerY = playerCircle.position.y
    if playerY < (Settings.INTERNAL_HEIGHT / 2) then
      baseSpeedForScore = baseSpeedForScore + ((Settings.INTERNAL_HEIGHT / 2) - playerY) * 0.02
    end
  end

  local scrollSpeed = baseSpeedForScore

  if PowerupsManager.isSlowed then
    local playerY = playerCircle and playerCircle.position.y or 0
    if playerY < (Settings.INTERNAL_HEIGHT * 0.2) then
      scrollSpeed = baseScrollSpeed + ((Settings.INTERNAL_HEIGHT / 2) - playerY) * 0.02
    elseif playerY > (Settings.INTERNAL_HEIGHT * 0.5) and playerY < (Settings.INTERNAL_HEIGHT * 0.8) then
      scrollSpeed = baseScrollSpeed
    elseif playerY >= (Settings.INTERNAL_HEIGHT * 0.8) then
      scrollSpeed = baseScrollSpeed * 0.10
    end
  end

  circleAddDist = circleAddDist - scrollSpeed
  addScore(baseSpeedForScore)

  if playerCircle and playerCircle.position.y > Settings.INTERNAL_HEIGHT - 1 then
    if not attractMode then
      if PowerupsManager.isBoltActive and playerCircle.next then
        if Powerups.checkLightningCollision(playerCircle) then
          Sound.play("teleport")
          particle(playerCircle.position, 20, 3, 0, math.pi * 2, Colors.yellow)
          particle(playerCircle.next.position, 20, 3, 0, math.pi * 2, Colors.yellow)
          playerCircle.isPassed = true
          playerCircle = playerCircle.next
          return
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
      particle(playerCircle.position, 20, 3, 0, math.pi * 2, Colors.yellow)
      particle(playerCircle.next.position, 20, 3, 0, math.pi * 2, Colors.yellow)
      playerCircle.isPassed = true
      playerCircle = playerCircle.next
    end
  end

  local obstacles = {}
  remove(circles, function(circle)
    circle.position.y = circle.position.y + scrollSpeed
    if circle.position.y > Settings.INTERNAL_HEIGHT + circle.radius then
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
  local trig = getCachedTrig(-rectAngle)
  local cosAngle = trig.cos
  local sinAngle = trig.sin

  local dx1 = lineP1.x - rectCenter.x
  local dy1 = lineP1.y - rectCenter.y
  local dx2 = lineP2.x - rectCenter.x
  local dy2 = lineP2.y - rectCenter.y

  local localP1x = dx1 * cosAngle - dy1 * sinAngle
  local localP1y = dx1 * sinAngle + dy1 * cosAngle
  local localP2x = dx2 * cosAngle - dy2 * sinAngle
  local localP2y = dx2 * sinAngle + dy2 * cosAngle

  local halfW = rectWidth * 0.5
  local halfH = rectHeight * 0.5

  return Game.lineAABBIntersect(localP1x, localP1y, localP2x, localP2y, -halfW, -halfH, halfW, halfH)
end

return Game
