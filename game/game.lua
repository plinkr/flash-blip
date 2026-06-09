local Game = {}

local Vector = require("lib.vector")
local Settings = require("settings")
local Powerups = require("powerups")
local Sound = require("sound")
local Colors = require("colors")
local MathUtils = require("math_utils")
local GameState = require("gamestate")
local PowerupsManager = require("powerups_manager")
local LevelsSelector = require("levels_selector")
local Debuffs = require("debuffs")
local PlayerProgress = require("player_progress")

Game.jumpPings = {}
Game.circles = {}
Game.playerCircle = nil
Game.particles = {}

local circles
local particles
local circleAddDist
local lastCircle
local playerCircle
local ticks
local difficulty
local baseDifficulty
local baseScrollSpeed = 0.08
local isAttractMode = false
local minCircleDist = Settings.INTERNAL_HEIGHT / 4

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
  isAttractMode = is_attract_mode
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
    position = vec(MathUtils.rnd(15, Settings.INTERNAL_WIDTH - 15), yPos),
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
    if not isAttractMode then
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
      if not isAttractMode then
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

local function getBlipColor(currentLevelData, blip_counter)
  if
    currentLevelData
    and currentLevelData.winCondition.type == "blips"
    and blip_counter.value == currentLevelData.winCondition.value - 1
  then
    return currentLevelData.winCondition.finalBlipColor
  else
    return PowerupsManager.getPingColor()
  end
end

function Game.handleSuccessfulBlip(blipType, params)
  blipType = blipType or "manual" -- "manual", "phase_shift", "bolt"

  local playerCircle = Game.get_player_circle()
  if not playerCircle or not playerCircle.next then
    return
  end

  local blipColor = getBlipColor(params.currentLevelData, params.blip_counter)

  if blipType == "phase_shift" or blipType == "bolt" then
    if not GameState.isAttractMode then
      Sound.play("teleport")
    end
    particle(playerCircle.position, 20, 3, 0, math.pi * 2, blipColor)
    particle(playerCircle.next.position, 20, 3, 0, math.pi * 2, blipColor)
  else -- "manual"
    if not GameState.isAttractMode then
      Sound.play("blip")
    end
    local currentPos = playerCircle.position:copy()
    -- Divide the distance between player and next point into 10 equal pieces
    local stepVector = (Vector:new(playerCircle.next.position.x, playerCircle.next.position.y)
      :sub(playerCircle.position)):div(10)
    local particleAngle = stepVector:angle()
    for _ = 1, 10 do
      particle(currentPos, 4, 2, particleAngle + math.pi, 0.5, blipColor)
      currentPos:add(stepVector)
    end
  end

  if blipType ~= "bolt" then
    params.setFlashLine({
      p1 = playerCircle.position:copy(),
      p2 = playerCircle.next.position:copy(),
      timer = 2,
    })
  end
  playerCircle.isPassed = true
  Game.set_player_circle(playerCircle.next)
  params.blip_counter.value = params.blip_counter.value + 1
  if
    params.currentLevelData
    and params.currentLevelData.winCondition.type == "blips"
    and params.blip_counter.value >= params.currentLevelData.winCondition.value
  then
    if blipType == "bolt" then
      params.setPendingWinLevelDelay(2)
    else
      params.setPendingWinLevel()
    end
  end
end

function Game.winLevel(currentLevelData, score, currentLevelHighScore, hiScore)
  GameState.set("levelCompleted")
  GameState.levelCompletedInputDelay = 1.5
  PowerupsManager.reset()
  if currentLevelData then -- Arcade mode
    if score > currentLevelHighScore then
      PlayerProgress.set_level_high_score(currentLevelData.id, score)
      currentLevelHighScore = score
      GameState.nuHiScore = true
      GameState.hiScoreFlashVisible = true
    end
  else
    if score > hiScore then
      hiScore = score
      GameState.nuHiScore = true
      GameState.hiScoreFlashVisible = true
    end
  end
  local current_level_index
  for i, level in ipairs(LevelsSelector.get_level_points()) do
    if currentLevelData and level.label == currentLevelData.id then
      current_level_index = i
      break
    end
  end
  if current_level_index and current_level_index < #LevelsSelector.get_level_points() then
    local next_level = LevelsSelector.get_level_points()[current_level_index + 1]
    PlayerProgress.unlock_level(next_level.label)
  end
  if current_level_index then
    GameState.allLevelsCompleted = (current_level_index == #LevelsSelector.get_level_points())
  end
  PlayerProgress.save()
  return currentLevelHighScore, hiScore
end

function Game.clearGameObjects()
  Game.circles = {}
  Game.particles = {}
  Game.playerCircle = nil
  Game.init(GameState.isAttractMode)
  PowerupsManager.init(Game.circles, GameState.isAttractMode)
  Debuffs.reset()
  if Powerups then
    Powerups.reset()
  end
  Game.jumpPings = {}
end

return Game
