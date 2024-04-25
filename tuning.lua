local color = require "math.modules.color"
local Enum = require "util.enum"
local Strict = require "util.strict"
local Lume = require "util.lume"
local Weight = require "components/weight"

local HSB = color.HSBFromInts
local MONSTER_MOVE_SPEED_MOD = 1
local PLAYER_MOVE_SPEED_MOD = 1

--[[ Definitions:
Modifier - A named value (variable) that is mathematically combined (i.e. added or multiplied) with some
other game value to produce a modified value.
Name - A string value that identifies a Modifier.
ResolvedModifier - Multiple Sources may contribute to a single Mdifier. When all Sources for a Modifier are
mathematically combined (typically via addition), a ResolvedModifier is produced.
Source - Contributes to one or more modifiers.
Sink - Consumes ResolvedModifiers.
]]

EnemyModifierNames = Enum {
	"HealthMult",   -- all enemies, including bosses and minibosses
	"BasicHealthMult", -- all non-boss and non-miniboss enemies, explicitly merged with Health in code (monsterutil.lua, MakeBasicMonster and MakeStationaryMonster). Includes Elites.
	"BossHealthMult", -- bosses only, explicitly merged with Health in code (monsterutil.lua, ExtendToBossMonster)

	-- NOTE: The miniboss likely already has a modified health due to its assigned ENEMY_MULTIPLAYER_MODS.
	-- This value is a nudge above that likely-existing number, just to differentiate the Miniboss version from the
	-- Elite version of that mob that shows up elsewhere.
	"MinibossHealthMult", -- minibosses only, explicitly merged with Health in code (monsterutil.lua, MakeMiniboss)

	"SpawnCountMult",
	"StationarySpawnCountMult",
	"MinibossSpawnCountMult",

	"CooldownMult",
	"EliteCooldownMult",
	"BossCooldownMult",

	"CooldownMinMult",
	"EliteCooldownMinMult",
	"BossCooldownMinMult",

	"InitialCooldownMult",
	"EliteInitialCooldownMult",
	"BossInitialCooldownMult",

	"StartupFramesMult",
	"EliteStartupFramesMult",
	"BossStartupFramesMult",

	"EliteChance",
	"EliteSpawnCount", -- Further modify the amount returned from waves.elite_counts. Ascension that boosts it up, or power that boosts it down, etc.

	"DungeonTierDamageMult",
}

-- Multipliers default to 1; additives default to 0.
local ENEMY_MODIFIER_DEFAULTS = {}
for _, modifier in ipairs(EnemyModifierNames:Ordered()) do
	ENEMY_MODIFIER_DEFAULTS[modifier] = 1
end
ENEMY_MODIFIER_DEFAULTS[EnemyModifierNames.s.BasicHealthMult] = 0
ENEMY_MODIFIER_DEFAULTS[EnemyModifierNames.s.BossHealthMult] = 0
ENEMY_MODIFIER_DEFAULTS[EnemyModifierNames.s.MinibossHealthMult] = 0.5
ENEMY_MODIFIER_DEFAULTS[EnemyModifierNames.s.EliteChance] = 0
ENEMY_MODIFIER_DEFAULTS[EnemyModifierNames.s.EliteSpawnCount] = 0
ENEMY_MODIFIER_DEFAULTS[EnemyModifierNames.s.DungeonTierDamageMult] = 0
Strict.strictify(ENEMY_MODIFIER_DEFAULTS)

-- Enemy modifier tables keyed by Tier index.
-- NOTE @chrisp #meta - If you add a dungeon tier row here, you probably want to add corresponding rows to
-- WeaponILvlModifierSource and ArmourILvlModifierSource to balance game-play.
local DungeonTierModifierSource = {
	{ [EnemyModifierNames.s.HealthMult] = 0.0, [EnemyModifierNames.s.DungeonTierDamageMult] = 0.15 }, --Treemon Forest
	{ [EnemyModifierNames.s.HealthMult] = 0.33, [EnemyModifierNames.s.DungeonTierDamageMult] = 0.33 }, --Owlitzer Forest
	{ [EnemyModifierNames.s.HealthMult] = 0.66, [EnemyModifierNames.s.DungeonTierDamageMult] = 0.66 }, --Bandicoot Swamp
	{ [EnemyModifierNames.s.HealthMult] = 1.00, [EnemyModifierNames.s.DungeonTierDamageMult] = 1.00 }, --Thatcher Swamp
	{ [EnemyModifierNames.s.HealthMult] = 1.33, [EnemyModifierNames.s.DungeonTierDamageMult] = 1.33 },
	{ [EnemyModifierNames.s.HealthMult] = 1.66, [EnemyModifierNames.s.DungeonTierDamageMult] = 1.66 },
	{ [EnemyModifierNames.s.HealthMult] = 2.00, [EnemyModifierNames.s.DungeonTierDamageMult] = 2.00 },
	{ [EnemyModifierNames.s.HealthMult] = 2.33, [EnemyModifierNames.s.DungeonTierDamageMult] = 2.33 },
	{ [EnemyModifierNames.s.HealthMult] = 2.66, [EnemyModifierNames.s.DungeonTierDamageMult] = 2.66 },
	{ [EnemyModifierNames.s.HealthMult] = 3.00, [EnemyModifierNames.s.DungeonTierDamageMult] = 3.00 },
	{ [EnemyModifierNames.s.HealthMult] = 3.33, [EnemyModifierNames.s.DungeonTierDamageMult] = 3.33 },
}
Strict.strictify(DungeonTierModifierSource)

-- Enemy modifier tables keyed by ascension level.
-- Remember that ascension level starts at 0. Ascension 0 is NOT represented in this table.

-- Here's a spreadsheet to help sketch these numbers:
-- https://docs.google.com/spreadsheets/d/1hK80TeeUqjxuqK9M6RkYY5AR_XNrRaiiOKnRBtp64ss/edit#gid=0
local AscensionModifierSource = {
	-- The boss in Dungeon1 Frenzy1 should be about as strong as the boss in Dungeon2 Frenzy0.
	-- Boss D[n]F1 roughly == Boss D[n+1]F0

	{ -- Ascension 1
		-- Basic Health/Damage Modifiers:
		-- Elites are already being added in this, so we don't need to change these values too much to add more difficulty and health-loss due to attrition while moving room to room.
		-- We also do not want to scare players away from frenzies, so keep this a bit softer.

		-- Equipment for UpgradeLevel1, or the next dungeon == +0.33
		[EnemyModifierNames.s.BasicHealthMult] = 0.2,
		[EnemyModifierNames.s.DungeonTierDamageMult] = 0.2,

		-- However, since there is only one Boss and only one Miniboss, we can increase them a bit more so this change is more noticeable.
		[EnemyModifierNames.s.BossHealthMult] = 0.35,
		[EnemyModifierNames.s.MinibossHealthMult] = 0.8, -- The miniboss fight is typically simpler, so let's give them a lot more health to let the encounter be juicier. Make sure the encounter feels like a "miniboss fight" and not just a "pretty hard mob"

		[EnemyModifierNames.s.InitialCooldownMult] = -0.25,

		-- Star of the show: Enable Elite mobs, which present all new mechanics to learn for every mob.
		[EnemyModifierNames.s.EliteChance] = 0.25,
	},

	{ -- Ascension 2
		-- Equipment for UpgradeLevel2, or two dungeons from now == +0.66. Push "damage dealt" a bit farther.
		[EnemyModifierNames.s.BasicHealthMult] = 0.25, -- add last Ascension,  0.45 total
		[EnemyModifierNames.s.DungeonTierDamageMult] = 0.35, -- add last Ascension,  0.55 total

		[EnemyModifierNames.s.BossHealthMult] = 0.5,
		[EnemyModifierNames.s.MinibossHealthMult] = 0.8,

		-- Star of the show: Introduce cooldown modifiers -- make all mobs more aggressive. This should be noticeable.
		[EnemyModifierNames.s.CooldownMult] = -0.4,
		[EnemyModifierNames.s.CooldownMinMult] = -0.6,
		[EnemyModifierNames.s.InitialCooldownMult] = -0.25,
		[EnemyModifierNames.s.EliteCooldownMult] = -0.4,
		[EnemyModifierNames.s.EliteCooldownMinMult] = -0.6,
		[EnemyModifierNames.s.EliteInitialCooldownMult] = -0.5,
		[EnemyModifierNames.s.BossCooldownMult] = -0.3, -- Some bosses already have 0 cooldown. This can't be a "star of the show".
		[EnemyModifierNames.s.BossCooldownMinMult] = -0.5,
		[EnemyModifierNames.s.BossInitialCooldownMult] = -0.5,

		[EnemyModifierNames.s.EliteChance] = 0.2,
		[EnemyModifierNames.s.EliteSpawnCount] = 3,
	},

	-- NOV2023: This is currently our "final ascension", so make this a bit chunkier for now to provide a difficult goal for skilled players.
	{ -- Ascension 3
		-- Equipment for UpgradeLevel2, or two dungeons from now == +0.66.
		-- Using equipment 3 dungeons from now would be +1.0.
		[EnemyModifierNames.s.BasicHealthMult] = 0.35, -- add last Ascension, 0.8 total
		[EnemyModifierNames.s.DungeonTierDamageMult] = 0.45, -- add last Ascension, 1.0 total

		[EnemyModifierNames.s.BossHealthMult] = 0.5,
		[EnemyModifierNames.s.MinibossHealthMult] = 0.8,

		-- Continue adjusting cooldowns by a small amount. Not as noticeable, subtle silent shift.
		-- By this point, initial cooldowns are 0.
		[EnemyModifierNames.s.CooldownMult] = -0.1,
		[EnemyModifierNames.s.CooldownMinMult] = -0.2,
		[EnemyModifierNames.s.InitialCooldownMult] = -0.5,
		[EnemyModifierNames.s.EliteCooldownMult] = -0.1,
		[EnemyModifierNames.s.EliteCooldownMinMult] = -0.2,
		[EnemyModifierNames.s.EliteInitialCooldownMult] = -0.5,
		[EnemyModifierNames.s.BossCooldownMult] = -0.1,
		[EnemyModifierNames.s.BossCooldownMinMult] = -0.2,
		[EnemyModifierNames.s.BossInitialCooldownMult] = -0.5,

		[EnemyModifierNames.s.StartupFramesMult] = -0.25,
		[EnemyModifierNames.s.EliteStartupFramesMult] = -0.25,
		[EnemyModifierNames.s.BossStartupFramesMult] = -0.25, -- Consider cranking this up.

		-- Star of the show: Convert more Normal mobs into Elite mobs. There should be a *lot* of Elites in this Ascension.
		[EnemyModifierNames.s.EliteChance] = 0.1,
		[EnemyModifierNames.s.EliteSpawnCount] = 8,
	},
}
Strict.strictify(AscensionModifierSource)

