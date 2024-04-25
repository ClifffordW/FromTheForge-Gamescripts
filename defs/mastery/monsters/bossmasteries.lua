local Mastery = require "defs.mastery.mastery"
local MetaProgress = require "defs.metaprogression.metaprogress"
local Constructable = require"defs.constructable"
local Consumable = require"defs.consumable"
local Cosmetic = require "defs.cosmetics.cosmetics"
local templates = require"defs.mastery.masterytemplates"

local function add_mastery_fn(mastery_id, data)
	Mastery.AddMastery(Mastery.Slots.MONSTER_MASTERY, mastery_id, "OTHER", data)
end

templates.AddBossKillMonsterMastery(add_mastery_fn, "megatreemon", {
	default_unlocked = true,
	difficulty = MASTERY_DIFFICULY.s.MEDIUM,
	rewards =
	{
		MetaProgress.Reward(Constructable, Constructable.Slots.DECOR, "cabbageroll_sm_plushies"),
		MetaProgress.Reward(Constructable, Constructable.Slots.DECOR, "beets_sm_plushies"),

		-- Give some Elite Loot to let them upgrade one piece to higher level
		-- One for each armor type in this dungeon
		MetaProgress.Reward(Consumable, Consumable.Slots.MATERIALS, "yammo_stem", 1),
		MetaProgress.Reward(Consumable, Consumable.Slots.MATERIALS, "blarmadillo_trunk", 1),
		MetaProgress.Reward(Consumable, Consumable.Slots.MATERIALS, "cabbageroll_baby", 1),
		MetaProgress.Reward(Consumable, Consumable.Slots.MATERIALS, "beets_leaf", 1),
	},
	-- next_step = { "owlitzer_kill", "megatreemon_kill_ascension_1" },
}, 1)

templates.AddAscensionBossKillMonsterMastery(add_mastery_fn, "megatreemon", {
	difficulty = MASTERY_DIFFICULY.s.MEDIUM,
	rewards =
	{
		MetaProgress.Reward(Constructable, Constructable.Slots.DECOR, "blarmadillo_sm_plushies"),
		MetaProgress.Reward(Constructable, Constructable.Slots.DECOR, "treemon_sm_plushies"),
	},
	-- next_step = { "megatreemon_kill_ascension_2" },
}, 1, 1)
templates.AddAscensionBossKillMonsterMastery(add_mastery_fn, "megatreemon", {
	difficulty = MASTERY_DIFFICULY.s.HARD,
	rewards =
	{
		MetaProgress.Reward(Constructable, Constructable.Slots.DECOR, "megatreemon_lrg_plushies"),
		MetaProgress.Reward(Constructable, Constructable.Slots.DECOR, "yammo_mid_plushies"),
	},
	-- next_step = { "megatreemon_kill_ascension_3" },
}, 2, 1)
templates.AddAscensionBossKillMonsterMastery(add_mastery_fn, "megatreemon", {
	difficulty = MASTERY_DIFFICULY.s.HARD,
	rewards =
	{
		-- Boss statue
		MetaProgress.Reward(Constructable, Constructable.Slots.STRUCTURES, "megatreemon_town_bossstatue"),
		MetaProgress.Reward(Cosmetic, Cosmetic.Slots.PLAYER_TITLE, "forestkeeper")
	},
	-- next_step = { },
}, 3, 1)

templates.AddBossKillMonsterMastery(add_mastery_fn, "owlitzer", {
	difficulty = MASTERY_DIFFICULY.s.MEDIUM,
	rewards =
	{
		MetaProgress.Reward(Constructable, Constructable.Slots.DECOR, "gnarlic_sm_plushies"),

		MetaProgress.Reward(Consumable, Consumable.Slots.MATERIALS, "gourdo_skin", 1),
		MetaProgress.Reward(Consumable, Consumable.Slots.MATERIALS, "battoad_wing", 1),
		MetaProgress.Reward(Consumable, Consumable.Slots.MATERIALS, "zucco_claw", 1),
		MetaProgress.Reward(Consumable, Consumable.Slots.MATERIALS, "gnarlic_sprouts", 1),
	},
	-- next_step = { "bandicoot_kill", "owlitzer_kill_ascension_1" },
}, 1)
templates.AddAscensionBossKillMonsterMastery(add_mastery_fn, "owlitzer", {
	difficulty = MASTERY_DIFFICULY.s.MEDIUM,
	rewards =
	{
		MetaProgress.Reward(Constructable, Constructable.Slots.DECOR, "windmon_mid_plushies"),
		MetaProgress.Reward(Constructable, Constructable.Slots.DECOR, "zucco_sm_plushies"),
	},
	-- next_step = { "owlitzer_kill_ascension_2" },
}, 1, 1)
templates.AddAscensionBossKillMonsterMastery(add_mastery_fn, "owlitzer", {
	difficulty = MASTERY_DIFFICULY.s.HARD,
	rewards =
	{
		MetaProgress.Reward(Constructable, Constructable.Slots.DECOR, "battoad_sm_plushies"),
		MetaProgress.Reward(Constructable, Constructable.Slots.DECOR, "owlitzer_lrg_plushies"),
		MetaProgress.Reward(Constructable, Constructable.Slots.DECOR, "gourdo_mid_plushies"),
	},
	-- next_step = { "owlitzer_kill_ascension_3" },
}, 2, 1)
templates.AddAscensionBossKillMonsterMastery(add_mastery_fn, "owlitzer", {
	difficulty = MASTERY_DIFFICULY.s.HARD,
	rewards =
	{
		MetaProgress.Reward(Constructable, Constructable.Slots.DECOR, "trio_mid_plushies"),
		MetaProgress.Reward(Constructable, Constructable.Slots.STRUCTURES, "owlitzer_town_bossstatue"),
		MetaProgress.Reward(Cosmetic, Cosmetic.Slots.PLAYER_TITLE, "nightshroud")
	},
	-- next_step = { },
}, 3, 1)

