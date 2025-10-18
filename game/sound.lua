local Sound = {}

local sounds = {}
local isMuted = false

function Sound.toggleMute()
  isMuted = not isMuted
  for _, sound in pairs(sounds) do
    sound:setVolume(isMuted and 0 or 1)
  end
end

-- Generates a sound wave procedurally.
function Sound.generateSound(name)
  local soundParams = {
    blip = { startFreq = 800, endFreq = 1600, duration = 0.07, volume = 0.4 },
    explosion = { startFreq = 200, endFreq = 50, duration = 0.2, volume = 0.6 },
    star_powerup = { startFreq = 1000, endFreq = 2000, duration = 0.15, volume = 0.4 },
    slowdown_powerup = { startFreq = 2000, endFreq = 1000, duration = 0.15, volume = 0.4 },
    phaseshift_powerup = { startFreq = 500, endFreq = 2500, duration = 0.2, volume = 0.4 },
    teleport = { startFreq = 1500, endFreq = 800, duration = 0.1, volume = 0.4 },
    bolt_powerup = { startFreq = 2500, endFreq = 500, duration = 0.2, volume = 0.4 },
  }

  local params = soundParams[name]
  if not params then
    return
  end

  local sampleRate = 44100
  local bitDepth = 16
  local channels = 1
  local sampleCount = math.floor(sampleRate * params.duration)
  local soundData = love.sound.newSoundData(sampleCount, sampleRate, bitDepth, channels)

  for i = 0, sampleCount - 1 do
    local time = i / sampleRate
    local freq
    if name == "blip" then
      freq = params.startFreq + (params.endFreq - params.startFreq) * (time / params.duration)
    else
      freq = params.startFreq * ((params.endFreq / params.startFreq) ^ (time / params.duration))
    end
    local value = math.sin(2 * math.pi * freq * time) > 0 and params.volume or -params.volume
    ---@diagnostic disable-next-line: undefined-field
    soundData:setSample(i, value)
  end

  sounds[name] = love.audio.newSource(soundData)
end

function Sound.play(name)
  local sound = sounds[name]
  if sound then
    sound:stop()
    if isMuted then
      sound:setVolume(0)
    end
    sound:play()
  end
end

function Sound:load()
  self.generateSound("explosion")
  self.generateSound("blip")
  self.generateSound("star_powerup")
  self.generateSound("slowdown_powerup")
  self.generateSound("phaseshift_powerup")
  self.generateSound("teleport")
  self.generateSound("bolt_powerup")
end

return Sound
