local LevelsSelector = {}

local AllColors = require("colors")
local Settings = require("settings")
local Text = require("text")
local PlayerProgress = require("player_progress")
local LevelData = require("level_data")
local Parallax = require("parallax")

local level_points = {}
local selected_index = 1
local hovered_index = nil
local current_y_offset = 0
local target_y_offset = 0

local last_move_time = 0
local move_delay = 0.15

local function initialize_level_points()
  level_points = {}
  for level_index = 1, Settings.MAX_LEVELS do
    local level_key = string.format("%02d", level_index)
    local y_pct = 0.95 - (level_index - 1) * 0.1
    local x_pct = 0.1 + math.random() * 0.8

    table.insert(level_points, {
      x = x_pct * Settings.WINDOW_WIDTH,
      y = y_pct * Settings.WINDOW_HEIGHT,
      label = level_key,
    })
  end
end

function LevelsSelector.load()
  initialize_level_points()
  -- Initialize selected_index to the highest unlocked level
  local highest_unlocked_level = 1
  for i = #level_points, 1, -1 do
    local point = level_points[i]
    if PlayerProgress.is_level_unlocked(point.label) then
      highest_unlocked_level = i
      break
    end
  end
  selected_index = highest_unlocked_level
  target_y_offset = (selected_index - 5) * 0.1
  current_y_offset = target_y_offset
end

function LevelsSelector.update(dt)
  Parallax.update(dt)
  -- Smooth transition while moving between levels
  local lerp_speed = 5
  current_y_offset = current_y_offset + (target_y_offset - current_y_offset) * lerp_speed * dt

  local current_time = love.timer.getTime()
  if love.keyboard.isDown("up") and current_time - last_move_time > move_delay then
    LevelsSelector.move_up()
    last_move_time = current_time
  end
  if love.keyboard.isDown("down") and current_time - last_move_time > move_delay then
    LevelsSelector.move_down()
    last_move_time = current_time
  end
end

function LevelsSelector.draw()
  local current_level = PlayerProgress.get_current_level()

  local y_offset = current_y_offset
  local visible_start = math.max(1, selected_index - 4)
  local visible_end = math.min(Settings.MAX_LEVELS, selected_index + 5)

  ---@diagnostic disable-next-line: param-type-mismatch
  love.graphics.setLineStyle("rough")
  for i = visible_start, visible_end - 1 do
    local p1 = level_points[i]
    local p2 = level_points[i + 1]
    if PlayerProgress.is_level_unlocked(p1.label) and PlayerProgress.is_level_unlocked(p2.label) then
      love.graphics.setColor(AllColors.light_blue_glow)
    else
      love.graphics.setColor(AllColors.gunmetal_gray)
    end
    local draw_y1 = p1.y + y_offset * Settings.WINDOW_HEIGHT
    local draw_y2 = p2.y + y_offset * Settings.WINDOW_HEIGHT
    love.graphics.line(p1.x, draw_y1, p2.x, draw_y2)
  end
  ---@diagnostic disable-next-line: param-type-mismatch
  love.graphics.setLineStyle("smooth")

  for i = visible_start, visible_end do
    local point = level_points[i]
    local draw_y = point.y + y_offset * Settings.WINDOW_HEIGHT

    if PlayerProgress.is_level_unlocked(point.label) then
      if i == hovered_index then
        -- Visual feedback for hovered level
        for j = 1, 5 do
          local alpha = 1 - (j / 5)
          love.graphics.setColor(
            AllColors.tangerine_blaze[1],
            AllColors.tangerine_blaze[2],
            AllColors.tangerine_blaze[3],
            alpha * 0.4
          )
          love.graphics.polygon(
            "fill",
            point.x,
            draw_y - (30 + j),
            point.x - (30 + j),
            draw_y + (30 + j),
            point.x + (30 + j),
            draw_y + (30 + j)
          )
        end
      end
      if i == selected_index then
        -- Visual feedback for selected level
        for j = 1, 5 do
          local alpha = 1 - (j / 5)
          love.graphics.setColor(
            AllColors.tangerine_blaze[1],
            AllColors.tangerine_blaze[2],
            AllColors.tangerine_blaze[3],
            alpha * 0.8
          )
          love.graphics.polygon(
            "fill",
            point.x,
            draw_y - (30 + j),
            point.x - (30 + j),
            draw_y + (30 + j),
            point.x + (30 + j),
            draw_y + (30 + j)
          )
        end
      end
      if point.label == current_level then
        for j = 1, 5 do
          local alpha = 1 - (j / 5)
          love.graphics.setColor(AllColors.cyan[1], AllColors.cyan[2], AllColors.cyan[3], alpha * 0.2)
          love.graphics.polygon(
            "fill",
            point.x,
            draw_y - (20 + j),
            point.x - (20 + j),
            draw_y + (20 + j),
            point.x + (20 + j),
            draw_y + (20 + j)
          )
        end
      end
      love.graphics.setColor(AllColors.cyan)
    else
      love.graphics.setColor(AllColors.gunmetal_gray)
    end

    love.graphics.polygon("fill", point.x, draw_y - 20, point.x - 20, draw_y + 20, point.x + 20, draw_y + 20)
    love.graphics.setColor(AllColors.white)
    local labelScale = Text.calculateScaleForWidth(point.label, 0.10)
    local labelWidth = Text.getTextWidth(point.label, labelScale)
    Text.drawText(point.label, point.x - labelWidth / 2, draw_y - 45, labelScale)
  end
