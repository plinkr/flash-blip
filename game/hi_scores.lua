local Colors = require("colors")
local Settings = require("settings")
local Text = require("text")
local PlayerProgress = require("player_progress")
local GameState = require("gamestate")

local hi_scores = {}

local max_display_count = 10
local cache = nil
local uniform_scale = nil
local last_state = nil
local count = 0

local function rebuild_cache()
  local list = PlayerProgress.get_all_high_scores()
  count = math.min(#list, max_display_count)
  if count == 0 then
    cache = nil
    uniform_scale = nil
    return
  end

  cache = {}
  for i = 1, count do
    local entry = list[i]
    local score_text = tostring(math.floor(entry.score))
    local line_text = score_text .. " - " .. entry.source
    table.insert(cache, { text = line_text, score = entry.score, source = entry.source })
  end

  uniform_scale = Text.calculateUniformScale(cache, 0.55)
  local height_factor = Settings.WINDOW_HEIGHT / 800
  local min_scale = 1.1 * height_factor
  local max_scale = 3.5 * height_factor
  uniform_scale = math.max(min_scale, math.min(max_scale, uniform_scale))
end

function hi_scores.update(_dt) end

function hi_scores.draw()
  if GameState.current ~= last_state then
    last_state = GameState.current
    if GameState.current == "hi_scores" then
      rebuild_cache()
    end
  end

  love.graphics.setColor(0, 0, 0, 0.8)
  love.graphics.rectangle("fill", 0, 0, Settings.WINDOW_WIDTH, Settings.WINDOW_HEIGHT)

  love.graphics.setColor(Colors.cyan)
  Text.drawCenteredText("HI SCORES", Settings.WINDOW_HEIGHT * 0.1, 0.75)

  if count == 0 then
    love.graphics.setColor(Colors.white)
    Text.drawCenteredText("NO HIGH SCORES", Settings.WINDOW_HEIGHT * 0.45, 0.6)
  else
    local start_y = Settings.WINDOW_HEIGHT * 0.22
    local spacing = Settings.WINDOW_HEIGHT * 0.055

    for i = 1, count do
      local item = cache[i]
      local y_pos = start_y + (i - 1) * spacing

      if item.score >= 100000 then
        love.graphics.setColor(Colors.tangerine_blaze)
      else
        love.graphics.setColor(Colors.neon_lime_splash)
      end

      local text_width = Text.getTextWidth(item.text, uniform_scale)
      local x_pos = (Settings.WINDOW_WIDTH - text_width) / 2
      Text.drawText(item.text, x_pos, y_pos, uniform_scale)
    end
  end

  Text.drawGameVersion()

  love.graphics.setColor(Colors.white)
  local return_text
  if Settings.IS_MOBILE then
    return_text = "PRESS BACK OR TOUCH TO RETURN"
  else
    return_text = "PRESS ESC OR CLICK TO RETURN"
  end
  Text.drawCenteredText(return_text, Settings.WINDOW_HEIGHT * 0.9, 0.6)
end

function hi_scores.keypressed(_key) end

function hi_scores.mousepressed(_x, _y, _button) end

return hi_scores
