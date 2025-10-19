--[[
FLASH-BLIP - A fast-paced 2D game built with the LÖVE framework. Dodge obstacles, survive as long as you can, and get the highest score.
--]]

Main = {}

local Moonshine = require("lib.shaders")
local Parallax = require("parallax")
local Vector = require("lib.vector")
local Powerups = require("powerups")
local Colors = require("colors")
local Text = require("text")
local Settings = require("settings")
local Sound = require("sound")
local About = require("about")
local Help = require("help")
local LevelsSelector = require("levels_selector")
local PlayerProgress = require("player_progress")
local PowerupsManager = require("powerups_manager")
local GameState = require("gamestate")
local MathUtils = require("math_utils")
local Game = require("game")
local Music = require("music")
local Input = require("input")

local score
local hiScore = 0
local currentLevelHighScore = 0
local gameOverLine = nil
local flashLine = nil
Main.currentLevelData = nil
local blip_counter = 0

local jumpPings = {}
local lastNextCircle = nil

local circles
local playerCircle
local particles
local gameCanvas
local effects
-- Platform detection: check once at module level
local isMobile = love.system.getOS() == "Android" or love.system.getOS() == "iOS"

local function initGame()
  score = 0
  blip_counter = 0
  GameState.set(GameState.attractMode and "attract" or "playing")
  gameOverLine = nil

  if Main.currentLevelData then
    currentLevelHighScore = PlayerProgress.get_level_high_score(Main.currentLevelData.id)
    Main.currentLevelData:load()
  else
    currentLevelHighScore = 0
  end

  local initDifficulty = Main.currentLevelData and Main.currentLevelData.difficulty or 1
  Game.init(GameState.attractMode, initDifficulty)
  circles = Game.get_circles()
  particles = Game.get_particles()
  playerCircle = Game.get_player_circle()

  Input:resetJustPressed()
  GameState.nuHiScore = false

  PowerupsManager.init(circles, GameState.attractMode)
  if Powerups then
    Powerups.stars = {}
    Powerups.clocks = {}
    Powerups.phaseShifts = {}
    Powerups.bolts = {}
    Powerups.scoreMultipliers = {}
    Powerups.spawnRateBoosts = {}
    Powerups.particles = {}
  end
  jumpPings = {}
end

Main.initGame = initGame

local function clearGameObjects()
  circles = {}
  particles = {}
  playerCircle = nil
  Game.init(GameState.attractMode)
  PowerupsManager.init(circles, GameState.attractMode)
  if Powerups then
    Powerups.stars = {}
    Powerups.clocks = {}
    Powerups.phaseShifts = {}
    Powerups.bolts = {}
    Powerups.scoreMultipliers = {}
    Powerups.spawnRateBoosts = {}
    Powerups.particles = {}
    Powerups.lightning = nil
  end
  jumpPings = {}
end

Main.clearGameObjects = clearGameObjects

function love.load()
  love.window.setTitle("FLASH-BLIP")

  -- Calculate optimal resolution for current screen
  local desktopWidth, desktopHeight = love.window.getDesktopDimensions()
  local scaleX = math.floor(desktopWidth / Settings.INTERNAL_WIDTH)
  local scaleY = math.floor(desktopHeight / Settings.INTERNAL_HEIGHT)
  Settings.SCALE_FACTOR = math.min(scaleX, scaleY)

  Settings.WINDOW_WIDTH = Settings.INTERNAL_WIDTH * Settings.SCALE_FACTOR
  Settings.WINDOW_HEIGHT = Settings.INTERNAL_HEIGHT * Settings.SCALE_FACTOR

  love.window.setMode(Settings.WINDOW_WIDTH, Settings.WINDOW_HEIGHT, {
    resizable = false,
    fullscreen = isMobile, -- only in mobiles is fullscreen
    vsync = true,
    highdpi = true,
  })

  Sound:load()
  Music.play()

  love.graphics.setBackgroundColor(Colors.dark_blue)

  gameCanvas = love.graphics.newCanvas(Settings.WINDOW_WIDTH, Settings.WINDOW_HEIGHT)

  if not isMobile then
    effects = Moonshine(Moonshine.effects.glow)
      .chain(Moonshine.effects.gaussianblur)
      .chain(Moonshine.effects.scanlines)
      .chain(Moonshine.effects.crt)

    effects.glow.strength = 20
    effects.glow.min_luma = 0.1
    effects.gaussianblur.sigma = 1
    effects.scanlines.width = 4
    effects.scanlines.opacity = 0.2
    effects.scanlines.color = Colors.light_blue
  end

  initGame()
  Parallax.load(nil, nil)
  About.load()
  Help.load()
  LevelsSelector.load()
  PlayerProgress.load()
  hiScore = PlayerProgress.get_endless_high_score()

  if Settings.IS_DEBUG_ENABLED then
    OverlayStats = require("lib.overlayStats")
    OverlayStats.load()
  end
