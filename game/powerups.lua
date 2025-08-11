-- powerups.lua

local Powerups = {}

local colors = require("colors")
local Vector = require("lib.vector")
local settings = require("settings")

-- Tablas de los powerups
Powerups.stars = {}
Powerups.clocks = {}
Powerups.phaseShifts = {}
Powerups.bolts = {}
Powerups.lightning = {}

Powerups.lingeringPings = {}
Powerups.particles = {}

-- Temporizador para controlar la aparición de nuevos powerups
local spawnTimer = 0
-- Intervalo de tiempo aleatorio para la aparición de un nuevo powerup
local spawnInterval = love.math.random(5, 10)
-- Tipo de powerup que aparecerá
local nextPowerupType = "star"

-- Función para dibujar una Star
function Powerups.drawStar(x, y, r, rotation)
  love.graphics.push()
  love.graphics.translate(x, y)
  love.graphics.rotate(rotation)

  local points = {}
  local spikes = 5
  local outerRadius = r
  local innerRadius = r * 0.4
  local angleStep = 2 * math.pi / (spikes * 2)

  -- Generar puntos de la Star
  for i = 0, 2 * spikes - 1 do
    local radius = (i % 2 == 0) and outerRadius or innerRadius
    local angle = i * angleStep - math.pi / 2
    table.insert(points, math.cos(angle) * radius)
    table.insert(points, math.sin(angle) * radius)
  end

  -- Usar triangulación para polígonos cóncavos
  local triangles = love.math.triangulate(points)

  -- Dibujar cada triángulo
  for i, triangle in ipairs(triangles) do
    love.graphics.polygon("fill", triangle)
  end

  love.graphics.pop()
end

-- Función para dibujar un reloj de arena
function Powerups.drawClock(x, y, r, rotation)
  love.graphics.push()
  love.graphics.translate(x, y)
  love.graphics.rotate(rotation)

  -- Dos triángulos opuestos para formar el reloj de arena
  local halfHeight = r
  local halfWidth = r * 0.75

  -- Triángulo superior
  local triangle_up = {
    -halfWidth,
    -halfHeight, -- Esquina superior izquierda
    halfWidth,
    -halfHeight, -- Esquina superior derecha
    0,
    0, -- Punta inferior
  }

  -- Triángulo inferior
  local triangle_bottom = {
    -halfWidth,
    halfHeight, -- Esquina inferior izquierda
    halfWidth,
    halfHeight, -- Esquina inferior derecha
    0,
    0, -- Punta superior
  }

  love.graphics.polygon("fill", triangle_up)
  love.graphics.polygon("fill", triangle_bottom)

  love.graphics.pop()
end

-- Función para dibujar el power-up "Phase Shift"
function Powerups.drawPhaseShift(x, y, r, rotation, lineWidth)
  love.graphics.push()
  love.graphics.translate(x, y)
  love.graphics.rotate(rotation)
  love.graphics.setLineWidth(lineWidth or 1)

  -- Dibuja dos flechas chevron apuntando una hacia la otra
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

-- Función para dibujar el power-up "Bolt"
function Powerups.drawBolt(x, y, r, rotation, lineWidth)
  love.graphics.push()
  love.graphics.translate(x, y)
  love.graphics.rotate(rotation)
  love.graphics.setLineWidth(lineWidth or 1)

  -- Forma de S triangular para el rayo
  local points = {
    -r * 0.2,
    -r, -- Punto de inicio superior
    r * 0.4,
    -r * 0.2, -- Esquina superior derecha
    -r * 0.4,
    r * 0.2, -- Esquina inferior izquierda
    r * 0.2,
    r, -- Punto final inferior
  }

  love.graphics.line(points)

  love.graphics.pop()
  love.graphics.setLineWidth(1)
end

-- Función para crear una nueva Star
function Powerups.spawnStar()
  local star = {
    pos = Vector:new(love.math.random(2.5, settings.INTERNAL_WIDTH - 2.5), -2.5), -- Coordenadas en la escala del juego (100x100)
    radius = 3, -- Radio en la escala del juego
    speed = love.math.random(6, 12),
    color = colors.yellow,
    life = 1,
    rotation = 0,
  }
  table.insert(Powerups.stars, star)
