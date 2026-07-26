local http = require("socket.http")
local ltn12 = require("ltn12")
local hmac = require("lib.hmac")

local HighscoreManager = {}

HighscoreManager.MIN_RELEVANT_SCORE = 5000

local active_thread = nil
local relevance_thread = nil

local thread_code = [[
  local http = require("socket.http")
  local ltn12 = require("ltn12")
  local url = ...

  local resp_body = {}
  local ok, code = http.request({
    url = url,
    method = "GET",
    sink = ltn12.sink.table(resp_body),
  })

  local channel = love.thread.getChannel("highscore_download")
  if ok and code == 200 then
    channel:push({ success = true, data = table.concat(resp_body) })
  else
    channel:push({ success = false, error = "Connection failed: " .. tostring(code or "offline") })
  end
]]

local relevance_thread_code = [[
  local http = require("socket.http")
  local ltn12 = require("ltn12")
  local url = ...

  local resp_body = {}
  local ok, code = http.request({
    url = url,
    method = "GET",
    sink = ltn12.sink.table(resp_body),
  })

  local channel = love.thread.getChannel("relevance_check")
  if ok and (code == 200 or code == 201) then
    local raw_json = table.concat(resp_body)
    local relevant = raw_json:match('"relevant"%s*:%s*true') ~= nil
    channel:push({ success = true, relevant = relevant })
  else
    channel:push({ success = false, relevant = false })
  end
]]

local config = {
  BACKEND_IP = "127.0.0.1",
  BACKEND_PORT = "8080",
}

if love.filesystem.getInfo("product.env") then
  for line in love.filesystem.lines("product.env") do
    if not (line:match("^%s*#") or line:match("^%s*$")) then
      local key, value = line:match("([^=]+)=(.*)")
      if key then
        key = key:match("^%s*(.-)%s*$")
        value = value:match('^"?(.-)"?$')
        value = value:match("^%s*(.-)%s*$")
        if key == "BACKEND_IP" or key == "BACKEND_PORT" then
          config[key] = value
        end
      end
    end
  end
end

local base_url = "http://" .. config.BACKEND_IP .. ":" .. config.BACKEND_PORT

