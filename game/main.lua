-- main.lua

--[[
FLASH-BLIP - Juego Pixel Art, para aprender LÖVE 2D.
--]]

-- overlayStats para depuración
local overlayStats = require("lib.overlayStats")
local moonshine = require("lib.shaders")

-- Definir un objeto Vector con métodos útiles.
local Vector = {}
Vector.__index = Vector

-- Crea una nueva instancia de Vector.
function Vector:new(x, y)
  return setmetatable({ x = x, y = y }, self)
end

-- Devuelve una copia del vector.
function Vector:copy()
  return Vector:new(self.x, self.y)
end

-- Suma otro vector al vector actual.
function Vector:add(otherVector)
  self.x = self.x + otherVector.x
  self.y = self.y + otherVector.y
  return self
end

-- Añade un vector definido por un ángulo y una longitud.
function Vector:addWithAngle(angle, length)
  self.x = self.x + math.cos(angle) * length
  self.y = self.y + math.sin(angle) * length
  return self
end

-- Rota el vector por un ángulo dado.
function Vector:rotate(angle)
  local cosAngle = math.cos(angle)
  local sinAngle = math.sin(angle)
  local newX = self.x * cosAngle - self.y * sinAngle
  local newY = self.x * sinAngle + self.y * cosAngle
  self.x = newX
  self.y = newY
  return self
end

-- Normaliza el vector (lo convierte en un vector unitario).
function Vector:normalize()
  local len = math.sqrt(self.x * self.x + self.y * self.y)
  if len > 0 then
    self.x = self.x / len
    self.y = self.y / len
  end
  return self
end

-- Multiplica el vector por un escalar.
function Vector:mul(scalar)
  self.x = self.x * scalar
  self.y = self.y * scalar
  return self
end

-- Resta otro vector y devuelve el resultado como un nuevo vector.
function Vector:sub(otherVector)
  return Vector:new(self.x - otherVector.x, self.y - otherVector.y)
end

-- Divide el vector por un escalar y devuelve el resultado como un nuevo vector.
function Vector:div(scalar)
  if scalar ~= 0 then
    return Vector:new(self.x / scalar, self.y / scalar)
  else
    return Vector:new(self.x, self.y) -- Devuelve una copia para evitar la división por cero.
  end
end

-- Devuelve la longitud (magnitud) del vector.
function Vector:length()
  return math.sqrt(self.x * self.x + self.y * self.y)
end

-- Devuelve la distancia a otro vector.
function Vector:distance(other)
  local dx = self.x - other.x
  local dy = self.y - other.y
  return math.sqrt(dx * dx + dy * dy)
end

-- Devuelve el ángulo del vector en radianes.
function Vector:angle()
  return math.atan2(self.y, self.x)
end

-- Función de conveniencia para crear un nuevo vector.
function vec(x, y)
  return Vector:new(x, y)
end

-- Genera un número aleatorio decimal en el rango [a, b).
function rnd(a, b)
  if b == nil then
    b = a
    a = 0
  end
  return love.math.random() * (b - a) + a
end

-- Genera un número aleatorio entero en el rango [a, b].
function rndi(a, b)
  return love.math.random(a, b)
end

-- Genera un número aleatorio en un rango simétrico [-a, a] o [a, b).
function rnds(a, b)
  if b == nil then
    return love.math.random() * (2 * a) - a
  else
    return love.math.random() * (b - a) + a
  end
end

-- Paleta de colores (valores de 0 a 1).
local colors = {
  cyan = { 0, 1, 1 },
  safety_orange = { 1, 0.392, 0 },
  sea_of_tears = { 0.059, 0.302, 0.659 },
  green_blob = { 0.204, 0.847, 0 },
  naranjaRojo = { 1, 0.25, 0 },
  white = { 1, 1, 1 },
  black = { 0, 0, 0 },
  red = { 1, 0, 0 },
  green = { 0, 1, 0 },
  yellow = { 1, 1, 0 },
  neon_lime_splash = { 0.478, 0.886, 0.345 },
  dark_blue = { 0.035, 0.047, 0.106 },
  light_blue = { 0.678, 0.847, 0.901 },
}

