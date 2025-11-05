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
  Text.drawCenteredText("ABOUT", Settings.WINDOW_HEIGHT * 0.1, 0.45)

  love.graphics.setColor(Colors.neon_lime_splash)
  local description1 = "A FAST-PACED, RETRO-STYLE ARCADE"
  local description2 = "VERTICAL SCROLLER IN LOVE2D"
  local description3 = "SURVIVE AND AIM FOR THE HIGH SCORE!"
  Text.drawCenteredText(description1, Settings.WINDOW_HEIGHT * 0.24, 0.95)
  Text.drawCenteredText(description2, Settings.WINDOW_HEIGHT * 0.27, 0.80)
  Text.drawCenteredText(description3, Settings.WINDOW_HEIGHT * 0.30, 0.96)

  local lineMIT = "LICENSED UNDER MIT"
  local lineMITScale = Text.calculateScaleForWidth(lineMIT, 0.8)
  local lineMITWidth = Text.getTextWidth(lineMIT, lineMITScale)
  local mitHeight = Text.getTextHeight(lineMITScale)
  local mitX = (Settings.WINDOW_WIDTH - lineMITWidth) / 2
  local mitY = Settings.WINDOW_HEIGHT * 0.5
  mitBounds = { x = mitX, y = mitY, width = lineMITWidth, height = mitHeight }
  Text.drawCenteredText(lineMIT, mitY, 0.8)

  local lineKentaCho = "INSPIRED BY THE WORK OF KENTA CHO"
  Text.drawCenteredText(lineKentaCho, Settings.WINDOW_HEIGHT * 0.70, 0.9)

  local urlScale = Text.calculateScaleForWidth(url, 0.9)
  local urlWidth = Text.getTextWidth(url, urlScale)
  local urlHeight = Text.getTextHeight(urlScale)
  local urlX = (Settings.WINDOW_WIDTH - urlWidth) / 2
  local urlY = Settings.WINDOW_HEIGHT * 0.75
  urlBounds = { x = urlX, y = urlY, width = urlWidth, height = urlHeight }
  Text.drawCenteredText(url, urlY, 0.95)

  Text.drawGameVersion()

  love.graphics.setColor(Colors.white)
  local returnText
  if Settings.IS_MOBILE then
    returnText = "PRESS BACK OR TOUCH TO RETURN"
  else
    returnText = "PRESS ESC OR CLICK TO RETURN"
  end
  Text.drawCenteredText(returnText, Settings.WINDOW_HEIGHT * 0.9, 0.6)
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
