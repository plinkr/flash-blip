Input = {}

local CustomFont = require("font")

local GameState = require("gamestate")
local Sound = require("sound")
local Text = require("text")
local settings = require("settings")
local Powerups = require("powerups")
local PowerupsManager = require("powerups_manager")
local LevelsSelector = require("levels_selector")
local About = require("about")
local Help = require("help")
local Game = require("game")
local Parallax = require("parallax")

local menuItems = {
  { text = "ENDLESS MODE", action = "start_endless" },
  { text = "ARCADE MODE", action = "start_arcade" },
  { text = "ABOUT", action = "show_about" },
  { text = "HELP", action = "show_help" },
}
if love.system.getOS() ~= "Web" then
  table.insert(menuItems, { text = "EXIT", action = "exit_game" })
end

local pauseMenuItems = {
  { text = "RESUME", action = "resume" },
  { text = "RESTART", action = "restart" },
  { text = "HELP", action = "show_help" },
  { text = "QUIT TO MENU", action = "quit_to_menu" },
}

local selectedMenuItem = 1
local selectedPauseMenuItem = 1
local justPressed = false

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
        GameState.attractMode = false
        Main.currentLevelData = nil
        love.math.setRandomSeed(os.time())
        Main.initGame()
      elseif action == "start_arcade" then
        GameState.set("levels")
        Main.clearGameObjects()
      elseif action == "show_about" then
        GameState.previous = "attract"
        GameState.set("about")
      elseif action == "show_help" then
        GameState.previous = GameState.current
        GameState.set("help")
      elseif action == "exit_game" then
        love.event.quit()
      end
    end
  elseif GameState.is("help") then
    Help.keypressed(key)
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
      elseif action == "show_help" then
        GameState.previous = GameState.current
        GameState.set("help")
      elseif action == "quit_to_menu" then
        GameState.isPaused = false
        GameState.attractMode = true
        Main.currentLevelData = nil
        Main.initGame()
      end
    end
  elseif GameState.is("playing") and (key == "space" or key == "return") then
    if not GameState.isPaused then
      justPressed = true
    end
  end

  if key == "r" then
    Main.initGame()
  end

  if key == "escape" then
    if GameState.is("levels") then
      GameState.attractMode = true
      Main.currentLevelData = nil
      Main.initGame()
      GameState.set("attract")
      Parallax.resume()
    elseif GameState.is("help") or GameState.is("about") then
      GameState.set(GameState.previous or "attract")
    elseif GameState.isPaused then
      GameState.isPaused = false
    elseif GameState.is("playing") then
      GameState.isPaused = true
    elseif GameState.is("attract") then
      if love.system.getOS() ~= "Web" then
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

  if GameState.is("help") then
    if button == 1 then
      if GameState.previous == "attract" then
        GameState.attractMode = true
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
    local startY = settings.WINDOW_HEIGHT * 0.4
    local fontSize = 5
    local yPos = startY
    for i, item in ipairs(menuItems) do
      local itemWidth = Text.getTextWidth(item.text, fontSize)
      local itemX = (settings.WINDOW_WIDTH - itemWidth) / 2
      item.y = yPos
      item.height = CustomFont:getTextHeight(fontSize)
      yPos = yPos + 50
      if x >= itemX and x <= itemX + itemWidth and y >= item.y and y <= item.y + item.height then
        Input.setSelectedMenuItem(i)
        Sound.play("blip")
        local action = item.action
        if action == "start_endless" then
          GameState.attractMode = false
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
  elseif button == 1 and GameState.isPaused then
    local startY = settings.WINDOW_HEIGHT * 0.5
    local fontSize = 5
    local yPos = startY
    for i, item in ipairs(pauseMenuItems) do
      local itemWidth = Text.getTextWidth(item.text, fontSize)
      local itemX = (settings.WINDOW_WIDTH - itemWidth) / 2
      item.y = yPos
      item.height = CustomFont:getTextHeight(fontSize)
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
        elseif action == "show_help" then
          GameState.previous = GameState.current
          GameState.set("help")
        elseif action == "quit_to_menu" then
          GameState.isPaused = false
          GameState.attractMode = true
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

function Input:wheelmoved(x, y)
  if GameState.is("help") then
    Help.wheelmoved(x, y)
  end
end

-- Simulate user input so the game runs automatically in attract mode.
function Input:simulateAttractInput(playerCircle)
  if GameState.attractMode then
    local clickChance = 0.01
    if playerCircle and playerCircle.position.y > (settings.INTERNAL_HEIGHT * 0.8) then
      clickChance = clickChance * 50 -- Multiply click probability by 50
    end
    if math.random() < clickChance then
      justPressed = true
    end
  end
end

function Input:isGameOverContinue()
  return (love.keyboard.isDown("space") or love.keyboard.isDown("return") or love.mouse.isDown(1))
end

function Input:isLevelCompletedContinue()
  return (love.keyboard.isDown("space") or love.keyboard.isDown("return") or love.mouse.isDown(1))
end

function Input:resetJustPressed()
  justPressed = false
end

return Input