local function http_post(url, body, headers)
  local resp_body = {}
  headers["Content-Length"] = tostring(#body)
  local ok, code = http.request({
    url = url,
    method = "POST",
    headers = headers,
    source = ltn12.source.string(body),
    sink = ltn12.sink.table(resp_body),
  })
  return ok, code, table.concat(resp_body)
end

local function prepare_submission(player_name, score, rng_seed, total_ticks, difficulty)
  local payload = string.format(
    '{"p":%q,"s":%d,"rng_seed":%d,"total_ticks":%d,"difficulty":%.2f}',
    player_name,
    math.floor(score),
    math.floor(rng_seed),
    math.floor(total_ticks),
    difficulty
  )
  local headers = { ["Content-Type"] = "application/json" }
  local ok, code, raw = http_post(base_url .. "/scores/prepare", payload, headers)
  if not ok or (code ~= 200 and code ~= 201) then
    return nil, nil, "prepare failed: " .. tostring(code)
  end
  local token = raw:match('"token"%s*:%s*"([^"]+)"')
  local nonce = raw:match('"nonce"%s*:%s*"([^"]+)"')
  if not token or not nonce then
    return nil, nil, "invalid prepare response"
  end
  return token, nonce, nil
end

local function submit_with_token(token, nonce, replay_binary)
  local compressed = love.data.compress("data", "zlib", replay_binary, 9)
  local encoded = love.data.encode("string", "base64", compressed)
  local signature = hmac.sha256(encoded, nonce)
  local headers = {
    ["Content-Type"] = "application/octet-stream",
    ["X-Submit-Token"] = token,
    ["X-Signature"] = signature,
  }
  local ok, code, _ = http_post(base_url .. "/scores/submit", encoded, headers)
  return ok and (code == 200 or code == 201), code
end

function HighscoreManager.submit(player_name, score, replay_binary, rng_seed, total_ticks, difficulty, callback)
  if type(difficulty) == "function" then
    callback = difficulty
    difficulty = 1.0
  end
  difficulty = difficulty or 1.0

  local token, nonce, error_message = prepare_submission(player_name, score, rng_seed, total_ticks, difficulty)
  if not token then
    if callback then
      callback(false, "Prepare step failed: " .. error_message)
    end
    return
  end

  local ok, code = submit_with_token(token, nonce, replay_binary)
  if callback then
    if ok then
      callback(true, "Score uploaded successfully")
    else
      callback(false, "Submit step failed: " .. tostring(code))
    end
  end
end

function HighscoreManager.start_download()
  if active_thread then
    return
  end

  local url = base_url .. "/scores"
  local channel = love.thread.getChannel("highscore_download")
  channel:clear()

  active_thread = love.thread.newThread(thread_code)
  active_thread:start(url)
end

function HighscoreManager.poll_download(callback)
  if not active_thread then
    return false
  end

  local channel = love.thread.getChannel("highscore_download")
  local msg = channel:pop()
  if msg then
    active_thread = nil
    if msg.success then
      local raw_json = msg.data
      local scores = {}

      -- naive regex-based json parser
      for entry in raw_json:gmatch("{([^}]+)}") do
        local id = entry:match('"id"%s*:%s*(%d+)')
        local player = entry:match('"player"%s*:%s*"([^"]+)"')
        local score = entry:match('"score"%s*:%s*(%d+)')
        local total_ticks = entry:match('"total_ticks"%s*:%s*(%d+)')
        local duration = entry:match('"duration_seconds"%s*:%s*([%d%.]+)')
        local achieved_at = entry:match('"achieved_at"%s*:%s*"([^"]+)"')
        local replay_id = entry:match('"replay_id"%s*:%s*(%d+)')

        if player and score then
          table.insert(scores, {
            id = tonumber(id),
            player = player,
            score = tonumber(score),
            total_ticks = tonumber(total_ticks),
            duration_seconds = tonumber(duration),
            achieved_at = achieved_at,
            replay_id = tonumber(replay_id),
          })
        end
      end

      table.sort(scores, function(entry_a, entry_b)
        return entry_a.score > entry_b.score
      end)

      if callback then
        callback(true, scores)
      end
    else
      if callback then
        callback(false, msg.error)
      end
    end
    return true
  end

  return false
end

function HighscoreManager.is_downloading()
  return active_thread ~= nil
end

function HighscoreManager.start_relevance_check(score)
  relevance_thread = nil
  local channel = love.thread.getChannel("relevance_check")
  channel:clear()

  if score <= HighscoreManager.MIN_RELEVANT_SCORE then
    channel:push({ success = true, relevant = false })
    return
  end

  local url = base_url .. "/scores/check?score=" .. tostring(math.floor(score))
  relevance_thread = love.thread.newThread(relevance_thread_code)
  relevance_thread:start(url)
end

function HighscoreManager.poll_relevance_check(callback)
  if not relevance_thread then
    return false
  end

  local channel = love.thread.getChannel("relevance_check")
  local msg = channel:pop()
  if msg then
    relevance_thread = nil
    if callback then
      callback(msg.success and msg.relevant)
    end
    return true
  end

  return false
end

function HighscoreManager.is_checking_relevance()
  return relevance_thread ~= nil
end

function HighscoreManager.is_score_relevant(score)
  if score <= HighscoreManager.MIN_RELEVANT_SCORE then
    return false
  end

  local url = base_url .. "/scores/check?score=" .. tostring(math.floor(score))
  local resp_body = {}

  local ok, code = http.request({
    url = url,
    method = "GET",
    sink = ltn12.sink.table(resp_body),
  })

  if ok and (code == 200 or code == 201) then
    local raw_json = table.concat(resp_body)
    local relevant = raw_json:match('"relevant"%s*:%s*true') ~= nil
    return relevant
  end

  return false
end

return HighscoreManager
