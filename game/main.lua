--[[
FLASH-BLIP - A fast-paced 2D game built with the LÖVE framework. Dodge obstacles, survive as long as you can, and get the highest score.
--]]

Main = {}

local SimpleSplash = require("simple_splash")
local Moonshine = require("lib.shaders")
local Parallax = require("parallax")
local Vector = require("lib.vector")
local Powerups = require("powerups")
local Colors = require("colors")
local Text = require("text")
local Settings = require("settings")
local Sound = require("sound")
local About = require("about")
local Options = require("options")
local Help = require("help")
local LevelsSelector = require("levels_selector")
local PlayerProgress = require("player_progress")
local HiScores = require("hi_scores")
local PowerupsManager = require("powerups_manager")
local GameState = require("gamestate")
local Debuffs = require("debuffs")
local MathUtils = require("math_utils")
local GlowBenchmark = require("glow_benchmark")
local Game = require("game")
local Music = require("music")
local Input = require("input")
local DisplayConfig = require("display_config")
local HighscoreFlow = require("highscore_flow")
local HttpClient = require("http_client")
local UpdateChecker = require("update_checker")

local score
local hi_score = 0
local current_level_high_score = 0
Main.current_level_data = nil

local game_canvas
local splash_canvas
local effects
local splash
local is_splash_active

-- Variables to handle initialization on Android
local graphics_initialized = false
local orientation_stabilized = false
local orientation_check_frames = 0
local last_width, last_height = 0, 0

local function set_window_mode(width, height)
  love.window.setMode(width, height, {
    resizable = false,
    fullscreen = false,
    vsync = true,
    highdpi = true,
  })
end

local function is_correct_orientation()
  local width = love.graphics.getWidth()
  local height = love.graphics.getHeight()
  return height > width -- Portrait: height greater than width
end

-- Function to initialize canvas and effects
local function initialize_graphics()
  if graphics_initialized then
    -- Clear previous canvases
    if game_canvas then
      game_canvas:release()
      game_canvas = nil
    end
    if splash_canvas then
      splash_canvas:release()
      splash_canvas = nil
    end
    if effects then
      effects = nil
    end
  end

  -- Create canvas with the correct dimensions
  game_canvas = love.graphics.newCanvas(Settings.WINDOW_WIDTH, Settings.WINDOW_HEIGHT)
  splash_canvas = love.graphics.newCanvas(Settings.WINDOW_WIDTH, Settings.WINDOW_HEIGHT)

  effects = Moonshine(Moonshine.effects.glow)
    .chain(Moonshine.effects.fastgaussianblur)
    .chain(Moonshine.effects.scanlines)
    .chain(Moonshine.effects.crt)
    .resize(Settings.WINDOW_WIDTH, Settings.WINDOW_HEIGHT)

  effects.glow.min_luma = 0.1
  effects.fastgaussianblur.sigma = 1
  effects.scanlines.width = 4
  effects.scanlines.opacity = 0.2
  effects.scanlines.color = Colors.light_blue

  Main.apply_glow_setting()
  Main.apply_blur_setting()

  graphics_initialized = true
end

function Main.apply_glow_setting()
  if not effects or not effects.glow then
    return
  end

  if Settings.IS_GLOW_ENABLED then
    effects.glow.strength = 20
  else
    effects.glow.strength = 1
  end
end

function Main.apply_blur_setting()
  if not effects then
    return
  end

  if Settings.IS_BLUR_ENABLED then
    effects.enable("fastgaussianblur")
  else
    effects.disable("fastgaussianblur")
  end
end

local function init_game()
  score = 0
  GameState.set(GameState.is_attract_mode and "attract" or "playing")
  HighscoreFlow.reset()

  if Main.current_level_data then
    current_level_high_score = PlayerProgress.get_level_high_score(Main.current_level_data.id)
    Main.current_level_data:load()
  else
    current_level_high_score = 0
  end

  local init_difficulty = Main.current_level_data and Main.current_level_data.difficulty or 1
  Game.init(GameState.is_attract_mode, init_difficulty)

  Input:reset_just_pressed()
  GameState.is_new_hi_score = false

  if not GameState.is_attract_mode then
    GameState.ignore_input_timer = 1
  else
    GameState.ignore_input_timer = 0
  end
end

Main.init_game = init_game

