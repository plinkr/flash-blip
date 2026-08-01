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

  local win_value = data.winCondition.value
  if data.winCondition.type == "blips" then
    win_value = math.ceil(win_value * data.difficulty)
  end

  level.winCondition = {
    type = data.winCondition.type,
    value = win_value,
    finalBlipColor = data.winCondition.finalBlipColor,
  }
  level.seed = data.seed

  return level
end

function LevelData:load()
  love.math.setRandomSeed(self.seed)
end

return LevelData
