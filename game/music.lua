local Music = {}
local Settings = require("settings")

local function bytebeat1(t)
  local y = t % 16384
  local drum = 0
  if y ~= 0 then
    local div = 3000 / y
    drum = (math.floor(div) % 2) * 35
  end
  local idx = math.floor(t / 65536) % 4
  local mults = "6689"
  local mult = tonumber(mults:sub(idx + 1, idx + 1))
  local temp = t * mult / 24
  local x = math.floor(temp) % 128
  local bass = x * y / 40000
  local t8 = math.floor(t / 256)
  local t10 = math.floor(t / 1024)
  local t14 = math.floor(t / 16384)
  local t8_low = t8 % 64
  local t10_low = t10 % 64
  local t14_low = t14 % 64
  local x_low = x % 64
  local xor_low = 0
  local pow = 1
  local a = t8_low
  local b = t10_low
  for _ = 1, 6 do
    local ba = a % 2
    local bb = b % 2
    if ba ~= bb then
      xor_low = xor_low + pow
    end
    a = math.floor(a / 2)
    b = math.floor(b / 2)
    pow = pow * 2
  end
  local bor1 = 0
  a = xor_low
  b = t14_low
  pow = 1
  for _ = 1, 6 do
    local ba = a % 2
    local bb = b % 2
    if ba == 1 or bb == 1 then
      bor1 = bor1 + pow
    end
    a = math.floor(a / 2)
    b = math.floor(b / 2)
    pow = pow * 2
  end
  local lead = 0
  a = bor1
  b = x_low
  pow = 1
  for _ = 1, 6 do
    local ba = a % 2
    local bb = b % 2
    if ba == 1 or bb == 1 then
      lead = lead + pow
    end
    a = math.floor(a / 2)
    b = math.floor(b / 2)
    pow = pow * 2
  end
  return drum + bass + lead
end

local function SS(s, o, r, p, t)
  local idx = (math.floor(t / (2 ^ r)) % p) + 1
  local c = s:byte(idx) or 32
  if c == 32 then
    return 0
  end
  return (t % 32) * math.pow(2, c / 12 - o)
end

local function bytebeat2(t)
  local part1 = SS("0 0     7 7     037:<<", 6, 10, 32, t)
  local part2 = 0
  if math.floor(t / 4096) % 2 == 1 then
    local env = (4096 - (t % 4096)) / 4096
    part2 = SS("037", 4, 8, 3, t) * env
  end
  return part1 + part2
end

local function combined_bytebeat(t)
  return bytebeat1(t) + bytebeat2(t)
end

local function generate_buffer_samples(buffer, start_tt, num_samples, step, amplitude, cycle_length)
  local local_tt = start_tt
  for i = 0, num_samples - 1 do
    local s = combined_bytebeat(local_tt)
    local sample = ((s / 128) - 1) * amplitude
    buffer:setSample(i, sample)
    local_tt = local_tt + step
    if local_tt >= cycle_length then
      local_tt = local_tt - cycle_length
    end
  end
  return local_tt
end

local function create_audio_source(sound_data, is_muted)
  local source = love.audio.newSource(sound_data, "static")
  source:setLooping(true)
  source:setVolume(is_muted and 0 or 1.0)
  source:play()
  return source
end

local source
local queue_source
local isGenerating = false
local isMuted = not Settings.IS_MUSIC_ENABLED
local tt = 0
local cycle_length = 1572864
local full_rate = 32000
local web_rate = 8000
local amplitude = 0.2
local buffer_size = 512
local web_buffer_count = 256
local web_step = full_rate / web_rate

local generation_thread
local sound_data_channel = love.thread.getChannel("sound_data")
local is_generating_sound_data = false
local isReady = false

function Music.stop()
  if source then
    source:stop()
    source = nil
  end
  if queue_source then
    queue_source:stop()
    queue_source = nil
  end
  isGenerating = false
  is_generating_sound_data = false
  isReady = false
  if generation_thread then
    generation_thread:wait()
    generation_thread = nil
  end
end

function Music.toggle_mute(mute)
  isMuted = mute
  if source then
    source:setVolume(isMuted and 0 or 1)
  end
  if queue_source then
    queue_source:setVolume(isMuted and 0 or 1)
  end
end

