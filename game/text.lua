local CustomFont = require("custom_font")
local Colors = require("colors")
local Settings = require("settings")

local Text = {}

CustomFont:init()

Text.charHeight = CustomFont.charHeight

function Text.drawCenteredText(text, yPosition, widthPercentage, minScale, maxScale)
  local scale = Text.calculateScaleForWidth(text, widthPercentage)

  if minScale and maxScale then
    local height_factor = Settings.WINDOW_HEIGHT / 800
    minScale = minScale * height_factor
    maxScale = math.min(maxScale, maxScale * height_factor)
    scale = math.max(minScale, math.min(maxScale, scale))
  end

  local textWidth = Text.getTextWidth(text, scale)
  local x = (Settings.WINDOW_WIDTH - textWidth) / 2
  Text.drawText(text, x, yPosition, scale)
end

local function drawMenuItems(menuItems, selectedItem, startY, widthPercentage)
  local uniformScale = Text.calculateUniformScale(menuItems, widthPercentage)

  local yPos = startY
  for i, item in ipairs(menuItems) do
    if i == selectedItem then
      love.graphics.setColor(Colors.cyan)
    else
      love.graphics.setColor(Colors.white)
    end
    -- Use the uniform scale for all items
    local textWidth = Text.getTextWidth(item.text, uniformScale)
    local x = (Settings.WINDOW_WIDTH - textWidth) / 2
    Text.drawText(item.text, x, yPos, uniformScale)
    item.y = yPos -- Store y position for click detection
    item.height = Text.getTextHeight(uniformScale) -- Uniform height based on uniform scale
    yPos = yPos + 50
  end
end

local function drawHighScoreFlash(hiScore, nuHiScore, hiScoreFlashVisible)
  if nuHiScore and hiScoreFlashVisible then
    love.graphics.setColor(Colors.neon_lime_splash)
    Text.drawCenteredText("NEW HIGH", Settings.WINDOW_HEIGHT * 0.08, 0.8)
    Text.drawCenteredText("SCORE!", Settings.WINDOW_HEIGHT * 0.18, 0.55)
    Text.drawCenteredText(tostring(math.floor(hiScore)), Settings.WINDOW_HEIGHT * 0.27, 0.5, 12.0, 15.0)
  end
end

function Text.drawAttract(menuItems, selectedItem)
  love.graphics.setColor(0, 0, 0, 0.5)
  love.graphics.rectangle("fill", 0, 0, Settings.WINDOW_WIDTH, Settings.WINDOW_HEIGHT)
  love.graphics.setColor(Colors.cyan)
  Text.drawCenteredText("FLASH-BLIP", Settings.WINDOW_HEIGHT * 0.15, 0.95)

  drawMenuItems(menuItems, selectedItem, Settings.WINDOW_HEIGHT * 0.4, 0.55)

  Text.drawGameVersion()
  love.graphics.setColor(1, 1, 1)
end

function Text.drawGameVersion()
  love.graphics.setColor(Colors.light_blue_glow)
  local gameVersionScale = Text.calculateScaleForWidth(GAME_VERSION, 0.09)
  local gameVersionWidth = Text.getTextWidth(GAME_VERSION, gameVersionScale)
  Text.drawText(
    GAME_VERSION,
    (Settings.WINDOW_WIDTH - gameVersionWidth) * 0.97,
    Settings.WINDOW_HEIGHT * 0.97,
    gameVersionScale
  )
end

function Text.drawPauseMenu(menuItems, selectedItem)
  love.graphics.setColor(0, 0, 0, 0.65)
  love.graphics.rectangle("fill", 0, 0, Settings.WINDOW_WIDTH, Settings.WINDOW_HEIGHT)
  love.graphics.setColor(Colors.cyan)
  Text.drawCenteredText("PAUSED", Settings.WINDOW_HEIGHT * 0.25, 0.6)

  drawMenuItems(menuItems, selectedItem, Settings.WINDOW_HEIGHT * 0.5, 0.50)

  love.graphics.setColor(1, 1, 1)
end

function Text.drawGameOver(hiScore, nuHiScore, hiScoreFlashVisible)
  love.graphics.setColor(0, 0, 0, 0.65)
  love.graphics.rectangle("fill", 0, 0, Settings.WINDOW_WIDTH, Settings.WINDOW_HEIGHT)

  drawHighScoreFlash(hiScore, nuHiScore, hiScoreFlashVisible)

  love.graphics.setColor(Colors.naranjaRojo)
  Text.drawCenteredText("GAME OVER", Settings.WINDOW_HEIGHT * 0.4, 0.9)

  love.graphics.setColor(Colors.white)
  Text.drawCenteredText("PRESS SPACE OR CLICK", Settings.WINDOW_HEIGHT * 0.55, 0.9)
  Text.drawCenteredText("TO RESTART", Settings.WINDOW_HEIGHT * 0.60, 0.45)
end

local function drawCompletionBackground(hiScore, nuHiScore, hiScoreFlashVisible)
  love.graphics.setColor(0, 0, 0, 0.65)
  love.graphics.rectangle("fill", 0, 0, Settings.WINDOW_WIDTH, Settings.WINDOW_HEIGHT)

  drawHighScoreFlash(hiScore, nuHiScore, hiScoreFlashVisible)
