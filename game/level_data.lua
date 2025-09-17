local LevelDefinitions = require("level_definitions")

local LevelData = {}
LevelData.__index = LevelData

function LevelData.new(level_id)
  local data = LevelDefinitions[level_id]
  if not data then
    error("Level data not found for level_id: " .. tostring(level_id))
  end

  local level = setmetatable({}, LevelData)

  level.id = level_id
  level.backgroundColor = data.backgroundColor
  level.starColors = data.starColors
  level.difficulty = data.difficulty
  level.winCondition = data.winCondition
  level.seed = data.seed

  return level
end

function LevelData:load()
  love.math.setRandomSeed(self.seed)
end

return LevelData
