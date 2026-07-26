local Colors = require("colors")
local Settings = require("settings")
local Text = require("text")
local PlayerProgress = require("player_progress")
local GameState = require("gamestate")

local hi_scores = {}

local max_display_count = 10
local cache = nil
local uniform_scale = nil
local count = 0

local view_mode = "local"
local global_page = 1
local global_cache = nil
local last_global_fetch_time = 0
local global_fetch_error = nil
local global_loading = false
local global_display_cache = nil
local uniform_scale_global = nil

local loading_base = "LOADING GLOBAL SCORES"
local loading_dots = { "", ".", "..", "..." }
local loading_index = 1
local loading_timer = 0
local loading_delay = 0.25

local function rebuild_global_display()
  if not global_cache or #global_cache == 0 then
    global_display_cache = nil
    uniform_scale_global = nil
    return
  end

  global_display_cache = {}
  local start_idx = (global_page - 1) * 10 + 1
  local end_idx = math.min(global_page * 10, #global_cache)
  for idx = start_idx, end_idx do
    local entry = global_cache[idx]
    local line_text = string.format("%d. %s - %d", idx, entry.player, math.floor(entry.score))
    table.insert(global_display_cache, { text = line_text, score = entry.score, player = entry.player })
  end

  uniform_scale_global = Text.calculateUniformScale(global_display_cache, 0.55)
  local height_factor = Settings.WINDOW_HEIGHT / 800
  local min_scale = 1.1 * height_factor
  local max_scale = 3.5 * height_factor
  uniform_scale_global = math.max(min_scale, math.min(max_scale, uniform_scale_global))
end

local function rebuild_cache()
  local list = PlayerProgress.get_all_high_scores()
  count = math.min(#list, max_display_count)
  if count == 0 then
    cache = nil
    uniform_scale = nil
  else
    cache = {}
    for i = 1, count do
      local entry = list[i]
      local score_text = tostring(math.floor(entry.score))
      local line_text = entry.source .. " - " .. score_text
      table.insert(cache, { text = line_text, score = entry.score, source = entry.source })
    end

    uniform_scale = Text.calculateUniformScale(cache, 0.55)
    local height_factor = Settings.WINDOW_HEIGHT / 800
    local min_scale = 1.1 * height_factor
    local max_scale = 3.5 * height_factor
    uniform_scale = math.max(min_scale, math.min(max_scale, uniform_scale))
  end

  local now = love.timer.getTime()
  local needs_fetch = (not global_cache and not global_loading and not global_fetch_error)
    or (now - last_global_fetch_time > 60 and not global_loading)
    or (GameState.has_played_since_hi_scores and not global_loading)

  if needs_fetch then
    GameState.has_played_since_hi_scores = false
    global_loading = true
    loading_index = 1
    loading_timer = 0
    global_fetch_error = nil

    local HighscoreManager = require("highscore_manager")
    HighscoreManager.start_download()
    last_global_fetch_time = now
  end
end

local function is_hovering(ax, ay, rx, ry)
  local mx, my = love.mouse.getPosition()
  return math.abs(mx - ax) <= rx and math.abs(my - ay) <= ry
end

local function draw_arrow(direction, x, y, size, color)
  love.graphics.setColor(color)
  if direction == "right" then
    love.graphics.polygon("fill", x - size / 2, y - size, x + size, y, x - size / 2, y + size)
  elseif direction == "left" then
    love.graphics.polygon("fill", x + size / 2, y - size, x - size, y, x + size / 2, y + size)
  elseif direction == "up" then
    love.graphics.polygon("fill", x - size, y + size / 2, x, y - size, x + size, y + size / 2)
  elseif direction == "down" then
    love.graphics.polygon("fill", x - size, y - size / 2, x, y + size, x + size, y - size / 2)
  end
end

function hi_scores.update(dt)
  local HighscoreManager = require("highscore_manager")
  if HighscoreManager.is_downloading() then
    HighscoreManager.poll_download(function(success, data)
      global_loading = false
      if success then
        global_cache = data
        global_fetch_error = nil
        rebuild_global_display()
      else
        global_cache = nil
        global_fetch_error = data
      end
    end)
  end

  loading_timer = loading_timer + dt
  if loading_timer >= loading_delay then
    loading_timer = 0
    loading_index = (loading_index % #loading_dots) + 1
  end
end

function hi_scores.draw()
  if GameState.hi_scores_dirty then
    GameState.hi_scores_dirty = false
    view_mode = "local"
    global_page = 1
    loading_index = 1
    loading_timer = 0
    rebuild_cache()
  end

  love.graphics.setColor(0, 0, 0, 0.8)
  love.graphics.rectangle("fill", 0, 0, Settings.WINDOW_WIDTH, Settings.WINDOW_HEIGHT)

  love.graphics.setColor(Colors.cyan)
  if view_mode == "local" then
    Text.drawCenteredText("LOCAL HI SCORES", Settings.WINDOW_HEIGHT * 0.1, 0.75)
  else
    Text.drawCenteredText("GLOBAL HI SCORES", Settings.WINDOW_HEIGHT * 0.1, 0.75)
  end

  local top_boundary = Settings.WINDOW_HEIGHT * 0.18
  local bottom_boundary = Settings.WINDOW_HEIGHT * 0.80
  local start_y = Settings.WINDOW_HEIGHT * 0.22
  local spacing = Settings.WINDOW_HEIGHT * 0.055

  love.graphics.setScissor(0, top_boundary, Settings.WINDOW_WIDTH, bottom_boundary - top_boundary)

  if view_mode == "local" then
    if count == 0 then
      love.graphics.setColor(Colors.white)
      Text.drawCenteredText("NO HIGH SCORES", Settings.WINDOW_HEIGHT * 0.45, 0.6)
    else
      if cache then
        for i = 1, count do
          local item = cache[i]
          if item then
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
      end
    end
  else
    if global_loading then
      love.graphics.setColor(Colors.white)
      local full_text = loading_base .. "..."
      local scale = Text.calculateScaleForWidth(full_text, 0.5)
      local height_factor = Settings.WINDOW_HEIGHT / 800
      scale = math.max(0.5 * height_factor, scale)
      local full_width = Text.getTextWidth(full_text, scale)
      local x_start = (Settings.WINDOW_WIDTH - full_width) / 2
      local display_text = loading_base .. loading_dots[loading_index]
      Text.drawText(display_text, x_start, Settings.WINDOW_HEIGHT * 0.45, scale)
    elseif global_fetch_error then
      love.graphics.setColor(Colors.crimson)
      Text.drawCenteredText("CONNECTION ERROR", Settings.WINDOW_HEIGHT * 0.42, 0.55)
      love.graphics.setColor(Colors.white)
      Text.drawCenteredText("NO GLOBAL HIGH SCORES", Settings.WINDOW_HEIGHT * 0.52, 0.45)
    elseif not global_cache or #global_cache == 0 then
      love.graphics.setColor(Colors.white)
      Text.drawCenteredText("NO GLOBAL HIGH SCORES", Settings.WINDOW_HEIGHT * 0.45, 0.6)
    else
      if global_display_cache then
        for i = 1, #global_display_cache do
          local item = global_display_cache[i]
          if item then
            local y_pos = start_y + (i - 1) * spacing
            if item.score >= 100000 then
              love.graphics.setColor(Colors.tangerine_blaze)
            else
              love.graphics.setColor(Colors.neon_lime_splash)
            end

            local text_width = Text.getTextWidth(item.text, uniform_scale_global)
            local x_pos = (Settings.WINDOW_WIDTH - text_width) / 2
            Text.drawText(item.text, x_pos, y_pos, uniform_scale_global)
          end
        end
      end
    end
  end

  love.graphics.setScissor()

  local arrow_size = 12 * (Settings.WINDOW_HEIGHT / 800)

  if view_mode == "local" then
    local rx = Settings.WINDOW_WIDTH - 35
    local ry = Settings.WINDOW_HEIGHT * 0.5
    local r_hovered = is_hovering(rx, ry, 25, 25)
    local r_color = r_hovered and Colors.neon_lime_splash or Colors.cyan
    draw_arrow("right", rx, ry, arrow_size, r_color)
  else
    local lx = 35
    local ly = Settings.WINDOW_HEIGHT * 0.5
    local l_hovered = is_hovering(lx, ly, 25, 25)
    local l_color = l_hovered and Colors.neon_lime_splash or Colors.cyan
    draw_arrow("left", lx, ly, arrow_size, l_color)

    if global_cache and #global_cache > 0 then
      if global_page > 1 then
        local ux = Settings.WINDOW_WIDTH / 2 - 40
        local uy = Settings.WINDOW_HEIGHT * 0.83
        local u_hovered = is_hovering(ux, uy, 25, 25)
        local u_color = u_hovered and Colors.neon_lime_splash or Colors.cyan
        draw_arrow("up", ux, uy, arrow_size, u_color)
      end

      if #global_cache > global_page * 10 and global_page < 10 then
        local dx = Settings.WINDOW_WIDTH / 2 + 40
        local dy = Settings.WINDOW_HEIGHT * 0.83
        local d_hovered = is_hovering(dx, dy, 25, 25)
        local d_color = d_hovered and Colors.neon_lime_splash or Colors.cyan
        draw_arrow("down", dx, dy, arrow_size, d_color)
      end
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
  Text.drawCenteredText(return_text, Settings.WINDOW_HEIGHT * 0.92, 0.5)
end

function hi_scores.keypressed(_key) end

function hi_scores.mousepressed(x, y, button)
  if button ~= 1 then
    return false
  end

  local function in_bounds(bx, by, rx, ry)
    return math.abs(x - bx) <= rx and math.abs(y - by) <= ry
  end

  if view_mode == "local" then
    local rx = Settings.WINDOW_WIDTH - 35
    local ry = Settings.WINDOW_HEIGHT * 0.5
    if in_bounds(rx, ry, 25, 25) then
      view_mode = "global"
      global_page = 1
      rebuild_global_display()
      local Sound = require("sound")
      Sound.play("blip")
      return true
    end
  else
    local lx = 35
    local ly = Settings.WINDOW_HEIGHT * 0.5
    if in_bounds(lx, ly, 25, 25) then
      view_mode = "local"
      local Sound = require("sound")
      Sound.play("blip")
      return true
    end

    if global_cache and #global_cache > 0 then
      if global_page > 1 then
        local ux = Settings.WINDOW_WIDTH / 2 - 40
        local uy = Settings.WINDOW_HEIGHT * 0.83
        if in_bounds(ux, uy, 25, 25) then
          global_page = global_page - 1
          rebuild_global_display()
          local Sound = require("sound")
          Sound.play("blip")
          return true
        end
      end

      if #global_cache > global_page * 10 and global_page < 10 then
        local dx = Settings.WINDOW_WIDTH / 2 + 40
        local dy = Settings.WINDOW_HEIGHT * 0.83
        if in_bounds(dx, dy, 25, 25) then
          global_page = global_page + 1
          rebuild_global_display()
          local Sound = require("sound")
          Sound.play("blip")
          return true
        end
      end
    end
  end

  return false
end

return hi_scores
