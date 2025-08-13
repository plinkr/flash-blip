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
local settings = require("settings")
local Sound = require("sound")
local About = require("about")
local Help = require("help")

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

local ticks
local difficulty
local score
local hiScore = 0
-- La dificultad base siempre es 1.
local baseDifficulty = 1
local baseScrollSpeed = 0.08
local gameState
local gameOverLine = nil
local flashLine = nil
local minCircleDist = settings.INTERNAL_HEIGHT / 4
local restartDelayCounter = 0
local nuHiScore
local hiScoreFlashTimer = 0
local hiScoreFlashVisible = true
local previousGameState
local ignoreInputTimer = 0
local gameOverInputDelay = 0
local endGame
local isPaused = false

-- Variables para Power ups
local invulnerabilityTimer = 0
local isSlowed = false
local slowMotionTimer = 0
local originalVelocities = {}
local originalSizes = {}
local isPhaseShiftActive = false
local phaseShiftTimer = 0
local phaseShiftTeleports = 0
local isBoltActive = false
local boltTimer = 0
local isScoreMultiplierActive = false
local scoreMultiplierTimer = 0
local isSpawnRateBoostActive = false
local spawnRateBoostTimer = 0

-- Para el ping visual en el siguiente punto de salto
local jumpPings = {}
local lastNextCircle = nil

local circles
local circleAddDist
local lastCircle
local playerCircle
local particles
local gameCanvas

local effects

-- Estado del modo de atracción (pantalla de inicio).
local attractMode = true
local attractInstructionTimer = 0
local attractInstructionVisible = true
local helpScrollY = 0
local menuItems = {
  { text = "ENDLESS MODE", action = "start_endless" },
  { text = "ARCADE MODE", action = "start_arcade" },
  { text = "ABOUT", action = "show_about" },
  { text = "HELP", action = "show_help" },
}
if love.system.getOS() ~= "Web" then
  table.insert(menuItems, { text = "EXIT", action = "exit_game" })
end
local selectedMenuItem = 1
local pauseMenuItems = {
  { text = "RESUME", action = "resume" },
  { text = "RESTART", action = "restart" },
  { text = "HELP", action = "show_help" },
  { text = "QUIT TO MENU", action = "quit_to_menu" },
}
local selectedPauseMenuItem = 1

-- Activa las estadísticas de depuración (se puede alternar con F3).
local isDebugEnabled = true

-- Configuración inicial de la ventana y carga de recursos.
function love.load()
  love.window.setTitle("FLASH-BLIP")

  -- Calcular la resolución óptima para la pantalla actual
  local desktopWidth, desktopHeight = love.window.getDesktopDimensions()
  local scaleX = math.floor(desktopWidth / settings.INTERNAL_WIDTH)
  local scaleY = math.floor(desktopHeight / settings.INTERNAL_HEIGHT)
  settings.SCALE_FACTOR = math.min(scaleX, scaleY)

  settings.WINDOW_WIDTH = settings.INTERNAL_WIDTH * settings.SCALE_FACTOR
  settings.WINDOW_HEIGHT = settings.INTERNAL_HEIGHT * settings.SCALE_FACTOR

  love.window.setMode(settings.WINDOW_WIDTH, settings.WINDOW_HEIGHT, {
    resizable = false,
    vsync = true,
    highdpi = true,
  })

  -- Seed ramdom para hacer pruebas, quiza un en un futuro se pueda hacer levels usando esto
  -- love.math.setRandomSeed(27)

  Sound:load()

  love.graphics.setBackgroundColor(colors.dark_blue)
  -- love.graphics.setDefaultFilter("nearest", "nearest")

  gameCanvas = love.graphics.newCanvas(settings.WINDOW_WIDTH, settings.WINDOW_HEIGHT)
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
  About.load()
  Help.load()

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
  _G.isInvulnerable = false
  invulnerabilityTimer = 0
  isSlowed = false
  slowMotionTimer = 0
  isPhaseShiftActive = false
  phaseShiftTimer = 0
  phaseShiftTeleports = 0
  isBoltActive = false
  boltTimer = 0
  isScoreMultiplierActive = false
  scoreMultiplierTimer = 0
  isSpawnRateBoostActive = false
  spawnRateBoostTimer = 0
  originalVelocities = {}
  originalSizes = {}
  if Powerups then
    Powerups.stars = {}
    Powerups.clocks = {}
    Powerups.phaseShifts = {}
    Powerups.bolts = {}
    Powerups.scoreMultipliers = {}
    Powerups.spawnRateBoosts = {}
    Powerups.particles = {}
  end
  jumpPings = {}