end

-- Función para crear un nuevo Clock
function Powerups.spawnClock()
  local clock = {
    pos = Vector:new(love.math.random(2.5, settings.INTERNAL_WIDTH - 2.5), -2.5),
    radius = 3,
    speed = love.math.random(6, 12),
    color = colors.cyan_glow,
    life = 1,
    rotation = 0,
  }
  table.insert(Powerups.clocks, clock)
end

-- Función para crear un nuevo Phase Shift
function Powerups.spawnPhaseShift()
  local phaseShift = {
    pos = Vector:new(love.math.random(2.5, settings.INTERNAL_WIDTH - 2.5), -2.5),
    radius = 4,
    speed = love.math.random(6, 12),
    color = colors.emerald_shade,
    life = 1,
    rotation = 0,
  }
  table.insert(Powerups.phaseShifts, phaseShift)
end

-- Función para crear un nuevo Bolt
function Powerups.spawnBolt()
  local bolt = {
    pos = Vector:new(love.math.random(2.5, settings.INTERNAL_WIDTH - 2.5), -2.5),
    radius = 4,
    speed = love.math.random(6, 12),
    color = colors.tangerine_blaze, -- Color inicial del rayo
    life = 1,
    rotation = 0,
  }
  table.insert(Powerups.bolts, bolt)
end

-- Crear partículas
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

function remove(tbl, predicate)
  local i = #tbl
  while i >= 1 do
    if predicate(tbl[i]) then
      table.remove(tbl, i)
    end
    i = i - 1
  end
end

-- Actualiza la lógica de los powerups
function Powerups.update(dt, gameState, isBoltActive)
  if gameState == "gameOver" or gameState == "help" then
    return
  end

  if isBoltActive then
    -- reset the line
    local source = { x = 0, y = settings.INTERNAL_HEIGHT * 0.9 }
    local target = { x = settings.INTERNAL_WIDTH, y = settings.INTERNAL_HEIGHT * 0.9 }
    Powerups.lightning.mainLine = { source, target }
    for i = 1, 10 do
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

  -- Lógica para la aparición de powerups
  spawnTimer = spawnTimer + dt
  if spawnTimer > spawnInterval then
    if nextPowerupType == "star" then
      Powerups.spawnStar()
    elseif nextPowerupType == "clock" then
      Powerups.spawnClock()
    elseif nextPowerupType == "phaseShift" then
      Powerups.spawnPhaseShift()
    else
      Powerups.spawnBolt()
    end
    spawnTimer = 0
    spawnInterval = love.math.random(7, 12) -- Siguiente powerup en un tiempo aleatorio
    local rand = love.math.random()
    if rand > 0.75 then -- 25% de probabilidad para la Star
      nextPowerupType = "star"
    elseif rand > 0.50 then -- 25% de probabilidad para el Clock
      nextPowerupType = "clock"
    elseif rand > 0.25 then -- 25% de probabilidad para el Phase Shift
      nextPowerupType = "phaseShift"
    else -- 25% de probabilidad para el Bolt
      nextPowerupType = "bolt"
    end
  end

  -- Mueve los powerups y sus partículas
  for i = #Powerups.stars, 1, -1 do
    local star = Powerups.stars[i]
    star.pos.y = star.pos.y + star.speed * dt
    star.rotation = star.rotation + dt * 2
    -- Crear estela de partículas
    Powerups.particle(star.pos, 1, 0.5, -math.pi / 2, 0.5, colors.yellow)

    -- Eliminar stars que salen de la pantalla
    if star.pos.y > settings.INTERNAL_HEIGHT + star.radius then -- Límite de la pantalla del juego
      table.remove(Powerups.stars, i)
    end
  end

  for i = #Powerups.clocks, 1, -1 do
    local clock = Powerups.clocks[i]
    clock.pos.y = clock.pos.y + clock.speed * dt
    clock.rotation = clock.rotation + dt * 2
    -- Crear estela de partículas
    Powerups.particle(clock.pos, 1, 0.5, -math.pi / 2, 0.5, colors.cyan_glow)

    -- Eliminar clocks que salen de la pantalla
    if clock.pos.y > settings.INTERNAL_HEIGHT + clock.radius then -- Límite de la pantalla del juego
      table.remove(Powerups.clocks, i)
    end
  end

  for i = #Powerups.phaseShifts, 1, -1 do
    local ps = Powerups.phaseShifts[i]
    ps.pos.y = ps.pos.y + ps.speed * dt
    ps.rotation = ps.rotation + dt * 1.5
    -- Crear estela de partículas
    Powerups.particle(ps.pos, 1, 0.5, -math.pi / 2, 0.5, colors.emerald_shade)

    -- Eliminar phase shifts que salen de la pantalla
    if ps.pos.y > settings.INTERNAL_HEIGHT + ps.radius then
      table.remove(Powerups.phaseShifts, i)
    end
  end

  for i = #Powerups.bolts, 1, -1 do
    local bolt = Powerups.bolts[i]
    bolt.pos.y = bolt.pos.y + bolt.speed * dt
    bolt.rotation = bolt.rotation + dt * 1.5
    -- Crear estela de partículas
    Powerups.particle(bolt.pos, 1, 0.5, -math.pi / 2, 0.5, colors.tangerine_blaze)

    -- Eliminar bolts que salen de la pantalla
    if bolt.pos.y > settings.INTERNAL_HEIGHT + bolt.radius then
      table.remove(Powerups.bolts, i)
    end
  end

  -- Actualiza las partículas
  remove(Powerups.particles, function(p)
    p.pos:add(p.vel:copy():mul(dt * 60)) -- Asegura movimiento consistente
    p.life = p.life - 1
    return p.life <= 0
  end)
