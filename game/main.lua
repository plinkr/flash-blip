-- main.lua

--[[
FLASH-BLIP - Juego Pixel Art, para aprender LÖVE 2D.
--]]

-- overlayStats para depuración
local overlayStats = require("lib.overlayStats")
local moonshine = require("lib.shaders")
local Parallax = require("parallax")
local Vector = require("lib.vector")
local Powerups = require("powerups")
local colors = require("colors")
local Text = require("text")

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
local nuHiScore
local hiScoreFlashTimer = 0
local hiScoreFlashVisible = true
local previousGameState
local ignoreInputTimer = 0
local endGame

-- Variables para el Power-up
local isInvulnerable = false
local invulnerabilityTimer = 0
-- Variables para el Power-up de ralentización
local isSlowed = false
local slowMotionTimer = 0
local originalVelocities = {}
local originalSizes = {}
local isPhaseShiftActive = false
local phaseShiftTimer = 0
local phaseShiftTeleports = 0

-- Para el ping visual en el siguiente punto de salto
local jumpPings = {}
local lastNextCircle = nil

-- Variables específicas de la lógica de FLASH-BLIP.
local circles
local circleAddDist
local lastCircle
local playerCircle
local particles
local gameCanvas

-- Cadena de efectos de post-procesamiento.
local effects

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
  generateSound("star_powerup")
  generateSound("slowdown_powerup")
  generateSound("phaseshift_powerup")
  generateSound("teleport")

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
  Parallax.load()

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
  nuHiScore = false

  -- Reiniciar estado de powerups
  isInvulnerable = false
  invulnerabilityTimer = 0
  isSlowed = false
  slowMotionTimer = 0
  isPhaseShiftActive = false
  phaseShiftTimer = 0
  phaseShiftTeleports = 0
  originalVelocities = {}
  originalSizes = {}
  if Powerups and Powerups.stars then
    Powerups.stars = {}
    Powerups.clocks = {}
    Powerups.phaseShifts = {}
    Powerups.particles = {}
  end
  jumpPings = {}
end

function endGame()
  if gameState == "gameOver" then
    return
  end
  gameState = "gameOver"
  if not attractMode then
    if score > hiScore then
      hiScore = score
      nuHiScore = true
      hiScoreFlashVisible = true
    end
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
    star_powerup = { startFreq = 1000, endFreq = 2000, duration = 0.15, volume = 0.6 },
    slowdown_powerup = { startFreq = 2000, endFreq = 1000, duration = 0.15, volume = 0.6 },
    phaseshift_powerup = { startFreq = 500, endFreq = 2500, duration = 0.2, volume = 0.6 },
    teleport = { startFreq = 1500, endFreq = 800, duration = 0.1, volume = 0.7 },
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
function particle(position, count, speed, angle, angleWidth, color)
  count = count or 1
  for _ = 1, count do
    local particleAngle = angle + rnds(angleWidth or 0)
    table.insert(particles, {
      pos = position:copy(),
      vel = vec(math.cos(particleAngle) * speed, math.sin(particleAngle) * speed),
      life = rnd(10, 20),
      color = color or colors.periwinkle_mist,
    })
  end
end
-- Hacer la función global para que otros módulos puedan acceder a ella
_G.particle = particle

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
    isPassed = false, -- Estado para saber si el jugador ha pasado por este círculo
  }

  if isSlowed then
    newCircle.angularVelocity = rnds(0.005, 0.015) -- Velocidad angular base fija.
    newCircle.obstacleLength = newCircle.obstacleLength * 0.5 -- Tamaño reducido.
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
    if gameState == "help" then
      gameState = previousGameState
    elseif gameState ~= "gameOver" then
      justPressed = true
    end
  end

  if key == "r" then
    initGame()
  end
  if key == "escape" then
    love.event.quit()
  end

  if key == "p" and playerCircle and gameState == "playing" then
    Powerups.activatePlayerPing(playerCircle.position, isPhaseShiftActive)
  end

  if isDebugEnabled then
    overlayStats.handleKeyboard(key)
  end

  if key == "h" then
    if gameState ~= "help" then
      previousGameState = gameState
      gameState = "help"
    else
      gameState = previousGameState
    end
    ignoreInputTimer = 0.1
  end
end

