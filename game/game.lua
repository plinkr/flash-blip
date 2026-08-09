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
local InputRecorder = require("input_recorder")

Game.jump_pings = {}
Game.jumpPings = Game.jump_pings
Game.circles = {}
Game.player_circle = nil
Game.playerCircle = nil
Game.particles = {}
Game.blip_counter = { value = 0 }
Game.flash_line = nil
Game.flashLine = nil
Game.game_over_line = nil
Game.gameOverLine = nil
Game.last_next_circle = nil
Game.pending_win_level = false
Game.pending_win_level_delay = 0
Game.time = 0

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
local PERP_WAVE_INTENSITY = 0.3 -- 0 off to 1.0 normal

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

  Game.circles = circles
  Game.particles = particles
  Game.player_circle = nil
  Game.playerCircle = nil
  Game.jump_pings = {}
  Game.jumpPings = Game.jump_pings
  Game.blip_counter = { value = 0 }
  Game.flash_line = nil
  Game.flashLine = nil
  Game.game_over_line = nil
  Game.gameOverLine = nil
  Game.last_next_circle = nil
  Game.pending_win_level = false
  Game.pending_win_level_delay = 0
  Game.time = 0

  PowerupsManager.init(Game.circles, isAttractMode)
  Debuffs.init()
  if Powerups then
    Powerups.reset()
  end

  if not isAttractMode then
    local seed = (Main and Main.currentLevelData) and Main.currentLevelData.seed or nil
    InputRecorder.start(seed)
  else
    InputRecorder.stop()
  end
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
  Game.player_circle = circle
  Game.playerCircle = circle
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
  Game.time = (Game.time or 0) + dt
  ticks = ticks + 1
  InputRecorder.tick()
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

local function get_blip_color(current_level_data, blip_counter)
  if
    current_level_data
    and current_level_data.winCondition.type == "blips"
    and blip_counter.value == current_level_data.winCondition.value - 1
  then
    return current_level_data.winCondition.finalBlipColor
  else
    return PowerupsManager.getPingColor()
  end
end

function Game.handle_successful_blip(blip_type, level_data_or_params)
  blip_type = blip_type or "manual" -- "manual", "phase_shift", "bolt"
  local current_level_data
  if type(level_data_or_params) == "table" and level_data_or_params.currentLevelData ~= nil then
    current_level_data = level_data_or_params.currentLevelData
  else
    current_level_data = level_data_or_params
  end

  if not isAttractMode then
    InputRecorder.record(InputRecorder.INPUT.BLIP)
  end

  local player_circle = Game.get_player_circle()
  if not player_circle or not player_circle.next then
    return
  end

  local blip_color = get_blip_color(current_level_data, Game.blip_counter)

  if blip_type == "phase_shift" or blip_type == "bolt" then
    if not GameState.isAttractMode then
      Sound.play("teleport")
    end
    particle(player_circle.position, 20, 3, 0, math.pi * 2, blip_color)
    particle(player_circle.next.position, 20, 3, 0, math.pi * 2, blip_color)
  else -- "manual"
    if not GameState.isAttractMode then
      Sound.play("blip")
    end
    local current_pos = player_circle.position:copy()
    -- Divide the distance between player and next point into 10 equal pieces
    local step_vector = (Vector:new(player_circle.next.position.x, player_circle.next.position.y)
      :sub(player_circle.position)):div(10)
    local particle_angle = step_vector:angle()
    for _ = 1, 10 do
      particle(current_pos, 4, 2, particle_angle + math.pi, 0.5, blip_color)
      current_pos:add(step_vector)
    end
  end

  if blip_type ~= "bolt" then
    Game.flash_line = {
      p1 = player_circle.position:copy(),
      p2 = player_circle.next.position:copy(),
      timer = 2,
    }
    Game.flashLine = Game.flash_line
  end

  player_circle.isPassed = true
  Game.set_player_circle(player_circle.next)
  Game.blip_counter.value = Game.blip_counter.value + 1

  if
    current_level_data
    and current_level_data.winCondition.type == "blips"
    and Game.blip_counter.value >= current_level_data.winCondition.value
  then
    if blip_type == "bolt" then
      Game.pending_win_level_delay = 2
    else
      Game.pending_win_level = true
    end
  end
