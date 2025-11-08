Input = {}

Input.helpScrollY = 0

local GameState = require("gamestate")
local Sound = require("sound")
local Music = require("music")
local Text = require("text")
local Settings = require("settings")
local Powerups = require("powerups")
local PowerupsManager = require("powerups_manager")
local LevelsSelector = require("levels_selector")
local About = require("about")
local Options = require("options")
local Game = require("game")
local Parallax = require("parallax")

local menuItems = {
  { text = "ENDLESS MODE", action = "start_endless" },
  { text = "ARCADE MODE", action = "start_arcade" },
  { text = "OPTIONS", action = "show_options" },
  { text = "ABOUT", action = "show_about" },
  { text = "HELP", action = "show_help" },
}
if not Settings.IS_WEB then
  table.insert(menuItems, { text = "EXIT", action = "exit_game" })
end

local pauseMenuItems = {
  { text = "RESUME", action = "resume" },
  { text = "RESTART", action = "restart" },
  { text = "OPTIONS", action = "show_options" },
  { text = "HELP", action = "show_help" },
  { text = "QUIT TO MENU", action = "quit_to_menu" },
}

local selectedMenuItem = 1
local selectedPauseMenuItem = 1
local justPressed = false

-- Touch support variables
local touchHoldTimer = 0
local touchHoldThreshold = 0.5
local isTouchHolding = false
local pingInterval = 0.5 -- 2 pings per second
local lastPingTime = 0

local activeTouches = {}
local pingGestureThreshold = 0.15 -- Max time difference for simultaneous detection (150ms)
local minSimultaneousTouches = 2

local touchInitialY = {}
local hasTouchscreen = false
local touch_start_y = nil
local touch_id = nil

function Input.getMenuItems()
  return menuItems
end

function Input.getPauseMenuItems()
  return pauseMenuItems
end

function Input.getSelectedMenuItem()
  return selectedMenuItem
end

function Input.setSelectedMenuItem(index)
  selectedMenuItem = index
end

function Input.getSelectedPauseMenuItem()
  return selectedPauseMenuItem
end

function Input.setSelectedPauseMenuItem(index)
  selectedPauseMenuItem = index
end

function Input.isJustPressed()
  return justPressed
end

