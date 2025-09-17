local Levels = {}

local all_colors = require("colors")
local settings = require("settings")
local CustomFont = require("font")
local PlayerProgress = require("player_progress")
local LevelData = require("level_data")
local Parallax = require("parallax")

local level_points = {}

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
      x = x_pct * settings.WINDOW_WIDTH,
      y = data.y_pct * settings.WINDOW_HEIGHT,
      label = data.label,
    })
  end
end

function Levels.load()
  initialize_level_points()
end

function Levels.update(dt)
  Parallax.update(dt)
end

function Levels.draw()
  local current_level = PlayerProgress.get_current_level()

  ---@diagnostic disable-next-line: param-type-mismatch
  love.graphics.setLineStyle("rough")
  for i = 1, #level_points - 1 do
    local p1 = level_points[i]
    local p2 = level_points[i + 1]
    if PlayerProgress.is_level_unlocked(p1.label) and PlayerProgress.is_level_unlocked(p2.label) then
      love.graphics.setColor(all_colors.light_blue_glow)
    else
      love.graphics.setColor(all_colors.gunmetal_gray)
    end
    love.graphics.line(p1.x, p1.y, p2.x, p2.y)
  end
  ---@diagnostic disable-next-line: param-type-mismatch
  love.graphics.setLineStyle("smooth")

  for _, point in ipairs(level_points) do
    if PlayerProgress.is_level_unlocked(point.label) then
      if point.label == current_level then
        for i = 1, 5 do
          local alpha = 1 - (i / 5)
          love.graphics.setColor(all_colors.cyan[1], all_colors.cyan[2], all_colors.cyan[3], alpha * 0.2)
          love.graphics.polygon(
            "fill",
            point.x,
            point.y - (20 + i),
            point.x - (20 + i),
            point.y + (20 + i),
            point.x + (20 + i),
            point.y + (20 + i)
          )
        end
      end
      love.graphics.setColor(all_colors.cyan)
    else
      love.graphics.setColor(all_colors.gunmetal_gray)
    end

    love.graphics.polygon("fill", point.x, point.y - 20, point.x - 20, point.y + 20, point.x + 20, point.y + 20)
    love.graphics.setColor(all_colors.white)
    local labelWidth = CustomFont:getTextWidth(point.label, 3)
    CustomFont:drawText(point.label, point.x - labelWidth / 2, point.y - 45, 3)
  end
end

function Levels.keypressed(key)
  if key == "escape" then
    Main.set_game_state("attract")
  end
end

function Levels.mousepressed(x, y, button)
  if button == 1 then
    for i, point in ipairs(level_points) do
      if x > point.x - 20 and x < point.x + 20 and y > point.y - 20 and y < point.y + 20 then
        if PlayerProgress.is_level_unlocked(point.label) then
          PlayerProgress.set_current_level(point.label)
          local levelData = LevelData.new(point.label)
          Main.start_game_from_level(levelData)
        end
        break
      end
    end
  end
end

function Levels.get_level_points()
  return level_points
end

return Levels