-- Variables globales del estado del juego.
local ticks
local difficulty
local score
local hiScore = 0
local gameState
local gameOverLine = nil
local flashLine = nil
local minCircleDist = 25
local restartDelayCounter = 0

-- Variables específicas de la lógica de FLASH-BLIP.
local circles
local circleAddDist
local lastCircle
local playerCircle
local particles
local gameCanvas

-- Cadena de efectos de post-procesamiento.
local effects

-- Carga y configura la fuente personalizada.
local CustomFont = require("font")
CustomFont:init() -- Calcula el ancho de los glifos.

-- Estado del modo de atracción (pantalla de inicio).
local attractMode = true
local attractInstructionTimer = 0
local attractInstructionVisible = true

-- Activa las estadísticas de depuración (se puede alternar con F3).
local isDebugEnabled = true

-- Configuración inicial de la ventana y carga de recursos.
function love.load()
  love.window.setTitle("FLASH-BLIP")
  love.window.setMode(800, 800) -- La resolución interna es de 100x100 píxeles.
  love.math.setRandomSeed(27)

  sounds = {}
  generateSound("explosion")
  generateSound("blip")

  love.graphics.setBackgroundColor(colors.dark_blue)
  -- love.graphics.setDefaultFilter("nearest", "nearest")

  gameCanvas = love.graphics.newCanvas(800, 800)
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

  if isDebugEnabled then
    overlayStats.load()
  end
end

-- Función para inicializar o reiniciar las variables del juego.
function initGame()
  ticks = 0
  difficulty = 1
  score = 0
  gameState = attractMode and "attract" or "playing"
  gameOverLine = nil

  -- Inicialización de variables de la mecánica del juego.
  circles = {}
  particles = {}
  circleAddDist = 0
  lastCircle = nil
  playerCircle = nil

  attractInstructionTimer = 0
  attractInstructionVisible = true
  justPressed = false
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

-- Reproduce un sonido por su nombre.
function play(name)
  local sound = sounds[name]
  if sound then
    sound:stop()
    sound:play()
  end
end

-- Genera una onda de sonido de forma procedural.
function generateSound(name)
  local soundParams = {
    blip = { startFreq = 800, endFreq = 1600, duration = 0.07, volume = 0.4 },
    explosion = { startFreq = 200, endFreq = 50, duration = 0.2, volume = 1 },
  }

  local params = soundParams[name]
  if not params then
    return
  end

  local sampleRate = 44100
  local bitDepth = 16
  local channels = 1
  local sampleCount = math.floor(sampleRate * params.duration)
  local soundData = love.sound.newSoundData(sampleCount, sampleRate, bitDepth, channels)

  for i = 0, sampleCount - 1 do
    local time = i / sampleRate
    local freq
    if name == "blip" then
      freq = params.startFreq + (params.endFreq - params.startFreq) * (time / params.duration)
    else
      freq = params.startFreq * ((params.endFreq / params.startFreq) ^ (time / params.duration))
    end
    local value = math.sin(2 * math.pi * freq * time) > 0 and params.volume or -params.volume
    soundData:setSample(i, value)
  end

  sounds[name] = love.audio.newSource(soundData)
end

-- Añade puntos al score si no se está en modo atracción.
function addScore(value)
  if not attractMode then
    score = score + value
  end
end

-- Crea partículas en una posición dada.
function particle(position, count, speed, angle, angleWidth)
  count = count or 1
  for _ = 1, count do
    local particleAngle = angle + rnds(angleWidth or 0)
    table.insert(particles, {
      pos = position:copy(),
      vel = vec(math.cos(particleAngle) * speed, math.sin(particleAngle) * speed),
      life = rnd(10, 20),
    })
  end
