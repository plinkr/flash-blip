-- game/font.lua
--[[
Módulo para renderizar una fuente pixelada personalizada.
]]
local Font = {}

-- Definición de la fuente. Cada caracter es 6x8 píxeles.
-- El espacio ' ' representa un pixel apagado, cualquier otro caracter es un pixel encendido.
-- Esto es una decisión conciente, no quiero usar assets externos como fuentes o sprites,
-- es un ejercicio interesante dibujar el texto de manera manual.
Font.glyphs = {
  ["A"] = {
    "      ",
    " 1111 ",
    "11   1",
    "11   1",
    "111111",
    "11   1",
    "11   1",
    "11   1",
  },
  ["B"] = {
    "      ",
    "11111 ",
    "11   1",
    "11   1",
    "11111 ",
    "11   1",
    "11   1",
    "11111 ",
  },
  ["C"] = {
    "      ",
    " 11111",
    "11    ",
    "11    ",
    "11    ",
    "11    ",
    "11    ",
    " 11111",
  },
  ["D"] = {
    "      ",
    "11111 ",
    "11   1",
    "11   1",
    "11   1",
    "11   1",
    "11   1",
    "11111 ",
  },
  ["E"] = {
    "      ",
    "111111",
    "11    ",
    "11    ",
    "1111  ",
    "11    ",
    "11    ",
    "111111",
  },
  ["F"] = {
    "      ",
    "111111",
    "11    ",
    "11    ",
    "11111 ",
    "11    ",
    "11    ",
    "11    ",
  },
  ["G"] = {
    "      ",
    " 11111",
    "11    ",
    "11    ",
    "11 111",
    "11   1",
    "11   1",
    "  1111",
  },
  ["H"] = {
    "      ",
    "11   1",
    "11   1",
    "11   1",
    "111111",
    "11   1",
    "11   1",
    "11   1",
  },
  ["I"] = {
    "      ",
    "111111",
    "  11  ",
    "  11  ",
    "  11  ",
    "  11  ",
    "  11  ",
    "111111",
  },
  ["J"] = {
    "      ",
    " 11111",
    "    11",
    "    11",
    "    11",
    "11   1",
    "11   1",
    " 1111 ",
  },
  ["K"] = {
    "      ",
    "11   1",
    "11  1 ",
    "11 1  ",
    "111   ",
    "11 1  ",
    "11  1 ",
    "11   1",
  },
  ["L"] = {
    "      ",
    "11    ",
    "11    ",
    "11    ",
    "11    ",
    "11    ",
    "11    ",
    "111111",
  },
  ["M"] = {
    "      ",
    "11   1",
    "111 11",
    "11 1 1",
    "11   1",
    "11   1",
    "11   1",
    "11   1",
  },
  ["N"] = {
    "      ",
    "11   1",
    "111  1",
    "111  1",
    "11 1 1",
    "11 1 1",
    "11  11",
    "11  11",
  },
  ["O"] = {
    "      ",
    " 1111 ",
    "11   1",
    "11   1",
    "11   1",
    "11   1",
    "11   1",
    " 1111 ",
  },
  ["P"] = {
    "      ",
    "11111 ",
    "11   1",
    "11   1",
    "11   1",
    "11111 ",
    "11    ",
    "11    ",
  },
  ["Q"] = {
    "      ",
    " 1111 ",
    "11   1",
    "11   1",
    "11   1",
    "11 1 1",
    "11  1 ",
    " 111 1",
  },
  ["R"] = {
    "      ",
    "11111 ",
    "11   1",
    "11   1",
    "11   1",
    "11111 ",
    "11   1",
    "11   1",
  },
  ["S"] = {
    "      ",
    " 11111",
    "11    ",
    "11    ",
    " 1111 ",
    "    11",
    "    11",
    "11111 ",
  },
  ["T"] = {
    "      ",
    "111111",
    "  11  ",
    "  11  ",
    "  11  ",
    "  11  ",
    "  11  ",
    "  11  ",
  },
  ["U"] = {
    "      ",
    "11   1",
    "11   1",
    "11   1",
    "11   1",
    "11   1",
    "11   1",
    " 1111 ",
  },
  ["V"] = {
    "      ",
    "11   1",
    "11   1",
    "11   1",
    "11   1",
    "11   1",
    " 11 1 ",
    "  11  ",
  },
  ["W"] = {
    "      ",
    "11   1",
    "11   1",
    "11   1",
    "11   1",
    "11 1 1",
    "11 1 1",
    " 11 1 ",
  },
  ["X"] = {
    "      ",
    "11   1",
    "11   1",
    " 11 1 ",
    "  11  ",
    " 11 1 ",
    "11   1",
    "11   1",
  },
  ["Y"] = {
    "      ",
    "11   1",
    "11   1",
    "11   1",
    " 11 1 ",
    "  11  ",
    "  11  ",
    "  11  ",
  },
  ["Z"] = {
    "      ",
    "111111",
    "    11",
    "   11 ",
    "  11  ",
    " 11   ",
    "11    ",
    "111111",
  },

  ["0"] = {
    "      ",
    "11111 ",
    "11  1 ",
    "11  1 ",
    "11  1 ",
    "11  1 ",
    "11  1 ",
    "11111 ",
  },
  ["1"] = {
    "      ",
    " 11   ",
    "111   ",
    " 11   ",
    " 11   ",
    " 11   ",
    " 11   ",
    " 11   ",
  },
  ["2"] = {
    "      ",
    "11111 ",
    "   11 ",
    "   11 ",
    "11111 ",
    "11    ",
    "11    ",
    "11111 ",
  },
  ["3"] = {
    "      ",
    "11111 ",
    "   11 ",
    "   11 ",
    " 1111 ",
    "   11 ",
    "   11 ",
    "11111 ",
  },
  ["4"] = {
    "      ",
    "11  1 ",
    "11  1 ",
    "11  1 ",
    "11111 ",
    "   11 ",
    "   11 ",
    "   11 ",
  },
  ["5"] = {
    "      ",
    "11111 ",
    "11    ",
    "11    ",
    "11111 ",
    "   11 ",
    "   11 ",
    "11111 ",
  },
  ["6"] = {
    "      ",
    "11111 ",
    "11    ",
    "11    ",
    "11111 ",
    "11  1 ",
    "11  1 ",
    "11111 ",
  },
  ["7"] = {
    "      ",
    "11111 ",
    "   11 ",
    "   11 ",
    "   11 ",
    "   11 ",
    "   11 ",
    "   11 ",
  },
  ["8"] = {
    "      ",
    "11111 ",
    "11  1 ",
    "11  1 ",
    "11111 ",
    "11  1 ",
    "11  1 ",
    "11111 ",
  },
  ["9"] = {
    "      ",
    "11111 ",
    "1  11 ",
    "1  11 ",
    "11111 ",
    "   11 ",
    "   11 ",
    "11111 ",
  },
  ["."] = {
    "  ",
    "  ",
    "  ",
    "  ",
    "  ",
    "  ",
    "11",
    "11",
  },
  [":"] = {
    "  ",
    "  ",
    "11",
    "11",
    "  ",
    "  ",
    "11",
    "11",
  },
  ["!"] = {
    "11",
    "11",
    "11",
    "11",
    "11",
    "11",
    "  ",
    "11",
  },
  ["+"] = {
    "      ",
    "      ",
    "  11  ",
    "  11  ",
    "111111",
    "111111",
    "  11  ",
    "  11  ",
  },
  ["-"] = {
    "      ",
    "      ",
    "      ",
    "      ",
    "111111",
    "111111",
    "      ",
    "      ",
  },
  ["/"] = {
    "   11",
    "   11",
    "  11 ",
    "  11 ",
    " 11  ",
    " 11  ",
    "11   ",
    "11   ",
  },
  [" "] = { " ", " ", " ", " ", " ", " ", " ", " " },
}

