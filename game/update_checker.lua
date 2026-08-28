local Colors = require("colors")
local GameState = require("gamestate")
local Settings = require("settings")
local Text = require("text")
local HttpClient = require("http_client")

local UpdateChecker = {}

UpdateChecker.RELEASES_BASE_URL = "https://github.com/plinkr/flash-blip/releases/tag/"

local VERSION_ENDPOINT = "/game_version"
local CHECK_TIMEOUT_SECONDS = 5
local NOTICE_WIDTH_PERCENTAGE = 0.3
local HIT_PADDING_X_PERCENTAGE = 0.02
local HIT_PADDING_Y_PERCENTAGE = 0.015

local state
local started = false

function UpdateChecker.parse_tag(raw)
  if type(raw) ~= "string" then
    return nil
  end
  return raw:match('"tag_name"%s*:%s*"([^"]+)"')
end

local function strip_version_prefix(version)
  if type(version) ~= "string" then
    return ""
  end
  return (version:gsub("^[vV]+", ""))
end

local function split_numeric_segments(version)
  local segments = {}
  for part in version:gmatch("[^.]+") do
    local num = tonumber(part)
    if not num then
      return nil
    end
    table.insert(segments, num)
  end
  if #segments == 0 then
    return nil
  end
  return segments
end

function UpdateChecker.is_newer(current, candidate)
  local current_segments = split_numeric_segments(strip_version_prefix(current))
  local candidate_segments = split_numeric_segments(strip_version_prefix(candidate))
  if not current_segments or not candidate_segments then
    return false
  end

  for i = 1, math.max(#current_segments, #candidate_segments) do
    local current_n = current_segments[i] or 0
    local candidate_n = candidate_segments[i] or 0
    if candidate_n > current_n then
      return true
    elseif candidate_n < current_n then
      return false
    end
  end
  return false
end

local function layout_notice(tag)
  local text = " █ UPDATE: " .. tag:upper() .. " █"
  local scale = Text.calculate_scale_for_width(text, NOTICE_WIDTH_PERCENTAGE)
  local width = Text.get_text_width(text, scale)
  local height = Text.get_text_height(scale)
  local padding_x = Settings.WINDOW_WIDTH * HIT_PADDING_X_PERCENTAGE
  local padding_y = Settings.WINDOW_HEIGHT * HIT_PADDING_Y_PERCENTAGE

  local draw_x = (Settings.WINDOW_WIDTH - width) * 0.03
  local draw_y = Settings.WINDOW_HEIGHT * 0.97
  local bounds = {
    x = draw_x - padding_x,
    y = draw_y - padding_y,
    width = width + padding_x * 2,
    height = height + padding_y * 2,
  }

  return {
    text = text,
    scale = scale,
    draw_x = draw_x,
    draw_y = draw_y,
    bounds = bounds,
  }
end

function UpdateChecker.start()
  if started then
    return
  end
  started = true

  HttpClient.get(VERSION_ENDPOINT, function(ok, _status, data)
    if not ok then
      return
    end
    local tag = UpdateChecker.parse_tag(data)
    if tag and UpdateChecker.is_newer(GAME_VERSION, tag) then
      state = {
        tag = tag,
        url = UpdateChecker.RELEASES_BASE_URL .. tag,
        layout = layout_notice(tag),
      }
    end
  end, { timeout = CHECK_TIMEOUT_SECONDS })
end

function UpdateChecker.draw()
  if not state or not state.layout then
    return
  end

  local layout = state.layout
  love.graphics.setColor(Colors.neon_lime_splash)
  Text.draw_text(layout.text, layout.draw_x, layout.draw_y, layout.scale)
  love.graphics.setColor(Colors.white)
end

local function is_point_in_bounds(x, y, bounds)
  return x > bounds.x and x < bounds.x + bounds.width and y > bounds.y and y < bounds.y + bounds.height
end

function UpdateChecker.handle_click(x, y)
  if not state or not state.layout then
    return false
  end
  if GameState.ignore_input_timer > 0 and not GameState.is_paused then
    return false
  end
  if not is_point_in_bounds(x, y, state.layout.bounds) then
    return false
  end
  love.system.openURL(state.url)
  return true
end

return UpdateChecker
