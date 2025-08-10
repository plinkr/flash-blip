-- powerups.lua

local Powerups = {}

local colors = require("colors")
local Vector = require("lib.vector")

-- Tabla para almacenar las estrellas activas
Powerups.stars = {}
-- Tabla para almacenar los relojes activos
Powerups.clocks = {}
Powerups.particles = {}

-- Temporizador para controlar la aparición de nuevos powerups
local spawnTimer = 0
-- Intervalo de tiempo aleatorio para la aparición de un nuevo powerup
local spawnInterval = love.math.random(5, 10)
-- Tipo de powerup que aparecerá ("star" o "clock")
local nextPowerupType = "star"

-- Función para dibujar una estrella
local function drawStar(x, y, r, rotation)
  love.graphics.push()
  love.graphics.translate(x, y)
  love.graphics.rotate(rotation)

  local points = {}
  local spikes = 5
  local outerRadius = r
  local innerRadius = r * 0.4
  local angleStep = 2 * math.pi / (spikes * 2)

  -- Generar puntos de la estrella
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
local function drawClock(x, y, r, rotation)
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

-- Función para crear una nueva estrella
function Powerups.spawnStar()
  local star = {
    pos = Vector:new(love.math.random(2.5, 97.5), -2.5), -- Coordenadas en la escala del juego (100x100)
    radius = 3, -- Radio en la escala del juego
    speed = love.math.random(6, 12),
    color = colors.yellow,
    life = 1,
    rotation = 0,
  }
  table.insert(Powerups.stars, star)
end

-- Función para crear un nuevo reloj powerup
function Powerups.spawnClock()
  local clock = {
    pos = Vector:new(love.math.random(2.5, 97.5), -2.5),
    radius = 3,
    speed = love.math.random(6, 12),
    color = colors.cyan_glow,
    life = 1,
    rotation = 0,
  }
  table.insert(Powerups.clocks, clock)
end

-- Crear partículas
function Powerups.particle(position, color, count, speed, angle, angleWidth)
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

-- Función de utilidad para eliminar elementos de una tabla que cumplen una condición.
function remove(tbl, predicate)
  local i = #tbl
  while i >= 1 do
    if predicate(tbl[i]) then
      table.remove(tbl, i)
    end
    i = i - 1
  end
end

-- Actualiza la lógica de las estrellas
function Powerups.update(dt, gameState)
  if gameState == "gameOver" then
    return
  end
  -- Lógica para la aparición de estrellas
  spawnTimer = spawnTimer + dt
  if spawnTimer > spawnInterval then
    if nextPowerupType == "star" then
      Powerups.spawnStar()
    else
      Powerups.spawnClock()
    end
    spawnTimer = 0
    spawnInterval = love.math.random(7, 12) -- Siguiente powerup en un tiempo aleatorio
    if love.math.random() > 0.60 then -- 40% de probabilidad de que el siguiente sea una estrella
      nextPowerupType = "star"
    else
      nextPowerupType = "clock"
    end
  end

  -- Mueve los powerups y sus partículas
  for i = #Powerups.stars, 1, -1 do
    local star = Powerups.stars[i]
    star.pos.y = star.pos.y + star.speed * dt
    star.rotation = star.rotation + dt * 2
    -- Crear estela de partículas
    Powerups.particle(star.pos, colors.apricot_glow, 1, 0.5, -math.pi / 2, 0.5)

    -- Eliminar estrellas que salen de la pantalla
    if star.pos.y > 100 + star.radius then -- Límite de la pantalla del juego
      table.remove(Powerups.stars, i)
    end
  end

  for i = #Powerups.clocks, 1, -1 do
    local clock = Powerups.clocks[i]
    clock.pos.y = clock.pos.y + clock.speed * dt
    clock.rotation = clock.rotation + dt * 2
    -- Crear estela de partículas
    Powerups.particle(clock.pos, colors.cyan_glow, 1, 0.5, -math.pi / 2, 0.5)

    -- Eliminar relojes que salen de la pantalla
    if clock.pos.y > 100 + clock.radius then -- Límite de la pantalla del juego
      table.remove(Powerups.clocks, i)
    end
  end

  -- Actualiza las partículas
  remove(Powerups.particles, function(p)
    p.pos:add(p.vel:copy():mul(dt * 60)) -- Asegura movimiento consistente
    p.life = p.life - 1
    return p.life <= 0
  end)