function love.mousepressed(x, y, button)
  if button == 1 and attractMode and gameState ~= "help" then
    attractMode = false
    initGame()
    return
  end

  if button == 1 then
    if gameState == "help" then
      gameState = previousGameState
      ignoreInputTimer = 0.1
    elseif gameState ~= "gameOver" then
      justPressed = true
    end
  end

  if button == 2 and playerCircle and gameState == "playing" then
    Powerups.activatePlayerPing(playerCircle.position, isPhaseShiftActive)
  end
end

-- Actualiza la dificultad según el score
function updateDifficulty()
  difficulty = 1 + score * 0.001
end

function love.update(dt)
  if ignoreInputTimer > 0 then
    ignoreInputTimer = ignoreInputTimer - dt
    if ignoreInputTimer < 0 then
      ignoreInputTimer = 0
    end
  end

  Parallax.update(dt, gameState)
  Powerups.update(dt, gameState)
  Powerups.updatePing(dt, isPhaseShiftActive)
  Powerups.updateLingeringPings(dt)
  updatePings(dt)

  -- Actualizar temporizador de invulnerabilidad
  if isInvulnerable and gameState ~= "help" then
    invulnerabilityTimer = invulnerabilityTimer - dt
    if invulnerabilityTimer <= 0 then
      isInvulnerable = false
    end
  end

  -- Actualizar temporizador de ralentización
  if isSlowed and gameState ~= "help" then
    slowMotionTimer = slowMotionTimer - dt
    if slowMotionTimer <= 0 then
      isSlowed = false
      -- Restaurar velocidades originales de los obstáculos
      for i, circle in ipairs(circles) do
        if originalVelocities[circle] then
          circle.angularVelocity = originalVelocities[circle]
        end
        if originalSizes[circle] then
          circle.obstacleLength = originalSizes[circle]
        end
      end
      originalVelocities = {} -- Limpiar la tabla
      originalSizes = {}
    end
  end

  -- Actualizar temporizador de phase shift
  if isPhaseShiftActive and gameState ~= "help" then
    phaseShiftTimer = phaseShiftTimer - dt
    if phaseShiftTimer <= 0 then
      isPhaseShiftActive = false
    end
  end

  -- Lógica para la línea de movimiento
  if flashLine and flashLine.timer > 0 then
    flashLine.timer = flashLine.timer - 1
  else
    flashLine = nil -- Elimina la línea cuando el temporizador expira.
  end

  if nuHiScore then
    hiScoreFlashTimer = hiScoreFlashTimer + dt
    if hiScoreFlashTimer > 0.8 then
      hiScoreFlashVisible = not hiScoreFlashVisible
      hiScoreFlashTimer = 0
    end
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

  if gameState == "help" then
    return -- Pausar la lógica del juego
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

  -- Aplica el efecto de ralentización del power-up del reloj
  if isSlowed then
    local playerY = playerCircle and playerCircle.position.y or 0
    -- Si el jugador está en el 80% superior de la pantalla, la velocidad de scroll es normal.
    if playerY < 80 then
      -- No se aplica reducción de velocidad para permitir que la pantalla se ponga al día.
    else
      -- El jugador está en el 20% inferior, se reduce la velocidad de scroll.
      scrollSpeed = scrollSpeed * 0.10 -- El jugador baja a un 10% de la velocidad normal
    end
  end
  circleAddDist = circleAddDist - scrollSpeed
  addScore(scrollSpeed)

  -- Si el player se va del límite inferior de la pantalla, es game over
  if playerCircle and playerCircle.position.y > 99 then
    if not attractMode then
      play("explosion")
    end
    endGame()
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
    local didTeleport = false
    if isPhaseShiftActive and playerCircle.next and ignoreInputTimer <= 0 then
      if Powerups.checkPingConnection(jumpPings) then
        if not attractMode then
          play("teleport")
        end
        -- Teletransporte instantáneo
        particle(playerCircle.position, 20, 3, 0, math.pi * 2, colors.emerald_shade) -- Origen
        particle(playerCircle.next.position, 20, 3, 0, math.pi * 2, colors.emerald_shade) -- Destino
        playerCircle.isPassed = true -- Marcar el círculo como pasado
        playerCircle = playerCircle.next
        didTeleport = true
        Powerups.consumePing() -- Función para invalidar el ping
      end
    end

    if not didTeleport and justPressed and playerCircle.next and ignoreInputTimer <= 0 then
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

      if collision and not isInvulnerable then
        if not attractMode then
          play("explosion")
          endGame()
          gameOverLine = {
            p1 = playerCircle.position:copy(),
            p2 = playerCircle.next.position:copy(),
            timer = 60,
            width = 3,
          }
        end
      else -- Sin colisión (o invulnerable), el jugador avanza al siguiente círculo.
        if not attractMode then
          play("blip")
        end
        local currentPos = playerCircle.position:copy()
        local blipColor = colors.periwinkle_mist
        if isPhaseShiftActive then
          blipColor = colors.emerald_shade
        end
        -- divido la distancia entre el player y el punto siguiente en 10 pedazos iguales
        local stepVector = (vec(playerCircle.next.position.x, playerCircle.next.position.y):sub(playerCircle.position)):div(
          10
        )
        local particleAngle = stepVector:angle()
        -- el rastro de partículas al hacer blip
        for i = 1, 10 do
          particle(currentPos, 4, 2, particleAngle + math.pi, 0.5, blipColor)
          currentPos:add(stepVector)
        end
        -- Efecto de línea rápido entre el círculo de origen y el de destino.
        flashLine = {
          p1 = playerCircle.position:copy(),
          p2 = playerCircle.next.position:copy(),
          timer = 2, -- Duración de la línea en frames.
        }
        playerCircle.isPassed = true -- Marcar el círculo como pasado
        playerCircle = playerCircle.next
      end
    end
  end

  if playerCircle and playerCircle.next and playerCircle.next ~= lastNextCircle then
    activateJumpPing(playerCircle.next, colors.periwinkle_mist)
    lastNextCircle = playerCircle.next
  elseif not playerCircle or not playerCircle.next then
    lastNextCircle = nil
    jumpPings = {} -- Limpiar pings si no hay siguiente círculo
  end

  -- Comprobar colisión con power-ups
  local collectedStar, collectedClock, collectedPhaseShift = Powerups.checkCollisions(playerCircle)
  if collectedStar and not attractMode then
    isInvulnerable = true
    invulnerabilityTimer = 10 -- segundos de invulnerabilidad
    play("star_powerup")
  end

  if collectedClock and not attractMode then
    isSlowed = true
    slowMotionTimer = 10 -- segundos de ralentización
    play("slowdown_powerup") -- Un sonido diferente para este power-up

    -- Ralentizar los obstáculos actuales
    originalVelocities = {} -- Limpiar velocidades anteriores
    originalSizes = {}
    for i, circle in ipairs(circles) do
      originalVelocities[circle] = circle.angularVelocity
      -- Establecer una velocidad angular base fija, no un factor de la actual.
      -- Esto simula la velocidad que tendrían los obstáculos con dificultad 1.
      circle.angularVelocity = rnds(0.005, 0.015)

      originalSizes[circle] = circle.obstacleLength
      circle.obstacleLength = circle.obstacleLength * 0.5 -- Reducir el tamaño a la mitad
    end
  end

  if collectedPhaseShift and not attractMode then
    isPhaseShiftActive = true
    phaseShiftTimer = 10 -- duración en segundos de phase shift
    play("phaseshift_powerup")
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
    if isInvulnerable then
      love.graphics.setColor(colors.yellow[1], colors.yellow[2], colors.yellow[3], alpha)
    else
      love.graphics.setColor(p.color[1], p.color[2], p.color[3], alpha)
    end
    love.graphics.circle("fill", p.pos.x, p.pos.y, 0.5)
  end

  -- Dibuja los círculos y sus barras giratorias.
  for _, circle in ipairs(circles) do
    if isPhaseShiftActive and (circle == playerCircle or (playerCircle and circle == playerCircle.next)) then
      love.graphics.setColor(colors.emerald_shade)
    elseif circle == playerCircle or (playerCircle and circle == playerCircle.next) then
      love.graphics.setColor(colors.periwinkle_mist)
    elseif circle.isPassed then
      love.graphics.setColor(colors.rusty_cedar_transparent)
    else
      love.graphics.setColor(colors.rusty_cedar)
    end
    if not (isInvulnerable and circle == playerCircle) then
      love.graphics.circle("fill", circle.position.x, circle.position.y, 1.5)
    end

    -- Dibuja los obstáculos (rectángulos que orbitan).
    if isSlowed then
      love.graphics.setColor(colors.light_blue_glow) -- Color "frío" para indicar ralentización
    else
      love.graphics.setColor(colors.safety_orange)
    end
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
    if isInvulnerable then
      -- Efecto visual de invulnerabilidad (parpadeo)
      local alpha = 0.6 + math.sin(love.timer.getTime() * 20) * 0.4
      love.graphics.setColor(colors.yellow[1], colors.yellow[2], colors.yellow[3], alpha)
    elseif isPhaseShiftActive then
      love.graphics.setColor(colors.emerald_shade)
    else
      love.graphics.setColor(colors.periwinkle_mist)
    end
    love.graphics.rectangle("fill", playerCircle.position.x - 2.5, playerCircle.position.y - 2.5, 5, 5, 1.6, 1.6)
  end

  -- Dibuja la línea de colisión en Game Over.
  if gameOverLine then
    if isPhaseShiftActive then
      love.graphics.setColor(colors.emerald_shade)
    else
      love.graphics.setColor(colors.periwinkle_mist)
    end
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
      if isInvulnerable then
        love.graphics.setColor(colors.yellow[1], colors.yellow[2], colors.yellow[3], alpha)
      elseif isPhaseShiftActive then
        love.graphics.setColor(colors.emerald_shade[1], colors.emerald_shade[2], colors.emerald_shade[3], alpha)
      else
        love.graphics.setColor(colors.periwinkle_mist[1], colors.periwinkle_mist[2], colors.periwinkle_mist[3], alpha)
      end
      love.graphics.rectangle("fill", currentPos.x - 2, currentPos.y - 2, 4, 4, 1.6, 1.6)
      currentPos:add(stepVector:copy():mul(3))
    end
  end

  Powerups.draw(gameState)

  love.graphics.pop()

  -- Dibuja la interfaz de usuario (UI).
  love.graphics.push()
  love.graphics.origin() -- Resetea cualquier transformación previa de escala
  if not attractMode then
    Text:drawScore(score, hiScore)
  end

  -- Dibuja la pantalla del modo de atracción.
  if attractMode then
    Text:drawAttract(attractInstructionVisible)
    attractInstructionTimer = attractInstructionTimer + 1
    if attractInstructionTimer > 60 then
      attractInstructionVisible = not attractInstructionVisible
      attractInstructionTimer = 0
    end
  end

  if gameState == "gameOver" and not attractMode then
    if not gameOverLine or gameOverLine.timer <= 0 then
      Text:drawGameOver(score, hiScore, nuHiScore, hiScoreFlashVisible)
    end
  end

  love.graphics.pop()

  -- Fin del dibujado en el canvas
  love.graphics.setCanvas()

  -- Dibuja el canvas en la pantalla aplicando los efectos de shader
  effects(function()
    love.graphics.setColor(1, 1, 1, 1)
    Parallax.draw()

    love.graphics.draw(gameCanvas)

    love.graphics.push()
    love.graphics.scale(8, 8) -- Escalar para el ping
    Powerups.drawPing(isPhaseShiftActive)
    drawPings()
    love.graphics.pop()
    if gameState == "help" then
      Text:drawHelpScreen()
    end
  end)

  if isDebugEnabled then
    overlayStats.draw()
  end
