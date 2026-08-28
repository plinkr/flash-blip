Input = {}

Input.help_scroll_y = 0
Input.max_help_scroll = 300

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
local UpdateChecker = require("update_checker")

local menu_items = {
  { text = "ENDLESS MODE", action = "start_endless" },
  { text = "ARCADE MODE", action = "start_arcade" },
  { text = "HI SCORES", action = "show_hi_scores" },
  { text = "OPTIONS", action = "show_options" },
  { text = "ABOUT", action = "show_about" },
  { text = "HELP", action = "show_help" },
}
if not Settings.IS_WEB then
  table.insert(menu_items, { text = "EXIT", action = "exit_game" })
end

local pause_menu_items = {
  { text = "RESUME", action = "resume" },
  { text = "RESTART", action = "restart" },
  { text = "OPTIONS", action = "show_options" },
  { text = "HELP", action = "show_help" },
  { text = "QUIT TO MENU", action = "quit_to_menu" },
}

local selected_menu_item = 1
local selected_pause_menu_item = 1
local just_pressed = false

-- Touch support variables
local touch_hold_timer = 0
local touch_hold_threshold = 0.5
local is_touch_holding = false
local ping_interval = 0.5 -- 2 pings per second
local last_ping_time = 0

local active_touches = {}
local ping_gesture_threshold = 0.15 -- Max time difference for simultaneous detection (150ms)
local min_simultaneous_touches = 2

local touch_initial_y = {}
local has_touchscreen = false
local touch_start_y = nil
local touch_id = nil

function Input.get_menu_items()
  return menu_items
end

function Input.get_pause_menu_items()
  return pause_menu_items
end

function Input.get_selected_menu_item()
  return selected_menu_item
end

function Input.set_selected_menu_item(index)
  selected_menu_item = index
end

function Input.get_selected_pause_menu_item()
  return selected_pause_menu_item
end

function Input.set_selected_pause_menu_item(index)
  selected_pause_menu_item = index
end

function Input.is_just_pressed()
  return just_pressed
end

