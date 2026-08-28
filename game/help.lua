local Colors = require("colors")
local Settings = require("settings")
local Powerups = require("powerups")
local Debuffs = require("debuffs")
local Text = require("text")
local Input = require("input")
local GameState = require("gamestate")
local ScreenUtils = require("screen_utils")

local help = {}
local is_dragging = false
local last_drag_y = nil

function help.load()
  is_dragging = false
  last_drag_y = nil
end

local function draw_help_screen_static()
  love.graphics.setColor(0, 0, 0, 0.9)
  love.graphics.rectangle("fill", 0, 0, Settings.WINDOW_WIDTH, Settings.WINDOW_HEIGHT)
  love.graphics.setColor(Colors.cyan)
  Text.draw_centered_text("HOW TO PLAY", Settings.WINDOW_HEIGHT * 0.03, 0.80)

  love.graphics.setColor(Colors.spiced_amber)
  Text.draw_centered_text("UP/DOWN TO SCROLL", Settings.WINDOW_HEIGHT * 0.12, 0.3)

  local return_text = ScreenUtils.get_return_prompt()
  local return_text_size = ScreenUtils.get_return_width_percentage()
  local return_y = Settings.WINDOW_HEIGHT * 0.97
  ScreenUtils.draw_return_control(return_text, return_y, return_text_size)
  Text.draw_game_version()
end

local function draw_help_screen_scrollable(scroll_y)
  scroll_y = scroll_y or 0
  local left_margin = Settings.WINDOW_WIDTH * 0.03
  local start_y = Settings.WINDOW_HEIGHT * 0.18
  local y_pos = start_y - scroll_y

  local move_text, move_scale, ping_text, ping_scale
  local connected_joysticks = Input:get_connected_joysticks()
  local has_controller = next(connected_joysticks) ~= nil

  if Settings.IS_MOBILE then
    move_text = "TOUCH ON SCREEN:"
    move_scale = 0.55
    ping_text = "HOLD SCREEN OR DOUBLE TOUCH:"
    ping_scale = 0.85
  elseif has_controller then
    move_text = "BUTTON 1:"
    move_scale = 0.3
    ping_text = "BUTTON 2:"
    ping_scale = 0.3
  else
    move_text = "LEFT CLICK OR SPACE:"
    move_scale = 0.6
    ping_text = "RIGHT CLICK OR C:"
    ping_scale = 0.5
  end

  local function draw_text(text, x, width_pct, color)
    love.graphics.setColor(color or Colors.white)
    local scale = Text.calculate_scale_for_width(text, width_pct)
    Text.draw_text(text, x, y_pos, scale)
    local height = Text.get_text_height(scale)
    y_pos = y_pos + height + (Settings.WINDOW_HEIGHT * 0.015)
  end

  local function draw_section_header(text, width_pct, color)
    draw_text(text, left_margin, width_pct, color)
  end

  local function draw_section_detail(text, width_pct, color)
    draw_text(text, left_margin + (Settings.WINDOW_WIDTH * 0.02), width_pct, color)
  end

  draw_section_header(move_text, move_scale)
  draw_section_detail("MOVES PLAYER TO THE NEXT POINT", 0.8)
  y_pos = y_pos + (Settings.WINDOW_HEIGHT * 0.02)

  draw_section_header(ping_text, ping_scale)
  draw_section_detail("PINGS TO COLLECT POWERUPS NEARBY", 0.85)
  y_pos = y_pos + (Settings.WINDOW_HEIGHT * 0.02)

  local text_icon_offset = Settings.WINDOW_WIDTH * 0.08

  local function draw_powerup_header(
    draw_icon_func,
    r_factor,
    y_offset_factor,
    text,
    width_pct,
    color,
    has_line_width,
    lw_multiplier
  )
    local scale = Text.calculate_scale_for_width(text, width_pct)
    local text_height = Text.get_text_height(scale)
    local base_radius = (text_height / 2) * 1.4
    local radius = base_radius * (r_factor or 1)
    local icon_x = left_margin + (Settings.WINDOW_WIDTH * 0.02)
    local icon_y = y_pos + (text_height / 2) + (radius * (y_offset_factor or 0))

    love.graphics.setColor(color)
    if has_line_width then
      local line_width = math.max(1, radius * 0.2) * (lw_multiplier or 1)
      draw_icon_func(icon_x, icon_y, radius, 0, line_width)
    else
      draw_icon_func(icon_x, icon_y, radius, 0)
    end
    draw_text(text, left_margin + text_icon_offset, width_pct, color)
  end

  draw_powerup_header(Powerups.draw_star, 1.0, 0, "STAR POWERUP:", 0.4, Colors.yellow)
  draw_section_detail("10 SECONDS OF INVULNERABILITY", 0.85, Colors.yellow)
  y_pos = y_pos + (Settings.WINDOW_HEIGHT * 0.02)

  draw_powerup_header(Powerups.draw_clock, 1.0, 0, "HOURGLASS POWERUP:", 0.55, Colors.light_blue_glow)
  draw_section_detail("SHRINKS AND SLOWS OBSTACLES", 0.8, Colors.light_blue_glow)
  draw_section_detail("PREVENTS PLAYER FROM FALLING", 0.8, Colors.light_blue_glow)
  y_pos = y_pos + (Settings.WINDOW_HEIGHT * 0.02)

  draw_powerup_header(Powerups.draw_phase_shift, 1.6, 0, "PHASE SHIFT POWERUP:", 0.6, Colors.emerald_shade, true, 1.2)
  draw_section_detail("RIGHT CLICK PING TELEPORTS", 0.8, Colors.emerald_shade)
  draw_section_detail("TO NEXT POINT. LASTS 10 SECONDS.", 0.8, Colors.emerald_shade)
  y_pos = y_pos + (Settings.WINDOW_HEIGHT * 0.02)

  draw_powerup_header(Powerups.draw_bolt, 1.2, 0, "BOLT POWERUP:", 0.4, Colors.tangerine_blaze, true, 1.2)
  draw_section_detail("A SAFETY NET THAT TELEPORTS YOU", 0.8, Colors.tangerine_blaze)
  draw_section_detail("TO THE NEXT POINT. LASTS 30 SECS.", 0.8, Colors.tangerine_blaze)
  y_pos = y_pos + (Settings.WINDOW_HEIGHT * 0.02)

  draw_powerup_header(Powerups.draw_score_multiplier, 1.0, 0, "SCORE MULTIPLIER:", 0.55, Colors.yellow)
  draw_section_detail("MULTIPLY YOUR SCORE BY 4X.", 0.8, Colors.yellow)
  draw_section_detail("LASTS 30 SECONDS.", 0.5, Colors.yellow)
  y_pos = y_pos + (Settings.WINDOW_HEIGHT * 0.02)

  draw_powerup_header(Powerups.draw_spawn_rate_boost, 1.1, 0.4, "SPAWN RATE BOOST:", 0.55, Colors.neon_lime_splash)
  draw_section_detail("INCREASES POWERUP SPAWN RATE.", 0.8, Colors.neon_lime_splash)
  draw_section_detail("LASTS 30 SECONDS.", 0.5, Colors.neon_lime_splash)
  y_pos = y_pos + (Settings.WINDOW_HEIGHT * 0.02)

  draw_powerup_header(Debuffs.draw_emp_fuse, 1.1, 0.20, "PING GLITCH DEBUFF:", 0.55, Colors.crimson, true, 1.2)
  draw_section_detail("REMOVES ACTIVE POWERUPS ON CONTACT.", 0.85, Colors.crimson)
  draw_section_detail("BLOCKS ALL PING ACTIONS FOR 10 SECS.", 0.85, Colors.crimson)
  y_pos = y_pos + (Settings.WINDOW_HEIGHT * 0.01)
  draw_section_detail("HINT: THE DEBUFF AND POWERUPS CANCEL EACH OTHER", 0.85, Colors.periwinkle_mist)
  draw_section_detail("PLAY CAREFULLY AND BLIP OVER POWERUPS TO CANCEL IT", 0.90, Colors.periwinkle_mist)

  return y_pos + scroll_y - start_y