end
Game.handleSuccessfulBlip = Game.handle_successful_blip

function Game.update_effects(win_level_fn)
  if Game.flash_line then
    if Game.flash_line.timer > 0 then
      Game.flash_line.timer = Game.flash_line.timer - 1
    else
      Game.flash_line = nil
      Game.flashLine = nil
      if Game.pending_win_level then
        Game.pending_win_level = false
        if win_level_fn then
          win_level_fn()
        end
      end
    end
  end

  if Game.pending_win_level_delay > 0 then
    Game.pending_win_level_delay = Game.pending_win_level_delay - 1
    if Game.pending_win_level_delay <= 0 and win_level_fn then
      win_level_fn()
    end
  end

  if Game.game_over_line and Game.game_over_line.timer > 0 then
    Game.game_over_line.timer = Game.game_over_line.timer - 1
  end
end

function Game.update_jump_pings(color)
  local player_circle = Game.get_player_circle()
  if player_circle and player_circle.next and player_circle.next ~= Game.last_next_circle then
    Game.jump_pings = {
      {
        circle = player_circle.next,
        radius = 0,
        maxRadius = 12,
        speed = 10,
        life = 1,
        color = color or Colors.periwinkle_mist,
      },
    }
    Game.jumpPings = Game.jump_pings
    Game.last_next_circle = player_circle.next
  elseif not player_circle or not player_circle.next then
    Game.last_next_circle = nil
    Game.jump_pings = {}
    Game.jumpPings = Game.jump_pings
  end
end

function Game.draw_game_over_line()
  if not Game.game_over_line then
    return
  end

  if PowerupsManager.isPhaseShiftActive then
    love.graphics.setColor(Colors.emerald_shade)
  elseif PowerupsManager.isSlowed then
    love.graphics.setColor(Colors.light_blue_glow)
  else
    love.graphics.setColor(Colors.periwinkle_mist)
  end

  local line = Game.game_over_line
  local angle = Vector:new(line.p2.x, line.p2.y):sub(Vector:new(line.p1.x, line.p1.y)):angle()
  local length = line.p1:distance(line.p2) + 2
  local width = line.width or 2

  love.graphics.push()
  love.graphics.translate(line.p1.x, line.p1.y)
  love.graphics.rotate(angle)
  love.graphics.rectangle("fill", 0, -width / 2, length, width, width / 2, width / 2)
  love.graphics.pop()
end

