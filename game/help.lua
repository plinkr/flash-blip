-- help.lua
local CustomFont = require("font")
local colors = require("colors")
local settings = require("settings")
local Powerups = require("powerups")

local help = {}
local helpScrollY = 0

function help.load() end

function help.update(dt) end

local function drawHelpScreenStatic()
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
  local returnText = "PRESS ESC TO RETURN"
  local returnWidth = CustomFont:getTextWidth(returnText, 3)
  CustomFont:drawText(returnText, (settings.WINDOW_WIDTH - returnWidth) / 2, settings.WINDOW_HEIGHT * 0.95, 3)
end

local function drawHelpScreenScrollable(scrollY)
  scrollY = scrollY or 0
  local leftMargin = settings.WINDOW_WIDTH * 0.03
  -- local rightMargin = settings.WINDOW_WIDTH * 0.95
  local yPos = settings.WINDOW_HEIGHT * 0.18 - scrollY

  love.graphics.setColor(colors.white)
  CustomFont:drawText("LEFT CLICK OR SPACE:", leftMargin, yPos, 3)
  yPos = yPos + 40
  CustomFont:drawText("MOVES PLAYER TO THE NEXT POINT", leftMargin + 20, yPos, 3)
  yPos = yPos + 60

  love.graphics.setColor(colors.white)
  CustomFont:drawText("RIGHT CLICK OR C:", leftMargin, yPos, 3)
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
  Powerups.drawScoreMultiplier(leftMargin + 20, yPos + 10, 20, 0)
  CustomFont:drawText("SCORE MULTIPLIER:", leftMargin + 70, yPos - 4, 3)
  yPos = yPos + 40
  CustomFont:drawText("MULTIPLY YOUR SCORE BY 4X.", leftMargin + 30, yPos, 3)
  yPos = yPos + 30
  CustomFont:drawText("LASTS 15 SECONDS.", leftMargin + 30, yPos, 3)
  yPos = yPos + 60

  love.graphics.setColor(colors.neon_lime_splash)
  Powerups.drawSpawnRateBoost(leftMargin + 20, yPos + 10, 20, 0)
  CustomFont:drawText("SPAWN RATE BOOST:", leftMargin + 70, yPos - 4, 3)
  yPos = yPos + 40
  CustomFont:drawText("INCREASES POWERUP SPAWN RATE.", leftMargin + 30, yPos, 3)
  yPos = yPos + 30
  CustomFont:drawText("LASTS 30 SECONDS.", leftMargin + 30, yPos, 3)
end

function help.draw()
  drawHelpScreenStatic()
  local topBoundary = settings.WINDOW_HEIGHT * 0.15
  local bottomBoundary = settings.WINDOW_HEIGHT * 0.9
  love.graphics.setScissor(0, topBoundary, settings.WINDOW_WIDTH, bottomBoundary - topBoundary)
  drawHelpScreenScrollable(helpScrollY)
  love.graphics.setScissor() -- Reset scissor
end

function help.keypressed(key)
  if key == "escape" then
    -- This will be handled in main.lua to return to the previous state
  elseif key == "up" then
    helpScrollY = math.max(0, helpScrollY - 20)
  elseif key == "down" then
    helpScrollY = math.min(300, helpScrollY + 20)
  end
end

function help.wheelmoved(x, y)
  helpScrollY = helpScrollY - y * 20 -- y is -1 for up, 1 for down
  helpScrollY = math.max(0, helpScrollY)
  helpScrollY = math.min(300, helpScrollY)
end

function help.mousepressed(x, y, button)
  if button == 1 then
    -- This will be handled in main.lua to return to the previous state
  end
end

return help