end

local function endGame()
  if GameState.is("gameOver") then
    return
  end
  GameState.set("gameOver")
  GameState.gameOverInputDelay = 3.0
  if Main.currentLevelData then -- is Arcade mode
    if score > currentLevelHighScore then
      PlayerProgress.set_level_high_score(Main.currentLevelData.id, score)
      currentLevelHighScore = score
      GameState.nuHiScore = true
      GameState.hiScoreFlashVisible = true
    end
  elseif not GameState.attractMode then -- is Endless mode
    if score > hiScore then
      hiScore = score
      PlayerProgress.set_endless_high_score(score)
      GameState.nuHiScore = true
      GameState.hiScoreFlashVisible = true
    end
  end
end

local function updateParticles(dt)
  local writeIndex = 1
  for readIndex = 1, #particles do
    local p = particles[readIndex]
    p.pos:add(p.vel)
    p.life = p.life - 0.4

    if p.life > 0 then
      particles[writeIndex] = p
      writeIndex = writeIndex + 1
    end
  end

  for i = writeIndex, #particles do
    particles[i] = nil
  end
end

local function addScore(value)
  if not GameState.attractMode then
    local multiplier = PowerupsManager.isScoreMultiplierActive and 4 or 1
    score = score + (value * multiplier)
  end
end

local function particle(position, count, speed, angle, angleWidth, color)
  count = count or 1
  for _ = 1, count do
    local particleAngle = angle + MathUtils.rnds(angleWidth or 0)
    table.insert(particles, {
      pos = position:copy(),
      vel = Vector:new(math.cos(particleAngle) * speed, math.sin(particleAngle) * speed),
      life = MathUtils.rnd(10, 20),
      color = color or Colors.periwinkle_mist,
    })
  end
end
_G.particle = particle

local function restartGame()
  if GameState.is("gameOver") and (gameOverLine == nil or gameOverLine.timer <= 0) then
    initGame()
    GameState.restartDelayCounter = 10
  end
end

Main.restartGame = restartGame

function love.keypressed(key)
  Input:keypressed(key)
  if Settings.IS_DEBUG_ENABLED then
    OverlayStats.handleKeyboard(key)
  end
end

function love.wheelmoved(x, y)
  Input:wheelmoved(x, y)
end

function love.mousemoved(x, y, dx, dy, istouch)
  Input:mousemove(x, y)
end

function love.mousepressed(x, y, button)
  Input:mousepressed(x, y, button)
end

function love.touchpressed(id, x, y, dx, dy, pressure)
  Input:touchpressed(id, x, y, dx, dy, pressure)
end

function love.touchmoved(id, x, y, dx, dy, pressure)
  Input:touchmoved(id, x, y, dx, dy, pressure)
end

function love.touchreleased(id, x, y, dx, dy, pressure)
  Input:touchreleased(id, x, y, dx, dy, pressure)
end

function love.joystickpressed(joystick, button)
  Input:joystickpressed(joystick, button)
end

function love.gamepadpressed(joystick, button)
  Input:gamepadpressed(joystick, button)
end

function love.joystickadded(joystick)
  Input:joystickadded(joystick)
end

function love.joystickremoved(joystick)
  Input:joystickremoved(joystick)
end

local function activateJumpPing(circle, color)
  jumpPings = {}
  table.insert(jumpPings, {
    circle = circle,
    radius = 0,
    maxRadius = 12,
    speed = 10,
    life = 1,
    color = color,
  })
end

local function updatePings(dt)
  if GameState.isNot("playing") then
    return
  end
  for i = #jumpPings, 1, -1 do
    local ping = jumpPings[i]
    local currentMaxRadius = PowerupsManager.isPhaseShiftActive and 18 or 12
    ping.speed = PowerupsManager.isPhaseShiftActive and 15 or 10

    ping.radius = ping.radius + ping.speed * dt
    if ping.radius >= currentMaxRadius then
      -- Reset radius for cyclic effect
      ping.radius = 0
    end
  end
