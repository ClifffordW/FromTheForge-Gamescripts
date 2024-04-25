local Constructable = require "defs.constructable"
local Cosmetic = require "defs.cosmetics.cosmetics"
local MetaProgression = require "defs.metaprogression"
local lume = require "util.lume"

-- Load data that populates MetaProgression.
assert(MetaProgression.all_rewards and #MetaProgression.all_rewards > 0, "Moved rewards out of progression? Please add them here.")
require "defs.masteries"


-- Assets for unlockable items created with CosmeticEditor and pure code.


-- Currently: Rewards contain many types:
-- * Constructable: Constructable.Slots.DECOR, Constructable.Slots.STRUCTURES
-- * Consumable: Consumable.Slots.MATERIALS
-- * Cosmetic: Cosmetic.Slots.PLAYER_BODYPART, Cosmetic.Slots.PLAYER_TITLE
-- * Equipment: Equipment.Slots.WEAPON
-- * Power: Power.Slots.PLAYER, Power.Slots.SKILL
-- Since there's so much diversity, we filter for all reward names and allow any cosmetics with those types.

local unlockables = lume(MetaProgression.all_rewards)
	:map(function(v)
		return v.def.name
	end)
	:result()

local cosmetics = lume(Cosmetic.GetAllDefaultUnlocks())
	:merge(Cosmetic.PlayerEmotes)  -- emotes art is baked into character, so keep all
	:keys()
	:concat(unlockables)  -- any from rewards
	:invert()
	:result()

local assets_cosmetic = {
	prod = {},
	dev = {},
}
Cosmetic.CollectAssets(assets_cosmetic, cosmetics)


local constructs = lume(Constructable.Items)
	:filter(function(x)
		-- TODO: Assuming basic unlocked by default?
		return x.slot == Constructable.Categories.BASIC
	end, true)
	:keys()
	:concat(unlockables)  -- any from rewards
	:invert()
	:result()

local prefabs_construct = {}
Constructable.CollectPrefabs(prefabs_construct, constructs)

return
	Prefab(GroupPrefab("deps_town_unlockables"), function() end, nil, prefabs_construct),
	Prefab(GroupPrefab("deps_player_cosmetics"), function() end, assets_cosmetic.prod),
	Prefab(GroupPrefab("deps_player_cosmetics_dev"), function() end, assets_cosmetic.dev)
