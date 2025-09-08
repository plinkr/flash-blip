local PlayerProgress = {}

-- Default player data
local default_progress = {
  current_level = "0000",
  unlocked_levels = { "0000" },
  level_high_scores = {},
}

-- In-memory player data
local progress = {}

-- Function to load player progress from memory
function PlayerProgress.load()
  -- Initialize with default progress
  progress = default_progress
end

-- Function to save player progress to memory
function PlayerProgress.save()
  -- This function is now a placeholder as progress is managed in memory.
  -- The 'progress' table is updated directly by other functions.
end

-- Function to get the player's current level
function PlayerProgress.get_current_level()
  return progress.current_level
end

-- Function to set the player's current level
function PlayerProgress.set_current_level(level)
  progress.current_level = level
  PlayerProgress.save()
end

-- Function to check if a level is unlocked
function PlayerProgress.is_level_unlocked(level)
  for _, unlocked_level in ipairs(progress.unlocked_levels) do
    if unlocked_level == level then
      return true
    end
  end
  return false
end

-- Function to unlock a new level
function PlayerProgress.unlock_level(level)
  if not PlayerProgress.is_level_unlocked(level) then
    table.insert(progress.unlocked_levels, level)
    PlayerProgress.save()
  end
end

-- Function to get the high score for a specific level
function PlayerProgress.get_level_high_score(level_id)
  return progress.level_high_scores[level_id] or 0
end

-- Function to set the high score for a specific level
function PlayerProgress.set_level_high_score(level_id, score)
  if score > (progress.level_high_scores[level_id] or 0) then
    progress.level_high_scores[level_id] = score
    PlayerProgress.save()
  end
end

-- Initialize by loading progress
PlayerProgress.load()

return PlayerProgress
