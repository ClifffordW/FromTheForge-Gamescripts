local Enum = require "util.enum"

-- Enumerate all the SaveData formats. Functions that effect version updates for these formats will be keyed by these
-- variants.
local SaveDataFormat = Enum {
	"Room",
	"Progress",
	"Character",
	"Dungeon",
	"SaveManagement",
	"ActivePlayers",
	"Friends",
	"Cheats",
	"Network",
	"About",
	"Replay"
}

return SaveDataFormat
