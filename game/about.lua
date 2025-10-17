local CustomFont = require("font")
local Colors = require("colors")
local Settings = require("settings")
local Text = require("text")

local about = {}

local url = "https://github.com/plinkr/flash-blip"
local urlBounds = {}

local mitUrl = "https://github.com/plinkr/flash-blip?tab=MIT-1-ov-file"
local mitBounds = {}

function about.load() end

function about.update(dt) end

function about.draw()
  love.graphics.setColor(0, 0, 0, 0.8)
  love.graphics.rectangle("fill", 0, 0, Settings.WINDOW_WIDTH, Settings.WINDOW_HEIGHT)

  love.graphics.setColor(Colors.cyan)
  Text.drawCenteredText("ABOUT", Settings.WINDOW_HEIGHT * 0.1, 9)

  love.graphics.setColor(Colors.neon_lime_splash)
  local description1 = "A FAST-PACED, RETRO-STYLE ARCADE"
  local description2 = "VERTICAL SCROLLER IN LOVE2D"
  local description3 = "SURVIVE AND AIM FOR THE HIGH SCORE!"
  Text.drawCenteredText(description1, Settings.WINDOW_HEIGHT * 0.24, 3.2)
  Text.drawCenteredText(description2, Settings.WINDOW_HEIGHT * 0.27, 3.2)
  Text.drawCenteredText(description3, Settings.WINDOW_HEIGHT * 0.30, 3.2)

  local line1 = "LICENSED UNDER MIT"
  local line1Width = CustomFont:getTextWidth(line1, 4)
  CustomFont:drawText(line1, (Settings.WINDOW_WIDTH - line1Width) / 2, Settings.WINDOW_HEIGHT * 0.5, 4)

  local mitX = (Settings.WINDOW_WIDTH - line1Width) / 2
  local mitY = Settings.WINDOW_HEIGHT * 0.5
  local mitHeight = CustomFont.charHeight * 4
  mitBounds = { x = mitX, y = mitY, width = line1Width, height = mitHeight }

  local line2 = "INSPIRED BY THE WORK OF KENTA CHO"
  Text.drawCenteredText(line2, Settings.WINDOW_HEIGHT * 0.70, 3.3)

  love.graphics.setColor(Colors.neon_lime_splash)
  local urlWidth = CustomFont:getTextWidth(url, 2.9)
  local urlHeight = CustomFont.charHeight * 2.9
  local urlX = (Settings.WINDOW_WIDTH - urlWidth) / 2
  local urlY = Settings.WINDOW_HEIGHT * 0.75
  urlBounds = { x = urlX, y = urlY, width = urlWidth, height = urlHeight }
  CustomFont:drawText(url, urlX, urlY, 2.9)

  love.graphics.setColor(Colors.light_blue_glow)
  local gameVersionWidth = CustomFont:getTextWidth(GAME_VERSION, 2)
  CustomFont:drawText(GAME_VERSION, (Settings.WINDOW_WIDTH - gameVersionWidth) * 0.95, Settings.WINDOW_HEIGHT * 0.95, 2)

  love.graphics.setColor(Colors.white)
  local returnText = "PRESS ESC OR CLICK TO RETURN"
  Text.drawCenteredText(returnText, Settings.WINDOW_HEIGHT * 0.9, 3)
end

function about.keypressed(key) end

function about.mousepressed(x, y, button)
  if button == 1 then
    if
      x > urlBounds.x
      and x < urlBounds.x + urlBounds.width
      and y > urlBounds.y
      and y < urlBounds.y + urlBounds.height
    then
      love.system.openURL(url)
      return true -- Opens the URL
    end

    if
      x > mitBounds.x
      and x < mitBounds.x + mitBounds.width
      and y > mitBounds.y
      and y < mitBounds.y + mitBounds.height
    then
      love.system.openURL(mitUrl)
      return true -- Opens the project's MIT license URL
    end
  end
  return false -- Not clicked on URL, handled in main.lua
end

return about
