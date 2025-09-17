local PlayerProgress = {}

local default_progress = {
  current_level = "0000",
  unlocked_levels = { ["0000"] = true },
  level_high_scores = {},
  endless_high_score = 0,
}

local progress = {}

function PlayerProgress.load()
  local content, _, error = love.filesystem.read("player_progress.txt")
  if content then
    progress = {
      current_level = nil,
      unlocked_levels = nil,
      level_high_scores = nil,
      endless_high_score = nil,
    }
    for line in content:gmatch("[^\n]+") do
      local key, value = line:match("([^=]+)=(.*)")
      if key and value then
        key = key:match("^%s*(.-)%s*$")
        value = value:match("^%s*(.-)%s*$")
        if key == "current_level" then
          progress.current_level = value
        elseif key == "unlocked_levels" then
          progress.unlocked_levels = {}
          for lvl in value:gmatch("[^,]+") do
            lvl = lvl:match("^%s*(.-)%s*$")
            progress.unlocked_levels[lvl] = true
          end
        elseif key == "level_high_scores" then
          progress.level_high_scores = {}
          for pair_str in value:gmatch("[^,]+") do
            local lvl, score_str = pair_str:match("([^:]+):([^:]+)")
            if lvl and score_str then
              lvl = lvl:match("^%s*(.-)%s*$")
              score_str = score_str:match("^%s*(.-)%s*$")
              progress.level_high_scores[lvl] = tonumber(score_str) or 0
            end
          end
        elseif key == "endless_high_score" then
          progress.endless_high_score = tonumber(value) or 0
        end
      end
    end
    if not progress.current_level then
      progress.current_level = default_progress.current_level
    end
    if not progress.unlocked_levels then
      progress.unlocked_levels = { ["0000"] = true }
    end
    if not progress.level_high_scores then
      progress.level_high_scores = {}
    end
    if not progress.endless_high_score then
      progress.endless_high_score = 0
    end
  else
    progress = {
      current_level = default_progress.current_level,
      unlocked_levels = { ["0000"] = true },
      level_high_scores = default_progress.level_high_scores,
      endless_high_score = 0,
    }
    if error and not (error:match("No such file") or error:match("does not exist")) then
      print("Failed to load progress: " .. error)
    end
  end
end

function PlayerProgress.save()
  local data = "current_level=" .. progress.current_level .. "\n"
  local ul_levels = {}
  for lvl in pairs(progress.unlocked_levels) do
    table.insert(ul_levels, lvl)
  end
  table.sort(ul_levels, function(a, b)
    return tonumber(a) < tonumber(b)
  end)
  local ul_str = table.concat(ul_levels, ",")
  data = data .. "unlocked_levels=" .. ul_str .. "\n"
  local hs_str = ""
  for lvl, score in pairs(progress.level_high_scores) do
    if #hs_str > 0 then
      hs_str = hs_str .. ","
    end
    local truncated_score = math.floor(score)
    hs_str = hs_str .. lvl .. ":" .. tostring(truncated_score)
  end
  data = data .. "level_high_scores=" .. hs_str .. "\n"
  data = data .. "endless_high_score=" .. tostring(math.floor(progress.endless_high_score or 0)) .. "\n"

  local success, message = love.filesystem.write("player_progress.txt", data)
  if not success then
    print("Failed to save progress: " .. (message or "Unknown error"))
  end
end

function PlayerProgress.get_current_level()
  return progress.current_level
end

function PlayerProgress.set_current_level(level)
  progress.current_level = level
  PlayerProgress.save()
end

function PlayerProgress.is_level_unlocked(level)
  return progress.unlocked_levels[level] ~= nil
end

function PlayerProgress.unlock_level(level)
  if not PlayerProgress.is_level_unlocked(level) then
    progress.unlocked_levels[level] = true
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

function PlayerProgress.get_endless_high_score()
  return progress.endless_high_score or 0
end

function PlayerProgress.set_endless_high_score(score)
  if score > (progress.endless_high_score or 0) then
    progress.endless_high_score = score
    PlayerProgress.save()
  end
end

PlayerProgress.load()

return PlayerProgress
