--[[
FLASH-BLIP - A fast-paced 2D game built with the LÖVE framework. Dodge obstacles, survive as long as you can, and get the highest score.
--]]

Main = {}

local overlayStats = require("lib.overlayStats")
local moonshine = require("lib.shaders")
local Parallax = require("parallax")
local Vector = require("lib.vector")
local Powerups = require("powerups")
local colors = require("colors")
local Text = require("text")
local settings = require("settings")
local Sound = require("sound")
local About = require("about")
local Help = require("help")
local Levels = require("levels")
local PlayerProgress = require("player_progress")
local PowerupsManager = require("powerups_manager")
local GameState = require("gamestate")
local MathUtils = require("math_utils")
local Game = require("game")
local Music = require("music")

local score
local hiScore = 0
local currentLevelHighScore = 0
local gameOverLine = nil
local flashLine = nil
local currentLevelData = nil
local blip_counter = 0

local justPressed = false

local jumpPings = {}
local lastNextCircle = nil

local circles
local playerCircle
local particles
local gameCanvas

local effects

local helpScrollY = 0
local menuItems = {
  { text = "ENDLESS MODE", action = "start_endless" },
  { text = "ARCADE MODE", action = "start_arcade" },
  { text = "ABOUT", action = "show_about" },
  { text = "HELP", action = "show_help" },
}
if love.system.getOS() ~= "Web" then
  table.insert(menuItems, { text = "EXIT", action = "exit_game" })
end
local selectedMenuItem = 1
local pauseMenuItems = {
  { text = "RESUME", action = "resume" },
  { text = "RESTART", action = "restart" },
  { text = "HELP", action = "show_help" },
  { text = "QUIT TO MENU", action = "quit_to_menu" },
}
local selectedPauseMenuItem = 1

-- Enables debug statistics (can be toggled with F3).
local isDebugEnabled = false

local function initGame()
  score = 0
  blip_counter = 0
  GameState.set(GameState.attractMode and "attract" or "playing")
  gameOverLine = nil

  if currentLevelData then
    currentLevelHighScore = PlayerProgress.get_level_high_score(currentLevelData.id)
    currentLevelData:load()
  else
    currentLevelHighScore = 0
  end

  local initDifficulty = currentLevelData and currentLevelData.difficulty or 1
  Game.init(GameState.attractMode, initDifficulty)
  circles = Game.get_circles()
  particles = Game.get_particles()
  playerCircle = Game.get_player_circle()

  justPressed = false
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

function love.load()
  love.window.setTitle("FLASH-BLIP")

  -- Calculate optimal resolution for current screen
  local desktopWidth, desktopHeight = love.window.getDesktopDimensions()
  local scaleX = math.floor(desktopWidth / settings.INTERNAL_WIDTH)
  local scaleY = math.floor(desktopHeight / settings.INTERNAL_HEIGHT)
  settings.SCALE_FACTOR = math.min(scaleX, scaleY)

  settings.WINDOW_WIDTH = settings.INTERNAL_WIDTH * settings.SCALE_FACTOR
  settings.WINDOW_HEIGHT = settings.INTERNAL_HEIGHT * settings.SCALE_FACTOR

  love.window.setMode(settings.WINDOW_WIDTH, settings.WINDOW_HEIGHT, {
    resizable = false,
    vsync = true,
    highdpi = true,
  })

  Sound:load()
  Music.play()

  love.graphics.setBackgroundColor(colors.dark_blue)
  -- love.graphics.setDefaultFilter("nearest", "nearest")

  gameCanvas = love.graphics.newCanvas(settings.WINDOW_WIDTH, settings.WINDOW_HEIGHT)
  -- gameCanvas:setFilter("nearest", "nearest")

  effects = moonshine(moonshine.effects.glow)
    .chain(moonshine.effects.gaussianblur)
    .chain(moonshine.effects.scanlines)
    .chain(moonshine.effects.crt)

  effects.glow.strength = 20
  effects.glow.min_luma = 0.1
  effects.gaussianblur.sigma = 1
  effects.scanlines.width = 4
  effects.scanlines.opacity = 0.2
  effects.scanlines.color = colors.light_blue

  initGame()
  Parallax.load(nil, nil)
  About.load()
  Help.load()
  Levels.load()
  PlayerProgress.load()
  hiScore = PlayerProgress.get_endless_high_score()

  if isDebugEnabled then
    overlayStats.load()
  end