-- TODO: modify miniboss health based on multiplayer count -- give them more health than normal scaled enemies because they will be focused so hard
local ENEMY_MULTIPLAYER_MODS =
{
	-- Enemy modifier tables keyed by player count (from 1P to 4P).
	-- SpawnCount reasoning:
	-- 		2 PLAYERS
	--			1 mobs * 1.25 =  1.25		1 -> 1
	--			2 mobs * 1.25 =  2.5		2 -> 2 or 3
	--			3 mobs * 1.25 =  3.75		3 -> 4
	--			4 mobs * 1.25 =  5			4 -> 5
	--		3 PLAYERS
	--			1 mobs * 1.5 =  1.5			1 -> 1 or 2
	--			2 mobs * 1.5 =  3			2 -> 3
	--			3 mobs * 1.5 =  4.5			3 -> 4 or 5
	--			4 mobs * 1.5 =  6			4 -> 6
	--		4 PLAYERS
	--			1 mobs * 1.75 =  1.75		1 -> 2
	--			2 mobs * 1.75 =  3.5		2 -> 3 or 4
	--			3 mobs * 1.75 =  5.25		3 -> 5
	--			4 mobs * 1.75 =  7			4 -> 7
	BASIC = {
		{},
		{ [EnemyModifierNames.s.SpawnCountMult] = 0.25, [EnemyModifierNames.s.StationarySpawnCountMult] = 0.25 },
		{ [EnemyModifierNames.s.SpawnCountMult] = 0.50, [EnemyModifierNames.s.StationarySpawnCountMult] = 0.50 },
		{ [EnemyModifierNames.s.SpawnCountMult] = 0.50, [EnemyModifierNames.s.StationarySpawnCountMult] = 0.50, [EnemyModifierNames.s.HealthMult] = 0.25 }, -- Be careful spawning too many mobs, since this will get out of hand.
	},

	MINOR = {
		{ [EnemyModifierNames.s.HealthMult] = 0.0 },
		{ [EnemyModifierNames.s.HealthMult] = 0.5 },
		{ [EnemyModifierNames.s.HealthMult] = 0.5, [EnemyModifierNames.s.SpawnCountMult] = 0.50, [EnemyModifierNames.s.StationarySpawnCountMult] = 0.50 },
		{ [EnemyModifierNames.s.HealthMult] = 1.2, [EnemyModifierNames.s.SpawnCountMult] = 0.50, [EnemyModifierNames.s.StationarySpawnCountMult] = 0.50 },
	},

	MAJOR = {
		{ [EnemyModifierNames.s.HealthMult] = 0.0 },
		{ [EnemyModifierNames.s.HealthMult] = 1.0 },
		{ [EnemyModifierNames.s.HealthMult] = 1.5, [EnemyModifierNames.s.SpawnCountMult] = 0.50, [EnemyModifierNames.s.StationarySpawnCountMult] = 0.50 },
		{ [EnemyModifierNames.s.HealthMult] = 2.0, [EnemyModifierNames.s.SpawnCountMult] = 0.50, [EnemyModifierNames.s.StationarySpawnCountMult] = 0.50 },
	},

	SWARM = {
		{ [EnemyModifierNames.s.SpawnCountMult] = 0.00 },
		{ [EnemyModifierNames.s.SpawnCountMult] = 0.25, [EnemyModifierNames.s.StationarySpawnCountMult] = 0.25 },
		{ [EnemyModifierNames.s.SpawnCountMult] = 0.25, [EnemyModifierNames.s.StationarySpawnCountMult] = 0.25 },
		{ [EnemyModifierNames.s.SpawnCountMult] = 0.50, [EnemyModifierNames.s.StationarySpawnCountMult] = 0.50 },
	},

	ELITE = {
		{ [EnemyModifierNames.s.HealthMult] = 0.00 },
		{ [EnemyModifierNames.s.HealthMult] = 1.25 },
		{ [EnemyModifierNames.s.HealthMult] = 1.75 },
		{ [EnemyModifierNames.s.HealthMult] = 2.25, [EnemyModifierNames.s.SpawnCountMult] = 0.50, [EnemyModifierNames.s.StationarySpawnCountMult] = 0.50 },
	},

	MINIBOSS = {
		{ [EnemyModifierNames.s.HealthMult] = 0.0 },
		{ [EnemyModifierNames.s.HealthMult] = 2.0 },
		{ [EnemyModifierNames.s.HealthMult] = 3.0 },
		{ [EnemyModifierNames.s.HealthMult] = 4.0 },
	},

	-- By setting Health multipliers here rather than BossHealth, we allow this BOSS tuning
	-- table to be used by non-Boss enemies (for better or worse).
	BOSS = {
		{ [EnemyModifierNames.s.HealthMult] = 0.00 },
		{ [EnemyModifierNames.s.HealthMult] = 1.5  },
		{ [EnemyModifierNames.s.HealthMult] = 2.0  },
		{ [EnemyModifierNames.s.HealthMult] = 2.5  },
	},
}

local ASCENSION_ALLOWABLE_ELITES =
{
	-- Ascension 1, only allow small mobs to be elite.
	{ "BASIC", "SWARM" },

	-- Ascension 2, let some bigger mobs become elite.
	{ "MINOR" },

	-- Ascension 3, let MAJORs become elites, which will allow the miniboss to spawn.
	{ "MAJOR" },
}

-- Verify that all of our types are elite-able, in case we add more types.
for type,_ in pairs(ENEMY_MULTIPLAYER_MODS) do
	-- Don't worry about elites or boss
	if type ~= "ELITE" and type ~= "BOSS" and type ~= "MINIBOSS" then

		local found = false

		for _, tbl in ipairs(ASCENSION_ALLOWABLE_ELITES) do
			if Lume.find(tbl, type) then
				found = true
				break
			end
		end

		assert(found, string.format("[%s] is not found in ASCENSION_ALLOWABLE_ELITES. If you add a new type to ENEMY_MULTIPLAYER_MODS, please ask about where to slot it into ascensions!", type))
	end
end

-- Item levels are closely related to dungeon tiers. Items found in a dungeon will have item levels equal to, or
-- slightly greater than, the dungeon tier.

-- Enumerate the modifiers that can be applied to player attributes. Note that different sources (e.g. weapon, armour)
-- may apply them.
local PlayerModifierNames = Enum {
	"AmmoMult",
	"CritChance",
	"CritDamageMult",
	"DamageMult",
	"FocusMult",
	"Luck",
	"RollVelocityMult",
	"SpeedMult",
	"DungeonTierDamageReductionMult",
}

local PLAYER_MODIFIER_DEFAULTS = {}
for _, modifier in ipairs(PlayerModifierNames:Ordered()) do
	PLAYER_MODIFIER_DEFAULTS[modifier] = 1
end
PLAYER_MODIFIER_DEFAULTS[PlayerModifierNames.s.Luck] = 0
PLAYER_MODIFIER_DEFAULTS[PlayerModifierNames.s.CritChance] = 0
PLAYER_MODIFIER_DEFAULTS[PlayerModifierNames.s.FocusMult] = 0
PLAYER_MODIFIER_DEFAULTS[PlayerModifierNames.s.SpeedMult] = 0
PLAYER_MODIFIER_DEFAULTS[PlayerModifierNames.s.CritDamageMult] = 0
PLAYER_MODIFIER_DEFAULTS[PlayerModifierNames.s.DungeonTierDamageReductionMult] = 0
Strict.strictify(PLAYER_MODIFIER_DEFAULTS)

-- Weapon modifier tables keyed by item level.
-- Note: Right now, WeaponMultiplier.s.DamageMult here is matched to EnemyModifiers.s.HealthMult in DungeonTierModifiers.
local WeaponILvlModifierSource = {
	-- These damage values also get modified by WeaponWeightModifierSource and WeaponRarityModifierSource below.

	-- The number below represents a Normal weapon, "balanced" relative to the dungeon's Mob HealthMult.
	-- A Light weapon will be slightly below "balanced", and a Heavy weapon will be slightly above "balanced".

	-- If those numbers are equal, then the weapon for that dungeon will exactly keep pace with the mob scaling.

	-- TUNING INTENTION: Always be slightly behind the curve by roughly how much HEAVY armour gives.
	{ [PlayerModifierNames.s.DamageMult] = 0.15 }, 	-- First dungeon will have 0.00 bonus in health, so this is just purely an improvement, not catch-up.
													-- That relationship changes now:
	{ [PlayerModifierNames.s.DamageMult] = 0.28 }, 	-- 0.33    Owlitzer
	{ [PlayerModifierNames.s.DamageMult] = 0.60 }, 	-- 0.66   Bandicoot
	{ [PlayerModifierNames.s.DamageMult] = 0.95 },	-- 1.00    Thatcher
	{ [PlayerModifierNames.s.DamageMult] = 1.28 }, 	-- 1.33
	{ [PlayerModifierNames.s.DamageMult] = 1.60 }, 	-- 1.66
	{ [PlayerModifierNames.s.DamageMult] = 1.95 }, 	-- 2.00
	{ [PlayerModifierNames.s.DamageMult] = 1.28 }, 	-- 2.33
	{ [PlayerModifierNames.s.DamageMult] = 2.60 }, 	-- 2.66
	{ [PlayerModifierNames.s.DamageMult] = 2.95 }, 	-- 3.00
	{ [PlayerModifierNames.s.DamageMult] = 2.28 }, 	-- 3.33
}

local WeaponWeightModifierSource = {
	-- Light Weapons do slightly less damage, Heavy Weapons do slightly more damage.
	[Weight.EquipmentWeight.s.Light] =
	{
		[PlayerModifierNames.s.DamageMult] = -0.05
	},
	[Weight.EquipmentWeight.s.Normal] =
	{
		[PlayerModifierNames.s.DamageMult] = 0,
	},
	[Weight.EquipmentWeight.s.Heavy] =
	{
		[PlayerModifierNames.s.DamageMult] = 0.05,
	},
}
local WeaponRarityModifierSource = {
	-- Rarity of the weapon slightly affects the damage output.
	[ITEM_RARITY.s.COMMON] =
	{
		[PlayerModifierNames.s.DamageMult] = -0.15, -- MAKE THIS MATCH ILVL=1's DAMAGEMULT
	},
	[ITEM_RARITY.s.UNCOMMON] =
	{
		[PlayerModifierNames.s.DamageMult] = 0,
	},
	[ITEM_RARITY.s.EPIC] =
	{
		[PlayerModifierNames.s.DamageMult] = 0.05,
	},
	-- These don't exist yet:
	[ITEM_RARITY.s.LEGENDARY] =
	{
		[PlayerModifierNames.s.DamageMult] = 0.1,
	},
	[ITEM_RARITY.s.TITAN] =
	{
		[PlayerModifierNames.s.DamageMult] = 0.15,
	},
}
-- Armour modifier tables keyed by item level.
-- Note: Right now, ArmourModifiers.s.DungeonTierDamageReductionMult here is matched to CombatModifiers.s.DungeonTierDamageMult in
-- DungeonTierModifiers.

-- Spreadsheet to help sketch these numbers: https://docs.google.com/spreadsheets/d/15grup3aGw-N0WyFkQ9LITqLSyldMmtSbJ4SQOCSNEvw/edit#gid=0

