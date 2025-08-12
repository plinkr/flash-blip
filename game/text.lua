local CustomFont = require("font")
local colors = require("colors")
local Powerups = require("powerups")
local settings = require("settings")

local Text = {}

-- Carga y configura la fuente personalizada.
local CustomFont = require("font")
CustomFont:init()

function Text:drawAttract(attractInstructionVisible)
  love.graphics.setColor(0, 0, 0, 0.5)
  love.graphics.rectangle("fill", 0, 0, settings.WINDOW_WIDTH, settings.WINDOW_HEIGHT)
  love.graphics.setColor(colors.cyan)
  local title = "FLASH-BLIP"
  local titleWidth = CustomFont:getTextWidth(title, 10)
  CustomFont:drawText(title, (settings.WINDOW_WIDTH - titleWidth) / 2, settings.WINDOW_HEIGHT * 0.25, 10)

  love.graphics.setColor(colors.white)
  if attractInstructionVisible then
    local line1 = "PRESS SPACE OR CLICK TO BLIP"
    local line1width = CustomFont:getTextWidth(line1, 4)
    CustomFont:drawText(line1, (settings.WINDOW_WIDTH - line1width) / 2, settings.WINDOW_HEIGHT * 0.4, 4)

    local line2 = "RIGHT CLICK OR P TO PING"
    local line2width = CustomFont:getTextWidth(line2, 4)
    CustomFont:drawText(line2, (settings.WINDOW_WIDTH - line2width) / 2, settings.WINDOW_HEIGHT * 0.45, 4)

    local line3 = "PRESS H FOR HELP"
    local line3width = CustomFont:getTextWidth(line3, 4)
    CustomFont:drawText(line3, (settings.WINDOW_WIDTH - line3width) / 2, settings.WINDOW_HEIGHT * 0.5, 4)
  end
  love.graphics.setColor(colors.neon_lime_splash)
  local url = "https://github.com/plinkr/flash-blip"
  local urlWidth = CustomFont:getTextWidth(url, 2.9)
  CustomFont:drawText(url, (settings.WINDOW_WIDTH - urlWidth) / 2, settings.WINDOW_HEIGHT * 0.75, 2.9)
  love.graphics.setColor(1, 1, 1, 1)
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

function Text:drawHelpScreenStatic()
  love.graphics.setColor(0, 0, 0, 0.9)
  love.graphics.rectangle("fill", 0, 0, settings.WINDOW_WIDTH, settings.WINDOW_HEIGHT)
  love.graphics.setColor(colors.cyan)
  local title = "HOW TO PLAY"
  local titleWidth = CustomFont:getTextWidth(title, 9)
  CustomFont:drawText(title, (settings.WINDOW_WIDTH - titleWidth) / 2, settings.WINDOW_HEIGHT * 0.03, 9)

  love.graphics.setColor(colors.spiced_amber)
  local scrollText = "UP/DOWN TO SCROLL"
  local scrollTextWidth = CustomFont:getTextWidth(scrollText, 2)
  CustomFont:drawText(scrollText, (settings.WINDOW_WIDTH - scrollTextWidth) / 2, settings.WINDOW_HEIGHT * 0.12, 2)

  love.graphics.setColor(colors.white)
  local returnText = "PRESS H TO RETURN"
  local returnWidth = CustomFont:getTextWidth(returnText, 3)
  CustomFont:drawText(returnText, (settings.WINDOW_WIDTH - returnWidth) / 2, settings.WINDOW_HEIGHT * 0.95, 3)
end

