local PlayerProgress = {}

local default_progress = {
  current_level = "0000",
  unlocked_levels = { "0000" },
  level_high_scores = {},
}

local progress = {}

function PlayerProgress.load()
  -- Initialize with default progress
  progress = default_progress
end

function PlayerProgress.save()
  end

function PlayerProgress.get_current_level()
  return progress.current_level
end

function PlayerProgress.set_current_level(level)
  progress.current_level = level
  PlayerProgress.save()
end

function PlayerProgress.is_level_unlocked(level)
  for _, unlocked_level in ipairs(progress.unlocked_levels) do
    if unlocked_level == level then
      return true
    end
  end
  return false
end

function PlayerProgress.unlock_level(level)
  if not PlayerProgress.is_level_unlocked(level) then
    table.insert(progress.unlocked_levels, level)
    PlayerProgress.save()
  end
end

function PlayerProgress.get_level_high_score(level_id)
  return progress.level_high_scores[level_id] or 0
end

function PlayerProgress.set_level_high_score(level_id, score)
  if score > (progress.level_high_scores[level_id] or 0) then
    progress.level_high_scores[level_id] = score
    PlayerProgress.save()
  end
end

PlayerProgress.load()

return PlayerProgress
