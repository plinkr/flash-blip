local CustomFont = require("font")
local colors = require("colors")
local settings = require("settings")

local Text = {}

-- Carga y configura la fuente personalizada.
local CustomFont = require("font")
CustomFont:init()

function Text:drawAttract(menuItems, selectedItem)
  love.graphics.setColor(0, 0, 0, 0.5)
  love.graphics.rectangle("fill", 0, 0, settings.WINDOW_WIDTH, settings.WINDOW_HEIGHT)
  love.graphics.setColor(colors.cyan)
  local title = "FLASH-BLIP"
  local titleWidth = CustomFont:getTextWidth(title, 10)
  CustomFont:drawText(title, (settings.WINDOW_WIDTH - titleWidth) / 2, settings.WINDOW_HEIGHT * 0.15, 10)

  local gameVersionWidth = CustomFont:getTextWidth(GAME_VERSION, 2)
  CustomFont:drawText(GAME_VERSION, (settings.WINDOW_WIDTH - gameVersionWidth) * 0.95, settings.WINDOW_HEIGHT * 0.95, 2)

  local yPos = settings.WINDOW_HEIGHT * 0.4
  for i, item in ipairs(menuItems) do
    if i == selectedItem then
      love.graphics.setColor(colors.light_blue_glow)
    else
      love.graphics.setColor(colors.white)
    end
    local itemWidth = CustomFont:getTextWidth(item.text, 5)
    CustomFont:drawText(item.text, (settings.WINDOW_WIDTH - itemWidth) / 2, yPos, 5)
    item.y = yPos -- Store y position for click detection
    item.height = CustomFont:getTextHeight(5)
    yPos = yPos + 50
  end
end

function Text:drawPauseMenu(menuItems, selectedItem)
  love.graphics.setColor(0, 0, 0, 0.65)
  love.graphics.rectangle("fill", 0, 0, settings.WINDOW_WIDTH, settings.WINDOW_HEIGHT)
  love.graphics.setColor(colors.cyan)
  local title = "PAUSED"
  local titleWidth = CustomFont:getTextWidth(title, 10)
  CustomFont:drawText(title, (settings.WINDOW_WIDTH - titleWidth) / 2, settings.WINDOW_HEIGHT * 0.25, 10)

  local yPos = settings.WINDOW_HEIGHT * 0.5
  for i, item in ipairs(menuItems) do
    if i == selectedItem then
      love.graphics.setColor(colors.light_blue_glow)
    else
      love.graphics.setColor(colors.white)
    end
    local itemWidth = CustomFont:getTextWidth(item.text, 5)
    CustomFont:drawText(item.text, (settings.WINDOW_WIDTH - itemWidth) / 2, yPos, 5)
    item.y = yPos -- Store y position for click detection
    item.height = CustomFont:getTextHeight(5)
    yPos = yPos + 50
  end
end

function Text:drawGameOver(score, hiScore, nuHiScore, hiScoreFlashVisible)
  love.graphics.setColor(0, 0, 0, 0.65)
  love.graphics.rectangle("fill", 0, 0, settings.WINDOW_WIDTH, settings.WINDOW_HEIGHT)

  if nuHiScore then
    if hiScoreFlashVisible then
      love.graphics.setColor(colors.neon_lime_splash)
      local newHigh = "NEW HIGH"
      local newHighWidth = CustomFont:getTextWidth(newHigh, 11)
      CustomFont:drawText(newHigh, (settings.WINDOW_WIDTH - newHighWidth) / 2, settings.WINDOW_HEIGHT * 0.1, 11)
      local scoreText = "SCORE!"
      local scoreWidth = CustomFont:getTextWidth(scoreText, 11)
      CustomFont:drawText(scoreText, (settings.WINDOW_WIDTH - scoreWidth) / 2, settings.WINDOW_HEIGHT * 0.2, 11)
    end
  end

  love.graphics.setColor(colors.naranjaRojo)
  local gameOver = "GAME OVER"
  local gameOverWidth = CustomFont:getTextWidth(gameOver, 11)
  CustomFont:drawText(gameOver, (settings.WINDOW_WIDTH - gameOverWidth) / 2, settings.WINDOW_HEIGHT * 0.4, 11)

  love.graphics.setColor(colors.white)
  local restart = "PRESS SPACE OR CLICK"
  local restartWidth = CustomFont:getTextWidth(restart, 5)
  CustomFont:drawText(restart, (settings.WINDOW_WIDTH - restartWidth) / 2, settings.WINDOW_HEIGHT * 0.55, 5)
  local restart = "TO RESTART"
  local restartWidth = CustomFont:getTextWidth(restart, 5)
  CustomFont:drawText(restart, (settings.WINDOW_WIDTH - restartWidth) / 2, settings.WINDOW_HEIGHT * 0.60, 5)
end

function Text:drawScore(score, hiScore, isMultiplying)
  local scoreText = tostring(math.floor(score))
  local scoreColor = colors.white
  local scoreSize = 5

  if isMultiplying then
    scoreText = scoreText .. " X4"
    scoreSize = 6
    scoreColor = colors.yellow
  end

  love.graphics.setColor(scoreColor)
  CustomFont:drawText(scoreText, 10, 10, scoreSize)

  love.graphics.setColor(colors.white)
  local hiScoreText = "HI: " .. math.floor(hiScore)
  local textWidth = CustomFont:getTextWidth(hiScoreText, 5)
  CustomFont:drawText(hiScoreText, settings.WINDOW_WIDTH - textWidth - 10, 10, 5)
end

function Text:getTextWidth(text, scale)
  return CustomFont:getTextWidth(text, scale)
end

return Text