end

-- Dibuja las estrellas y sus partículas
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

  -- Dibujar las estrellas
  for _, star in ipairs(Powerups.stars) do
    love.graphics.setColor(star.color[1], star.color[2], star.color[3], 1)
    drawStar(star.pos.x, star.pos.y, star.radius, star.rotation)
  end

  -- Dibujar los relojes
  for _, clock in ipairs(Powerups.clocks) do
    love.graphics.setColor(clock.color[1], clock.color[2], clock.color[3], 1)
    drawClock(clock.pos.x, clock.pos.y, clock.radius, clock.rotation)
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
function Powerups.activatePlayerPing(playerPos)
  ping = {
    pos = playerPos:copy(),
    radius = 0,
    maxRadius = 30, -- Radio del ping en la escala del juego
    speed = 40,
    life = 1,
  }
end

function Powerups.checkCollisions(player)
  if not player then
    return false, false, false
  end

  local collectedStar = false
  local collectedClock = false

  -- Colisión directa del jugador con una estrella
  for i = #Powerups.stars, 1, -1 do
    local star = Powerups.stars[i]
    if circleCollision(player.position.x, player.position.y, 2.5, star.pos.x, star.pos.y, star.radius) then
      Powerups.particle(star.pos, colors.apricot_glow, 20, 2, 0, math.pi * 2) -- Explosión de partículas
      table.remove(Powerups.stars, i)
      collectedStar = true
    end
  end

  -- Colisión directa del jugador con un reloj
  for i = #Powerups.clocks, 1, -1 do
    local clock = Powerups.clocks[i]
    if circleCollision(player.position.x, player.position.y, 2.5, clock.pos.x, clock.pos.y, clock.radius) then
      Powerups.particle(clock.pos, colors.cyan_glow, 20, 2, 0, math.pi * 2) -- Explosión de partículas
      table.remove(Powerups.clocks, i)
      collectedClock = true
    end
  end

  -- Colisión del "ping" con una estrella
  if ping and ping.life > 0 then
    for i = #Powerups.stars, 1, -1 do
      local star = Powerups.stars[i]
      if circleCollision(ping.pos.x, ping.pos.y, ping.radius, star.pos.x, star.pos.y, star.radius) then
        Powerups.particle(star.pos, colors.apricot_glow, 20, 2, 0, math.pi * 2) -- Explosión de partículas
        table.remove(Powerups.stars, i)
        collectedStar = true
      end
    end
  end

  -- Colisión del "ping" con un reloj
  if ping and ping.life > 0 then
    for i = #Powerups.clocks, 1, -1 do
      local clock = Powerups.clocks[i]
      if circleCollision(ping.pos.x, ping.pos.y, ping.radius, clock.pos.x, clock.pos.y, clock.radius) then
        Powerups.particle(clock.pos, colors.cyan_glow, 20, 2, 0, math.pi * 2) -- Explosión de partículas
        table.remove(Powerups.clocks, i)
        collectedClock = true
      end
    end
  end

  return collectedStar, collectedClock
end

function Powerups.updatePing(dt)
  if ping and ping.life > 0 then
    ping.radius = ping.radius + ping.speed * dt
    if ping.radius >= ping.maxRadius then
      ping.life = 0 -- El ping desaparece al alcanzar su radio máximo
    end
  end
end

function Powerups.drawPing()
  if ping and ping.life > 0 then
    local alpha = math.max(0, 1 - (ping.radius / ping.maxRadius))
    love.graphics.setColor(colors.cyan[1], colors.cyan[2], colors.cyan[3], alpha * 0.8)
    love.graphics.circle("line", ping.pos.x, ping.pos.y, ping.radius, ping.radius / 2)
  end
end

return Powerups
