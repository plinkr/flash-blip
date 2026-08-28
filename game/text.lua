local CustomFont = require("custom_font")
local Colors = require("colors")
local Settings = require("settings")

local Text = {}

local UTF8_PATTERN = "[%z\1-\127\194-\244][\128-\191]*"

CustomFont:init()

Text.char_height = CustomFont.char_height

function Text.draw_centered_text(text, y_position, width_percentage, min_scale, max_scale)
  local scale = Text.calculate_scale_for_width(text, width_percentage)

  if min_scale and max_scale then
    local height_factor = Settings.WINDOW_HEIGHT / 800
    min_scale = min_scale * height_factor
    max_scale = math.min(max_scale, max_scale * height_factor)
    scale = math.max(min_scale, math.min(max_scale, scale))
  end

  local text_width = Text.get_text_width(text, scale)
  local x = (Settings.WINDOW_WIDTH - text_width) / 2
  Text.draw_text(text, x, y_position, scale)
end

local function draw_menu_items(menu_items, selected_item, start_y, width_percentage)
  local uniform_scale = Text.calculate_uniform_scale(menu_items, width_percentage)

  local y_pos = start_y
  for i, item in ipairs(menu_items) do
    if i == selected_item then
      love.graphics.setColor(Colors.cyan)
    else
      love.graphics.setColor(Colors.white)
    end
    -- Use the uniform scale for all items
    local text_width = Text.get_text_width(item.text, uniform_scale)
    local x = (Settings.WINDOW_WIDTH - text_width) / 2
    Text.draw_text(item.text, x, y_pos, uniform_scale)
    item.y = y_pos -- Store y position for click detection
    item.height = Text.get_text_height(uniform_scale) -- Uniform height based on uniform scale
    y_pos = y_pos + 50
  end
end

local function draw_high_score_flash(hi_score, is_new_hi_score, hi_score_flash_visible)
  if is_new_hi_score and hi_score_flash_visible then
    love.graphics.setColor(Colors.neon_lime_splash)
    Text.draw_centered_text("NEW HIGH", Settings.WINDOW_HEIGHT * 0.08, 0.8)
    Text.draw_centered_text("SCORE!", Settings.WINDOW_HEIGHT * 0.18, 0.55)
    Text.draw_centered_text(tostring(math.floor(hi_score)), Settings.WINDOW_HEIGHT * 0.27, 0.5, 12.0, 15.0)
  end
end

local function draw_continue_prompt(action_text, action_text_size, prompt_y, action_y)
  local input_prompt
  if Settings.IS_MOBILE then
    input_prompt = "TOUCH / TAP ON SCREEN"
  else
    input_prompt = "PRESS SPACE OR CLICK"
  end

  love.graphics.setColor(Colors.white)
  Text.draw_centered_text(input_prompt, prompt_y, 0.9)
  Text.draw_centered_text(action_text, action_y, action_text_size)
end

function Text.draw_attract(menu_items, selected_item)
  love.graphics.setColor(0, 0, 0, 0.5)
  love.graphics.rectangle("fill", 0, 0, Settings.WINDOW_WIDTH, Settings.WINDOW_HEIGHT)
  love.graphics.setColor(Colors.cyan)
  Text.draw_centered_text("FLASH-BLIP", Settings.WINDOW_HEIGHT * 0.15, 0.95)

  draw_menu_items(menu_items, selected_item, Settings.WINDOW_HEIGHT * 0.4, 0.55)

  Text.draw_game_version()
  love.graphics.setColor(1, 1, 1)
end

function Text.draw_game_version()
  love.graphics.setColor(Colors.light_blue_glow)
  local game_version_scale = Text.calculate_scale_for_width(GAME_VERSION, 0.09)
  local game_version_width = Text.get_text_width(GAME_VERSION, game_version_scale)
  Text.draw_text(
    GAME_VERSION,
    (Settings.WINDOW_WIDTH - game_version_width) * 0.97,
    Settings.WINDOW_HEIGHT * 0.97,
    game_version_scale
  )
end