templates.AddBossKillMonsterMastery(add_mastery_fn, "bandicoot", {
	difficulty = MASTERY_DIFFICULY.s.HARD,
	rewards =
	{
		MetaProgress.Reward(Constructable, Constructable.Slots.DECOR, "eyev_sm_plushies"),
		MetaProgress.Reward(Constructable, Constructable.Slots.DECOR, "mossquito_sm_plushies"),

		MetaProgress.Reward(Consumable, Consumable.Slots.MATERIALS, "groak_elite", 1),
		MetaProgress.Reward(Consumable, Consumable.Slots.MATERIALS, "eyev_eyelashes", 1),
		MetaProgress.Reward(Consumable, Consumable.Slots.MATERIALS, "bulbug_bulb", 1),
		MetaProgress.Reward(Consumable, Consumable.Slots.MATERIALS, "mothball_teen_ear", 1),
	},
	-- next_step = { "thatcher_kill", "bandicoot_kill_ascension_1" },
}, 1)
templates.AddAscensionBossKillMonsterMastery(add_mastery_fn, "bandicoot", {
	difficulty = MASTERY_DIFFICULY.s.HARD,
	rewards =
	{
		MetaProgress.Reward(Constructable, Constructable.Slots.DECOR, "bulbug_sm_plushies"),
		MetaProgress.Reward(Constructable, Constructable.Slots.DECOR, "mothball_teen_mid_plushies"),
	},
	-- next_step = { "bandicoot_kill_ascension_2" },
}, 1, 1)
templates.AddAscensionBossKillMonsterMastery(add_mastery_fn, "bandicoot", {
	difficulty = MASTERY_DIFFICULY.s.HARD,
	rewards =
	{
		MetaProgress.Reward(Constructable, Constructable.Slots.DECOR, "sporemon_sm_plushies"),
		MetaProgress.Reward(Constructable, Constructable.Slots.DECOR, "bandicoot_lrg_plushies"),
		MetaProgress.Reward(Constructable, Constructable.Slots.DECOR, "groak_mid_plushies"),
	},
	-- next_step = { "bandicoot_kill_ascension_3" },
}, 2, 1)
templates.AddAscensionBossKillMonsterMastery(add_mastery_fn, "bandicoot", {
	difficulty = MASTERY_DIFFICULY.s.HARD,
	rewards =
	{
		-- Boss Statue
		MetaProgress.Reward(Constructable, Constructable.Slots.STRUCTURES, "bandicoot_town_bossstatue"),
		MetaProgress.Reward(Cosmetic, Cosmetic.Slots.PLAYER_TITLE, "madtrickster")
	},
	-- next_step = { },
}, 3, 1)

templates.AddBossKillMonsterMastery(add_mastery_fn, "thatcher", {
	difficulty = MASTERY_DIFFICULY.s.HARD,
	rewards =
	{
		MetaProgress.Reward(Constructable, Constructable.Slots.DECOR, "mothball_sm_plushies"),
		MetaProgress.Reward(Constructable, Constructable.Slots.DECOR, "woworm_mid_plushies"),

		MetaProgress.Reward(Consumable, Consumable.Slots.MATERIALS, "floracrane_beak", 1),
		MetaProgress.Reward(Consumable, Consumable.Slots.MATERIALS, "slowpoke_eye", 1),
		MetaProgress.Reward(Consumable, Consumable.Slots.MATERIALS, "woworm_shield", 1),
		MetaProgress.Reward(Consumable, Consumable.Slots.MATERIALS, "swarmy_arm", 1),
	},
	-- next_step = { "thatcher_kill_ascension_1" },
}, 1)
templates.AddAscensionBossKillMonsterMastery(add_mastery_fn, "thatcher", {
	difficulty = MASTERY_DIFFICULY.s.HARD,
	rewards =
	{
		MetaProgress.Reward(Constructable, Constructable.Slots.DECOR, "slowpoke_mid_plushies"),
	},
	-- next_step = { "thatcher_kill_ascension_2" },
}, 1, 1)
templates.AddAscensionBossKillMonsterMastery(add_mastery_fn, "thatcher", {
	difficulty = MASTERY_DIFFICULY.s.HARD,
	rewards =
	{
		MetaProgress.Reward(Constructable, Constructable.Slots.DECOR, "swarmy_sm_plushies"),
		MetaProgress.Reward(Constructable, Constructable.Slots.DECOR, "thatcher_lrg_plushies"),
		MetaProgress.Reward(Constructable, Constructable.Slots.DECOR, "floracrane_mid_plushies"),
	},
	-- next_step = { "thatcher_kill_ascension_3" },
}, 2, 1)
templates.AddAscensionBossKillMonsterMastery(add_mastery_fn, "thatcher", {
	difficulty = MASTERY_DIFFICULY.s.HARD,
	rewards =
	{
		MetaProgress.Reward(Constructable, Constructable.Slots.DECOR, "totolili_mid_plushies"),
		MetaProgress.Reward(Constructable, Constructable.Slots.STRUCTURES, "thatcher_town_bossstatue"),
		MetaProgress.Reward(Cosmetic, Cosmetic.Slots.PLAYER_TITLE, "balladweaver") -- TODO @H: update this
	},
	-- next_step = { },
}, 3, 1)