local ArmourILvlModifierSource = {
	-- These are further modified by ArmourWeightModifierSource and ArmourRarityModifierSource below.
	-- A full set of Normal Armour of a given dungeon should result in this damage reduction, which is tuned in relation to the enemy's damage increase.
	-- A full set of Light Armour will be slightly below this, and a full set of Heavy Armour will be slightly above this.
	-- In addition, there are 3 tiers of Rarity within a dungeon: Common, Uncommon, and Epic. This will further adjust.

	-- TUNING INTENTION: Always be slightly behind the curve by roughly how much HEAVY weapon gives.
	{ [PlayerModifierNames.s.DungeonTierDamageReductionMult] = 0.15 },  -- First dungeon we start under the curve with 0.0 damage reduction, while they have 0.15 damage. Buying this lets you catch up and even out.

																		-- That relationship changes now:
	{ [PlayerModifierNames.s.DungeonTierDamageReductionMult] = 0.28 },  -- 0.33   Owlitzer
	{ [PlayerModifierNames.s.DungeonTierDamageReductionMult] = 0.60 },  -- 0.66   Bandicoot
	{ [PlayerModifierNames.s.DungeonTierDamageReductionMult] = 0.95 },  -- 1.00   Thatcher
	{ [PlayerModifierNames.s.DungeonTierDamageReductionMult] = 1.28 },  -- 1.33
	{ [PlayerModifierNames.s.DungeonTierDamageReductionMult] = 1.60 },  -- 1.66
	{ [PlayerModifierNames.s.DungeonTierDamageReductionMult] = 1.95 },  -- 2.00
	{ [PlayerModifierNames.s.DungeonTierDamageReductionMult] = 1.28 },  -- 2.33
	{ [PlayerModifierNames.s.DungeonTierDamageReductionMult] = 2.60 },  -- 2.66
	{ [PlayerModifierNames.s.DungeonTierDamageReductionMult] = 2.95 },  -- 3.00
	{ [PlayerModifierNames.s.DungeonTierDamageReductionMult] = 2.28 },   -- 3.33
}

local ArmourWeightModifierSource = {
	[Weight.EquipmentWeight.s.Light] =
	{
		[PlayerModifierNames.s.DungeonTierDamageReductionMult] = -0.05,
	},
	[Weight.EquipmentWeight.s.Normal] =
	{
		[PlayerModifierNames.s.DungeonTierDamageReductionMult] = 0,
	},
	[Weight.EquipmentWeight.s.Heavy] =
	{
		[PlayerModifierNames.s.DungeonTierDamageReductionMult] = 0.15,
	},
}

local ArmourRarityModifierSource = {
	-- Rarity of the armour slightly affects the damage reduction.
	[ITEM_RARITY.s.COMMON] =
	{
		[PlayerModifierNames.s.DungeonTierDamageReductionMult] = -0.15, -- Just to undo the first ilvl amount
	},
	[ITEM_RARITY.s.UNCOMMON] =
	{
		[PlayerModifierNames.s.DungeonTierDamageReductionMult] = 0,
	},
	[ITEM_RARITY.s.EPIC] =
	{
		[PlayerModifierNames.s.DungeonTierDamageReductionMult] = 0.1,
	},
	[ITEM_RARITY.s.LEGENDARY] =
	{
		[PlayerModifierNames.s.DungeonTierDamageReductionMult] = 0.1,
	},
	[ITEM_RARITY.s.TITAN] =
	{
		[PlayerModifierNames.s.DungeonTierDamageReductionMult] = 0.15,
	},
}

local default_vision_tuning =
{
	retarget_period = 1,
	aggro_range = 20,
	too_far_retarget = 1000, -- If this is lower than aggro_range, you can walk away from an enemy to make it lose its target and disengage from battle.
	retarget_range = 55,     -- If you have a target, and the target is farther away than this, allow switching to a more nearby target. (use 'too_near_switch_target')
	too_near_switch_target = 25, -- If there is a possible target within this range, and your existing target is further away than 'retarget_range'
	share_target_range = 50,
	share_target_tags = { "mob" },
	share_not_target_tags = { "INLIMBO" },
}
local elite_vision_tuning =
{
	retarget_period = 1,
	aggro_range = 70,
	too_far_retarget = 1000, -- If this is lower than aggro_range, you can walk away from an enemy to make it lose its target and disengage from battle.
	retarget_range = 60,     -- If you have a target, and the target is farther away than this, allow switching to a more nearby target. (use 'too_near_switch_target')
	too_near_switch_target = 25, -- If there is a possible target within this range, and your existing target is further away than 'retarget_range'
	share_target_range = 55,
	share_target_tags = { "mob" },
	share_not_target_tags = { "INLIMBO" },
}

local HitStunPressureFrames =
{
	LOW = 30,
	MEDIUM = 50,
	HIGH = 70,
}

local function GetLastPlayerCount()
	return TheDungeon:GetDungeonMap():GetLastPlayerCount() or 1
end

-- Merge tables of modifiers. 'modifiers' itself is an array-like tables of keys.
-- The mergeable tables are dict-like tables keyed by the modifiers.
-- (This is like Lume:sum(), but filtered against explicit keys).
function ResolveModifiers(modifiers, ...)
	local merged = {}
	local arg_count = select("#", ...)
	for _, modifier in ipairs(modifiers) do
		local sum = 0
		for i = 1, arg_count do
			local tuning = select(i, ...)
			local value = tuning[modifier]
			if value then
				sum = sum + value
			end
		end
		merged[modifier] = sum
	end
	Strict.strictify(merged)
	return merged
end