end

local function drawContinuePrompt()
  love.graphics.setColor(Colors.white)
  Text.drawCenteredText("PRESS SPACE OR CLICK", Settings.WINDOW_HEIGHT * 0.70, 0.9)
  Text.drawCenteredText("TO CONTINUE", Settings.WINDOW_HEIGHT * 0.75, 0.5)
end

function Text.drawLevelCompleted(hiScore, nuHiScore, hiScoreFlashVisible)
  drawCompletionBackground(hiScore, nuHiScore, hiScoreFlashVisible)

  love.graphics.setColor(Colors.neon_lime_splash)
  Text.drawCenteredText("LEVEL", Settings.WINDOW_HEIGHT * 0.4, 0.5)
  Text.drawCenteredText("COMPLETED!", Settings.WINDOW_HEIGHT * 0.5, 0.9)

  drawContinuePrompt()
end

function Text.drawAllLevelsCompleted(hiScore, nuHiScore, hiScoreFlashVisible)
  drawCompletionBackground(hiScore, nuHiScore, hiScoreFlashVisible)

  love.graphics.setColor(Colors.neon_lime_splash)
  Text.drawCenteredText("YOU COMPLETED", Settings.WINDOW_HEIGHT * 0.40, 0.95)
  Text.drawCenteredText("ALL LEVELS!", Settings.WINDOW_HEIGHT * 0.48, 0.8)
  Text.drawCenteredText("A GREAT FEAT!", Settings.WINDOW_HEIGHT * 0.56, 0.9)

  drawContinuePrompt()
end

function Text.drawScore(score, hiScore, isMultiplying)
  local currentScoreText = tostring(math.floor(score))
  local scoreColor = Colors.white
  local scoreScale = Text.calculateScaleForWidth(currentScoreText, 0.15)

  if isMultiplying then
    currentScoreText = currentScoreText .. " X4"
    scoreScale = Text.calculateScaleForWidth(currentScoreText, 0.4)
    scoreColor = Colors.yellow
  end

  -- Apply min/max scale based on window height
  local height_factor = Settings.WINDOW_HEIGHT / 800
  local minScale = 3 * height_factor
  local maxScale = 5 * height_factor
  scoreScale = math.max(minScale, math.min(maxScale, scoreScale))

  love.graphics.setColor(scoreColor)
  Text.drawText(currentScoreText, 10, 10, scoreScale)

  love.graphics.setColor(Colors.white)
  local hiScoreText = "HI: " .. math.floor(hiScore)
  local hiScoreScale = Text.calculateScaleForWidth(hiScoreText, 0.15)
  hiScoreScale = math.max(minScale, math.min(maxScale, hiScoreScale))
  local textWidth = Text.getTextWidth(hiScoreText, hiScoreScale)
  Text.drawText(hiScoreText, Settings.WINDOW_WIDTH - textWidth - 10, 10, hiScoreScale)
end

function Text.drawTextByPercentage(text, xPosition, yPosition, widthPercentage)
  local scale = Text.calculateScaleForWidth(text, widthPercentage)
  Text.drawText(text, xPosition, yPosition, scale)
end

function Text.drawText(text, x, y, scale)
  scale = scale or 1
  local currentX = x

  for i = 1, #text do
    local char = string.upper(text:sub(i, i))
    local glyph = CustomFont.glyphs[char]

    if glyph then
      for row = 1, #glyph do
        for col = 1, #glyph[row] do
          if glyph[row]:sub(col, col) ~= " " then
            love.graphics.rectangle("fill", currentX + (col - 1) * scale, y + (row - 1) * scale, scale, scale)
          end
        end
      end

      local width = CustomFont.glyphWidths[char] or CustomFont.spaceWidth
      currentX = currentX + (width + CustomFont.tracking) * scale
    else
      -- Character not found, advance as a space
      currentX = currentX + (CustomFont.spaceWidth + CustomFont.tracking) * scale
    end
  end
end

function Text.getTextWidth(text, scale)
  scale = scale or 1
  local totalWidth = 0
  for i = 1, #text do
    local char = string.upper(text:sub(i, i))
    local width = CustomFont.glyphWidths[char] or CustomFont.spaceWidth
    totalWidth = totalWidth + (width + CustomFont.tracking) * scale
  end
  return totalWidth
end

function Text.getTextHeight(scale)
  scale = scale or 1
  return CustomFont.charHeight * scale
end

function Text.calculateScaleForWidth(text, widthPercentage)
  local targetWidth = Settings.WINDOW_WIDTH * widthPercentage
  local textWidthAtScale1 = Text.getTextWidth(text, 1)
  if textWidthAtScale1 == 0 then
    return 1
  end
  return targetWidth / textWidthAtScale1
end

function Text.calculateUniformScale(menuItems, widthPercentage)
  -- Find the text with the maximum width at scale 1 to determine the uniform scale
  local maxWidth = 0
  local maxWidthText = ""
  for _, item in ipairs(menuItems) do
    local textWidth = Text.getTextWidth(item.text, 1)
    if textWidth > maxWidth then
      maxWidth = textWidth
      maxWidthText = item.text
    end
  end
  -- Calculate the uniform scale based on the longest text
  return Text.calculateScaleForWidth(maxWidthText, widthPercentage)
end

return Text
