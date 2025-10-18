local Powerups = {}

local Colors = require("colors")
local Vector = require("lib.vector")
local Settings = require("settings")

Powerups.stars = {}
Powerups.clocks = {}
Powerups.phaseShifts = {}
Powerups.bolts = {}
Powerups.scoreMultipliers = {}
Powerups.spawnRateBoosts = {}

Powerups.particles = {}
Powerups.activePings = {}
_G.isInvulnerable = false

local activeSpawnTimer = 0
local activeSpawnInterval = love.math.random(7, 12)
local nextActivePowerupType = "star"

local supportSpawnTimer = 0
local supportSpawnInterval = love.math.random(10, 15)
local nextSupportPowerupType = "bolt"

function Powerups.drawStar(x, y, r, rotation)
  love.graphics.push()
  love.graphics.translate(x, y)
  love.graphics.rotate(rotation)

  local points = {}
  local spikes = 5
  local outerRadius = r
  local innerRadius = r * 0.4
  local angleStep = 2 * math.pi / (spikes * 2)

  for i = 0, 2 * spikes - 1 do
    local radius = (i % 2 == 0) and outerRadius or innerRadius
    local angle = i * angleStep - math.pi / 2
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

function Powerups.drawClock(x, y, r, rotation)
  love.graphics.push()
  love.graphics.translate(x, y)
  love.graphics.rotate(rotation)

  -- Two opposite triangles to form the hourglass
  local halfHeight = r
  local halfWidth = r * 0.75

  -- Upper triangle
  local triangle_up = {
    -halfWidth,
    -halfHeight,
    halfWidth,
    -halfHeight,
    0,
    0,
  }

  -- Lower triangle
  local triangle_bottom = {
    -halfWidth,
    halfHeight,
    halfWidth,
    halfHeight,
    0,
    0,
  }

  love.graphics.polygon("fill", triangle_up)
  love.graphics.polygon("fill", triangle_bottom)

  love.graphics.pop()
end

function Powerups.drawPhaseShift(x, y, r, rotation, lineWidth)
  love.graphics.push()
  love.graphics.translate(x, y)
  love.graphics.rotate(rotation)
  love.graphics.setLineWidth(lineWidth or 1)

  -- Draw two chevron arrows pointing at each other
  local arrowPoints1 = {
    -r * 0.6,
    -r * 0.5,
    -r * 0.2,
    0,
    -r * 0.6,
    r * 0.5,
  }
  local arrowPoints2 = {
    r * 0.6,
    -r * 0.5,
    r * 0.2,
    0,
    r * 0.6,
    r * 0.5,
  }

  love.graphics.line(arrowPoints1)
  love.graphics.line(arrowPoints2)

  love.graphics.pop()
  love.graphics.setLineWidth(1)
end

function Powerups.drawBolt(x, y, r, rotation, lineWidth)
  love.graphics.push()
  love.graphics.translate(x, y)
  love.graphics.rotate(rotation)
  love.graphics.setLineWidth(lineWidth or 1)

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

function Powerups.drawScoreMultiplier(x, y, r, rotation)
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

function Powerups.drawSpawnRateBoost(x, y, r, rotation)
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

function Powerups.spawnStar()
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

function Powerups.spawnClock()
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

function Powerups.spawnPhaseShift()
  local phaseShift = {
    pos = Vector:new(love.math.random(2.5, Settings.INTERNAL_WIDTH - 2.5), -2.5),
    radius = 4,
    speed = love.math.random(6, 12),
    color = Colors.emerald_shade,
    life = 1,
    rotation = 0,
  }
  table.insert(Powerups.phaseShifts, phaseShift)
end

function Powerups.spawnBolt()
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

function Powerups.spawnScoreMultiplier()
  local multiplier = {
    pos = Vector:new(love.math.random(2.5, Settings.INTERNAL_WIDTH - 2.5), -2.5),
    radius = 4,
    speed = love.math.random(6, 12),
    color = Colors.yellow,
    life = 1,
    rotation = 0,
  }
  table.insert(Powerups.scoreMultipliers, multiplier)
