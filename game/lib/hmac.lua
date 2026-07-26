-- lib/hmac.lua
-- HMAC-SHA256 en Lua puro

local hmac = {}

-- XOR byte a byte compatible con todas las versiones de Lua
local function xor_byte(a, b)
  -- Lua 5.3+ tiene el operador ~ nativo
  -- LuaJIT y Lua 5.1 no lo tienen, usamos tabla de verdad
  local result = 0
  local bit_val = 1
  for _ = 1, 8 do
    local a_bit = a % 2
    local b_bit = b % 2
    if a_bit ~= b_bit then
      result = result + bit_val
    end
    a = math.floor(a / 2)
    b = math.floor(b / 2)
    bit_val = bit_val * 2
  end
  return result
end

-- Detecta si podemos usar operadores nativos más rápidos
local _xor
if _VERSION == "Lua 5.3" or _VERSION == "Lua 5.4" then
  -- Operador nativo de Lua 5.3+
  _xor = load("return function(a,b) return a ~ b end")()
elseif pcall(require, "bit") then
  -- LuaBitOp disponible (LuaJIT desktop/android normal)
  local bit = require("bit")
  _xor = bit.bxor
else
  -- Fallback puro: web/love.js
  _xor = xor_byte
end

function hmac.sha256(msg, key)
  local block_size = 64

  -- Si la clave es más larga que el bloque, la hashea primero
  if #key > block_size then
    key = love.data.hash("sha256", key)
  end
  -- Padding a block_size bytes
  if #key < block_size then
    key = key .. string.rep("\0", block_size - #key)
  end

  -- Construye ipad y opad
  local ipad = {}
  local opad = {}
  for i = 1, block_size do
    local k = key:byte(i)
    ipad[i] = string.char(_xor(k, 0x36))
    opad[i] = string.char(_xor(k, 0x5c))
  end
  local ipad_str = table.concat(ipad)
  local opad_str = table.concat(opad)

  -- HMAC = SHA256(opad || SHA256(ipad || msg))
  local inner = love.data.hash("sha256", ipad_str .. msg)
  local outer = love.data.hash("sha256", opad_str .. inner)

  -- Convierte a hex
  local hex = {}
  for i = 1, #outer do
    hex[i] = string.format("%02x", outer:byte(i))
  end
  return table.concat(hex)
end

return hmac
