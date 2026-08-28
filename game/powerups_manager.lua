local PowerupsManager = {}

local Powerups = require("powerups")
local Sound = require("sound")
local MathUtils = require("math_utils")
local Colors = require("colors")
local GameState = require("gamestate")
local Settings = require("settings")
local InputRecorder = require("input_recorder")

local Debuffs = setmetatable({}, {
  __index = function(t, k)
    local m = require("debuffs")
    setmetatable(t, { __index = m })
    return m[k]
  end,
})
local circles = {}
local is_attract_mode = false

PowerupsManager.is_invulnerable = false
PowerupsManager.invulnerability_timer = 0
PowerupsManager.is_slowed = false
PowerupsManager.slow_motion_timer = 0
PowerupsManager.is_phase_shift_active = false
PowerupsManager.phase_shift_timer = 0
PowerupsManager.is_bolt_active = false
PowerupsManager.bolt_timer = 0
PowerupsManager.is_score_multiplier_active = false
PowerupsManager.score_multiplier_timer = 0
PowerupsManager.is_spawn_rate_boost_active = false
PowerupsManager.spawn_rate_boost_timer = 0

local original_velocities = {}
local original_sizes = {}

local function activate_invulnerability(attract_mode_active)
  Debuffs.clear_active_debuffs()

  PowerupsManager.is_invulnerable = true
  PowerupsManager.invulnerability_timer = 10
  if not attract_mode_active then
    Sound.play("star_powerup")
  end
end

local function activate_slow_motion(attract_mode_active)
  Debuffs.clear_active_debuffs()

  PowerupsManager.is_slowed = true
  PowerupsManager.slow_motion_timer = 10
  if not attract_mode_active then
    Sound.play("slowdown_powerup")
  end
  original_velocities = {}
  original_sizes = {}
  for _, circle in ipairs(circles) do
    original_velocities[circle] = circle.angular_velocity
    circle.angular_velocity = MathUtils.rnds(0.005, 0.015)
    original_sizes[circle] = circle.obstacle_length
    local min_obstacle_length = 5
    circle.obstacle_length = math.max(circle.obstacle_length * 0.5, min_obstacle_length)
  end
end

local function activate_phase_shift(attract_mode_active)
  Debuffs.clear_active_debuffs()

  PowerupsManager.is_phase_shift_active = true
  PowerupsManager.phase_shift_timer = 10
  if not attract_mode_active then
    Sound.play("phaseshift_powerup")
  end
end

local function activate_bolt(attract_mode_active)
  Debuffs.clear_active_debuffs()

  PowerupsManager.is_bolt_active = true
  PowerupsManager.bolt_timer = 30
  Powerups.create_lightning()
  if not attract_mode_active then
    Sound.play("bolt_powerup")
  end
end

local function activate_score_multiplier(attract_mode_active)
  Debuffs.clear_active_debuffs()

  if PowerupsManager.is_score_multiplier_active then
    InputRecorder.record_next_tick(InputRecorder.INPUT.MULTIPLIER_ENDED)
  end
  PowerupsManager.is_score_multiplier_active = true
  PowerupsManager.score_multiplier_timer = 30
  InputRecorder.record_next_tick(InputRecorder.INPUT.MULTIPLIER_STARTED)
  if not attract_mode_active then
    Sound.play("star_powerup")
  end
end

local function activate_spawn_rate_boost(attract_mode_active)
  Debuffs.clear_active_debuffs()

  PowerupsManager.is_spawn_rate_boost_active = true
  PowerupsManager.spawn_rate_boost_timer = 30
  if not attract_mode_active then
    Sound.play("phaseshift_powerup")
  end
end

function PowerupsManager.init(circles_ref, attract_mode_active)
  circles = circles_ref
  is_attract_mode = attract_mode_active
  PowerupsManager.reset()
  original_velocities = {}
  original_sizes = {}
end

