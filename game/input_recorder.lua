local InputRecorder = {}

local events = {}
local is_running = false
local ticks = 0
local seed = 0

InputRecorder.REPLAY_VERSION = 2

InputRecorder.INPUT = {
  NONE = 0,
  BLIP = 1,
  PING = 2,
  MULTIPLIER_STARTED = 3,
  MULTIPLIER_ENDED = 4,
}

function InputRecorder.start(initial_seed)
  events = {}
  is_running = true
  ticks = 0
  if initial_seed then
    seed = initial_seed
  else
    seed = love.math.random(0, 2147483647)
  end
  love.math.setRandomSeed(seed)
end

function InputRecorder.stop()
  is_running = false
end

function InputRecorder.tick()
  if is_running then
    ticks = ticks + 1
  end
end

local function add_event(event_tick, input_id)
  local event = { tick = event_tick, id = input_id }
  local insert_at = #events + 1
  while insert_at > 1 and events[insert_at - 1].tick > event_tick do
    insert_at = insert_at - 1
  end
  table.insert(events, insert_at, event)
end

function InputRecorder.record(input_id)
  if not is_running or input_id == InputRecorder.INPUT.NONE then
    return
  end
  add_event(ticks, input_id)
end

function InputRecorder.record_next_tick(input_id)
  if not is_running or input_id == InputRecorder.INPUT.NONE then
    return
  end
  add_event(ticks + 1, input_id)
end

local function serialize_event(event)
  local event_tick = event.tick
  local tick_byte_1 = event_tick % 256
  local tick_byte_2 = math.floor(event_tick / 256) % 256
  local tick_byte_3 = math.floor(event_tick / 65536) % 256
  local tick_byte_4 = math.floor(event_tick / 16777216) % 256
  return string.char(tick_byte_1, tick_byte_2, tick_byte_3, tick_byte_4, event.id)
end

function InputRecorder.serialize()
  local parts = {}
  for _, event in ipairs(events) do
    table.insert(parts, serialize_event(event))
  end
  return table.concat(parts)
end

function InputRecorder.serialize_v2()
  local parts = { "FBRP", string.char(InputRecorder.REPLAY_VERSION, 1, 0, 0) }
  for _, event in ipairs(events) do
    table.insert(parts, serialize_event(event))
  end
  return table.concat(parts)
end

function InputRecorder.get_seed()
  return seed
end

function InputRecorder.get_ticks()
  return ticks
end

function InputRecorder.get_count()
  return #events
end

function InputRecorder.is_active()
  return is_running
end

return InputRecorder
