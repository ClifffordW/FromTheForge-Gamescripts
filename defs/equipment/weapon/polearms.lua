local Weapon = require "defs.equipment.weapon.weapon"
local lume = require "util.lume"
local EquipmentGem = require "defs.equipmentgems.equipmentgem"
local Weight = require "components/weight"

local function Construct(id, build_id, rarity, data)
	return Weapon.Construct(WEAPON_TYPES.POLEARM, "polearm_" .. id, "weapon_back_polearm_" .. build_id, rarity,
		lume.merge(data, {
			fx_type = data.fx_type or "basic",
			crafting_data = data.crafting_data or {},
		}))
end

return {
	Construct("basic", "basic", ITEM_RARITY.s.COMMON,
		{
			tags = { },
			crafting_data =
			{
				monster_source = { "cabbageroll", "beets" },
			},
			usage_data = { skill_on_equip = "polearm_shove", },
			gem_slots = EquipmentGem.GemSlotConfigs.BASIC,
		}),

	-- treemon_forest:
	Construct("treemon_forest", "startingforest",
		ITEM_RARITY.s.UNCOMMON,
		{
			tags = { },
			crafting_data =
			{
				monster_source = { "treemon", "zucco" },
				craftable_location = { "treemon_forest" },
			},
			usage_data = { skill_on_equip = "polearm_vault", power_on_equip = "equipment_polearm_long_range" },
			gem_slots = EquipmentGem.GemSlotConfigs.FOREST,
			fx_type = "long",
			weight = Weight.EquipmentWeight.s.Light,
		}),
	Construct("yammo", "yammo",
		ITEM_RARITY.s.EPIC,
		{
			tags = { },
			crafting_data =
			{
				monster_source = { "yammo" },
				craftable_location = { "treemon_forest" },
			},
			usage_data = { skill_on_equip = "miniboss_yammo", power_on_equip = "equipment_yammo_weapon" },
			gem_slots = EquipmentGem.GemSlotConfigs.FOREST,
			weight = Weight.EquipmentWeight.s.Heavy,
		}),

	-- owlitzer_forest:
	Construct("gourdo", "gourdo", ITEM_RARITY.s.EPIC,
		{
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
	Construct("bandi_swamp", "swamp", ITEM_RARITY.s.UNCOMMON,
		{
			tags = { },
			crafting_data =
			{
				monster_source = { "bulbug", "eyev" },
				craftable_location = { "bandi_swamp" },
			},
			usage_data = { skill_on_equip = "polearm_shove", power_on_equip = "equipment_polearm_extended_multithrust" },
			gem_slots = EquipmentGem.GemSlotConfigs.SWAMP,
			weight = Weight.EquipmentWeight.s.Heavy,
		}),
	Construct("groak", "groak", ITEM_RARITY.s.EPIC,
		{
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
	Construct("floracrane", "floracrane", ITEM_RARITY.s.EPIC,
		{
			tags = { },
			crafting_data =
			{
				monster_source = { "floracrane" },
				craftable_location = { "thatcher_swamp" }, -- thatcher_swamp
			},
			usage_data = { skill_on_equip = "miniboss_floracrane", power_on_equip = "equipment_floracrane_weapon" },
			gem_slots = EquipmentGem.GemSlotConfigs.SWAMP,
		}),


	Construct("megatreemon", "megatreemon", ITEM_RARITY.s.EPIC,
		{
			tags = { "hide" }, --hide while reworking equipment
			crafting_data =
			{
				monster_source = { "megatreemon" },
			},
			usage_data = { skill_on_equip = "megatreemon_weaponskill", },
			gem_slots = EquipmentGem.GemSlotConfigs.MEGATREEMON,
		}),

	Construct("bandicoot", "bandicoot", ITEM_RARITY.s.EPIC,
		{
			tags = { "hide" }, --hide while reworking equipment
			crafting_data =
			{
				monster_source = { "bandicoot" },
			},
			usage_data = { skill_on_equip = "parry", }, --TODO bandicoot skill
			gem_slots = EquipmentGem.GemSlotConfigs.BANDICOOT,
		}),
}
