local Sound = {}
local Settings = require("settings")

local sounds = {}
local is_muted = not Settings.IS_SFX_ENABLED

-- Enable to adjust SE volume
function Sound.set_volume(volume)
  volume = math.max(0, math.min(1, tonumber(volume) or 1.0))
  if volume < 0.005 then
    volume = 0
  end
  Settings.IS_SFX_VOLUME = volume

  local final_volume = is_muted and 0 or volume

  for _, sound in pairs(sounds) do
    sound:setVolume(final_volume)
  end
end

function Sound.toggle_mute(mute)
  is_muted = mute

  local final_volume = is_muted and 0 or Settings.IS_SFX_VOLUME

  for _, sound in pairs(sounds) do
    sound:setVolume(final_volume)
  end
end

-- Generates a sound wave procedurally.
function Sound.generate_sound(name)
  local sound_params = {
    blip = { start_freq = 800, end_freq = 1600, duration = 0.07, volume = 0.4 },
    explosion = { start_freq = 200, end_freq = 50, duration = 0.2, volume = 0.6 },
    star_powerup = { start_freq = 1000, end_freq = 2000, duration = 0.15, volume = 0.4 },
    slowdown_powerup = { start_freq = 2000, end_freq = 1000, duration = 0.15, volume = 0.4 },
    phaseshift_powerup = { start_freq = 500, end_freq = 2500, duration = 0.2, volume = 0.4 },
    teleport = { start_freq = 1500, end_freq = 800, duration = 0.1, volume = 0.4 },
    bolt_powerup = { start_freq = 2500, end_freq = 500, duration = 0.2, volume = 0.4 },
    debuff_emp = { start_freq = 300, end_freq = 100, duration = 0.25, volume = 0.4 },
  }

  local params = sound_params[name]
  if not params then
    return
  end

  local sample_rate = 44100
  local bit_depth = 16
  local channels = 1
  local sample_count = math.floor(sample_rate * params.duration)
  local sound_data = love.sound.newSoundData(sample_count, sample_rate, bit_depth, channels)

  for i = 0, sample_count - 1 do
    local time = i / sample_rate
    local freq
    if name == "blip" then
      freq = params.start_freq + (params.end_freq - params.start_freq) * (time / params.duration)
    else
      freq = params.start_freq * ((params.end_freq / params.start_freq) ^ (time / params.duration))
    end
    local value = math.sin(2 * math.pi * freq * time) > 0 and params.volume or -params.volume
    ---@diagnostic disable-next-line: undefined-field
    sound_data:setSample(i, value)
  end

  sounds[name] = love.audio.newSource(sound_data)
end

function Sound.play(name)
  local sound = sounds[name]
  if sound then
    sound:stop()
    sound:setVolume(is_muted and 0 or Settings.IS_SFX_VOLUME)
    sound:play()
  end
end

function Sound:load()
  self.generate_sound("explosion")
  self.generate_sound("blip")
  self.generate_sound("star_powerup")
  self.generate_sound("slowdown_powerup")
  self.generate_sound("phaseshift_powerup")
  self.generate_sound("teleport")
  self.generate_sound("bolt_powerup")
  self.generate_sound("debuff_emp")
end

return Sound