function PowerupsManager.reset()
  PowerupsManager.is_invulnerable = false
  PowerupsManager.invulnerability_timer = 0
  PowerupsManager.is_slowed = false
  PowerupsManager.slow_motion_timer = 0
  PowerupsManager.is_phase_shift_active = false
  PowerupsManager.phase_shift_timer = 0
  PowerupsManager.is_bolt_active = false
  PowerupsManager.bolt_timer = 0
  PowerupsManager.is_score_multiplier_active = false
  PowerupsManager.score_multiplier_timer = 0
  PowerupsManager.is_spawn_rate_boost_active = false
  PowerupsManager.spawn_rate_boost_timer = 0
end

function PowerupsManager.clear_active_powerups()
  if PowerupsManager.is_score_multiplier_active then
    InputRecorder.record_next_tick(InputRecorder.INPUT.MULTIPLIER_ENDED)
  end
  if PowerupsManager.is_slowed then
    for _, circle in ipairs(circles) do
      if original_velocities[circle] then
        circle.angular_velocity = original_velocities[circle]
      end
      if original_sizes[circle] then
        circle.obstacle_length = original_sizes[circle]
      end
    end
    original_velocities = {}
    original_sizes = {}
  end
  PowerupsManager.reset()
end

function PowerupsManager.get_player_color()
  if PowerupsManager.is_invulnerable then
    return Colors.yellow
  elseif PowerupsManager.is_phase_shift_active then
    return Colors.emerald_shade
  elseif PowerupsManager.is_slowed then
    return Colors.cyan_glow
  else
    return Colors.periwinkle_mist
  end
end

function PowerupsManager.get_ping_color()
  if PowerupsManager.is_phase_shift_active then
    return Colors.emerald_shade
  elseif PowerupsManager.is_invulnerable then
    return Colors.yellow
  elseif PowerupsManager.is_slowed then
    return Colors.cyan_glow
  else
    return Colors.periwinkle_mist
  end
end

function PowerupsManager.get_current_max_radius()
  return PowerupsManager.is_phase_shift_active and 18 or 12
end

function PowerupsManager.draw_next_jump_ping_indicator(jump_pings, blip_counter, current_level_data)
  if not jump_pings then
    return
  end
  if GameState.is_not("playing") then
    return
  end
  for _, ping in ipairs(jump_pings) do
    if ping.life > 0 and ping.circle then
      local current_max_radius = PowerupsManager.get_current_max_radius()
      local color
      if
        current_level_data
        and current_level_data.win_condition.type == "blips"
        and blip_counter.value >= current_level_data.win_condition.value - 1
      then
        color = current_level_data.win_condition.final_blip_color
      elseif ping.circle and ping.circle.is_passed then
        color = Colors.rusty_cedar_transparent
      else
        color = PowerupsManager.get_ping_color()
      end
      local alpha = math.max(0, 1 - (ping.radius / current_max_radius))

      love.graphics.setColor(color[1], color[2], color[3], alpha * 0.8)
      love.graphics.setLineWidth(1.5)
      love.graphics.circle("line", ping.circle.position.x, ping.circle.position.y, ping.radius)
      love.graphics.setLineWidth(1)
    end
  end
end

