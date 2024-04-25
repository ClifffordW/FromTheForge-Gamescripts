local Weapon = require "defs.equipment.weapon.weapon"
local EquipmentGem = require "defs.equipmentgems.equipmentgem"
local lume = require "util.lume"
local Weight = require "components/weight"

local function ConstructShotput(id, build_id, rarity, data)
	return Weapon.Construct(WEAPON_TYPES.SHOTPUT, "shotput_" .. id, "weapon_back_shotput_" .. build_id, rarity,
		lume.merge(data, {
			fx_type = data.fx_type or "basic",
			crafting_data = data.crafting_data or {},
		}))
end

return {
	ConstructShotput("basic", "basic", ITEM_RARITY.s.COMMON,
		{
			ammo = 2,
			usage_data = { skill_on_equip = "shotput_recall", },
			crafting_data =
			{
				monster_source = { "cabbageroll", "beets" },
			},
			gem_slots = EquipmentGem.GemSlotConfigs.BASIC,
			weight = Weight.EquipmentWeight.s.Light,
		}),

	-- treemon_forest:
	ConstructShotput("treemon_forest", "blarmatreemon",
		ITEM_RARITY.s.UNCOMMON,
		{
			tags = { "hide" }, -- this shotput doesn't exist
			ammo = 2,
			crafting_data = {
				monster_source = { "blarmadillo", "treemon" },
				craftable_location = { "treemon_forest" }
			},
			usage_data = { skill_on_equip = "shotput_recall", },
			gem_slots = EquipmentGem.GemSlotConfigs.FOREST,
			weight = Weight.EquipmentWeight.s.Normal,
		}),

	ConstructShotput("yammo", "yammo",
		ITEM_RARITY.s.EPIC,
		{
			tags = { },
			ammo = 2,
			crafting_data = {
				monster_source = { "yammo" },
				craftable_location = { "treemon_forest" }
			},
			usage_data = { skill_on_equip = "miniboss_yammo", power_on_equip = "equipment_yammo_weapon" },
			gem_slots = EquipmentGem.GemSlotConfigs.FOREST,
			weight = Weight.EquipmentWeight.s.Heavy,
		}),

	-- owlitzer_forest:
	ConstructShotput("owlitzer_forest", "zuccowindmon",
		ITEM_RARITY.s.UNCOMMON,
		{
			tags = { },
			ammo = 2,
			crafting_data = {
				monster_source = { "zucco", "windmon" },
				craftable_location = { "owlitzer_forest" }
			},
			usage_data = { skill_on_equip = "shotput_slam", power_on_equip = "equipment_shotput_rebounds_to_owner" },
			gem_slots = EquipmentGem.GemSlotConfigs.FOREST,
			weight = Weight.EquipmentWeight.s.Light,
			rebounds_to_owner = true,
		}),
	ConstructShotput("gourdo", "gourdo", ITEM_RARITY.s.EPIC,
		{
			tags = { },
			ammo = 2,
			crafting_data =
			{
				monster_source = { "gourdo" },
				craftable_location = { "owlitzer_forest" },
			},
			usage_data = { skill_on_equip = "miniboss_gourdo", power_on_equip = "equipment_gourdo_weapon" },
			gem_slots = EquipmentGem.GemSlotConfigs.FOREST,
			weight = Weight.EquipmentWeight.s.Heavy,
		}),

	-- bandi_swamp:
	ConstructShotput("bandi_swamp", "swamp1", ITEM_RARITY.s.UNCOMMON,
		{
			ammo = 2,
			crafting_data = {
				monster_source = { "mossquito", "eyev" },
				craftable_location = { "bandi_swamp" }
			},
			usage_data = { skill_on_equip = "shotput_lob", power_on_equip = "equipment_shotput_explode_on_land" },
			gem_slots = EquipmentGem.GemSlotConfigs.SWAMP,
			weight = Weight.EquipmentWeight.s.Heavy,
			rebound_hitbox_radius = 1.25, -- Make it a bit harder to catch/bounce on an enemy's head, so that it actually hits the ground and explodes more often.
		}),
	ConstructShotput("groak", "groak", ITEM_RARITY.s.EPIC,
		{
			ammo = 2,
			crafting_data =
			{
				monster_source = { "groak" },
				craftable_location = { "bandi_swamp" },
			},
			usage_data = { skill_on_equip = "miniboss_groak", power_on_equip = "equipment_groak_weapon" },
			gem_slots = EquipmentGem.GemSlotConfigs.SWAMP,
			weight = Weight.EquipmentWeight.s.Heavy,
		}),

	-- thatcher_swamp:
	ConstructShotput("floracrane", "floracrane", ITEM_RARITY.s.EPIC,
		{
			tags = { }, --hide while reworking equipment
			ammo = 2,
			crafting_data = {
				monster_source = { "groak", "floracrane" },
				craftable_location = { "thatcher_swamp" } -- thatcher_swamp
			},
			usage_data = { skill_on_equip = "miniboss_floracrane", power_on_equip = "equipment_floracrane_weapon" },
			gem_slots = EquipmentGem.GemSlotConfigs.SWAMP,
			weight = Weight.EquipmentWeight.s.Light,
		}),


-- Bosses
	ConstructShotput("megatreemon", "megatreemon", ITEM_RARITY.s.EPIC,
		{
			tags = { "hide" }, --hide while reworking equipment
			crafting_data =
			{
				monster_source = { "megatreemon" },
			},
			usage_data = { skill_on_equip = "megatreemon_weaponskill", },
			gem_slots = EquipmentGem.GemSlotConfigs.MEGATREEMON,
		}),
	ConstructShotput("bandicoot", "bandicoot", ITEM_RARITY.s.EPIC,
		{
			tags = { "hide" }, --hide while reworking equipment
			crafting_data =
			{
				monster_source = { "bandicoot" },
			},
			usage_data = { skill_on_equip = "parry", }, --TODO: bandicoot skill
			gem_slots = EquipmentGem.GemSlotConfigs.BANDICOOT,
		}),
}