function Text.draw_pause_menu(menu_items, selected_item, level_id)
  love.graphics.setColor(0, 0, 0, 0.65)
  love.graphics.rectangle("fill", 0, 0, Settings.WINDOW_WIDTH, Settings.WINDOW_HEIGHT)
  love.graphics.setColor(Colors.cyan)
  Text.draw_centered_text("PAUSED", Settings.WINDOW_HEIGHT * 0.25, 0.6)

  if level_id then
    local level_text = "LEVEL " .. level_id
    love.graphics.setColor(Colors.spring_green)
    Text.draw_centered_text(level_text, Settings.WINDOW_HEIGHT * 0.35, 0.3)
  end

  draw_menu_items(menu_items, selected_item, Settings.WINDOW_HEIGHT * 0.5, 0.5)

  love.graphics.setColor(1, 1, 1)
end

function Text.draw_game_over(hi_score, is_new_hi_score, hi_score_flash_visible)
  love.graphics.setColor(0, 0, 0, 0.65)
  love.graphics.rectangle("fill", 0, 0, Settings.WINDOW_WIDTH, Settings.WINDOW_HEIGHT)

  draw_high_score_flash(hi_score, is_new_hi_score, hi_score_flash_visible)

  love.graphics.setColor(Colors.naranja_rojo)
  Text.draw_centered_text("GAME OVER", Settings.WINDOW_HEIGHT * 0.4, 0.9)

  draw_continue_prompt("TO RESTART", 0.45, Settings.WINDOW_HEIGHT * 0.55, Settings.WINDOW_HEIGHT * 0.6)
end

local function draw_completion_background(hi_score, is_new_hi_score, hi_score_flash_visible)
  love.graphics.setColor(0, 0, 0, 0.65)
  love.graphics.rectangle("fill", 0, 0, Settings.WINDOW_WIDTH, Settings.WINDOW_HEIGHT)

  draw_high_score_flash(hi_score, is_new_hi_score, hi_score_flash_visible)
end

function Text.draw_level_completed(hi_score, is_new_hi_score, hi_score_flash_visible)
  draw_completion_background(hi_score, is_new_hi_score, hi_score_flash_visible)

  love.graphics.setColor(Colors.neon_lime_splash)
  Text.draw_centered_text("LEVEL", Settings.WINDOW_HEIGHT * 0.4, 0.5)
  Text.draw_centered_text("COMPLETED!", Settings.WINDOW_HEIGHT * 0.5, 0.9)

  draw_continue_prompt("TO CONTINUE", 0.5, Settings.WINDOW_HEIGHT * 0.7, Settings.WINDOW_HEIGHT * 0.75)
end

function Text.draw_all_levels_completed(hi_score, is_new_hi_score, hi_score_flash_visible)
  draw_completion_background(hi_score, is_new_hi_score, hi_score_flash_visible)

  love.graphics.setColor(Colors.neon_lime_splash)
  Text.draw_centered_text("YOU COMPLETED", Settings.WINDOW_HEIGHT * 0.4, 0.95)
  Text.draw_centered_text("ALL LEVELS!", Settings.WINDOW_HEIGHT * 0.48, 0.8)
  Text.draw_centered_text("A GREAT FEAT!", Settings.WINDOW_HEIGHT * 0.56, 0.9)

  draw_continue_prompt()
end

function Text.draw_score(score, hi_score, is_multiplying)
  local current_score_text = tostring(math.floor(score))
  local score_color = Colors.white
  local score_scale = Text.calculate_scale_for_width(current_score_text, 0.15)

  if is_multiplying then
    current_score_text = current_score_text .. " X4"
    score_scale = Text.calculate_scale_for_width(current_score_text, 0.4)
    score_color = Colors.yellow
  end

  -- Apply min/max scale based on window height
  local height_factor = Settings.WINDOW_HEIGHT / 800
  local min_scale = 3 * height_factor
  local max_scale = 5 * height_factor
  score_scale = math.max(min_scale, math.min(max_scale, score_scale))

  love.graphics.setColor(score_color)
  local current_score_text_height = Text.get_text_height(score_scale)
  -- Bottom left Score
  Text.draw_text(current_score_text, 10, Settings.WINDOW_HEIGHT - current_score_text_height - 10, score_scale)

  love.graphics.setColor(Colors.white)
  local hi_score_text = "HI: " .. math.floor(hi_score)
  local hi_score_scale = Text.calculate_scale_for_width(hi_score_text, 0.15)
  hi_score_scale = math.max(min_scale, math.min(max_scale, hi_score_scale))
  local hi_score_text_width = Text.get_text_width(hi_score_text, hi_score_scale)
  local hi_score_text_height = Text.get_text_height(hi_score_scale)
  -- Bootom right High Score
  Text.draw_text(
    hi_score_text,
    Settings.WINDOW_WIDTH - hi_score_text_width - 10,
    Settings.WINDOW_HEIGHT - hi_score_text_height - 10,
    hi_score_scale
  )
