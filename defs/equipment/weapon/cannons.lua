local Weapon = require "defs.equipment.weapon.weapon"
local lume = require "util.lume"
local EquipmentGem = require "defs.equipmentgems.equipmentgem"
local Weight = require "components/weight"

local function Construct(id, build_id, rarity, data)
	return Weapon.Construct(WEAPON_TYPES.CANNON, "cannon_" .. id, "weapon_back_cannon_" .. build_id, rarity,
		lume.merge(data, {
			fx_type = data.fx_type or "basic",
			crafting_data = data.crafting_data or {},
		}))
end

return {
	Construct("basic", "basic", ITEM_RARITY.s.COMMON,
		{
			crafting_data =
			{
				monster_source = { "cabbageroll", "beets" },
			},
			usage_data = { skill_on_equip = "cannon_butt" },
			gem_slots = EquipmentGem.GemSlotConfigs.BASIC,
		}),

	-- treemon_forest:
	Construct("yammo", "yammo", ITEM_RARITY.s.EPIC,
		{
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
	Construct("owlitzer_forest", "gnarlicwindbat", ITEM_RARITY.s.UNCOMMON,
		{
			tags = { },
			focus_sequence =
			{
			-- Of a given clip, which shots are FOCUS shots and which are NORMAL shots?
			[1] = false,
			[2] = false,
			[3] = false,
			[4] = false,
			[5] = false,
			[6] = true,
			},
			mortar_focus_sequence =
			{
				[1] = true,
				[2] = true,
				[3] = true,
				[4] = true,
				[5] = true,
				[6] = true,
			},
			crafting_data =
			{
				monster_source = { "battoad", "gnarlic" },
				craftable_location = { "owlitzer_forest" },
			},
			usage_data = { skill_on_equip = "cannon_singlereload", power_on_equip = "equipment_cannon_pierce_focus" },
			gem_slots = EquipmentGem.GemSlotConfigs.SWAMP,
			weight = Weight.EquipmentWeight.s.Normal,
		}),
	Construct("gourdo", "gourdo", ITEM_RARITY.s.EPIC,
		{
			tags = { },
			crafting_data =
			{
				monster_source = { "gourdo" },
				craftable_location = { "owlitzer_forest" },
			},
			usage_data = { skill_on_equip = "miniboss_gourdo", power_on_equip = "equipment_gourdo_weapon" },
			gem_slots = EquipmentGem.GemSlotConfigs.SWAMP,
			weight = Weight.EquipmentWeight.s.Heavy,
		}),

	-- bandi_swamp:
	Construct("groak", "groak", ITEM_RARITY.s.EPIC,
		{
			tags = { },
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
	Construct("thatcher_swamp", "wowototoswarmy", ITEM_RARITY.s.UNCOMMON,
		{
			crafting_data =
			{
				monster_source = { "woworm", "swarmy" },
				craftable_location = { "thatcher_swamp" },
			},
			usage_data = { skill_on_equip = "cannon_butt", power_on_equip = "equipment_cannon_clusterbomb", },
			gem_slots = EquipmentGem.GemSlotConfigs.BASIC,
		}),

	Construct("floracrane", "floracrane", ITEM_RARITY.s.EPIC,
		{
			tags = { },
			crafting_data =
			{
				monster_source = { "floracrane" },
				craftable_location = { "thatcher_swamp" },
			},
			usage_data = { skill_on_equip = "miniboss_floracrane", power_on_equip = "equipment_floracrane_weapon" },
			gem_slots = EquipmentGem.GemSlotConfigs.SWAMP,
			weight = Weight.EquipmentWeight.s.Light,
		}),
	-- Nothing here yet.


-- BOSSES:
	Construct("bandicoot", "bandicoot", ITEM_RARITY.s.EPIC,
		{
			tags = { "hide" }, --hide while reworking equipment
			crafting_data =
			{
				monster_source = { "bandicoot" },
			},
			usage_data = { skill_on_equip = "parry", },
			gem_slots = EquipmentGem.GemSlotConfigs.BANDICOOT,
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
}