local function setup_dimensions()
  -- Calculate optimal resolution for current screen
  local desktop_width, desktop_height = love.window.getDesktopDimensions()

  if Settings.IS_MOBILE then
    local saved_config = DisplayConfig.load()

    if saved_config then
      Settings.DPI_SCALE = saved_config.dpi_scale
      Settings.INTERNAL_HEIGHT = saved_config.internal_height
      Settings.SCALE_FACTOR = saved_config.scale_factor
      Settings.WINDOW_WIDTH = saved_config.pixel_width
      Settings.WINDOW_HEIGHT = saved_config.pixel_height
      return true
    else
      -- Calculate dimensions for the first time
      local pixel_width = love.graphics.getWidth()
      local pixel_height = love.graphics.getHeight()

      -- Ensure we have portrait orientation (height > width)
      if pixel_width > pixel_height then
        pixel_width, pixel_height = pixel_height, pixel_width
      end

      -- Calculate DPI scale factor and aspect ratio to adjust internal height
      Settings.DPI_SCALE = pixel_width / math.min(desktop_width, desktop_height)
      local aspect_ratio = pixel_height / pixel_width
      Settings.INTERNAL_HEIGHT = math.floor(Settings.INTERNAL_WIDTH * aspect_ratio)
      -- Calculate scale to fit the width perfectly
      Settings.SCALE_FACTOR = pixel_width / Settings.INTERNAL_WIDTH
      Settings.WINDOW_WIDTH = pixel_width
      Settings.WINDOW_HEIGHT = pixel_height

      DisplayConfig.save({
        pixel_width = pixel_width,
        pixel_height = pixel_height,
        desktop_width = desktop_width,
        desktop_height = desktop_height,
        dpi_scale = Settings.DPI_SCALE,
        internal_height = Settings.INTERNAL_HEIGHT,
        scale_factor = Settings.SCALE_FACTOR,
      })
      return true
    end
  else
    -- Desktop
    local scale_x = math.floor(desktop_width / Settings.INTERNAL_WIDTH)
    local scale_y = math.floor(desktop_height / Settings.INTERNAL_HEIGHT)
    Settings.SCALE_FACTOR = math.min(scale_x, scale_y)
    Settings.WINDOW_WIDTH = Settings.INTERNAL_WIDTH * Settings.SCALE_FACTOR
    Settings.WINDOW_HEIGHT = Settings.INTERNAL_HEIGHT * Settings.SCALE_FACTOR
    return true
  end
end

function love.load()
  love.window.setTitle("FLASH-BLIP")

  Settings.load()

  GlowBenchmark.init()
  GlowBenchmark.set_on_glow_disabled(Main.apply_glow_setting)

  local desktop_width, desktop_height = love.window.getDesktopDimensions()

  if Settings.IS_MOBILE then
    -- For mobiles, set portrait mode explicitly
    local portrait_width = math.min(desktop_width, desktop_height)
    local portrait_height = math.max(desktop_width, desktop_height)
    set_window_mode(portrait_width, portrait_height)

    -- DO NOT initialize graphics yet on mobiles, will wait for the orientation to stabilize
    orientation_stabilized = false
    is_splash_active = false
    last_width = love.graphics.getWidth()
    last_height = love.graphics.getHeight()
  else
    -- Desktop
    setup_dimensions()
    set_window_mode(Settings.WINDOW_WIDTH, Settings.WINDOW_HEIGHT)

    splash = SimpleSplash.new(Settings.WINDOW_WIDTH, Settings.WINDOW_HEIGHT)
    is_splash_active = true
    splash.on_done = function()
      is_splash_active = false
      init_game()
    end

    initialize_graphics()

    if GlowBenchmark.is_benchmark_needed() then
      GlowBenchmark.start()
    end
  end

  Sound:load()
  Music.play()

  Sound.toggle_mute(not Settings.IS_SFX_ENABLED)
  Music.toggle_mute(not Settings.IS_MUSIC_ENABLED)
  Music.set_volume(Settings.IS_MUSIC_VOLUME)
  Sound.set_volume(Settings.IS_SFX_VOLUME)

  Parallax.load(nil, nil)
  About.load()
  Options.load()
  Help.load()
  LevelsSelector.load()
  PlayerProgress.load()
  hi_score = PlayerProgress.get_endless_high_score()

  UpdateChecker.start()

  if Settings.IS_DEBUG_ENABLED then
    OverlayStats = require("lib.overlayStats")
    OverlayStats.load()
  end
end

