local Consumable = require "defs.consumable"
local inv_town_decoration = require "gen.atlas.inv_town_decoration"
local kassert = require "util.kassert"
local lume = require "util.lume"
local Enum = require "util.enum"
local missinglist = require "util.missinglist"
local slotutil = require "defs.slotutil"
require "strings.strings"

-- Items that can be placed in the world.
local Constructable = {
	Slots = {},
	SlotDescriptor = {},
	Items = {},
}

local ordered_slots = {}

Constructable.Categories = {
	BASIC = "basic",
	TREEMON_FOREST = "treemon_forest",
	OWLITZER_FOREST = "owlitzer_forest",
	BANDI_SWAMP = "bandi_swamp",
	THATCHER_SWAMP = "thatcher_swamp",
}

local Ingredient = Consumable.CreateIngredient

local function MonsterIngredient(monster, rarity, count)
	count = count or 1
	local monster_tag = ("drops_%s"):format(monster)
	local items = Consumable.GetItemList(Consumable.Slots.MATERIALS, { monster_tag, rarity })

	if #items > 0 then
		local item = items[1]
		return Ingredient(item.name, count)
	else
		assert(true, ("Invalid material: %s/ %s"):format(monster, rarity))
	end
end

local function AddSlot(slot, tags)
	slotutil.AddSlot(Constructable, slot, tags)
	Constructable.SlotDescriptor[slot].icon = ("images/icons_ftf/build_%s.tex"):format(slot:lower())
	-- Maintain an ordered list of slots.
	table.insert(ordered_slots, slot)
end

local function GetIcon(prefab_name)
	-- consumable item icon name format: icon_[symbol]_[build]
	local icon_name = ("town_prop_%s"):format(prefab_name)
	local icon = inv_town_decoration.tex[icon_name]
	if not icon then
		missinglist.AddMissingItem("Constructable", prefab_name, ("Missing icon '%s'.\t\tExpected tex: %s.tex"):format(prefab_name, icon_name))
		icon = "images/icons_ftf/item_temp.tex"
	end
	return icon
end

local function AddItem(slot, name, tags)
	local items = Constructable.Items[slot]
	assert(items ~= nil and items[name] == nil, "Nonexistent slot " .. slot)

	local def = {
		name = name,
		slot = slot,
		icon = GetIcon(name),
		pretty = slotutil.GetPrettyStrings(slot, name),
		tags = lume.invert(tags or {}),
		rarity = ITEM_RARITY.s.COMMON,
		weight = 1,
		stackable = false,
	}

	def.tags.placeable = true
	items[name] = def

	return def
end

local CalculateDecorCost = function(monster_names, rarity)
	--calculate the decor cost based on the monsters and rarity of the item
	local loot_amount = TUNING.DECOR_COSTS.BY_RARITY[rarity]

	--rare items take epic loot
	local loot_tag = rarity == ITEM_RARITY.s.EPIC and LOOT_TAGS.ELITE or LOOT_TAGS.NORMAL

	local loot_tbl = {}

	--distribute the loot among the monsters
	while loot_amount > 0 do
		for _, monster_name in ipairs(monster_names) do
			loot_tbl[monster_name] = loot_tbl[monster_name] and loot_tbl[monster_name] + 1 or 1
			loot_amount = loot_amount - 1
			if loot_amount == 0 then
				break
			end
		end
	end

	local ret = {}
	for monster_name, count in pairs(loot_tbl) do
		ret = lume.concat(ret, {MonsterIngredient(monster_name, loot_tag, count)} )
	end

	return ret
end

local function AddIngredientsToDef(def, ingredients)
	def.ingredients = {}
	for i, ingredient in ipairs(ingredients) do
		def.ingredients[ingredient.name] = ingredient.count
	end
	return def
end

-- an NPC's home. Cannot build more than one of these, and they are not built through the normal crafting menu
local function AddBuilding(...)
	local def = AddItem(Constructable.Slots.BUILDINGS, ...)
	--def.tags.playercraftable = false
	return def
end

local function AddNewDecorItem(name, rarity, ingredients, tags, category, slot, ingredient_override)
	if type(ingredients) == "string" then
		--if it's just one thing, put it in a list
		ingredients = {ingredients}
	end

	dbassert(type(ingredients) == "table")

	if type(tags) == "string" then
		--if it's just one thing, put it in a list
		tags = {tags}
	end

	dbassert(type(tags) == "table")

	table.insert(tags, "playercraftable")
	table.insert(tags, category)
	local def = AddItem(slot, name, tags)
	def.rarity = rarity

	if ingredient_override then
		ingredients = ingredient_override
	else
		ingredients = {table.unpack(CalculateDecorCost(ingredients, rarity))}
	end

	def = AddIngredientsToDef(def, ingredients)
	return def
