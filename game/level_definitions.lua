local colors = require("colors")

local definitions = {
  ["0000"] = {
    backgroundColor = colors.almost_black,
    starColors = { colors.magenta, colors.cyan, colors.apricot_glow, colors.royal_sapphire },
    difficulty = 1,
    winCondition = { type = "blips", value = 10, finalBlipColor = colors.antique_gold },
    seed = 1,
  },
  ["0001"] = {
    backgroundColor = colors.dark_blue,
    starColors = { colors.periwinkle_mist, colors.skyline_azure, colors.royal_sapphire, colors.midnight_harbor },
    difficulty = 1.2,
    winCondition = { type = "blips", value = 20, finalBlipColor = colors.antique_gold },
    seed = 11,
  },
  ["0010"] = {
    backgroundColor = colors.almost_dark_blue,
    starColors = { colors.magenta, colors.cyan, colors.apricot_glow, colors.midnight_harbor },
    difficulty = 1.4,
    winCondition = { type = "blips", value = 30, finalBlipColor = colors.antique_gold },
    seed = 111,
  },
  ["0011"] = {
    backgroundColor = colors.dark_reddish_black,
    starColors = { colors.magenta, colors.cyan, colors.apricot_glow, colors.royal_sapphire },
    difficulty = 1.6,
    winCondition = { type = "blips", value = 40, finalBlipColor = colors.antique_gold },
    seed = 1111,
  },
  ["0100"] = {
    backgroundColor = colors.dark_bluish_black,
    starColors = { colors.magenta, colors.cyan, colors.apricot_glow, colors.midnight_harbor },
    difficulty = 1.8,
    winCondition = { type = "blips", value = 50, finalBlipColor = colors.antique_gold },
    seed = 11111,
  },
  ["0101"] = {
    backgroundColor = colors.deep_midnight_blue,
    starColors = { colors.periwinkle_mist, colors.skyline_azure, colors.royal_sapphire, colors.midnight_harbor },
    difficulty = 2.2,
    winCondition = { type = "blips", value = 60, finalBlipColor = colors.antique_gold },
    seed = 111111,
  },
  ["0110"] = {
    backgroundColor = colors.subtle_violet,
    starColors = { colors.magenta, colors.cyan, colors.apricot_glow, colors.royal_sapphire },
    difficulty = 2.4,
    winCondition = { type = "blips", value = 70, finalBlipColor = colors.antique_gold },
    seed = 1111111,
  },
  ["0111"] = {
    backgroundColor = colors.faint_crimson,
    starColors = { colors.magenta, colors.cyan, colors.apricot_glow, colors.midnight_harbor },
    difficulty = 2.6,
    winCondition = { type = "blips", value = 80, finalBlipColor = colors.antique_gold },
    seed = 11111111,
  },
  ["1000"] = {
    backgroundColor = colors.shadow_green,
    starColors = { colors.periwinkle_mist, colors.skyline_azure, colors.royal_sapphire, colors.midnight_harbor },
    difficulty = 2.8,
    winCondition = { type = "blips", value = 90, finalBlipColor = colors.antique_gold },
    seed = 111111111,
  },
  ["1001"] = {
    backgroundColor = colors.inky_blue,
    starColors = { colors.magenta, colors.cyan, colors.apricot_glow, colors.royal_sapphire },
    difficulty = 3.0,
    winCondition = { type = "blips", value = 100, finalBlipColor = colors.antique_gold },
    seed = 1337,
  },
}

return definitions
