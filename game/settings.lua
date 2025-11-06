local Settings = {
  INTERNAL_WIDTH = 120,
  INTERNAL_HEIGHT = 160,
  -- Enables debug statistics (the on-screen info can be toggled with F3)
  IS_DEBUG_ENABLED = false,
  -- The scale factor and window size will be calculated dynamically in main.lua
  SCALE_FACTOR = 1,
  -- Platform detection
  IS_MOBILE = love.system.getOS() == "Android" or love.system.getOS() == "iOS",
  IS_ARM_LINUX = love.system.getOS() == "Linux" and (require("ffi").arch == "arm" or require("ffi").arch == "arm64"),
  OPENGL_VERSION = select(2, love.graphics.getRendererInfo()),
  IS_WEB = love.system.getOS() == "Web",
  SUPPORTS_GLSL3 = love.graphics.getSupported().glsl3,
  ASPECT_RATIO = nil,
  WINDOW_WIDTH = 120,
  WINDOW_HEIGHT = 160,
  -- DPI scale for mobile devices
  DPI_SCALE = 1,
  -- Maximum number of levels for Arcade Mode
  MAX_LEVELS = 100,
  IS_MUSIC_ENABLED = true,
  IS_SFX_ENABLED = true,
}

return Settings