end

local function endGame()
  if GameState.is("gameOver") then
    return
  end
  GameState.set("gameOver")
  GameState.gameOverInputDelay = 3.0
  if currentLevelData then -- is Arcade mode
    if score > currentLevelHighScore then
      PlayerProgress.set_level_high_score(currentLevelData.id, score)
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

local function remove(tbl, predicate)
  local i = #tbl
  while i >= 1 do
    if predicate(tbl[i]) then
      table.remove(tbl, i)
    end
    i = i - 1
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
      color = color or colors.periwinkle_mist,
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

function love.keypressed(key)
  if GameState.is("attract") then
    if key == "up" then
      selectedMenuItem = math.max(1, selectedMenuItem - 1)
      Sound.play("blip")
    elseif key == "down" then
      selectedMenuItem = math.min(#menuItems, selectedMenuItem + 1)
      Sound.play("blip")
    elseif key == "return" or key == "space" then
      local action = menuItems[selectedMenuItem].action
      if action == "start_endless" then
        GameState.attractMode = false
        currentLevelData = nil
        love.math.setRandomSeed(os.time())
        initGame()
      elseif action == "start_arcade" then
        GameState.set("levels")
        clearGameObjects()
        -- Parallax.pause()
      elseif action == "show_about" then
        GameState.previous = "attract"
        GameState.set("about")
      elseif action == "show_help" then
        GameState.previous = GameState.current
        GameState.set("help")
      elseif action == "exit_game" then
        love.event.quit()
      end
    end
  elseif GameState.is("help") then
    Help.keypressed(key)
  elseif GameState.isPaused then
    if key == "up" then
      selectedPauseMenuItem = math.max(1, selectedPauseMenuItem - 1)
      Sound.play("blip")
    elseif key == "down" then
      selectedPauseMenuItem = math.min(#pauseMenuItems, selectedPauseMenuItem + 1)
      Sound.play("blip")
    elseif key == "return" then
      local action = pauseMenuItems[selectedPauseMenuItem].action
      if action == "resume" then
        GameState.isPaused = false
      elseif action == "restart" then
        GameState.isPaused = false
        initGame()
      elseif action == "show_help" then
        GameState.previous = GameState.current
        GameState.set("help")
      elseif action == "quit_to_menu" then
        GameState.isPaused = false
        GameState.attractMode = true
        currentLevelData = nil
        initGame()
      end
    end
  elseif GameState.is("playing") and (key == "space" or key == "return") then
    if not GameState.isPaused then
      justPressed = true
    end
  end

  if key == "r" then
    initGame()
  end

  if key == "escape" then
    if GameState.is("levels") then
      GameState.attractMode = true
      currentLevelData = nil
      initGame()
      GameState.set("attract")
      Parallax.resume()
    elseif GameState.is("help") or GameState.is("about") then
      GameState.set(GameState.previous or "attract")
    elseif GameState.isPaused then
      GameState.isPaused = false
    elseif GameState.is("playing") then
      GameState.isPaused = true
    elseif GameState.is("attract") then
      if love.system.getOS() ~= "Web" then
        love.event.quit()
      end
    end
  end

  if key == "c" and playerCircle and GameState.is("playing") then
    Powerups.activatePlayerPing(
      playerCircle.position,
      PowerupsManager.isPhaseShiftActive,
      PowerupsManager.getPingColor()
    )
  end

  if key == "up" and GameState.is("help") then
    helpScrollY = math.max(0, helpScrollY - 20)
  elseif key == "down" and GameState.is("help") then
    helpScrollY = math.min(300, helpScrollY + 20)
  end

  if isDebugEnabled then
    overlayStats.handleKeyboard(key)
  end
end

function love.wheelmoved(x, y)
  if GameState.is("help") then
    Help.wheelmoved(x, y)
  end
end

function love.mousepressed(x, y, button)
  if GameState.ignoreInputTimer > 0 then
    return
  end

  if GameState.is("levels") then
    Levels.mousepressed(x, y, button)
    return
  end

  if GameState.is("about") then
    if button == 1 then
      -- If not clicked on the URL, return to previous screen
      if not About.mousepressed(x, y, button) then
        GameState.set(GameState.previous or "attract")
      end
    end
    return
  end

  if GameState.is("help") then
    if button == 1 then
      if GameState.previous == "attract" then
        GameState.attractMode = true
        GameState.set(GameState.previous)
      else
        local came_from_pause = GameState.isPaused
        GameState.set(GameState.previous)
        if came_from_pause then
          GameState.isPaused = true
        end
      end
      return
    end
  end

  if button == 1 and GameState.is("attract") then
    for i, item in ipairs(menuItems) do
      local itemWidth = Text.getTextWidth(item.text, 5)
      local itemX = (settings.WINDOW_WIDTH - itemWidth) / 2
      if x >= itemX and x <= itemX + itemWidth and y >= item.y and y <= item.y + item.height then
        selectedMenuItem = i
        Sound.play("blip")
        local action = item.action
        if action == "start_endless" then
          GameState.attractMode = false
          currentLevelData = nil
          love.math.setRandomSeed(os.time())
          initGame()
        elseif action == "start_arcade" then
          GameState.set("levels")
          clearGameObjects()
          -- Parallax.pause()
        elseif action == "show_about" then
          if GameState.is("playing") then
            GameState.isPaused = true
          end
          GameState.set("about")
        elseif action == "show_help" then
          GameState.previous = GameState.current
          if GameState.is("playing") then
            GameState.isPaused = true
          end
          GameState.set("help")
        elseif action == "exit_game" then
          love.event.quit()
        end
        return
      end
    end
    return
  elseif button == 1 and GameState.isPaused then
    for i, item in ipairs(pauseMenuItems) do
      local itemWidth = Text.getTextWidth(item.text, 5)
      local itemX = (settings.WINDOW_WIDTH - itemWidth) / 2
      if x >= itemX and x <= itemX + itemWidth and y >= item.y and y <= item.y + item.height then
        selectedPauseMenuItem = i
        Sound.play("blip")
        local action = pauseMenuItems[selectedPauseMenuItem].action
        if action == "resume" then
          GameState.isPaused = false
        elseif action == "restart" then
          GameState.isPaused = false
          initGame()
        elseif action == "show_help" then
          GameState.previous = GameState.current
          GameState.set("help")
        elseif action == "quit_to_menu" then
          GameState.isPaused = false
          GameState.attractMode = true
          currentLevelData = nil
          initGame()
        end
        return
      end
    end
    return
  end

  if button == 1 then
    if GameState.isNot("gameOver") and not GameState.isPaused then
      justPressed = true
    end
  end

  if button == 2 and playerCircle and GameState.is("playing") then
    Powerups.activatePlayerPing(
      playerCircle.position,
      PowerupsManager.isPhaseShiftActive,
      PowerupsManager.getPingColor()
    )
  end
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
  for i, level in ipairs(Levels.get_level_points()) do
    if currentLevelData and level.label == currentLevelData.id then
      current_level_index = i
      break
    end
  end
  if current_level_index and current_level_index < #Levels.get_level_points() then
    local next_level = Levels.get_level_points()[current_level_index + 1]
    PlayerProgress.unlock_level(next_level.label)
  end
  if current_level_index then
    GameState.allLevelsCompleted = (current_level_index == #Levels.get_level_points())
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
        currentLevelData
        and currentLevelData.winCondition.type == "blips"
        and blip_counter >= currentLevelData.winCondition.value - 1
      then
        color = currentLevelData.winCondition.finalBlipColor
      elseif ping.circle and ping.circle.isPassed then
        color = colors.rusty_cedar_transparent
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
    Levels.update(dt)
    return
  end

  if GameState.isPaused then
    return
  end

  GameState.update(dt)
  Music.update(dt)

  Parallax.update(dt, GameState.current)
  PowerupsManager.update(dt, GameState.current)
  Powerups.updatePings(dt)
  updatePings(dt)

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
      ---@diagnostic disable-next-line: param-type-mismatch
      (love.keyboard.isDown("space") or love.keyboard.isDown("return") or love.mouse.isDown(1))
      and (gameOverLine == nil or gameOverLine.timer <= 0)
      and GameState.gameOverInputDelay <= 0
    then
      restartGame()
    end
    if GameState.attractMode and (gameOverLine == nil or gameOverLine.timer <= 0) then
      initGame()
    end
    return
  end

  if GameState.is("levelCompleted") then
    if
      GameState.levelCompletedInputDelay <= 0
      and (love.keyboard.isDown("space") or love.keyboard.isDown("return") or love.mouse.isDown(1))
    then
      clearGameObjects()
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
    -- Simulate user input so the game runs automatically in attract mode.
    local clickChance = 0.01
    if playerCircle and playerCircle.position.y > (settings.INTERNAL_HEIGHT * 0.8) then
      clickChance = clickChance * 50 -- Multiply click probability by 50
    end
    if math.random() < clickChance then
      justPressed = true
    end
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
          currentLevelData
          and currentLevelData.winCondition.type == "blips"
          and blip_counter == currentLevelData.winCondition.value - 1
        then
          blipColor = currentLevelData.winCondition.finalBlipColor
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
          currentLevelData
          and currentLevelData.winCondition.type == "blips"
          and blip_counter >= currentLevelData.winCondition.value
        then
          winLevel()
        end
        didTeleport = true
      end
    end

    if not didTeleport and justPressed and playerCircle.next and GameState.ignoreInputTimer <= 0 then
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
          currentLevelData
          and currentLevelData.winCondition.type == "blips"
          and blip_counter == currentLevelData.winCondition.value - 1
        then
          blipColor = currentLevelData.winCondition.finalBlipColor
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
          currentLevelData
          and currentLevelData.winCondition.type == "blips"
          and blip_counter >= currentLevelData.winCondition.value
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
    activateJumpPing(playerCircle.next, colors.periwinkle_mist)
    lastNextCircle = playerCircle.next
  elseif not playerCircle or not playerCircle.next then
    lastNextCircle = nil
    jumpPings = {}
  end

  PowerupsManager.handlePlayerCollision(playerCircle)

  remove(particles, function(p)
    p.pos:add(p.vel)
    p.life = p.life - 0.4
    return p.life <= 0
  end)

  justPressed = false

  if isDebugEnabled then
    overlayStats.update(dt)
  end
end

local function drawSpawnRateIndicator()
  if GameState.is("gameOver") then
    return
  end
  local pulse = math.sin(love.timer.getTime() * 8) * 0.2 + 0.6 -- Pulses between 40% and 80% opacity
  local color = colors.neon_lime_splash

  love.graphics.setColor(color[1], color[2], color[3], pulse)

  love.graphics.rectangle("fill", 0, 0, settings.INTERNAL_WIDTH, 2.5)
end

function love.draw()
  love.graphics.setCanvas(gameCanvas)
  love.graphics.clear()

  love.graphics.push()
  love.graphics.scale(settings.SCALE_FACTOR, settings.SCALE_FACTOR)

  for _, p in ipairs(particles) do
    local alpha = math.max(0, p.life / 20)
    if PowerupsManager.isInvulnerable then
      love.graphics.setColor(colors.yellow[1], colors.yellow[2], colors.yellow[3], alpha)
    else
      love.graphics.setColor(p.color[1], p.color[2], p.color[3], alpha)
    end
    love.graphics.circle("fill", p.pos.x, p.pos.y, 0.5)
  end

  -- Draw circles and their rotating obstacles
  for _, circle in ipairs(circles) do
    if
      currentLevelData
      and currentLevelData.winCondition.type == "blips"
      and blip_counter == currentLevelData.winCondition.value - 1
      and circle == playerCircle.next
    then
      love.graphics.setColor(currentLevelData.winCondition.finalBlipColor)
    elseif
      PowerupsManager.isPhaseShiftActive and (circle == playerCircle or (playerCircle and circle == playerCircle.next))
    then
      love.graphics.setColor(colors.emerald_shade)
    elseif
      PowerupsManager.isInvulnerable and (circle == playerCircle or (playerCircle and circle == playerCircle.next))
    then
      love.graphics.setColor(colors.yellow)
    elseif circle == playerCircle or (playerCircle and circle == playerCircle.next) then
      if PowerupsManager.isSlowed then
        love.graphics.setColor(colors.light_blue_glow)
      else
        love.graphics.setColor(colors.periwinkle_mist)
      end
    elseif circle.isPassed then
      love.graphics.setColor(colors.rusty_cedar_transparent)
    else
      love.graphics.setColor(colors.rusty_cedar)
    end
    if not (PowerupsManager.isInvulnerable and circle == playerCircle) then
      love.graphics.circle("fill", circle.position.x, circle.position.y, 1.5)
    end

    -- Obstacles
    if PowerupsManager.isSlowed then
      love.graphics.setColor(colors.light_blue_glow)
    else
      love.graphics.setColor(colors.safety_orange)
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
      love.graphics.setColor(colors.yellow[1], colors.yellow[2], colors.yellow[3], alpha)
    elseif PowerupsManager.isPhaseShiftActive then
      love.graphics.setColor(colors.emerald_shade)
    elseif PowerupsManager.isSlowed then
      love.graphics.setColor(colors.light_blue_glow)
    else
      love.graphics.setColor(colors.periwinkle_mist)
    end
    love.graphics.rectangle("fill", playerCircle.position.x - 2.5, playerCircle.position.y - 2.5, 5, 5, 1.6, 1.6)
  end

  if PowerupsManager.isSpawnRateBoostActive then
    drawSpawnRateIndicator()
  end

  if gameOverLine then
    if PowerupsManager.isPhaseShiftActive then
      love.graphics.setColor(colors.emerald_shade)
    elseif PowerupsManager.isSlowed then
      love.graphics.setColor(colors.light_blue_glow)
    else
      love.graphics.setColor(colors.periwinkle_mist)
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
        currentLevelData
        and currentLevelData.winCondition.type == "blips"
        and blip_counter >= currentLevelData.winCondition.value
      then
        love.graphics.setColor(
          currentLevelData.winCondition.finalBlipColor[1],
          currentLevelData.winCondition.finalBlipColor[2],
          currentLevelData.winCondition.finalBlipColor[3],
          alpha
        )
      elseif PowerupsManager.isInvulnerable then
        love.graphics.setColor(colors.yellow[1], colors.yellow[2], colors.yellow[3], alpha)
      elseif PowerupsManager.isPhaseShiftActive then
        love.graphics.setColor(colors.emerald_shade[1], colors.emerald_shade[2], colors.emerald_shade[3], alpha)
      elseif PowerupsManager.isSlowed then
        love.graphics.setColor(colors.cyan_glow[1], colors.cyan_glow[2], colors.cyan_glow[3], alpha)
      else
        love.graphics.setColor(colors.periwinkle_mist[1], colors.periwinkle_mist[2], colors.periwinkle_mist[3], alpha)
      end
      love.graphics.rectangle("fill", currentPos.x - 2, currentPos.y - 2, 4, 4, 1.6, 1.6)
      currentPos:add(stepVector:copy():mul(3))
    end
  end

  Powerups.draw(GameState.current)

  if PowerupsManager.isBoltActive and GameState.isNot("gameOver") then
    Powerups.drawLightning()
  end

  love.graphics.pop()

  -- Draw user interface (UI).
  love.graphics.push()
  love.graphics.origin() -- Reset any previous scale transformations
  local displayHiScore = hiScore
  if currentLevelData then
    displayHiScore = currentLevelHighScore
  end

  if not GameState.attractMode and not GameState.is("levels") then
    Text.drawScore(score, displayHiScore, PowerupsManager.isScoreMultiplierActive)
  end

  if GameState.is("attract") then
    Text.drawAttract(menuItems, selectedMenuItem)
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
    Text.drawPauseMenu(pauseMenuItems, selectedPauseMenuItem)
  end

  love.graphics.pop()

  love.graphics.setCanvas()

  -- Draw canvas to screen applying shader effects
  effects(function()
    love.graphics.setColor(1, 1, 1, 1)
    Parallax.draw()

    love.graphics.draw(gameCanvas)

    love.graphics.push()
    love.graphics.scale(settings.SCALE_FACTOR, settings.SCALE_FACTOR)
    if GameState.isNot("gameOver") then
      Powerups.drawPings()
      drawNextJumpPingIndicator()
    end
    love.graphics.pop()
    if GameState.is("help") then
      Help.draw()
    elseif GameState.is("about") then
      About.draw()
    elseif GameState.is("levels") then
      Levels.draw()
    end
  end)

  if isDebugEnabled then
    overlayStats.draw()
  end
end

function Main.start_game_from_level(levelData)
  currentLevelData = levelData
  if currentLevelData.winCondition.type == "blips" then
    currentLevelData.winCondition.value = math.ceil(currentLevelData.winCondition.value * currentLevelData.difficulty)
  end
  Parallax.load(currentLevelData.backgroundColor, currentLevelData.starColors)
  currentLevelData:load()
  GameState.attractMode = false
  initGame()
  Parallax.resume()
end

function Main.set_game_state(state)
  GameState.set(state)
end
