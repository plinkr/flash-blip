local hmac = require("lib.hmac")
local Settings = require("settings")

local HighscoreManager = {}

HighscoreManager.MIN_RELEVANT_SCORE = 5000

local http, ltn12
if not Settings.IS_WEB then
  http = require("socket.http")
  ltn12 = require("ltn12")
end

local config = { BACKEND_IP = "127.0.0.1", BACKEND_PORT = "8080" }

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

local function build_score_payload(player_name, score, rng_seed, total_ticks, difficulty)
  return string.format(
    '{"p":%q,"s":%d,"rng_seed":%d,"total_ticks":%d,"difficulty":%.2f}',
    player_name,
    math.floor(score),
    math.floor(rng_seed),
    math.floor(total_ticks),
    difficulty
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

local web = {
  requests = {}, -- id -> { callback, req_file, resp_file }
  next_id = 0,
  bridge_ready = false,
}

local function web_ensure_bridge_ready()
  if web.bridge_ready then
    return
  end
  love.filesystem.write("bridge_init.dat", "1")
  web.bridge_ready = true
end

local function web_request(method, endpoint, body, headers, callback)
  web_ensure_bridge_ready()

  web.next_id = web.next_id + 1
  local id = tostring(web.next_id)
  local req_file = "web_req_" .. id .. ".dat"
  local resp_file = "web_resp_" .. id .. ".dat"
  local has_body = body ~= nil

  if has_body then
    love.filesystem.write(req_file, body)
  end

  local req_path = has_body and (love.filesystem.getSaveDirectory() .. "/" .. req_file) or ""
  local resp_path = love.filesystem.getSaveDirectory() .. "/" .. resp_file
  local url = base_url .. endpoint

  local command = table.concat({ id, method, url, req_path, resp_path }, "|")
  if headers then
    for key, value in pairs(headers) do
      command = command .. "|" .. key .. ":" .. value
    end
  end

  web.requests[id] = {
    callback = callback,
    req_file = has_body and req_file or nil,
    resp_file = resp_file,
  }

  print("__LOVE_HTTP__" .. command)
end

local function web_poll()
  local finished_ids = {}
  for id, req in pairs(web.requests) do
    if love.filesystem.getInfo(req.resp_file) then
      table.insert(finished_ids, id)
    end
  end

  for _, id in ipairs(finished_ids) do
    local req = web.requests[id]
    web.requests[id] = nil

    local content = love.filesystem.read(req.resp_file)
    love.filesystem.remove(req.resp_file)
    if req.req_file then
      love.filesystem.remove(req.req_file)
    end

    local newline_pos = content:find("\n")
    if newline_pos then
      local status = tonumber(content:sub(1, newline_pos - 1)) or 0
      local data = content:sub(newline_pos + 1)
      req.callback(status >= 200 and status < 300, status, data)
    else
      req.callback(false, 0, "Invalid bridge response format")
    end
  end
end

local NATIVE_GET_THREAD_CODE = [[
  local http = require("socket.http")
  local ltn12 = require("ltn12")
  local url, channel_name = ...
  local resp_body = {}
  local ok, code = http.request({ url = url, method = "GET", sink = ltn12.sink.table(resp_body) })
  local channel = love.thread.getChannel(channel_name)
  if ok and (code == 200 or code == 201) then
    channel:push({ success = true, data = table.concat(resp_body) })
  else
    channel:push({ success = false, error = "Connection failed: " .. tostring(code or "offline") })
  end
]]

local function native_post(endpoint, body, headers, callback)
  headers = headers or {}
  headers["Content-Length"] = tostring(#body)
  local resp_body = {}
  local ok, code = http.request({
    url = base_url .. endpoint,
    method = "POST",
    headers = headers,
    source = ltn12.source.string(body),
    sink = ltn12.sink.table(resp_body),
  })
  callback(ok and (code == 200 or code == 201), code, table.concat(resp_body))
end

local function post(endpoint, body, headers, callback)
  if Settings.IS_WEB then
    web_request("POST", endpoint, body, headers, callback)
  else
    native_post(endpoint, body, headers, callback)
  end
end

local function start_get(endpoint, channel_name)
  if Settings.IS_WEB then
    web_request("GET", endpoint, nil, nil, function(ok, status, data)
      local channel = love.thread.getChannel(channel_name)
      if ok then
        channel:push({ success = true, data = data })
      else
        channel:push({ success = false, error = tostring(status) })
      end
    end)
    return
  end

  local thread = love.thread.newThread(NATIVE_GET_THREAD_CODE)
  thread:start(base_url .. endpoint, channel_name)
end

local active_download = false
local checking_relevance = false

function HighscoreManager.submit(player_name, score, replay_binary, rng_seed, total_ticks, difficulty, callback)
  if type(difficulty) == "function" then
    callback = difficulty
    difficulty = 1.0
  end
  difficulty = difficulty or 1.0

  local payload = build_score_payload(player_name, score, rng_seed, total_ticks, difficulty)

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

  if score <= HighscoreManager.MIN_RELEVANT_SCORE then
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

function HighscoreManager.is_checking_relevance()
  return checking_relevance
end

function HighscoreManager.is_score_relevant(score)
  if Settings.IS_WEB then
    print("HighscoreManager: is_score_relevant() is synchronous and does not run on web; use start_relevance_check().")
    return false
  end

  if score <= HighscoreManager.MIN_RELEVANT_SCORE then
    return false
  end

  local resp_body = {}
  local ok, code = http.request({
    url = base_url .. "/scores/check?score=" .. tostring(math.floor(score)),
    method = "GET",
    sink = ltn12.sink.table(resp_body),
  })
  if ok and (code == 200 or code == 201) then
    return table.concat(resp_body):match('"relevant"%s*:%s*true') ~= nil
  end
  return false
end

if Settings.IS_WEB then
  function HighscoreManager.update()
    web_poll()
  end
end

return HighscoreManager