function Input:keypressed(key)
  if GameState.is("attract") then
    if key == "up" then
      selectedMenuItem = math.max(1, selectedMenuItem - 1)
      Sound.play("blip")
    elseif key == "down" then
      selectedMenuItem = math.min(#menuItems, selectedMenuItem + 1)
      Sound.play("blip")
    elseif key == "return" or key == "space" then
      local action = menuItems[selectedMenuItem].action
      if action == "start_endless" then
        GameState.isAttractMode = false
        Main.currentLevelData = nil
        love.math.setRandomSeed(os.time())
        Main.initGame()
      elseif action == "start_arcade" then
        GameState.set("levels")
        Main.clearGameObjects()
      elseif action == "show_about" then
        GameState.previous = "attract"
        GameState.set("about")
      elseif action == "show_options" then
        GameState.previous = "attract"
        GameState.set("options")
      elseif action == "show_help" then
        GameState.previous = GameState.current
        GameState.set("help")
      elseif action == "exit_game" then
        love.event.quit()
      end
    end
  elseif GameState.is("help") then
    if key == "escape" then
    elseif key == "up" then
      Input.helpScrollY = math.max(0, Input.helpScrollY - 20)
    elseif key == "down" then
      Input.helpScrollY = math.min(300, Input.helpScrollY + 20)
    end
  elseif GameState.is("options") then
    Options.keypressed(key)
  elseif GameState.isPaused then
    if key == "up" then
      selectedPauseMenuItem = math.max(1, selectedPauseMenuItem - 1)
      Sound.play("blip")
    elseif key == "down" then
      selectedPauseMenuItem = math.min(#pauseMenuItems, selectedPauseMenuItem + 1)
      Sound.play("blip")
    elseif key == "return" then
      local action = pauseMenuItems[selectedPauseMenuItem].action
      if action == "resume" then
        GameState.isPaused = false
      elseif action == "restart" then
        GameState.isPaused = false
        Main.initGame()
      elseif action == "show_options" then
        GameState.previous = GameState.current
        GameState.set("options")
      elseif action == "show_help" then
        GameState.previous = GameState.current
        GameState.set("help")
      elseif action == "quit_to_menu" then
        GameState.isPaused = false
        GameState.isAttractMode = true
        Main.currentLevelData = nil
        Main.initGame()
      end
    end
  elseif GameState.is("playing") and (key == "space" or key == "return") then
    if not GameState.isPaused then
      justPressed = true
    end
  elseif GameState.is("levels") then
    if key == "escape" then
      GameState.isAttractMode = true
      Main.currentLevelData = nil
      Main.initGame()
      GameState.set("attract")
      Parallax.resume()
      return
    else
      LevelsSelector.keypressed(key)
    end
  end

  if key == "r" then
    Main.initGame()
  end

  if key == "escape" then
    if GameState.is("help") or GameState.is("about") or GameState.is("options") then
      GameState.set(GameState.previous or "attract")
    elseif GameState.isPaused then
      GameState.isPaused = false
    elseif GameState.is("playing") then
      GameState.isPaused = true
    elseif GameState.is("attract") then
      if not Settings.IS_WEB then
        love.event.quit()
      end
    end
  end

  if key == "c" and Game.get_player_circle() and GameState.is("playing") then
    local playerCircle = Game.get_player_circle()
    Powerups.activatePlayerPing(
      playerCircle.position,
      PowerupsManager.isPhaseShiftActive,
      PowerupsManager.getPingColor()
    )
  end

  if key == "m" then
    if love.keyboard.isDown("lshift") or love.keyboard.isDown("rshift") then
      Music.stop()
      Music.play()
    else
      Settings.IS_MUSIC_ENABLED = not Settings.IS_MUSIC_ENABLED
      Music.toggle_mute(not Settings.IS_MUSIC_ENABLED)
      Settings.IS_SFX_ENABLED = not Settings.IS_SFX_ENABLED
      Sound.toggle_mute(not Settings.IS_SFX_ENABLED)
    end
  end
end

function Input:mousemove(x, y)
  if GameState.is("levels") then
    LevelsSelector.mousemove(x, y)
  end
end

function Input:wheelmoved(x, y)
  if GameState.is("help") then
    Input.helpScrollY = Input.helpScrollY - y * 20
    Input.helpScrollY = math.max(0, Input.helpScrollY)
    Input.helpScrollY = math.min(300, Input.helpScrollY)
  elseif GameState.is("levels") then
    if y > 0 then
      -- Scroll up
      LevelsSelector.move_up()
    elseif y < 0 then
      -- Scroll down
      LevelsSelector.move_down()
    end
  end
end

function Input:mousepressed(x, y, button)
  if GameState.ignoreInputTimer > 0 then
    return
  end

  if GameState.is("levels") then
    LevelsSelector.mousepressed(x, y, button)
    return
  end

  if GameState.is("about") then
    if button == 1 then
      -- If not clicked on the URL, return to previous screen
      if not About.mousepressed(x, y, button) then
        GameState.set(GameState.previous or "attract")
      end
    end
    return
  end

  if GameState.is("options") then
    if button == 1 then
      if not Options.mousepressed(x, y, button) then
        GameState.set(GameState.previous or "attract")
      end
    end
    return
  end

  if GameState.is("help") then
    if button == 1 and not hasTouchscreen then
      if GameState.previous == "attract" then
        GameState.isAttractMode = true
        GameState.set(GameState.previous)
      else
        local came_from_pause = GameState.isPaused
        GameState.set(GameState.previous)
        if came_from_pause then
          GameState.isPaused = true
        end
      end
      return
    end
  end

  -- Attract menu mouse
  if button == 1 and GameState.is("attract") then
    local startY = Settings.WINDOW_HEIGHT * 0.4
    local textPercentage = 0.55
    local uniformScale = Text.calculateUniformScale(menuItems, textPercentage)

    local yPos = startY
    for i, item in ipairs(menuItems) do
      local itemWidth = Text.getTextWidth(item.text, uniformScale)
      local itemX = (Settings.WINDOW_WIDTH - itemWidth) / 2
      item.y = yPos
      item.height = Text.getTextHeight(uniformScale)
      yPos = yPos + 50
      if x >= itemX and x <= itemX + itemWidth and y >= item.y and y <= item.y + item.height then
        Input.setSelectedMenuItem(i)
        Sound.play("blip")
        local action = item.action
        if action == "start_endless" then
          GameState.isAttractMode = false
          Main.currentLevelData = nil
          love.math.setRandomSeed(os.time())
          Main.initGame()
        elseif action == "start_arcade" then
          GameState.set("levels")
          Main.clearGameObjects()
        elseif action == "show_about" then
          if GameState.is("playing") then
            GameState.isPaused = true
          end
          GameState.set("about")
        elseif action == "show_options" then
          GameState.previous = "attract"
          GameState.set("options")
        elseif action == "show_help" then
          GameState.previous = GameState.current
          if GameState.is("playing") then
            GameState.isPaused = true
          end
          GameState.set("help")
        elseif action == "exit_game" then
          love.event.quit()
        end
        return
      end
    end
    return
  -- Pause menu mouse
  elseif button == 1 and GameState.isPaused then
    local startY = Settings.WINDOW_HEIGHT * 0.5
    local textPercentage = 0.50
    local uniformScale = Text.calculateUniformScale(pauseMenuItems, textPercentage)

    local yPos = startY
    for i, item in ipairs(pauseMenuItems) do
      local itemWidth = Text.getTextWidth(item.text, uniformScale)
      local itemX = (Settings.WINDOW_WIDTH - itemWidth) / 2
      item.y = yPos
      item.height = Text.getTextHeight(uniformScale)
      yPos = yPos + 50
      if x >= itemX and x <= itemX + itemWidth and y >= item.y and y <= item.y + item.height then
        Input.setSelectedPauseMenuItem(i)
        Sound.play("blip")
        local action = item.action
        if action == "resume" then
          GameState.isPaused = false
        elseif action == "restart" then
          GameState.isPaused = false
          Main.initGame()
        elseif action == "show_options" then
          GameState.previous = GameState.current
          GameState.set("options")
        elseif action == "show_help" then
          GameState.previous = GameState.current
          GameState.set("help")
        elseif action == "quit_to_menu" then
          GameState.isPaused = false
          GameState.isAttractMode = true
          Main.currentLevelData = nil
          Main.initGame()
        end
        return
      end
    end
    return
  end

  if button == 1 then
    if GameState.isNot("gameOver") and not GameState.isPaused then
      justPressed = true
    end
  end

  local playerCircle = Game.get_player_circle()
  if button == 2 and playerCircle and GameState.is("playing") then
    Powerups.activatePlayerPing(
      playerCircle.position,
      PowerupsManager.isPhaseShiftActive,
      PowerupsManager.getPingColor()
    )
  end
end

-- Simulate user input so the game runs automatically in attract mode.
function Input:simulateAttractInput(playerCircle)
  local clickChance = 0.01
  if playerCircle and playerCircle.position.y > (Settings.INTERNAL_HEIGHT * 0.8) then
    clickChance = clickChance * 50 -- Multiply click probability by 50
  end
  if math.random() < clickChance then
    justPressed = true
  end
end

-- Controller support
local connectedJoysticks = {}
local controllerButtonOne = 1
local controllerButtonTwo = 2
local controllerButtonThree = 3

function Input:gamepadpressed(joystick, button)
  if button == "dpup" then
    self:keypressed("up")
  elseif button == "dpdown" then
    self:keypressed("down")
  end
end

function Input:joystickpressed(joystick, button)
  if button == controllerButtonOne then
    self:keypressed("return")
  elseif button == controllerButtonTwo then
    self:keypressed("c")
  elseif button == controllerButtonThree then
    self:keypressed("escape")
  end
end

function Input:joystickadded(joystick)
  connectedJoysticks[joystick:getID()] = joystick
  print("Controller connected: " .. joystick:getName())
end

function Input:joystickremoved(joystick)
  connectedJoysticks[joystick:getID()] = nil
  print("Controller disconnected: " .. joystick:getName())
end

function Input:getConnectedJoysticks()
  return connectedJoysticks
end

local function isKeyboardOrMouseContinue()
  return love.keyboard.isDown("space") or love.keyboard.isDown("return") or love.mouse.isDown(1)
end

local function isControllerContinue()
  for _, joystick in pairs(connectedJoysticks) do
    if joystick:isDown(controllerButtonOne) then
      return true
    end
  end
  return false
end

function Input:isGameOverContinue()
  return isKeyboardOrMouseContinue() or isControllerContinue()
end

function Input:isLevelCompletedContinue()
  return isKeyboardOrMouseContinue() or isControllerContinue()
end

function Input:resetJustPressed()
  justPressed = false
end

function Input:triggerPing()
  local playerCircle = Game.get_player_circle()
  if playerCircle and GameState.is("playing") then
    Powerups.activatePlayerPing(
      playerCircle.position,
      PowerupsManager.isPhaseShiftActive,
      PowerupsManager.getPingColor()
    )
  end
end

function Input:update(dt)
  if isTouchHolding then
    touchHoldTimer = touchHoldTimer + dt
    if touchHoldTimer >= touchHoldThreshold then
      -- Start pinging continuously
      local currentTime = love.timer.getTime()
      if currentTime - lastPingTime >= pingInterval then
        self:triggerPing()
        lastPingTime = currentTime
      end
    end
  end
end

function Input:touchpressed(id, x, y, dx, dy, pressure)
  hasTouchscreen = true

  if GameState.is("help") then
    -- Store initial touch position for scrolling
    touchInitialY[id] = y
    return
  elseif GameState.is("levels") then
    touch_id = id
    touch_start_y = y
    return
  end

  if GameState.isNot("gameOver") and not GameState.isPaused then
    activeTouches[id] = { x = x, y = y, time = love.timer.getTime() }

    -- Check for simultaneous touches to trigger direct ping
    local simultaneousTouches = 0
    local currentTime = love.timer.getTime()

    for _, touchData in pairs(activeTouches) do
      if currentTime - touchData.time <= pingGestureThreshold then
        simultaneousTouches = simultaneousTouches + 1
      end
    end

    if simultaneousTouches >= minSimultaneousTouches then
      self:triggerPing()
    else
      isTouchHolding = true
      touchHoldTimer = 0
    end
  end
end

function Input:touchmoved(id, x, y, dx, dy, pressure)
  if GameState.is("help") and hasTouchscreen and touchInitialY[id] then
    -- Calculate scroll delta based on touch movement
    local deltaY = touchInitialY[id] - y
    Input.helpScrollY = Input.helpScrollY + deltaY
    Input.helpScrollY = math.max(0, Input.helpScrollY)
    Input.helpScrollY = math.min(300, Input.helpScrollY)
    -- Update initial position for continuous scrolling
    touchInitialY[id] = y
    return
  elseif GameState.is("levels") and hasTouchscreen and touch_id == id and touch_start_y then
    local delta_y = y - touch_start_y
    if math.abs(delta_y) > 50 then -- threshold for swipe
      if delta_y > 0 then
        -- Swipe down
        LevelsSelector.move_down()
      else
        -- Swipe up
        LevelsSelector.move_up()
      end
      touch_start_y = y -- reset for continuous swiping
    end
    return
  end

  -- Handle touch movement as mouse movement
  self:mousemove(x, y)
end

function Input:touchreleased(id, x, y, dx, dy, pressure)
  if GameState.is("help") then
    -- Clear touch data for help screen
    touchInitialY[id] = nil
    return
  elseif GameState.is("levels") and id == touch_id then
    touch_id = nil
    touch_start_y = nil
    return
  end

  activeTouches[id] = nil

  if isTouchHolding then
    -- Stop pinging when touch is released
    isTouchHolding = false
    touchHoldTimer = 0
  end
end

return Input