end

-- Activa un ping visual en un círculo específico
function activateJumpPing(circle, color)
  jumpPings = {} -- Asegura que solo haya un ping a la vez
  table.insert(jumpPings, {
    circle = circle,
    radius = 0,
    maxRadius = 12,
    speed = 10,
    life = 1,
    color = color,
  })
end

-- Actualiza el estado de los pings de salto
function updatePings(dt)
  if gameState ~= "playing" then
    return
  end
  for i = #jumpPings, 1, -1 do
    local ping = jumpPings[i]
    local currentMaxRadius = isPhaseShiftActive and 18 or 12
    ping.speed = isPhaseShiftActive and 15 or 10

    ping.radius = ping.radius + ping.speed * dt
    if ping.radius >= currentMaxRadius then
      ping.radius = 0 -- Reinicia el radio para un efecto cíclico
    end
  end
end

-- Dibuja los pings de salto
function drawPings()
  if gameState ~= "playing" then
    return
  end
  for _, ping in ipairs(jumpPings) do
    if ping.life > 0 and ping.circle then
      local currentMaxRadius = isPhaseShiftActive and 18 or 12
      local color
      if ping.circle and ping.circle.isPassed then
        color = colors.rusty_cedar_transparent
      else
        color = isPhaseShiftActive and colors.emerald_shade or ping.color
      end
      local alpha = math.max(0, 1 - (ping.radius / currentMaxRadius))

      love.graphics.setColor(color[1], color[2], color[3], alpha * 0.8)
      love.graphics.setLineWidth(1.5)
      love.graphics.circle("line", ping.circle.position.x, ping.circle.position.y, ping.radius)
      love.graphics.setLineWidth(1)
    end
  end
end
