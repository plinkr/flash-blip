local Parallax = {}

-- local colors = {
--   apricot_glow = { 1, 0.631, 0.392 },
--   tangerine_blaze = { 1, 0.529, 0.224 },
--   spiced_amber = { 0.776, 0.306, 0 },
--   rusty_cedar = { 0.608, 0.239, 0 },
-- }
local colors = {
  periwinkle_mist = { 33.3 / 100, 49.8 / 100, 74.5 / 100 },
  skyline_azure = { 20 / 100, 39.6 / 100, 68.2 / 100 },
  royal_sapphire = { 4.3 / 100, 23.1 / 100, 51 / 100 },
  midnight_harbor = { 2.7 / 100, 17.6 / 100, 40 / 100 },
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

function Parallax.load()
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
    for j = 1, stars_in_layer do
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
  if gameState == "gameOver" then
    return
  end
  for i, layer in ipairs(layers) do
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
  for i, layer in ipairs(layers) do
    for _, star in ipairs(layer.stars) do
      love.graphics.setColor(star.color[1], star.color[2], star.color[3])
      -- Using rectangles for square pixels, with variable size
      love.graphics.rectangle("fill", star.x, star.y, layer.size, layer.size)
    end
  end
  -- Reset color to white after drawing the parallax background
  love.graphics.setColor(1, 1, 1)
end

return Parallax
