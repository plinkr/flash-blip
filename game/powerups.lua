local Powerups = {}

local Colors = require("colors")
local Vector = require("lib.vector")
local Settings = require("settings")
local MathUtils = require("math_utils")

Powerups.stars = {}
Powerups.clocks = {}
Powerups.phase_shifts = {}
Powerups.bolts = {}
Powerups.score_multipliers = {}
Powerups.spawn_rate_boosts = {}

Powerups.particles = {}
Powerups.active_pings = {}

-- First intervals are shorter
local active_spawn_timer = 0
local active_spawn_interval = love.math.random(4, 8)
local next_active_powerup_type = "star"

local support_spawn_timer = 0
local support_spawn_interval = love.math.random(5, 10)
local next_support_powerup_type = "bolt"

function Powerups.reset()
  Powerups.stars = {}
  Powerups.clocks = {}
  Powerups.phase_shifts = {}
  Powerups.bolts = {}
  Powerups.score_multipliers = {}
  Powerups.spawn_rate_boosts = {}
  Powerups.particles = {}
  Powerups.active_pings = {}
  Powerups.lightning = nil
  active_spawn_timer = 0
  active_spawn_interval = love.math.random(4, 8)
  next_active_powerup_type = "star"
  support_spawn_timer = 0
  support_spawn_interval = love.math.random(5, 10)
  next_support_powerup_type = "bolt"
end

local function get_lightning_y_position()
  return Settings.INTERNAL_HEIGHT * 0.65
end

function Powerups.draw_star(x, y, r, rotation)
  love.graphics.push()
  love.graphics.translate(x, y)
  love.graphics.rotate(rotation)

  local points = {}
  local spikes = 5
  local outer_radius = r
  local inner_radius = r * 0.4
  local angle_step = 2 * math.pi / (spikes * 2)

  for i = 0, 2 * spikes - 1 do
    local radius = (i % 2 == 0) and outer_radius or inner_radius
    local angle = i * angle_step - math.pi / 2
    table.insert(points, math.cos(angle) * radius)
    table.insert(points, math.sin(angle) * radius)
  end

  -- Use triangulation for concave polygons
  local triangles = love.math.triangulate(points)

  for _, triangle in ipairs(triangles) do
    love.graphics.polygon("fill", triangle)
  end

  love.graphics.pop()
end

function Powerups.draw_clock(x, y, r, rotation)
  love.graphics.push()
  love.graphics.translate(x, y)
  love.graphics.rotate(rotation)

  -- Two opposite triangles to form the hourglass
  local half_height = r
  local half_width = r * 0.75

  -- Upper triangle
  local triangle_up = {
    -half_width,
    -half_height,
    half_width,
    -half_height,
    0,
    0,
  }

  -- Lower triangle
  local triangle_bottom = {
    -half_width,
    half_height,
    half_width,
    half_height,
    0,
    0,
  }

  love.graphics.polygon("fill", triangle_up)
  love.graphics.polygon("fill", triangle_bottom)

  love.graphics.pop()
end

function Powerups.draw_phase_shift(x, y, r, rotation, line_width)
  love.graphics.push()
  love.graphics.translate(x, y)
  love.graphics.rotate(rotation)
  love.graphics.setLineWidth(line_width or 1)

  -- Draw two chevron arrows pointing at each other
  local arrow_points_1 = {
    -r * 0.6,
    -r * 0.5,
    -r * 0.2,
    0,
    -r * 0.6,
    r * 0.5,
  }
  local arrow_points_2 = {
    r * 0.6,
    -r * 0.5,
    r * 0.2,
    0,
    r * 0.6,
    r * 0.5,
  }

  love.graphics.line(arrow_points_1)
  love.graphics.line(arrow_points_2)

  love.graphics.pop()
  love.graphics.setLineWidth(1)
end

function Powerups.draw_bolt(x, y, r, rotation, line_width)
  love.graphics.push()
  love.graphics.translate(x, y)
  love.graphics.rotate(rotation)
  love.graphics.setLineWidth((line_width or 1) * 1.2)

  -- Triangular S shape for the lightning bolt
  local points = {
    -r * 0.2,
    -r,
    r * 0.4,
    -r * 0.2,
    -r * 0.4,
    r * 0.2,
    r * 0.2,
    r,
  }

  love.graphics.line(points)

  love.graphics.pop()
  love.graphics.setLineWidth(1)
