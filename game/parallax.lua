local Settings = require("settings")
local Parallax = {}

local AllColors = require("colors")

local colors = {
  periwinkle_mist = AllColors.periwinkle_mist,
  skyline_azure = AllColors.skyline_azure,
  royal_sapphire = AllColors.royal_sapphire,
  midnight_harbor = AllColors.midnight_harbor,
}

local color_names = {}
for name, _ in pairs(colors) do
  table.insert(color_names, name)
end

local function get_random_color()
  local random_index = math.random(#color_names)
  local random_name = color_names[random_index]
  return colors[random_name]
end

local layers = {}
local num_layers = 4
local paused = false
local backgroundColor = AllColors.dark_blue
local starColors = { get_random_color() }

function Parallax.setColors(bg, stars)
  backgroundColor = bg
  starColors = stars
end

local function get_random_color(colors_table)
  local colors_to_use = colors_table or starColors
  if #colors_to_use == 0 then
    return get_random_color(colors)
  end
  return colors_to_use[math.random(#colors_to_use)]
end

function Parallax.pause()
  paused = true
end

function Parallax.resume()
  paused = false
end

function Parallax.load(bgColor, sColors)
  if bgColor and sColors then
    Parallax.setColors(bgColor, sColors)
  end
  layers = {}
  for i = 1, num_layers do
    local stars_in_layer = math.random(50, 100)
    layers[i] = {
      stars = {},
      -- Deeper layers move slower, closer layers are faster
      speed = i * 15 + 5,
      -- Closer layers have bigger stars
      size = 1 + (i / num_layers) * 3,
    }
    for _ = 1, stars_in_layer do
      table.insert(layers[i].stars, {
        x = math.random(Settings.WINDOW_WIDTH),
        y = math.random(Settings.WINDOW_HEIGHT),
        -- Use different colors for different layers to enhance depth
        color = get_random_color(),
      })
    end
  end
end

function Parallax.update(dt, gameState)
  if paused or gameState == "gameOver" or gameState == "help" then
    return
  end
  for _, layer in ipairs(layers) do
    for _, star in ipairs(layer.stars) do
      star.y = star.y + layer.speed * dt
      if star.y > love.graphics.getHeight() then
        star.y = 0
        star.x = math.random(Settings.WINDOW_WIDTH)
      end
    end
  end
end

function Parallax.draw()
  love.graphics.setBackgroundColor(backgroundColor)
  for _, layer in ipairs(layers) do
    for _, star in ipairs(layer.stars) do
      if star.color then
        love.graphics.setColor(star.color, star.color, star.color)
        -- Using rectangles for square pixels, with variable size
        love.graphics.rectangle("fill", star.x, star.y, layer.size, layer.size)
      end
    end
  end
  -- Reset color to white after drawing the parallax background
  love.graphics.setColor(1, 1, 1)
end

return Parallax