end

function endGame()
  if gameState == "gameOver" then
    return
  end
  gameState = "gameOver"
  gameOverInputDelay = 3.0 -- 3 segundos de retraso
  if not attractMode then
    if score > hiScore then
      hiScore = score
      nuHiScore = true
      hiScoreFlashVisible = true
    end
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

function addScore(value)
  if not attractMode then
    local multiplier = isScoreMultiplierActive and 4 or 1
    score = score + (value * multiplier)
  end
end

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

function addCircle()
  local radius = rnd(20, 30)

  -- Asegura una distancia mínima con el círculo del jugador.
  local yPos = -radius
  if playerCircle then
    yPos = math.min(yPos, playerCircle.position.y - minCircleDist)
  end

  local newCircle = {
    position = vec(rnd(20, settings.INTERNAL_WIDTH - 20), yPos),
    radius = radius,
    obstacleCount = rndi(1, 3), -- 1, 2, o 3 obstáculos girando alrededor de los puntos.
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

function restartGame()
  if gameState == "gameOver" and (gameOverLine == nil or gameOverLine.timer <= 0) then
    initGame()
    restartDelayCounter = 10
  end
end

-- Variable para detectar una única pulsación.
local justPressed = false
function love.keypressed(key)
  if gameState == "attract" then
    if key == "up" then
      selectedMenuItem = math.max(1, selectedMenuItem - 1)
      Sound:play("blip")
    elseif key == "down" then
      selectedMenuItem = math.min(#menuItems, selectedMenuItem + 1)
      Sound:play("blip")
    elseif key == "return" or key == "space" then
      local action = menuItems[selectedMenuItem].action
      if action == "start_endless" then
        attractMode = false
        initGame()
      elseif action == "start_arcade" then
        -- Do nothing for now
      elseif action == "show_about" then
        previousGameState = "attract"
        gameState = "about"
      elseif action == "show_help" then
        previousGameState = gameState
        gameState = "help"
      elseif action == "exit_game" then
        love.event.quit()
      end
    end
  elseif gameState == "help" then
    Help.keypressed(key)
  elseif isPaused then
    if key == "up" then
      selectedPauseMenuItem = math.max(1, selectedPauseMenuItem - 1)
      Sound:play("blip")
    elseif key == "down" then
      selectedPauseMenuItem = math.min(#pauseMenuItems, selectedPauseMenuItem + 1)
      Sound:play("blip")
    elseif key == "return" then
      local action = pauseMenuItems[selectedPauseMenuItem].action
      if action == "resume" then
        isPaused = false
      elseif action == "restart" then
        isPaused = false
        initGame()
      elseif action == "show_help" then
        previousGameState = gameState
        gameState = "help"
      elseif action == "quit_to_menu" then
        isPaused = false
        attractMode = true
        initGame()
      end
    end
  elseif gameState == "playing" and (key == "space" or key == "return") then
    if not isPaused then
      justPressed = true
    end
  end

  if key == "r" then
    initGame()
  end

  if key == "escape" then
    if gameState == "help" or gameState == "about" then
      gameState = previousGameState or "attract"
    elseif isPaused then
      isPaused = false
    elseif gameState == "playing" then
      isPaused = true
    elseif gameState == "attract" then
      love.event.quit()
    end
  end

  if key == "p" and playerCircle and gameState == "playing" then
    Powerups.activatePlayerPing(playerCircle.position, isPhaseShiftActive)
  end

  if key == "up" and gameState == "help" then
    helpScrollY = math.max(0, helpScrollY - 20)
  elseif key == "down" and gameState == "help" then
    helpScrollY = math.min(300, helpScrollY + 20)
  end

  if isDebugEnabled then
    overlayStats.handleKeyboard(key)
  end
end

function love.wheelmoved(x, y)
  if gameState == "help" then
    Help.wheelmoved(x, y)
  end
end

function love.mousepressed(x, y, button)
  if ignoreInputTimer > 0 then
    return
  end

  if gameState == "about" then
    if button == 1 then
      gameState = previousGameState or "attract"
    end
    return
  end

  if gameState == "help" then
    if button == 1 then
      if previousGameState == "attract" then
        attractMode = true
        gameState = previousGameState
      else
        local came_from_pause = isPaused
        gameState = previousGameState
        if came_from_pause then
          isPaused = true
        end
      end
      return
    end
  end

  if button == 1 and gameState == "attract" then
    for i, item in ipairs(menuItems) do
      local itemWidth = Text:getTextWidth(item.text, 5)
      local itemX = (settings.WINDOW_WIDTH - itemWidth) / 2
      if x >= itemX and x <= itemX + itemWidth and y >= item.y and y <= item.y + item.height then
        selectedMenuItem = i
        Sound:play("blip")
        local action = item.action
        if action == "start_endless" then
          attractMode = false
          initGame()
        elseif action == "start_arcade" then
          -- Do nothing for now
        elseif action == "show_about" then
          if gameState == "playing" then
            isPaused = true
          end
          gameState = "about"
        elseif action == "show_help" then
          previousGameState = gameState
          if gameState == "playing" then
            isPaused = true
          end
          gameState = "help"
        elseif action == "exit_game" then
          love.event.quit()
        end
        return
      end
    end
    return
  elseif button == 1 and isPaused then
    for i, item in ipairs(pauseMenuItems) do
      local itemWidth = Text:getTextWidth(item.text, 5)
      local itemX = (settings.WINDOW_WIDTH - itemWidth) / 2
      if x >= itemX and x <= itemX + itemWidth and y >= item.y and y <= item.y + item.height then
        selectedPauseMenuItem = i
        Sound:play("blip")
        local action = pauseMenuItems[selectedPauseMenuItem].action
        if action == "resume" then
          isPaused = false
        elseif action == "restart" then
          isPaused = false
          initGame()
        elseif action == "show_help" then
          previousGameState = gameState
          gameState = "help"
        elseif action == "quit_to_menu" then
          isPaused = false
          attractMode = true
          initGame()
        end
        return
      end
    end
    return
  end

  if button == 1 then
    if gameState ~= "gameOver" and not isPaused then
      justPressed = true
    end
  end

  if button == 2 and playerCircle and gameState == "playing" then
    Powerups.activatePlayerPing(playerCircle.position, isPhaseShiftActive)
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
        color = isPhaseShiftActive and colors.emerald_shade
          or (isSlowed and colors.naranjaRojo_transparent or ping.color)
      end
      local alpha = math.max(0, 1 - (ping.radius / currentMaxRadius))

      love.graphics.setColor(color[1], color[2], color[3], alpha * 0.8)
      love.graphics.setLineWidth(1.5)
      love.graphics.circle("line", ping.circle.position.x, ping.circle.position.y, ping.radius)
      love.graphics.setLineWidth(1)
    end
  end
end

-- Dibuja el indicador visual para el Spawn Rate Boost
function drawSpawnRateIndicator()
  if gameState == "gameOver" then
    return
  end
  -- Crea un efecto de pulso suave usando el tiempo del juego
  local pulse = math.sin(love.timer.getTime() * 8) * 0.2 + 0.6 -- Pulsa entre 40% y 80% de opacidad
  local color = colors.neon_lime_splash

  love.graphics.setColor(color[1], color[2], color[3], pulse)

  -- Dibuja un rectángulo delgado en la parte superior de la pantalla
  love.graphics.rectangle("fill", 0, 0, settings.INTERNAL_WIDTH, 2.5)
end

function updateDifficulty()
  local ticksPerUnit = 3600 -- 3600 ticks = 1 minuto a 60 FPS
  local exponent = 1.25 -- Si es 1, la curva es lineal. Si es > 1, la curva se empina
  local scaleFactor = 1.5 -- Multiplicador general para controlar la intensidad.

  -- Calculamos cuántas "unidades de tiempo" han pasado.
  local timeUnits = ticks / ticksPerUnit

  -- La fórmula aplica el exponente a las unidades de tiempo.
  difficulty = baseDifficulty + (timeUnits ^ exponent) * scaleFactor
end

function love.update(dt)
  if isPaused then
    return
  end

  if ignoreInputTimer > 0 then
    ignoreInputTimer = ignoreInputTimer - dt
    if ignoreInputTimer < 0 then
      ignoreInputTimer = 0
    end
  end

  Parallax.update(dt, gameState)
  Powerups.update(dt, gameState, isBoltActive, isSpawnRateBoostActive)
  Powerups.updatePings(dt)
  updatePings(dt)

  -- Actualizar temporizador de invulnerabilidad
  if _G.isInvulnerable and gameState ~= "help" then
    invulnerabilityTimer = invulnerabilityTimer - dt
    if invulnerabilityTimer <= 0 then
      _G.isInvulnerable = false
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

  -- Actualizar temporizador de bolt
  if isBoltActive and gameState ~= "help" then
    boltTimer = boltTimer - dt
    if boltTimer <= 0 then
      isBoltActive = false
    end
  end

  -- Actualizar temporizador de multiplicador de score
  if isScoreMultiplierActive and gameState ~= "help" then
    scoreMultiplierTimer = scoreMultiplierTimer - dt
    if scoreMultiplierTimer <= 0 then
      isScoreMultiplierActive = false
    end
  end

  -- Actualizar temporizador de spawn rate boost
  if isSpawnRateBoostActive and gameState ~= "help" then
    spawnRateBoostTimer = spawnRateBoostTimer - dt
    if spawnRateBoostTimer <= 0 then
      isSpawnRateBoostActive = false
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
    if gameOverInputDelay > 0 then
      gameOverInputDelay = gameOverInputDelay - dt
    end
    if gameOverLine and gameOverLine.timer > 0 then
      gameOverLine.timer = gameOverLine.timer - 1
    end
    if
      (love.keyboard.isDown("space") or love.keyboard.isDown("return") or love.mouse.isDown(1))
      and (gameOverLine == nil or gameOverLine.timer <= 0)
      and gameOverInputDelay <= 0
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
    if playerCircle and playerCircle.position.y > (settings.INTERNAL_HEIGHT * 0.8) then
      clickChance = clickChance * 50 -- se multiplica por 50 la probabilidad del dar click
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
    circleAddDist = circleAddDist + rnd(settings.INTERNAL_HEIGHT * 0.25, settings.INTERNAL_HEIGHT * 0.45)
  end

  -- La velocidad de desplazamiento aumenta con la dificultad.
  local baseSpeedForScore = difficulty * baseScrollSpeed
  if playerCircle then
    local playerY = playerCircle.position.y
    if playerY < (settings.INTERNAL_HEIGHT / 2) then
      -- El desplazamiento es más rápido cuando el jugador está cerca de la parte superior.
      baseSpeedForScore = baseSpeedForScore + ((settings.INTERNAL_HEIGHT / 2) - playerY) * 0.02
    end
  end

  -- Esta es la velocidad real (teniendo en cuenta el powerup de slowDown)
  local scrollSpeed = baseSpeedForScore

  -- Aplica el efecto de ralentización del power-up del reloj
  if isSlowed then
    local playerY = playerCircle and playerCircle.position.y or 0
    -- Parte superior (0% - 20%): aceleración del juego normal
    if playerY < (settings.INTERNAL_HEIGHT * 0.2) then
      -- El desplazamiento es más rápido cuando el jugador está cerca de la parte superior
      scrollSpeed = baseScrollSpeed + ((settings.INTERNAL_HEIGHT / 2) - playerY) * 0.02

    -- Parte media (20% - 50%): mantener velocidad base (nivel 1)
    elseif playerY > (settings.INTERNAL_HEIGHT * 0.5) and playerY < (settings.INTERNAL_HEIGHT * 0.8) then
      scrollSpeed = baseScrollSpeed

    -- Parte inferior (80% - 100%) scroll lento, 10% de la velocidad normal
    elseif playerY >= (settings.INTERNAL_HEIGHT * 0.8) then
      scrollSpeed = baseScrollSpeed * 0.10
    end
  end

  circleAddDist = circleAddDist - scrollSpeed
  addScore(baseSpeedForScore)

  -- Si el player se va del límite inferior de la pantalla, es game over
  if playerCircle and playerCircle.position.y > settings.INTERNAL_HEIGHT - 1 then
    if not attractMode then
      if isBoltActive and playerCircle.next then
        if Powerups.checkLightningCollision(playerCircle) then
          Sound:play("teleport")
          particle(playerCircle.position, 20, 3, 0, math.pi * 2, colors.yellow) -- Origen
          particle(playerCircle.next.position, 20, 3, 0, math.pi * 2, colors.yellow) -- Destino
          playerCircle.isPassed = true
          playerCircle = playerCircle.next
          return -- Evita el game over
        end
      end
      Sound:play("explosion")
    end
    endGame()
    return
  end
  if isBoltActive and playerCircle and playerCircle.next then
    if Powerups.checkLightningCollision(playerCircle) then
      if not attractMode then
        Sound:play("teleport")
      end
      particle(playerCircle.position, 20, 3, 0, math.pi * 2, colors.yellow)
      particle(playerCircle.next.position, 20, 3, 0, math.pi * 2, colors.yellow)
      playerCircle.isPassed = true
      playerCircle = playerCircle.next
    end
  end

  -- Actualiza los círculos y prepara la detección de colisiones futuras.
  local obstacles = {}
  remove(circles, function(circle)
    circle.position.y = circle.position.y + scrollSpeed
    if circle.position.y > settings.INTERNAL_HEIGHT + circle.radius then
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
          Sound:play("teleport")
        end
        -- Teletransporte instantáneo
        particle(playerCircle.position, 20, 3, 0, math.pi * 2, colors.emerald_shade) -- Origen
        particle(playerCircle.next.position, 20, 3, 0, math.pi * 2, colors.emerald_shade) -- Destino
        playerCircle.isPassed = true -- Marcar el círculo como pasado
        playerCircle = playerCircle.next
        didTeleport = true
      end
    end

    if not didTeleport and justPressed and playerCircle.next and ignoreInputTimer <= 0 then
      -- Primero, verificar si el blip recoge algún power-up
      local collectedStar, collectedClock, collectedPhaseShift, collectedBolt, collectedScoreMultiplier, collectedSpawnRateBoost =
        Powerups.checkBlipCollision(playerCircle, playerCircle.next)

      if collectedStar then
        _G.isInvulnerable = true
        invulnerabilityTimer = 10
        if not attractMode then
          Sound:play("star_powerup")
        end
      end
      if collectedClock then
        isSlowed = true
        slowMotionTimer = 10
        if not attractMode then
          Sound:play("slowdown_powerup")
        end
        originalVelocities = {}
        originalSizes = {}
        for i, circle in ipairs(circles) do
          originalVelocities[circle] = circle.angularVelocity
          circle.angularVelocity = rnds(0.005, 0.015)
          originalSizes[circle] = circle.obstacleLength
          circle.obstacleLength = circle.obstacleLength * 0.5
        end
      end
      if collectedPhaseShift then
        isPhaseShiftActive = true
        phaseShiftTimer = 10
        if not attractMode then
          Sound:play("phaseshift_powerup")
        end
      end
      if collectedBolt then
        isBoltActive = true
        boltTimer = 30
        Powerups.createLightning()
        if not attractMode then
          Sound:play("bolt_powerup")
        end
      end
      if collectedScoreMultiplier then
        isScoreMultiplierActive = true
        scoreMultiplierTimer = 15
        if not attractMode then
          Sound:play("star_powerup")
        end
      end
      if collectedSpawnRateBoost then
        isSpawnRateBoostActive = true
        spawnRateBoostTimer = 30
        if not attractMode then
          Sound:play("phaseshift_powerup")
        end
      end

      local blipCollectedPowerup = collectedStar
        or collectedClock
        or collectedPhaseShift
        or collectedBolt
        or collectedScoreMultiplier
        or collectedSpawnRateBoost

      if blipCollectedPowerup and not collectedStar then
        _G.isInvulnerable = true -- Se vuelve invulnerable durante este blip
      elseif blipCollectedPowerup and collectedStar then
        -- No hacer nada aquí para no sobreescribir la invulnerabilidad de 10s
      end

      local collision = false
      -- Si no es invulnerable (ni por power-up de estrella ni por recolección en blip), chequear colisión con obstáculos
      if not _G.isInvulnerable then
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
      end

      if collision then
        if not attractMode then
          Sound:play("explosion")
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
          Sound:play("blip")
        end
        local currentPos = playerCircle.position:copy()
        local blipColor = colors.periwinkle_mist
        if isPhaseShiftActive then
          blipColor = colors.emerald_shade
        elseif isSlowed then
          blipColor = colors.naranjaRojo
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
        -- Si se recogió un power-up en el blip, la invulnerabilidad se desactiva al llegar al destino.
        if blipCollectedPowerup and not collectedStar then
          _G.isInvulnerable = false
        end
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
  local collectedStar, collectedClock, collectedPhaseShift, collectedBolt, collectedScoreMultiplier, collectedSpawnRateBoost =
    Powerups.checkCollisions(playerCircle)
  if collectedStar and not attractMode then
    _G.isInvulnerable = true
    invulnerabilityTimer = 10 -- segundos de invulnerabilidad
    Sound:play("star_powerup")
  end

  if collectedClock and not attractMode then
    isSlowed = true
    slowMotionTimer = 10 -- segundos de ralentización
    Sound:play("slowdown_powerup") -- Un sonido diferente para este power-up

    -- Ralentizar los obstáculos actuales
    originalVelocities = {} -- Limpiar velocidades anteriores
    originalSizes = {}
    for i, circle in ipairs(circles) do
      originalVelocities[circle] = circle.angularVelocity
      -- Establecer una velocidad angular base fija, no un factor de la actual.
      -- Esto simula la velocidad que tendrían los obstáculos con dificultad 1.
      circle.angularVelocity = rnds(0.005, 0.015)

      originalSizes[circle] = circle.obstacleLength
      -- Reducir el tamaño a la mitad pero nunca bajando de un tamaño mínimo
      local minObstacleLength = 5
      circle.obstacleLength = math.max(circle.obstacleLength * 0.5, minObstacleLength)
    end
  end

  if collectedPhaseShift and not attractMode then
    isPhaseShiftActive = true
    phaseShiftTimer = 10 -- duración en segundos de phase shift
    Sound:play("phaseshift_powerup")
  end

  if collectedBolt and not attractMode then
    isBoltActive = true
    boltTimer = 30 -- Duración de 30 segundos
    Powerups.createLightning()
    Sound:play("bolt_powerup") -- Sonido para el power-up de rayo
  end

  if collectedScoreMultiplier and not attractMode then
    isScoreMultiplierActive = true
    scoreMultiplierTimer = 15 -- segundos de multiplicador de score
    Sound:play("star_powerup") -- Placeholder sound
  end

  if collectedSpawnRateBoost and not attractMode then
    isSpawnRateBoostActive = true
    spawnRateBoostTimer = 30 -- 30 segundos de spawn rate boost
    Sound:play("phaseshift_powerup") -- Placeholder sound
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

  love.graphics.push()
  love.graphics.scale(settings.SCALE_FACTOR, settings.SCALE_FACTOR)

  -- Dibuja las partículas.
  for _, p in ipairs(particles) do
    local alpha = math.max(0, p.life / 20) -- La vida máxima es 20.
    if _G.isInvulnerable then
      love.graphics.setColor(colors.yellow[1], colors.yellow[2], colors.yellow[3], alpha)
    else
      love.graphics.setColor(p.color[1], p.color[2], p.color[3], alpha)
    end
    love.graphics.circle("fill", p.pos.x, p.pos.y, 0.5)
  end

  -- Dibuja los círculos y sus obstáculos giratorios
  for _, circle in ipairs(circles) do
    if isPhaseShiftActive and (circle == playerCircle or (playerCircle and circle == playerCircle.next)) then
      love.graphics.setColor(colors.emerald_shade)
    elseif circle == playerCircle or (playerCircle and circle == playerCircle.next) then
      if isSlowed then
        love.graphics.setColor(colors.naranjaRojo)
      else
        love.graphics.setColor(colors.periwinkle_mist)
      end
    elseif circle.isPassed then
      love.graphics.setColor(colors.rusty_cedar_transparent)
    else
      love.graphics.setColor(colors.rusty_cedar)
    end
    if not (_G.isInvulnerable and circle == playerCircle) then
      love.graphics.circle("fill", circle.position.x, circle.position.y, 1.5)
    end

    if isSlowed then
      love.graphics.setColor(colors.light_blue_glow) -- Color frío para indicar ralentización
    else
      love.graphics.setColor(colors.safety_orange)
    end
    for i = 1, circle.obstacleCount do
      local obstacleAngle = circle.angle + (i * math.pi * 2) / circle.obstacleCount
      local rectCenter = vec(circle.position.x, circle.position.y):addWithAngle(obstacleAngle, circle.radius)

      love.graphics.push()
      love.graphics.translate(rectCenter.x, rectCenter.y)
      love.graphics.rotate(obstacleAngle + math.pi / 2) -- Rota para que sea perpendicular al radio.
      love.graphics.rectangle("fill", -circle.obstacleLength / 2, -1.5, circle.obstacleLength, 3, 1.2, 1.2)
      love.graphics.pop()
    end
  end

  -- Dibuja al jugador (un círculo cuadrado más grande).
  if playerCircle then
    if _G.isInvulnerable then
      -- Efecto visual de invulnerabilidad (parpadeo)
      local alpha = 0.6 + math.sin(love.timer.getTime() * 20) * 0.4
      love.graphics.setColor(colors.yellow[1], colors.yellow[2], colors.yellow[3], alpha)
    elseif isPhaseShiftActive then
      love.graphics.setColor(colors.emerald_shade)
    elseif isSlowed then
      love.graphics.setColor(colors.naranjaRojo)
    else
      love.graphics.setColor(colors.periwinkle_mist)
    end
    love.graphics.rectangle("fill", playerCircle.position.x - 2.5, playerCircle.position.y - 2.5, 5, 5, 1.6, 1.6)
  end

  if isSpawnRateBoostActive then
    drawSpawnRateIndicator()
  end

  -- Dibuja la línea de colisión en Game Over.
  if gameOverLine then
    if isPhaseShiftActive then
      love.graphics.setColor(colors.emerald_shade)
    elseif isSlowed then
      love.graphics.setColor(colors.naranjaRojo)
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
      if _G.isInvulnerable then
        love.graphics.setColor(colors.yellow[1], colors.yellow[2], colors.yellow[3], alpha)
      elseif isPhaseShiftActive then
        love.graphics.setColor(colors.emerald_shade[1], colors.emerald_shade[2], colors.emerald_shade[3], alpha)
      elseif isSlowed then
        love.graphics.setColor(colors.naranjaRojo[1], colors.naranjaRojo[2], colors.naranjaRojo[3], alpha)
      else
        love.graphics.setColor(colors.periwinkle_mist[1], colors.periwinkle_mist[2], colors.periwinkle_mist[3], alpha)
      end
      love.graphics.rectangle("fill", currentPos.x - 2, currentPos.y - 2, 4, 4, 1.6, 1.6)
      currentPos:add(stepVector:copy():mul(3))
    end
  end

  Powerups.draw(gameState)

  if isBoltActive and gameState ~= "gameOver" then
    Powerups.drawLightning()
  end

  love.graphics.pop()

  -- Dibuja la interfaz de usuario (UI).
  love.graphics.push()
  love.graphics.origin() -- Resetea cualquier transformación previa de escala
  if not attractMode then
    Text:drawScore(score, hiScore, isScoreMultiplierActive)
  end

  -- Dibuja la pantalla del modo de atracción.
  if gameState == "attract" then
    Text:drawAttract(menuItems, selectedMenuItem)
  end

  if gameState == "gameOver" and not attractMode then
    if not gameOverLine or gameOverLine.timer <= 0 then
      Text:drawGameOver(score, hiScore, nuHiScore, hiScoreFlashVisible)
    end
  end

  if isPaused then
    Text:drawPauseMenu(pauseMenuItems, selectedPauseMenuItem)
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
    love.graphics.scale(settings.SCALE_FACTOR, settings.SCALE_FACTOR) -- Escalar para el ping
    if gameState ~= "gameOver" then
      Powerups.drawPings()
      drawPings()
    end
    love.graphics.pop()
    if gameState == "help" then
      Help.draw()
    elseif gameState == "about" then
      About.draw()
    end
  end)

  if isDebugEnabled then
    overlayStats.draw()
  end
end
