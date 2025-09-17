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

local music = {}

local source
local queue_source
local isGenerating = false
local tt = 0
local cycle_length = 1572864
local full_rate = 32000
local web_rate = 8000
local amplitude = 0.2
local buffer_size = 512
local web_buffer_count = 256
local web_step = full_rate / web_rate

function music.play()
  if source then
    source:stop()
    source = nil
  end
  if queue_source then
    queue_source:stop()
    queue_source = nil
  end
  isGenerating = false
  tt = 0

  local isWeb = love.system.getOS() == "Web"

  if not isWeb then
    local rate = full_rate
    local step = 1
    local total_samples = cycle_length
    local bits = 16
    local channels = 1
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

    source = love.audio.newSource(sound_data, "static")
    source:setLooping(true)
    source:setVolume(1.0)
    source:play()
  else
    queue_source = love.audio.newQueueableSource(web_rate, 16, 1, web_buffer_count)
    queue_source:setVolume(1.0)

    while queue_source:getFreeBufferCount() > 0 do
      local buffer = love.sound.newSoundData(buffer_size, web_rate, 16, 1)
      local local_tt = tt

      for i = 0, buffer_size - 1 do
        local s = combined_bytebeat(local_tt)
        buffer:setSample(i, ((s / 128) - 1) * amplitude)
        local_tt = local_tt + web_step
      end

      tt = local_tt
      if tt >= cycle_length then
        tt = tt - cycle_length
      end

      queue_source:queue(buffer)
    end

    queue_source:play()
    isGenerating = true
  end
end

function music.update(dt)
  if not isGenerating or not queue_source then
    return
  end

  while queue_source:getFreeBufferCount() > 0 do
    local buffer = love.sound.newSoundData(buffer_size, web_rate, 16, 1)
    local local_tt = tt

    for i = 0, buffer_size - 1 do
      local s = combined_bytebeat(local_tt)
      buffer:setSample(i, ((s / 128) - 1) * amplitude)
      local_tt = local_tt + web_step
    end

    tt = local_tt
    if tt >= cycle_length then
      tt = tt - cycle_length
    end

    queue_source:queue(buffer)
  end
end

return music