end

-- Dibuja las Stars y sus partículas
function Powerups.draw(gameState)
  if gameState == "gameOver" then
    return
  end
  -- Dibujar partículas de la estela
  for _, p in ipairs(Powerups.particles) do
    local alpha = math.max(0, p.life / p.maxLife)
    love.graphics.setColor(p.color[1], p.color[2], p.color[3], alpha)
    love.graphics.circle("fill", p.pos.x, p.pos.y, 0.25)
  end

  -- Dibujar las Stars
  for _, star in ipairs(Powerups.stars) do
    love.graphics.setColor(star.color[1], star.color[2], star.color[3], 1)
    Powerups.drawStar(star.pos.x, star.pos.y, star.radius, star.rotation)
  end

  -- Dibujar los Clock
  for _, clock in ipairs(Powerups.clocks) do
    love.graphics.setColor(clock.color[1], clock.color[2], clock.color[3], 1)
    Powerups.drawClock(clock.pos.x, clock.pos.y, clock.radius, clock.rotation)
  end

  -- Dibujar los Phase Shifts
  for _, ps in ipairs(Powerups.phaseShifts) do
    love.graphics.setColor(ps.color[1], ps.color[2], ps.color[3], 1)
    Powerups.drawPhaseShift(ps.pos.x, ps.pos.y, ps.radius, ps.rotation, 1)
  end

  -- Dibujar los Bolts
  for _, bolt in ipairs(Powerups.bolts) do
    love.graphics.setColor(bolt.color[1], bolt.color[2], bolt.color[3], 1)
    Powerups.drawBolt(bolt.pos.x, bolt.pos.y, bolt.radius, bolt.rotation, 1)
  end

  love.graphics.setColor(1, 1, 1, 1)
end

