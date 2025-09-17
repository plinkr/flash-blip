-- gamestate.lua

local GameState = {}

GameState.current = "attract"
GameState.previous = nil
GameState.attractMode = true
GameState.isPaused = false
GameState.ignoreInputTimer = 0
GameState.gameOverInputDelay = 0
GameState.levelCompletedInputDelay = 0
GameState.restartDelayCounter = 0
GameState.nuHiScore = false
GameState.hiScoreFlashTimer = 0
GameState.hiScoreFlashVisible = true
GameState.allLevelsCompleted = false

function GameState.set(state)
  GameState.previous = GameState.current
  GameState.current = state
end

function GameState.update(dt)
  if GameState.ignoreInputTimer > 0 then
    GameState.ignoreInputTimer = GameState.ignoreInputTimer - dt
    if GameState.ignoreInputTimer < 0 then
      GameState.ignoreInputTimer = 0
    end
  end

  if GameState.current == "gameOver" then
    if GameState.gameOverInputDelay > 0 then
      GameState.gameOverInputDelay = GameState.gameOverInputDelay - dt
    end
  elseif GameState.current == "levelCompleted" then
    if GameState.levelCompletedInputDelay > 0 then
      GameState.levelCompletedInputDelay = GameState.levelCompletedInputDelay - dt
    end
  end

  if GameState.restartDelayCounter > 0 then
    GameState.restartDelayCounter = GameState.restartDelayCounter - 1
  end

  if GameState.nuHiScore then
    GameState.hiScoreFlashTimer = GameState.hiScoreFlashTimer + dt
    if GameState.hiScoreFlashTimer > 0.8 then
      GameState.hiScoreFlashVisible = not GameState.hiScoreFlashVisible
      GameState.hiScoreFlashTimer = 0
    end
  end
end

function GameState.is(state)
  return GameState.current == state
end

function GameState.isNot(state)
  return GameState.current ~= state
end

return GameState
