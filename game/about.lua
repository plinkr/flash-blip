local Colors = require("colors")
local Settings = require("settings")
local Text = require("text")
local GameState = require("gamestate")
local ScreenUtils = require("screen_utils")

local about = {}
local RETURN_Y_PERCENTAGE = 0.9
local RETURN_WIDTH_PERCENTAGE = 0.6

local link_items = {
  {
    text = "LICENSED UNDER MIT",
    url = "https://github.com/plinkr/flash-blip?tab=MIT-1-ov-file",
    y_percentage = 0.5,
    width_percentage = 0.8,
  },
  {
    text = "https://github.com/plinkr/flash-blip",
    url = "https://github.com/plinkr/flash-blip",
    y_percentage = 0.75,
    width_percentage = 0.95,
  },
}

local function update_link_bounds()
  for _, item in ipairs(link_items) do
    local scale = Text.calculate_scale_for_width(item.text, item.width_percentage)
    local width = Text.get_text_width(item.text, scale)
    item.bounds = {
      x = (Settings.WINDOW_WIDTH - width) / 2,
      y = Settings.WINDOW_HEIGHT * item.y_percentage,
      width = width,
      height = Text.get_text_height(scale),
    }
  end
end

local function is_point_in_bounds(x, y, bounds)
  return x > bounds.x and x < bounds.x + bounds.width and y > bounds.y and y < bounds.y + bounds.height
end

function about.load() end

function about.update(_dt) end

function about.draw()
  update_link_bounds()

  love.graphics.setColor(0, 0, 0, 0.8)
  love.graphics.rectangle("fill", 0, 0, Settings.WINDOW_WIDTH, Settings.WINDOW_HEIGHT)

  love.graphics.setColor(Colors.cyan)
  Text.draw_centered_text("ABOUT", Settings.WINDOW_HEIGHT * 0.1, 0.45)

  love.graphics.setColor(Colors.neon_lime_splash)
  local description1 = "A FAST-PACED, RETRO-STYLE ARCADE"
  local description2 = "VERTICAL SCROLLER IN LOVE2D"
  local description3 = "SURVIVE AND AIM FOR THE HIGH SCORE!"
  Text.draw_centered_text(description1, Settings.WINDOW_HEIGHT * 0.24, 0.95)
  Text.draw_centered_text(description2, Settings.WINDOW_HEIGHT * 0.27, 0.80)
  Text.draw_centered_text(description3, Settings.WINDOW_HEIGHT * 0.30, 0.96)

  for _, item in ipairs(link_items) do
    Text.draw_centered_text(item.text, item.bounds.y, item.width_percentage)
  end

  local line_kenta_cho = "INSPIRED BY THE WORK OF KENTA CHO"
  Text.draw_centered_text(line_kenta_cho, Settings.WINDOW_HEIGHT * 0.70, 0.9)

  Text.draw_game_version()

  local return_text = ScreenUtils.get_return_prompt()
  local return_y = Settings.WINDOW_HEIGHT * RETURN_Y_PERCENTAGE
  ScreenUtils.draw_return_control(return_text, return_y, RETURN_WIDTH_PERCENTAGE)
end

function about.keypressed(_key) end

function about.mousepressed(x, y, button)
  if button == 1 then
    update_link_bounds()

    local return_text = ScreenUtils.get_return_prompt()
    local return_y = Settings.WINDOW_HEIGHT * RETURN_Y_PERCENTAGE
    if ScreenUtils.is_return_control_clicked(return_text, return_y, RETURN_WIDTH_PERCENTAGE, x, y) then
      GameState.set(GameState.previous or "attract")
      return true
    end

    for _, item in ipairs(link_items) do
      if is_point_in_bounds(x, y, item.bounds) then
        love.system.openURL(item.url)
        return true
      end
    end
  end
  return true
end

return about
