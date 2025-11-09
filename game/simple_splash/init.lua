local Text = require("text")
local Colors = require("colors")

local SimpleSplash = {
  CUBAN_FLAG = "iVBORw0KGgoAAAANSUhEUgAAAKoAAACWBAMAAAC84A5nAAAAAXNSR0IArs4c6QAAAARnQU1BAACx"
    .. "jwv8YQUAAAASUExURUdwTAAAAPz8/gAAgIAAAAICgacQmYMAAAABdFJOUwBA5thmAAAAl0lEQVRo"
    .. "3u3ayw2EIABAQVuwBVugBVvY/lvZyGGJRIiymPiZd4IQ5kbgwDBIknTzxnWHVqlUahmcf4WltDmO"
    .. "wro9NJX6ajWB01Ki4zSuTqXKNJVK3dqX0VQqteeJjX2qtaqhGpX6DHXrpfk/SKVSi2e34Q6kUql1"
    .. "uidIpVIzuvX6o1Kpe+lOIJVKzehzfoBQqa9WJUm6QF+hUqlzAImF5QAAAABJRU5ErkJggg==",
}

function SimpleSplash.new(width, height)
  local self = {}

  self.width = width
  self.height = height
  self.background = Colors.murky_blue
  self.done = false
  self.alpha = 1
  local decoded = love.data.decode("data", "base64", SimpleSplash.CUBAN_FLAG)
  local fileData = love.filesystem.newFileData(decoded, "flag.png")
  local imageData = love.image.newImageData(fileData)
  self.flagImage = love.graphics.newImage(imageData)

  self.loading_text = "LOADING..."
  self.loading_index = 1
  self.loading_timer = 0
  self.loading_delay = 0.2

  self.draw = SimpleSplash.draw
  self.update = SimpleSplash.update
  self.setDone = SimpleSplash.setDone

  return self
end

function SimpleSplash:draw()
  local width, height = self.width, self.height

  love.graphics.clear(self.background)

  love.graphics.setColor(1, 1, 1, self.alpha)
  local imageWidth = self.flagImage:getWidth()
  local imageHeight = self.flagImage:getHeight()
  local scale = math.min(width / imageWidth, height / imageHeight) * 0.5
  local x = (width - imageWidth * scale) / 2
  local y = (height - imageHeight * scale) / 2
  love.graphics.draw(self.flagImage, x, y, 0, scale, scale)

  local imageBottom = y + imageHeight * scale
  local textY = imageBottom + height * 0.01
  Text.drawCenteredText("Made with LOVE2D", textY, 0.8)
  Text.drawCenteredText("by plinkr", textY + height * 0.05, 0.4)

  local loading_display = self.loading_text:sub(1, self.loading_index)
  Text.drawCenteredText(loading_display, textY + height * 0.20, 0.4, 2, 2)
end

function SimpleSplash:update(dt)
  self.loading_timer = self.loading_timer + dt
  if self.loading_timer >= self.loading_delay then
    self.loading_timer = 0
    self.loading_index = self.loading_index + 1
    if self.loading_index > #self.loading_text then
      self.loading_index = 1
    end
  end
end

function SimpleSplash:setDone()
  if not self.done then
    self.done = true
    if self.onDone then
      self.onDone()
    end
  end
end

return SimpleSplash
