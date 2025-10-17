local Colors = require("colors")

local definitions = {
  ["0000"] = {
    backgroundColor = Colors.almost_black,
    starColors = { Colors.magenta, Colors.cyan, Colors.apricot_glow, Colors.royal_sapphire },
    difficulty = 1,
    winCondition = { type = "blips", value = 10, finalBlipColor = Colors.antique_gold },
    seed = 1,
  },
  ["0001"] = {
    backgroundColor = Colors.dark_blue,
    starColors = { Colors.periwinkle_mist, Colors.skyline_azure, Colors.royal_sapphire, Colors.midnight_harbor },
    difficulty = 1.2,
    winCondition = { type = "blips", value = 20, finalBlipColor = Colors.antique_gold },
    seed = 11,
  },
  ["0010"] = {
    backgroundColor = Colors.almost_dark_blue,
    starColors = { Colors.magenta, Colors.cyan, Colors.apricot_glow, Colors.midnight_harbor },
    difficulty = 1.4,
    winCondition = { type = "blips", value = 30, finalBlipColor = Colors.antique_gold },
    seed = 111,
  },
  ["0011"] = {
    backgroundColor = Colors.dark_reddish_black,
    starColors = { Colors.magenta, Colors.cyan, Colors.apricot_glow, Colors.royal_sapphire },
    difficulty = 1.6,
    winCondition = { type = "blips", value = 40, finalBlipColor = Colors.antique_gold },
    seed = 1111,
  },
  ["0100"] = {
    backgroundColor = Colors.dark_bluish_black,
    starColors = { Colors.magenta, Colors.cyan, Colors.apricot_glow, Colors.midnight_harbor },
    difficulty = 1.8,
    winCondition = { type = "blips", value = 50, finalBlipColor = Colors.antique_gold },
    seed = 11111,
  },
  ["0101"] = {
    backgroundColor = Colors.deep_midnight_blue,
    starColors = { Colors.periwinkle_mist, Colors.skyline_azure, Colors.royal_sapphire, Colors.midnight_harbor },
    difficulty = 2.2,
    winCondition = { type = "blips", value = 60, finalBlipColor = Colors.antique_gold },
    seed = 111111,
  },
  ["0110"] = {
    backgroundColor = Colors.subtle_violet,
    starColors = { Colors.magenta, Colors.cyan, Colors.apricot_glow, Colors.royal_sapphire },
    difficulty = 2.4,
    winCondition = { type = "blips", value = 70, finalBlipColor = Colors.antique_gold },
    seed = 1111111,
  },
  ["0111"] = {
    backgroundColor = Colors.faint_crimson,
    starColors = { Colors.magenta, Colors.cyan, Colors.apricot_glow, Colors.midnight_harbor },
    difficulty = 2.6,
    winCondition = { type = "blips", value = 80, finalBlipColor = Colors.antique_gold },
    seed = 11111111,
  },
  ["1000"] = {
    backgroundColor = Colors.shadow_green,
    starColors = { Colors.periwinkle_mist, Colors.skyline_azure, Colors.royal_sapphire, Colors.midnight_harbor },
    difficulty = 2.8,
    winCondition = { type = "blips", value = 90, finalBlipColor = Colors.antique_gold },
    seed = 111111111,
  },
  ["1001"] = {
    backgroundColor = Colors.inky_blue,
    starColors = { Colors.magenta, Colors.cyan, Colors.apricot_glow, Colors.royal_sapphire },
    difficulty = 3.0,
    winCondition = { type = "blips", value = 100, finalBlipColor = Colors.antique_gold },
    seed = 1337,
  },
}

return definitions