end

-- Añade un nuevo círculo al juego.
function addCircle()
  local radius = rnd(20, 30)

  -- Asegura una distancia mínima con el círculo del jugador.
  local yPos = -radius
  if playerCircle then
    yPos = math.min(yPos, playerCircle.position.y - minCircleDist)
  end

  local newCircle = {
    position = vec(rnd(20, 80), yPos),
    radius = radius,
    obstacleCount = rndi(1, 3), -- 1, 2, o 3 rectángulos.
    angle = rnd(math.pi * 2),
    angularVelocity = rnds(0.005, 0.015) * difficulty, -- Velocidad de rotación.
    obstacleLength = rnd(15, 25),
    next = nil,
  }

  if lastCircle ~= nil then
    lastCircle.next = newCircle
  end
  if playerCircle == nil then
    playerCircle = newCircle
  end
  lastCircle = newCircle
  table.insert(circles, newCircle)
end

-- Verifica si un segmento de línea colisiona con un rectángulo rotado.
function checkLineRotatedRectCollision(lineP1, lineP2, rectCenter, rectWidth, rectHeight, rectAngle)
  -- Transforma la línea al sistema de coordenadas local del rectángulo.
  local cosAngle = math.cos(-rectAngle)
  local sinAngle = math.sin(-rectAngle)

  local localP1x = (lineP1.x - rectCenter.x) * cosAngle - (lineP1.y - rectCenter.y) * sinAngle
  local localP1y = (lineP1.x - rectCenter.x) * sinAngle + (lineP1.y - rectCenter.y) * cosAngle
  local localP2x = (lineP2.x - rectCenter.x) * cosAngle - (lineP2.y - rectCenter.y) * sinAngle
  local localP2y = (lineP2.x - rectCenter.x) * sinAngle + (lineP2.y - rectCenter.y) * cosAngle

  -- Comprueba la colisión con un rectángulo alineado con los ejes (AABB).
  local halfW = rectWidth / 2
  local halfH = rectHeight / 2

  return lineAABBIntersect(localP1x, localP1y, localP2x, localP2y, -halfW, -halfH, halfW, halfH)
end

-- Algoritmo de intersección entre una línea y un AABB (Axis-Aligned Bounding Box).
function lineAABBIntersect(x1, y1, x2, y2, minX, minY, maxX, maxY)
  local dx = x2 - x1
  local dy = y2 - y1

  if math.abs(dx) < 1e-8 and math.abs(dy) < 1e-8 then
    return x1 >= minX and x1 <= maxX and y1 >= minY and y1 <= maxY
  end

  local t1, t2 = 0, 1

  if math.abs(dx) > 1e-8 then
    local invDx = 1 / dx
    local tx1 = (minX - x1) * invDx
    local tx2 = (maxX - x1) * invDx
    t1 = math.max(t1, math.min(tx1, tx2))
    t2 = math.min(t2, math.max(tx1, tx2))
  else
    if x1 < minX or x1 > maxX then
      return false
    end
  end

  if math.abs(dy) > 1e-8 then
    local invDy = 1 / dy
    local ty1 = (minY - y1) * invDy
    local ty2 = (maxY - y1) * invDy
    t1 = math.max(t1, math.min(ty1, ty2))
    t2 = math.min(t2, math.max(ty1, ty2))
  else
    if y1 < minY or y1 > maxY then
      return false
    end
  end

  return t1 <= t2
end

-- Reinicia el juego desde la pantalla de Game Over.
function restartGame()
  if gameState == "gameOver" and (gameOverLine == nil or gameOverLine.timer <= 0) then
    initGame()
    restartDelayCounter = 10
  end
end

