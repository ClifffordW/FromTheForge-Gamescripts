local Enum = require "util.enum"

local CurrencyType = Enum {
	"Run", -- (Teffra) Currency gained and spent during dungeon run.
	"Meta", -- (Corestones) Currency gained and spent throughout the game, persisting across dungeon runs.
	"Health", -- An "inverse" currency. That is, the more health the player *doesn't* have, the more they can spend.
	"Loot", -- Creature drops
}

-- Minimum number of bits required to represent the maximum CurrencyType.id.
CurrencyType.BIT_COUNT = 3

return CurrencyType
