local LevelsSelector = {}

local AllColors = require("colors")
local Settings = require("settings")
local Text = require("text")
local PlayerProgress = require("player_progress")
local LevelData = require("level_data")
local Parallax = require("parallax")

local level_points = {}
local selected_index = 1

local function initialize_level_points()
  local points_data = {
    { y_pct = 0.95, label = "0000" },
    { y_pct = 0.85, label = "0001" },
    { y_pct = 0.75, label = "0010" },
    { y_pct = 0.65, label = "0011" },
    { y_pct = 0.55, label = "0100" },
    { y_pct = 0.45, label = "0101" },
    { y_pct = 0.35, label = "0110" },
    { y_pct = 0.25, label = "0111" },
    { y_pct = 0.15, label = "1000" },
    { y_pct = 0.05, label = "1001" },
  }

  for _, data in ipairs(points_data) do
    local x_pct = 0.1 + math.random() * 0.8

    table.insert(level_points, {
      x = x_pct * Settings.WINDOW_WIDTH,
      y = data.y_pct * Settings.WINDOW_HEIGHT,
      label = data.label,
    })
  end
end

function LevelsSelector.load()
  initialize_level_points()
  -- Initialize selected_index to current level or first unlocked
  local current_level = PlayerProgress.get_current_level()
  for i, point in ipairs(level_points) do
    if point.label == current_level and PlayerProgress.is_level_unlocked(point.label) then
      selected_index = i
      break
    elseif PlayerProgress.is_level_unlocked(point.label) then
      selected_index = i
      break
    end
  end
end

function LevelsSelector.update(dt)
  Parallax.update(dt)
end

function LevelsSelector.draw()
  local current_level = PlayerProgress.get_current_level()

  ---@diagnostic disable-next-line: param-type-mismatch
  love.graphics.setLineStyle("rough")
  for i = 1, #level_points - 1 do
    local p1 = level_points[i]
    local p2 = level_points[i + 1]
    if PlayerProgress.is_level_unlocked(p1.label) and PlayerProgress.is_level_unlocked(p2.label) then
      love.graphics.setColor(AllColors.light_blue_glow)
    else
      love.graphics.setColor(AllColors.gunmetal_gray)
    end
    love.graphics.line(p1.x, p1.y, p2.x, p2.y)
  end
  ---@diagnostic disable-next-line: param-type-mismatch
  love.graphics.setLineStyle("smooth")

  for i, point in ipairs(level_points) do
    if PlayerProgress.is_level_unlocked(point.label) then
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
            point.y - (30 + j),
            point.x - (30 + j),
            point.y + (30 + j),
            point.x + (30 + j),
            point.y + (30 + j)
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
            point.y - (20 + j),
            point.x - (20 + j),
            point.y + (20 + j),
            point.x + (20 + j),
            point.y + (20 + j)
          )
        end
      end
      love.graphics.setColor(AllColors.cyan)
    else
      love.graphics.setColor(AllColors.gunmetal_gray)
    end

    love.graphics.polygon("fill", point.x, point.y - 20, point.x - 20, point.y + 20, point.x + 20, point.y + 20)
    love.graphics.setColor(AllColors.white)
    local labelWidth = Text.getTextWidth(point.label, 3)
    Text.drawText(point.label, point.x - labelWidth / 2, point.y - 45, 3)
  end
end

function LevelsSelector.keypressed(key)
  if key == "escape" then
    Main.set_game_state("attract")
  elseif key == "down" then
    for i = selected_index - 1, 1, -1 do
      if PlayerProgress.is_level_unlocked(level_points[i].label) then
        selected_index = i
        break
      end
    end
  elseif key == "up" then
    for i = selected_index + 1, #level_points do
      if PlayerProgress.is_level_unlocked(level_points[i].label) then
        selected_index = i
        break
      end
    end
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
  -- Update selected_index based on mouse hover over unlocked levels
  for i, point in ipairs(level_points) do
    if x > point.x - 20 and x < point.x + 20 and y > point.y - 20 and y < point.y + 20 then
      if PlayerProgress.is_level_unlocked(point.label) then
        selected_index = i
        break
      end
    end
  end
end

function LevelsSelector.mousepressed(x, y, button)
  if button == 1 then
    for i, point in ipairs(level_points) do
      if x > point.x - 20 and x < point.x + 20 and y > point.y - 20 and y < point.y + 20 then
        if PlayerProgress.is_level_unlocked(point.label) then
          selected_index = i
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
