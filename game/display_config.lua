local DisplayConfig = {}

local CONFIG_FILE = "display_config.txt"

function DisplayConfig.save(config)
  love.filesystem.write(
    CONFIG_FILE,
    table.concat({
      config.pixel_width,
      config.pixel_height,
      config.desktop_width,
      config.desktop_height,
      config.dpi_scale,
      config.internal_height,
      config.scale_factor,
    }, "\n")
  )
end

function DisplayConfig.load()
  if not love.filesystem.getInfo(CONFIG_FILE) then
    return nil
  end

  local content = love.filesystem.read(CONFIG_FILE)
  if not content then
    return nil
  end

  local values = {}
  for line in content:gmatch("[^\n]+") do
    table.insert(values, tonumber(line))
  end

  if #values ~= 7 then
    return nil
  end

  return {
    pixel_width = values[1],
    pixel_height = values[2],
    desktop_width = values[3],
    desktop_height = values[4],
    dpi_scale = values[5],
    internal_height = values[6],
    scale_factor = values[7],
  }
end

function DisplayConfig.clear()
  love.filesystem.remove(CONFIG_FILE)
end

return DisplayConfig