end

function Powerups.spawnSpawnRateBoost()
  local boost = {
    pos = Vector:new(love.math.random(2.5, Settings.INTERNAL_WIDTH - 2.5), -2.5),
    radius = 4,
    speed = love.math.random(6, 12),
    color = Colors.neon_lime_splash,
    life = 1,
    rotation = 0,
  }
  table.insert(Powerups.spawnRateBoosts, boost)
end

-- Create particles
function Powerups.particle(position, count, speed, angle, angleWidth, color)
  count = count or 1
  for _ = 1, count do
    local particleAngle = angle + (love.math.random() * 2 - 1) * angleWidth
    table.insert(Powerups.particles, {
      pos = position:copy(),
      vel = Vector:new(math.cos(particleAngle) * speed, math.sin(particleAngle) * speed),
      life = love.math.random(15, 30),
      maxLife = 30,
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

function Powerups.update(dt, gameState, isBoltActive, isSpawnRateBoostActive)
  if gameState == "gameOver" or gameState == "help" then
    return
  end

  if isBoltActive then
    local source = { x = 0, y = Settings.INTERNAL_HEIGHT * 0.9 }
    local target = { x = Settings.INTERNAL_WIDTH, y = Settings.INTERNAL_HEIGHT * 0.9 }
    Powerups.lightning.mainLine = { source, target }
    for _ = 1, 10 do
      local index = math.random(#Powerups.lightning.mainLine - 1)
      Powerups.addPoint(Powerups.lightning, index)
    end

    if Powerups.lightning.isFlashing then
      Powerups.lightning.flashTimer = Powerups.lightning.flashTimer - dt
      if Powerups.lightning.flashTimer <= 0 then
        Powerups.lightning.isFlashing = false
      end
    end
  end

  -- Logic for the appearance of active powerups
  activeSpawnTimer = activeSpawnTimer + dt
  if activeSpawnTimer > activeSpawnInterval then
    if nextActivePowerupType == "star" then
      Powerups.spawnStar()
    elseif nextActivePowerupType == "clock" then
      Powerups.spawnClock()
    else
      Powerups.spawnPhaseShift()
    end
    activeSpawnTimer = 0
    if isSpawnRateBoostActive then
      activeSpawnInterval = love.math.random(3, 6)
    else
      activeSpawnInterval = love.math.random(7, 12)
    end
    local rand = love.math.random()
    if rand > 0.66 then
      nextActivePowerupType = "star"
    elseif rand > 0.33 then
      nextActivePowerupType = "clock"
    else
      nextActivePowerupType = "phaseShift"
    end
  end

  -- Logic for the appearance of support powerups
  supportSpawnTimer = supportSpawnTimer + dt
  if supportSpawnTimer > supportSpawnInterval then
    if nextSupportPowerupType == "bolt" then
      Powerups.spawnBolt()
    elseif nextSupportPowerupType == "scoreMultiplier" then
      Powerups.spawnScoreMultiplier()
    else
      Powerups.spawnSpawnRateBoost()
    end
    supportSpawnTimer = 0
    -- The next powerup will have a higher probability of appearing 2x
    if isSpawnRateBoostActive then
      supportSpawnInterval = love.math.random(7, 12)
    else
      supportSpawnInterval = love.math.random(15, 25)
    end
    local rand = love.math.random()
    if rand > 0.66 then
      nextSupportPowerupType = "bolt"
    elseif rand > 0.33 then
      nextSupportPowerupType = "scoreMultiplier"
    else
      nextSupportPowerupType = "spawnRateBoost"
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

  for i = #Powerups.phaseShifts, 1, -1 do
    local ps = Powerups.phaseShifts[i]
    ps.pos.y = ps.pos.y + ps.speed * dt
    ps.rotation = ps.rotation + dt * 1.5
    Powerups.particle(ps.pos, 1, 0.5, -math.pi / 2, 0.5, Colors.emerald_shade)

    if ps.pos.y > Settings.INTERNAL_HEIGHT + ps.radius then
      table.remove(Powerups.phaseShifts, i)
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

  for i = #Powerups.scoreMultipliers, 1, -1 do
    local m = Powerups.scoreMultipliers[i]
    m.pos.y = m.pos.y + m.speed * dt
    m.rotation = m.rotation + dt * 1.5
    Powerups.particle(m.pos, 1, 0.5, -math.pi / 2, 0.5, m.color)
    if m.pos.y > Settings.INTERNAL_HEIGHT + m.radius then
      table.remove(Powerups.scoreMultipliers, i)
    end
  end

  for i = #Powerups.spawnRateBoosts, 1, -1 do
    local b = Powerups.spawnRateBoosts[i]
    b.pos.y = b.pos.y + b.speed * dt
    b.rotation = b.rotation + dt * 1.5
    Powerups.particle(b.pos, 1, 0.5, -math.pi / 2, 0.5, b.color)
    if b.pos.y > Settings.INTERNAL_HEIGHT + b.radius then
      table.remove(Powerups.spawnRateBoosts, i)
    end
  end

  remove(Powerups.particles, function(p)
    p.pos:add(p.vel:copy():mul(dt * 60))
    p.life = p.life - 1
    return p.life <= 0
  end)
end

function Powerups.draw(gameState)
  if gameState == "gameOver" then
    return
  end
  for _, p in ipairs(Powerups.particles) do
    local alpha = math.max(0, p.life / p.maxLife)
    love.graphics.setColor(p.color[1], p.color[2], p.color[3], alpha)
    love.graphics.circle("fill", p.pos.x, p.pos.y, 0.25)
  end

  for _, star in ipairs(Powerups.stars) do
    love.graphics.setColor(star.color[1], star.color[2], star.color[3], 1)
    Powerups.drawStar(star.pos.x, star.pos.y, star.radius, star.rotation)
  end

  for _, clock in ipairs(Powerups.clocks) do
    love.graphics.setColor(clock.color[1], clock.color[2], clock.color[3], 1)
    Powerups.drawClock(clock.pos.x, clock.pos.y, clock.radius, clock.rotation)
  end

  for _, ps in ipairs(Powerups.phaseShifts) do
    love.graphics.setColor(ps.color[1], ps.color[2], ps.color[3], 1)
    Powerups.drawPhaseShift(ps.pos.x, ps.pos.y, ps.radius, ps.rotation, 1)
  end

  for _, bolt in ipairs(Powerups.bolts) do
    love.graphics.setColor(bolt.color[1], bolt.color[2], bolt.color[3], 1)
    Powerups.drawBolt(bolt.pos.x, bolt.pos.y, bolt.radius, bolt.rotation, 1)
  end

  for _, m in ipairs(Powerups.scoreMultipliers) do
    love.graphics.setColor(m.color[1], m.color[2], m.color[3], 1)
    Powerups.drawScoreMultiplier(m.pos.x, m.pos.y, m.radius, m.rotation)
  end

  for _, b in ipairs(Powerups.spawnRateBoosts) do
    love.graphics.setColor(b.color[1], b.color[2], b.color[3], 1)
    Powerups.drawSpawnRateBoost(b.pos.x, b.pos.y, b.radius, b.rotation)
  end

  love.graphics.setColor(1, 1, 1, 1)
end

function Powerups.drawLightning()
  if not Powerups.lightning.mainLine then
    return
  end

  local lightningColors = { Colors.apricot_glow, Colors.tangerine_blaze }

  for i = 1, #Powerups.lightning.mainLine - 1 do
    local start_point = Powerups.lightning.mainLine[i]
    local end_point = Powerups.lightning.mainLine[i + 1]

    local color = lightningColors[love.math.random(1, #lightningColors)]
    if Powerups.lightning.isFlashing then
      color = Powerups.lightning.flashColor
    end

    love.graphics.setColor(color)
    love.graphics.line(start_point.x, start_point.y, end_point.x, end_point.y)
  end

  love.graphics.setColor(1, 1, 1, 1)
end

local function circleCollision(x1, y1, r1, x2, y2, r2)
  local dx = x1 - x2
  local dy = y1 - y2
  local distance = math.sqrt(dx * dx + dy * dy)
  return distance < (r1 + r2)
end

function Powerups.activatePlayerPing(playerPos, isPhaseShiftActive, color)
  local newPing = {
    pos = playerPos:copy(),
    radius = 0,
    maxRadius = isPhaseShiftActive and (Settings.INTERNAL_WIDTH / 1.2) or (Settings.INTERNAL_WIDTH / 2.5),
    speed = isPhaseShiftActive and 60 or 40,
    life = 1,
    isPhaseShiftActive = isPhaseShiftActive,
    color = color,
  }
  table.insert(Powerups.activePings, newPing)
end

function Powerups.checkCollisions(player)
  if not player then
    return false, false, false, false, false, false
  end

  local collectedStar = false
  local collectedClock = false
  local collectedPhaseShift = false
  local collectedBolt = false
  local collectedScoreMultiplier = false
  local collectedSpawnRateBoost = false

  for i = #Powerups.stars, 1, -1 do
    local star = Powerups.stars[i]
    if circleCollision(player.position.x, player.position.y, 2.5, star.pos.x, star.pos.y, star.radius) then
      Powerups.particle(star.pos, 20, 2, 0, math.pi * 2, Colors.yellow)
      table.remove(Powerups.stars, i)
      collectedStar = true
    end
  end

  for i = #Powerups.clocks, 1, -1 do
    local clock = Powerups.clocks[i]
    if circleCollision(player.position.x, player.position.y, 2.5, clock.pos.x, clock.pos.y, clock.radius) then
      Powerups.particle(clock.pos, 20, 2, 0, math.pi * 2, Colors.cyan_glow)
      table.remove(Powerups.clocks, i)
      collectedClock = true
    end
  end

  for i = #Powerups.phaseShifts, 1, -1 do
    local ps = Powerups.phaseShifts[i]
    if circleCollision(player.position.x, player.position.y, 2.5, ps.pos.x, ps.pos.y, ps.radius) then
      Powerups.particle(ps.pos, 20, 2, 0, math.pi * 2, Colors.emerald_shade)
      table.remove(Powerups.phaseShifts, i)
      collectedPhaseShift = true
    end
  end

  for i = #Powerups.bolts, 1, -1 do
    local bolt = Powerups.bolts[i]
    if circleCollision(player.position.x, player.position.y, 2.5, bolt.pos.x, bolt.pos.y, bolt.radius) then
      Powerups.particle(bolt.pos, 20, 2, 0, math.pi * 2, Colors.tangerine_blaze)
      table.remove(Powerups.bolts, i)
      collectedBolt = true
    end
  end

  for i = #Powerups.scoreMultipliers, 1, -1 do
    local m = Powerups.scoreMultipliers[i]
    if circleCollision(player.position.x, player.position.y, 2.5, m.pos.x, m.pos.y, m.radius) then
      Powerups.particle(m.pos, 20, 2, 0, math.pi * 2, m.color)
      table.remove(Powerups.scoreMultipliers, i)
      collectedScoreMultiplier = true
    end
  end

  for i = #Powerups.spawnRateBoosts, 1, -1 do
    local b = Powerups.spawnRateBoosts[i]
    if circleCollision(player.position.x, player.position.y, 2.5, b.pos.x, b.pos.y, b.radius) then
      Powerups.particle(b.pos, 20, 2, 0, math.pi * 2, b.color)
      table.remove(Powerups.spawnRateBoosts, i)
      collectedSpawnRateBoost = true
    end
  end

  for i = #Powerups.activePings, 1, -1 do
    local ping = Powerups.activePings[i]
    if ping.life > 0 then
      for j = #Powerups.stars, 1, -1 do
        local star = Powerups.stars[j]
        if circleCollision(ping.pos.x, ping.pos.y, ping.radius, star.pos.x, star.pos.y, star.radius) then
          Powerups.particle(star.pos, 20, 2, 0, math.pi * 2, Colors.yellow)
          table.remove(Powerups.stars, j)
          collectedStar = true
        end
      end
      for j = #Powerups.clocks, 1, -1 do
        local clock = Powerups.clocks[j]
        if circleCollision(ping.pos.x, ping.pos.y, ping.radius, clock.pos.x, clock.pos.y, clock.radius) then
          Powerups.particle(clock.pos, 20, 2, 0, math.pi * 2, Colors.cyan_glow)
          table.remove(Powerups.clocks, j)
          collectedClock = true
        end
      end
      for j = #Powerups.phaseShifts, 1, -1 do
        local ps = Powerups.phaseShifts[j]
        if circleCollision(ping.pos.x, ping.pos.y, ping.radius, ps.pos.x, ps.pos.y, ps.radius) then
          Powerups.particle(ps.pos, 20, 2, 0, math.pi * 2, Colors.emerald_shade)
          table.remove(Powerups.phaseShifts, j)
          collectedPhaseShift = true
        end
      end
      for j = #Powerups.bolts, 1, -1 do
        local bolt = Powerups.bolts[j]
        if circleCollision(ping.pos.x, ping.pos.y, ping.radius, bolt.pos.x, bolt.pos.y, bolt.radius) then
          Powerups.particle(bolt.pos, 20, 2, 0, math.pi * 2, Colors.tangerine_blaze)
          table.remove(Powerups.bolts, j)
          collectedBolt = true
        end
      end
      for j = #Powerups.scoreMultipliers, 1, -1 do
        local m = Powerups.scoreMultipliers[j]
        if circleCollision(ping.pos.x, ping.pos.y, ping.radius, m.pos.x, m.pos.y, m.radius) then
          Powerups.particle(m.pos, 20, 2, 0, math.pi * 2, m.color)
          table.remove(Powerups.scoreMultipliers, j)
          collectedScoreMultiplier = true
        end
      end
      for j = #Powerups.spawnRateBoosts, 1, -1 do
        local b = Powerups.spawnRateBoosts[j]
        if circleCollision(ping.pos.x, ping.pos.y, ping.radius, b.pos.x, b.pos.y, b.radius) then
          Powerups.particle(b.pos, 20, 2, 0, math.pi * 2, b.color)
          table.remove(Powerups.spawnRateBoosts, j)
          collectedSpawnRateBoost = true
        end
      end
    end
  end

  return collectedStar,
    collectedClock,
    collectedPhaseShift,
    collectedBolt,
    collectedScoreMultiplier,
    collectedSpawnRateBoost
end

function Powerups.addPoint(lightning, index)
  local x1 = lightning.mainLine[index].x
  local y1 = lightning.mainLine[index].y
  local x2 = lightning.mainLine[index + 1].x
  local y2 = lightning.mainLine[index + 1].y

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

  local perpX = dy / length
  local perpY = -dx / length

  -- Deviation amplitude (proportional to the total length of the lightning)
  local amplitud = 0.10

  -- Random perpendicular offset
  local offset = (math.random() - 0.5) * 2 * amplitud * length
  x = x + perpX * offset
  y = y + perpY * offset

  table.insert(lightning.mainLine, index + 1, { x = x, y = y })
end

function Powerups.createLightning()
  local source = { x = 0, y = Settings.INTERNAL_HEIGHT * 0.9 }
  local target = { x = Settings.INTERNAL_WIDTH, y = Settings.INTERNAL_HEIGHT * 0.9 }
  Powerups.lightning = {
    source = source,
    target = target,
    mainLine = { source, target },
    color = Colors.tangerine_blaze,
    flashColor = Colors.white,
    isFlashing = false,
    flashTimer = 0,
  }
end

function Powerups.checkLightningCollision(player)
  if not player or not Powerups.lightning.mainLine then
    return false
  end

  local playerY = player.position.y
  local netY = Settings.INTERNAL_HEIGHT * 0.9

  if playerY >= netY then
    Powerups.lightning.isFlashing = true
    Powerups.lightning.flashTimer = 0.2
    return true
  end

  return false
end

function Powerups.updatePings(dt)
  for i = #Powerups.activePings, 1, -1 do
    local ping = Powerups.activePings[i]
    if ping.life > 0 then
      local currentMaxRadius = ping.isPhaseShiftActive and 60 or 30
      ping.radius = ping.radius + ping.speed * dt
      if ping.radius >= currentMaxRadius then
        ping.life = 0
      end
    else
      table.remove(Powerups.activePings, i)
    end
  end
end

function Powerups.drawPings()
  for _, ping in ipairs(Powerups.activePings) do
    if ping.life > 0 then
      local currentMaxRadius = ping.isPhaseShiftActive and 60 or 30
      local alpha = math.max(0, 1 - (ping.radius / currentMaxRadius))
      local color = ping.color or (ping.isPhaseShiftActive and Colors.emerald_shade or Colors.cyan)

      love.graphics.setColor(color[1], color[2], color[3], alpha * 0.8)
      love.graphics.setLineWidth(1.5)
      love.graphics.circle("line", ping.pos.x, ping.pos.y, ping.radius)
      love.graphics.setLineWidth(1)
    end
  end
end

function Powerups.checkPingConnection(jumpPings)
  for _, ping in ipairs(Powerups.activePings) do
    if ping.life > 0 and jumpPings and #jumpPings > 0 then
      local jumpPing = jumpPings[1]
      if jumpPing.circle and jumpPing.life > 0 then
        if
          circleCollision(
            ping.pos.x,
            ping.pos.y,
            ping.radius,
            jumpPing.circle.position.x,
            jumpPing.circle.position.y,
            jumpPing.radius
          )
        then
          return true
        end
      end
    end
  end
  return false
end

local function lineCircleCollision(p1, p2, circleCenter, circleRadius)
  local d = Vector:new(p2.x, p2.y):sub(p1)
  local f = Vector:new(p1.x, p1.y):sub(circleCenter)

  local a = d:dot(d)
  local b = 2 * f:dot(d)
  local c = f:dot(f) - circleRadius * circleRadius

  local discriminant = b * b - 4 * a * c
  if discriminant < 0 then
    return false
  else
    discriminant = math.sqrt(discriminant)
    local t1 = (-b - discriminant) / (2 * a)
    local t2 = (-b + discriminant) / (2 * a)

    if (t1 >= 0 and t1 <= 1) or (t2 >= 0 and t2 <= 1) then
      return true
    end

    if f:dot(f) < circleRadius * circleRadius then
      return true
    end

    return false
  end
end

function Powerups.checkBlipCollision(player, target)
  if not player or not target then
    return false, false, false, false, false, false
  end

  local collectedStar = false
  local collectedClock = false
  local collectedPhaseShift = false
  local collectedBolt = false
  local collectedScoreMultiplier = false
  local collectedSpawnRateBoost = false

  local p1 = player.position
  local p2 = target.position

  local function checkList(list, callback)
    for i = #list, 1, -1 do
      local item = list[i]
      if lineCircleCollision(p1, p2, item.pos, item.radius) then
        Powerups.particle(item.pos, 20, 2, 0, math.pi * 2, item.color)
        table.remove(list, i)
        callback()
      end
    end
  end

  checkList(Powerups.stars, function()
    collectedStar = true
  end)
  checkList(Powerups.clocks, function()
    collectedClock = true
  end)
  checkList(Powerups.phaseShifts, function()
    collectedPhaseShift = true
  end)
  checkList(Powerups.bolts, function()
    collectedBolt = true
  end)
  checkList(Powerups.scoreMultipliers, function()
    collectedScoreMultiplier = true
  end)
  checkList(Powerups.spawnRateBoosts, function()
    collectedSpawnRateBoost = true
  end)

  return collectedStar,
    collectedClock,
    collectedPhaseShift,
    collectedBolt,
    collectedScoreMultiplier,
    collectedSpawnRateBoost
end

return Powerups
