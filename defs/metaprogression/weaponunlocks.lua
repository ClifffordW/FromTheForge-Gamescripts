local MetaProgress = require "defs.metaprogression.metaprogress"
local Power = require"defs.powers"
local Equipment = require("defs.equipment")

-- This Progress is for converting Corestones into Weapon Unlocks.

-- A weapon rack in town accepts corestones, and after a certain amount of them unlocks the weapon class.
-- After that point, the weapon rack acts as an Inventory opener.

function MetaProgress.AddWeaponUnlock(id, data)
	assert(data.base_exp, "weaponunlocks.lua: must configure an amount of XP to unlock weapon class")
	MetaProgress.AddProgression(MetaProgress.Slots.WEAPON_UNLOCKS, id, data)
end

MetaProgress.AddProgressionType("WEAPON_UNLOCKS")

MetaProgress.AddWeaponUnlock("hammer",
{
	base_exp = { 0 },
	rewards =
	{
		-- Unlock Polearm class
		-- MetaProgress.Reward(Equipment, Equipment.Slots.WEAPON, "hammer_basic"),
	},
	no_rewards_cb = function(metastore, player, args)
		local WeaponSelectionScreen = require "screens.town.weaponselectionscreen"
		TheFrontEnd:PushScreen(WeaponSelectionScreen(player, WEAPON_TYPES.HAMMER))
	end,
})

MetaProgress.AddWeaponUnlock("polearm",
{
	base_exp = { 5 },
	rewards =
	{
		-- Unlock Polearm class
		MetaProgress.Reward(Equipment, Equipment.Slots.WEAPON, "polearm_basic"),
	},
	no_rewards_cb = function(metastore, player, args)
		local WeaponSelectionScreen = require "screens.town.weaponselectionscreen"
		TheFrontEnd:PushScreen(WeaponSelectionScreen(player, WEAPON_TYPES.POLEARM))
	end,
})

MetaProgress.AddWeaponUnlock("shotput",
{
	base_exp = { 7 },
	rewards =
	{
		-- Unlock Shotput class
		MetaProgress.Reward(Equipment, Equipment.Slots.WEAPON, "shotput_basic"),
	},
	no_rewards_cb = function(metastore, player, args)
		local WeaponSelectionScreen = require "screens.town.weaponselectionscreen"
		TheFrontEnd:PushScreen(WeaponSelectionScreen(player, WEAPON_TYPES.SHOTPUT))
	end,
})

MetaProgress.AddWeaponUnlock("cannon",
{
	base_exp = { 9 },
	rewards =
	{
		-- Unlock Cannon class
		MetaProgress.Reward(Equipment, Equipment.Slots.WEAPON, "cannon_basic"),
	},

	no_rewards_cb = function(metastore, player, args)
		local WeaponSelectionScreen = require "screens.town.weaponselectionscreen"
		TheFrontEnd:PushScreen(WeaponSelectionScreen(player, WEAPON_TYPES.CANNON))
	end,
})