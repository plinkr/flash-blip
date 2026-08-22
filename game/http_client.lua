local Settings = require("settings")

local HttpClient = {}

local DEFAULT_TIMEOUT_SECONDS = 5
local POST_TIMEOUT_SECONDS = 15

local function is_success(code)
  return type(code) == "number" and code >= 200 and code < 300
end

local http, ltn12
if not Settings.IS_WEB then
  http = require("socket.http")
  ltn12 = require("ltn12")
  http.TIMEOUT = DEFAULT_TIMEOUT_SECONDS
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
        if key == "BACKEND_IP" or key == "BACKEND_IP_HTTPS" or key == "BACKEND_PORT" then
          config[key] = value
        end
      end
    end
  end
end

-- On web, itch.io forces HTTPS, so the browser requires the backend to use HTTPS too (Mixed Content policy)
-- In native builds, we use plain HTTP directly because LuaSocket doesn't support TLS without LuaSec
local base_url
if Settings.IS_WEB then
  base_url = "https://" .. config.BACKEND_IP_HTTPS
else
  base_url = "http://" .. config.BACKEND_IP .. ":" .. config.BACKEND_PORT
end

local web = {
  requests = {},
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

local function web_request(method, endpoint, body, headers, callback, timeout)
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
    deadline = love.timer.getTime() + (timeout or DEFAULT_TIMEOUT_SECONDS),
  }

  print("__LOVE_HTTP__" .. command)
end

local function web_poll()
  if not Settings.IS_WEB or next(web.requests) == nil then
    return
  end

  local now = love.timer.getTime()
  for _, req in pairs(web.requests) do
    if req.deadline and not req.abandoned and now >= req.deadline then
      req.abandoned = true
      req.callback(false, 0, "timeout")
    end
  end

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

    if not req.abandoned then
      if not content then
        req.callback(false, 0, "Failed to read bridge response file")
      else
        local newline_pos = content:find("\n")
        if newline_pos then
          local status = tonumber(content:sub(1, newline_pos - 1)) or 0
          local data = content:sub(newline_pos + 1)
          req.callback(is_success(status), status, data)
        else
          req.callback(false, 0, "Invalid bridge response format")
        end
      end
    end
  end
end

local NATIVE_GET_THREAD_CODE = [[
  local http = require("socket.http")
  local ltn12 = require("ltn12")
  local url, channel_name, timeout = ...
  http.TIMEOUT = timeout
  local resp_body = {}
  local ok, code = http.request({ url = url, method = "GET", sink = ltn12.sink.table(resp_body) })
  local channel = love.thread.getChannel(channel_name)
  channel:push({ ok = ok, code = code, data = table.concat(resp_body) })
]]

local NATIVE_POST_THREAD_CODE = [[
  local http = require("socket.http")
  local ltn12 = require("ltn12")
  local url, channel_name, timeout, body, headers = ...
  http.TIMEOUT = timeout
  headers["Content-Length"] = tostring(#body)
  local resp_body = {}
  local ok, code = http.request({
    url = url,
    method = "POST",
    headers = headers,
    source = ltn12.source.string(body),
    sink = ltn12.sink.table(resp_body),
  })
  local channel = love.thread.getChannel(channel_name)
  channel:push({ ok = ok, code = code, data = table.concat(resp_body) })
]]

---@diagnostic disable-next-line: unused-local
local active_threads = {} --luacheck: ignore active_threads
local pending_requests = {}
local next_channel_id = 0

function HttpClient.post(endpoint, body, headers, callback)
  if Settings.IS_WEB then
    web_request("POST", endpoint, body, headers, callback, POST_TIMEOUT_SECONDS)
    return
  end

  headers = headers or {}
  next_channel_id = next_channel_id + 1
  local channel_name = "http_post_" .. next_channel_id
  local thread = love.thread.newThread(NATIVE_POST_THREAD_CODE)
  ---@diagnostic disable-next-line: unused-local
  active_threads[thread] = true
  table.insert(pending_requests, { channel_name = channel_name, callback = callback, thread = thread })
  thread:start(base_url .. endpoint, channel_name, POST_TIMEOUT_SECONDS, body, headers)
end

function HttpClient.get(endpoint, callback, opts)
  opts = opts or {}

  if Settings.IS_WEB then
    web_request("GET", endpoint, nil, nil, callback, opts.timeout)
    return
  end

  next_channel_id = next_channel_id + 1
  local channel_name = "http_get_" .. next_channel_id
  local thread = love.thread.newThread(NATIVE_GET_THREAD_CODE)
  ---@diagnostic disable-next-line: unused-local
  active_threads[thread] = true
  table.insert(pending_requests, { channel_name = channel_name, callback = callback, thread = thread })
  thread:start(base_url .. endpoint, channel_name, opts.timeout or DEFAULT_TIMEOUT_SECONDS)
end

function HttpClient.get_via_channel(endpoint, channel_name)
  HttpClient.get(endpoint, function(ok, status, data)
    local channel = love.thread.getChannel(channel_name)
    if ok then
      channel:push({ success = true, data = data })
    else
      local reason = status == 0 and "offline" or tostring(status)
      channel:push({ success = false, error = "Connection failed: " .. reason })
    end
  end)
end

function HttpClient.sync_get(endpoint)
  if Settings.IS_WEB or not http then
    return false, ""
  end

  local resp_body = {}
  local ok, code = http.request({
    url = base_url .. endpoint,
    method = "GET",
    sink = ltn12.sink.table(resp_body),
  })
  return ok and is_success(code), table.concat(resp_body)
end

local function poll_thread_results(entries)
  for i = #entries, 1, -1 do
    local entry = entries[i]
    local msg = love.thread.getChannel(entry.channel_name):pop()
    if msg then
      ---@diagnostic disable-next-line: unused-local
      active_threads[entry.thread] = nil
      table.remove(entries, i)
      entry.callback(msg.ok and is_success(msg.code), msg.code or 0, msg.data)
    end
  end
end

function HttpClient.update()
  web_poll()
  poll_thread_results(pending_requests)
end

return HttpClient
