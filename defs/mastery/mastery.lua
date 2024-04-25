local kassert = require "util.kassert"
local kstring = require "util.kstring"
local lume = require "util.lume"
local missinglist = require "util.missinglist"
local mastery_icons = require "gen.atlas.ui_ftf_mastery_icons"
local slotutil = require "defs.slotutil"
local Consumable = require "defs.consumable"

local MetaProgress = require "defs.metaprogression.metaprogress"
require "defs.metaprogression.metareward"

require "strings.strings"

local Mastery = {
	Items = {},
	Slots = {},
	SlotDescriptor = {},
}

local ordered_slots = {}

function Mastery.AddMasteryFamily(slot, tags)
	slotutil.AddSlot(Mastery, slot, tags)
	table.insert(ordered_slots, slot)
end

Mastery.AddMasteryFamily("WEAPON_MASTERY")
Mastery.AddMasteryFamily("MONSTER_MASTERY")

local function GetIcon(mastery_name)
	-- mastery icon name format: icon_mastery_[mastery_type]
	local icon_name = ("icon_mastery_%s"):format(mastery_name)

	icon_name = string.lower(icon_name)

	local icon = mastery_icons.tex[icon_name]

	if not icon then
		missinglist.AddMissingItem("Mastery", mastery_name, ("Missing mastery icon for '%s'.\t\tExpected tex: %s.tex"):format(mastery_name, icon_name))
		icon = mastery_icons.tex.icon_mastery_temp
	end

	return icon
end

local _default_update_thresholds =
{
	-- percentage completion, gets put into persistdata on creation of a mastery with an associated bool for whether that threshold has been updated or not
	0.85,
	0.75,
	0.5,
	0.25,
	0.01, -- Basically, update the first time it happens
}

function Mastery.AddMastery(slot, name, mastery_type, data)
	local items = Mastery.Items[slot]
	assert(items ~= nil and items[name] == nil, "Nonexistent slot " .. slot)

	local difficulty = data.difficulty or MASTERY_DIFFICULY.s.EASY
	local def = {
		name = name,
		slot = slot,
		icon = GetIcon(name),
		pretty = slotutil.GetPrettyStringsByType(slot, mastery_type, name),
		rarity = ITEM_RARITY.s.COMMON, -- the tuning system expects a rarity, so we're just faking one in
		tuning = { [ITEM_RARITY.s.COMMON] = data.tuning or {} },
		-- Used both as organizational tags (for querying mastery defs) and tags
		-- applied to the entity! Added to the entity while the mastery is active.
		tags = data.tags or {},
		assets = data.assets,
		mastery_type = mastery_type,
		default_unlocked = data.default_unlocked or false,

		hide = data.hide or false,

		on_update_fn = data.on_update_fn,
		on_add_fn = data.on_add_fn,
		on_remove_fn = data.on_remove_fn,
		event_triggers = data.event_triggers or {},
		remote_event_triggers = data.remote_event_triggers or {},

		update_thresholds = data.update_thresholds or _default_update_thresholds,
		progress = data.progress,
		starting_progress = data.starting_progress or 0,
		max_progress = data.max_progress or 20, -- default to 20?
		tooltips = data.tooltips or {},
		difficulty = difficulty,

		rewards = lume.concat({
			MetaProgress.Reward(Consumable, Consumable.Slots.MATERIALS, "konjur_soul_lesser", TUNING.MASTERIES.CORESTONE_REWARDS[difficulty])
		}, data.rewards or {}),

		next_step = data.next_step or nil,

		--for sorting
		order = table.count(items)
	}

	items[name] = def
	return def
end

function Mastery.FindMasteryByQualifiedName(qualified_name)
	local mastery_name = qualified_name:match("^mst_(%S+)$")
	kassert.assert_fmt(mastery_name, "Invalid mastery '%s'", qualified_name)
	return Mastery.FindMasteryByName(mastery_name)
end

function Mastery.FindMasteryByName(mastery_name)
	for _, slot in pairs(Mastery.Items) do
		for name, def in pairs(slot) do
			if mastery_name == name then
				return def
			end
		end
	end
	error("Invalid mastery name: ".. mastery_name)
end

function Mastery.GetDesc(mastery)
	local def = mastery:GetDef()
	local desc = kstring.subfmt(def.pretty.desc, mastery:GetTuning())
	return kstring.subfmt("{desc}", {desc = desc})
end

function Mastery.CollectAssets(tbl)
	for _, slot in pairs(Mastery.Items) do
		for name, def in pairs(slot) do
			for _, asset in ipairs(def.assets or table.empty) do
				table.insert(tbl, asset)
			end
		end
	end
end

function Mastery.CollectPrefabs(tbl)
	for _, slot in pairs(Mastery.Items) do
		for name, def in pairs(slot) do
			for _, prefab in ipairs(def.prefabs or table.empty) do
				table.insert(tbl, prefab)
			end
		end
	end
end

function Mastery.GetOrderedSlots()
	return ordered_slots
end

return Mastery

-- MASTERY IDEAS:

-- General, applicable to any mob
-- Perfect Dodge an attack from [mob]
-- Kill a [mob] using a trap
-- Do an x-hit combo on [mob]
-- Land a critical hit on [mob]
-- Knockdown [mob]

-- Do X in a single run
