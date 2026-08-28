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
  ---@diagnostic disable-next-line: param-type-mismatch
  local image_data = love.image.newImageData(decoded)
  self.flag_image = love.graphics.newImage(image_data)

  self.loading_text = "LOADING..."
  self.loading_index = 1
  self.loading_timer = 0
  self.loading_delay = 0.2

  self.draw = SimpleSplash.draw
  self.update = SimpleSplash.update
  self.set_done = SimpleSplash.set_done

  return self
end

function SimpleSplash:draw()
  local width, height = self.width, self.height

  love.graphics.clear(self.background)

  love.graphics.setColor(1, 1, 1, self.alpha)
  local image_width = self.flag_image:getWidth()
  local image_height = self.flag_image:getHeight()
  local scale = math.min(width / image_width, height / image_height) * 0.5
  local x = (width - image_width * scale) / 2
  local y = (height - image_height * scale) / 2
  love.graphics.draw(self.flag_image, x, y, 0, scale, scale)

  local image_bottom = y + image_height * scale
  local text_y = image_bottom + height * 0.01
  Text.draw_centered_text("Made with LOVE2D", text_y, 0.8)
  Text.draw_centered_text("by plinkr", text_y + height * 0.05, 0.4)

  local loading_display = self.loading_text:sub(1, self.loading_index)
  Text.draw_centered_text(loading_display, text_y + height * 0.20, 0.4, 2, 2)
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

function SimpleSplash:set_done()
  if not self.done then
    self.done = true
    if self.on_done then
      self.on_done()
    end
  end
end

return SimpleSplash