function Input:keypressed(key)
  if GameState.is("virtual_keyboard") then
    local VirtualKeyboard = require("virtual_keyboard")
    VirtualKeyboard.keypressed(key)
    return
  end

  if GameState.is("attract") then
    if key == "up" then
      selected_menu_item = math.max(1, selected_menu_item - 1)
      Sound.play("blip")
    elseif key == "down" then
      selected_menu_item = math.min(#menu_items, selected_menu_item + 1)
      Sound.play("blip")
    elseif key == "return" or key == "space" then
      local action = menu_items[selected_menu_item].action
      if action == "start_endless" then
        GameState.is_attract_mode = false
        Main.current_level_data = nil
        love.math.setRandomSeed(os.time())
        Main.init_game()
      elseif action == "start_arcade" then
        Game.clear_game_objects()
        GameState.set("levels")
      elseif action == "show_hi_scores" then
        GameState.previous = "attract"
        GameState.set("hi_scores")
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
      Input.help_scroll_y = math.max(0, Input.help_scroll_y - 20)
    elseif key == "down" then
      Input.help_scroll_y = math.min(Input.max_help_scroll, Input.help_scroll_y + 20)
    end
  elseif GameState.is("options") then
    Options.keypressed(key)
  elseif GameState.is_paused then
    if key == "up" then
      selected_pause_menu_item = math.max(1, selected_pause_menu_item - 1)
      Sound.play("blip")
    elseif key == "down" then
      selected_pause_menu_item = math.min(#pause_menu_items, selected_pause_menu_item + 1)
      Sound.play("blip")
    elseif key == "return" then
      local action = pause_menu_items[selected_pause_menu_item].action
      if action == "resume" then
        GameState.is_paused = false
      elseif action == "restart" then
        GameState.is_paused = false
        Main.init_game()
      elseif action == "show_options" then
        GameState.previous = GameState.current
        GameState.set("options")
      elseif action == "show_help" then
        GameState.previous = GameState.current
        GameState.set("help")
      elseif action == "quit_to_menu" then
        GameState.is_paused = false
        GameState.is_attract_mode = true
        Main.current_level_data = nil
        Main.init_game()
      end
    end
  elseif GameState.is("playing") and (key == "space" or key == "return") then
    if not GameState.is_paused and GameState.ignore_input_timer <= 0 then
      just_pressed = true
    end
  elseif GameState.is("levels") then
    LevelsSelector.keypressed(key)
    return
  end

  if key == "r" then
    Main.init_game()
  end

  if key == "escape" then
    if GameState.is("help") or GameState.is("about") or GameState.is("options") or GameState.is("hi_scores") then
      GameState.set(GameState.previous or "attract")
    elseif GameState.is_paused then
      GameState.is_paused = false
    elseif GameState.is("playing") then
      GameState.is_paused = true
    elseif GameState.is("attract") then
      if not Settings.IS_WEB then
        love.event.quit()
      end
    end
  end

  if key == "c" and Game.get_player_circle() and GameState.is("playing") and GameState.ignore_input_timer <= 0 then
    local player_circle = Game.get_player_circle()
    Powerups.activate_player_ping(
      player_circle.position,
      PowerupsManager.is_phase_shift_active,
      PowerupsManager.get_ping_color()
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
      Settings.save_debounced()
    end
  end
end

function Input:mousemove(x, y)
  if GameState.is("help") then
    require("help").mousemoved(x, y)
  elseif GameState.is("levels") then
    LevelsSelector.mousemove(x, y)
  end
end

function Input:wheelmoved(x, y)
  if GameState.is("help") then
    Input.help_scroll_y = Input.help_scroll_y - y * 20
    Input.help_scroll_y = math.max(0, Input.help_scroll_y)
    Input.help_scroll_y = math.min(Input.max_help_scroll, Input.help_scroll_y)
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
  if GameState.is("virtual_keyboard") then
    local VirtualKeyboard = require("virtual_keyboard")
    VirtualKeyboard.mousepressed(x, y, button)
    return
  end

  if GameState.is("levels") then
    LevelsSelector.mousepressed(x, y, button)
    return
  end

  if GameState.is("about") then
    if button == 1 then
      About.mousepressed(x, y, button)
    end
    return
  end

  if GameState.is("hi_scores") then
    if button == 1 then
      local HiScores = require("hi_scores")
      if not HiScores.mousepressed(x, y, button) then
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
    if button == 1 then
      require("help").mousepressed(x, y, button)
    end
    return
  end

  if GameState.ignore_input_timer > 0 and not GameState.is_paused then
    return
  end

  -- Attract menu mouse
  if button == 1 and GameState.is("attract") then
    if UpdateChecker.handle_click(x, y) then
      return
    end

    local start_y = Settings.WINDOW_HEIGHT * 0.4
    local text_percentage = 0.55
    local uniform_scale = Text.calculate_uniform_scale(menu_items, text_percentage)

    local y_pos = start_y
    for i, item in ipairs(menu_items) do
      local item_width = Text.get_text_width(item.text, uniform_scale)
      local item_x = (Settings.WINDOW_WIDTH - item_width) / 2
      item.y = y_pos
      item.height = Text.get_text_height(uniform_scale)
      y_pos = y_pos + 50
      if x >= item_x and x <= item_x + item_width and y >= item.y and y <= item.y + item.height then
        Input.set_selected_menu_item(i)
        Sound.play("blip")
        local action = item.action
        if action == "start_endless" then
          GameState.is_attract_mode = false
          Main.current_level_data = nil
          love.math.setRandomSeed(os.time())
          Main.init_game()
        elseif action == "start_arcade" then
          Game.clear_game_objects()
          GameState.set("levels")
        elseif action == "show_hi_scores" then
          GameState.previous = "attract"
          GameState.set("hi_scores")
        elseif action == "show_about" then
          if GameState.is("playing") then
            GameState.is_paused = true
          end
          GameState.set("about")
        elseif action == "show_options" then
          GameState.previous = "attract"
          GameState.set("options")
        elseif action == "show_help" then
          GameState.previous = GameState.current
          if GameState.is("playing") then
            GameState.is_paused = true
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
  elseif button == 1 and GameState.is_paused then
    local start_y = Settings.WINDOW_HEIGHT * 0.5
    local text_percentage = 0.50
    local uniform_scale = Text.calculate_uniform_scale(pause_menu_items, text_percentage)

    local y_pos = start_y
    for i, item in ipairs(pause_menu_items) do
      local item_width = Text.get_text_width(item.text, uniform_scale)
      local item_x = (Settings.WINDOW_WIDTH - item_width) / 2
      item.y = y_pos
      item.height = Text.get_text_height(uniform_scale)
      y_pos = y_pos + 50
      if x >= item_x and x <= item_x + item_width and y >= item.y and y <= item.y + item.height then
        Input.set_selected_pause_menu_item(i)
        Sound.play("blip")
        local action = item.action
        if action == "resume" then
          GameState.is_paused = false
        elseif action == "restart" then
          GameState.is_paused = false
          Main.init_game()
        elseif action == "show_options" then
          GameState.previous = GameState.current
          GameState.set("options")
        elseif action == "show_help" then
          GameState.previous = GameState.current
          GameState.set("help")
        elseif action == "quit_to_menu" then
          GameState.is_paused = false
          GameState.is_attract_mode = true
          Main.current_level_data = nil
          Main.init_game()
        end
        return
      end
    end
    return
  end

  if button == 1 then
    if GameState.is_not("gameOver") and not GameState.is_paused then
      just_pressed = true
    end
  end

  local player_circle = Game.get_player_circle()
  if button == 2 and player_circle and GameState.is("playing") then
    Powerups.activate_player_ping(
      player_circle.position,
      PowerupsManager.is_phase_shift_active,
      PowerupsManager.get_ping_color()
    )
  end
end

-- Simulate user input so the game runs automatically in attract mode.
function Input:simulate_attract_input(player_circle)
  local click_chance = 0.01
  if player_circle and player_circle.position.y > (Settings.INTERNAL_HEIGHT * 0.7) then
    click_chance = click_chance * 50 -- Multiply click probability by 50
  end
  if math.random() < click_chance then
    just_pressed = true
  end
end

-- Controller support
local connected_joysticks = {}
local controller_button_one = 1
local controller_button_two = 2
local controller_button_three = 3

function Input:gamepadpressed(joystick, button)
  if button == "dpup" then
    self:keypressed("up")
  elseif button == "dpdown" then
    self:keypressed("down")
  end
end

function Input:joystickpressed(joystick, button)
  if button == controller_button_one then
    self:keypressed("return")
  elseif button == controller_button_two then
    self:keypressed("c")
  elseif button == controller_button_three then
    self:keypressed("escape")
  end
end

function Input:joystickadded(joystick)
  connected_joysticks[joystick:getID()] = joystick
  print("Controller connected: " .. joystick:getName())
end

function Input:joystickremoved(joystick)
  connected_joysticks[joystick:getID()] = nil
  print("Controller disconnected: " .. joystick:getName())
end

function Input:get_connected_joysticks()
  return connected_joysticks
end

local function is_keyboard_or_mouse_continue()
  return love.keyboard.isDown("space") or love.keyboard.isDown("return") or love.mouse.isDown(1)
end

local function is_controller_continue()
  for _, joystick in pairs(connected_joysticks) do
    if joystick:isDown(controller_button_one) then
      return true
    end
  end
  return false
end

function Input:is_game_over_continue()
  return is_keyboard_or_mouse_continue() or is_controller_continue()
end

function Input:is_level_completed_continue()
  return is_keyboard_or_mouse_continue() or is_controller_continue()
end

function Input:reset_just_pressed()
  just_pressed = false
end

function Input:trigger_ping()
  local player_circle = Game.get_player_circle()
  if player_circle and GameState.is("playing") and GameState.ignore_input_timer <= 0 then
    Powerups.activate_player_ping(
      player_circle.position,
      PowerupsManager.is_phase_shift_active,
      PowerupsManager.get_ping_color()
    )
  end
end

function Input:update(dt)
  if is_touch_holding then
    touch_hold_timer = touch_hold_timer + dt
    if touch_hold_timer >= touch_hold_threshold then
      -- Start pinging continuously
      local current_time = love.timer.getTime()
      if current_time - last_ping_time >= ping_interval then
        self:trigger_ping()
        last_ping_time = current_time
      end
    end
  end
end

function Input:touchpressed(id, x, y, dx, dy, pressure)
  has_touchscreen = true

  if GameState.is("help") then
    -- Store initial touch position for scrolling
    touch_initial_y[id] = y
    return
  elseif GameState.is("levels") then
    touch_id = id
    touch_start_y = y
    return
  elseif GameState.is("about") then
    return
  elseif GameState.is("attract") then
    return
  end

  if GameState.is("playing") then
    if GameState.ignore_input_timer > 0 and not GameState.is_paused then
      return
    end
    active_touches[id] = { x = x, y = y, time = love.timer.getTime() }

    -- Check for simultaneous touches to trigger direct ping
    local simultaneous_touches = 0
    local current_time = love.timer.getTime()

    for _, touch_data in pairs(active_touches) do
      if current_time - touch_data.time <= ping_gesture_threshold then
        simultaneous_touches = simultaneous_touches + 1
      end
    end

    if simultaneous_touches >= min_simultaneous_touches then
      self:trigger_ping()
    else
      is_touch_holding = true
      touch_hold_timer = 0
    end
  end
end

function Input:touchmoved(id, x, y, dx, dy, pressure)
  if GameState.is("help") and (has_touchscreen or Settings.IS_MOBILE) and touch_initial_y[id] then
    -- Calculate scroll delta based on touch movement
    local delta_y = touch_initial_y[id] - y
    Input.help_scroll_y = Input.help_scroll_y + delta_y
    Input.help_scroll_y = math.max(0, Input.help_scroll_y)
    Input.help_scroll_y = math.min(Input.max_help_scroll, Input.help_scroll_y)
    -- Update initial position for continuous scrolling
    touch_initial_y[id] = y
    return
  elseif GameState.is("levels") and (has_touchscreen or Settings.IS_MOBILE) and touch_id == id and touch_start_y then
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
    touch_initial_y[id] = nil
    require("help").mousereleased(x, y, 1)
    return
  elseif GameState.is("levels") and id == touch_id then
    touch_id = nil
    touch_start_y = nil
    return
  end

  active_touches[id] = nil

  if is_touch_holding then
    -- Stop pinging when touch is released
    is_touch_holding = false
    touch_hold_timer = 0
  end
end

function Input:mousereleased(x, y, button)
  if GameState.is("help") then
    require("help").mousereleased(x, y, button)
  end
end

return Input