local function BuildTuning()
    local Tuning = {
		-- 60Hz, hit shudder was expressed in ticks, is now anim frames
        HITSHUDDER_AMOUNT_LIGHT = 6,
        HITSHUDDER_AMOUNT_MEDIUM = 8,
        HITSHUDDER_AMOUNT_HEAVY = 12,

        PUSHBACK_DISTANCE_DEFAULT = 0.2,

        PLAYER_POSTHIT_IFRAMES = 8, -- NOTE: This kicks in -after- hitstop and hitstun is over. The entirety of hitstop/hitstun is invincible.
        PLAYER_HEALTH = 900,
        PLAYER_LUCK = 0.01,
        PLAYER_HITBOX_SIZE = 0.6, -- NOTE: Although the hitbox is printed in 2d on the floor, our hitboxes have to represent verticality, too. Size this based on the player's body, not just the position of the box around the feet.

		CRIT_PUSHBACK_MULT = 1,
		CRIT_HITSTOP_EXTRA_FRAMES = 2, -- expressed as anim frames

        HITSTOP_TO_PLAYER_EXTRA_FRAMES = 1, -- expressed as anim frames
		HITSTOP_PLAYER_QUICK_RISE_FRAMES = 2,
		HITSTOP_PLAYER_KILL_DELAY_FRAMES = 1, --when a player gets killed, how many anim frames should we wait before applying kill hitstop?
		HITSTOP_BOSS_KILL_DELAY_FRAMES = 2, --when a boss gets killed, how many anim frames should we wait before applying kill hitstop?

		HITSTOP_LAST_KILL_EXTRA_FRAMES = 5, -- expressed as anim frames
		LAST_KILL_DELTATIME_MULTIPLIER = 0.5, -- When we kill the last enemy in the room, how slow should our animstate move?
		LAST_KILL_DELTATIME_MULTIPLIER_FRAMES = 15, -- When we kill the last enemy in the room, for how many frames should our animstate slow?

        POTION_HOLD_TICKS = 0, -- Number of frames the player has to hold the "potion" button before we start to execute the potion drink. Prevents accidental presses.
        POTION_AOE_RANGE = 6, -- When a player drinks a potion, in what range should it heal friendlies?
        POTION_AOE_PERCENT = 0.4, -- When a player drinks a potion, what % of the self-heal should be applied to friendlies?

        REVIVE_TIME = 2,
        REVIVE_HEALTH_PERCENT = 0.4,
        REVIVE_HEALTH_DONATION_ASCENSION_LEVEL = 2,

        ENEMY_FRIENDLY_FIRE_DAMAGE_MULTIPLIER = 1/3, -- When an enemy deals damage to another enemy how much should the damage be affected?

        GEM_DEFAULT_UPDATE_THRESHOLDS =
		{
			-- percentage of a level completed -- stored on creation of a gem with an associated bool for whether that threshold has been updated or not
			0.85,
			0.75,
			0.5,
			0.25,
			0.01, -- Basically, update the first time it happens
		},

		DEFAULT_MINIMUM_COOLDOWN = 2,

		PLAYER =
		{
			HIT_STREAK =
			{
				BASE_DECAY = 1.2,
				KILL_BONUS = 0.3,
				FOCUS_KILL_BONUS = 0.4,
				MAX_TIME = 1.65,
			},

			ROLL =
			{
				NORMAL =
				{
					IFRAMES = 12,
					DISTANCE = 3,
					LENGTH_ANIMFRAMES = 9,
				},
				LIGHT =
				{
					IFRAMES = 7,
					DISTANCE = 4.5,
					LENGTH_ANIMFRAMES = 5,
				},
				HEAVY =
				{
					IFRAMES = 10,
					DISTANCE = 2.7,
					LENGTH_ANIMFRAMES = 11,
				},
			},

			POTION_HOLD_REQUIREMENT_FRAMES = 5, -- How many frames does the player have to hold the 'potion' button before we accept that they wanted to drink. Used to prevent accidental drinks.
		},

		FLICKERS = -- Separating these out for easy access for a possible epilepsy-disabling mode
		{
			PLAYER_QUICK_RISE =
			{
				COLOR = { 170/255, 170/255, 170/255 },
				FLICKERS = 4,
				FADE = true,
				TWEENS = true,
			},
			BOMB_WARNING =
			{
				COLOR = { 204/255, 128/255, 204/255 },
				FLICKERS = 14,
				FADE = false,
				TWEENS = false,
			},
			SPIKE_WARNING =
			{
				COLOR = { 179/255, 51/255, 179/255 },
				FLICKERS = 4,
				FADE = false,
				TWEENS = false,
			},
			WEAPONS =
			{
				HAMMER =
				{
					CHARGE_COMPLETE =
					{
						COLOR = { 180/255, 180/255, 180/255, 1 },
						FLICKERS = 2,
						FADE = false,
						TWEENS = false,
					},
					FOCUS_SWING =
					{
						COLOR = { 0/255, 150/255, 190/255, .5 },
					},
				},
			},
			POWERS =
			{
				MULLIGAN = -- Player has iframes during this flicker
				{
					COLOR = { 90/255, 30/255, 90/255 },
					FLICKERS = 10,
					FADE = true,
					TWEENS = false,
				},
			},
		},

		BLINK_AND_FADES = -- Separating these out for easy access for a possible epilepsy-disabling mode
		{
			-- "FRAMES" IS ANIMATION FRAMES
			PLAYER_DEATH =
			{
				-- This happens after hitstop has finished
				-- On impact, immediately jump to this colour, then after the hitstop has finished, release the colour with this frame count as a fade
				COLOR = { 230/255, 160/255, 200/255 },
				FRAMES = 4,
			},

			POWER_DROP_KONJUR_PROXIMITY =
			{
				-- This is when the player touches the konjur blob, right before it bursts
				COLOR = { 100/255, 100/255, 100/255 },
				FRAMES = 4,
			},
		},

		KONJUR_ON_SKIP_SKILL = 35, --
		KONJUR_ON_SKIP_POWER = 35, -- Konjur given by skipping a power should be less than konjur given by choosing a "Konjur Reward" room. See konjurreward.lua
								   -- Also consider the amount a potion costs, currently 75K. Should one relic skip == a free potion? Skipping power should be "damn, I should have gone for Konjur Reward!" not rewarding itself
		KONJUR_ON_SKIP_POWER_FABLED = 100, -- comparable reward here is a Hard Konjur Reward, which is currently tuned as 130-170. Be less than that.

        POWERS =
        {
			DROP_SPAWN_INITIAL_DELAY_FRAMES = 1 * SECONDS, -- After the last enemy is killed in a room, how long should we wait before spawning the power drop? Give the player some time to process the final kill.
			DROP_SPAWN_SEQUENCE_DELAY_FRAMES_FABLED = 0.5 * SECONDS, -- When spawning multiple power drops (fabled relics), how much delay should exist between the two spawning?
			DROP_SPAWN_SEQUENCE_DELAY_FRAMES_PLAIN = 0.3 * SECONDS,

			DROP_CHANCE = -- starting drop chances
			{
			    COMMON = 80,
			    EPIC = 20,
			    LEGENDARY = 0,
			},

			DROP_CHANCE_INCREASE = -- when these types are not rolled, how much more likely should seeing one of them become next roll? measured in %
			{
				{ -- difficulty "1/ tutorial" rooms
					COMMON = 0,
					EPIC = 2,
					LEGENDARY = 1
				},
				{  -- difficulty "2/ easy" rooms
					COMMON = 0,
					EPIC = 2,
					LEGENDARY = 1
				},
				{  -- difficulty "3/ hard" rooms
					COMMON = 0,
					EPIC = 8,
					LEGENDARY = 4
				},
			},

			UPGRADE_PRICE =
			{
				COMMON = 75, -- Common to Epic
				EPIC = 150, -- Epic to Legendary
			},

			FABLED_ROOM_NORMAL_CHANCE = -- when spawning the Normal Relic within a fabled power room, what chance of Epic and Legendary should there be? This number stays static, does not adjust over time.
			{
				EPIC = 50,
				COMMON = 30,
				LEGENDARY = 20,
			},
        },

        GEAR =
        {
        	MINIMUM_DUNGEONTIER_DAMAGE_MULT = 0.5, -- When combining the Extra Damage that a mob wants to do based on its DungeonTier+AscensionLevel, with the Damage Reduction that an Armour wants to apply based on its DungeonTier+UpgradeLevel, what is the lowest multiplier we allow?
        										   -- If this == 0, then it means players can equip enough armor that they reduce incoming damage to 0.

			STAT_ALLOCATION_PER_SLOT =
			{
				-- When we tune armour sets, we want to tune for how much the entire set should give you.
				-- If an armour set is meant to give 10% Damage Reduction, how should that 10% be divvied out across the pieces?
				BODY = 0.5,
				WAIST = 0.25,
				HEAD = 0.25,
			},

			WEAPONS =
	        {
				BASE_FOCUS_DAMAGE_MULT = 1,
				BASE_CRIT_DAMAGE_MULT = 2,

				HAMMER =
				{
					BASE_DAMAGE = 60,
					BASE_CRIT = 0.01,
				},
				POLEARM =
				{
					BASE_DAMAGE = 50,
					BASE_CRIT = 0.01,
				},
				CANNON =
				{
					BASE_DAMAGE = 60,
					BASE_CRIT = 0.01,
					ROLL_VELOCITY = 11,
					AMMO = 6,
					DEFAULT_FOCUS_SEQUENCE =
					{
						-- Of a given clip, which shots are FOCUS shots and which are NORMAL shots?
						[1] = true,
						[2] = true,
						[3] = true,
						[4] = false,
						[5] = false,
						[6] = false,
					},
					DEFAULT_MORTAR_FOCUS_SEQUENCE =
					{
						-- When doing a Mortar with X ammo remaining, at what point does it become focus?
						[1] = true,
						[2] = true,
						[3] = true,
						[4] = false,
						[5] = false,
						[6] = false,
					},
				},
				SHOTPUT =
				{
					-- Normal  DISTANCE = 3,
					-- Light DISTANCE = 4.5,
					-- Heavy DISTANCE = 2.25,
					BASE_DAMAGE = 75,
					BASE_CRIT = 0.01,
					ROLL_DISTANCE_OVERRIDE =
					{
						-- Make Normal a bit faster to make mobility better when having no ball / trying to line up ball shots
						-- Make Light a bit slower so that it's easier to steer
						-- Make Heavy a bit faster so it's easier to actually do Ball stuff
						NORMAL = 3.6,
						LIGHT = 4.25,
						HEAVY = 2.5,
					},
					AMMO = 2,
					REBOUND_HITBOX_RADIUS = 2,
				},
				CLEAVER =
				{
					BASE_DAMAGE = 100,
					BASE_CRIT = 0.05,
				},
	        },
        },

        MONSTER_RESEARCH =
        {
			RARITY_TO_EXP =
			{
				[ITEM_RARITY.s.UNCOMMON] = 10,
				[ITEM_RARITY.s.EPIC] = 30,
				[ITEM_RARITY.s.LEGENDARY] = 50,
			},
        },

        TRAPS =
        {
			DAMAGE_TO_PLAYER_MULTIPLIER = 1/3,

			trap_spike =
			{
				BASE_DAMAGE = 300,
				COLLISION_DATA = nil,
				HEALTH = nil,
			},
			trap_exploding =
			{
				BASE_DAMAGE = 500,
				COLLISION_DATA =
				{
					SIZE = .5,
					MASS = 1000000000000,
					COLLISIONGROUP = COLLISION.SMALLOBSTACLES,
					COLLIDESWITH = { COLLISION.CHARACTERS, COLLISION.ITEMS, COLLISION.GIANTS }
				},
				HEALTH = 1,
				WARNING_COLORS =
				{
					{0, 0, 0, 0},
					{140/255, 20/255, 100/255, 1},
					{255/255, 170/255, 200/255, 1},
				}
			},
			trap_zucco = {
				BASE_DAMAGE = 200,
			},
			trap_bananapeel = {
				BASE_DAMAGE = 0, -- This trap only applies a knockdown
			},
			trap_spores = {
				BASE_DAMAGE = 0, -- Most spores do 0 damage and only apply an effect.
				DAMAGE_VERSION_BASE_DAMAGE = 300, -- How much damage the DAMAGE spores do
				DAMAGE_VERSION_BASE_HEAL = 300, -- How much healing the HEAL spores do
				HEALTH = 1,
				COLLISION_DATA =
				{
					SIZE = .5,
					MASS = 1000000000000,
					COLLISIONGROUP = COLLISION.SMALLOBSTACLES,
					COLLIDESWITH = { }
				},
				VARIETIES =
				{
					trap_spores_juggernaut =
					{
						power = "juggernaut",
						stacks = 25,
						burst_fx = "fx_spores_juggernaut_all",
						target_fx = "spore_hit_juggernaut"
					},

					trap_spores_smallify =
					{
						power = "smallify",
						stacks = 1,
						burst_fx = "fx_spores_shrink_all",
						target_fx = "spore_hit_shrink"
					},

					trap_spores_shield =
					{
						power = "shield",
						stacks = 4,
						burst_fx = "fx_spores_shield_all",
						target_fx = "spore_hit_shield"
					},

					trap_spores_confused =
					{
						power = "confused",
						stacks = 4,
						burst_fx = "fx_spores_confused_all",
						target_fx = "spore_hit_confused"
					},

					trap_spores_heal =
					{
						power = "override",
						override_effect = "heal", -- Amount of healing is in TUNING.TRAPS.trap_spores, scaled down *1/3 against players
						burst_fx = "fx_spores_heal_all",
						target_fx = "spore_hit_heal",
						disable_hit_reaction = true,
					},

					trap_spores_damage =
					{
						power = "override",
						override_effect = "damage", -- Amount of damage is in TUNING.TRAPS.trap_spores, scaled down *1/3 against players
						burst_fx = "fx_spores_damage_all",
						target_fx = "spore_hit_damaged"
					},

					trap_spores_groak =
					{
						power = "override",
						override_effect = "summon_groak", -- Amount of damage is in TUNING.TRAPS.trap_spores, scaled down *1/3 against players
						burst_fx = "fx_spores_groak_all",
					},
				}
			},

			trap_acid = {
				BASE_DAMAGE = 30,
				TOXICITY_STACKS_PER_TICK = 10 + 32, -- Damage is dealt at 1000 stacks, account for the decay which is 10 every tick (1000 / (stacks - decay)) * 0.016
				KNOCKDOWN_STACKS_MULT = 1.5, -- Multiply amount of stacks per tick if lying in the acid
				AURA_APPLYER = true,
				MOB_PERCENT_DAMAGE = 0.06,
				MOB_MAX_DAMAGE = 70
			},

			-- Permanent acid spawned in the Thatcher room
			trap_acid_stage = {
				BASE_DAMAGE = 30,
				TOXICITY_STACKS_PER_TICK = 10 + 32, -- Damage is dealt at 1000 stacks, account for the decay which is 10 every tick (1000 / (stacks - decay)) * 0.016
				KNOCKDOWN_STACKS_MULT = 1.5, -- Multiply amount of stacks per tick if lying in the acid
				AURA_APPLYER = true,
				MOB_PERCENT_DAMAGE = 0.06,
				MOB_MAX_DAMAGE = 70
			},

			trap_acidgeyser = {
				BASE_DAMAGE = 0,
			},

			trap_windtotem = {
				BASE_DAMAGE = 0,
				AURA_APPLYER = true,
				AURA_DATA =
				{
					effect = "windtotem_wind",
					beamhitbox = { -0.5, 50, 3.00 },
				},
			},

			trap_thorns =
			{
				BASE_DAMAGE = 60,
				COLLISION_DATA =
				{
					SIZE = 1.2,
					MASS = 1000000000000,
					COLLISIONGROUP = COLLISION.OBSTACLES,
					COLLIDESWITH = { COLLISION.CHARACTERS, COLLISION.ITEMS }
				},
				HEALTH = nil,
			},

			swamp_stalactite =
			{
				BASE_DAMAGE = 400,
				HEALTH = 200,
				fx = { "hit_stalag", "hit_konjur" },
			},

			swamp_stalagmite =
			{
				HEALTH = 200,
				fx = { "hit_stalag", "hit_konjur" },
			},

			trap_stalactite = {
				BASE_DAMAGE = 0,
			},

			owlitzer_spikeball = {
				BASE_DAMAGE = 40
			},

			tundra_torch =
			{
				HEAT_POINTS = 10,
				STAY_HEAT_TIME = 10,
				COOLDOWN = 0.2, -- Per second
			},
        },

		player = {
			run_speed = PLAYER_MOVE_SPEED_MOD * 8,
			attack_angle_clamp = 60, -- When the player moves forward during attacking, what angle should we clamp to?
			attack_angle_zero_deadzone = 20,  -- When the player attacks more-or-less directly in front of itself (relative to the waist), below what angle should we just clamp to 0?

			extra_controlqueueticks_on_hitstop_mult = 3, -- When the player has hitstop applied to them, modify their controlqueueticks by the amount of hitstop multiplied by this number.
														 -- Increase this if it feels like your button presses are being "eaten" by pressing again too early when you hit an enemy.
			extra_controlqueueticks_on_hitstop_maximum = 15, -- When the above modification happens, what is the maximum amount of frames we're allowed to add?
															 -- Decrease this if it feels like the game is sluggish to respond to your button presses when you press after hitting an enemy.
			extra_controlqueueticks_on_hitstop_minimum = 10, -- When the above modification happens, what is the maximum amount of frames we're allowed to add?
		},

		MYSTERIES = {
			ROOMS = {
				CHANCES = -- starting drop chances
				{
					monster = 30,
					potion = 5,
					powerupgrade = 5,
					wanderer = 60, --bank choice: when the other types are not rolled, they get increased chance to roll next time. that % comes from this choice
					-- ranger = 35, -- Original tuning was 35, disabling for Early Access.
				},

				CHANCE_INCREASE = -- when these types are not rolled, how much more likely should seeing one of them become next roll? measured in %
				{
					monster = 15,
					potion = 10,
					powerupgrade = 10,
					ranger = 20,
					wanderer = 0, --bank choice
				},
			},
			MONSTER_CHANCES = {
				-- If a monster room is chosen,
				DIFFICULTIES =
				{
					medium = 35,
					hard = 65,
				},

				REWARDS =
				{
					medium = {
						plain = 50,
						coin = 50,
					},
					hard = {
						fabled = 60,
						coin = 40,
					},
				},
			},
		},

        ----- Monsters

        ENEMY_MIN_STARTUP_FRAMES_AFTER_INTERRUPTION = 15, -- After an enemy's attack gets interrupted during its "hold" state, what is the minimum amount of frames for them to get back to their attack?
        												  -- If this is set to 0, it means if an enemy was interrupted with 2f left in their startup, they will return to their attack with 2f startup total.
        												  -- This feels really unfair! So let's set a speed limit.
        												  -- If this is too HIGH, it becomes easy to stun-lock enemies. Set this conservatively.

        ----- Starting Forest
		cabbageroll_elite = {
			health = 450,
			base_damage = 135,
			multiplayer_mods = "ELITE",
		},

		cabbageroll = {
			health = 300,
			base_damage = 90,
			vision = default_vision_tuning,
			roll_animframes = 20,
			walk_speed = MONSTER_MOVE_SPEED_MOD * 3,
			speedmult = {
				steps = 6,
				scale = 0.3,
				centered = true,
			},
			steeringlimit = 720,
			multiplayer_mods = "BASIC",
			charm_colors = {
				color_add = { 28/255, 0/255, 58/255, 1 },
				color_mult = { 255/255, 160/255, 255/255, 1 },
				bloom = { 64/255, 0/255, 70/255, 0.5 },
			},
		},

		-- dummy tuning table, used only for the encounter debugger
		cabbagerolls2 =
		{
			health = 600,
			multiplayer_mods = "BASIC",
		},

		-- dummy tuning table, used only for the encounter debugger
		cabbagerolls =
		{
			health = 900,
			multiplayer_mods = "BASIC",
		},

		blarmadillo_elite = {
			health = 750,
			base_damage = 135,
			multiplayer_mods = "ELITE",
		},

		blarmadillo = {
			health = 500,
			base_damage = 90,
			vision = default_vision_tuning,
			walk_speed = MONSTER_MOVE_SPEED_MOD * 4.2,
			roll_animframes = 10,
			speedmult = {
				steps = 5,
				scale = 0.2,
				centered = true,
			},
			multiplayer_mods = "BASIC",
			steeringlimit = 360,
			charm_colors = {
				color_add = { 28/255, 0/255, 38/255, 1 },
				color_mult = { 220/255, 169/255, 255/255, 1 },
				bloom = { 64/255, 0/255, 70/255, 0.5 },
			},
			charm_colors_projectile = {
				color_add = { 28/255, 0/255, 38/255, 1 },
				color_mult = { 220/255, 169/255, 255/255, 1 },
				bloom = { 64/255, 0/255, 70/255, 0.5 },
			},
		},

		shellsquid_elite = {
			health = 750,
			base_damage = 135,
			multiplayer_mods = "ELITE",
		},

		shellsquid = {
			health = 500,
			base_damage = 90,
			vision = default_vision_tuning,
			walk_speed = MONSTER_MOVE_SPEED_MOD * 4.2,
			dash = {
				duration_frames = 1 * SECONDS,
				fire_distance = 1.0,
				stopping_distance = 1.0,
				movespeed = 20, -- blarm roll is 12
				min_dash_distance = 15,
				max_dash_distance = 20,
			},
			pierce = {
				movespeed = 2,
			},
			speedmult = {
				steps = 5,
				scale = 0.2,
				centered = true,
			},
			steeringlimit = 360,
			charm_colors = {
				color_add = { 28/255, 0/255, 38/255, 1 },
				color_mult = { 220/255, 169/255, 255/255, 1 },
				bloom = { 64/255, 0/255, 70/255, 0.5 },
			},
			charm_colors_projectile = {
				color_add = { 28/255, 0/255, 38/255, 1 },
				color_mult = { 220/255, 169/255, 255/255, 1 },
				bloom = { 64/255, 0/255, 70/255, 0.5 },
			},
		},

		yammo_miniboss = {
			health = 3250,
			base_damage = 230,
			vision = elite_vision_tuning,
			charge_speed = MONSTER_MOVE_SPEED_MOD * 6.66,
			multiplayer_mods = "MINIBOSS",
		},

		yammo_elite = {
			health = 2250,
			base_damage = 230,
			vision = elite_vision_tuning,
			charge_speed = MONSTER_MOVE_SPEED_MOD * 6.66,
			multiplayer_mods = "ELITE",
		},

		yammo = {
			health = 1500,
			base_damage = 200,
			hitstun_pressure_frames = HitStunPressureFrames.HIGH,
			vision = default_vision_tuning,
			walk_speed = MONSTER_MOVE_SPEED_MOD * 2.75,
			speedmult = {
				steps = 4,
				scale = 0.2,
				centered = false,
			},
			steeringlimit = 180,
			multiplayer_mods = "MAJOR",
			charm_colors = {
				color_add = { 28/255, 0/255, 58/255, 1 },
				color_mult = { 220/255, 169/255, 255/255, 1 },
				bloom = { 64/255, 0/255, 70/255, 0.5 },
			},
			colorshift = {
				HSB(0, 100, 100),
				HSB(10, 100, 100),
				HSB(-8, 100, 100),
			},
		},

		zucco_elite = {
			health = 1500,
			base_damage = 180,
			multiplayer_mods = "ELITE",
		},

		zucco = {
			forced_loot_priority = true,
			health = 1250, -- Because Zucco attacks relentlessly and doesn't try to avoid damage, if he has too low of health he'll just die. Make sure he has enough health to get a full attack chain or two off, while under pressure.
			base_damage = 135,
			hitstun_pressure_frames = HitStunPressureFrames.MEDIUM,
			vision = default_vision_tuning,
			walk_speed = MONSTER_MOVE_SPEED_MOD * 6.75,
			run_speed = MONSTER_MOVE_SPEED_MOD * 6.0,
			steeringlimit = 360,
			speedmult = {
				steps = 4,
				scale = 0.2,
				centered = false,
			},
			multiplayer_mods = "MINOR",
			charm_colors = {
				color_add = { 38/255, 0/255, 68/255, 1 },
				color_mult = { 255/255, 145/255, 255/255, 1 },
				bloom = { 64/255, 0/255, 70/255, 0.5 },
			},
			custom_puppet_scale = 0.3, -- it's a bit larger than cabbagerolls and blarmadillos
			colorshift = {
				HSB(0, 100, 100),
				HSB(-8, 100, 100),
				HSB(8, 100, 100),
			},
		},

		gourdo_miniboss = {
			health = 3000,
			base_damage = 200,
			butt_slam_pst_knockdown_seconds = 2,
			healing_seed = {
				health = 520,
				heal_amount = 350,
				heal_radius = 80,
				heal_period = 2.7,
			},
			vision = elite_vision_tuning,
			multiplayer_mods = "MINIBOSS",
		},

		gourdo_elite = {
			health = 2500,
			base_damage = 200,
			butt_slam_pst_knockdown_seconds = 2,
			healing_seed = {
				health = 520,
				heal_amount = 350,
				heal_radius = 80,
				heal_period = 2.7,
			},
			vision = elite_vision_tuning,
			multiplayer_mods = "ELITE",
		},

		gourdo = {
			health = 1700,
			base_damage = 160,
			hitstun_pressure_frames = HitStunPressureFrames.HIGH,
			butt_slam_pst_knockdown_seconds = 2,
			healing_seed = {
				health = 420,
				heal_amount = 200,
				heal_radius = 11,
				heal_period = 2.2,
			},
			vision = default_vision_tuning,
			walk_speed = MONSTER_MOVE_SPEED_MOD * 2.6,
			speedmult = {
				steps = 4,
				scale = 0.2,
				centered = false,
			},
			multiplayer_mods = "MAJOR",
			steeringlimit = 180,
			charm_colors = {
				color_add = { 28/255, 0/255, 88/255, 1 },
				color_mult = { 160/255, 230/255, 255/255, 1 },
				bloom = { 64/255, 0/255, 70/255, 0.5 },
			},
			charm_colors_projectile = {
				color_add = { 50/255, 0/255, 35/255, 1 },
				color_mult = { 200/255, 170/255, 255/255, 1 },
				bloom = { 64/255, 0/255, 70/255, 0.5 },
			},
			charm_colors_seed = {
				color_add = { 50/255, 0/255, 35/255, 1 },
				color_mult = { 200/255, 170/255, 255/255, 1 },
				bloom = { 64/255, 0/255, 70/255, 0.5 },
			},
			colorshift = {
				HSB(0, 100, 100),
				HSB(8, 100, 100),
				HSB(-8, 100, 100),
			},
			colorshift_miniboss = {
				HSB(-25, 100, 100),
				HSB(25, 100, 100),
				HSB(-25, 100, 100),
			},
		},

		eyev_elite = {
			health = 1200,
			base_damage = 90,
			multiplayer_mods = "ELITE",
		},

		eyev =
		{
			health = 750,
			base_damage = 60,
			vision = default_vision_tuning,
			walk_speed = MONSTER_MOVE_SPEED_MOD * 5.5,
			hitstun_pressure_frames = HitStunPressureFrames.LOW,
			speedmult = {
				steps = 4,
				scale = 0.2,
				centered = false,
			},
			multiplayer_mods = "MINOR",
			steeringlimit = 720,
			charm_colors = {
				color_add = { 38/255, 0/255, 68/255, 1 },
				color_mult = { 255/255, 145/255, 255/255, 1 },
				bloom = { 64/255, 0/255, 70/255, 0.5 },
			},
		},

		treemon_elite = {
			health = 900,
			base_damage = 100,
			multiplayer_mods = "ELITE",
		},

		treemon = {
			base_damage = 50,
			health = 450,
			stationary = true,
			multiplayer_mods = "MINOR",
			vision = default_vision_tuning,
			charm_colors = {
				color_add = { 28/255, 0/255, 88/255, 1 },
				color_mult = { 160/255, 230/255, 255/255, 1 },
				bloom = { 64/255, 0/255, 70/255, 0.5 },
			},
			charm_colors_projectile = {
				color_add = { 50/255, 0/255, 35/255, 1 },
				color_mult = { 200/255, 170/255, 255/255, 1 },
				bloom = { 64/255, 0/255, 70/255, 0.5 },
			},
		},

		gnarlic_elite = {
			health = 600,
			base_damage = 140,
			multiplayer_mods = "ELITE",
		},

		gnarlic =
		{
			health = 200,
			base_damage = 90,
			vision = default_vision_tuning,
			roll_animframes = 20,
			walk_speed = MONSTER_MOVE_SPEED_MOD * 3,
			speedmult = {
				steps = 6,
				scale = 0.3,
				centered = true,
			},
			steeringlimit = 720,
			multiplayer_mods = "BASIC",
			charm_colors = {
				color_add = { 28/255, 0/255, 58/255, 1 },
				color_mult = { 255/255, 160/255, 255/255, 1 },
				bloom = { 64/255, 0/255, 70/255, 0.5 },
			},
		},

		beets_elite = {
			health = 600,
			base_damage = 150,
			multiplayer_mods = "ELITE",
		},
		beets =
		{
			health = 200,
			base_damage = 90,
			vision = default_vision_tuning,
			roll_animframes = 20,
			walk_speed = MONSTER_MOVE_SPEED_MOD * 2,
			speedmult = {
				steps = 6,
				scale = 0.3,
				centered = true,
			},
			steeringlimit = 720,
			multiplayer_mods = "BASIC",
			charm_colors = {
				color_add = { 28/255, 0/255, 58/255, 1 },
				color_mult = { 255/255, 160/255, 255/255, 1 },
				bloom = { 64/255, 0/255, 70/255, 0.5 },
			},
		},

		windmon_elite = {
			health = 800,
			base_damage = 80,
			multiplayer_mods = "ELITE",
		},

		windmon = {
			base_damage = 40,
			health = 450,
			stationary = true,
			multiplayer_mods = "MINOR",
			vision = default_vision_tuning,
			charm_colors = {
				color_add = { 28/255, 0/255, 88/255, 1 },
				color_mult = { 160/255, 230/255, 255/255, 1 },
				bloom = { 64/255, 0/255, 70/255, 0.5 },
			},
			charm_colors_projectile = {
				color_add = { 50/255, 0/255, 35/255, 1 },
				color_mult = { 200/255, 170/255, 255/255, 1 },
				bloom = { 64/255, 0/255, 70/255, 0.5 },
			},
		},

		----- Swamp
		mothball_elite = {
			health = 750, -- Although this is a mothball, this is likely the single elite in the room. It should still be meaningful. Be wary of tuning too low!
			base_damage = 70,
			walk_speed = MONSTER_MOVE_SPEED_MOD * 3.5,
			multiplayer_mods = "ELITE",
		},

		mothball =
		{
			health =  100, -- Make sure when changing this, that it is still easy and satisfying to mow through collections of mothballs. Too much health means they aren't easy to mow through! I should be able to Spear Drill through and kill them.
			base_damage = 35,
			vision = default_vision_tuning,
			walk_speed = MONSTER_MOVE_SPEED_MOD * 3,
			speedmult = {
				steps = 4,
				scale = 0.2,
				centered = false,
			},
			steeringlimit = 720,
			multiplayer_mods = "SWARM",
			charm_colors = {
				color_add = { 38/255, 0/255, 68/255, 1 },
				color_mult = { 255/255, 145/255, 255/255, 1 },
				bloom = { 64/255, 0/255, 70/255, 0.5 },
			},
		},

		mothball_teen_elite = {
			health = 1200,
			base_damage = 75,
			escape_speed = 15,
			escape_time = 2,
			multiplayer_mods = "ELITE",
		},

		mothball_teen =
		{
			health = 750,
			base_damage = 50,
			vision = default_vision_tuning,
			walk_speed = MONSTER_MOVE_SPEED_MOD * 6,
			speedmult = {
				steps = 4,
				scale = 0.2,
				centered = false,
			},
			steeringlimit = 720,
			multiplayer_mods = "MINOR",
			charm_colors = {
				color_add = { 38/255, 0/255, 68/255, 1 },
				color_mult = { 255/255, 145/255, 255/255, 1 },
				bloom = { 64/255, 0/255, 70/255, 0.5 },
			},
			charm_colors_projectile = {
				color_add = { 50/255, 0/255, 35/255, 1 },
				color_mult = { 200/255, 170/255, 255/255, 1 },
				bloom = { 64/255, 0/255, 70/255, 0.5 },
			},

			escape_speed = 14,
			escape_time = 1.3,
		},

		mothball_teen_projectile =
		{
			movement_speed = 4,
			acceleration = 0.6,
			slow_down_time = 0.5,
		},

		-- Slow effect projectile
		mothball_teen_projectile_elite =
		{
			movement_speed = 6,
		},

		-- Confuse effect projectile
		mothball_teen_projectile2_elite =
		{
			movement_speed = 4,
			acceleration = 0.6,
			slow_down_time = 0.5,
		},

		mothball_spawner =
		{
			health = 1000,
			base_damage = 50,
			vision = default_vision_tuning,
			speedmult = {
				steps = 4,
				scale = 0.2,
				centered = false,
			},
			multiplayer_mods = "MINOR",
			charm_colors = {
				color_add = { 38/255, 0/255, 68/255, 1 },
				color_mult = { 255/255, 145/255, 255/255, 1 },
				bloom = { 64/255, 0/255, 70/255, 0.5 },
			},
		},

		sporemon_elite = {
			health = 1300,
			base_damage = 180,
			multiplayer_mods = "ELITE",
			stationary = true,
		},

		sporemon = {
			base_damage = 100,
			health = 800,
			stationary = true,
			multiplayer_mods = "MINOR",
			vision = default_vision_tuning,
			charm_colors = {
				color_add = { 28/255, 0/255, 88/255, 1 },
				color_mult = { 160/255, 230/255, 255/255, 1 },
				bloom = { 64/255, 0/255, 70/255, 0.5 },
			},
			charm_colors_projectile = {
				color_add = { 50/255, 0/255, 35/255, 1 },
				color_mult = { 200/255, 170/255, 255/255, 1 },
				bloom = { 64/255, 0/255, 70/255, 0.5 },
			},
		},

		mossquito_elite = {
			health = 600,
			base_damage = 120,
			walk_speed = MONSTER_MOVE_SPEED_MOD * 6,
			spray_interval = 13,
			multiplayer_mods = "ELITE",
		},

		mossquito = {
			health = 450,
			base_damage = 90,
			vision = default_vision_tuning,
			roll_animframes = 20,
			walk_speed = MONSTER_MOVE_SPEED_MOD * 10,
			speedmult = {
				steps = 6,
				scale = 0.3,
				centered = true,
			},
			steeringlimit = 720,
			multiplayer_mods = "BASIC",
			charm_colors = {
				color_add = { 28/255, 0/255, 58/255, 1 },
				color_mult = { 255/255, 160/255, 255/255, 1 },
				bloom = { 64/255, 0/255, 70/255, 0.5 },
			},
			spray_interval = 26,
		},

		battoad_elite = {
			health = 1100,
			base_damage = 100,
			multiplayer_mods = "ELITE",
		},

		battoad =
		{
			health = 750,
			base_damage = 75,
			vision = default_vision_tuning,
			walk_speed = MONSTER_MOVE_SPEED_MOD * 7, -- hopping speed
			walk_speed_fleeing = MONSTER_MOVE_SPEED_MOD * 10, -- hopping speed while running away after eating konjur
			run_speed = MONSTER_MOVE_SPEED_MOD * 6, -- flying speed
			speedmult = {
				steps = 4,
				scale = 0.2,
				centered = false,
			},
			steeringlimit = 720,
			multiplayer_mods = "MINOR",
			charm_colors = {
				color_add = { 38/255, 0/255, 68/255, 1 },
				color_mult = { 255/255, 145/255, 255/255, 1 },
				bloom = { 64/255, 0/255, 70/255, 0.5 },
			},
			charm_colors_projectile = {
				color_add = { 50/255, 0/255, 35/255, 1 },
				color_mult = { 200/255, 170/255, 255/255, 1 },
				bloom = { 64/255, 0/255, 70/255, 0.5 },
			},
		},

		bulbug_elite = {
			health = 1250 * 1.5,
			base_damage = 50 * 2,
			multiplayer_mods = "ELITE",
		},

		bulbug =
		{
			health = 1250,
			base_damage = 50,
			hitstun_pressure_frames = HitStunPressureFrames.MEDIUM,
			vision = default_vision_tuning,
			walk_speed = MONSTER_MOVE_SPEED_MOD * 6,
			speedmult = {
				steps = 4,
				scale = 0.2,
				centered = false,
			},
			steeringlimit = 720,
			multiplayer_mods = "MAJOR",
			charm_colors = {
				color_add = { 38/255, 0/255, 68/255, 1 },
				color_mult = { 255/255, 145/255, 255/255, 1 },
				bloom = { 64/255, 0/255, 70/255, 0.5 },
			},
			charm_colors_projectile = {
				color_add = { 50/255, 0/255, 35/255, 1 },
				color_mult = { 200/255, 170/255, 255/255, 1 },
				bloom = { 64/255, 0/255, 70/255, 0.5 },
			},
		},

		floracrane_miniboss = {
			health = 3250,
			base_damage = 180,
			bird_kick_move_speed = 3,
			vision = elite_vision_tuning,
			multiplayer_mods = "MINIBOSS",
		},

		floracrane_elite = {
			health = 2800, -- tune relative to Yammo Elite
			base_damage = 180,
			bird_kick_move_speed = 3,
			vision = elite_vision_tuning,
			multiplayer_mods = "ELITE",
		},

		floracrane =
		{
			health = 1750,
			base_damage = 130,
			bird_kick_move_speed = 1.5,
			hitstun_pressure_frames = HitStunPressureFrames.MEDIUM,
			vision = default_vision_tuning,
			walk_speed = MONSTER_MOVE_SPEED_MOD * 4.5,
			speedmult = {
				steps = 4,
				scale = 0.2,
				centered = false,
			},
			steeringlimit = 720,
			multiplayer_mods = "MAJOR",
			charm_colors = {
				color_add = { 38/255, 0/255, 68/255, 1 },
				color_mult = { 255/255, 145/255, 255/255, 1 },
				bloom = { 64/255, 0/255, 70/255, 0.5 },
			},
		},

		groak_miniboss = {
			health = 3250,
			base_damage = 80 * 1.5,
			walk_speed = MONSTER_MOVE_SPEED_MOD * 3,
			vision = elite_vision_tuning,
			multiplayer_mods = "MINIBOSS",
		},

		groak_elite = {
			health = 2000* 1.5,
			base_damage = 80 * 1.5,
			walk_speed = MONSTER_MOVE_SPEED_MOD * 3,
			vision = elite_vision_tuning,
			multiplayer_mods = "ELITE",
		},

		groak = {
			health = 2000,
			base_damage = 80,
			hitstun_pressure_frames = HitStunPressureFrames.HIGH,
			vision = default_vision_tuning,
			walk_speed = MONSTER_MOVE_SPEED_MOD * 3,
			speedmult = {
				steps = 4,
				scale = 0.2,
				centered = false,
			},
			steeringlimit = 180,
			multiplayer_mods = "MAJOR",
			charm_colors = {
				color_add = { 28/255, 0/255, 58/255, 1 },
				color_mult = { 220/255, 169/255, 255/255, 1 },
				bloom = { 64/255, 0/255, 70/255, 0.5 },
			},
		},

		slowpoke_elite = {
			health = 800 * 1.5,
			base_damage = 110 * 2,
			num_slams = 3,
			multiplayer_mods = "ELITE",
		},

		slowpoke = {
			health = 800,
			base_damage = 110,
			hitstun_pressure_frames = HitStunPressureFrames.MEDIUM,
			vision = default_vision_tuning,
			walk_speed = MONSTER_MOVE_SPEED_MOD * 2,
			speedmult = {
				steps = 4,
				scale = 0.2,
				centered = false,
			},
			steeringlimit = 90,
			multiplayer_mods = "MINOR",
			charm_colors = {
				color_add = { 28/255, 0/255, 58/255, 1 },
				color_mult = { 220/255, 169/255, 255/255, 1 },
				bloom = { 64/255, 0/255, 70/255, 0.5 },
			},
		},

		swarmy_elite = {
			health = 750,
			base_damage = 160,
			multiplayer_mods = "ELITE",
		},

		swarmy = {
			health = 400,
			base_damage = 90,
			vision = default_vision_tuning,
			walk_speed = MONSTER_MOVE_SPEED_MOD * 4,
			speedmult = {
				steps = 6,
				scale = 0.3,
				centered = true,
			},
			steeringlimit = 720,
			multiplayer_mods = "BASIC",
			charm_colors = {
				color_add = { 28/255, 0/255, 58/255, 1 },
				color_mult = { 255/255, 160/255, 255/255, 1 },
				bloom = { 64/255, 0/255, 70/255, 0.5 },
			},
		},

		woworm_elite = {
			health = 900,
			shell_health = 2000, -- This does not get scaled by dungeon health modifiers.
			base_damage = 140,
			multiplayer_mods = "ELITE",
			walk_speed = MONSTER_MOVE_SPEED_MOD * 1.7,
		},

		woworm = {
			health = 500,
			shell_health = 1300, -- This does not get scaled by dungeon health modifiers. Woworm, at time of writing, has 1000 health in Dungeon4.
			base_damage = 110,
			vision = default_vision_tuning,
			walk_speed = MONSTER_MOVE_SPEED_MOD * 2,
			speedmult = {
				steps = 6,
				scale = 0.3,
				centered = true,
			},
			steeringlimit = 720,
			multiplayer_mods = "MINOR",
			charm_colors = {
				color_add = { 28/255, 0/255, 58/255, 1 },
				color_mult = { 255/255, 160/255, 255/255, 1 },
				bloom = { 64/255, 0/255, 70/255, 0.5 },
			},
		},

		totolili_elite = {
			health = 1200,
			base_damage = 180,
			multiplayer_mods = "ELITE",
		},

		totolili = {
			health = 600,
			base_damage = 90,
			vision = default_vision_tuning,
			walk_speed = MONSTER_MOVE_SPEED_MOD * 3.5,
			speedmult = {
				steps = 6,
				scale = 0.3,
				centered = true,
			},
			steeringlimit = 720,
			multiplayer_mods = "MINOR",
			charm_colors = {
				color_add = { 28/255, 0/255, 58/255, 1 },
				color_mult = { 255/255, 160/255, 255/255, 1 },
				bloom = { 64/255, 0/255, 70/255, 0.5 },
			},
		},

		----- Ice Biome
		warmy = {
			health = 600, -- FIX ME
			base_damage = 90, -- FIX ME
			vision = default_vision_tuning,
			walk_speed = MONSTER_MOVE_SPEED_MOD * 7.5,
			speedmult = {
				steps = 6,
				scale = 0.3,
				centered = true,
			},
			steeringlimit = 720,
			multiplayer_mods = "BASIC",
			charm_colors = {
				color_add = { 28/255, 0/255, 58/255, 1 },
				color_mult = { 255/255, 160/255, 255/255, 1 },
				bloom = { 64/255, 0/255, 70/255, 0.5 },
			},
		},

		bunippy_elite = {
			health = 800,
			base_damage = 150,
			multiplayer_mods = "ELITE",
		},
		bunippy =
		{
			health = 400,
			base_damage = 90,
			vision = default_vision_tuning,
			walk_speed = MONSTER_MOVE_SPEED_MOD * 4,
			speedmult = {
				steps = 6,
				scale = 0.3,
				centered = true,
			},
			steeringlimit = 720,
			multiplayer_mods = "BASIC",
			charm_colors = {
				color_add = { 28/255, 0/255, 58/255, 1 },
				color_mult = { 255/255, 160/255, 255/255, 1 },
				bloom = { 64/255, 0/255, 70/255, 0.5 },
			},
		},

		meowl_elite = {
			health = 1350,
			base_damage = 200,
			multiplayer_mods = "ELITE",
		},
		meowl =
		{
			health = 750,
			base_damage = 100,
			vision = default_vision_tuning,
			walk_speed = MONSTER_MOVE_SPEED_MOD * 4,
			speedmult = {
				steps = 6,
				scale = 0.3,
				centered = true,
			},
			steeringlimit = 720,
			multiplayer_mods = "BASIC",
			charm_colors = {
				color_add = { 28/255, 0/255, 58/255, 1 },
				color_mult = { 255/255, 160/255, 255/255, 1 },
				bloom = { 64/255, 0/255, 70/255, 0.5 },
			},
		},

		antleer_elite = {
			health = 1400,
			base_damage = 200,
			vision = elite_vision_tuning,
			multiplayer_mods = "ELITE",
		},

		antleer = {
			health = 800,
			base_damage = 140,
			hitstun_pressure_frames = HitStunPressureFrames.MEDIUM,
			vision = default_vision_tuning,
			walk_speed = MONSTER_MOVE_SPEED_MOD * 2,
			speedmult = {
				steps = 4,
				scale = 0.2,
				centered = false,
			},
			steeringlimit = 180,
			multiplayer_mods = "MAJOR",
			charm_colors = {
				color_add = { 28/255, 0/255, 58/255, 1 },
				color_mult = { 220/255, 169/255, 255/255, 1 },
				bloom = { 64/255, 0/255, 70/255, 0.5 },
			},
			colorshift = {
				HSB(0, 100, 100),
				HSB(10, 100, 100),
				HSB(-8, 100, 100),
			},
		},

		crystroll_miniboss = {
			health = 3250,
			base_damage = 240,
			vision = elite_vision_tuning,
			multiplayer_mods = "MINIBOSS",
		},

		crystroll_elite = {
			health = 2400,
			base_damage = 240,
			vision = elite_vision_tuning,
			multiplayer_mods = "ELITE",
		},

		crystroll = {
			health = 1600,
			base_damage = 200,
			hitstun_pressure_frames = HitStunPressureFrames.HIGH,
			vision = default_vision_tuning,
			walk_speed = MONSTER_MOVE_SPEED_MOD * 2,
			speedmult = {
				steps = 4,
				scale = 0.2,
				centered = false,
			},
			steeringlimit = 180,
			multiplayer_mods = "MAJOR",
			charm_colors = {
				color_add = { 28/255, 0/255, 58/255, 1 },
				color_mult = { 220/255, 169/255, 255/255, 1 },
				bloom = { 64/255, 0/255, 70/255, 0.5 },
			},
			colorshift = {
				HSB(0, 100, 100),
				HSB(10, 100, 100),
				HSB(-8, 100, 100),
			},
		},

		----- Bosses

		bandicoot = {
			base_damage = 200,
			health = 17000,
			hitstun_pressure_frames = HitStunPressureFrames.HIGH,
			walk_speed = MONSTER_MOVE_SPEED_MOD * 6,
			run_speed = MONSTER_MOVE_SPEED_MOD * 9,
			steeringlimit = 360,
			vision = {
				retarget_period = 1,
				aggro_range = 30,
				retarget_range = 55,
				too_near_switch_target = 25,
				too_far_retarget = 10000,
				share_target_range = 50,
				share_target_tags = { "mob" },
				share_not_target_tags = { "INLIMBO" },
			},
			multiplayer_mods = "BOSS",
			num_clones_normal =
			{
				1, -- +real bandicoot = 2 monsters on battlefield (for 1 player)
				1,
				2,
				2, -- (4 players)
			},
			num_clones_low_health =
			{
				1,
				1,
				2,
				2,
			},
			max_mobs =
			{
				8,
				9,
				10,
				12,
			},
			spore_weights =
			{
				trap_spores_damage = 55,
				trap_spores_heal = 42.5,
				-- trap_spores_groak = 2.5,
			},
			clone_spawn_move_speed = 15,
		},

		bandicoot_clone = {
			base_damage = 1,
			health = 1000,
			hitstun_pressure_frames = HitStunPressureFrames.MEDIUM,
			walk_speed = MONSTER_MOVE_SPEED_MOD * 6,
			run_speed = MONSTER_MOVE_SPEED_MOD * 9,
			steeringlimit = 360,
			multiplayer_mods = "BOSS",
			vision = {
				retarget_period = 1,
				aggro_range = 15,
				retarget_range = 55,
				too_near_switch_target = 25,
				too_far_retarget = 10000,
				share_target_range = 50,
				share_target_tags = { "mob" },
				share_not_target_tags = { "INLIMBO" },
			},
			clone_spawn_move_speed = 15,
		},

		thatcher = {
			base_damage = 200,
			health = 15000,
			hitstun_pressure_frames = HitStunPressureFrames.HIGH,
			walk_speed = MONSTER_MOVE_SPEED_MOD * 8,
			run_speed = MONSTER_MOVE_SPEED_MOD * 8,
			steeringlimit = 360, -- TODO: untuned
			multiplayer_mods = "BOSS",
			vision = {
				retarget_period = 1,
				aggro_range = 30,
				retarget_range = 55,
				too_near_switch_target = 25,
				too_far_retarget = 10000,
				share_target_range = 50,
				share_target_tags = { "mob" },
				share_not_target_tags = { "INLIMBO" },
			},
		},

		megatreemon = {
			base_damage = 270,
			health = 15000,
			stationary = true,
			multiplayer_mods = "BOSS",
			hitstun_pressure_frames = HitStunPressureFrames.HIGH,

			vision = {
				retarget_period = 1,
				aggro_range = 20,
				retarget_range = 55,
				too_near_switch_target = 25,
				too_far_retarget = 10000,
				share_target_range = 50,
				share_target_tags = { "mob" },
				share_not_target_tags = { "INLIMBO" },
			},
		},

		owlitzer = {
			base_damage = 180,
			health = 16000,
			walk_speed = MONSTER_MOVE_SPEED_MOD * 12,
			steeringlimit = 360,
			multiplayer_mods = "BOSS",
			hitstun_pressure_frames = HitStunPressureFrames.HIGH,
			vision = {
				retarget_period = 1,
				aggro_range = 15,
				retarget_range = 55,
				too_near_switch_target = 25,
				too_far_retarget = 10000,
				share_target_range = 50,
				share_target_tags = { "mob" },
				share_not_target_tags = { "INLIMBO" },
			},
		},

		----- Destructible Props
		PROP_DESTRUCTIBLE = {
			HEALTH = {
				LOW = 150,
				MEDIUM = 225,
				HIGH = 250,
				VERY_HIGH = 500,
			},
		},

		----- Friendly Minions
		minion_melee = {
			health = 1,
			base_damage = 75, -- TODO: make this take the base_damage of the equipped weapon upon spawn?
			vision = default_vision_tuning,
		},

		minion_ranged = {
			health = 1,
			base_damage = 50, -- TODO: make this take the base_damage of the equipped weapon upon spawn?
			vision = default_vision_tuning,
		},

		----- Default Tuning

		default_charm_colors = {
			-- Intentionally ugly to draw attention to itself, so we know we are missing a color set!
			color_add = { 255/255, 0/255, 255/255, 1 },
			color_mult = { 255/255, 255/255, 255/255, 1 },
			bloom = { 255/255, 0/255, 255/255, 1 },
		},

		----- npcs
		npc = {
			generic = {
				wander_dist = 6,
			},
		},

		-- Biome Exploration
		BIOME_EXPLORATION =
		{
			BASE = 150,
			MINIBOSS = 75,
			BOSS = 200,
			CORESTONE_REWARD = 3,
			FRENZY_LEVEL_MODIFIER = 0.1, -- 10% exp per frenzy level

			-- EXP for full clear
			-- F0 425
			-- F1 468
			-- F2 510
			-- F3 553
		},

		BIOME_LEVEL_EXPERIENCE =
		{
			400,
			450,
			500,
			550,
			600,
			650,
		},

		BIOME_LEVEL_EXPERIENCE_GROWN = 0.1,

		-- Crafting

		CRAFTING =
		{
			-- first time constructing decor reward, in corestones
			CONSTRUCTABLE_RARITY_TO_BOUNTY =
			{
				[ITEM_RARITY.s.COMMON] = 1,
			    [ITEM_RARITY.s.UNCOMMON] = 2,
			    [ITEM_RARITY.s.EPIC] = 5,
			    [ITEM_RARITY.s.LEGENDARY] = 10,
			},

			--base upgrade cost for items
			UPGRADE_COSTS =
			{
				HEAD = 2,
				BODY = 4,
				WAIST = 2,
				WEAPON = 4,
			},

			--rarer items cost more
			RARITY_UPGRADE_MODIFIER =
			{
				[ITEM_RARITY.s.COMMON] = 1,
				[ITEM_RARITY.s.UNCOMMON] = 1.5,
				[ITEM_RARITY.s.EPIC] = 2.5,
			},

			--recipes
			ARMOUR_UPGRADE_PATH =
			{
				[ITEM_RARITY.s.COMMON] =
				{
					{ -- 2
						{ t = INGREDIENTS.s.MONSTER, r = ITEM_RARITY.s.UNCOMMON },
					},
					{ -- 3
						{ t = INGREDIENTS.s.MONSTER, r = ITEM_RARITY.s.EPIC },
					},
				},

				[ITEM_RARITY.s.UNCOMMON] =
				{
					{ -- 2
						{ t = INGREDIENTS.s.MONSTER, r = ITEM_RARITY.s.UNCOMMON },
					},
					{ -- 3
						{ t = INGREDIENTS.s.MONSTER, r = ITEM_RARITY.s.EPIC },
					},
				},

				[ITEM_RARITY.s.EPIC] =
				{
					{ -- 2
						{ t = INGREDIENTS.s.MONSTER, r = ITEM_RARITY.s.UNCOMMON },
					},
					{ -- 3
						{ t = INGREDIENTS.s.MONSTER, r = ITEM_RARITY.s.EPIC },
					},
				},
			},

			TONICS =
			{
				COUNT = 5,
				[ITEM_RARITY.s.COMMON] =
				{
					{ t = INGREDIENTS.s.CURRENCY, r = ITEM_RARITY.s.COMMON, a = 1 },
				},

				[ITEM_RARITY.s.UNCOMMON] = {
					{ t = INGREDIENTS.s.CURRENCY, r = ITEM_RARITY.s.UNCOMMON, a = 1 },
				},

				[ITEM_RARITY.s.EPIC] =
				{
					{ t = INGREDIENTS.s.CURRENCY, r = ITEM_RARITY.s.EPIC, a = 1 },
				},
			},

			FOOD =
			{
				COUNT = 3,
				[ITEM_RARITY.s.COMMON] =
				{
					{ t = INGREDIENTS.s.CURRENCY, r = ITEM_RARITY.s.UNCOMMON, a = 1 },
				},

				[ITEM_RARITY.s.UNCOMMON] = {
					{ t = INGREDIENTS.s.CURRENCY, r = ITEM_RARITY.s.UNCOMMON, a = 1 },
				},

				[ITEM_RARITY.s.EPIC] =
				{
					{ t = INGREDIENTS.s.CURRENCY, r = ITEM_RARITY.s.EPIC, a = 1 },
				},
			},

			WEAPON =
			{
				UPGRADE_PATH = true,
			},

			ARMOUR_MEDIUM =
			{
				UPGRADE_PATH = true,
			},
		},

		--jcheng: chance of any room having loot drop
		--  every time you enter a room, draw one of these numbers from a grabbag
		--	if you are past the miniboess, draw twice
		LOOT_REWARD_CHANCE = { 0, 0, 0, 0, 0, 0, 1, 1, 1, 2 },

		-- per frenzy, draw one of these numbers from a grabbag to see how much loot
		BOSS_LOOT_VALUE =
		{
			-- 2 + FrenzyLevel
			{ 2 },			--F0
			{ 3 },			--F1
			{ 4 },			--F2
			{ 5 },			--F3
		},
		MINIBOSS_LOOT_VALUE =
		{
			-- Since this is half the effort as a boss, give less.
			-- 1 + (FrenzyLevel/2)
			{ 1 }, 			--F0 (1 + 0)
			{ 1, 2 },		--F1 (1 + 0.5)
			{ 2 },			--F2 (1 + 1)
			{ 2, 3 },		--F3 (1 + 1.5)
		},

		--jcheng: change the weight of items you get
		--  you are more likely to get loot useful for upgrades than for building decor
		LOOT_WEIGHTS =
		{
			EXCESS_LOOT_MULT = 0.25, -- If you have over EXCESS_LOOT_THRESHOLD amount of an ing, mult the weight by this value
			BASE_ILVL_MULT = 0.25, -- Multiply loot weight by 1 + this (per base ilvl). IE: ilvl 5 has 50% additional weight
			EQUIPPED_GEAR = 1.1,
			HELD_GEAR = 1,
			DECOR = 1
		},

		CORESTONE_REWARD_MODIFIER =
		{
			--change how many corestones you receive from corestone rooms based on current difficulty
			[1] = { 1 },
			[2] = { 1, 1, 2, 2 },
			[3] = { 2, 2, 2, 2, 2, 2, 2, 2, 3, 3 },
			[4] = { 2, 2, 2, 3, 3, 3, 4 },
			[5] = { 3, 3, 3, 3, 3, 3, 4, 4 },
			[6] = { 3, 3, 3, 4, 4, 4, 5 },
			[7] = { 4, 4, 4, 4, 4, 5 },
		},

		--how much things cost in the market
		MARKET_ITEM_COSTS =
		{
			--base cost for items
			EQUIPMENT_COSTS =
			{
				HEAD = 1,
				BODY = 2,
				WAIST = 1,
				WEAPON = 4,
			},

			--harder dungeons have more expensive equipment
			DUNGEON_MODIFIER =
			{
				[1] = 1,
				[2] = 1.5,
				[3] = 2.5,
				[4] = 3.5,
				[5] = 5, -- not implemented
				[6] = 6, -- not implemented
			},

			--rarer items cost more
			RARITY_MODIFIER =
			{
				[ITEM_RARITY.s.COMMON] = 1,
				[ITEM_RARITY.s.UNCOMMON] = 1.5,
				[ITEM_RARITY.s.EPIC] = 2.5,
			}
		},

		MASTERIES =
		{
			CORESTONE_REWARDS =
			{
				[MASTERY_DIFFICULY.s.EASY] = 1,
				[MASTERY_DIFFICULY.s.MEDIUM] = 2,
				[MASTERY_DIFFICULY.s.HARD] = 4,
			}
		},

		DECOR_COSTS =
		{
			PLUSHIE =
			{
				[DECOR_PLUSHIE_SIZE.s.SMALL] = 4,
				[DECOR_PLUSHIE_SIZE.s.MEDIUM] = 6,
				[DECOR_PLUSHIE_SIZE.s.LARGE] = 8,
			},

			BOSSSTATUE = 12,

			BY_RARITY =
			{
				[ITEM_RARITY.s.COMMON] = 1,
				[ITEM_RARITY.s.UNCOMMON] = 2,
				[ITEM_RARITY.s.EPIC] = 3,
			}

		},

    }

	function Tuning:GetEnemyModifiersAtAscensionAndTier(enemy_prefab, ascension, dungeon_tier)
		-- Remember that ascension level starts at 0. Ascension 0 is NOT represented in AscensionMultipliers.
		-- Merge all ascension multipliers up to the current ascension level.
		local ascension_modifiers = {}
		for i = 1, ascension do
			table.insert(ascension_modifiers, AscensionModifierSource[i])
		end

		local dungeon = DungeonTierModifierSource[dungeon_tier]

		local multiplayer = {}
		if enemy_prefab then
			local enemy_tuning = self[enemy_prefab]
			if not enemy_tuning then
				TheLog.ch.Tuning:printf("No tuning table found for enemy [%s]", enemy_prefab)
			end
			if enemy_tuning and not enemy_tuning.multiplayer_mods then
				TheLog.ch.Tuning:printf("No multiplayer_mods found in tuning table for enemy [%s]", enemy_prefab)
			end
			local multiplayer_mods_id = enemy_tuning
				and enemy_tuning.multiplayer_mods
				or "BASIC"

			local multiplayer_mods = ENEMY_MULTIPLAYER_MODS[multiplayer_mods_id]
			multiplayer = multiplayer_mods[GetLastPlayerCount()]
		end

		return ResolveModifiers(
			EnemyModifierNames:Ordered(),
			ENEMY_MODIFIER_DEFAULTS,
			dungeon,
			multiplayer,
			table.unpack(ascension_modifiers) -- Note that the unpack() needs to appear as the final argument.
		)
	end

	--- Returns a table of resolved EnemyModifiers keyed by EnemyModifiers.s.
	--- Uses the AscensionManager's current level for ascension and the curren dungeon for dungeon tier.
	--- If enemy_prefab is not nil, also merge in modifiers based on enemy category.
	function Tuning:GetEnemyModifiers(enemy_prefab)
		local ascension = TheDungeon.progression.components.ascensionmanager:GetCurrentLevel()

		local dungeon_tier = TheSceneGen
			and TheSceneGen.components.scenegen:GetTier()
			or 1

		return self:GetEnemyModifiersAtAscensionAndTier(enemy_prefab, ascension, dungeon_tier)
	end

	-- Resolved PlayerModifiers for the specified weapon, keyed by PlayerModifier.s.
	function Tuning:GetWeaponModifiers(ilvl, weight, rarity)
		return ResolveModifiers(
			PlayerModifierNames:Ordered(),
			PLAYER_MODIFIER_DEFAULTS,
			WeaponILvlModifierSource[ilvl],
			WeaponWeightModifierSource[weight],
			WeaponRarityModifierSource[rarity]
		)
	end

	-- Resolved PlayerModifiers for the specified armour, keyed by PlayerModifier.s.
	function Tuning:GetArmourModifiers(ilvl, weight, rarity)
		return ResolveModifiers(
			PlayerModifierNames:Ordered(),
			PLAYER_MODIFIER_DEFAULTS,
			ArmourILvlModifierSource[ilvl],
			ArmourWeightModifierSource[weight],
			ArmourRarityModifierSource[rarity]
		)
	end

	function Tuning:GetTrapModifiers()
		-- TODO @chrisp #traps - for now we are just using EnemyModifiers for traps
		-- we may want trap-specific (or trap_type-specific) tuning
		return self:GetEnemyModifiers()
	end

	function Tuning:GetEligibleEliteCategories(ascension)
		local eligible = {}
		for i=1,ascension do
			table.appendarrays(eligible, ASCENSION_ALLOWABLE_ELITES[i])
		end
		return eligible
	end

	return Tuning
