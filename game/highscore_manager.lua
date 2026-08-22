local hmac = require("lib.hmac")
local Settings = require("settings")
local HttpClient = require("http_client")

local HighscoreManager = {}

HighscoreManager.MIN_RELEVANT_SCORE = 5000

local function build_score_payload(player_name, score, rng_seed, total_ticks, difficulty, replay_version)
  return string.format(
    '{"p":%q,"s":%d,"rng_seed":%d,"total_ticks":%d,"difficulty":%.2f,"replay_version":%d}',
    player_name,
    math.floor(score),
    math.floor(rng_seed),
    math.floor(total_ticks),
    difficulty,
    replay_version or 1
  )
end

local function sign_replay(replay_binary, nonce)
  local compressed = love.data.compress("data", "lz4", replay_binary, 8)
  local encoded = love.data.encode("string", "base64", compressed)
  local signature = hmac.sha256(encoded, nonce)
  return encoded, signature
end

local function parse_prepare_response(raw)
  local token = raw:match('"token"%s*:%s*"([^"]+)"')
  local nonce = raw:match('"nonce"%s*:%s*"([^"]+)"')
  return token, nonce
end

local function parse_scores(raw_json)
  local scores = {}
  for entry in raw_json:gmatch("{([^}]+)}") do
    local id = entry:match('"id"%s*:%s*(%d+)')
    local player = entry:match('"player"%s*:%s*"([^"]+)"')
    local score = entry:match('"score"%s*:%s*(%d+)')
    if player and score then
      table.insert(scores, { id = tonumber(id), player = player, score = tonumber(score) })
    end
  end
  table.sort(scores, function(a, b)
    return a.score > b.score
  end)
  return scores
end

local post = HttpClient.post
local start_get = HttpClient.get_via_channel

local active_download = false
local checking_relevance = false

function HighscoreManager.submit(
  player_name,
  score,
  replay_binary,
  rng_seed,
  total_ticks,
  difficulty,
  replay_version,
  callback
)
  if type(replay_version) == "function" then
    callback = replay_version
    replay_version = 1
  end
  if type(difficulty) == "function" then
    callback = difficulty
    difficulty = 1.0
  end
  difficulty = difficulty or 1.0

  local payload = build_score_payload(player_name, score, rng_seed, total_ticks, difficulty, replay_version)

  post("/scores/prepare", payload, { ["Content-Type"] = "application/json" }, function(ok, status, raw)
    if not ok then
      if callback then
        callback(false, "Prepare failed: " .. tostring(status))
      end
      return
    end

    local token, nonce = parse_prepare_response(raw)
    if not token or not nonce then
      if callback then
        callback(false, "Prepare failed: invalid response format")
      end
      return
    end

    local encoded, signature = sign_replay(replay_binary, nonce)
    local submit_headers = {
      ["Content-Type"] = "application/octet-stream",
      ["X-Submit-Token"] = token,
      ["X-Signature"] = signature,
    }

    post("/scores/submit", encoded, submit_headers, function(sub_ok, sub_status)
      if not callback then
        return
      end
      if sub_ok then
        callback(true, "Score uploaded")
      else
        callback(false, "Submit failed: " .. tostring(sub_status))
      end
    end)
  end)
end

function HighscoreManager.start_download()
  if active_download then
    return
  end
  active_download = true
  love.thread.getChannel("highscore_download"):clear()
  start_get("/scores", "highscore_download")
end

function HighscoreManager.poll_download(callback)
  if not active_download then
    return false
  end
  local msg = love.thread.getChannel("highscore_download"):pop()
  if not msg then
    return false
  end

  active_download = false

  if msg.success then
    if callback then
      callback(true, parse_scores(msg.data))
    end
  else
    if callback then
      callback(false, msg.error)
    end
  end
  return true
end

function HighscoreManager.is_downloading()
  return active_download
end

function HighscoreManager.start_relevance_check(score)
  if checking_relevance then
    return
  end
  checking_relevance = true

  local channel = love.thread.getChannel("relevance_check")
  channel:clear()

  if score < HighscoreManager.MIN_RELEVANT_SCORE then
    channel:push({ success = true, relevant = false })
    return
  end

  start_get("/scores/check?score=" .. tostring(math.floor(score)), "relevance_check")
end

function HighscoreManager.poll_relevance_check(callback)
  if not checking_relevance then
    return false
  end
  local msg = love.thread.getChannel("relevance_check"):pop()
  if not msg then
    return false
  end

  checking_relevance = false

  local relevant = false
  if msg.success then
    if msg.relevant ~= nil then
      relevant = msg.relevant
    else
      relevant = (msg.data or ""):match('"relevant"%s*:%s*true') ~= nil
    end
  end

  if callback then
    callback(relevant)
  end
  return true
end

function HighscoreManager.is_score_above_min(score)
  return score >= HighscoreManager.MIN_RELEVANT_SCORE
end

function HighscoreManager.is_checking_relevance()
  return checking_relevance
end

function HighscoreManager.is_score_relevant(score)
  if Settings.IS_WEB then
    print("HighscoreManager: is_score_relevant() is synchronous and does not run on web; use start_relevance_check().")
    return false
  end

  if score < HighscoreManager.MIN_RELEVANT_SCORE then
    return false
  end

  local ok, body = HttpClient.sync_get("/scores/check?score=" .. tostring(math.floor(score)))
  return ok and body:match('"relevant"%s*:%s*true') ~= nil
end

return HighscoreManager
