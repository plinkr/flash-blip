local Debuffs = {}

local Vector = require("lib.vector")
local Settings = require("settings")
local Sound = require("sound")
local Colors = require("colors")
local MathUtils = require("math_utils")
local GameState = require("gamestate")

Debuffs.emp_fuses = {}
Debuffs.particles = {}
Debuffs.is_emp_active = false
Debuffs.emp_timer = 0
Debuffs.glitch_timer = 0

local min_spawn_interval = 20
local max_spawn_interval = 40

local min_particle_life = 20
local max_particle_life = 40

local spawn_timer = 0
local spawn_interval = love.math.random(min_spawn_interval, max_spawn_interval)

local debuff_color = Colors.crimson

function Debuffs.init()
  Debuffs.reset()
end

function Debuffs.reset()
  Debuffs.emp_fuses = {}
  Debuffs.particles = {}
  Debuffs.is_emp_active = false
  Debuffs.emp_timer = 0
  Debuffs.glitch_timer = 0
  spawn_timer = 0
  spawn_interval = love.math.random(min_spawn_interval, max_spawn_interval)
end

function Debuffs.spawn_emp_fuse()
  local emp_fuse = {
    pos = Vector:new(love.math.random(2.5, Settings.INTERNAL_WIDTH - 2.5), -2.5),
    radius = 3.5,
    speed = love.math.random(6, 12),
    color = debuff_color,
    life = 1,
    rotation = 0,
  }
  table.insert(Debuffs.emp_fuses, emp_fuse)
end

function Debuffs.spawn_particle(position, count, speed, angle, angle_width, color)
  count = count or 1
  for _ = 1, count do
    local particle_angle = angle + (love.math.random() * 2 - 1) * angle_width
    table.insert(Debuffs.particles, {
      pos = position:copy(),
      vel = Vector:new(math.cos(particle_angle) * speed, math.sin(particle_angle) * speed),
      life = love.math.random(min_particle_life, max_particle_life),
      max_life = max_particle_life,
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

function Debuffs.update(dt, game_state)
  if game_state == "gameOver" or game_state == "help" or game_state == "levelCompleted" then
    return
  end

  if Debuffs.is_emp_active then
    Debuffs.emp_timer = Debuffs.emp_timer - dt
    if Debuffs.emp_timer <= 0 then
      Debuffs.is_emp_active = false
    end
  end

  if Debuffs.glitch_timer and Debuffs.glitch_timer > 0 then
    Debuffs.glitch_timer = Debuffs.glitch_timer - dt
  end

  spawn_timer = spawn_timer + dt
  if spawn_timer > spawn_interval then
    Debuffs.spawn_emp_fuse()
    spawn_timer = 0
    spawn_interval = love.math.random(min_spawn_interval, max_spawn_interval)
  end

  for i = #Debuffs.emp_fuses, 1, -1 do
    local fuse = Debuffs.emp_fuses[i]
    fuse.pos.y = fuse.pos.y + fuse.speed * dt
    fuse.rotation = fuse.rotation + dt * 2.5
    Debuffs.spawn_particle(fuse.pos, 1, 0.5, -math.pi / 2, 0.5, debuff_color)

    if fuse.pos.y > Settings.INTERNAL_HEIGHT + fuse.radius then
      table.remove(Debuffs.emp_fuses, i)
    end
  end

  remove(Debuffs.particles, function(p)
    p.pos:add(p.vel:copy():mul(dt * 60))
    p.life = p.life - 1
    return p.life <= 0
  end)
end

function Debuffs.draw_emp_fuse(x, y, r, rotation, lineWidth)
  love.graphics.push()
  love.graphics.translate(x, y)
  love.graphics.rotate(rotation)

  -- Outer segmented circle
  love.graphics.setLineWidth(lineWidth or 1)
  love.graphics.circle("line", 0, 0, r, 8)

  -- Inner cross (times sign)
  love.graphics.line(-r * 0.35, -r * 0.35, r * 0.35, r * 0.35)
  love.graphics.line(-r * 0.35, r * 0.35, r * 0.35, -r * 0.35)

  love.graphics.pop()
  love.graphics.setLineWidth(1)
end

function Debuffs.draw(game_state)
  if game_state == "gameOver" or game_state == "levelCompleted" then
    return
  end

  for _, p in ipairs(Debuffs.particles) do
    local alpha = math.max(0, p.life / p.max_life)
    love.graphics.setColor(p.color[1], p.color[2], p.color[3], alpha)
    love.graphics.circle("fill", p.pos.x, p.pos.y, 0.25)
  end

  for _, fuse in ipairs(Debuffs.emp_fuses) do
    love.graphics.setColor(fuse.color[1], fuse.color[2], fuse.color[3], 1)
    Debuffs.draw_emp_fuse(fuse.pos.x, fuse.pos.y, fuse.radius, fuse.rotation)
  end

  love.graphics.setColor(1, 1, 1, 1)
end

function Debuffs.activate_emp()
  Debuffs.is_emp_active = true
  Debuffs.emp_timer = 10.0 -- EMP debuff duration
  if not GameState.isAttractMode then
    Sound.play("debuff_emp")
  end

  local PowerupsManager = require("powerups_manager")
  PowerupsManager.clearActivePowerups()

  local Powerups = require("powerups")
  Powerups.activePings = {}
  Powerups.particles = {}
end

function Debuffs.check_collisions(player)
  if not player then
    return false
  end

  local collected_emp = false

  for i = #Debuffs.emp_fuses, 1, -1 do
    local fuse = Debuffs.emp_fuses[i]
    if MathUtils.circle_collision(player.position.x, player.position.y, 2.5, fuse.pos.x, fuse.pos.y, fuse.radius) then
      Debuffs.spawn_particle(fuse.pos, 25, 2.5, 0, math.pi * 2, debuff_color)
      table.remove(Debuffs.emp_fuses, i)
      collected_emp = true
    end
  end

  local Powerups = require("powerups")
  for i = #Powerups.activePings, 1, -1 do
    local ping = Powerups.activePings[i]
    if ping.life > 0 then
      for j = #Debuffs.emp_fuses, 1, -1 do
        local fuse = Debuffs.emp_fuses[j]
        if MathUtils.circle_collision(ping.pos.x, ping.pos.y, ping.radius, fuse.pos.x, fuse.pos.y, fuse.radius) then
          Debuffs.spawn_particle(fuse.pos, 25, 2.5, 0, math.pi * 2, debuff_color)
          table.remove(Debuffs.emp_fuses, j)
          collected_emp = true
        end
      end
    end
  end

  if collected_emp then
    Debuffs.activate_emp()
  end

  return collected_emp
end

function Debuffs.check_blip_collision(player, target)
  if not player or not target then
    return false
  end

  local collected_emp = false
  local p1 = player.position
  local p2 = target.position

  for i = #Debuffs.emp_fuses, 1, -1 do
    local fuse = Debuffs.emp_fuses[i]
    if MathUtils.line_circle_collision(p1, p2, fuse.pos, fuse.radius) then
      Debuffs.spawn_particle(fuse.pos, 25, 2.5, 0, math.pi * 2, debuff_color)
      table.remove(Debuffs.emp_fuses, i)
      collected_emp = true
    end
  end

  if collected_emp then
    Debuffs.activate_emp()
  end

  return collected_emp
end

function Debuffs.clear_active_debuffs()
  Debuffs.is_emp_active = false
  Debuffs.emp_timer = 0
end

return Debuffs