end

local function winLevel()
  GameState.set("levelCompleted")
  GameState.levelCompletedInputDelay = 1.5
  if Main.currentLevelData then -- Arcade mode
    if score > currentLevelHighScore then
      PlayerProgress.set_level_high_score(Main.currentLevelData.id, score)
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
    if Main.currentLevelData and level.label == Main.currentLevelData.id then
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
end

local function drawNextJumpPingIndicator()
  if GameState.isNot("playing") then
    return
  end
  for _, ping in ipairs(jumpPings) do
    if ping.life > 0 and ping.circle then
      local currentMaxRadius = PowerupsManager.isPhaseShiftActive and 18 or 12
      local color
      if
        Main.currentLevelData
        and Main.currentLevelData.winCondition.type == "blips"
        and blip_counter >= Main.currentLevelData.winCondition.value - 1
      then
        color = Main.currentLevelData.winCondition.finalBlipColor
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

function love.update(dt)
  if GameState.is("levels") then
    LevelsSelector.update(dt)
    return
  end
  dt = math.min(dt, 1 / 30)
  if GameState.isPaused then
    return
  end

  GameState.update(dt)
  Music.update(dt)

  Parallax.update(dt, GameState.current)
  PowerupsManager.update(dt, GameState.current)
  Powerups.updatePings(dt)
  updatePings(dt)
  Input:update(dt)

  if flashLine and flashLine.timer > 0 then
    flashLine.timer = flashLine.timer - 1
  else
    flashLine = nil
  end

  if GameState.is("gameOver") then
    if gameOverLine and gameOverLine.timer > 0 then
      gameOverLine.timer = gameOverLine.timer - 1
    end
    if
      Input:isGameOverContinue()
      and (gameOverLine == nil or gameOverLine.timer <= 0)
      and GameState.gameOverInputDelay <= 0
    then
      Main.restartGame()
    end
    if GameState.attractMode and (gameOverLine == nil or gameOverLine.timer <= 0) then
      initGame()
    end
    return
  end

  if GameState.is("levelCompleted") then
    if GameState.levelCompletedInputDelay <= 0 and Input:isLevelCompletedContinue() then
      Main.clearGameObjects()
      GameState.set("levels")
      Parallax.pause()
    end
    return
  end

  if GameState.is("help") then
    return
  end

  if GameState.restartDelayCounter > 0 then
    return
  end

  if GameState.attractMode then
    Input:simulateAttractInput(playerCircle)
  end

  local obstacles = Game.update(dt, PowerupsManager, endGame, addScore)
  playerCircle = Game.get_player_circle()
  circles = Game.get_circles()

  if playerCircle then
    local didTeleport = false
    if PowerupsManager.isPhaseShiftActive and playerCircle.next and GameState.ignoreInputTimer <= 0 then
      if Powerups.checkPingConnection(jumpPings) then
        if not GameState.attractMode then
          Sound.play("teleport")
        end
        local blipColor
        if
          Main.currentLevelData
          and Main.currentLevelData.winCondition.type == "blips"
          and blip_counter == Main.currentLevelData.winCondition.value - 1
        then
          blipColor = Main.currentLevelData.winCondition.finalBlipColor
        else
          blipColor = PowerupsManager.getPingColor()
        end
        particle(playerCircle.position, 20, 3, 0, math.pi * 2, blipColor)
        particle(playerCircle.next.position, 20, 3, 0, math.pi * 2, blipColor)
        flashLine = {
          p1 = playerCircle.position:copy(),
          p2 = playerCircle.next.position:copy(),
          timer = 2,
        }
        playerCircle.isPassed = true
        Game.set_player_circle(playerCircle.next)
        playerCircle = Game.get_player_circle()
        blip_counter = blip_counter + 1
        if
          Main.currentLevelData
          and Main.currentLevelData.winCondition.type == "blips"
          and blip_counter >= Main.currentLevelData.winCondition.value
        then
          winLevel()
        end
        didTeleport = true
      end
    end

    if not didTeleport and Input.isJustPressed() and playerCircle.next and GameState.ignoreInputTimer <= 0 then
      local wasInvulnerable = PowerupsManager.isInvulnerable
      local blipCollectedPowerup, collectedStar = PowerupsManager.handleBlipCollision(playerCircle)
      local collision = false
      if not PowerupsManager.isInvulnerable then
        for _, obstacle in ipairs(obstacles or {}) do
          if
            Game.checkLineRotatedRectCollision(
              playerCircle.position,
              playerCircle.next.position,
              obstacle.center,
              obstacle.width,
              obstacle.height,
              obstacle.angle
            )
          then
            collision = true
            break
          end
        end
      end

      if collision then
        if not GameState.attractMode then
          Sound.play("explosion")
          endGame()
          gameOverLine = {
            p1 = playerCircle.position:copy(),
            p2 = playerCircle.next.position:copy(),
            timer = 60,
            width = 3,
          }
        end
      else
        if not GameState.attractMode then
          Sound.play("blip")
        end
        local currentPos = playerCircle.position:copy()
        local blipColor
        if
          Main.currentLevelData
          and Main.currentLevelData.winCondition.type == "blips"
          and blip_counter == Main.currentLevelData.winCondition.value - 1
        then
          blipColor = Main.currentLevelData.winCondition.finalBlipColor
        else
          blipColor = PowerupsManager.getPingColor()
        end
        -- Divide the distance between player and next point into 10 equal pieces
        local stepVector = (Vector:new(playerCircle.next.position.x, playerCircle.next.position.y)
          :sub(playerCircle.position)):div(10)
        local particleAngle = stepVector:angle()
        for _ = 1, 10 do
          particle(currentPos, 4, 2, particleAngle + math.pi, 0.5, blipColor)
          currentPos:add(stepVector)
        end
        flashLine = {
          p1 = playerCircle.position:copy(),
          p2 = playerCircle.next.position:copy(),
          timer = 2,
        }
        playerCircle.isPassed = true
        Game.set_player_circle(playerCircle.next)
        playerCircle = Game.get_player_circle()
        blip_counter = blip_counter + 1
        if
          Main.currentLevelData
          and Main.currentLevelData.winCondition.type == "blips"
          and blip_counter >= Main.currentLevelData.winCondition.value
        then
          winLevel()
        end
        -- If a power-up was collected on the blip, invulnerability is deactivated upon arriving at the destination only if it wasn't active previously.
        if blipCollectedPowerup and not collectedStar and not wasInvulnerable then
          PowerupsManager.isInvulnerable = false
        end
      end
    end
  end

  if playerCircle and playerCircle.next and playerCircle.next ~= lastNextCircle then
    activateJumpPing(playerCircle.next, Colors.periwinkle_mist)
    lastNextCircle = playerCircle.next
  elseif not playerCircle or not playerCircle.next then
    lastNextCircle = nil
    jumpPings = {}
  end

  PowerupsManager.handlePlayerCollision(playerCircle)

  updateParticles(dt)

  Input:resetJustPressed()

  if Settings.IS_DEBUG_ENABLED then
    OverlayStats.update(dt)
    local fps = love.timer.getFPS()
    if fps < 58 then
      print(
        string.format(
          "FPS dropped to %.2f | dt: %.4f | State: %s | Particles: %d | Circles: %d | Blips: %d | Time: %.2f",
          fps,
          dt,
          GameState.current,
          #particles,
          #circles,
          blip_counter,
          love.timer.getTime()
        )
      )
    end
  end