function Text:drawHelpScreenScrollable(scrollY)
  scrollY = scrollY or 0
  local leftMargin = settings.WINDOW_WIDTH * 0.03
  local rightMargin = settings.WINDOW_WIDTH * 0.95
  local yPos = settings.WINDOW_HEIGHT * 0.18 - scrollY

  love.graphics.setColor(colors.white)
  CustomFont:drawText("LEFT CLICK OR SPACE:", leftMargin, yPos, 3)
  yPos = yPos + 40
  CustomFont:drawText("MOVES PLAYER TO THE NEXT POINT", leftMargin + 20, yPos, 3)
  yPos = yPos + 60

  love.graphics.setColor(colors.white)
  CustomFont:drawText("RIGHT CLICK OR P:", leftMargin, yPos, 3)
  yPos = yPos + 40
  CustomFont:drawText("PINGS TO COLLECT POWERUPS NEARBY", leftMargin + 18, yPos, 3)
  yPos = yPos + 80

  love.graphics.setColor(colors.yellow)
  Powerups.drawStar(leftMargin + 20, yPos + 10, 16, 0)
  CustomFont:drawText("STAR POWERUP:", leftMargin + 70, yPos - 4, 3)
  yPos = yPos + 50
  CustomFont:drawText("10 SECONDS OF INVULNERABILITY.", leftMargin + 30, yPos - 10, 3)
  yPos = yPos + 60

  love.graphics.setColor(colors.light_blue_glow)
  Powerups.drawClock(leftMargin + 20, yPos + 10, 16, 0)
  CustomFont:drawText("HOURGLASS POWERUP:", leftMargin + 70, yPos - 4, 3)
  yPos = yPos + 40
  CustomFont:drawText("SHRINKS AND SLOWS OBSTACLES.", leftMargin + 30, yPos, 3)
  yPos = yPos + 30
  CustomFont:drawText("PREVENTS PLAYER FROM FALLING.", leftMargin + 30, yPos, 3)
  yPos = yPos + 60

  love.graphics.setColor(colors.emerald_shade)
  Powerups.drawPhaseShift(leftMargin + 20, yPos + 10, 24, 0, 6)
  CustomFont:drawText("PHASE SHIFT POWERUP:", leftMargin + 70, yPos - 4, 3)
  yPos = yPos + 40
  CustomFont:drawText("RIGHT CLICK PING TELEPORTS", leftMargin + 30, yPos, 3)
  yPos = yPos + 30
  CustomFont:drawText("TO NEXT POINT. LASTS 10 SECONDS.", leftMargin + 30, yPos, 3)
  yPos = yPos + 60

  love.graphics.setColor(colors.tangerine_blaze)
  Powerups.drawBolt(leftMargin + 20, yPos + 10, 20, 0, 6)
  CustomFont:drawText("BOLT POWERUP:", leftMargin + 70, yPos - 4, 3)
  yPos = yPos + 40
  CustomFont:drawText("A SAFETY NET THAT TELEPORTS YOU", leftMargin + 30, yPos, 3)
  yPos = yPos + 30
  CustomFont:drawText("TO THE NEXT POINT. LASTS 30 SECS.", leftMargin + 30, yPos, 3)
  yPos = yPos + 60

  love.graphics.setColor(colors.yellow)
  Powerups.drawScoreMultiplier(leftMargin + 20, yPos + 10, 20, 0, 6)
  CustomFont:drawText("SCORE MULTIPLIER:", leftMargin + 70, yPos - 4, 3)
  yPos = yPos + 40
  CustomFont:drawText("MULTIPLY YOUR SCORE BY 4X.", leftMargin + 30, yPos, 3)
  yPos = yPos + 30
  CustomFont:drawText("LASTS 15 SECONDS.", leftMargin + 30, yPos, 3)
  yPos = yPos + 60

  love.graphics.setColor(colors.neon_lime_splash)
  Powerups.drawSpawnRateBoost(leftMargin + 20, yPos + 10, 20, 0, 6)
  CustomFont:drawText("SPAWN RATE BOOST:", leftMargin + 70, yPos - 4, 3)
  yPos = yPos + 40
  CustomFont:drawText("INCREASES POWERUP SPAWN RATE.", leftMargin + 30, yPos, 3)
  yPos = yPos + 30
  CustomFont:drawText("LASTS 30 SECONDS.", leftMargin + 30, yPos, 3)
  yPos = yPos + 60
end

return Text