end

function Text.draw_level_progress(current, total, final_color)
  local progress = math.min(1, current / total)
  -- Bar size to just below the drawing position of the bolt powerup
  local bar_height = Settings.WINDOW_HEIGHT * 0.29
  local bar_width = 4
  local margin = 12
  local x = Settings.WINDOW_WIDTH - margin
  -- Starting position it just above the Hi Score area
  local hi_score_area_height = Settings.WINDOW_HEIGHT * 0.05
  local y = Settings.WINDOW_HEIGHT - hi_score_area_height

  -- Background track (dim black bar)
  love.graphics.setColor(0, 0, 0, 0.8)
  love.graphics.rectangle("fill", x, y - bar_height, bar_width, bar_height, 1, 1)

  -- Completion Fill (Bottom to Top)
  local start_color = Colors.periwinkle_mist
  local end_color = final_color or Colors.antique_gold
  local fill_color = Colors.lerp(start_color, end_color, progress)

  love.graphics.setColor(fill_color)
  local current_height = bar_height * progress
  love.graphics.rectangle("fill", x, y - current_height, bar_width, current_height, 1, 1)

  -- Percentage text
  local percent_value = math.floor(progress * 100)
  local percent_text = tostring(percent_value) .. "%"
  -- Use a fixed reference to calculate scale so it doesn't change as numbers grow
  local percent_scale = Text.calculate_scale_for_width("100", 0.05)
  local percent_width = Text.get_text_width(percent_text, percent_scale)
  local percent_height = Text.get_text_height(percent_scale)

  love.graphics.setColor(fill_color)
  Text.draw_text(percent_text, x - percent_width - 2, y - current_height - (percent_height / 2), percent_scale)

  love.graphics.setColor(1, 1, 1, 1)
end

function Text.draw_text_by_percentage(text, x_position, y_position, width_percentage)
  local scale = Text.calculate_scale_for_width(text, width_percentage)
  Text.draw_text(text, x_position, y_position, scale)
end

function Text.draw_text(text, x, y, scale)
  scale = scale or 1
  local current_x = x or 0

  -- Display block characters such as █.
  for raw_char in text:gmatch(UTF8_PATTERN) do
    local char = string.upper(raw_char)
    local glyph = CustomFont.glyphs[char]

    if glyph then
      for row = 1, #glyph do
        for col = 1, #glyph[row] do
          if glyph[row]:sub(col, col) ~= " " then
            love.graphics.rectangle("fill", current_x + (col - 1) * scale, y + (row - 1) * scale, scale, scale)
          end
        end
      end

      local width = CustomFont.glyph_widths[char] or CustomFont.space_width
      current_x = current_x + (width + CustomFont.tracking) * scale
    else
      -- Character not found, advance as a space
      current_x = current_x + (CustomFont.space_width + CustomFont.tracking) * scale
    end
  end
end

function Text.get_text_width(text, scale)
  scale = scale or 1
  local total_width = 0
  for raw_char in text:gmatch(UTF8_PATTERN) do
    local char = string.upper(raw_char)
    local width = CustomFont.glyph_widths[char] or CustomFont.space_width
    total_width = total_width + (width + CustomFont.tracking) * scale
  end
  return total_width
end

function Text.get_text_height(scale)
  scale = scale or 1
  return CustomFont.char_height * scale
end

function Text.calculate_scale_for_width(text, width_percentage)
  local target_width = Settings.WINDOW_WIDTH * width_percentage
  local text_width_at_scale1 = Text.get_text_width(text, 1)
  if text_width_at_scale1 == 0 then
    return 1
  end
  return target_width / text_width_at_scale1
end

function Text.calculate_uniform_scale(menu_items, width_percentage)
  -- Find the text with the maximum width at scale 1 to determine the uniform scale
  local max_width = 0
  local max_width_text = ""
  for _, item in ipairs(menu_items) do
    local text_width = Text.get_text_width(item.text, 1)
    if text_width > max_width then
      max_width = text_width
      max_width_text = item.text
    end
  end
  -- Calculate the uniform scale based on the longest text
  return Text.calculate_scale_for_width(max_width_text, width_percentage)
end

return Text
