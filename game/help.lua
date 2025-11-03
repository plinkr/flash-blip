local Colors = require("colors")
local Settings = require("settings")
local Powerups = require("powerups")
local Text = require("text")
local Input = require("input")

local help = {}

function help.load() end

local function drawHelpScreenStatic()
  love.graphics.setColor(0, 0, 0, 0.9)
  love.graphics.rectangle("fill", 0, 0, Settings.WINDOW_WIDTH, Settings.WINDOW_HEIGHT)
  love.graphics.setColor(Colors.cyan)
  Text.drawCenteredText("HOW TO PLAY", Settings.WINDOW_HEIGHT * 0.03, 0.80)

  love.graphics.setColor(Colors.spiced_amber)
  Text.drawCenteredText("UP/DOWN TO SCROLL", Settings.WINDOW_HEIGHT * 0.12, 0.3)

  love.graphics.setColor(Colors.white)
  local returnText
  if Settings.IS_MOBILE then
    returnText = "PRESS BACK TO RETURN"
  else
    returnText = "PRESS ESC TO RETURN"
  end
  Text.drawCenteredText(returnText, Settings.WINDOW_HEIGHT * 0.97, 0.4)
  Text.drawGameVersion()
end

local function drawHelpScreenScrollable(scrollY)
  scrollY = scrollY or 0
  local leftMargin = Settings.WINDOW_WIDTH * 0.03
  -- local rightMargin = settings.WINDOW_WIDTH * 0.95
  local yPos = Settings.WINDOW_HEIGHT * 0.18 - scrollY

  local moveText, moveScale, pingText, pingScale
  local connectedJoysticks = Input:getConnectedJoysticks()
  local hasController = next(connectedJoysticks) ~= nil

  if Settings.IS_MOBILE then
    moveText = "TOUCH ON SCREEN:"
    moveScale = 0.55
    pingText = "HOLD SCREEN OR DOUBLE TOUCH:"
    pingScale = 0.85
  elseif hasController then
    moveText = "BUTTON 1:"
    moveScale = 0.3
    pingText = "BUTTON 2:"
    pingScale = 0.3
  else
    moveText = "LEFT CLICK OR SPACE:"
    moveScale = 0.6
    pingText = "RIGHT CLICK OR C:"
    pingScale = 0.5
  end

  love.graphics.setColor(Colors.white)
  Text.drawTextByPercentage(moveText, leftMargin, yPos, moveScale)
  yPos = yPos + 45
  Text.drawTextByPercentage("MOVES PLAYER TO THE NEXT POINT", leftMargin + 20, yPos, 0.8)
  yPos = yPos + 55

  love.graphics.setColor(Colors.white)
  Text.drawTextByPercentage(pingText, leftMargin, yPos, pingScale)
  yPos = yPos + 45
  Text.drawTextByPercentage("PINGS TO COLLECT POWERUPS NEARBY", leftMargin + 18, yPos, 0.85)
  yPos = yPos + 55

  love.graphics.setColor(Colors.yellow)
  Powerups.drawStar(leftMargin + 20, yPos + 10, 16, 0)
  Text.drawTextByPercentage("STAR POWERUP:", leftMargin + 70, yPos - 4, 0.4)
  yPos = yPos + 50
  Text.drawTextByPercentage("10 SECONDS OF INVULNERABILITY", leftMargin + 30, yPos - 10, 0.85)
  yPos = yPos + 60

  love.graphics.setColor(Colors.light_blue_glow)
  Powerups.drawClock(leftMargin + 20, yPos + 10, 16, 0)
  Text.drawTextByPercentage("HOURGLASS POWERUP:", leftMargin + 70, yPos - 4, 0.55)
  yPos = yPos + 40
  Text.drawTextByPercentage("SHRINKS AND SLOWS OBSTACLES", leftMargin + 30, yPos, 0.8)
  yPos = yPos + 30
  Text.drawTextByPercentage("PREVENTS PLAYER FROM FALLING", leftMargin + 30, yPos, 0.8)
  yPos = yPos + 60

  love.graphics.setColor(Colors.emerald_shade)
  Powerups.drawPhaseShift(leftMargin + 20, yPos + 10, 24, 0, 6)
  Text.drawTextByPercentage("PHASE SHIFT POWERUP:", leftMargin + 70, yPos - 4, 0.6)
  yPos = yPos + 40
  Text.drawTextByPercentage("RIGHT CLICK PING TELEPORTS", leftMargin + 30, yPos, 0.8)
  yPos = yPos + 30
  Text.drawTextByPercentage("TO NEXT POINT. LASTS 10 SECONDS.", leftMargin + 30, yPos, 0.8)
  yPos = yPos + 60

  love.graphics.setColor(Colors.tangerine_blaze)
  Powerups.drawBolt(leftMargin + 20, yPos + 10, 20, 0, 6)
  Text.drawTextByPercentage("BOLT POWERUP:", leftMargin + 70, yPos - 4, 0.4)
  yPos = yPos + 40
  Text.drawTextByPercentage("A SAFETY NET THAT TELEPORTS YOU", leftMargin + 30, yPos, 0.8)
  yPos = yPos + 30
  Text.drawTextByPercentage("TO THE NEXT POINT. LASTS 30 SECS.", leftMargin + 30, yPos, 0.8)
  yPos = yPos + 60

  love.graphics.setColor(Colors.yellow)
  Powerups.drawScoreMultiplier(leftMargin + 20, yPos + 10, 20, 0)
  Text.drawTextByPercentage("SCORE MULTIPLIER:", leftMargin + 70, yPos - 4, 0.55)
  yPos = yPos + 40
  Text.drawTextByPercentage("MULTIPLY YOUR SCORE BY 4X.", leftMargin + 30, yPos, 0.8)
  yPos = yPos + 30
  Text.drawTextByPercentage("LASTS 30 SECONDS.", leftMargin + 30, yPos, 0.5)
  yPos = yPos + 60

  love.graphics.setColor(Colors.neon_lime_splash)
  Powerups.drawSpawnRateBoost(leftMargin + 20, yPos + 20, 20, 0)
  Text.drawTextByPercentage("SPAWN RATE BOOST:", leftMargin + 70, yPos - 4, 0.55)
  yPos = yPos + 40
  Text.drawTextByPercentage("INCREASES POWERUP SPAWN RATE.", leftMargin + 30, yPos, 0.8)
  yPos = yPos + 30
  Text.drawTextByPercentage("LASTS 30 SECONDS.", leftMargin + 30, yPos, 0.5)
end

function help.draw()
  drawHelpScreenStatic()
  local topBoundary = Settings.WINDOW_HEIGHT * 0.15
  local bottomBoundary = Settings.WINDOW_HEIGHT * 0.95
  love.graphics.setScissor(0, topBoundary, Settings.WINDOW_WIDTH, bottomBoundary - topBoundary)
  drawHelpScreenScrollable(Input.helpScrollY)
  love.graphics.setScissor()
end

return help