end

--[[
local WeaponRarityModifierSource = {
	-- Rarity of the weapon slightly affects the damage output.
	[ITEM_RARITY.s.COMMON] =
	{
]]

-- Assert some tuning relationships.
assert(#DungeonTierModifierSource == #ArmourILvlModifierSource and #DungeonTierModifierSource == #WeaponILvlModifierSource, "Please make sure that the number of DungeonTierModifiers, ArmourILvlModifier, and WeaponILvlModifierSource match! These are meant to be form one relationship.")
assert(WeaponRarityModifierSource[ITEM_RARITY.s.COMMON][PlayerModifierNames.s.DamageMult] == WeaponILvlModifierSource[1][PlayerModifierNames.s.DamageMult] * -1, "The negative value of COMMON weapons needs to match the positive value of the first ilvl's buff. This is so our first Basic weapon has the intended tuning.")
assert(ArmourRarityModifierSource[ITEM_RARITY.s.COMMON][PlayerModifierNames.s.DungeonTierDamageReductionMult] == ArmourILvlModifierSource[1][PlayerModifierNames.s.DungeonTierDamageReductionMult] * -1, "The negative value of COMMON armor needs to match the positive value of the first ilvl's buff. This is so our first Basic gear has the intended tuning.")

return BuildTuning
