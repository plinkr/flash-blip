local settings = {
  -- The base game's internal resolution will be 120x160 (aspect ratio 3:4) to provide more vertical play space.
  INTERNAL_WIDTH = 120,
  INTERNAL_HEIGHT = 160,
}

settings.ASPECT_RATIO = settings.INTERNAL_WIDTH / settings.INTERNAL_HEIGHT

-- The scale factor and window size will be calculated dynamically in main.lua
settings.SCALE_FACTOR = 1
settings.WINDOW_WIDTH = settings.INTERNAL_WIDTH
settings.WINDOW_HEIGHT = settings.INTERNAL_HEIGHT

return settings