end

-- has collision
local function AddStructure(name, rarity, ingredients, tags, category, ingredient_override)
	AddNewDecorItem(name, rarity, ingredients, tags, category, Constructable.Slots.STRUCTURES, ingredient_override)
end

-- a purely decorative item in the base, has no functionality other than looking nice
local function AddDecor(name, rarity, ingredients, tags, category, ingredient_override)
	AddNewDecorItem(name, rarity, ingredients, tags, category, Constructable.Slots.DECOR, ingredient_override)
end

--------------------------------------------------------------------------

function Constructable.GetItemDef(slot, name)
	return Constructable.Items[slot][name]
end

function Constructable.GetAllItems(tags)
	local items = {}
	for _, slot in pairs(Constructable.Slots) do
		items = table.appendarrays(items, Constructable.GetItemList(slot, tags))
	end
	return items
end

function Constructable.GetItemList(slot, tags)
	return slotutil.GetOrderedItemsWithTag(Constructable.Items[slot], tags)
end

function Constructable.GetOrderedSlots()
	return ordered_slots
end

function Constructable.CollectPrefabs(prefabs, allowed_props)
	for slot, items in pairs(Constructable.Items) do
		for name in pairs(items) do
			if allowed_props[name] then
				prefabs[#prefabs + 1] = name
			end
		end
	end
end

function Constructable.HasSlot(slot)
	return Constructable.Slots[slot] ~= nil
end

function Constructable.IsSlot(slot)
	for _, v in pairs(Constructable.Slots) do
		if v == slot then
			return true
		end
	end

	return false
end

function Constructable.FindItem(query)
	for slot_name, slot_items in pairs(Constructable.Items) do
		for name, def in pairs(slot_items) do
			if name == query then
				return def
			end
		end
	end
end

function Constructable.GetFirstCraftBounty(def)
	-- What do you get and how many do you get?
	local num = TUNING.CRAFTING.CONSTRUCTABLE_RARITY_TO_BOUNTY[def.rarity] or 1
	return "konjur_soul_lesser", num
end

--------------------------------------------------------------------------

AddSlot("FAVOURITES") -- only exists for descriptor
Constructable.SlotDescriptor.FAVOURITES.is_favourites = true

AddSlot("BUILDINGS") -- TODO @H: Remove this
AddSlot("STRUCTURES")
AddSlot("DECOR")

--------------------------------------------------------------------------

-- AddBuilding("kitchen",   		{"kitchen"})
-- AddBuilding("kitchen_1",   		{"kitchen"})
-- AddBuilding("apothecary",  		{"potion"})
-- AddBuilding("armorer",     		{"armor"})
-- AddBuilding("armorer_1",   		{"armor"})
-- AddBuilding("chemist",     		{"chemist"})
-- AddBuilding("chemist_1",   		{"chemist"})
-- AddBuilding("forge",       		{"weapon"})
-- AddBuilding("forge_1",     		{"weapon"})
-- AddBuilding("scout_tent",  		{"scout"})
-- AddBuilding("scout_tent_1",		{"scout"})
-- AddBuilding("refinery_1",		{"refiner"})
-- AddBuilding("refinery",		    {"refiner"})
-- AddBuilding("dojo_1",			{"dojo_master"})
AddBuilding("marketroom_shop",	{"dungeon_armorsmith"})

--------------------------------------------------------------------------

--------------------------------------------------------------------------
-- PLUSHIES
--------------------------------------------------------------------------
local PLUSHIE_SUFFIX = 
{
	[DECOR_PLUSHIE_SIZE.s.SMALL] = "_sm_plushies",
	[DECOR_PLUSHIE_SIZE.s.MEDIUM] = "_mid_plushies",
	[DECOR_PLUSHIE_SIZE.s.LARGE] = "_lrg_plushies",
}

local AddPlushie = function(monster_name, loot_tag, size, location, ingredient_override)
	local tags = {}
	table.insert(tags, "playercraftable")
	table.insert(tags, "plushies")
	table.insert(tags, location)

	local ingredients = {}
	if ingredient_override then
		ingredients = ingredient_override
	else
		ingredients = {MonsterIngredient(monster_name, loot_tag, TUNING.DECOR_COSTS.PLUSHIE[size])}
	end

	local name = monster_name..PLUSHIE_SUFFIX[size]
	local def = AddItem(Constructable.Slots.DECOR, name, tags)
	def = AddIngredientsToDef(def, ingredients)
	def.rarity = ITEM_RARITY.s.EPIC
	return def
end

AddPlushie("zucco", 		LOOT_TAGS.ELITE, DECOR_PLUSHIE_SIZE.s.SMALL, Constructable.Categories.TREEMON_FOREST )
AddPlushie("cabbageroll", 	LOOT_TAGS.ELITE, DECOR_PLUSHIE_SIZE.s.SMALL, Constructable.Categories.TREEMON_FOREST )
AddPlushie("blarmadillo", 	LOOT_TAGS.ELITE, DECOR_PLUSHIE_SIZE.s.SMALL, Constructable.Categories.TREEMON_FOREST )
AddPlushie("beets", 		LOOT_TAGS.ELITE, DECOR_PLUSHIE_SIZE.s.SMALL, Constructable.Categories.TREEMON_FOREST )
AddPlushie("treemon", 		LOOT_TAGS.ELITE, DECOR_PLUSHIE_SIZE.s.SMALL, Constructable.Categories.TREEMON_FOREST )
AddPlushie("yammo", 		LOOT_TAGS.ELITE, DECOR_PLUSHIE_SIZE.s.MEDIUM, Constructable.Categories.TREEMON_FOREST )
AddPlushie("megatreemon", 	LOOT_TAGS.NORMAL, DECOR_PLUSHIE_SIZE.s.LARGE, Constructable.Categories.TREEMON_FOREST )

AddPlushie("battoad", 		LOOT_TAGS.ELITE, DECOR_PLUSHIE_SIZE.s.SMALL, Constructable.Categories.OWLITZER_FOREST )
AddPlushie("gourdo", 		LOOT_TAGS.ELITE, DECOR_PLUSHIE_SIZE.s.MEDIUM, Constructable.Categories.OWLITZER_FOREST )
AddPlushie("gnarlic", 		LOOT_TAGS.ELITE, DECOR_PLUSHIE_SIZE.s.SMALL, Constructable.Categories.OWLITZER_FOREST )
AddPlushie("windmon", 		LOOT_TAGS.ELITE, DECOR_PLUSHIE_SIZE.s.MEDIUM, Constructable.Categories.OWLITZER_FOREST )
AddPlushie("trio", 			LOOT_TAGS.ELITE, DECOR_PLUSHIE_SIZE.s.MEDIUM, Constructable.Categories.OWLITZER_FOREST, { MonsterIngredient("yammo", LOOT_TAGS.ELITE), MonsterIngredient("gourdo", LOOT_TAGS.ELITE), MonsterIngredient("zucco", LOOT_TAGS.ELITE) } )
AddPlushie("owlitzer", 		LOOT_TAGS.NORMAL, DECOR_PLUSHIE_SIZE.s.LARGE, Constructable.Categories.OWLITZER_FOREST )

AddPlushie("mothball", 		LOOT_TAGS.ELITE, DECOR_PLUSHIE_SIZE.s.SMALL, Constructable.Categories.BANDI_SWAMP )
AddPlushie("mothball_teen",	LOOT_TAGS.ELITE, DECOR_PLUSHIE_SIZE.s.MEDIUM, Constructable.Categories.BANDI_SWAMP, { MonsterIngredient("mothball", LOOT_TAGS.ELITE, TUNING.DECOR_COSTS.PLUSHIE[DECOR_PLUSHIE_SIZE.s.MEDIUM]) })
AddPlushie("bulbug", 		LOOT_TAGS.ELITE, DECOR_PLUSHIE_SIZE.s.SMALL, Constructable.Categories.BANDI_SWAMP )
AddPlushie("mossquito", 	LOOT_TAGS.ELITE, DECOR_PLUSHIE_SIZE.s.SMALL, Constructable.Categories.BANDI_SWAMP )
AddPlushie("groak", 		LOOT_TAGS.ELITE, DECOR_PLUSHIE_SIZE.s.MEDIUM, Constructable.Categories.BANDI_SWAMP )
AddPlushie("eyev", 			LOOT_TAGS.ELITE, DECOR_PLUSHIE_SIZE.s.SMALL, Constructable.Categories.BANDI_SWAMP )
AddPlushie("sporemon",		LOOT_TAGS.ELITE, DECOR_PLUSHIE_SIZE.s.SMALL, Constructable.Categories.BANDI_SWAMP )
AddPlushie("bandicoot",		LOOT_TAGS.NORMAL, DECOR_PLUSHIE_SIZE.s.LARGE, Constructable.Categories.BANDI_SWAMP )

AddPlushie("swarmy", 		LOOT_TAGS.ELITE, DECOR_PLUSHIE_SIZE.s.SMALL,  Constructable.Categories.THATCHER_SWAMP )
AddPlushie("totolili", 		LOOT_TAGS.ELITE, DECOR_PLUSHIE_SIZE.s.MEDIUM, Constructable.Categories.THATCHER_SWAMP )
AddPlushie("floracrane", 	LOOT_TAGS.ELITE, DECOR_PLUSHIE_SIZE.s.MEDIUM, Constructable.Categories.THATCHER_SWAMP )
AddPlushie("slowpoke", 		LOOT_TAGS.ELITE, DECOR_PLUSHIE_SIZE.s.MEDIUM, Constructable.Categories.THATCHER_SWAMP )
AddPlushie("woworm",		LOOT_TAGS.ELITE, DECOR_PLUSHIE_SIZE.s.MEDIUM, Constructable.Categories.THATCHER_SWAMP )
AddPlushie("thatcher",		LOOT_TAGS.NORMAL, DECOR_PLUSHIE_SIZE.s.LARGE, Constructable.Categories.THATCHER_SWAMP )

--------------------------------------------------------------------------
--Add the other decor for each location

--------------------------------------------------------------------------
-- BASIC DECOR
--------------------------------------------------------------------------
AddStructure("bench_basic",					ITEM_RARITY.s.COMMON, "treemon", "chair", Constructable.Categories.BASIC )
AddStructure("chair_basic",					ITEM_RARITY.s.COMMON, "beets", "chair", Constructable.Categories.BASIC )
AddStructure("street_lamp",					ITEM_RARITY.s.COMMON, "treemon", "light_fixture", Constructable.Categories.BASIC )

AddStructure("stool_outdoor_seating_basic",	ITEM_RARITY.s.UNCOMMON, {"treemon", "yammo"}, "chair", Constructable.Categories.BASIC )
AddStructure("lamp_basic",					ITEM_RARITY.s.UNCOMMON, {"zucco", "beets"}, "light_fixture", Constructable.Categories.BASIC )
AddStructure("outdoor_seating_basic", 		ITEM_RARITY.s.UNCOMMON, {"blarmadillo", "zucco"}, "chair", Constructable.Categories.BASIC )

-- AddStructure("r_fence_iron", 		ITEM_RARITY.s.COMMON, "blarmadillo", "town", Constructable.Categories.BASIC )
-- AddStructure("l_fence_iron", 		ITEM_RARITY.s.COMMON, "blarmadillo", "town", Constructable.Categories.BASIC )
-- AddStructure("l_fence_stone", 		ITEM_RARITY.s.COMMON, "beets", "town", Constructable.Categories.BASIC )
-- AddStructure("r_fence_stone", 		ITEM_RARITY.s.COMMON, "beets", "town", Constructable.Categories.BASIC )
AddStructure("fence_iron", 			ITEM_RARITY.s.COMMON, "floracrane", "town", Constructable.Categories.BASIC )
AddStructure("fence_stone", 		ITEM_RARITY.s.COMMON, "gourdo", "town", Constructable.Categories.BASIC )

-- AddDecor("wooden_cart", ITEM_RARITY.s.COMMON, "blarmadillo", "town", Constructable.Categories.BASIC )
AddStructure("wood_wooden_cart", 	ITEM_RARITY.s.UNCOMMON, {"gnarlic", "treemon"}, "town", Constructable.Categories.BASIC )
AddStructure("straw_wooden_cart", 	ITEM_RARITY.s.UNCOMMON, {"windmon", "treemon"}, "town", Constructable.Categories.BASIC )

AddStructure("rugged_weapon_rack", 	ITEM_RARITY.s.UNCOMMON, {"mossquito", "treemon"}, "town", Constructable.Categories.BASIC )
AddStructure("rustic_weapon_rack", 	ITEM_RARITY.s.UNCOMMON, {"eyev", "treemon"}, "town", Constructable.Categories.BASIC )

AddStructure("bread_basket", 		ITEM_RARITY.s.UNCOMMON, "swarmy", "town", Constructable.Categories.BASIC )
AddStructure("fruit_basket", 		ITEM_RARITY.s.UNCOMMON, "totolili", "town", Constructable.Categories.BASIC )
AddStructure("hammock_basic", 		ITEM_RARITY.s.UNCOMMON, {"mothball", "blarmadillo"}, "town", Constructable.Categories.BASIC )

AddDecor("basket", 					ITEM_RARITY.s.COMMON, 	"bulbug", "town", Constructable.Categories.BASIC )
AddDecor("bread_oven", 				ITEM_RARITY.s.EPIC, 	{"swamry", "slowpoke"}, "town", Constructable.Categories.BASIC )
AddDecor("pergola", 				ITEM_RARITY.s.EPIC, 	{"treemon", "blarmadillo"}, "town", Constructable.Categories.BASIC )
AddDecor("well", 					ITEM_RARITY.s.UNCOMMON, {"owlitzer"}, "town", Constructable.Categories.BASIC )
AddDecor("town_shrub", 				ITEM_RARITY.s.COMMON, "blarmadillo", "flora", Constructable.Categories.BASIC )

--------------------------------------------------------------------------
-- TREEMON FOREST
--------------------------------------------------------------------------
AddStructure("chair_forest_1", 					ITEM_RARITY.s.UNCOMMON, {"cabbageroll", "treemon"},	"chair", Constructable.Categories.TREEMON_FOREST )
AddStructure("bench_forest_1", 					ITEM_RARITY.s.EPIC, 	{"cabbageroll", "treemon"}, "chair", Constructable.Categories.TREEMON_FOREST )
AddStructure("lamp_forest_1", 					ITEM_RARITY.s.UNCOMMON, "yammo", 					"light_fixture", Constructable.Categories.TREEMON_FOREST )
AddStructure("bed_forest_1", 					ITEM_RARITY.s.EPIC, 	"yammo",	 				"chair", Constructable.Categories.TREEMON_FOREST )
AddStructure("outdoor_seating_forest_1", 		ITEM_RARITY.s.EPIC,		{"blarmadillo", "treemon"}, "chair", Constructable.Categories.TREEMON_FOREST )
AddStructure("stool_outdoor_seating_forest_1", 	ITEM_RARITY.s.UNCOMMON,	{"blarmadillo", "treemon"},	"chair", Constructable.Categories.TREEMON_FOREST )

AddStructure("megatreemon_town_bossstatue", 	ITEM_RARITY.s.EPIC, {"megatreemon"}, "town", Constructable.Categories.TREEMON_FOREST, { MonsterIngredient("megatreemon", LOOT_TAGS.NORMAL, TUNING.DECOR_COSTS.BOSSSTATUE)} )

AddDecor("town_flower_bush", 			ITEM_RARITY.s.COMMON, "cabbageroll", "flora", Constructable.Categories.TREEMON_FOREST )
AddDecor("town_flower_violet", 			ITEM_RARITY.s.COMMON, "beets", "flora", Constructable.Categories.TREEMON_FOREST )

--------------------------------------------------------------------------
-- OWLIZTER FOREST
--------------------------------------------------------------------------
AddStructure("chair_forest_2", 					ITEM_RARITY.s.UNCOMMON, {"gnarlic", "windmon"}, "chair", Constructable.Categories.OWLITZER_FOREST )
AddStructure("bench_forest_2", 					ITEM_RARITY.s.EPIC, 	{"gnarlic", "windmon"}, "chair", Constructable.Categories.OWLITZER_FOREST )
AddStructure("lamp_forest_2", 					ITEM_RARITY.s.UNCOMMON, "battoad", "light_fixture", Constructable.Categories.OWLITZER_FOREST )
AddStructure("bed_forest_2", 					ITEM_RARITY.s.EPIC, 	{"battoad", "gourdo" }, "chair", Constructable.Categories.OWLITZER_FOREST )
AddStructure("outdoor_seating_forest_2", 		ITEM_RARITY.s.EPIC,		{"windmon"}, "chair", Constructable.Categories.OWLITZER_FOREST )
AddStructure("stool_outdoor_seating_forest_2",	ITEM_RARITY.s.UNCOMMON, {"gourdo", "windmon"}, "chair", Constructable.Categories.OWLITZER_FOREST )

AddStructure("owlitzer_town_bossstatue", 		ITEM_RARITY.s.EPIC, {"owlitzer"}, "town", Constructable.Categories.OWLITZER_FOREST, { MonsterIngredient("owlitzer", LOOT_TAGS.NORMAL, TUNING.DECOR_COSTS.BOSSSTATUE)})

AddDecor("town_flower_coralbell", 					ITEM_RARITY.s.UNCOMMON, "gnarlic", "flora", Constructable.Categories.OWLITZER_FOREST )

--------------------------------------------------------------------------
-- BANDI
--------------------------------------------------------------------------
AddStructure("chair_swamp_1", 					ITEM_RARITY.s.UNCOMMON, {"eyev", "mothball"}, "chair", Constructable.Categories.BANDI_SWAMP )
AddStructure("bench_swamp_1", 					ITEM_RARITY.s.EPIC, 	{"eyev", "bulbug"}, "chair", Constructable.Categories.BANDI_SWAMP )
AddStructure("lamp_swamp_1", 					ITEM_RARITY.s.UNCOMMON, "bulbug", "light_fixture", Constructable.Categories.BANDI_SWAMP )
AddStructure("bed_swamp_1", 					ITEM_RARITY.s.EPIC, 	{"eyev", "mothball_teen"}, "chair", Constructable.Categories.BANDI_SWAMP )
AddStructure("outdoor_seating_swamp_1", 		ITEM_RARITY.s.EPIC, 	{"mossquito", "eyev"}, "chair", Constructable.Categories.BANDI_SWAMP )
AddStructure("stool_outdoor_seating_swamp_1", 	ITEM_RARITY.s.UNCOMMON, {"groak", "mothball"}, "chair", Constructable.Categories.BANDI_SWAMP )

AddStructure("bandicoot_town_bossstatue", 		ITEM_RARITY.s.EPIC,     {"bandicoot"}, "town", Constructable.Categories.BANDI_SWAMP, { MonsterIngredient("bandicoot", LOOT_TAGS.NORMAL, TUNING.DECOR_COSTS.BOSSSTATUE)})

--------------------------------------------------------------------------
-- THATCHER
--------------------------------------------------------------------------
AddStructure("chair_swamp_2", 					ITEM_RARITY.s.UNCOMMON, {"slowpoke", "woworm"}, "chair", Constructable.Categories.THATCHER_SWAMP )
AddStructure("bench_swamp_2", 					ITEM_RARITY.s.EPIC, 	{"slowpoke", "woworm"}, "chair", Constructable.Categories.THATCHER_SWAMP )
AddStructure("lamp_swamp_2", 					ITEM_RARITY.s.UNCOMMON, "floracrane", "light_fixture", Constructable.Categories.THATCHER_SWAMP )
AddStructure("bed_swamp_2", 					ITEM_RARITY.s.EPIC, 	{"swarmy", "totolili"}, "chair", Constructable.Categories.THATCHER_SWAMP )
AddStructure("outdoor_seating_swamp_2", 		ITEM_RARITY.s.EPIC, 	{"floracrane", "woworm"}, "chair", Constructable.Categories.THATCHER_SWAMP )
AddStructure("stool_outdoor_seating_swamp_2",	ITEM_RARITY.s.UNCOMMON, {"totolili", "swamry"}, "chair", Constructable.Categories.THATCHER_SWAMP )

AddStructure("thatcher_town_bossstatue", 		ITEM_RARITY.s.EPIC, {"thatcher"}, "town", Constructable.Categories.THATCHER_SWAMP, { MonsterIngredient("thatcher", LOOT_TAGS.NORMAL, TUNING.DECOR_COSTS.BOSSSTATUE)})

--------------------------------------------------------------------------

--~ local inspect = require "inspect"
--~ print("all_constructables =", inspect(Constructable.Items, { depth = 5, }))

assert(next(Constructable.Items.FAVOURITES) == nil, "No items should exist in favourites")
slotutil.ValidateSlotStrings(Constructable)

-- crafting menu uses ids as unique lookups
local craft_ids = {}
for slot, items in pairs(Constructable.Items) do
	for name, def in pairs(items) do
		local qualified = ("Constructable.Items.%s.%s"):format(slot, name)
		assert(
			craft_ids[name] == nil,
			("Duplicate item id '%s' used by: '%s' and '%s'"):format(name, qualified, craft_ids[name])
		)
		craft_ids[name] = qualified
	end
end
craft_ids = nil

-- When we want to expose AddSlot and AddItem for mods, we should expose
-- wrappers around them that accept names and icons and stuff those into the
-- appropriate places.

return Constructable
