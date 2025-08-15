local colors = require("colors")

local definitions = {
  ["0000"] = {
    backgroundColor = colors.dark_blue,
    starColors = { colors.white, colors.light_yellow, colors.pale_blue },
    difficulty = 1,
    winCondition = { type = "blips", value = 5, finalBlipColor = colors.antique_gold },
    seed = 1337,
  },
  ["0001"] = {
    backgroundColor = colors.charcoal_black,
    starColors = { colors.magenta, colors.cyan, colors.apricot_glow },
    difficulty = 1.2,
    winCondition = { type = "blips", value = 20, finalBlipColor = colors.antique_gold },
    seed = 42,
  },
  ["0010"] = {
    backgroundColor = colors.charcoal_black,
    starColors = { colors.magenta, colors.cyan, colors.apricot_glow },
    difficulty = 1.4,
    winCondition = { type = "blips", value = 20, finalBlipColor = colors.antique_gold },
    seed = 111,
  },
}

return definitions