local generate_sound_data_code = [[
  require("love.sound")

  local rate = 32000
  local step = 1
  local total_samples = 1572864
  local bits = 16
  local channels = 1
  local amplitude = 0.2
  local cycle_length = 1572864

  local function xor_bits(a, b, bits)
    local result = 0
    local pow = 1
    for _ = 1, bits do
      local ba = a % 2
      local bb = b % 2
      if ba ~= bb then
        result = result + pow
      end
      a = math.floor(a / 2)
      b = math.floor(b / 2)
      pow = pow * 2
    end
    return result
  end

  local function or_bits(a, b, bits)
    local result = 0
    local pow = 1
    for _ = 1, bits do
      local ba = a % 2
      local bb = b % 2
      if ba == 1 or bb == 1 then
        result = result + pow
      end
      a = math.floor(a / 2)
      b = math.floor(b / 2)
      pow = pow * 2
    end
    return result
  end

  local function bytebeat1(t)
    local y = t % 16384
    local drum = 0
    if y ~= 0 then
      local div = 3000 / y
      drum = (math.floor(div) % 2) * 35
    end
    local idx = math.floor(t / 65536) % 4
    local mults = "6689"
    local mult = tonumber(mults:sub(idx + 1, idx + 1))
    local temp = t * mult / 24
    local x = math.floor(temp) % 128
    local bass = x * y / 40000
    local t8 = math.floor(t / 256)
    local t10 = math.floor(t / 1024)
    local t14 = math.floor(t / 16384)
    local t8_low = t8 % 64
    local t10_low = t10 % 64
    local t14_low = t14 % 64
    local x_low = x % 64
    local xor_low = xor_bits(t8_low, t10_low, 6)
    local bor1 = or_bits(xor_low, t14_low, 6)
    local lead = or_bits(bor1, x_low, 6)
    return drum + bass + lead
  end

  local function SS(s, o, r, p, t)
    local idx = (math.floor(t / (2 ^ r)) % p) + 1
    local c = s:byte(idx) or 32
    if c == 32 then
      return 0
    end
    return (t % 32) * math.pow(2, c / 12 - o)
  end

  local function bytebeat2(t)
    local part1 = SS("0 0     7 7     037:<<", 6, 10, 32, t)
    local part2 = 0
    if math.floor(t / 4096) % 2 == 1 then
      local env = (4096 - (t % 4096)) / 4096
      part2 = SS("037", 4, 8, 3, t) * env
    end
    return part1 + part2
  end

  local function combined_bytebeat(t)
    return bytebeat1(t) + bytebeat2(t)
  end

  local sound_data = love.sound.newSoundData(total_samples, rate, bits, channels)

  local local_tt = 0
  for i = 0, total_samples - 1 do
    local s = combined_bytebeat(local_tt)
    local_tt = local_tt + step
    if local_tt >= cycle_length then
      local_tt = local_tt - cycle_length
    end
    local sample = ((s / 128) - 1) * amplitude
    sound_data:setSample(i, sample)
  end

  love.thread.getChannel("sound_data"):push(sound_data)
]]

function Music.play()
  if source then
    source:stop()
    source = nil
  end
  if queue_source then
    queue_source:stop()
    queue_source = nil
  end
  isGenerating = false
  isReady = false
  tt = 0

  local isWeb = Settings.IS_WEB

  if not isWeb then
    if not is_generating_sound_data then
      generation_thread = love.thread.newThread(generate_sound_data_code)
      generation_thread:start()
      is_generating_sound_data = true
    end
  else
    queue_source = love.audio.newQueueableSource(web_rate, 16, 1, web_buffer_count)
    queue_source:setVolume(isMuted and 0 or 1.0)

    while queue_source:getFreeBufferCount() > 0 do
      local buffer = love.sound.newSoundData(buffer_size, web_rate, 16, 1)
      tt = generate_buffer_samples(buffer, tt, buffer_size, web_step, amplitude, cycle_length)
      queue_source:queue(buffer)
    end

    queue_source:play()
    isGenerating = true
    isReady = true
  end
end

function Music.update(dt)
  if not isGenerating or not queue_source then
    if not Settings.IS_WEB and is_generating_sound_data and generation_thread then
      if generation_thread:isRunning() then
        return
      else
        local sound_data = sound_data_channel:pop()
        if sound_data then
          source = create_audio_source(sound_data, isMuted)
          is_generating_sound_data = false
          isReady = true
          generation_thread:wait()
          generation_thread = nil
        end
        return
      end
    end
    return
  end

  while queue_source:getFreeBufferCount() > 0 do
    local buffer = love.sound.newSoundData(buffer_size, web_rate, 16, 1)
    tt = generate_buffer_samples(buffer, tt, buffer_size, web_step, amplitude, cycle_length)
    queue_source:queue(buffer)
  end
end

function Music.isReady()
  return isReady
end

return Music
