-- powerups.lua

local Powerups = {}

local colors = require("colors")
local Vector = require("lib.vector")

-- Tabla para almacenar las estrellas activas
Powerups.stars = {}
Powerups.particles = {}

-- Temporizador para controlar la aparición de nuevas estrellas
local spawnTimer = 0
-- Aparecerá una nueva estrella en un intervalo de tiempo aleatorio
local spawnInterval = love.math.random(5, 10)

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

-- Crear partículas
function Powerups.particle(position, count, speed, angle, angleWidth)
  count = count or 1
  for _ = 1, count do
    local particleAngle = angle + (love.math.random() * 2 - 1) * angleWidth
    table.insert(Powerups.particles, {
      pos = position:copy(),
      vel = Vector:new(math.cos(particleAngle) * speed, math.sin(particleAngle) * speed),
      life = love.math.random(15, 30),
      maxLife = 30,
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
    Powerups.spawnStar()
    spawnTimer = 0
    spawnInterval = love.math.random(8, 15) -- Siguiente estrella en un tiempo aleatorio
  end

  -- Mueve las estrellas y sus partículas
  for i = #Powerups.stars, 1, -1 do
    local star = Powerups.stars[i]
    star.pos.y = star.pos.y + star.speed * dt
    star.rotation = star.rotation + dt * 2
    -- Crear estela de partículas
    Powerups.particle(star.pos, 1, 0.5, -math.pi / 2, 0.5)

    -- Eliminar estrellas que salen de la pantalla
    if star.pos.y > 100 + star.radius then -- Límite de la pantalla del juego
      table.remove(Powerups.stars, i)
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
  -- Dibujar partículas de la estela
  for _, p in ipairs(Powerups.particles) do
    local alpha = math.max(0, p.life / p.maxLife)
    love.graphics.setColor(colors.apricot_glow[1], colors.apricot_glow[2], colors.apricot_glow[3], alpha)
    love.graphics.circle("fill", p.pos.x, p.pos.y, 0.25)
  end

  -- Dibujar las estrellas
  for _, star in ipairs(Powerups.stars) do
    love.graphics.setColor(star.color[1], star.color[2], star.color[3], 1)
    drawStar(star.pos.x, star.pos.y, star.radius, star.rotation)
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
    return false, false
  end

  local collectedStar = false
  -- Colisión directa del jugador con una estrella
  for i = #Powerups.stars, 1, -1 do
    local star = Powerups.stars[i]
    if circleCollision(player.position.x, player.position.y, 2.5, star.pos.x, star.pos.y, star.radius) then
      particle(star.pos, 20, 2, 0, math.pi * 2) -- Explosión de partículas
      table.remove(Powerups.stars, i)
      collectedStar = true
    end
  end

  -- Colisión del "ping" con una estrella
  if ping and ping.life > 0 then
    for i = #Powerups.stars, 1, -1 do
      local star = Powerups.stars[i]
      if circleCollision(ping.pos.x, ping.pos.y, ping.radius, star.pos.x, star.pos.y, star.radius) then
        particle(star.pos, 20, 2, 0, math.pi * 2) -- Explosión de partículas
        table.remove(Powerups.stars, i)
        collectedStar = true
      end
    end
  end

  return collectedStar
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