end

function help.draw()
  draw_help_screen_static()
  local top_boundary = Settings.WINDOW_HEIGHT * 0.15
  local bottom_boundary = Settings.WINDOW_HEIGHT * 0.95
  love.graphics.setScissor(0, top_boundary, Settings.WINDOW_WIDTH, bottom_boundary - top_boundary)

  local content_height = draw_help_screen_scrollable(Input.help_scroll_y)
  love.graphics.setScissor()

  local view_height = bottom_boundary - top_boundary
  Input.max_help_scroll = math.max(0, content_height - view_height + (Settings.WINDOW_HEIGHT * 0.05))
end

function help.mousepressed(x, y, button)
  if button ~= 1 then
    return true
  end

  local return_text = ScreenUtils.get_return_prompt()
  local return_text_size = ScreenUtils.get_return_width_percentage()
  local return_y = Settings.WINDOW_HEIGHT * 0.97
  if ScreenUtils.is_return_control_clicked(return_text, return_y, return_text_size, x, y) then
    GameState.set(GameState.previous or "attract")
    return true
  end

  if not Settings.IS_MOBILE and y >= Settings.WINDOW_HEIGHT * 0.15 and y < Settings.WINDOW_HEIGHT * 0.88 then
    is_dragging = true
    last_drag_y = y
  end

  return true
end

function help.mousemoved(_, y)
  if not love.mouse.isDown(1) then
    is_dragging = false
    last_drag_y = nil
    return
  end

  if not is_dragging or not last_drag_y then
    return
  end

  Input.help_scroll_y = Input.help_scroll_y + last_drag_y - y
  Input.help_scroll_y = math.max(0, math.min(Input.max_help_scroll, Input.help_scroll_y))
  last_drag_y = y
end

function help.mousereleased(_, _, button)
  if button == 1 then
    is_dragging = false
    last_drag_y = nil
  end
end

return help
