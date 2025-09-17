local CustomFont = require("font")
local colors = require("colors")
local settings = require("settings")

local Text = {}

CustomFont:init()

function Text.drawCenteredText(text, yPosition, fontSize)
  local textWidth = CustomFont:getTextWidth(text, fontSize)
  local x = (settings.WINDOW_WIDTH - textWidth) / 2
  CustomFont:drawText(text, x, yPosition, fontSize)
end

local function drawMenuItems(menuItems, selectedItem, startY, fontSize)
  local yPos = startY
  for i, item in ipairs(menuItems) do
    if i == selectedItem then
      love.graphics.setColor(colors.cyan)
    else
      love.graphics.setColor(colors.white)
    end
    Text.drawCenteredText(item.text, yPos, fontSize)
    item.y = yPos -- Store y position for click detection
    item.height = CustomFont:getTextHeight(fontSize)
    yPos = yPos + 50
  end
end

local function drawHighScoreFlash(hiScore, nuHiScore, hiScoreFlashVisible)
  if nuHiScore and hiScoreFlashVisible then
    love.graphics.setColor(colors.neon_lime_splash)
    Text.drawCenteredText("NEW HIGH", settings.WINDOW_HEIGHT * 0.1, 11)
    Text.drawCenteredText("SCORE!", settings.WINDOW_HEIGHT * 0.2, 11)
    Text.drawCenteredText(tostring(math.floor(hiScore)), settings.WINDOW_HEIGHT * 0.3, 11)
  end
end

function Text.drawAttract(menuItems, selectedItem)
  love.graphics.setColor(0, 0, 0, 0.5)
  love.graphics.rectangle("fill", 0, 0, settings.WINDOW_WIDTH, settings.WINDOW_HEIGHT)
  love.graphics.setColor(colors.cyan)
  Text.drawCenteredText("FLASH-BLIP", settings.WINDOW_HEIGHT * 0.15, 10)

  drawMenuItems(menuItems, selectedItem, settings.WINDOW_HEIGHT * 0.4, 5)

  love.graphics.setColor(colors.light_blue_glow)
  local gameVersionWidth = CustomFont:getTextWidth(GAME_VERSION, 2)
  CustomFont:drawText(GAME_VERSION, (settings.WINDOW_WIDTH - gameVersionWidth) * 0.95, settings.WINDOW_HEIGHT * 0.95, 2)
  love.graphics.setColor(1, 1, 1)
end

function Text.drawPauseMenu(menuItems, selectedItem)
  love.graphics.setColor(0, 0, 0, 0.65)
  love.graphics.rectangle("fill", 0, 0, settings.WINDOW_WIDTH, settings.WINDOW_HEIGHT)
  love.graphics.setColor(colors.cyan)
  Text.drawCenteredText("PAUSED", settings.WINDOW_HEIGHT * 0.25, 10)

  drawMenuItems(menuItems, selectedItem, settings.WINDOW_HEIGHT * 0.5, 5)

  love.graphics.setColor(1, 1, 1)
end

function Text.drawGameOver(hiScore, nuHiScore, hiScoreFlashVisible)
  love.graphics.setColor(0, 0, 0, 0.65)
  love.graphics.rectangle("fill", 0, 0, settings.WINDOW_WIDTH, settings.WINDOW_HEIGHT)

  drawHighScoreFlash(hiScore, nuHiScore, hiScoreFlashVisible)

  love.graphics.setColor(colors.naranjaRojo)
  Text.drawCenteredText("GAME OVER", settings.WINDOW_HEIGHT * 0.4, 11)

  love.graphics.setColor(colors.white)
  Text.drawCenteredText("PRESS SPACE OR CLICK", settings.WINDOW_HEIGHT * 0.55, 5)
  Text.drawCenteredText("TO RESTART", settings.WINDOW_HEIGHT * 0.60, 5)
end

local function drawCompletionBackground(hiScore, nuHiScore, hiScoreFlashVisible)
  love.graphics.setColor(0, 0, 0, 0.65)
  love.graphics.rectangle("fill", 0, 0, settings.WINDOW_WIDTH, settings.WINDOW_HEIGHT)

  drawHighScoreFlash(hiScore, nuHiScore, hiScoreFlashVisible)
end

local function drawContinuePrompt()
  love.graphics.setColor(colors.white)
  Text.drawCenteredText("PRESS SPACE OR CLICK", settings.WINDOW_HEIGHT * 0.70, 5)
  Text.drawCenteredText("TO CONTINUE", settings.WINDOW_HEIGHT * 0.75, 5)
end

function Text.drawLevelCompleted(hiScore, nuHiScore, hiScoreFlashVisible)
  drawCompletionBackground(hiScore, nuHiScore, hiScoreFlashVisible)

  love.graphics.setColor(colors.neon_lime_splash)
  Text.drawCenteredText("LEVEL", settings.WINDOW_HEIGHT * 0.4, 10)
  Text.drawCenteredText("COMPLETED!", settings.WINDOW_HEIGHT * 0.5, 10)

  drawContinuePrompt()
end

function Text.drawAllLevelsCompleted(hiScore, nuHiScore, hiScoreFlashVisible)
  drawCompletionBackground(hiScore, nuHiScore, hiScoreFlashVisible)

  love.graphics.setColor(colors.neon_lime_splash)
  Text.drawCenteredText("YOU COMPLETED", settings.WINDOW_HEIGHT * 0.40, 8)
  Text.drawCenteredText("ALL LEVELS!", settings.WINDOW_HEIGHT * 0.48, 8)
  Text.drawCenteredText("A GREAT FEAT!", settings.WINDOW_HEIGHT * 0.56, 8)

  drawContinuePrompt()
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
