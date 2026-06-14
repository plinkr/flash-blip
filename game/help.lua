local Colors = require("colors")
local Settings = require("settings")
local Powerups = require("powerups")
local Debuffs = require("debuffs")
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
  local returnTextSize
  if Settings.IS_MOBILE then
    returnText = "PRESS BACK TO RETURN"
    returnTextSize = 0.4
  else
    returnText = "PRESS ESC OR CLICK TO RETURN"
    returnTextSize = 0.6
  end
  Text.drawCenteredText(returnText, Settings.WINDOW_HEIGHT * 0.97, returnTextSize)
  Text.drawGameVersion()
end

local function drawHelpScreenScrollable(scrollY)
  scrollY = scrollY or 0
  local leftMargin = Settings.WINDOW_WIDTH * 0.03
  local startY = Settings.WINDOW_HEIGHT * 0.18
  local yPos = startY - scrollY

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

  local function drawText(text, x, widthPct, color)
    love.graphics.setColor(color or Colors.white)
    local scale = Text.calculateScaleForWidth(text, widthPct)
    Text.drawText(text, x, yPos, scale)
    local height = Text.getTextHeight(scale)
    yPos = yPos + height + (Settings.WINDOW_HEIGHT * 0.015)
  end

  local function drawSectionHeader(text, widthPct, color)
    drawText(text, leftMargin, widthPct, color)
  end

  local function drawSectionDetail(text, widthPct, color)
    drawText(text, leftMargin + (Settings.WINDOW_WIDTH * 0.02), widthPct, color)
  end

  drawSectionHeader(moveText, moveScale)
  drawSectionDetail("MOVES PLAYER TO THE NEXT POINT", 0.8)
  yPos = yPos + (Settings.WINDOW_HEIGHT * 0.02)

  drawSectionHeader(pingText, pingScale)
  drawSectionDetail("PINGS TO COLLECT POWERUPS NEARBY", 0.85)
  yPos = yPos + (Settings.WINDOW_HEIGHT * 0.02)

  local textIconOffset = Settings.WINDOW_WIDTH * 0.08

  local function drawPowerupHeader(
    drawIconFunc,
    rFactor,
    yOffsetFactor,
    text,
    widthPct,
    color,
    hasLineWidth,
    lwMultiplier
  )
    local scale = Text.calculateScaleForWidth(text, widthPct)
    local textHeight = Text.getTextHeight(scale)
    local baseR = (textHeight / 2) * 1.4
    local r = baseR * (rFactor or 1)
    local iconX = leftMargin + (Settings.WINDOW_WIDTH * 0.02)
    local iconY = yPos + (textHeight / 2) + (r * (yOffsetFactor or 0))

    love.graphics.setColor(color)
    if hasLineWidth then
      local lw = math.max(1, r * 0.2) * (lwMultiplier or 1)
      drawIconFunc(iconX, iconY, r, 0, lw)
    else
      drawIconFunc(iconX, iconY, r, 0)
    end
    drawText(text, leftMargin + textIconOffset, widthPct, color)
  end

  drawPowerupHeader(Powerups.drawStar, 1.0, 0, "STAR POWERUP:", 0.4, Colors.yellow)
  drawSectionDetail("10 SECONDS OF INVULNERABILITY", 0.85, Colors.yellow)
  yPos = yPos + (Settings.WINDOW_HEIGHT * 0.02)

  drawPowerupHeader(Powerups.drawClock, 1.0, 0, "HOURGLASS POWERUP:", 0.55, Colors.light_blue_glow)
  drawSectionDetail("SHRINKS AND SLOWS OBSTACLES", 0.8, Colors.light_blue_glow)
  drawSectionDetail("PREVENTS PLAYER FROM FALLING", 0.8, Colors.light_blue_glow)
  yPos = yPos + (Settings.WINDOW_HEIGHT * 0.02)

  drawPowerupHeader(Powerups.drawPhaseShift, 1.6, 0, "PHASE SHIFT POWERUP:", 0.6, Colors.emerald_shade, true, 1.2)
  drawSectionDetail("RIGHT CLICK PING TELEPORTS", 0.8, Colors.emerald_shade)
  drawSectionDetail("TO NEXT POINT. LASTS 10 SECONDS.", 0.8, Colors.emerald_shade)
  yPos = yPos + (Settings.WINDOW_HEIGHT * 0.02)

  drawPowerupHeader(Powerups.drawBolt, 1.2, 0, "BOLT POWERUP:", 0.4, Colors.tangerine_blaze, true, 1.2)
  drawSectionDetail("A SAFETY NET THAT TELEPORTS YOU", 0.8, Colors.tangerine_blaze)
  drawSectionDetail("TO THE NEXT POINT. LASTS 30 SECS.", 0.8, Colors.tangerine_blaze)
  yPos = yPos + (Settings.WINDOW_HEIGHT * 0.02)

  drawPowerupHeader(Powerups.drawScoreMultiplier, 1.0, 0, "SCORE MULTIPLIER:", 0.55, Colors.yellow)
  drawSectionDetail("MULTIPLY YOUR SCORE BY 4X.", 0.8, Colors.yellow)
  drawSectionDetail("LASTS 30 SECONDS.", 0.5, Colors.yellow)
  yPos = yPos + (Settings.WINDOW_HEIGHT * 0.02)

  drawPowerupHeader(Powerups.drawSpawnRateBoost, 1.1, 0.4, "SPAWN RATE BOOST:", 0.55, Colors.neon_lime_splash)
  drawSectionDetail("INCREASES POWERUP SPAWN RATE.", 0.8, Colors.neon_lime_splash)
  drawSectionDetail("LASTS 30 SECONDS.", 0.5, Colors.neon_lime_splash)
  yPos = yPos + (Settings.WINDOW_HEIGHT * 0.02)

  drawPowerupHeader(Debuffs.draw_emp_fuse, 1.1, 0.20, "PING GLITCH DEBUFF:", 0.55, Colors.crimson, true, 1.2)
  drawSectionDetail("REMOVES ACTIVE POWERUPS ON CONTACT.", 0.85, Colors.crimson)
  drawSectionDetail("BLOCKS ALL PING ACTIONS FOR 10 SECS.", 0.85, Colors.crimson)
  yPos = yPos + (Settings.WINDOW_HEIGHT * 0.01)
  drawSectionDetail("HINT: THE DEBUFF AND POWERUPS CANCEL EACH OTHER", 0.85, Colors.periwinkle_mist)
  drawSectionDetail("PLAY CAREFULLY AND BLIP OVER POWERUPS TO CANCEL IT", 0.90, Colors.periwinkle_mist)

  return yPos + scrollY - startY
end

function help.draw()
  drawHelpScreenStatic()
  local topBoundary = Settings.WINDOW_HEIGHT * 0.15
  local bottomBoundary = Settings.WINDOW_HEIGHT * 0.95
  love.graphics.setScissor(0, topBoundary, Settings.WINDOW_WIDTH, bottomBoundary - topBoundary)

  local contentHeight = drawHelpScreenScrollable(Input.helpScrollY)
  love.graphics.setScissor()

  local viewHeight = bottomBoundary - topBoundary
  Input.maxHelpScroll = math.max(0, contentHeight - viewHeight + (Settings.WINDOW_HEIGHT * 0.05))
end

return help