function PowerupsManager.update(dt, game_state)
  if PowerupsManager.is_invulnerable and game_state ~= "help" and game_state ~= "levelCompleted" then
    PowerupsManager.invulnerability_timer = PowerupsManager.invulnerability_timer - dt
    if PowerupsManager.invulnerability_timer <= 0 then
      PowerupsManager.is_invulnerable = false
    end
  end

  if PowerupsManager.is_slowed and game_state ~= "help" and game_state ~= "levelCompleted" then
    PowerupsManager.slow_motion_timer = PowerupsManager.slow_motion_timer - dt
    if PowerupsManager.slow_motion_timer <= 0 then
      PowerupsManager.is_slowed = false
      for _, circle in ipairs(circles) do
        if original_velocities[circle] then
          circle.angular_velocity = original_velocities[circle]
        end
        if original_sizes[circle] then
          circle.obstacle_length = original_sizes[circle]
        end
      end
      original_velocities = {}
      original_sizes = {}
    end
  end

  if PowerupsManager.is_phase_shift_active and game_state ~= "help" and game_state ~= "levelCompleted" then
    PowerupsManager.phase_shift_timer = PowerupsManager.phase_shift_timer - dt
    if PowerupsManager.phase_shift_timer <= 0 then
      PowerupsManager.is_phase_shift_active = false
    end
  end

  if PowerupsManager.is_bolt_active and game_state ~= "help" and game_state ~= "levelCompleted" then
    PowerupsManager.bolt_timer = PowerupsManager.bolt_timer - dt
    if PowerupsManager.bolt_timer <= 0 then
      PowerupsManager.is_bolt_active = false
    end
  end

  if PowerupsManager.is_score_multiplier_active and game_state ~= "help" and game_state ~= "levelCompleted" then
    PowerupsManager.score_multiplier_timer = PowerupsManager.score_multiplier_timer - dt
    if PowerupsManager.score_multiplier_timer <= 0 then
      InputRecorder.record_next_tick(InputRecorder.INPUT.MULTIPLIER_ENDED)
      PowerupsManager.is_score_multiplier_active = false
    end
  end

  if PowerupsManager.is_spawn_rate_boost_active and game_state ~= "help" and game_state ~= "levelCompleted" then
    PowerupsManager.spawn_rate_boost_timer = PowerupsManager.spawn_rate_boost_timer - dt
    if PowerupsManager.spawn_rate_boost_timer <= 0 then
      PowerupsManager.is_spawn_rate_boost_active = false
    end
  end

  Powerups.update(dt, game_state, PowerupsManager.is_bolt_active, PowerupsManager.is_spawn_rate_boost_active)
end

function PowerupsManager.handle_blip_collision(player_circle)
  if not player_circle or not player_circle.next then
    return false, false
  end
  local collected_star, collected_clock, collected_phase_shift, collected_bolt, collected_score_multiplier, collected_spawn_rate_boost =
    Powerups.check_blip_collision(player_circle, player_circle.next)

  if collected_star then
    activate_invulnerability(is_attract_mode)
  end
  if collected_clock then
    activate_slow_motion(is_attract_mode)
  end
  if collected_phase_shift then
    activate_phase_shift(is_attract_mode)
  end
  if collected_bolt then
    activate_bolt(is_attract_mode)
  end
  if collected_score_multiplier then
    activate_score_multiplier(is_attract_mode)
  end
  if collected_spawn_rate_boost then
    activate_spawn_rate_boost(is_attract_mode)
  end

  local blip_collected_powerup = collected_star
    or collected_clock
    or collected_phase_shift
    or collected_bolt
    or collected_score_multiplier
    or collected_spawn_rate_boost

  if blip_collected_powerup and not collected_star then
    PowerupsManager.is_invulnerable = true
  end

  return blip_collected_powerup, collected_star
end

function PowerupsManager.handle_player_collision(player_circle)
  if not player_circle then
    return
  end
  local collected_star, collected_clock, collected_phase_shift, collected_bolt, collected_score_multiplier, collected_spawn_rate_boost =
    Powerups.check_collisions(player_circle)
  if collected_star then
    activate_invulnerability(is_attract_mode)
  end

  if collected_clock then
    activate_slow_motion(is_attract_mode)
  end

  if collected_phase_shift then
    activate_phase_shift(is_attract_mode)
  end

  if collected_bolt then
    activate_bolt(is_attract_mode)
  end

  if collected_score_multiplier then
    activate_score_multiplier(is_attract_mode)
  end

  if collected_spawn_rate_boost then
    activate_spawn_rate_boost(is_attract_mode)
  end
end

local function draw_spawn_rate_indicator()
  if GameState.is("gameOver") or GameState.is("levelCompleted") then
    return
  end
  local alpha_pulse = 0.8
  if not GameState.is_paused then
    alpha_pulse = math.sin(love.timer.getTime() * 8) * 0.2 + 0.6 -- Pulses between 40% and 80% opacity
  end
  local color = Colors.neon_lime_splash

  love.graphics.setColor(color[1], color[2], color[3], alpha_pulse)
  love.graphics.rectangle("fill", 0, 0, Settings.INTERNAL_WIDTH, 2.5)
end

PowerupsManager.draw_spawn_rate_indicator = draw_spawn_rate_indicator

return PowerupsManager
