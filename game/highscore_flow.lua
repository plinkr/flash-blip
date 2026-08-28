local HighscoreManager = require("highscore_manager")
local VirtualKeyboard = require("virtual_keyboard")
local InputRecorder = require("input_recorder")
local GameState = require("gamestate")
local Settings = require("settings")

local HighscoreFlow = {
  pending_data = nil,
  waiting_action = nil,
  on_finish_callback = nil,
}

function HighscoreFlow.reset()
  HighscoreFlow.pending_data = nil
  HighscoreFlow.waiting_action = nil
  HighscoreFlow.on_finish_callback = nil
end

function HighscoreFlow.prepare(score_val, current_level_data)
  HighscoreFlow.reset()
  if HighscoreManager.is_score_above_min(score_val) then
    HighscoreFlow.pending_data = {
      score = score_val,
      seed = InputRecorder.get_seed(),
      ticks_count = InputRecorder.get_ticks(),
      replay_binary = InputRecorder.serialize_v2(),
      replay_version = InputRecorder.REPLAY_VERSION,
      level_data = current_level_data,
    }
    HighscoreManager.start_relevance_check(score_val)
  end
end

function HighscoreFlow.update(dt)
  if HighscoreManager.is_checking_relevance() then
    HighscoreManager.poll_relevance_check(function(is_relevant)
      if not is_relevant then
        HighscoreFlow.pending_data = nil
      end
      if HighscoreFlow.waiting_action and HighscoreFlow.on_finish_callback then
        local action = HighscoreFlow.waiting_action
        local callback = HighscoreFlow.on_finish_callback
        HighscoreFlow.waiting_action = nil
        HighscoreFlow.on_finish_callback = nil
        HighscoreFlow._execute_flow(action, callback)
      end
    end)
  end
end

function HighscoreFlow.request_proceed(action, on_finish_callback)
  if HighscoreManager.is_checking_relevance() then
    HighscoreFlow.waiting_action = action
    HighscoreFlow.on_finish_callback = on_finish_callback
  else
    HighscoreFlow._execute_flow(action, on_finish_callback)
  end
end

function HighscoreFlow.is_waiting()
  return HighscoreFlow.waiting_action ~= nil
end

function HighscoreFlow._execute_flow(action, on_finish_callback)
  local data = HighscoreFlow.pending_data
  HighscoreFlow.pending_data = nil

  if not data then
    on_finish_callback(action)
    return
  end

  local source_name = data.level_data and ("Level " .. data.level_data.id) or "Endless"
  GameState.set("virtual_keyboard")

  VirtualKeyboard.show(data.score, source_name, function(player_name)
    local difficulty = data.level_data and data.level_data.difficulty or 1.0
    HighscoreManager.submit(
      player_name,
      data.score,
      data.replay_binary,
      data.seed,
      data.ticks_count,
      difficulty,
      data.replay_version,
      function(success, message)
        if Settings.IS_DEBUG_ENABLED then
          print("Submit score result:", success, message)
        end
        if success then
          GameState.has_played_since_hi_scores = true
        end
        on_finish_callback(action)
      end
    )
  end, function()
    on_finish_callback(action)
  end)
end

return HighscoreFlow