function Game.draw_flash_line(current_level_data)
  if not Game.flash_line then
    return
  end

  local line = Game.flash_line
  local dist = line.p1:distance(line.p2)
  local step_vector = Vector:new(line.p2.x, line.p2.y):sub(line.p1):normalize()
  local current_pos = line.p1:copy()

  for i = 0, dist, 3 do
    local alpha = i / dist
    if Debuffs.is_emp_active then
      love.graphics.setColor(Colors.crimson[1], Colors.crimson[2], Colors.crimson[3], alpha)
    elseif
      current_level_data
      and current_level_data.winCondition.type == "blips"
      and Game.blip_counter.value >= current_level_data.winCondition.value
    then
      love.graphics.setColor(
        current_level_data.winCondition.finalBlipColor[1],
        current_level_data.winCondition.finalBlipColor[2],
        current_level_data.winCondition.finalBlipColor[3],
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
    love.graphics.rectangle("fill", current_pos.x - 2, current_pos.y - 2, 4, 4, 1.6, 1.6)
    current_pos:add(step_vector:copy():mul(3))
  end
end

function Game.winLevel(currentLevelData, score, currentLevelHighScore, hiScore)
  GameState.set("levelCompleted")
  GameState.levelCompletedInputDelay = 1.5
  PowerupsManager.clearActivePowerups()
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

function Game.get_player_color()
  if Debuffs.is_emp_active then
    local c = Colors.crimson
    return c[1], c[2], c[3], c[4] or 1.0
  elseif PowerupsManager.isInvulnerable then
    local alpha_pulse = 0.8
    if not GameState.isPaused then
      alpha_pulse = 0.6 + math.sin((Game.time or 0) * 20) * 0.4
    end
    local c = Colors.yellow
    return c[1], c[2], c[3], alpha_pulse
  elseif PowerupsManager.isPhaseShiftActive then
    local c = Colors.emerald_shade
    return c[1], c[2], c[3], c[4] or 1.0
  elseif PowerupsManager.isSlowed then
    local c = Colors.light_blue_glow
    return c[1], c[2], c[3], c[4] or 1.0
  else
    local c = Colors.periwinkle_mist
    return c[1], c[2], c[3], c[4] or 1.0
  end
end

function Game.draw_blip_chevrons()
  local player_circle = Game.get_player_circle()
  if not player_circle or not player_circle.next then
    return
  end

  if GameState.is("gameOver") or GameState.is("levelCompleted") then
    return
  end

  local p1 = player_circle.position
  local p2 = player_circle.next.position

  local dist = MathUtils.distance(p1, p2)
  if dist < 0.001 then
    return
  end

  local dir = p2:sub(p1)
  local dx, dy = dir.x, dir.y
  local angle = dir:angle()
  local r, g, b = Game.get_player_color()

  local num_chevrons = 5
  local start_offset = 6.5
  local max_span = math.min(dist * 0.45, 24)
  local spacing = math.max(3.2, (max_span - start_offset) / (num_chevrons - 1))

  local time = Game.time or 0

  -- last 1.5 seconds to warn the player
  local is_warning = PowerupsManager.isInvulnerable and PowerupsManager.invulnerabilityTimer <= 1.5

  local is_glitching = not GameState.isPaused
    and Debuffs.is_emp_active
    and Debuffs.glitch_timer
    and Debuffs.glitch_timer > 0

  for i = 1, num_chevrons do
    local t_grad = (i - 1) / (num_chevrons - 1)
    local grad_scale = 1.0 - t_grad * 0.62

    local perp_wave = math.sin(time * 7.0 - i * 0.85) * 1.1 * PERP_WAVE_INTENSITY
    local scale_wave = 1.0 + 0.16 * math.sin(time * 8.0 - i * 0.9)
    local opacity_wave = 0.55 + 0.45 * math.sin(time * 9.0 - i * 0.85)
    local chevron_alpha = math.max(0.15, math.min(1.0, 1 * opacity_wave))

    if is_warning then -- visual feedback so the player knows the invuln powerup is ending
      local warn_t = 0.5 + 0.5 * math.sin(time * 26 - i * 1.1)
      local c = Colors.lerp(Colors.yellow, Colors.periwinkle_mist, 1 - warn_t)
      r, g, b = c[1], c[2], c[3]
      perp_wave = perp_wave * 1.8
      scale_wave = 1.0 + 0.35 * math.sin(time * 20 - i * 1.1)
      chevron_alpha = math.max(0.6, chevron_alpha)
    end

    local base_w = 3.6
    local base_h = 4.2
    local w = base_w * grad_scale * scale_wave
    local h = base_h * grad_scale * scale_wave

    local d_i = start_offset + (i - 1) * spacing
    local cx = p1.x + (dx / dist) * d_i
    local cy = p1.y + (dy / dist) * d_i

    cx = cx + (-dy / dist) * perp_wave
    cy = cy + (dx / dist) * perp_wave

    if is_glitching and love.math.random() > 0.3 then
      cx = cx + love.math.random(-1.5, 1.5)
      cy = cy + love.math.random(-1.0, 1.0)
    end

    love.graphics.push()
    love.graphics.translate(cx, cy)
    love.graphics.rotate(angle)

    love.graphics.setColor(r, g, b, chevron_alpha)
    love.graphics.polygon("fill", w * 0.55, 0, -w * 0.45, -h * 0.5, -w * 0.15, 0, -w * 0.45, h * 0.5)
    love.graphics.pop()
  end
end

function Game.clear_game_objects()
  Game.init(GameState.isAttractMode)
end
Game.clearGameObjects = Game.clear_game_objects
Game.clear = Game.clear_game_objects

return Game