function Powerups.drawLightning()
  if not Powerups.lightning.mainLine then
    return
  end

  local lightningColors = { colors.apricot_glow, colors.tangerine_blaze }

  for i = 1, #Powerups.lightning.mainLine - 1 do
    local start_point = Powerups.lightning.mainLine[i]
    local end_point = Powerups.lightning.mainLine[i + 1]

    -- Seleccionar un color aleatorio para cada segmento del rayo
    local color = lightningColors[love.math.random(1, #lightningColors)]
    if Powerups.lightning.isFlashing then
      color = Powerups.lightning.flashColor
    end

    love.graphics.setColor(color)
    love.graphics.line(start_point.x, start_point.y, end_point.x, end_point.y)
  end

  love.graphics.setColor(1, 1, 1, 1)
end

-- Función de colisión círculo-círculo
function circleCollision(x1, y1, r1, x2, y2, r2)
  local dx = x1 - x2
  local dy = y1 - y2
  local distance = math.sqrt(dx * dx + dy * dy)
  return distance < (r1 + r2)
end

-- Lógica de colisión y área de efecto
-- Variable para el "ping" de absorción
local ping = nil
function Powerups.activatePlayerPing(playerPos, isPhaseShiftActive)
  ping = {
    pos = playerPos:copy(),
    radius = 0,
    maxRadius = isPhaseShiftActive and (settings.INTERNAL_WIDTH / 1.2) or (settings.INTERNAL_WIDTH / 2.5), -- Radio del ping en la escala del juego
    speed = 40,
    life = 1,
    isPhaseShiftActive = isPhaseShiftActive,
  }
end

function Powerups.checkCollisions(player)
  if not player then
    return false, false, false, false
  end

  local collectedStar = false
  local collectedClock = false
  local collectedPhaseShift = false
  local collectedBolt = false

  -- Colisión directa del jugador con una Star
  for i = #Powerups.stars, 1, -1 do
    local star = Powerups.stars[i]
    if circleCollision(player.position.x, player.position.y, 2.5, star.pos.x, star.pos.y, star.radius) then
      Powerups.particle(star.pos, 20, 2, 0, math.pi * 2, colors.yellow) -- Explosión de partículas
      table.remove(Powerups.stars, i)
      collectedStar = true
    end
  end

  -- Colisión directa del jugador con un Clock
  for i = #Powerups.clocks, 1, -1 do
    local clock = Powerups.clocks[i]
    if circleCollision(player.position.x, player.position.y, 2.5, clock.pos.x, clock.pos.y, clock.radius) then
      Powerups.particle(clock.pos, 20, 2, 0, math.pi * 2, colors.cyan_glow) -- Explosión de partículas
      table.remove(Powerups.clocks, i)
      collectedClock = true
    end
  end

  -- Colisión directa del jugador con un Phase Shift
  for i = #Powerups.phaseShifts, 1, -1 do
    local ps = Powerups.phaseShifts[i]
    if circleCollision(player.position.x, player.position.y, 2.5, ps.pos.x, ps.pos.y, ps.radius) then
      Powerups.particle(ps.pos, 20, 2, 0, math.pi * 2, colors.emerald_shade)
      table.remove(Powerups.phaseShifts, i)
      collectedPhaseShift = true
    end
  end

  -- Colisión directa del jugador con un Bolt
  for i = #Powerups.bolts, 1, -1 do
    local bolt = Powerups.bolts[i]
    if circleCollision(player.position.x, player.position.y, 2.5, bolt.pos.x, bolt.pos.y, bolt.radius) then
      Powerups.particle(bolt.pos, 20, 2, 0, math.pi * 2, colors.tangerine_blaze)
      table.remove(Powerups.bolts, i)
      collectedBolt = true
    end
  end

  -- Colisión del "ping" con una Star
  if ping and ping.life > 0 then
    for i = #Powerups.stars, 1, -1 do
      local star = Powerups.stars[i]
      if circleCollision(ping.pos.x, ping.pos.y, ping.radius, star.pos.x, star.pos.y, star.radius) then
        Powerups.particle(star.pos, 20, 2, 0, math.pi * 2, colors.yellow) -- Explosión de partículas
        table.remove(Powerups.stars, i)
        collectedStar = true
      end
    end
  end

  -- Colisión del "ping" con un Clock
  if ping and ping.life > 0 then
    for i = #Powerups.clocks, 1, -1 do
      local clock = Powerups.clocks[i]
      if circleCollision(ping.pos.x, ping.pos.y, ping.radius, clock.pos.x, clock.pos.y, clock.radius) then
        Powerups.particle(clock.pos, 20, 2, 0, math.pi * 2, colors.cyan_glow) -- Explosión de partículas
        table.remove(Powerups.clocks, i)
        collectedClock = true
      end
    end
  end

  -- Colisión del "ping" con un Phase Shift
  if ping and ping.life > 0 then
    for i = #Powerups.phaseShifts, 1, -1 do
      local ps = Powerups.phaseShifts[i]
      if circleCollision(ping.pos.x, ping.pos.y, ping.radius, ps.pos.x, ps.pos.y, ps.radius) then
        Powerups.particle(ps.pos, 20, 2, 0, math.pi * 2, colors.emerald_shade)
        table.remove(Powerups.phaseShifts, i)
        collectedPhaseShift = true
      end
    end
  end

  -- Colisión del "ping" con un Bolt
  if ping and ping.life > 0 then
    for i = #Powerups.bolts, 1, -1 do
      local bolt = Powerups.bolts[i]
      if circleCollision(ping.pos.x, ping.pos.y, ping.radius, bolt.pos.x, bolt.pos.y, bolt.radius) then
        Powerups.particle(bolt.pos, 20, 2, 0, math.pi * 2, colors.tangerine_blaze)
        table.remove(Powerups.bolts, i)
        collectedBolt = true
      end
    end
  end

  -- colisión del ping persistente con powerups
  for i = #Powerups.lingeringPings, 1, -1 do
    local p = Powerups.lingeringPings[i]
    if p.life > 0 then
      -- colision con Star
      for j = #Powerups.stars, 1, -1 do
        local star = Powerups.stars[j]
        if circleCollision(p.pos.x, p.pos.y, p.radius, star.pos.x, star.pos.y, star.radius) then
          Powerups.particle(star.pos, 20, 2, 0, math.pi * 2, colors.yellow)
          table.remove(Powerups.stars, j)
          collectedStar = true
        end
      end
      -- colision con Clock
      for j = #Powerups.clocks, 1, -1 do
        local clock = Powerups.clocks[j]
        if circleCollision(p.pos.x, p.pos.y, p.radius, clock.pos.x, clock.pos.y, clock.radius) then
          Powerups.particle(clock.pos, 20, 2, 0, math.pi * 2, colors.cyan_glow)
          table.remove(Powerups.clocks, j)
          collectedClock = true
        end
      end
      -- colision con Phase Shifts
      for j = #Powerups.phaseShifts, 1, -1 do
        local ps = Powerups.phaseShifts[j]
        if circleCollision(p.pos.x, p.pos.y, p.radius, ps.pos.x, ps.pos.y, ps.radius) then
          Powerups.particle(ps.pos, 20, 2, 0, math.pi * 2, colors.emerald_shade)
          table.remove(Powerups.phaseShifts, j)
          collectedPhaseShift = true
        end
      end
      -- colision con Bolts
      for j = #Powerups.bolts, 1, -1 do
        local bolt = Powerups.bolts[j]
        if circleCollision(p.pos.x, p.pos.y, p.radius, bolt.pos.x, bolt.pos.y, bolt.radius) then
          Powerups.particle(bolt.pos, 20, 2, 0, math.pi * 2, colors.tangerine_blaze)
          table.remove(Powerups.bolts, j)
          collectedBolt = true
        end
      end
    end
  end

  return collectedStar, collectedClock, collectedPhaseShift, collectedBolt
end

function Powerups.addPoint(lightning, index)
  local x1 = lightning.mainLine[index].x
  local y1 = lightning.mainLine[index].y
  local x2 = lightning.mainLine[index + 1].x
  local y2 = lightning.mainLine[index + 1].y

  -- Posición fraccionaria del nuevo punto entre x1,y1 y x2,y2
  local t = 0.25 + 0.5 * math.random()
  local x = x1 + t * (x2 - x1)
  local y = y1 + t * (y2 - y1)

  -- Vector perpendicular al segmento (clockwise)
  local dx = x2 - x1
  local dy = y2 - y1
  local length = math.sqrt(dx * dx + dy * dy)
  if length == 0 then
    return
  end

  local perpX = dy / length
  local perpY = -dx / length

  -- Amplitud de la desviación (en proporción a la longitud total del rayo)
  local amplitud = 0.10 -- 10% de la longitud

  -- Desplazamiento aleatorio perpendicular
  local offset = (math.random() - 0.5) * 2 * amplitud * length
  x = x + perpX * offset
  y = y + perpY * offset

  table.insert(lightning.mainLine, index + 1, { x = x, y = y })
end

function Powerups.createLightning()
  local source = { x = 0, y = settings.INTERNAL_HEIGHT * 0.9 }
  local target = { x = settings.INTERNAL_WIDTH, y = settings.INTERNAL_HEIGHT * 0.9 }
  Powerups.lightning = {
    source = source,
    target = target,
    mainLine = { source, target },
    color = colors.tangerine_blaze,
    flashColor = colors.white,
    isFlashing = false,
    flashTimer = 0,
  }
end

function Powerups.checkLightningCollision(player)
  if not player or not Powerups.lightning.mainLine then
    return false
  end

  local playerY = player.position.y
  local netY = settings.INTERNAL_HEIGHT * 0.9

  if playerY >= netY then
    -- Collision detected
    Powerups.lightning.isFlashing = true
    Powerups.lightning.flashTimer = 0.2 -- Flash for 0.2 seconds
    return true
  end

  return false
end

function Powerups.updatePing(dt, isPhaseShiftActive)
  if ping and ping.life > 0 then
    local currentMaxRadius = isPhaseShiftActive and 60 or 30
    ping.radius = ping.radius + ping.speed * dt
    if ping.radius >= currentMaxRadius then
      ping.life = 0 -- El ping desaparece al alcanzar su radio máximo
    end
  end
end

function Powerups.updateLingeringPings(dt)
  for i = #Powerups.lingeringPings, 1, -1 do
    local p = Powerups.lingeringPings[i]
    if p.life > 0 then
      p.radius = p.radius + p.speed * dt
      if p.radius >= p.maxRadius then
        p.life = 0
      end
    else
      table.remove(Powerups.lingeringPings, i)
    end
  end
end

function Powerups.drawPing(isPhaseShiftActive)
  if ping and ping.life > 0 then
    local currentMaxRadius = isPhaseShiftActive and 60 or 30
    local alpha = math.max(0, 1 - (ping.radius / currentMaxRadius))
    local color = isPhaseShiftActive and colors.emerald_shade or colors.cyan

    love.graphics.setColor(color[1], color[2], color[3], alpha * 0.8)
    love.graphics.setLineWidth(1.5)
    love.graphics.circle("line", ping.pos.x, ping.pos.y, ping.radius)
    love.graphics.setLineWidth(1)
  end

  -- dibujar los pings persistentes
  for _, p in ipairs(Powerups.lingeringPings) do
    if p.life > 0 then
      local currentMaxRadius = p.isPhaseShiftActive and 60 or 30
      local alpha = math.max(0, 1 - (p.radius / currentMaxRadius))
      local color = p.isPhaseShiftActive and colors.emerald_shade or colors.cyan
      love.graphics.setColor(color[1], color[2], color[3], alpha * 0.8)
      love.graphics.setLineWidth(1.5)
      love.graphics.circle("line", p.pos.x, p.pos.y, p.radius)
      love.graphics.setLineWidth(1)
    end
  end
end

function Powerups.checkPingConnection(jumpPings)
  if ping and ping.life > 0 and jumpPings and #jumpPings > 0 then
    local jumpPing = jumpPings[1] -- Asumimos que solo hay un ping de salto a la vez
    if jumpPing.circle and jumpPing.life > 0 then
      -- Comprobar si los dos círculos de ping se solapan
      return circleCollision(
        ping.pos.x,
        ping.pos.y,
        ping.radius,
        jumpPing.circle.position.x,
        jumpPing.circle.position.y,
        jumpPing.radius
      )
    end
  end
  return false
end

function Powerups.consumePing()
  if ping then
    -- Mueve el ping a la lista de pings persistentes en lugar de destruirlo
    table.insert(Powerups.lingeringPings, ping)
    ping = nil -- Limpia el ping activo
  end
end

return Powerups
