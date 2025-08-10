local CustomFont = require("font")
local colors = require("colors")

local Text = {}

-- Carga y configura la fuente personalizada.
local CustomFont = require("font")
CustomFont:init() -- Calcula el ancho de los glifos.

function Text:drawAttract(attractInstructionVisible)
  love.graphics.setColor(0, 0, 0, 0.2)
  love.graphics.rectangle("fill", 0, 0, 800, 800)
  love.graphics.setColor(colors.cyan)
  CustomFont:drawText("FLASH-BLIP", 60, 200, 10)

  love.graphics.setColor(colors.white)
  if attractInstructionVisible then
    CustomFont:drawText("PRESS SPACE OR CLICK TO BLIP", 55, 320, 4)
    CustomFont:drawText("RIGHT CLICK OR P TO PING", 112, 360, 4)
    CustomFont:drawText("PRESS H FOR HELP", 185, 400, 4)
  end
  love.graphics.setColor(colors.neon_lime_splash)
  CustomFont:drawText("https://github.com/plinkr/flash-blip", 40, 450, 3)
  love.graphics.setColor(1, 1, 1, 1)
end

function Text:drawGameOver(score, hiScore, nuHiScore, hiScoreFlashVisible)
  love.graphics.setColor(0, 0, 0, 0.65)
  love.graphics.rectangle("fill", 0, 0, 800, 800)

  if nuHiScore then
    if hiScoreFlashVisible then
      love.graphics.setColor(colors.neon_lime_splash)
      CustomFont:drawText("NEW HIGH", 140, 80, 10)
      CustomFont:drawText("SCORE!", 220, 180, 10)
    end
  end

  love.graphics.setColor(colors.naranjaRojo)
  CustomFont:drawText("GAME OVER", 120, 330, 10)
  love.graphics.setColor(colors.white)
  CustomFont:drawText("PRESS SPACE OR CLICK TO RESTART", 8, 450, 4)
end

function Text:drawScore(score, hiScore)
  love.graphics.setColor(colors.white)
  CustomFont:drawText(tostring(math.floor(score)), 10, 10, 5)
  local hiScoreText = "HI: " .. math.floor(hiScore)
  local textWidth = CustomFont:getTextWidth(hiScoreText, 5)
  CustomFont:drawText(hiScoreText, 800 - textWidth - 10, 10, 5)
end

function Text:drawHelpScreen()
  love.graphics.setColor(0, 0, 0, 0.9)
  love.graphics.rectangle("fill", 0, 0, 800, 800)
  love.graphics.setColor(colors.cyan)
  CustomFont:drawText("HOW TO PLAY", 100, 40, 9)

  love.graphics.setColor(colors.white)
  CustomFont:drawText("LEFT CLICK OR SPACE:", 30, 150, 3)
  CustomFont:drawText("MOVES PLAYER TO THE NEXT POINT", 80, 200, 3)

  love.graphics.setColor(colors.white)
  CustomFont:drawText("RIGHT CLICK OR P:", 30, 250, 3)
  CustomFont:drawText("PINGS TO COLLECT POWERUPS IN RADIUS", 80, 300, 3)

  love.graphics.setColor(colors.yellow)
  CustomFont:drawText("STAR POWERUP:", 30, 410, 3)
  CustomFont:drawText("10 SECONDS OF INVULNERABILITY", 80, 460, 3)

  love.graphics.setColor(colors.light_blue_glow)
  CustomFont:drawText("HOURGLASS POWERUP:", 30, 520, 3)
  CustomFont:drawText("SHRINKS OBSTACLES, SLOWS THEM DOWN,", 80, 570, 3)
  CustomFont:drawText("AND STOPS THE PLAYER FROM FALLING", 80, 610, 3)

  love.graphics.setColor(colors.white)
  CustomFont:drawText("PRESS H TO RETURN", 230, 700, 3)
end

return Text