end

function Powerups.draw_score_multiplier(x, y, r, rotation)
  love.graphics.push()
  love.graphics.translate(x, y)
  love.graphics.rotate(rotation)

  -- Draw 4 triangles pointing outward to symbolize multiplication
  local half_r = r * 0.5
  local outer_r = r * 1.1

  -- Upper triangle
  local tri_up = {
    0,
    -outer_r,
    -half_r,
    -half_r,
    half_r,
    -half_r,
  }

  -- Lower triangle
  local tri_down = {
    0,
    outer_r,
    -half_r,
    half_r,
    half_r,
    half_r,
  }

  -- Left triangle
  local tri_left = {
    -outer_r,
    0,
    -half_r,
    -half_r,
    -half_r,
    half_r,
  }

  -- Right triangle
  local tri_right = {
    outer_r,
    0,
    half_r,
    -half_r,
    half_r,
    half_r,
  }

  love.graphics.polygon("fill", tri_up)
  love.graphics.polygon("fill", tri_down)
  love.graphics.polygon("fill", tri_left)
  love.graphics.polygon("fill", tri_right)

  love.graphics.pop()
end

function Powerups.draw_spawn_rate_boost(x, y, r, rotation)
  love.graphics.push()
  love.graphics.translate(x, y)
  love.graphics.rotate(rotation)

  local arrow_width = r * 0.7
  local arrow_body_height = r * 0.5
  local arrow_tip_height = -r

  local arrow_points = {
    0,
    arrow_tip_height,
    -arrow_width,
    arrow_body_height,
    arrow_width,
    arrow_body_height,
  }
  love.graphics.polygon("fill", arrow_points)

  local particle_radius = r * 0.2
  love.graphics.circle("fill", 0, arrow_tip_height - particle_radius * 1.5, particle_radius)
  love.graphics.circle("fill", -arrow_width * 0.6, arrow_tip_height + particle_radius * 0.5, particle_radius * 0.8)
  love.graphics.circle("fill", arrow_width * 0.6, arrow_tip_height + particle_radius * 0.5, particle_radius * 0.8)

  love.graphics.pop()
end

function Powerups.spawn_star()
  local star = {
    pos = Vector:new(love.math.random(2.5, Settings.INTERNAL_WIDTH - 2.5), -2.5),
    radius = 3,
    speed = love.math.random(6, 12),
    color = Colors.yellow,
    life = 1,
    rotation = 0,
  }
  table.insert(Powerups.stars, star)
end

function Powerups.spawn_clock()
  local clock = {
    pos = Vector:new(love.math.random(2.5, Settings.INTERNAL_WIDTH - 2.5), -2.5),
    radius = 3,
    speed = love.math.random(6, 12),
    color = Colors.cyan_glow,
    life = 1,
    rotation = 0,
  }
  table.insert(Powerups.clocks, clock)
end

function Powerups.spawn_phase_shift()
  local phase_shift = {
    pos = Vector:new(love.math.random(2.5, Settings.INTERNAL_WIDTH - 2.5), -2.5),
    radius = 4,
    speed = love.math.random(6, 12),
    color = Colors.emerald_shade,
    life = 1,
    rotation = 0,
  }
  table.insert(Powerups.phase_shifts, phase_shift)
end

function Powerups.spawn_bolt()
  local bolt = {
    pos = Vector:new(love.math.random(2.5, Settings.INTERNAL_WIDTH - 2.5), -2.5),
    radius = 4,
    speed = love.math.random(6, 12),
    color = Colors.tangerine_blaze,
    life = 1,
    rotation = 0,
  }
  table.insert(Powerups.bolts, bolt)
end

function Powerups.spawn_score_multiplier()
  local multiplier = {
    pos = Vector:new(love.math.random(2.5, Settings.INTERNAL_WIDTH - 2.5), -2.5),
    radius = 4,
    speed = love.math.random(6, 12),
    color = Colors.yellow,
    life = 1,
    rotation = 0,
  }
  table.insert(Powerups.score_multipliers, multiplier)
end

function Powerups.spawn_spawn_rate_boost()
  local boost = {
    pos = Vector:new(love.math.random(2.5, Settings.INTERNAL_WIDTH - 2.5), -2.5),
    radius = 4,
    speed = love.math.random(6, 12),
    color = Colors.neon_lime_splash,
    life = 1,
    rotation = 0,
  }
  table.insert(Powerups.spawn_rate_boosts, boost)