local function end_game()
  if GameState.is("gameOver") then
    return
  end

  if Main.current_level_data then -- is Arcade mode
    if score > current_level_high_score then
      PlayerProgress.set_level_high_score(Main.current_level_data.id, score)
      current_level_high_score = score
      GameState.is_new_hi_score = true
      GameState.hi_score_flash_visible = true
    end
  elseif not GameState.is_attract_mode then -- is Endless mode
    if score > hi_score then
      hi_score = score
      PlayerProgress.set_endless_high_score(score)
      GameState.is_new_hi_score = true
      GameState.hi_score_flash_visible = true
    end
  end

  PowerupsManager.clear_active_powerups()
  Debuffs.clear_active_debuffs()

  HighscoreFlow.prepare(score, Main.current_level_data)

  GameState.set("gameOver")
  GameState.game_over_input_delay = 3.0
end

local function update_particles(dt)
  local write_index = 1
  for read_index = 1, #Game.particles do
    local p = Game.particles[read_index]
    p.pos:add(p.vel)
    p.life = p.life - 0.4

    if p.life > 0 then
      Game.particles[write_index] = p
      write_index = write_index + 1
    end
  end

  for i = write_index, #Game.particles do
    Game.particles[i] = nil
  end
end

local function add_score(value)
  if not GameState.is_attract_mode then
    local multiplier = PowerupsManager.is_score_multiplier_active and 4 or 1
    score = score + (value * multiplier)
  end
end

local function particle(position, count, speed, angle, angle_width, color)
  count = count or 1
  for _ = 1, count do
    local particle_angle = angle + MathUtils.rnds(angle_width or 0)
    table.insert(Game.particles, {
      pos = position:copy(),
      vel = Vector:new(math.cos(particle_angle) * speed, math.sin(particle_angle) * speed),
      life = MathUtils.rnd(10, 20),
      color = color or Colors.periwinkle_mist,
    })
  end
end
_G.particle = particle

local function restart_game()
  if GameState.is("gameOver") and (Game.game_over_line == nil or Game.game_over_line.timer <= 0) then
    init_game()
    GameState.restart_delay_counter = 10
  end
end

Main.restart_game = restart_game

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

function love.mousereleased(x, y, button)
  Input:mousereleased(x, y, button)
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

local function update_pings(dt)
  if GameState.is_not("playing") then
    return
  end
  for i = #Game.jump_pings, 1, -1 do
    local ping = Game.jump_pings[i]
    local current_max_radius = PowerupsManager.get_current_max_radius()
    ping.speed = PowerupsManager.is_phase_shift_active and 15 or 10

    ping.radius = ping.radius + ping.speed * dt
    if ping.radius >= current_max_radius then
      ping.radius = 0 -- Reset radius for cyclic effect
    end
  end
end

local function win_level()
  current_level_high_score, hi_score =
    Game.win_level(Main.current_level_data, score, current_level_high_score, hi_score)

  HighscoreFlow.prepare(score, Main.current_level_data)

  GameState.set("levelCompleted")
  GameState.level_completed_input_delay = 1.0
end

local function handle_successful_blip(blip_type)
  Game.handle_successful_blip(blip_type, Main.current_level_data)
end

