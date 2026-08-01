local is_mobile = love and love.system and (love.system.getOS() == "Android" or love.system.getOS() == "iOS") or false
local is_web = love and love.system and (love.system.getOS() == "Web") or false

local is_debug_env = os.getenv("LOCAL_LUA_DEBUGGER_VSCODE") == "1"
if not is_debug_env and arg then
  for _, v in ipairs(arg) do
    if v == "--debug" or v == "debug" then
      is_debug_env = true
      break
    end
  end
end

local has_ffi, ffi = pcall(require, "ffi")
local is_arm_linux = love
    and love.system
    and love.system.getOS() == "Linux"
    and has_ffi
    and (ffi.arch == "arm" or ffi.arch == "arm64")
  or false

local Settings = {
  CONFIG_FILE = "settings_config.txt",
  INTERNAL_WIDTH = 120,
  INTERNAL_HEIGHT = 160,
  -- Enables debug statistics (the on-screen info can be toggled with F3)
  IS_DEBUG_ENABLED = is_debug_env,
  -- The scale factor and window size will be calculated dynamically in main.lua
  SCALE_FACTOR = 1,
  -- Platform detection
  IS_MOBILE = is_mobile,
  IS_ARM_LINUX = is_arm_linux,
  OPENGL_VERSION = love and love.graphics and select(2, love.graphics.getRendererInfo()) or "OpenGL",
  IS_WEB = is_web,
  SUPPORTS_GLSL3 = love and love.graphics and love.graphics.getSupported and love.graphics.getSupported().glsl3
    or false,
  ASPECT_RATIO = nil,
  WINDOW_WIDTH = 120,
  WINDOW_HEIGHT = 160,
  -- DPI scale for mobile devices
  DPI_SCALE = 1,
  -- Maximum number of levels for Arcade Mode
  MAX_LEVELS = 100,
}

-- Options
local SCHEMA = {
  IS_MUSIC_ENABLED = { type = "boolean", default = true },
  IS_SFX_ENABLED = { type = "boolean", default = true },
  IS_GLOW_ENABLED = { type = "boolean", default = not is_mobile and not is_web },
  HAS_PASSED_GLOW_TEST = { type = "boolean", default = false },
  IS_BLUR_ENABLED = { type = "boolean", default = not is_mobile and not is_web },
  IS_MUSIC_VOLUME = { type = "number", default = 1.0, min = 0.0, max = 1.0 },
  IS_SFX_VOLUME = { type = "number", default = 1.0, min = 0.0, max = 1.0 },
}

-- Initialize default values from schema
for key, spec in pairs(SCHEMA) do
  Settings[key] = spec.default
end

local save_pending = false
local save_timer = 0

function Settings.save_debounced()
  save_pending = true
  save_timer = 0.5
end

function Settings.update(dt)
  if save_pending then
    save_timer = save_timer - dt
    if save_timer <= 0 then
      Settings.save()
    end
  end
end

function Settings.save()
  save_pending = false
  local lines = {}
  for key, spec in pairs(SCHEMA) do
    local val = Settings[key]
    if spec.type == "number" then
      val = string.format("%.2f", math.max(spec.min, math.min(spec.max, val or spec.default)))
    else
      val = tostring(val)
    end
    table.insert(lines, key .. "=" .. val)
  end
  local content = table.concat(lines, "\n") .. "\n"

  if love and love.filesystem and love.filesystem.write then
    local ok, err = love.filesystem.write(Settings.CONFIG_FILE, content)
    if not ok then
      print("[Settings] Error writing config: " .. tostring(err))
    end
  end
end

function Settings.load()
  if not (love and love.filesystem and love.filesystem.getInfo and love.filesystem.read) then
    return false
  end

  if not love.filesystem.getInfo(Settings.CONFIG_FILE) then
    return false
  end

  local content = love.filesystem.read(Settings.CONFIG_FILE)
  if not content then
    return false
  end

  local loaded_has_passed_glow_test = false
  for line in content:gmatch("[^\r\n]+") do
    local k, v = line:match("^%s*([^=]+)%s*=%s*(.-)%s*$")
    local spec = SCHEMA[k]
    if spec then
      if k == "HAS_PASSED_GLOW_TEST" then
        loaded_has_passed_glow_test = true
      end
      if spec.type == "boolean" then
        Settings[k] = (v == "true")
      elseif spec.type == "number" then
        local num = tonumber(v) or tonumber(spec.default) or 0
        Settings[k] = math.max(spec.min, math.min(spec.max, num))
      end
    end
  end

  if not loaded_has_passed_glow_test and Settings.IS_GLOW_ENABLED then
    Settings.HAS_PASSED_GLOW_TEST = true
  end

  return true
end

return Settings
