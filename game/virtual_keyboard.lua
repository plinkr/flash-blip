local Colors = require("colors")
local Settings = require("settings")
local Text = require("text")
local Sound = require("sound")

local VirtualKeyboard = {}

local name = ""
local max_name_length = 15
local score = 0
local source = ""
local on_accept_callback = nil
local on_cancel_callback = nil

local keys = {}
local cursor_timer = 0
local cursor_visible = true

local function layout()
  keys = {}
  local col_width = Settings.WINDOW_WIDTH / 10.6
  local padding = col_width * 0.12
  local key_w = col_width - padding
  local key_h = col_width * 1.25

  local start_y = Settings.WINDOW_HEIGHT * 0.42
  local row_spacing = col_width * 1.40

  local row0 = { "1", "2", "3", "4", "5", "6", "7", "8", "9", "0" }
  local r0_offset = (Settings.WINDOW_WIDTH - (10 * col_width - padding)) / 2
  for i, char in ipairs(row0) do
    local x = r0_offset + (i - 1) * col_width
    local y = start_y
    table.insert(keys, { char = char, x = x, y = y, w = key_w, h = key_h, action = char })
  end

  local row1 = { "Q", "W", "E", "R", "T", "Y", "U", "I", "O", "P" }
  local r1_offset = (Settings.WINDOW_WIDTH - (10 * col_width - padding)) / 2
  for i, char in ipairs(row1) do
    local x = r1_offset + (i - 1) * col_width
    local y = start_y + row_spacing
    table.insert(keys, { char = char, x = x, y = y, w = key_w, h = key_h, action = char })
  end

  local row2 = { "A", "S", "D", "F", "G", "H", "J", "K", "L" }
  local r2_offset = (Settings.WINDOW_WIDTH - (9 * col_width - padding)) / 2
  for i, char in ipairs(row2) do
    local x = r2_offset + (i - 1) * col_width
    local y = start_y + 2 * row_spacing
    table.insert(keys, { char = char, x = x, y = y, w = key_w, h = key_h, action = char })
  end

  local row3 = { "Z", "X", "C", "V", "B", "N", "M" }
  local r3_offset = (Settings.WINDOW_WIDTH - (7 * col_width - padding)) / 2
  for i, char in ipairs(row3) do
    local x = r3_offset + (i - 1) * col_width
    local y = start_y + 3 * row_spacing
    table.insert(keys, { char = char, x = x, y = y, w = key_w, h = key_h, action = char })
  end

  -- Row 4: CANCEL (ESC), DEL, SPACE, OK
  local r4_offset = r1_offset
  local y = start_y + 4 * row_spacing

  table.insert(keys, {
    char = "ESC",
    x = r4_offset,
    y = y,
    w = 2 * col_width - padding,
    h = key_h,
    action = "cancel",
    color = Colors.crimson,
  })

  table.insert(keys, {
    char = "DEL",
    x = r4_offset + 2 * col_width,
    y = y,
    w = 2 * col_width - padding,
    h = key_h,
    action = "backspace",
    color = Colors.safety_orange,
  })

  table.insert(keys, {
    char = "SPACE",
    x = r4_offset + 4 * col_width,
    y = y,
    w = 3.5 * col_width - padding,
    h = key_h,
    action = "space",
    color = Colors.periwinkle_mist,
  })

  table.insert(keys, {
    char = "OK",
    x = r4_offset + 7.5 * col_width,
    y = y,
    w = 2.5 * col_width - padding,
    h = key_h,
    action = "accept",
    color = Colors.neon_lime_splash,
  })
end

function VirtualKeyboard.show(score_val, source_val, on_accept, on_cancel)
  name = ""
  score = score_val or 0
  source = source_val or ""
  on_accept_callback = on_accept
  on_cancel_callback = on_cancel
  cursor_timer = 0
  cursor_visible = true
  layout()
end

function VirtualKeyboard.update(dt)
  cursor_timer = cursor_timer + dt
  if cursor_timer > 0.4 then
    cursor_visible = not cursor_visible
    cursor_timer = 0
  end
end