function love.update(dt)
  dt = math.min(dt, 1 / 30)

  Settings.update(dt)
  GlowBenchmark.update(dt)

  HttpClient.update()
  Music.update(dt)

  HighscoreFlow.update(dt)

  if Settings.IS_MOBILE and not orientation_stabilized then
    local current_width = love.graphics.getWidth()
    local current_height = love.graphics.getHeight()

    -- Check if dimensions have changed
    if current_width ~= last_width or current_height ~= last_height then
      last_width = current_width
      last_height = current_height
      orientation_check_frames = 0
    else
      orientation_check_frames = orientation_check_frames + 1
    end

    if orientation_check_frames >= 5 and is_correct_orientation() then
      orientation_stabilized = true

      setup_dimensions()

      Parallax.load(nil, nil)

      initialize_graphics()

      if GlowBenchmark.is_benchmark_needed() then
        GlowBenchmark.start()
      end

      LevelsSelector.load()

      splash = SimpleSplash.new(Settings.WINDOW_WIDTH, Settings.WINDOW_HEIGHT)
      is_splash_active = true
      splash.on_done = function()
        is_splash_active = false
        init_game()
      end
    end

    return -- Do not process anything else until stabilized
  end

  if is_splash_active then
    splash:update(dt)
    if Music.is_ready() then
      splash:set_done()
    end
    return
  end

  if GameState.is("virtual_keyboard") then
    local VirtualKeyboard = require("virtual_keyboard")
    VirtualKeyboard.update(dt)
    return
  end

  if GameState.is_paused then
    return
  end

  if GameState.is("levels") then
    LevelsSelector.update(dt)
    return
  end

  if GameState.is("hi_scores") then
    HiScores.update(dt)
  end

  GameState.update(dt)

  Parallax.update(dt, GameState.current)
  PowerupsManager.update(dt, GameState.current)
  Debuffs.update(dt, GameState.current)
  Powerups.update_pings(dt)
  update_pings(dt)
  Input:update(dt)

  Game.update_effects(win_level)

  if GameState.is("gameOver") then
    if
      Input:is_game_over_continue()
      and (Game.game_over_line == nil or Game.game_over_line.timer <= 0)
      and GameState.game_over_input_delay <= 0
      and not HighscoreFlow.is_waiting()
    then
      HighscoreFlow.request_proceed("gameOver", function()
        init_game()
        GameState.restart_delay_counter = 10
      end)
    end
    if GameState.is_attract_mode and (Game.game_over_line == nil or Game.game_over_line.timer <= 0) then
      init_game()
    end
    return
  end

  if GameState.is("levelCompleted") then
    if
      GameState.level_completed_input_delay <= 0
      and Input:is_level_completed_continue()
      and not HighscoreFlow.is_waiting()
    then
      HighscoreFlow.request_proceed("levelCompleted", function()
        Game.clear_game_objects()
        GameState.set("levels")
      end)
    end
    return
  end

  if GameState.is("help") then
    return
  end

  if GameState.restart_delay_counter > 0 then
    return
  end

  if GameState.is_attract_mode then
    Input:simulate_attract_input(Game.player_circle)
  end

  local obstacles = Game.update(dt, PowerupsManager, end_game, add_score)
  Game.player_circle = Game.get_player_circle()
  Game.circles = Game.get_circles()

  if Game.player_circle then
    local did_teleport = false
    if PowerupsManager.is_phase_shift_active and Game.player_circle.next and GameState.ignore_input_timer <= 0 then
      if Powerups.is_ping_connected(Game.jump_pings) then
        handle_successful_blip("phase_shift")
        did_teleport = true
      end
    end

    if
      PowerupsManager.is_bolt_active
      and not did_teleport
      and Game.player_circle.next
      and GameState.ignore_input_timer <= 0
    then
      if Powerups.check_lightning_collision(Game.player_circle) then
        handle_successful_blip("bolt")
        did_teleport = true
      end
    end

    if
      not did_teleport
      and Input.is_just_pressed()
      and Game.player_circle.next
      and GameState.ignore_input_timer <= 0
    then
      local was_invulnerable = PowerupsManager.is_invulnerable
      local blip_collected_powerup, collected_star = PowerupsManager.handle_blip_collision(Game.player_circle)
      Debuffs.check_blip_collision(Game.player_circle, Game.player_circle.next)
      local collision = false
      if not PowerupsManager.is_invulnerable then
        for _, obstacle in ipairs(obstacles or {}) do
          if
            MathUtils.is_line_rotated_rect_collision(
              Game.player_circle.position,
              Game.player_circle.next.position,
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
        if not GameState.is_attract_mode then
          Sound.play("explosion")
          end_game()
          Game.game_over_line = {
            p1 = Game.player_circle.position:copy(),
            p2 = Game.player_circle.next.position:copy(),
            timer = 60,
            width = 3,
          }
        end
      else
        handle_successful_blip("manual")
        -- If a power-up was collected on the blip, invulnerability is deactivated upon arriving at the destination only if it wasn't active previously.
        if blip_collected_powerup and not collected_star and not was_invulnerable then
          PowerupsManager.is_invulnerable = false
        end
      end
    end
  end

  Game.update_jump_pings(Colors.periwinkle_mist)

  PowerupsManager.handle_player_collision(Game.player_circle)
  Debuffs.check_collisions(Game.player_circle)

  update_particles(dt)

  Input:reset_just_pressed()

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
          #Game.particles,
          #Game.circles,
          Game.blip_counter.value,
          love.timer.getTime()
        )
      )
    end
  end
end

