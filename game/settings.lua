-- settings.lua
local settings = {
  -- La resolución interna del juego base será de 120x160 (aspect ratio 3:4),
  -- para dar más espacio vertical de juego.
  INTERNAL_WIDTH = 120,
  INTERNAL_HEIGHT = 160,
}

-- La relación de aspecto se mantiene constante.
settings.ASPECT_RATIO = settings.INTERNAL_WIDTH / settings.INTERNAL_HEIGHT

-- El factor de escala y el tamaño de la ventana se calcularán dinámicamente en main.lua
settings.SCALE_FACTOR = 1
settings.WINDOW_WIDTH = settings.INTERNAL_WIDTH
settings.WINDOW_HEIGHT = settings.INTERNAL_HEIGHT

return settings
