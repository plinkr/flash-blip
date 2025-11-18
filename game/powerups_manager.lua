local PowerupsManager = {}

local Powerups = require("powerups")
local Sound = require("sound")
local MathUtils = require("math_utils")
local Colors = require("colors")
local GameState = require("gamestate")
local Settings = require("settings")

local circles = {}
local isAttractMode = false

PowerupsManager.isInvulnerable = false
PowerupsManager.invulnerabilityTimer = 0
PowerupsManager.isSlowed = false
PowerupsManager.slowMotionTimer = 0
PowerupsManager.isPhaseShiftActive = false
PowerupsManager.phaseShiftTimer = 0
PowerupsManager.isBoltActive = false
PowerupsManager.boltTimer = 0
PowerupsManager.isScoreMultiplierActive = false
PowerupsManager.scoreMultiplierTimer = 0
PowerupsManager.isSpawnRateBoostActive = false
PowerupsManager.spawnRateBoostTimer = 0

local originalVelocities = {}
local originalSizes = {}

local function activate_invulnerability(attract_mode_active)
  PowerupsManager.isInvulnerable = true
  PowerupsManager.invulnerabilityTimer = 10
  if not attract_mode_active then
    Sound.play("star_powerup")
  end
end

local function activate_slow_motion(attract_mode_active)
  PowerupsManager.isSlowed = true
  PowerupsManager.slowMotionTimer = 10
  if not attract_mode_active then
    Sound.play("slowdown_powerup")
  end
  originalVelocities = {}
  originalSizes = {}
  for _, circle in ipairs(circles) do
    originalVelocities[circle] = circle.angularVelocity
    circle.angularVelocity = MathUtils.rnds(0.005, 0.015)
    originalSizes[circle] = circle.obstacleLength
    local minObstacleLength = 5
    circle.obstacleLength = math.max(circle.obstacleLength * 0.5, minObstacleLength)
  end
end

local function activate_phase_shift(attract_mode_active)
  PowerupsManager.isPhaseShiftActive = true
  PowerupsManager.phaseShiftTimer = 10
  if not attract_mode_active then
    Sound.play("phaseshift_powerup")
  end
end

local function activate_bolt(attract_mode_active)
  PowerupsManager.isBoltActive = true
  PowerupsManager.boltTimer = 30
  Powerups.createLightning()
  if not attract_mode_active then
    Sound.play("bolt_powerup")
  end
end

local function activate_score_multiplier(attract_mode_active)
  PowerupsManager.isScoreMultiplierActive = true
  PowerupsManager.scoreMultiplierTimer = 30
  if not attract_mode_active then
    Sound.play("star_powerup")
  end
end

local function activate_spawn_rate_boost(attract_mode_active)
  PowerupsManager.isSpawnRateBoostActive = true
  PowerupsManager.spawnRateBoostTimer = 30
  if not attract_mode_active then
    Sound.play("phaseshift_powerup")
  end
end

function PowerupsManager.init(circles_ref, is_attract_mode)
  circles = circles_ref
  isAttractMode = is_attract_mode
  PowerupsManager.reset()
  originalVelocities = {}
  originalSizes = {}
end

function PowerupsManager.reset()
  PowerupsManager.isInvulnerable = false
  PowerupsManager.invulnerabilityTimer = 0
  PowerupsManager.isSlowed = false
  PowerupsManager.slowMotionTimer = 0
  PowerupsManager.isPhaseShiftActive = false
  PowerupsManager.phaseShiftTimer = 0
  PowerupsManager.isBoltActive = false
  PowerupsManager.boltTimer = 0
  PowerupsManager.isScoreMultiplierActive = false
  PowerupsManager.scoreMultiplierTimer = 0
  PowerupsManager.isSpawnRateBoostActive = false
  PowerupsManager.spawnRateBoostTimer = 0
end

function PowerupsManager.getPlayerColor()
  if PowerupsManager.isInvulnerable then
    return Colors.yellow
  elseif PowerupsManager.isPhaseShiftActive then
    return Colors.emerald_shade
  elseif PowerupsManager.isSlowed then
    return Colors.cyan_glow
  else
    return Colors.periwinkle_mist
  end
end

function PowerupsManager.getPingColor()
  if PowerupsManager.isPhaseShiftActive then
    return Colors.emerald_shade
  elseif PowerupsManager.isInvulnerable then
    return Colors.yellow
  elseif PowerupsManager.isSlowed then
    return Colors.cyan_glow
  else
    return Colors.periwinkle_mist
  end
end

function PowerupsManager.getCurrentMaxRadius()
  return PowerupsManager.isPhaseShiftActive and 18 or 12
end

function PowerupsManager.drawNextJumpPingIndicator(jumpPings, blip_counter, currentLevelData)
  if not jumpPings then
    return
  end
  if GameState.isNot("playing") then
    return
  end
  for _, ping in ipairs(jumpPings) do
    if ping.life > 0 and ping.circle then
      local currentMaxRadius = PowerupsManager.getCurrentMaxRadius()
      local color
      if
        currentLevelData
        and currentLevelData.winCondition.type == "blips"
        and blip_counter.value >= currentLevelData.winCondition.value - 1
      then
        color = currentLevelData.winCondition.finalBlipColor
      elseif ping.circle and ping.circle.isPassed then
        color = Colors.rusty_cedar_transparent
      else
        color = PowerupsManager.getPingColor()
      end
      local alpha = math.max(0, 1 - (ping.radius / currentMaxRadius))

      love.graphics.setColor(color[1], color[2], color[3], alpha * 0.8)
      love.graphics.setLineWidth(1.5)
      love.graphics.circle("line", ping.circle.position.x, ping.circle.position.y, ping.radius)
      love.graphics.setLineWidth(1)
    end
  end