function love.draw()
  if Settings.IS_MOBILE and not orientation_stabilized then
    love.graphics.clear(Colors.murky_blue)
    love.graphics.setColor(1, 1, 1, 1)
    return
  end

  if is_splash_active then
    love.graphics.setCanvas(splash_canvas)
    love.graphics.clear()
    splash:draw()
    love.graphics.setCanvas()

    effects(function()
      love.graphics.setColor(1, 1, 1, 1)
      love.graphics.draw(splash_canvas, 0, 0)
    end)
    return
  end

  love.graphics.setCanvas(game_canvas)
  love.graphics.clear()
  Parallax.draw()

  love.graphics.push()
  love.graphics.scale(Settings.SCALE_FACTOR, Settings.SCALE_FACTOR)

  for _, p in ipairs(Game.particles) do
    local alpha = math.max(0, p.life / 20)
    if PowerupsManager.is_invulnerable then
      love.graphics.setColor(Colors.yellow[1], Colors.yellow[2], Colors.yellow[3], alpha)
    else
      love.graphics.setColor(p.color[1], p.color[2], p.color[3], alpha)
    end
    love.graphics.circle("fill", p.pos.x, p.pos.y, 0.5)
  end

  -- Draw circles and their rotating obstacles
  for _, circle in ipairs(Game.circles) do
    local is_final_blip = Main.current_level_data
      and Main.current_level_data.win_condition.type == "blips"
      and Game.blip_counter.value == Main.current_level_data.win_condition.value - 1
      and circle == Game.player_circle.next

    if is_final_blip then
      love.graphics.setColor(Main.current_level_data.win_condition.final_blip_color)
    elseif
      PowerupsManager.is_phase_shift_active
      and (circle == Game.player_circle or (Game.player_circle and circle == Game.player_circle.next))
    then
      love.graphics.setColor(Colors.emerald_shade)
    elseif
      PowerupsManager.is_invulnerable
      and (circle == Game.player_circle or (Game.player_circle and circle == Game.player_circle.next))
    then
      love.graphics.setColor(Colors.yellow)
    elseif circle == Game.player_circle or (Game.player_circle and circle == Game.player_circle.next) then
      if PowerupsManager.is_slowed then
        love.graphics.setColor(Colors.light_blue_glow)
      else
        love.graphics.setColor(Colors.periwinkle_mist)
      end
    elseif circle.is_passed then
      love.graphics.setColor(Colors.rusty_cedar_transparent)
    else
      love.graphics.setColor(Colors.rusty_cedar)
    end
    local is_glitching = Debuffs.glitch_timer and Debuffs.glitch_timer > 0
    if not ((PowerupsManager.is_invulnerable or is_glitching) and circle == Game.player_circle) then
      if is_final_blip then
        -- Draw hexagonal shape for final blip
        local x, y = circle.position.x, circle.position.y
        local size = 3.5
        love.graphics.polygon(
          "fill",
          x,
          y - size,
          x + size * 0.866,
          y - size * 0.5,
          x + size * 0.866,
          y + size * 0.5,
          x,
          y + size,
          x - size * 0.866,
          y + size * 0.5,
          x - size * 0.866,
          y - size * 0.5
        )
      else
        love.graphics.circle("fill", circle.position.x, circle.position.y, 1.5)
      end
    end

    -- Obstacles
    if PowerupsManager.is_slowed then
      love.graphics.setColor(Colors.light_blue_glow)
    else
      love.graphics.setColor(Colors.safety_orange)
    end
    for i = 1, circle.obstacle_count do
      local obstacle_angle = circle.angle + (i * math.pi * 2) / circle.obstacle_count
      local rect_center = Vector:new(circle.position.x, circle.position.y):addWithAngle(obstacle_angle, circle.radius)

      love.graphics.push()
      love.graphics.translate(rect_center.x, rect_center.y)
      love.graphics.rotate(obstacle_angle + math.pi / 2) -- The obstacles are perpendicular to radius.
      love.graphics.rectangle("fill", -circle.obstacle_length / 2, -1.5, circle.obstacle_length, 3, 1.2, 1.2)
      love.graphics.pop()
    end
  end

  -- Draw the player (larger square circle).
  if Game.player_circle then
    local px = Game.player_circle.position.x - 2.5
    local py = Game.player_circle.position.y - 2.5
    local pw = 5
    local ph = 5

    if Debuffs.is_emp_active then
      love.graphics.setColor(Colors.crimson)
      if Debuffs.glitch_timer and Debuffs.glitch_timer > 0 then
        px = px + love.math.random(-3, 3)
        py = py + love.math.random(-1, 1)
        pw = pw + love.math.random(-2, 3)
        ph = ph + love.math.random(-2, 2)

        -- Draw a thin horizontal glitch slice
        if love.math.random() > 0.4 then
          love.graphics.setColor(Colors.crimson[1], Colors.crimson[2], Colors.crimson[3], 0.6)
          love.graphics.rectangle(
            "fill",
            Game.player_circle.position.x - 5 + love.math.random(-6, 6),
            Game.player_circle.position.y - 1.5 + love.math.random(-3, 3),
            10,
            1,
            0,
            0
          )
          love.graphics.setColor(Colors.crimson)
        end
      end
    elseif PowerupsManager.is_invulnerable then
      local alpha_pulse = 0.8
      if not GameState.is_paused then
        -- Invulnerability visual effect (blinking) pulses from 0.2 to 1.0 (20% to 100% opacity)
        alpha_pulse = 0.6 + math.sin(love.timer.getTime() * 20) * 0.4
      end
      love.graphics.setColor(Colors.yellow[1], Colors.yellow[2], Colors.yellow[3], alpha_pulse)
    elseif PowerupsManager.is_phase_shift_active then
      love.graphics.setColor(Colors.emerald_shade)
    elseif PowerupsManager.is_slowed then
      love.graphics.setColor(Colors.light_blue_glow)
    else
      love.graphics.setColor(Colors.periwinkle_mist)
    end
    love.graphics.rectangle("fill", px, py, pw, ph, 1.6, 1.6)
    Game.draw_blip_chevrons()
  end

  if PowerupsManager.is_spawn_rate_boost_active then
    PowerupsManager.draw_spawn_rate_indicator()
  end

  Game.draw_game_over_line()
  Game.draw_flash_line(Main.current_level_data)

  Powerups.draw(GameState.current)
  Debuffs.draw(GameState.current)

  if PowerupsManager.is_bolt_active and GameState.is_not("gameOver") and GameState.is_not("levelCompleted") then
    Powerups.draw_lightning()
  end

  if GameState.is_not("gameOver") then
    Powerups.draw_pings()
    PowerupsManager.draw_next_jump_ping_indicator(Game.jump_pings, Game.blip_counter, Main.current_level_data)
  end

  love.graphics.pop()

  -- Draw user interface (UI).
  love.graphics.push()
  love.graphics.origin() -- Reset any previous scale transformations
  local display_hi_score = hi_score
  if Main.current_level_data then
    display_hi_score = current_level_high_score
  end

  if not GameState.is_attract_mode and not GameState.is("levels") then
    Text.draw_score(score, display_hi_score, PowerupsManager.is_score_multiplier_active)

    if Main.current_level_data and Main.current_level_data.win_condition.type == "blips" then
      Text.draw_level_progress(
        Game.blip_counter.value,
        Main.current_level_data.win_condition.value,
        Main.current_level_data.win_condition.final_blip_color
      )
    end
  end

  if GameState.is("attract") then
    Text.draw_attract(Input.get_menu_items(), Input.get_selected_menu_item())
    UpdateChecker.draw()
  end

  if GameState.is("gameOver") and not GameState.is_attract_mode then
    if not Game.game_over_line or Game.game_over_line.timer <= 0 then
      Text.draw_game_over(display_hi_score, GameState.is_new_hi_score, GameState.hi_score_flash_visible)
    end
  end

  if GameState.is("levelCompleted") then
    if GameState.all_levels_completed then
      Text.draw_all_levels_completed(display_hi_score, GameState.is_new_hi_score, GameState.hi_score_flash_visible)
    else
      Text.draw_level_completed(display_hi_score, GameState.is_new_hi_score, GameState.hi_score_flash_visible)
    end
  end

  if GameState.is_paused then
    local level_id = Main.current_level_data and Main.current_level_data.id or nil
    Text.draw_pause_menu(Input.get_pause_menu_items(), Input.get_selected_pause_menu_item(), level_id)
  end

  love.graphics.pop()
  love.graphics.setCanvas()

  local function draw_game_and_ui()
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.draw(game_canvas, 0, 0)
    if GameState.is("help") then
      Help.draw()
    elseif GameState.is("about") then
      About.draw()
    elseif GameState.is("options") then
      Options.draw()
    elseif GameState.is("hi_scores") then
      HiScores.draw()
    elseif GameState.is("levels") then
      LevelsSelector.draw()
    elseif GameState.is("virtual_keyboard") then
      local VirtualKeyboard = require("virtual_keyboard")
      VirtualKeyboard.draw()
    end
  end

  -- Draw canvas to screen applying shader effects
  effects(draw_game_and_ui)

  GlowBenchmark.draw()

  if Settings.IS_DEBUG_ENABLED then
    OverlayStats.draw()
  end
end
