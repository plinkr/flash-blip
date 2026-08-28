local Colors = require("colors")
local Settings = require("settings")

local definitions = {}

-- Background colors cycle
local bg_colors = {
  Colors.dark_blue,
  Colors.almost_black,
  Colors.almost_dark_blue,
  Colors.dark_reddish_black,
  Colors.dark_bluish_black,
  Colors.deep_midnight_blue,
  Colors.subtle_violet,
  Colors.faint_crimson,
  Colors.shadow_green,
  Colors.inky_blue,
}

-- Star colors cycle
local star_color_sets = {
  { Colors.periwinkle_mist, Colors.skyline_azure, Colors.royal_sapphire, Colors.midnight_harbor },
  { Colors.magenta, Colors.cyan, Colors.apricot_glow, Colors.royal_sapphire },
  { Colors.periwinkle_mist, Colors.skyline_azure, Colors.midnight_harbor, Colors.apricot_glow },
  { Colors.magenta, Colors.cyan, Colors.royal_sapphire, Colors.midnight_harbor },
  { Colors.periwinkle_mist, Colors.apricot_glow, Colors.skyline_azure, Colors.royal_sapphire },
  { Colors.magenta, Colors.cyan, Colors.midnight_harbor, Colors.apricot_glow },
  { Colors.periwinkle_mist, Colors.skyline_azure, Colors.royal_sapphire, Colors.apricot_glow },
}

for level_index = 1, Settings.MAX_LEVELS do
  local level_key = string.format("%02d", level_index)
  local jumps = 4 + level_index -- 5 to 104
  local difficulty = 1.0 + (level_index - 1) * (3.5 - 1.0) / (Settings.MAX_LEVELS - 1)
  local bg_color_index = ((level_index - 1) % #bg_colors) + 1
  local star_color_index = ((level_index - 1) % #star_color_sets) + 1
  local seed = level_index * 100

  definitions[level_key] = {
    background_color = bg_colors[bg_color_index],
    star_colors = star_color_sets[star_color_index],
    difficulty = math.floor(difficulty * 100 + 0.5) / 100,
    win_condition = { type = "blips", value = jumps, final_blip_color = Colors.antique_gold },
    seed = seed,
  }
end

return definitions
