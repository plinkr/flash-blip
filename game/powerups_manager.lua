local PowerupsManager = {}

local Powerups = require("powerups")
local Sound = require("sound")
local circles = {}
local attractMode = false
local MathUtils = require("math_utils")
local colors = require("colors")

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

function PowerupsManager.init(circles_ref, is_attract_mode)
  circles = circles_ref
  attractMode = is_attract_mode
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
  originalVelocities = {}
  originalSizes = {}
end

function PowerupsManager.getPlayerColor()
  if PowerupsManager.isInvulnerable then
    return colors.yellow
  elseif PowerupsManager.isPhaseShiftActive then
    return colors.emerald_shade
  elseif PowerupsManager.isSlowed then
    return colors.cyan_glow
  else
    return colors.periwinkle_mist
  end
end

function PowerupsManager.getPingColor()
  if PowerupsManager.isPhaseShiftActive then
    return colors.emerald_shade
  elseif PowerupsManager.isInvulnerable then
    return colors.yellow
  elseif PowerupsManager.isSlowed then
    return colors.cyan_glow
  else
    return colors.periwinkle_mist
  end
end

function PowerupsManager.update(dt, gameState)
  if PowerupsManager.isInvulnerable and gameState ~= "help" then
    PowerupsManager.invulnerabilityTimer = PowerupsManager.invulnerabilityTimer - dt
    if PowerupsManager.invulnerabilityTimer <= 0 then
      PowerupsManager.isInvulnerable = false
    end
  end

  if PowerupsManager.isSlowed and gameState ~= "help" then
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

  if PowerupsManager.isPhaseShiftActive and gameState ~= "help" then
    PowerupsManager.phaseShiftTimer = PowerupsManager.phaseShiftTimer - dt
    if PowerupsManager.phaseShiftTimer <= 0 then
      PowerupsManager.isPhaseShiftActive = false
    end
  end

  if PowerupsManager.isBoltActive and gameState ~= "help" then
    PowerupsManager.boltTimer = PowerupsManager.boltTimer - dt
    if PowerupsManager.boltTimer <= 0 then
      PowerupsManager.isBoltActive = false
    end
  end

  if PowerupsManager.isScoreMultiplierActive and gameState ~= "help" then
    PowerupsManager.scoreMultiplierTimer = PowerupsManager.scoreMultiplierTimer - dt
    if PowerupsManager.scoreMultiplierTimer <= 0 then
      PowerupsManager.isScoreMultiplierActive = false
    end
  end

  if PowerupsManager.isSpawnRateBoostActive and gameState ~= "help" then
    PowerupsManager.spawnRateBoostTimer = PowerupsManager.spawnRateBoostTimer - dt
    if PowerupsManager.spawnRateBoostTimer <= 0 then
      PowerupsManager.isSpawnRateBoostActive = false
    end
  end

  Powerups.update(dt, gameState, PowerupsManager.isBoltActive, PowerupsManager.isSpawnRateBoostActive)
end

function PowerupsManager.handleBlipCollision(playerCircle)
  local collectedStar, collectedClock, collectedPhaseShift, collectedBolt, collectedScoreMultiplier, collectedSpawnRateBoost =
    Powerups.checkBlipCollision(playerCircle, playerCircle.next)

  if collectedStar then
    PowerupsManager.isInvulnerable = true
    PowerupsManager.invulnerabilityTimer = 10
    if not attractMode then
      Sound.play("star_powerup")
    end
  end
  if collectedClock then
    PowerupsManager.isSlowed = true
    PowerupsManager.slowMotionTimer = 10
    if not attractMode then
      Sound.play("slowdown_powerup")
    end
    originalVelocities = {}
    originalSizes = {}
    for _, circle in ipairs(circles) do
      originalVelocities[circle] = circle.angularVelocity
      circle.angularVelocity = MathUtils.rnds(0.005, 0.015)
      originalSizes[circle] = circle.obstacleLength
      circle.obstacleLength = circle.obstacleLength * 0.5
    end
  end
  if collectedPhaseShift then
    PowerupsManager.isPhaseShiftActive = true
    PowerupsManager.phaseShiftTimer = 10
    if not attractMode then
      Sound.play("phaseshift_powerup")
    end
  end
  if collectedBolt then
    PowerupsManager.isBoltActive = true
    PowerupsManager.boltTimer = 30
    Powerups.createLightning()
    if not attractMode then
      Sound.play("bolt_powerup")
    end
  end
  if collectedScoreMultiplier then
    PowerupsManager.isScoreMultiplierActive = true
    PowerupsManager.scoreMultiplierTimer = 30
    if not attractMode then
      Sound.play("star_powerup")
    end
  end
  if collectedSpawnRateBoost then
    PowerupsManager.isSpawnRateBoostActive = true
    PowerupsManager.spawnRateBoostTimer = 30
    if not attractMode then
      Sound.play("phaseshift_powerup")
    end
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
  local collectedStar, collectedClock, collectedPhaseShift, collectedBolt, collectedScoreMultiplier, collectedSpawnRateBoost =
    Powerups.checkCollisions(playerCircle)
  if collectedStar and not attractMode then
    PowerupsManager.isInvulnerable = true
    PowerupsManager.invulnerabilityTimer = 10
    Sound.play("star_powerup")
  end

  if collectedClock and not attractMode then
    PowerupsManager.isSlowed = true
    PowerupsManager.slowMotionTimer = 10
    Sound.play("slowdown_powerup")

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

  if collectedPhaseShift and not attractMode then
    PowerupsManager.isPhaseShiftActive = true
    PowerupsManager.phaseShiftTimer = 10
    Sound.play("phaseshift_powerup")
  end

  if collectedBolt and not attractMode then
    PowerupsManager.isBoltActive = true
    PowerupsManager.boltTimer = 30
    Powerups.createLightning()
    Sound.play("bolt_powerup")
  end

  if collectedScoreMultiplier and not attractMode then
    PowerupsManager.isScoreMultiplierActive = true
    PowerupsManager.scoreMultiplierTimer = 30
    Sound.play("star_powerup")
  end

  if collectedSpawnRateBoost and not attractMode then
    PowerupsManager.isSpawnRateBoostActive = true
    PowerupsManager.spawnRateBoostTimer = 30
    Sound.play("phaseshift_powerup")
  end
end

return PowerupsManager