end

function PowerupsManager.update(dt, gameState)
  if PowerupsManager.isInvulnerable and gameState ~= "help" and gameState ~= "levelCompleted" then
    PowerupsManager.invulnerabilityTimer = PowerupsManager.invulnerabilityTimer - dt
    if PowerupsManager.invulnerabilityTimer <= 0 then
      PowerupsManager.isInvulnerable = false
    end
  end

  if PowerupsManager.isSlowed and gameState ~= "help" and gameState ~= "levelCompleted" then
    PowerupsManager.slowMotionTimer = PowerupsManager.slowMotionTimer - dt
    if PowerupsManager.slowMotionTimer <= 0 then
      PowerupsManager.isSlowed = false
      for _, circle in ipairs(circles) do
        if originalVelocities[circle] then
          circle.angularVelocity = originalVelocities[circle]
        end
        if originalSizes[circle] then
          circle.obstacleLength = originalSizes[circle]
        end
      end
      originalVelocities = {}
      originalSizes = {}
    end
  end

  if PowerupsManager.isPhaseShiftActive and gameState ~= "help" and gameState ~= "levelCompleted" then
    PowerupsManager.phaseShiftTimer = PowerupsManager.phaseShiftTimer - dt
    if PowerupsManager.phaseShiftTimer <= 0 then
      PowerupsManager.isPhaseShiftActive = false
    end
  end

  if PowerupsManager.isBoltActive and gameState ~= "help" and gameState ~= "levelCompleted" then
    PowerupsManager.boltTimer = PowerupsManager.boltTimer - dt
    if PowerupsManager.boltTimer <= 0 then
      PowerupsManager.isBoltActive = false
    end
  end

  if PowerupsManager.isScoreMultiplierActive and gameState ~= "help" and gameState ~= "levelCompleted" then
    PowerupsManager.scoreMultiplierTimer = PowerupsManager.scoreMultiplierTimer - dt
    if PowerupsManager.scoreMultiplierTimer <= 0 then
      PowerupsManager.isScoreMultiplierActive = false
    end
  end

  if PowerupsManager.isSpawnRateBoostActive and gameState ~= "help" and gameState ~= "levelCompleted" then
    PowerupsManager.spawnRateBoostTimer = PowerupsManager.spawnRateBoostTimer - dt
    if PowerupsManager.spawnRateBoostTimer <= 0 then
      PowerupsManager.isSpawnRateBoostActive = false
    end
  end

  Powerups.update(dt, gameState, PowerupsManager.isBoltActive, PowerupsManager.isSpawnRateBoostActive)
end

function PowerupsManager.handleBlipCollision(playerCircle)
  if not playerCircle or not playerCircle.next then
    return false, false
  end
  local collectedStar, collectedClock, collectedPhaseShift, collectedBolt, collectedScoreMultiplier, collectedSpawnRateBoost =
    Powerups.checkBlipCollision(playerCircle, playerCircle.next)

  if collectedStar then
    activate_invulnerability(isAttractMode)
  end
  if collectedClock then
    activate_slow_motion(isAttractMode)
  end
  if collectedPhaseShift then
    activate_phase_shift(isAttractMode)
  end
  if collectedBolt then
    activate_bolt(isAttractMode)
  end
  if collectedScoreMultiplier then
    activate_score_multiplier(isAttractMode)
  end
  if collectedSpawnRateBoost then
    activate_spawn_rate_boost(isAttractMode)
  end

  local blipCollectedPowerup = collectedStar
    or collectedClock
    or collectedPhaseShift
    or collectedBolt
    or collectedScoreMultiplier
    or collectedSpawnRateBoost

  if blipCollectedPowerup and not collectedStar then
    PowerupsManager.isInvulnerable = true
  end

  return blipCollectedPowerup, collectedStar
end

function PowerupsManager.handlePlayerCollision(playerCircle)
  if not playerCircle then
    return
  end
  local collectedStar, collectedClock, collectedPhaseShift, collectedBolt, collectedScoreMultiplier, collectedSpawnRateBoost =
    Powerups.checkCollisions(playerCircle)
  if collectedStar then
    activate_invulnerability(isAttractMode)
  end

  if collectedClock then
    activate_slow_motion(isAttractMode)
  end

  if collectedPhaseShift then
    activate_phase_shift(isAttractMode)
  end

  if collectedBolt then
    activate_bolt(isAttractMode)
  end

  if collectedScoreMultiplier then
    activate_score_multiplier(isAttractMode)
  end

  if collectedSpawnRateBoost then
    activate_spawn_rate_boost(isAttractMode)
  end
end

local function drawSpawnRateIndicator()
  if GameState.is("gameOver") or GameState.is("levelCompleted") then
    return
  end
  local alpha_pulse = 0.8
  if not GameState.isPaused then
    alpha_pulse = math.sin(love.timer.getTime() * 8) * 0.2 + 0.6 -- Pulses between 40% and 80% opacity
  end
  local color = Colors.neon_lime_splash

  love.graphics.setColor(color[1], color[2], color[3], alpha_pulse)
  love.graphics.rectangle("fill", 0, 0, Settings.INTERNAL_WIDTH, 2.5)
end

PowerupsManager.drawSpawnRateIndicator = drawSpawnRateIndicator

return PowerupsManager