end

local function drawSpawnRateIndicator()
  if GameState.is("gameOver") then
    return
  end
  local pulse = math.sin(love.timer.getTime() * 8) * 0.2 + 0.6 -- Pulses between 40% and 80% opacity
  local color = Colors.neon_lime_splash

  love.graphics.setColor(color[1], color[2], color[3], pulse)

  love.graphics.rectangle("fill", 0, 0, Settings.INTERNAL_WIDTH, 2.5)
end

function love.draw()
  love.graphics.setCanvas(gameCanvas)
  love.graphics.clear()
  Parallax.draw()

  love.graphics.push()
  love.graphics.scale(Settings.SCALE_FACTOR, Settings.SCALE_FACTOR)

  for _, p in ipairs(particles) do
    local alpha = math.max(0, p.life / 20)
    if PowerupsManager.isInvulnerable then
      love.graphics.setColor(Colors.yellow[1], Colors.yellow[2], Colors.yellow[3], alpha)
    else
      love.graphics.setColor(p.color[1], p.color[2], p.color[3], alpha)
    end
    love.graphics.circle("fill", p.pos.x, p.pos.y, 0.5)
  end

  -- Draw circles and their rotating obstacles
  for _, circle in ipairs(circles) do
    if
      Main.currentLevelData
      and Main.currentLevelData.winCondition.type == "blips"
      and blip_counter == Main.currentLevelData.winCondition.value - 1
      and circle == playerCircle.next
    then
      love.graphics.setColor(Main.currentLevelData.winCondition.finalBlipColor)
    elseif
      PowerupsManager.isPhaseShiftActive and (circle == playerCircle or (playerCircle and circle == playerCircle.next))
    then
      love.graphics.setColor(Colors.emerald_shade)
    elseif
      PowerupsManager.isInvulnerable and (circle == playerCircle or (playerCircle and circle == playerCircle.next))
    then
      love.graphics.setColor(Colors.yellow)
    elseif circle == playerCircle or (playerCircle and circle == playerCircle.next) then
      if PowerupsManager.isSlowed then
        love.graphics.setColor(Colors.light_blue_glow)
      else
        love.graphics.setColor(Colors.periwinkle_mist)
      end
    elseif circle.isPassed then
      love.graphics.setColor(Colors.rusty_cedar_transparent)
    else
      love.graphics.setColor(Colors.rusty_cedar)
    end
    if not (PowerupsManager.isInvulnerable and circle == playerCircle) then
      love.graphics.circle("fill", circle.position.x, circle.position.y, 1.5)
    end

    -- Obstacles
    if PowerupsManager.isSlowed then
      love.graphics.setColor(Colors.light_blue_glow)
    else
      love.graphics.setColor(Colors.safety_orange)
    end
    for i = 1, circle.obstacleCount do
      local obstacleAngle = circle.angle + (i * math.pi * 2) / circle.obstacleCount
      local rectCenter = Vector:new(circle.position.x, circle.position.y):addWithAngle(obstacleAngle, circle.radius)

      love.graphics.push()
      love.graphics.translate(rectCenter.x, rectCenter.y)
      love.graphics.rotate(obstacleAngle + math.pi / 2) -- The obstacles are perpendicular to radius.
      love.graphics.rectangle("fill", -circle.obstacleLength / 2, -1.5, circle.obstacleLength, 3, 1.2, 1.2)
      love.graphics.pop()
    end
  end

  -- Draw the player (larger square circle).
  if playerCircle then
    if PowerupsManager.isInvulnerable then
      -- Invulnerability visual effect (blinking) pulses from 0.2 to 1.0 (20% to 100% opacity)
      local alpha = 0.6 + math.sin(love.timer.getTime() * 20) * 0.4
      love.graphics.setColor(Colors.yellow[1], Colors.yellow[2], Colors.yellow[3], alpha)
    elseif PowerupsManager.isPhaseShiftActive then
      love.graphics.setColor(Colors.emerald_shade)
    elseif PowerupsManager.isSlowed then
      love.graphics.setColor(Colors.light_blue_glow)
    else
      love.graphics.setColor(Colors.periwinkle_mist)
    end
    love.graphics.rectangle("fill", playerCircle.position.x - 2.5, playerCircle.position.y - 2.5, 5, 5, 1.6, 1.6)
  end

  if PowerupsManager.isSpawnRateBoostActive then
    drawSpawnRateIndicator()
  end

  if gameOverLine then
    if PowerupsManager.isPhaseShiftActive then
      love.graphics.setColor(Colors.emerald_shade)
    elseif PowerupsManager.isSlowed then
      love.graphics.setColor(Colors.light_blue_glow)
    else
      love.graphics.setColor(Colors.periwinkle_mist)
    end
    local angle =
      Vector:new(gameOverLine.p2.x, gameOverLine.p2.y):sub(Vector:new(gameOverLine.p1.x, gameOverLine.p1.y)):angle()
    local length = gameOverLine.p1:distance(gameOverLine.p2) + 2
    local width = gameOverLine.width or 2

    love.graphics.push()
    love.graphics.translate(gameOverLine.p1.x, gameOverLine.p1.y)
    love.graphics.rotate(angle)
    love.graphics.rectangle("fill", 0, -width / 2, length, width, width / 2, width / 2)
    love.graphics.pop()
  end

  -- The "blip" line effect.
  if flashLine then
    local dist = flashLine.p1:distance(flashLine.p2)
    local stepVector = Vector:new(flashLine.p2.x, flashLine.p2.y):sub(flashLine.p1):normalize()
    local currentPos = flashLine.p1:copy()
    for i = 0, dist, 3 do
      local alpha = i / dist
      if
        Main.currentLevelData
        and Main.currentLevelData.winCondition.type == "blips"
        and blip_counter >= Main.currentLevelData.winCondition.value
      then
        love.graphics.setColor(
          Main.currentLevelData.winCondition.finalBlipColor[1],
          Main.currentLevelData.winCondition.finalBlipColor[2],
          Main.currentLevelData.winCondition.finalBlipColor[3],
          alpha
        )
      elseif PowerupsManager.isInvulnerable then
        love.graphics.setColor(Colors.yellow[1], Colors.yellow[2], Colors.yellow[3], alpha)
      elseif PowerupsManager.isPhaseShiftActive then
        love.graphics.setColor(Colors.emerald_shade[1], Colors.emerald_shade[2], Colors.emerald_shade[3], alpha)
      elseif PowerupsManager.isSlowed then
        love.graphics.setColor(Colors.cyan_glow[1], Colors.cyan_glow[2], Colors.cyan_glow[3], alpha)
      else
        love.graphics.setColor(Colors.periwinkle_mist[1], Colors.periwinkle_mist[2], Colors.periwinkle_mist[3], alpha)
      end
      love.graphics.rectangle("fill", currentPos.x - 2, currentPos.y - 2, 4, 4, 1.6, 1.6)
      currentPos:add(stepVector:copy():mul(3))
    end
  end

  Powerups.draw(GameState.current)

  if PowerupsManager.isBoltActive and GameState.isNot("gameOver") then
    Powerups.drawLightning()
  end

  if GameState.isNot("gameOver") then
    Powerups.drawPings()
    drawNextJumpPingIndicator()
  end

  love.graphics.pop()

  -- Draw user interface (UI).
  love.graphics.push()
  love.graphics.origin() -- Reset any previous scale transformations
  local displayHiScore = hiScore
  if Main.currentLevelData then
    displayHiScore = currentLevelHighScore
  end

  if not GameState.attractMode and not GameState.is("levels") then
    Text.drawScore(score, displayHiScore, PowerupsManager.isScoreMultiplierActive)
  end

  if GameState.is("attract") then
    Text.drawAttract(Input.getMenuItems(), Input.getSelectedMenuItem())
  end

  if GameState.is("gameOver") and not GameState.attractMode then
    if not gameOverLine or gameOverLine.timer <= 0 then
      Text.drawGameOver(displayHiScore, GameState.nuHiScore, GameState.hiScoreFlashVisible)
    end
  end

  if GameState.is("levelCompleted") then
    if GameState.allLevelsCompleted then
      Text.drawAllLevelsCompleted(displayHiScore, GameState.nuHiScore, GameState.hiScoreFlashVisible)
    else
      Text.drawLevelCompleted(displayHiScore, GameState.nuHiScore, GameState.hiScoreFlashVisible)
    end
  end

  if GameState.isPaused then
    Text.drawPauseMenu(Input.getPauseMenuItems(), Input.getSelectedPauseMenuItem())
  end

  love.graphics.pop()

  love.graphics.setCanvas()

  local function drawGameAndUI()
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.draw(gameCanvas)
    if GameState.is("help") then
      Help.draw()
    elseif GameState.is("about") then
      About.draw()
    elseif GameState.is("levels") then
      LevelsSelector.draw()
    end
  end

  if isMobile then
    drawGameAndUI()
  else
    -- Draw canvas to screen applying shader effects
    effects(drawGameAndUI)
  end

  if Settings.IS_DEBUG_ENABLED then
    OverlayStats.draw()
  end
end

function Main.start_game_from_level(levelData)
  Main.currentLevelData = levelData
  if Main.currentLevelData.winCondition.type == "blips" then
    Main.currentLevelData.winCondition.value =
      math.ceil(Main.currentLevelData.winCondition.value * Main.currentLevelData.difficulty)
  end
  Parallax.load(Main.currentLevelData.backgroundColor, Main.currentLevelData.starColors)
  Main.currentLevelData:load()
  GameState.attractMode = false
  initGame()
  Parallax.resume()
end

function Main.set_game_state(state)
  GameState.set(state)
end
