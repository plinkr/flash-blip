local Colors = require("colors")
local Settings = require("settings")
local Text = require("text")
local Sound = require("sound")
local Music = require("music")

local options = {}

local menu_items = {
  { text = "MUSIC", setting = "is_music_enabled" },
  { text = "SFX", setting = "is_sfx_enabled" },
}
local selected_item = 1
local bounds = {}

local function toggle_setting(setting)
  if setting == "is_music_enabled" then
    Settings.IS_MUSIC_ENABLED = not Settings.IS_MUSIC_ENABLED
    Music.toggle_mute(not Settings.IS_MUSIC_ENABLED)
  elseif setting == "is_sfx_enabled" then
    Settings.IS_SFX_ENABLED = not Settings.IS_SFX_ENABLED
    Sound.toggle_mute(not Settings.IS_SFX_ENABLED)
  end
end

function options.load()
  selected_item = 1
end

function options.update(dt) end

function options.draw()
  love.graphics.setColor(0, 0, 0, 0.85)
  love.graphics.rectangle("fill", 0, 0, Settings.WINDOW_WIDTH, Settings.WINDOW_HEIGHT)

  love.graphics.setColor(Colors.cyan)
  Text.drawCenteredText("OPTIONS", Settings.WINDOW_HEIGHT * 0.1, 0.7)

  local y_start = Settings.WINDOW_HEIGHT * 0.4
  local y_spacing = 70
  local width_percentage = 0.6

  -- Create a list of potential menu item texts to calculate a uniform scale
  local items_for_scaling = {}
  for _, item in ipairs(menu_items) do
    -- Use the longest possible text for stable scaling
    table.insert(items_for_scaling, { text = item.text .. " - YES" })
  end
  local uniform_scale = Text.calculateUniformScale(items_for_scaling, width_percentage)

  for i, item in ipairs(menu_items) do
    local y = y_start + (i - 1) * y_spacing
    local is_selected = (i == selected_item)
    local is_on = Settings[item.setting:upper()]

    local color
    if not Settings.IS_MOBILE and is_selected then
      color = Colors.cyan
    else
      if is_on then
        color = Colors.neon_lime_splash
      else
        color = Colors.naranjaRojo
      end
    end
    love.graphics.setColor(color)

    local checkbox_char = is_on and "YES" or "NO"
    local text = item.text .. " - " .. checkbox_char

    local text_width = Text.getTextWidth(text, uniform_scale)
    local x = (Settings.WINDOW_WIDTH - text_width) / 2
    Text.drawText(text, x, y, uniform_scale)

    -- Recalculate bounds for mouse input using the uniform scale
    local text_height = Text.getTextHeight(uniform_scale)
    bounds[i] = {
      x = x,
      y = y,
      width = text_width,
      height = text_height,
    }
  end

  love.graphics.setColor(Colors.white)
  local returnText
  if Settings.IS_MOBILE then
    returnText = "PRESS BACK OR TOUCH TO RETURN"
  else
    returnText = "PRESS ESC OR CLICK TO RETURN"
  end
  Text.drawCenteredText(returnText, Settings.WINDOW_HEIGHT * 0.9, 0.6)
end

function options.keypressed(key)
  if key == "up" then
    selected_item = math.max(1, selected_item - 1)
    Sound.play("blip")
  elseif key == "down" then
    selected_item = math.min(#menu_items, selected_item + 1)
    Sound.play("blip")
  elseif key == "return" or key == "space" then
    toggle_setting(menu_items[selected_item].setting)
    Sound.play("blip")
  end
end

function options.mousepressed(x, y, button)
  if button == 1 then
    for i, item_bounds in ipairs(bounds) do
      if
        x > item_bounds.x
        and x < item_bounds.x + item_bounds.width
        and y > item_bounds.y
        and y < item_bounds.y + item_bounds.height
      then
        selected_item = i
        toggle_setting(menu_items[i].setting)
        Sound.play("blip")
        return true
      end
    end
  end
  return false
end

return options
