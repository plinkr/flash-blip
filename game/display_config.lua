local DisplayConfig = {}

local CONFIG_FILE = "display_config.txt"

function DisplayConfig.save(config)
  love.filesystem.write(
    CONFIG_FILE,
    table.concat({
      config.pixelWidth,
      config.pixelHeight,
      config.desktopWidth,
      config.desktopHeight,
      config.dpiScale,
      config.internalHeight,
      config.scaleFactor,
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
    pixelWidth = values[1],
    pixelHeight = values[2],
    desktopWidth = values[3],
    desktopHeight = values[4],
    dpiScale = values[5],
    internalHeight = values[6],
    scaleFactor = values[7],
  }
end

function DisplayConfig.clear()
  love.filesystem.remove(CONFIG_FILE)
end

return DisplayConfig
