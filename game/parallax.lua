local Parallax = {}

local all_colors = require("colors")

local colors = {
  periwinkle_mist = all_colors.periwinkle_mist,
  skyline_azure = all_colors.skyline_azure,
  royal_sapphire = all_colors.royal_sapphire,
  midnight_harbor = all_colors.midnight_harbor,
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
local backgroundColor = all_colors.dark_blue
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
  -- Clear existing layers before creating new ones
  layers = {}
  for i = 1, num_layers do
    -- Random density for each layer
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
        x = math.random(love.graphics.getWidth()),
        y = math.random(love.graphics.getHeight()),
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
        star.x = math.random(love.graphics.getWidth())
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
