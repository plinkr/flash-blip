local Colors = require("colors")
local Settings = require("settings")
local Text = require("text")
local PlayerProgress = require("player_progress")
local GameState = require("gamestate")
local HighscoreManager = require("highscore_manager")
local Sound = require("sound")
local ScreenUtils = require("screen_utils")

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
local local_layout = nil
local global_layout = nil

local loading_base = "LOADING GLOBAL SCORES"
local loading_dots = { "", ".", "..", "..." }
local loading_index = 1
local loading_timer = 0
local loading_delay = 0.25

local function rebuild_global_display()
  if not global_cache or #global_cache == 0 then
    global_display_cache = nil
    uniform_scale_global = nil
    global_layout = nil
    return
  end

  global_display_cache = {}
  local start_idx = (global_page - 1) * 10 + 1
  local end_idx = math.min(global_page * 10, #global_cache)
  for idx = start_idx, end_idx do
    local entry = global_cache[idx]
    local rank_str = string.format("%d.", idx)
    local name_str = entry.player or "UNKNOWN"
    local score_str = tostring(math.floor(entry.score))
    table.insert(global_display_cache, {
      rank_str = rank_str,
      name_str = name_str,
      score_str = score_str,
      score = entry.score,
    })
  end

  local gap1 = Text.get_text_width("  ", 1)
  local gap2 = Text.get_text_width("   ", 1)
  local max_rank_w1 = 0
  local max_row_w1 = 0

  for _, item in ipairs(global_display_cache) do
    local r_w1 = Text.get_text_width(item.rank_str, 1)
    local n_w1 = Text.get_text_width(item.name_str, 1)
    local s_w1 = Text.get_text_width(item.score_str, 1)
    if r_w1 > max_rank_w1 then
      max_rank_w1 = r_w1
    end
    local row_w1 = r_w1 + gap1 + n_w1 + gap2 + s_w1
    if row_w1 > max_row_w1 then
      max_row_w1 = row_w1
    end
  end

  local target_pct = 0.75
  local target_width = Settings.WINDOW_WIDTH * target_pct
  local scale = target_width / (max_row_w1 > 0 and max_row_w1 or 1)
  local height_factor = Settings.WINDOW_HEIGHT / 800
  local min_scale = 1.2 * height_factor
  local max_scale = 4.5 * height_factor
  uniform_scale_global = math.max(min_scale, math.min(max_scale, scale))

  global_layout = {
    max_rank_w1 = max_rank_w1,
    max_row_w1 = max_row_w1,
    gap1 = gap1,
  }
end

local function rebuild_cache()
  local list = PlayerProgress.get_all_high_scores()
  count = math.min(#list, max_display_count)
  if count == 0 then
    cache = nil
    uniform_scale = nil
    local_layout = nil
  else
    cache = {}
    for i = 1, count do
      local entry = list[i]
      local rank_str = string.format("%d.", i)
      local name_str = entry.source or ""
      local score_str = tostring(math.floor(entry.score))
      table.insert(cache, {
        rank_str = rank_str,
        name_str = name_str,
        score_str = score_str,
        score = entry.score,
      })
    end

    local gap1 = Text.get_text_width("  ", 1)
    local gap2 = Text.get_text_width("   ", 1)
    local max_rank_w1 = 0
    local max_row_w1 = 0

    for _, item in ipairs(cache) do
      local r_w1 = Text.get_text_width(item.rank_str, 1)
      local n_w1 = Text.get_text_width(item.name_str, 1)
      local s_w1 = Text.get_text_width(item.score_str, 1)
      if r_w1 > max_rank_w1 then
        max_rank_w1 = r_w1
      end
      local row_w1 = r_w1 + gap1 + n_w1 + gap2 + s_w1
      if row_w1 > max_row_w1 then
        max_row_w1 = row_w1
      end
    end

    local target_pct = 0.75
    local target_width = Settings.WINDOW_WIDTH * target_pct
    local scale = target_width / (max_row_w1 > 0 and max_row_w1 or 1)
    local height_factor = Settings.WINDOW_HEIGHT / 800
    local min_scale = 1.2 * height_factor
    local max_scale = 4.5 * height_factor
    uniform_scale = math.max(min_scale, math.min(max_scale, scale))

    local_layout = {
      max_rank_w1 = max_rank_w1,
      max_row_w1 = max_row_w1,
      gap1 = gap1,
    }
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

    HighscoreManager.start_download()
    last_global_fetch_time = now
  end
end

local function is_hovering(ax, ay, rx, ry)
  local mx, my = love.mouse.getPosition()
  return math.abs(mx - ax) <= rx and math.abs(my - ay) <= ry
end

function hi_scores.update(dt)
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
    Text.draw_centered_text("LOCAL HI SCORES", Settings.WINDOW_HEIGHT * 0.1, 0.75)
  else
    Text.draw_centered_text("GLOBAL HI SCORES", Settings.WINDOW_HEIGHT * 0.1, 0.75)
  end

  local top_boundary = Settings.WINDOW_HEIGHT * 0.18
  local bottom_boundary = Settings.WINDOW_HEIGHT * 0.80
  local start_y = Settings.WINDOW_HEIGHT * 0.22
  local spacing = Settings.WINDOW_HEIGHT * 0.055

  love.graphics.setScissor(0, top_boundary, Settings.WINDOW_WIDTH, bottom_boundary - top_boundary)

  if view_mode == "local" then
    if count == 0 then
      love.graphics.setColor(Colors.white)
      Text.draw_centered_text("NO HIGH SCORES", Settings.WINDOW_HEIGHT * 0.45, 0.6)
    else
      if cache and local_layout and uniform_scale then
        local total_width = local_layout.max_row_w1 * uniform_scale
        local start_x = (Settings.WINDOW_WIDTH - total_width) / 2
        local name_x = start_x + (local_layout.max_rank_w1 + local_layout.gap1) * uniform_scale
        local end_x = start_x + total_width

        for i = 1, count do
          local item = cache[i]
          if item then
            local y_pos = start_y + (i - 1) * spacing
            if item.score >= 100000 then
              love.graphics.setColor(Colors.tangerine_blaze)
            else
              love.graphics.setColor(Colors.neon_lime_splash)
            end

            Text.draw_text(item.rank_str, start_x, y_pos, uniform_scale)
            Text.draw_text(item.name_str, name_x, y_pos, uniform_scale)

            local score_w = Text.get_text_width(item.score_str, uniform_scale)
            Text.draw_text(item.score_str, end_x - score_w, y_pos, uniform_scale)
          end
        end
      end
    end
  else
    if global_loading then
      love.graphics.setColor(Colors.white)
      local full_text = loading_base .. "..."
      local scale = Text.calculate_scale_for_width(full_text, 0.5)
      local height_factor = Settings.WINDOW_HEIGHT / 800
      scale = math.max(0.5 * height_factor, scale)
      local full_width = Text.get_text_width(full_text, scale)
      local x_start = (Settings.WINDOW_WIDTH - full_width) / 2
      local display_text = loading_base .. loading_dots[loading_index]
      Text.draw_text(display_text, x_start, Settings.WINDOW_HEIGHT * 0.45, scale)
    elseif global_fetch_error then
      love.graphics.setColor(Colors.crimson)
      Text.draw_centered_text("CONNECTION ERROR", Settings.WINDOW_HEIGHT * 0.42, 0.55)
      love.graphics.setColor(Colors.white)
      Text.draw_centered_text("NO GLOBAL HIGH SCORES", Settings.WINDOW_HEIGHT * 0.52, 0.45)
    elseif not global_cache or #global_cache == 0 then
      love.graphics.setColor(Colors.white)
      Text.draw_centered_text("NO GLOBAL HIGH SCORES", Settings.WINDOW_HEIGHT * 0.45, 0.6)
    else
      if global_display_cache and global_layout and uniform_scale_global then
        local total_width = global_layout.max_row_w1 * uniform_scale_global
        local start_x = (Settings.WINDOW_WIDTH - total_width) / 2
        local name_x = start_x + (global_layout.max_rank_w1 + global_layout.gap1) * uniform_scale_global
        local end_x = start_x + total_width

        for i = 1, #global_display_cache do
          local item = global_display_cache[i]
          if item then
            local y_pos = start_y + (i - 1) * spacing
            if item.score >= 100000 then
              love.graphics.setColor(Colors.tangerine_blaze)
            else
              love.graphics.setColor(Colors.neon_lime_splash)
            end

            Text.draw_text(item.rank_str, start_x, y_pos, uniform_scale_global)
            Text.draw_text(item.name_str, name_x, y_pos, uniform_scale_global)

            local score_w = Text.get_text_width(item.score_str, uniform_scale_global)
            Text.draw_text(item.score_str, end_x - score_w, y_pos, uniform_scale_global)
          end
        end
      end
    end
  end

  love.graphics.setScissor()

  local arrow_size = ScreenUtils.get_arrow_size()

  if view_mode == "local" then
    local rx = Settings.WINDOW_WIDTH - 35
    local ry = Settings.WINDOW_HEIGHT * 0.5
    local r_hovered = ScreenUtils.is_hovering_arrow("right", rx, ry, arrow_size)
    local r_color = r_hovered and Colors.neon_lime_splash or Colors.cyan
    ScreenUtils.draw_arrow("right", rx, ry, arrow_size, r_color)
  else
    local lx = 35
    local ly = Settings.WINDOW_HEIGHT * 0.5
    local l_hovered = ScreenUtils.is_hovering_arrow("left", lx, ly, arrow_size)
    local l_color = l_hovered and Colors.neon_lime_splash or Colors.cyan
    ScreenUtils.draw_arrow("left", lx, ly, arrow_size, l_color)

    if global_cache and #global_cache > 0 then
      if global_page > 1 then
        local ux = Settings.WINDOW_WIDTH / 2 - 40
        local uy = Settings.WINDOW_HEIGHT * 0.83
        local u_hovered = is_hovering(ux, uy, 25, 25)
        local u_color = u_hovered and Colors.neon_lime_splash or Colors.cyan
        ScreenUtils.draw_arrow("up", ux, uy, arrow_size, u_color)
      end

      if #global_cache > global_page * 10 and global_page < 10 then
        local dx = Settings.WINDOW_WIDTH / 2 + 40
        local dy = Settings.WINDOW_HEIGHT * 0.83
        local d_hovered = is_hovering(dx, dy, 25, 25)
        local d_color = d_hovered and Colors.neon_lime_splash or Colors.cyan
        ScreenUtils.draw_arrow("down", dx, dy, arrow_size, d_color)
      end
    end
  end

  Text.draw_game_version()

  local return_text = ScreenUtils.get_return_prompt()

  local return_y = Settings.WINDOW_HEIGHT * 0.92
  ScreenUtils.draw_return_control(return_text, return_y, 0.7)
end

function hi_scores.keypressed(_key) end

function hi_scores.mousepressed(x, y, button)
  if button ~= 1 then
    return true
  end

  local function is_in_bounds(bx, by, rx, ry)
    return math.abs(x - bx) <= rx and math.abs(y - by) <= ry
  end

  local function is_in_rect(x1, y1, x2, y2)
    return x >= x1 and x <= x2 and y >= y1 and y <= y2
  end

  local return_text = ScreenUtils.get_return_prompt()
  local return_y = Settings.WINDOW_HEIGHT * 0.92
  local return_width_percentage = 0.7
  if ScreenUtils.is_return_control_clicked(return_text, return_y, return_width_percentage, x, y) then
    GameState.set(GameState.previous or "attract")
    Sound.play("blip")
    return true
  end

  if view_mode == "local" then
    if
      is_in_rect(
        Settings.WINDOW_WIDTH - 70,
        Settings.WINDOW_HEIGHT * 0.18,
        Settings.WINDOW_WIDTH,
        Settings.WINDOW_HEIGHT * 0.88
      )
    then
      view_mode = "global"
      global_page = 1
      rebuild_global_display()
      Sound.play("blip")
      return true
    end
  else
    if is_in_rect(0, Settings.WINDOW_HEIGHT * 0.18, 70, Settings.WINDOW_HEIGHT * 0.88) then
      view_mode = "local"
      Sound.play("blip")
      return true
    end

    if global_cache and #global_cache > 0 then
      if global_page > 1 then
        local ux = Settings.WINDOW_WIDTH / 2 - 40
        local uy = Settings.WINDOW_HEIGHT * 0.83
        if is_in_bounds(ux, uy, 25, 25) then
          global_page = global_page - 1
          rebuild_global_display()
          Sound.play("blip")
          return true
        end
      end

      if #global_cache > global_page * 10 and global_page < 10 then
        local dx = Settings.WINDOW_WIDTH / 2 + 40
        local dy = Settings.WINDOW_HEIGHT * 0.83
        if is_in_bounds(dx, dy, 25, 25) then
          global_page = global_page + 1
          rebuild_global_display()
          Sound.play("blip")
          return true
        end
      end
    end
  end

  return true
end

return hi_scores
