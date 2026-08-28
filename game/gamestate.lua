local GameState = {}

GameState.current = "attract"
GameState.previous = nil
GameState.is_attract_mode = true
GameState.is_paused = false
GameState.ignore_input_timer = 0
GameState.game_over_input_delay = 0
GameState.level_completed_input_delay = 0
GameState.restart_delay_counter = 0
GameState.is_new_hi_score = false
GameState.hi_score_flash_timer = 0
GameState.hi_score_flash_visible = true
GameState.all_levels_completed = false
GameState.has_played_since_hi_scores = false
GameState.hi_scores_dirty = false

function GameState.set(state)
  GameState.previous = GameState.current
  GameState.current = state
  if state == "playing" then
    GameState.has_played_since_hi_scores = true
  end
  if state == "hi_scores" then
    GameState.hi_scores_dirty = true
  end
end

function GameState.update(dt)
  if GameState.ignore_input_timer > 0 then
    GameState.ignore_input_timer = GameState.ignore_input_timer - dt
    if GameState.ignore_input_timer < 0 then
      GameState.ignore_input_timer = 0
    end
  end

  if GameState.current == "gameOver" then
    if GameState.game_over_input_delay > 0 then
      GameState.game_over_input_delay = GameState.game_over_input_delay - dt
    end
  elseif GameState.current == "levelCompleted" then
    if GameState.level_completed_input_delay > 0 then
      GameState.level_completed_input_delay = GameState.level_completed_input_delay - dt
    end
  end

  if GameState.restart_delay_counter > 0 then
    GameState.restart_delay_counter = GameState.restart_delay_counter - 1
  end

  if GameState.is_new_hi_score then
    GameState.hi_score_flash_timer = GameState.hi_score_flash_timer + dt
    if GameState.hi_score_flash_timer > 0.8 then
      GameState.hi_score_flash_visible = not GameState.hi_score_flash_visible
      GameState.hi_score_flash_timer = 0
    end
  end
end

function GameState.is(state)
  return GameState.current == state
end

function GameState.is_not(state)
  return GameState.current ~= state
end

return GameState
