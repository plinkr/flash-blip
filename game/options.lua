local Colors = require("colors")
local Settings = require("settings")
local Text = require("text")
local Sound = require("sound")
local Music = require("music")
local GameState = require("gamestate")
local GlowBenchmark = require("glow_benchmark")
local ScreenUtils = require("screen_utils")

local options = {}

local menu_items = {
  { text = "MUSIC", setting = "is_music_volume" },
  { text = "SFX", setting = "is_sfx_volume" },
  { text = "GLOW", setting = "is_glow_enabled" },
  { text = "BLUR", setting = "is_blur_enabled" },
}

local selected_item = 1
local bounds = {}
Settings.IS_MUSIC_VOLUME = Settings.IS_MUSIC_VOLUME or 1.0
Settings.IS_SFX_VOLUME = Settings.IS_SFX_VOLUME or 1.0

local function toggle_setting(setting)
  if setting == "is_music_volume" then
    Settings.IS_MUSIC_ENABLED = not Settings.IS_MUSIC_ENABLED
    Music.toggle_mute(not Settings.IS_MUSIC_ENABLED)
    Settings.save_debounced()
  elseif setting == "is_sfx_volume" then
    Settings.IS_SFX_ENABLED = not Settings.IS_SFX_ENABLED
    Sound.toggle_mute(not Settings.IS_SFX_ENABLED)
    Settings.save_debounced()
  elseif setting == "is_glow_enabled" then
    Settings.IS_GLOW_ENABLED = not Settings.IS_GLOW_ENABLED
    Main.apply_glow_setting()
    if Settings.IS_GLOW_ENABLED and (Settings.IS_MOBILE or Settings.IS_WEB) then
      if not Settings.HAS_PASSED_GLOW_TEST then
        GlowBenchmark.start()
      else
        GlowBenchmark.stop()
        Settings.save_debounced()
      end
    else
      GlowBenchmark.stop()
      Settings.save_debounced()
    end
  elseif setting == "is_blur_enabled" then
    Settings.IS_BLUR_ENABLED = not Settings.IS_BLUR_ENABLED
    Main.apply_blur_setting()
    Settings.save_debounced()
  end
end

-- Change volume BGM and SE separately
local function change_volume(setting, delta)
  if setting == "is_music_volume" then
    Settings.IS_MUSIC_VOLUME = math.max(0, math.min(1, Settings.IS_MUSIC_VOLUME + delta))
    Music.set_volume(Settings.IS_MUSIC_VOLUME)
    Settings.save_debounced()
  elseif setting == "is_sfx_volume" then
    Settings.IS_SFX_VOLUME = math.max(0, math.min(1, Settings.IS_SFX_VOLUME + delta))
    Sound.set_volume(Settings.IS_SFX_VOLUME)
    Settings.save_debounced()
  end
end

local function volume_bar(percent)
  local total_slots = 5
  percent = tonumber(percent) or 0
  percent = math.max(0, math.min(100, percent))

  local filled = math.floor(percent / 20)
  filled = math.max(0, math.min(total_slots, filled))

  local empty = total_slots - filled

  return "- " .. string.rep("█", filled) .. string.rep("░", empty) .. " +"
end

function options.load()
  selected_item = 1
end

function options.update(dt) end

