local Settings = {
  -- The base game's internal resolution will be 120x160 (aspect ratio 3:4) to provide more vertical play space.
  INTERNAL_WIDTH = 120,
  INTERNAL_HEIGHT = 160,
  -- Enables debug statistics (the on-screen info can be toggled with F3)
  IS_DEBUG_ENABLED = false,
  -- The scale factor and window size will be calculated dynamically in main.lua
  SCALE_FACTOR = 1,
}
-- Platform detection
Settings.IS_MOBILE = love.system.getOS() == "Android" or love.system.getOS() == "iOS"

if Settings.IS_MOBILE then
  local ANDROID_ASPECT_RATIO = love.graphics.getWidth() / love.graphics.getHeight()
  Settings.INTERNAL_HEIGHT = math.floor(Settings.INTERNAL_WIDTH * ANDROID_ASPECT_RATIO)
end

Settings.ASPECT_RATIO = Settings.INTERNAL_WIDTH / Settings.INTERNAL_HEIGHT
Settings.WINDOW_WIDTH = Settings.INTERNAL_WIDTH
Settings.WINDOW_HEIGHT = Settings.INTERNAL_HEIGHT

return Settings