-- Variable para detectar una única pulsación.
local justPressed = false
function love.keypressed(key)
  if (key == "space" or key == "return") and attractMode then
    attractMode = false
    initGame()
    return
  end

  if key == "space" or key == "return" then
    if gameState ~= "gameOver" then
      justPressed = true
    end
  end

  if key == "r" then
    initGame()
  end
  if key == "escape" then
    love.event.quit()
  end
  if isDebugEnabled then
    overlayStats.handleKeyboard(key)
  end
end

function love.mousepressed(x, y, button)
  if button == 1 and attractMode then
    attractMode = false
    initGame()
    return
  end

  if button == 1 then
    if gameState ~= "gameOver" then
      justPressed = true
    end
  end
end

-- Actualiza la dificultad según el score
function updateDifficulty()
  difficulty = 1 + score * 0.001
end

function love.update(dt)
  -- Lógica para la línea de movimiento
  if flashLine and flashLine.timer > 0 then
    flashLine.timer = flashLine.timer - 1
  else
    flashLine = nil -- Elimina la línea cuando el temporizador expira.
  end

  if gameState == "gameOver" then
    if gameOverLine and gameOverLine.timer > 0 then
      gameOverLine.timer = gameOverLine.timer - 1
    end
    if
      (love.keyboard.isDown("space") or love.keyboard.isDown("return") or love.mouse.isDown(1))
      and (gameOverLine == nil or gameOverLine.timer <= 0)
    then
      restartGame()
    end
    if attractMode and (gameOverLine == nil or gameOverLine.timer <= 0) then
      initGame()
    end
    return
  end

  if restartDelayCounter > 0 then
    restartDelayCounter = restartDelayCounter - 1
    return
  end

  if attractMode then
    -- Simula una entrada de usuario para que el juego se ejecute solo en
    -- el modo de atracción.
    local clickChance = 0.01
    if playerCircle and playerCircle.position.y > 80 then
      clickChance = clickChance * 5 -- se multiplica por 5 la probabilidad del dar click
    end
    if math.random() < clickChance then
      justPressed = true
    end
  end

  ticks = ticks + 1
  updateDifficulty()

  if ticks == 1 then
    addCircle()
  end

  if circleAddDist <= 0 then
    addCircle()
    circleAddDist = circleAddDist + rnd(25, 45)
  end

  -- La velocidad de desplazamiento aumenta con la dificultad.
  local scrollSpeed = difficulty * 0.08
  if playerCircle then
    local playerY = playerCircle.position.y
    if playerY < 50 then
      -- El desplazamiento es más rápido cuando el jugador está cerca de la parte superior.
      scrollSpeed = scrollSpeed + (50 - playerY) * 0.02
    end
  end
  circleAddDist = circleAddDist - scrollSpeed
  addScore(scrollSpeed)

  -- Si el player se va del límite inferior de la pantalla, es game over
  if playerCircle and playerCircle.position.y > 99 then
    if not attractMode then
      play("explosion")
    end
    gameState = "gameOver"
    return
  end

  -- Actualiza los círculos y prepara la detección de colisiones futuras.
  local obstacles = {}
  remove(circles, function(circle)
    circle.position.y = circle.position.y + scrollSpeed
    if circle.position.y > 99 + circle.radius then
      return true -- Elimina el círculo si está fuera de la pantalla.
    end
    circle.angle = circle.angle + circle.angularVelocity

    -- Genera los obstáculos (rectángulos que orbitan los círculos).
    for i = 1, circle.obstacleCount do
      local obstacleAngle = circle.angle + (i * math.pi * 2) / circle.obstacleCount
      local rectCenter = vec(circle.position.x, circle.position.y):addWithAngle(obstacleAngle, circle.radius)
      table.insert(obstacles, {
        center = rectCenter,
        width = circle.obstacleLength,
        height = 3,
        angle = obstacleAngle + math.pi / 2, -- Perpendicular al radio para que la barra orbite.
      })
    end
    return false
  end)

  -- Actualiza el estado del jugador basado en la entrada del usuario.
  if playerCircle then
    if justPressed and playerCircle.next then
      local collision = false

      -- Verifica la colisión con todos los obstáculos.
      for _, obstacle in ipairs(obstacles) do
        if
          checkLineRotatedRectCollision(
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

      if collision then
        if not attractMode then
          play("explosion")
          gameState = "gameOver"
          gameOverLine = {
            p1 = playerCircle.position:copy(),
            p2 = playerCircle.next.position:copy(),
            timer = 60,
            width = 3,
          }
        end
      else -- Sin colisión, el jugador avanza al siguiente círculo.
        if not attractMode then
          play("blip")
        end
        local currentPos = playerCircle.position:copy()
        -- divido la distancia entre el player y el punto siguiente en 10 pedazos iguales
        local stepVector = (vec(playerCircle.next.position.x, playerCircle.next.position.y):sub(playerCircle.position)):div(
          10
        )
        local particleAngle = stepVector:angle()
        -- el rastro de partículas al hacer blip
        for i = 1, 10 do
          particle(currentPos, 4, 2, particleAngle + math.pi, 0.5)
          currentPos:add(stepVector)
        end
        -- Efecto de línea rápido entre el círculo de origen y el de destino.
        flashLine = {
          p1 = playerCircle.position:copy(),
          p2 = playerCircle.next.position:copy(),
          timer = 2, -- Duración de la línea en frames.
        }
        playerCircle = playerCircle.next
      end
    end
  end

  -- Actualiza las partículas y las elimina si su vida ha terminado.
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

function love.draw()
  love.graphics.setCanvas(gameCanvas)
  love.graphics.clear()

  -- Dibuja el juego (100x100)
  love.graphics.push()
  love.graphics.scale(8, 8) -- La pantalla del juego es de 100x100 píxeles, escalada 8x.

  -- Dibuja las partículas.
  for _, p in ipairs(particles) do
    local alpha = math.max(0, p.life / 20) -- La vida máxima es 20.
    love.graphics.setColor(colors.sea_of_tears[1], colors.sea_of_tears[2], colors.sea_of_tears[3], alpha)
    love.graphics.circle("fill", p.pos.x, p.pos.y, 0.5)
  end

  -- Dibuja los círculos y sus barras giratorias.
  for _, circle in ipairs(circles) do
    if circle == playerCircle or (playerCircle and circle == playerCircle.next) then
      love.graphics.setColor(colors.sea_of_tears)
    else
      love.graphics.setColor(colors.green_blob)
    end
    love.graphics.circle("fill", circle.position.x, circle.position.y, 1.5)

    -- Dibuja los obstáculos (rectángulos que orbitan).
    love.graphics.setColor(colors.safety_orange)
    for i = 1, circle.obstacleCount do
      local obstacleAngle = circle.angle + (i * math.pi * 2) / circle.obstacleCount
      local rectCenter = vec(circle.position.x, circle.position.y):addWithAngle(obstacleAngle, circle.radius)

      love.graphics.push()
      love.graphics.translate(rectCenter.x, rectCenter.y)
      love.graphics.rotate(obstacleAngle + math.pi / 2) -- Rota para que sea perpendicular al radio.
      -- dibuja los obstáculos que orbitan aldedor de los círculos
      love.graphics.rectangle("fill", -circle.obstacleLength / 2, -1.5, circle.obstacleLength, 3, 1.2, 1.2)
      love.graphics.pop()
    end
  end

  -- Dibuja al jugador (un círculo más grande).
  if playerCircle then
    love.graphics.setColor(colors.sea_of_tears)
    love.graphics.rectangle("fill", playerCircle.position.x - 2.5, playerCircle.position.y - 2.5, 5, 5, 1.6, 1.6)
  end

  -- Dibuja la línea de colisión en Game Over.
  if gameOverLine then
    love.graphics.setColor(colors.sea_of_tears)
    local angle = vec(gameOverLine.p2.x, gameOverLine.p2.y):sub(vec(gameOverLine.p1.x, gameOverLine.p1.y)):angle()
    local length = gameOverLine.p1:distance(gameOverLine.p2) + 2
    local width = gameOverLine.width or 2

    love.graphics.push()
    love.graphics.translate(gameOverLine.p1.x, gameOverLine.p1.y)
    love.graphics.rotate(angle)
    love.graphics.rectangle("fill", 0, -width / 2, length, width, width / 2, width / 2)
    love.graphics.pop()
  end

  -- Dibuja el efecto de línea de "blip".
  if flashLine then
    local dist = flashLine.p1:distance(flashLine.p2)
    local stepVector = vec(flashLine.p2.x, flashLine.p2.y):sub(flashLine.p1):normalize()
    local currentPos = flashLine.p1:copy()
    -- Dibuja círculos a lo largo de la línea para crear un efecto de movimiento.
    for i = 0, dist, 3 do -- Dibuja un círculo cada 3 píxeles.
      local alpha = i / dist -- Calcula la transparencia
      love.graphics.setColor(colors.sea_of_tears[1], colors.sea_of_tears[2], colors.sea_of_tears[3], alpha)
      love.graphics.rectangle("fill", currentPos.x - 2, currentPos.y - 2, 4, 4, 1.6, 1.6)
      currentPos:add(stepVector:copy():mul(3))
    end
  end

  love.graphics.pop()

  -- Dibuja la interfaz de usuario (UI).
  love.graphics.push()
  love.graphics.origin() -- Resetea cualquier transformación previa de escala
  if not attractMode then
    love.graphics.setColor(colors.white)
    CustomFont:drawText(tostring(math.floor(score)), 10, 10, 5)
    local hiScoreText = "HI: " .. math.floor(hiScore)
    local textWidth = CustomFont:getTextWidth(hiScoreText, 5)
    CustomFont:drawText(hiScoreText, 800 - textWidth - 10, 10, 5)
  end

  -- Dibuja la pantalla del modo de atracción.
  if attractMode then
    love.graphics.setColor(0, 0, 0, 0.2)
    love.graphics.rectangle("fill", 0, 0, 800, 800)
    love.graphics.setColor(colors.cyan)
    CustomFont:drawText("FLASH-BLIP", 60, 200, 10)

    love.graphics.setColor(colors.white)
    if attractInstructionVisible then
      CustomFont:drawText("PRESS SPACE OR CLICK TO BLIP", 55, 320, 4)
    end
    love.graphics.setColor(colors.neon_lime_splash)
    CustomFont:drawText("https://github.com/plinkr/flash-blip", 40, 450, 3)
    -- resetear el color para que al dibujar el canvas no se multipliquen los valores
    love.graphics.setColor(1, 1, 1, 1)

    attractInstructionTimer = attractInstructionTimer + 1
    if attractInstructionTimer > 30 then
      attractInstructionVisible = not attractInstructionVisible
      attractInstructionTimer = 0
    end
  end

  if gameState == "gameOver" and not attractMode then
    if not gameOverLine or gameOverLine.timer <= 0 then
      love.graphics.setColor(0, 0, 0, 0.65)
      love.graphics.rectangle("fill", 0, 0, 800, 800)
      love.graphics.setColor(colors.naranjaRojo)
      CustomFont:drawText("GAME OVER", 120, 300, 10)

      if score > hiScore then
        hiScore = score
      end
      love.graphics.setColor(colors.white)
      CustomFont:drawText("PRESS SPACE OR CLICK TO RESTART", 8, 420, 4)
    end
  end

  love.graphics.pop()

  -- Fin del dibujado en el canvas
  love.graphics.setCanvas()

  -- Dibuja el canvas en la pantalla aplicando los efectos de shader
  effects(function()
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.draw(gameCanvas)
  end)

  if isDebugEnabled then
    overlayStats.draw()
  end
end
