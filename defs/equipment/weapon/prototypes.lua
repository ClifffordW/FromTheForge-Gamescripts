local Weapon = require "defs.equipment.weapon.weapon"

-- #MAKING_WEAPONS: replace the ['PROTOTYPE'] weapon type in constants.lua too!

local weaponprototype_build = "weapon_back_template" --#MAKING_WEAPONS: replace with whatever build you want to test
--#MAKING_WEAPONS: Remember to add the bank to CollectAssets above!

-- Weapon Prototyper, for testing basic anim sets before they have actual stategraphs:

return {
	Weapon.Construct(WEAPON_TYPES.PROTOTYPE, "weaponprototype", weaponprototype_build, ITEM_RARITY.s.COMMON, {
		tags = { "weaponprototype", "hide" },
		fx_type = "basic",
	})
}
