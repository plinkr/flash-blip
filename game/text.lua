local CustomFont = require("font")
local Colors = require("colors")
local Settings = require("settings")

local Text = {}

CustomFont:init()

function Text.drawCenteredText(text, yPosition, fontSize)
  local textWidth = CustomFont:getTextWidth(text, fontSize)
  local x = (Settings.WINDOW_WIDTH - textWidth) / 2
  CustomFont:drawText(text, x, yPosition, fontSize)
end

local function drawMenuItems(menuItems, selectedItem, startY, fontSize)
  local yPos = startY
  for i, item in ipairs(menuItems) do
    if i == selectedItem then
      love.graphics.setColor(Colors.cyan)
    else
      love.graphics.setColor(Colors.white)
    end
    Text.drawCenteredText(item.text, yPos, fontSize)
    item.y = yPos -- Store y position for click detection
    item.height = CustomFont:getTextHeight(fontSize)
    yPos = yPos + 50
  end
end

local function drawHighScoreFlash(hiScore, nuHiScore, hiScoreFlashVisible)
  if nuHiScore and hiScoreFlashVisible then
    love.graphics.setColor(Colors.neon_lime_splash)
    Text.drawCenteredText("NEW HIGH", Settings.WINDOW_HEIGHT * 0.1, 11)
    Text.drawCenteredText("SCORE!", Settings.WINDOW_HEIGHT * 0.2, 11)
    Text.drawCenteredText(tostring(math.floor(hiScore)), Settings.WINDOW_HEIGHT * 0.3, 11)
  end
end

function Text.drawAttract(menuItems, selectedItem)
  love.graphics.setColor(0, 0, 0, 0.5)
  love.graphics.rectangle("fill", 0, 0, Settings.WINDOW_WIDTH, Settings.WINDOW_HEIGHT)
  love.graphics.setColor(Colors.cyan)
  Text.drawCenteredText("FLASH-BLIP", Settings.WINDOW_HEIGHT * 0.15, 10)

  drawMenuItems(menuItems, selectedItem, Settings.WINDOW_HEIGHT * 0.4, 5)

  love.graphics.setColor(Colors.light_blue_glow)
  local gameVersionWidth = CustomFont:getTextWidth(GAME_VERSION, 2)
  CustomFont:drawText(GAME_VERSION, (Settings.WINDOW_WIDTH - gameVersionWidth) * 0.95, Settings.WINDOW_HEIGHT * 0.95, 2)
  love.graphics.setColor(1, 1, 1)
end

function Text.drawPauseMenu(menuItems, selectedItem)
  love.graphics.setColor(0, 0, 0, 0.65)
  love.graphics.rectangle("fill", 0, 0, Settings.WINDOW_WIDTH, Settings.WINDOW_HEIGHT)
  love.graphics.setColor(Colors.cyan)
  Text.drawCenteredText("PAUSED", Settings.WINDOW_HEIGHT * 0.25, 10)

  drawMenuItems(menuItems, selectedItem, Settings.WINDOW_HEIGHT * 0.5, 5)

  love.graphics.setColor(1, 1, 1)
end

function Text.drawGameOver(hiScore, nuHiScore, hiScoreFlashVisible)
  love.graphics.setColor(0, 0, 0, 0.65)
  love.graphics.rectangle("fill", 0, 0, Settings.WINDOW_WIDTH, Settings.WINDOW_HEIGHT)

  drawHighScoreFlash(hiScore, nuHiScore, hiScoreFlashVisible)

  love.graphics.setColor(Colors.naranjaRojo)
  Text.drawCenteredText("GAME OVER", Settings.WINDOW_HEIGHT * 0.4, 11)

  love.graphics.setColor(Colors.white)
  Text.drawCenteredText("PRESS SPACE OR CLICK", Settings.WINDOW_HEIGHT * 0.55, 5)
  Text.drawCenteredText("TO RESTART", Settings.WINDOW_HEIGHT * 0.60, 5)
end

local function drawCompletionBackground(hiScore, nuHiScore, hiScoreFlashVisible)
  love.graphics.setColor(0, 0, 0, 0.65)
  love.graphics.rectangle("fill", 0, 0, Settings.WINDOW_WIDTH, Settings.WINDOW_HEIGHT)

  drawHighScoreFlash(hiScore, nuHiScore, hiScoreFlashVisible)
end

local function drawContinuePrompt()
  love.graphics.setColor(Colors.white)
  Text.drawCenteredText("PRESS SPACE OR CLICK", Settings.WINDOW_HEIGHT * 0.70, 5)
  Text.drawCenteredText("TO CONTINUE", Settings.WINDOW_HEIGHT * 0.75, 5)
end

function Text.drawLevelCompleted(hiScore, nuHiScore, hiScoreFlashVisible)
  drawCompletionBackground(hiScore, nuHiScore, hiScoreFlashVisible)

  love.graphics.setColor(Colors.neon_lime_splash)
  Text.drawCenteredText("LEVEL", Settings.WINDOW_HEIGHT * 0.4, 10)
  Text.drawCenteredText("COMPLETED!", Settings.WINDOW_HEIGHT * 0.5, 10)

  drawContinuePrompt()
end

function Text.drawAllLevelsCompleted(hiScore, nuHiScore, hiScoreFlashVisible)
  drawCompletionBackground(hiScore, nuHiScore, hiScoreFlashVisible)

  love.graphics.setColor(Colors.neon_lime_splash)
  Text.drawCenteredText("YOU COMPLETED", Settings.WINDOW_HEIGHT * 0.40, 8)
  Text.drawCenteredText("ALL LEVELS!", Settings.WINDOW_HEIGHT * 0.48, 8)
  Text.drawCenteredText("A GREAT FEAT!", Settings.WINDOW_HEIGHT * 0.56, 8)

  drawContinuePrompt()
end

function Text.drawScore(score, hiScore, isMultiplying)
  local scoreText = tostring(math.floor(score))
  local scoreColor = Colors.white
  local scoreSize = 5

  if isMultiplying then
    scoreText = scoreText .. " X4"
    scoreSize = 6
    scoreColor = Colors.yellow
  end

  love.graphics.setColor(scoreColor)
  CustomFont:drawText(scoreText, 10, 10, scoreSize)

  love.graphics.setColor(Colors.white)
  local hiScoreText = "HI: " .. math.floor(hiScore)
  local textWidth = CustomFont:getTextWidth(hiScoreText, 5)
  CustomFont:drawText(hiScoreText, Settings.WINDOW_WIDTH - textWidth - 10, 10, 5)
end

function Text.getTextWidth(text, scale)
  return CustomFont:getTextWidth(text, scale)
end

return Text