function options.draw()
  love.graphics.setColor(0, 0, 0, 0.85)
  love.graphics.rectangle("fill", 0, 0, Settings.WINDOW_WIDTH, Settings.WINDOW_HEIGHT)

  love.graphics.setColor(Colors.cyan)
  Text.draw_centered_text("OPTIONS", Settings.WINDOW_HEIGHT * 0.1, 0.7)

  local y_start = Settings.WINDOW_HEIGHT * 0.35
  local width_percentage = 0.65

  -- Create a list of potential menu item texts to calculate a uniform scale
  local items_for_scaling = {}
  for _, item in ipairs(menu_items) do
    -- Use the longest possible text for stable scaling
    if item.setting == "is_music_volume" or item.setting == "is_sfx_volume" then
      local volume = Settings[item.setting:upper()] or 0
      local percent = math.floor(volume * 100)
      table.insert(items_for_scaling, { text = "[✓] " .. item.text })
      table.insert(items_for_scaling, { text = "      " .. volume_bar(percent) })
    else
      table.insert(items_for_scaling, { text = "[✓] " .. item.text })
    end
  end

  local uniform_scale = Text.calculate_uniform_scale(items_for_scaling, width_percentage)

  -- Calculate common X to align all checkboxes to the left within a centered block
  local max_w = 0
  for _, item in ipairs(items_for_scaling) do
    max_w = math.max(max_w, Text.get_text_width(item.text, uniform_scale))
  end
  local common_x = (Settings.WINDOW_WIDTH - max_w) / 2

  local text_height = Text.get_text_height(uniform_scale)
  local current_y = y_start

  for i, item in ipairs(menu_items) do
    local is_selected = (i == selected_item)

    local is_on
    if item.setting == "is_music_volume" then
      is_on = Settings.IS_MUSIC_ENABLED
    elseif item.setting == "is_sfx_volume" then
      is_on = Settings.IS_SFX_ENABLED
    else
      is_on = Settings[item.setting:upper()]
    end

    local color
    if not Settings.IS_MOBILE and is_selected then
      color = Colors.cyan
    else
      color = is_on and Colors.neon_lime_splash or Colors.naranja_rojo
    end
    love.graphics.setColor(color)

    if item.setting == "is_music_volume" or item.setting == "is_sfx_volume" then
      local volume = Settings[item.setting:upper()] or 0
      local percent = math.floor(volume * 100)
      local checkbox = is_on and "[✓]" or "[✗]"

      local line1 = checkbox .. " " .. item.text
      local line2 = "      " .. volume_bar(percent)

      Text.draw_text(line1, common_x, current_y, uniform_scale)

      local y2 = current_y + text_height + 15
      Text.draw_text(line2, common_x, y2, uniform_scale)

      local w2 = Text.get_text_width(line2, uniform_scale)
      bounds[i] = {
        x = common_x,
        y = current_y,
        width = max_w + 50,
        height = (y2 + text_height) - current_y,
        line1_height = text_height + 10,
        x2 = common_x,
        w2 = w2,
        is_double = true,
      }
      current_y = current_y + (y2 + text_height - current_y) + 30
    else
      local checkbox = is_on and "[✓]" or "[✗]"
      local text = checkbox .. " " .. item.text
      Text.draw_text(text, common_x, current_y, uniform_scale)

      bounds[i] = { x = common_x, y = current_y, width = max_w, height = text_height }
      current_y = current_y + text_height + 40
    end
  end

  local status_y = current_y + 10
  if GlowBenchmark.is_testing() then
    local test_msg = "TESTING GLOW PERFORMANCE..."
    love.graphics.setColor(Colors.cyan)
    Text.draw_centered_text(test_msg, status_y, 0.6)
  elseif GlowBenchmark.get_notice_timer() > 0 then
    local notice_msg = GlowBenchmark.get_notice()
    local notice_color = notice_msg:find("DISABLED") and Colors.crimson or Colors.neon_lime_splash
    love.graphics.setColor(notice_color)
    Text.draw_centered_text(notice_msg, status_y, 0.6)
  end

  local return_text = ScreenUtils.get_return_prompt()

  local return_y = Settings.WINDOW_HEIGHT * 0.92
  ScreenUtils.draw_return_control(return_text, return_y, 0.7)
end

function options.keypressed(key)
  local setting = menu_items[selected_item].setting

  if key == "up" then
    selected_item = math.max(1, selected_item - 1)
    Sound.play("blip")
  elseif key == "down" then
    selected_item = math.min(#menu_items, selected_item + 1)
    Sound.play("blip")
  elseif key == "kp-" or key == "-" or key == "left" then
    if
      menu_items[selected_item].setting == "is_music_volume" or menu_items[selected_item].setting == "is_sfx_volume"
    then
      change_volume(setting, -0.2)
    else
      toggle_setting(setting)
    end
    Sound.play("blip")
  elseif key == "kp+" or key == "+" or key == "right" then
    if
      menu_items[selected_item].setting == "is_music_volume" or menu_items[selected_item].setting == "is_sfx_volume"
    then
      change_volume(setting, 0.2)
    else
      toggle_setting(setting)
    end
    Sound.play("blip")
  elseif key == "return" or key == "space" then
    toggle_setting(setting)
    Sound.play("blip")
  end
end

function options.mousepressed(x, y, button)
  if button ~= 1 then
    return true
  end

  local return_text = ScreenUtils.get_return_prompt()
  local return_y = Settings.WINDOW_HEIGHT * 0.92
  local return_width_percentage = 0.7
  if ScreenUtils.is_return_control_clicked(return_text, return_y, return_width_percentage, x, y) then
    GameState.set(GameState.previous or "attract")
    Sound.play("blip")
    return true
  end

  for i, item_bounds in ipairs(bounds) do
    if
      x > item_bounds.x
      and x < item_bounds.x + item_bounds.width
      and y > item_bounds.y
      and y < item_bounds.y + item_bounds.height
    then
      selected_item = i
      local setting = menu_items[i].setting

      if item_bounds.is_double then
        if y < item_bounds.y + item_bounds.line1_height then
          toggle_setting(setting)
        else
          -- Split the volume bar area in two for decrease/increase
          local bar_center_x = item_bounds.x2 + item_bounds.w2 / 2
          if x < bar_center_x then
            change_volume(setting, -0.2)
          else
            change_volume(setting, 0.2)
          end
        end
      else
        toggle_setting(setting)
      end
      Sound.play("blip")
      return true
    end
  end

  return true
end

return options