end

-- Create particles
function Powerups.particle(position, count, speed, angle, angle_width, color)
  count = count or 1
  for _ = 1, count do
    local particle_angle = angle + (love.math.random() * 2 - 1) * angle_width
    table.insert(Powerups.particles, {
      pos = position:copy(),
      vel = Vector:new(math.cos(particle_angle) * speed, math.sin(particle_angle) * speed),
      life = love.math.random(15, 30),
      max_life = 30,
      color = color,
    })
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

function Powerups.update(dt, game_state, is_bolt_active, is_spawn_rate_boost_active)
  if game_state == "gameOver" or game_state == "help" or game_state == "levelCompleted" then
    return
  end
  if is_bolt_active then
    local source = { x = 0, y = get_lightning_y_position() }
    local target = { x = Settings.INTERNAL_WIDTH, y = get_lightning_y_position() }
    Powerups.lightning.main_line = { source, target }
    for _ = 1, 10 do
      local index = math.random(#Powerups.lightning.main_line - 1)
      Powerups.add_point(Powerups.lightning, index)
    end

    if Powerups.lightning.is_flashing then
      Powerups.lightning.flash_timer = Powerups.lightning.flash_timer - dt
      if Powerups.lightning.flash_timer <= 0 then
        Powerups.lightning.is_flashing = false
      end
    end
  end

  -- Logic for the appearance of active powerups
  active_spawn_timer = active_spawn_timer + dt
  if active_spawn_timer > active_spawn_interval then
    if next_active_powerup_type == "star" then
      Powerups.spawn_star()
    elseif next_active_powerup_type == "clock" then
      Powerups.spawn_clock()
    else
      Powerups.spawn_phase_shift()
    end
    active_spawn_timer = 0
    if is_spawn_rate_boost_active then
      active_spawn_interval = love.math.random(2.5, 5)
    else
      active_spawn_interval = love.math.random(5, 10)
    end
    local rand = love.math.random()
    if rand > 0.66 then
      next_active_powerup_type = "star"
    elseif rand > 0.33 then
      next_active_powerup_type = "clock"
    else
      next_active_powerup_type = "phase_shift"
    end
  end

  -- Logic for the appearance of support powerups
  support_spawn_timer = support_spawn_timer + dt
  if support_spawn_timer > support_spawn_interval then
    if next_support_powerup_type == "bolt" then
      Powerups.spawn_bolt()
    elseif next_support_powerup_type == "scoreMultiplier" then
      Powerups.spawn_score_multiplier()
    else
      Powerups.spawn_spawn_rate_boost()
    end
    support_spawn_timer = 0
    -- The next powerup will have a higher probability of appearing 2x
    if is_spawn_rate_boost_active then
      support_spawn_interval = love.math.random(6, 10)
    else
      support_spawn_interval = love.math.random(12, 20)
    end
    local rand = love.math.random()
    if rand > 0.66 then
      next_support_powerup_type = "bolt"
    elseif rand > 0.33 then
      next_support_powerup_type = "scoreMultiplier"
    else
      next_support_powerup_type = "spawnRateBoost"
    end
  end

  for i = #Powerups.stars, 1, -1 do
    local star = Powerups.stars[i]
    star.pos.y = star.pos.y + star.speed * dt
    star.rotation = star.rotation + dt * 2
    Powerups.particle(star.pos, 1, 0.5, -math.pi / 2, 0.5, Colors.yellow)

    if star.pos.y > Settings.INTERNAL_HEIGHT + star.radius then
      table.remove(Powerups.stars, i)
    end
  end

  for i = #Powerups.clocks, 1, -1 do
    local clock = Powerups.clocks[i]
    clock.pos.y = clock.pos.y + clock.speed * dt
    clock.rotation = clock.rotation + dt * 2
    Powerups.particle(clock.pos, 1, 0.5, -math.pi / 2, 0.5, Colors.cyan_glow)

    if clock.pos.y > Settings.INTERNAL_HEIGHT + clock.radius then
      table.remove(Powerups.clocks, i)
    end
  end

  for i = #Powerups.phase_shifts, 1, -1 do
    local phase_shift = Powerups.phase_shifts[i]
    phase_shift.pos.y = phase_shift.pos.y + phase_shift.speed * dt
    phase_shift.rotation = phase_shift.rotation + dt * 1.5
    Powerups.particle(phase_shift.pos, 1, 0.5, -math.pi / 2, 0.5, Colors.emerald_shade)

    if phase_shift.pos.y > Settings.INTERNAL_HEIGHT + phase_shift.radius then
      table.remove(Powerups.phase_shifts, i)
    end
  end

  for i = #Powerups.bolts, 1, -1 do
    local bolt = Powerups.bolts[i]
    bolt.pos.y = bolt.pos.y + bolt.speed * dt
    bolt.rotation = bolt.rotation + dt * 1.5
    Powerups.particle(bolt.pos, 1, 0.5, -math.pi / 2, 0.5, Colors.tangerine_blaze)

    if bolt.pos.y > Settings.INTERNAL_HEIGHT + bolt.radius then
      table.remove(Powerups.bolts, i)
    end
  end

  for i = #Powerups.score_multipliers, 1, -1 do
    local multiplier = Powerups.score_multipliers[i]
    multiplier.pos.y = multiplier.pos.y + multiplier.speed * dt
    multiplier.rotation = multiplier.rotation + dt * 1.5
    Powerups.particle(multiplier.pos, 1, 0.5, -math.pi / 2, 0.5, multiplier.color)
    if multiplier.pos.y > Settings.INTERNAL_HEIGHT + multiplier.radius then
      table.remove(Powerups.score_multipliers, i)
    end
  end

  for i = #Powerups.spawn_rate_boosts, 1, -1 do
    local boost = Powerups.spawn_rate_boosts[i]
    boost.pos.y = boost.pos.y + boost.speed * dt
    boost.rotation = boost.rotation + dt * 1.5
    Powerups.particle(boost.pos, 1, 0.5, -math.pi / 2, 0.5, boost.color)
    if boost.pos.y > Settings.INTERNAL_HEIGHT + boost.radius then
      table.remove(Powerups.spawn_rate_boosts, i)
    end
  end

  remove(Powerups.particles, function(particle)
    particle.pos:add(particle.vel:copy():mul(dt * 60))
    particle.life = particle.life - 1
    return particle.life <= 0
  end)
end

function Powerups.draw(game_state)
  if game_state == "gameOver" or game_state == "levelCompleted" then
    return
  end
  for _, particle in ipairs(Powerups.particles) do
    local alpha = math.max(0, particle.life / particle.max_life)
    love.graphics.setColor(particle.color[1], particle.color[2], particle.color[3], alpha)
    love.graphics.circle("fill", particle.pos.x, particle.pos.y, 0.25)
  end

  for _, star in ipairs(Powerups.stars) do
    love.graphics.setColor(star.color[1], star.color[2], star.color[3], 1)
    Powerups.draw_star(star.pos.x, star.pos.y, star.radius, star.rotation)
  end

  for _, clock in ipairs(Powerups.clocks) do
    love.graphics.setColor(clock.color[1], clock.color[2], clock.color[3], 1)
    Powerups.draw_clock(clock.pos.x, clock.pos.y, clock.radius, clock.rotation)
  end

  for _, phase_shift in ipairs(Powerups.phase_shifts) do
    love.graphics.setColor(phase_shift.color[1], phase_shift.color[2], phase_shift.color[3], 1)
    Powerups.draw_phase_shift(phase_shift.pos.x, phase_shift.pos.y, phase_shift.radius, phase_shift.rotation, 1)
  end

  for _, bolt in ipairs(Powerups.bolts) do
    love.graphics.setColor(bolt.color[1], bolt.color[2], bolt.color[3], 1)
    Powerups.draw_bolt(bolt.pos.x, bolt.pos.y, bolt.radius, bolt.rotation, 1)
  end

  for _, multiplier in ipairs(Powerups.score_multipliers) do
    love.graphics.setColor(multiplier.color[1], multiplier.color[2], multiplier.color[3], 1)
    Powerups.draw_score_multiplier(multiplier.pos.x, multiplier.pos.y, multiplier.radius, multiplier.rotation)
  end

  for _, boost in ipairs(Powerups.spawn_rate_boosts) do
    love.graphics.setColor(boost.color[1], boost.color[2], boost.color[3], 1)
    Powerups.draw_spawn_rate_boost(boost.pos.x, boost.pos.y, boost.radius, boost.rotation)
  end

  love.graphics.setColor(1, 1, 1, 1)
end

function Powerups.draw_lightning()
  if not Powerups.lightning.main_line then
    return
  end

  local lightning_colors = { Colors.apricot_glow, Colors.tangerine_blaze }

  for i = 1, #Powerups.lightning.main_line - 1 do
    local start_point = Powerups.lightning.main_line[i]
    local end_point = Powerups.lightning.main_line[i + 1]

    local color = lightning_colors[love.math.random(1, #lightning_colors)]
    if Powerups.lightning.is_flashing then
      color = Powerups.lightning.flash_color
    end

    love.graphics.setColor(color)
    love.graphics.line(start_point.x, start_point.y, end_point.x, end_point.y)
  end

  love.graphics.setColor(1, 1, 1, 1)
end

function Powerups.activate_player_ping(player_pos, is_phase_shift_active, color)
  local Debuffs = require("debuffs")
  local Sound = require("sound")
  if Debuffs.is_emp_active then
    Sound.play("debuff_emp")
    Debuffs.spawn_particle(player_pos, 5, 1.5, 0, math.pi * 2, { 0.8, 0.1, 0.1 })
    Debuffs.glitch_timer = 0.3
    return
  end

  local InputRecorder = require("input_recorder")
  if InputRecorder.is_active() then
    InputRecorder.record(InputRecorder.INPUT.PING)
  end

  local new_ping = {
    pos = player_pos:copy(),
    radius = 0,
    max_radius = is_phase_shift_active and (Settings.INTERNAL_WIDTH / 1.2) or (Settings.INTERNAL_WIDTH / 2.5),
    speed = is_phase_shift_active and 60 or 40,
    life = 1,
    is_phase_shift_active = is_phase_shift_active,
    color = color,
  }
  table.insert(Powerups.active_pings, new_ping)
end

function Powerups.check_collisions(player)
  if not player then
    return false, false, false, false, false, false
  end

  local px, py = player.position.x, player.position.y
  local collected_star = false
  local collected_clock = false
  local collected_phase_shift = false
  local collected_bolt = false
  local collected_score_multiplier = false
  local collected_spawn_rate_boost = false

  for i = #Powerups.stars, 1, -1 do
    local star = Powerups.stars[i]
    if MathUtils.is_circle_collision(px, py, 2.5, star.pos.x, star.pos.y, star.radius) then
      Powerups.particle(star.pos, 20, 2, 0, math.pi * 2, Colors.yellow)
      table.remove(Powerups.stars, i)
      collected_star = true
    end
  end

  for i = #Powerups.clocks, 1, -1 do
    local clock = Powerups.clocks[i]
    if MathUtils.is_circle_collision(px, py, 2.5, clock.pos.x, clock.pos.y, clock.radius) then
      Powerups.particle(clock.pos, 20, 2, 0, math.pi * 2, Colors.cyan_glow)
      table.remove(Powerups.clocks, i)
      collected_clock = true
    end
  end

  for i = #Powerups.phase_shifts, 1, -1 do
    local phase_shift = Powerups.phase_shifts[i]
    if MathUtils.is_circle_collision(px, py, 2.5, phase_shift.pos.x, phase_shift.pos.y, phase_shift.radius) then
      Powerups.particle(phase_shift.pos, 20, 2, 0, math.pi * 2, Colors.emerald_shade)
      table.remove(Powerups.phase_shifts, i)
      collected_phase_shift = true
    end
  end

  for i = #Powerups.bolts, 1, -1 do
    local bolt = Powerups.bolts[i]
    if MathUtils.is_circle_collision(px, py, 2.5, bolt.pos.x, bolt.pos.y, bolt.radius) then
      Powerups.particle(bolt.pos, 20, 2, 0, math.pi * 2, Colors.tangerine_blaze)
      table.remove(Powerups.bolts, i)
      collected_bolt = true
    end
  end

  for i = #Powerups.score_multipliers, 1, -1 do
    local multiplier = Powerups.score_multipliers[i]
    if MathUtils.is_circle_collision(px, py, 2.5, multiplier.pos.x, multiplier.pos.y, multiplier.radius) then
      Powerups.particle(multiplier.pos, 20, 2, 0, math.pi * 2, multiplier.color)
      table.remove(Powerups.score_multipliers, i)
      collected_score_multiplier = true
    end
  end

  for i = #Powerups.spawn_rate_boosts, 1, -1 do
    local boost = Powerups.spawn_rate_boosts[i]
    if MathUtils.is_circle_collision(px, py, 2.5, boost.pos.x, boost.pos.y, boost.radius) then
      Powerups.particle(boost.pos, 20, 2, 0, math.pi * 2, boost.color)
      table.remove(Powerups.spawn_rate_boosts, i)
      collected_spawn_rate_boost = true
    end
  end

  for i = #Powerups.active_pings, 1, -1 do
    local ping = Powerups.active_pings[i]
    if ping.life > 0 then
      for j = #Powerups.stars, 1, -1 do
        local star = Powerups.stars[j]
        if MathUtils.is_circle_collision(ping.pos.x, ping.pos.y, ping.radius, star.pos.x, star.pos.y, star.radius) then
          Powerups.particle(star.pos, 20, 2, 0, math.pi * 2, Colors.yellow)
          table.remove(Powerups.stars, j)
          collected_star = true
        end
      end
      for j = #Powerups.clocks, 1, -1 do
        local clock = Powerups.clocks[j]
        if
          MathUtils.is_circle_collision(ping.pos.x, ping.pos.y, ping.radius, clock.pos.x, clock.pos.y, clock.radius)
        then
          Powerups.particle(clock.pos, 20, 2, 0, math.pi * 2, Colors.cyan_glow)
          table.remove(Powerups.clocks, j)
          collected_clock = true
        end
      end
      for j = #Powerups.phase_shifts, 1, -1 do
        local phase_shift = Powerups.phase_shifts[j]
        if
          MathUtils.is_circle_collision(
            ping.pos.x,
            ping.pos.y,
            ping.radius,
            phase_shift.pos.x,
            phase_shift.pos.y,
            phase_shift.radius
          )
        then
          Powerups.particle(phase_shift.pos, 20, 2, 0, math.pi * 2, Colors.emerald_shade)
          table.remove(Powerups.phase_shifts, j)
          collected_phase_shift = true
        end
      end
      for j = #Powerups.bolts, 1, -1 do
        local bolt = Powerups.bolts[j]
        if MathUtils.is_circle_collision(ping.pos.x, ping.pos.y, ping.radius, bolt.pos.x, bolt.pos.y, bolt.radius) then
          Powerups.particle(bolt.pos, 20, 2, 0, math.pi * 2, Colors.tangerine_blaze)
          table.remove(Powerups.bolts, j)
          collected_bolt = true
        end
      end
      for j = #Powerups.score_multipliers, 1, -1 do
        local multiplier = Powerups.score_multipliers[j]
        if
          MathUtils.is_circle_collision(
            ping.pos.x,
            ping.pos.y,
            ping.radius,
            multiplier.pos.x,
            multiplier.pos.y,
            multiplier.radius
          )
        then
          Powerups.particle(multiplier.pos, 20, 2, 0, math.pi * 2, multiplier.color)
          table.remove(Powerups.score_multipliers, j)
          collected_score_multiplier = true
        end
      end
      for j = #Powerups.spawn_rate_boosts, 1, -1 do
        local boost = Powerups.spawn_rate_boosts[j]
        if
          MathUtils.is_circle_collision(ping.pos.x, ping.pos.y, ping.radius, boost.pos.x, boost.pos.y, boost.radius)
        then
          Powerups.particle(boost.pos, 20, 2, 0, math.pi * 2, boost.color)
          table.remove(Powerups.spawn_rate_boosts, j)
          collected_spawn_rate_boost = true
        end
      end
    end
  end

  return collected_star,
    collected_clock,
    collected_phase_shift,
    collected_bolt,
    collected_score_multiplier,
    collected_spawn_rate_boost
end

function Powerups.add_point(lightning, index)
  local x1 = lightning.main_line[index].x
  local y1 = lightning.main_line[index].y
  local x2 = lightning.main_line[index + 1].x
  local y2 = lightning.main_line[index + 1].y

  -- Fractional position of the new point between x1,y1 and x2,y2
  local t = 0.25 + 0.5 * math.random()
  local x = x1 + t * (x2 - x1)
  local y = y1 + t * (y2 - y1)

  -- Perpendicular vector to the segment (clockwise)
  local dx = x2 - x1
  local dy = y2 - y1
  local length = math.sqrt(dx * dx + dy * dy)
  if length == 0 then
    return
  end

  local perp_x = dy / length
  local perp_y = -dx / length

  -- Deviation amplitude (proportional to the total length of the lightning)
  local amplitude = 0.10

  -- Random perpendicular offset
  local offset = (math.random() - 0.5) * 2 * amplitude * length
  x = x + perp_x * offset
  y = y + perp_y * offset

  table.insert(lightning.main_line, index + 1, { x = x, y = y })
end

function Powerups.create_lightning()
  local source = { x = 0, y = get_lightning_y_position() }
  local target = { x = Settings.INTERNAL_WIDTH, y = get_lightning_y_position() }
  Powerups.lightning = {
    source = source,
    target = target,
    main_line = { source, target },
    color = Colors.tangerine_blaze,
    flash_color = Colors.white,
    is_flashing = false,
    flash_timer = 0,
  }
end

function Powerups.check_lightning_collision(player)
  if not player or not Powerups.lightning.main_line then
    return false
  end

  local player_y = player.position.y
  local net_y = get_lightning_y_position()

  if player_y >= net_y then
    Powerups.lightning.is_flashing = true
    Powerups.lightning.flash_timer = 0.2
    return true
  end

  return false
end

function Powerups.update_pings(dt)
  for i = #Powerups.active_pings, 1, -1 do
    local ping = Powerups.active_pings[i]
    if ping.life > 0 then
      local current_max_radius = ping.is_phase_shift_active and 60 or 30
      ping.radius = ping.radius + ping.speed * dt
      if ping.radius >= current_max_radius then
        ping.life = 0
      end
    else
      table.remove(Powerups.active_pings, i)
    end
  end
end

function Powerups.draw_pings()
  for _, ping in ipairs(Powerups.active_pings) do
    if ping.life > 0 then
      local current_max_radius = ping.is_phase_shift_active and 60 or 30
      local alpha = math.max(0, 1 - (ping.radius / current_max_radius))
      local color = ping.color or (ping.is_phase_shift_active and Colors.emerald_shade or Colors.cyan)

      love.graphics.setColor(color[1], color[2], color[3], alpha * 0.8)
      love.graphics.setLineWidth(1.5)
      love.graphics.circle("line", ping.pos.x, ping.pos.y, ping.radius)
      love.graphics.setLineWidth(1)
    end
  end
end

function Powerups.is_ping_connected(jump_pings)
  for _, ping in ipairs(Powerups.active_pings) do
    if ping.life > 0 and jump_pings and #jump_pings > 0 then
      local jump_ping = jump_pings[1]
      if jump_ping.circle and jump_ping.life > 0 then
        if
          MathUtils.is_circle_collision(
            ping.pos.x,
            ping.pos.y,
            ping.radius,
            jump_ping.circle.position.x,
            jump_ping.circle.position.y,
            jump_ping.radius
          )
        then
          return true
        end
      end
    end
  end
  return false
end

function Powerups.check_blip_collision(player, target)
  if not player or not target then
    return false, false, false, false, false, false
  end

  local collected_star = false
  local collected_clock = false
  local collected_phase_shift = false
  local collected_bolt = false
  local collected_score_multiplier = false
  local collected_spawn_rate_boost = false

  local p1 = player.position
  local p2 = target.position

  local function check_list(list, callback)
    for i = #list, 1, -1 do
      local item = list[i]
      if MathUtils.is_line_circle_collision(p1, p2, item.pos, item.radius) then
        Powerups.particle(item.pos, 20, 2, 0, math.pi * 2, item.color)
        table.remove(list, i)
        callback()
      end
    end
  end

  check_list(Powerups.stars, function()
    collected_star = true
  end)
  check_list(Powerups.clocks, function()
    collected_clock = true
  end)
  check_list(Powerups.phase_shifts, function()
    collected_phase_shift = true
  end)
  check_list(Powerups.bolts, function()
    collected_bolt = true
  end)
  check_list(Powerups.score_multipliers, function()
    collected_score_multiplier = true
  end)
  check_list(Powerups.spawn_rate_boosts, function()
    collected_spawn_rate_boost = true
  end)

  return collected_star,
    collected_clock,
    collected_phase_shift,
    collected_bolt,
    collected_score_multiplier,
    collected_spawn_rate_boost
end

return Powerups