end

function LevelsSelector.move_up()
  for i = selected_index + 1, #level_points do
    if PlayerProgress.is_level_unlocked(level_points[i].label) then
      selected_index = i
      target_y_offset = (selected_index - 5) * 0.1
      break
    end
  end
end

function LevelsSelector.move_down()
  for i = selected_index - 1, 1, -1 do
    if PlayerProgress.is_level_unlocked(level_points[i].label) then
      selected_index = i
      target_y_offset = (selected_index - 5) * 0.1
      break
    end
  end
end

function LevelsSelector.keypressed(key)
  if key == "escape" then
    Main.set_game_state("attract")
  elseif key == "return" then
    local selected_point = level_points[selected_index]
    if selected_point and PlayerProgress.is_level_unlocked(selected_point.label) then
      PlayerProgress.set_current_level(selected_point.label)
      local levelData = LevelData.new(selected_point.label)
      Main.start_game_from_level(levelData)
    end
  end
end

function LevelsSelector.mousemove(x, y)
  -- Update hovered_index based on mouse hover over unlocked levels
  local y_offset = current_y_offset
  local visible_start = math.max(1, selected_index - 4)
  local visible_end = math.min(Settings.MAX_LEVELS, selected_index + 5)

  hovered_index = nil
  for i = visible_start, visible_end do
    local point = level_points[i]
    local draw_y = point.y + y_offset * Settings.WINDOW_HEIGHT
    if x > point.x - 20 and x < point.x + 20 and y > draw_y - 20 and y < draw_y + 20 then
      if PlayerProgress.is_level_unlocked(point.label) then
        hovered_index = i
        break
      end
    end
  end
end

function LevelsSelector.mousepressed(x, y, button)
  if button == 1 then
    local y_offset = current_y_offset
    local visible_start = math.max(1, selected_index - 4)
    local visible_end = math.min(Settings.MAX_LEVELS, selected_index + 5)

    for i = visible_start, visible_end do
      local point = level_points[i]
      local draw_y = point.y + y_offset * Settings.WINDOW_HEIGHT
      if x > point.x - 20 and x < point.x + 20 and y > draw_y - 20 and y < draw_y + 20 then
        if PlayerProgress.is_level_unlocked(point.label) then
          selected_index = i
          target_y_offset = (selected_index - 5) * 0.1
          PlayerProgress.set_current_level(point.label)
          local levelData = LevelData.new(point.label)
          Main.start_game_from_level(levelData)
        end
        break
      end
    end
  end
end

function LevelsSelector.get_level_points()
  return level_points
end

return LevelsSelector