function VirtualKeyboard.draw()
  love.graphics.setColor(0, 0, 0, 0.85)
  love.graphics.rectangle("fill", 0, 0, Settings.WINDOW_WIDTH, Settings.WINDOW_HEIGHT)

  -- Draw Titles
  love.graphics.setColor(Colors.yellow)
  Text.draw_centered_text("GOBAL HI SCORE!", Settings.WINDOW_HEIGHT * 0.08, 0.9)

  -- Draw score details
  love.graphics.setColor(Colors.neon_lime_splash)
  local score_str = tostring(math.floor(score)) .. " PTS (" .. tostring(source) .. ")"
  Text.draw_centered_text(score_str, Settings.WINDOW_HEIGHT * 0.16, 0.85)

  -- Prompt
  love.graphics.setColor(Colors.white)
  Text.draw_centered_text("ENTER YOUR NAME:", Settings.WINDOW_HEIGHT * 0.24, 0.8)

  -- Draw name input box
  local box_w = Settings.WINDOW_WIDTH * 0.85
  local box_h = Settings.WINDOW_HEIGHT * 0.08
  local box_x = (Settings.WINDOW_WIDTH - box_w) / 2
  local box_y = Settings.WINDOW_HEIGHT * 0.32

  love.graphics.setColor(Colors.cyan_glow)
  love.graphics.rectangle("line", box_x, box_y, box_w, box_h, 6, 6)

  -- Draw text with a cursor
  local stable_text = name
  if #name < max_name_length then
    stable_text = name .. "█"
  end

  love.graphics.setColor(Colors.white)
  local text_scale = Text.calculate_scale_for_width(stable_text, 0.75)
  local max_scale = Settings.WINDOW_HEIGHT * 0.004
  text_scale = math.min(text_scale, max_scale)

  local text_w = Text.get_text_width(stable_text, text_scale)
  local text_h = Text.get_text_height(text_scale)
  local text_x = box_x + (box_w - text_w) / 2
  local text_y = box_y + (box_h - text_h) / 2

  -- Draw the actual typed name
  Text.draw_text(name, text_x, text_y, text_scale)

  -- Draw the blinking block cursor immediately following the typed name
  if cursor_visible and #name < max_name_length then
    local name_w = Text.get_text_width(name, text_scale)
    Text.draw_text("█", text_x + name_w, text_y, text_scale)
  end

  -- Draw keyboard keys
  local mouse_x, mouse_y = love.mouse.getPosition()
  for _, key in ipairs(keys) do
    local is_hovered = (mouse_x >= key.x and mouse_x <= key.x + key.w and mouse_y >= key.y and mouse_y <= key.y + key.h)

    -- Draw key background
    if is_hovered then
      love.graphics.setColor(0.2, 0.2, 0.3, 0.9)
    else
      love.graphics.setColor(0.08, 0.08, 0.12, 0.85)
    end
    love.graphics.rectangle("fill", key.x, key.y, key.w, key.h, 4, 4)

    -- Draw key border
    local border_color = key.color or Colors.cyan
    if is_hovered then
      love.graphics.setColor(1, 1, 1, 1)
    else
      love.graphics.setColor(border_color[1], border_color[2], border_color[3], 0.6)
    end
    love.graphics.rectangle("line", key.x, key.y, key.w, key.h, 4, 4)

    -- Draw key label
    if is_hovered then
      love.graphics.setColor(1, 1, 1, 1)
    else
      love.graphics.setColor(border_color[1], border_color[2], border_color[3], 1)
    end

    local scale_pct = 0.075
    local max_scale_mult = 0.65
    if key.char:match("^%a$") then
      scale_pct = 0.09
      max_scale_mult = 0.75
    elseif key.char == "SPACE" then
      scale_pct = 0.12
    end

    local label_scale = Text.calculate_scale_for_width(key.char, scale_pct)
    local max_label_scale = key.w / Text.get_text_width(key.char, 1) * max_scale_mult
    label_scale = math.min(label_scale, max_label_scale)

    local label_width = Text.get_text_width(key.char, label_scale)
    local label_height = Text.get_text_height(label_scale)
    local label_x = key.x + (key.w - label_width) / 2
    local label_y = key.y + (key.h - label_height) / 2

    Text.draw_text(key.char, label_x, label_y, label_scale)
  end
end

local function handle_action(action)
  if action == "cancel" then
    if on_cancel_callback then
      Sound.play("explosion")
      -- Avoid duplicate submission triggers while asynchronous requests are in flight
      local callback = on_cancel_callback
      on_cancel_callback = nil
      on_accept_callback = nil
      callback()
    end
  elseif action == "backspace" then
    if #name > 0 then
      Sound.play("blip")
      name = name:sub(1, -2)
    end
  elseif action == "space" then
    if #name < max_name_length then
      Sound.play("blip")
      name = name .. " "
    end
  elseif action == "accept" then
    -- validation is strictly ASCII alphanumeric (%w) and spaces (%s)
    local clean_name = name:gsub("%s+", "")
    if #clean_name == 0 or not name:match("^[%w%s]+$") then
      name = ""
      Sound.play("explosion")
    else
      Sound.play("teleport")
      if on_accept_callback then
        local callback = on_accept_callback
        on_accept_callback = nil
        on_cancel_callback = nil
        callback(name)
      end
    end
  else
    if #name < max_name_length then
      Sound.play("blip")
      name = name .. action
    end
  end
end

function VirtualKeyboard.keypressed(key)
  if key == "escape" then
    handle_action("cancel")
  elseif key == "backspace" then
    handle_action("backspace")
  elseif key == "return" then
    handle_action("accept")
  elseif key == "space" then
    handle_action("space")
  elseif #key == 1 then
    local char = key:upper()
    if char:match("[%w]") then
      handle_action(char)
    end
  end
end

function VirtualKeyboard.mousepressed(x, y, button)
  if button ~= 1 then
    return
  end
  for _, key in ipairs(keys) do
    if x >= key.x and x <= key.x + key.w and y >= key.y and y <= key.y + key.h then
      handle_action(key.action)
      return
    end
  end
end

return VirtualKeyboard