Font.charWidth = 6
Font.charHeight = 8
Font.tracking = 1 -- Espacio horizontal entre caracteres
Font.spaceWidth = 2 -- Ancho personalizado para el espacio
Font.glyphWidths = {} -- Almacenará los anchos reales

function Font:init()
  for char, glyph in pairs(self.glyphs) do
    if char == " " then
      self.glyphWidths[char] = self.spaceWidth
    else
      local maxWidth = 0
      for _, rowStr in ipairs(glyph) do
        for col = #rowStr, 1, -1 do
          if rowStr:sub(col, col) ~= " " then
            maxWidth = math.max(maxWidth, col)
            break
          end
        end
      end
      self.glyphWidths[char] = maxWidth
    end
  end
end

function Font:drawText(text, x, y, scale)
  scale = scale or 1
  local currentX = x

  for i = 1, #text do
    local char = string.upper(text:sub(i, i))
    local glyph = self.glyphs[char]

    if glyph then
      for row = 1, #glyph do
        for col = 1, #glyph[row] do
          if glyph[row]:sub(col, col) ~= " " then
            love.graphics.rectangle("fill", currentX + (col - 1) * scale, y + (row - 1) * scale, scale, scale)
          end
        end
      end

      local width = self.glyphWidths[char] or self.spaceWidth
      currentX = currentX + (width + self.tracking) * scale
    else
      -- Caracter no encontrado, avanzar como un espacio
      currentX = currentX + (self.spaceWidth + self.tracking) * scale
    end
  end
end

function Font:getTextWidth(text, scale)
  scale = scale or 1
  local totalWidth = 0
  for i = 1, #text do
    local char = string.upper(text:sub(i, i))
    local width = self.glyphWidths[char] or self.spaceWidth
    totalWidth = totalWidth + (width + self.tracking) * scale
  end
  return totalWidth
end

function Font:getTextHeight(scale)
  scale = scale or 1
  return self.charHeight * scale
end

return Font
