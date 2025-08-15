local CustomFont = require("font")
local colors = require("colors")
local settings = require("settings")

local Text = {}

CustomFont:init()

local function drawMenuItems(menuItems, selectedItem, startY, fontSize)
  local yPos = startY
  for i, item in ipairs(menuItems) do
    if i == selectedItem then
      love.graphics.setColor(colors.light_blue_glow)
    else
      love.graphics.setColor(colors.white)
    end
    local itemWidth = CustomFont:getTextWidth(item.text, fontSize)
    CustomFont:drawText(item.text, (settings.WINDOW_WIDTH - itemWidth) / 2, yPos, fontSize)
    item.y = yPos -- Store y position for click detection
    item.height = CustomFont:getTextHeight(fontSize)
    yPos = yPos + 50
  end
end

function Text.drawAttract(menuItems, selectedItem)
  love.graphics.setColor(0, 0, 0, 0.5)
  love.graphics.rectangle("fill", 0, 0, settings.WINDOW_WIDTH, settings.WINDOW_HEIGHT)
  love.graphics.setColor(colors.cyan)
  local title = "FLASH-BLIP"
  local titleWidth = CustomFont:getTextWidth(title, 10)
  CustomFont:drawText(title, (settings.WINDOW_WIDTH - titleWidth) / 2, settings.WINDOW_HEIGHT * 0.15, 10)

  local gameVersionWidth = CustomFont:getTextWidth(GAME_VERSION, 2)
  CustomFont:drawText(GAME_VERSION, (settings.WINDOW_WIDTH - gameVersionWidth) * 0.95, settings.WINDOW_HEIGHT * 0.95, 2)

  drawMenuItems(menuItems, selectedItem, settings.WINDOW_HEIGHT * 0.4, 5)
end

function Text.drawPauseMenu(menuItems, selectedItem)
  love.graphics.setColor(0, 0, 0, 0.65)
  love.graphics.rectangle("fill", 0, 0, settings.WINDOW_WIDTH, settings.WINDOW_HEIGHT)
  love.graphics.setColor(colors.cyan)
  local title = "PAUSED"
  local titleWidth = CustomFont:getTextWidth(title, 10)
  CustomFont:drawText(title, (settings.WINDOW_WIDTH - titleWidth) / 2, settings.WINDOW_HEIGHT * 0.25, 10)

  drawMenuItems(menuItems, selectedItem, settings.WINDOW_HEIGHT * 0.5, 5)
end

function Text.drawGameOver(hiScore, nuHiScore, hiScoreFlashVisible)
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
      local hiScoreText = tostring(math.floor(hiScore))
      local hiScoreWidth = CustomFont:getTextWidth(hiScoreText, 11)
      CustomFont:drawText(hiScoreText, (settings.WINDOW_WIDTH - hiScoreWidth) / 2, settings.WINDOW_HEIGHT * 0.3, 11)
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
  restart = "TO RESTART"
  restartWidth = CustomFont:getTextWidth(restart, 5)
  CustomFont:drawText(restart, (settings.WINDOW_WIDTH - restartWidth) / 2, settings.WINDOW_HEIGHT * 0.60, 5)
end

function Text.drawLevelCompleted(hiScore, nuHiScore, hiScoreFlashVisible)
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
      local hiScoreText = tostring(math.floor(hiScore))
      local hiScoreWidth = CustomFont:getTextWidth(hiScoreText, 11)
      CustomFont:drawText(hiScoreText, (settings.WINDOW_WIDTH - hiScoreWidth) / 2, settings.WINDOW_HEIGHT * 0.3, 11)
    end
  end

  love.graphics.setColor(colors.neon_lime_splash)
  local levelCompleted = "LEVEL"
  local levelCompletedWidth = CustomFont:getTextWidth(levelCompleted, 10)
  CustomFont:drawText(
    levelCompleted,
    (settings.WINDOW_WIDTH - levelCompletedWidth) / 2,
    settings.WINDOW_HEIGHT * 0.4,
    10
  )
  levelCompleted = "COMPLETED!"
  levelCompletedWidth = CustomFont:getTextWidth(levelCompleted, 10)
  CustomFont:drawText(
    levelCompleted,
    (settings.WINDOW_WIDTH - levelCompletedWidth) / 2,
    settings.WINDOW_HEIGHT * 0.5,
    10
  )

  love.graphics.setColor(colors.white)
  local continueText = "PRESS SPACE OR CLICK"
  local continueWidth = CustomFont:getTextWidth(continueText, 5)
  CustomFont:drawText(continueText, (settings.WINDOW_WIDTH - continueWidth) / 2, settings.WINDOW_HEIGHT * 0.65, 5)
  continueText = "TO CONTINUE"
  continueWidth = CustomFont:getTextWidth(continueText, 5)
  CustomFont:drawText(continueText, (settings.WINDOW_WIDTH - continueWidth) / 2, settings.WINDOW_HEIGHT * 0.75, 5)
end

function Text.drawScore(score, hiScore, isMultiplying)
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

function Text.getTextWidth(text, scale)
  return CustomFont:getTextWidth(text, scale)
end

return Text
