local Mastery = require "defs.mastery.mastery"
local MetaProgress = require "defs.metaprogression.metaprogress"
local Consumable = require"defs.consumable"
local Constructable = require"defs.constructable"
local Cosmetic = require "defs.cosmetics.cosmetics"
local powerutil = require "util.powerutil"
local SGCommon = require "stategraphs.sg_common"

function Mastery.AddHammerMastery(id, data)
	--jcheng: wrap all the event triggers to check if we're using the right weapon first
	for k, fn in pairs(data.event_triggers) do
		data.event_triggers[k] = function(mst, inst, data)
			if inst.components.inventory:GetEquippedWeaponType() ~= WEAPON_TYPES.HAMMER then
				return
			end
			fn(mst, inst, data)
		end
	end

	Mastery.AddMastery(Mastery.Slots.WEAPON_MASTERY, id, WEAPON_TYPES.HAMMER, data)
end

-- Focus Attack Tree
Mastery.AddHammerMastery("hammer_focus_multiple_targets",
{
	max_progress = 10,
	event_triggers =
	{
		["light_attack"] = function(mst, inst, data)
			if #data.targets_hit >= 2 then
				mst:DeltaProgress(1)
			end
		end,

		["heavy_attack"] = function(mst, inst, data)
			if #data.targets_hit >= 2 then
				mst:DeltaProgress(1)
			end
		end,

		["skill"] = function(mst, inst, data)
			if #data.targets_hit >= 2 then
				mst:DeltaProgress(1)
			end
		end,
	},

	difficulty = MASTERY_DIFFICULY.s.EASY,
})

Mastery.AddHammerMastery("hammer_air_spin",
{
	max_progress = 5,
	-- Hit anything with LLHH
	event_triggers =
	{
		["do_damage"] = function(mst, inst, attack)
			local attack_name = attack:GetNameID()
			if attack_name == "HEAVY_AIR_SPIN" and attack:GetFocus() then
				mst:DeltaProgress(1)
			end
		end,
	},

	difficulty = MASTERY_DIFFICULY.s.EASY,
})

Mastery.AddHammerMastery("hammer_focus_hits",
{
	-- Get kills with focus hits
	event_triggers =
	{
		["kill"] = function(mst, inst, data)
			if powerutil.TargetIsEnemy(data.attack) then
				if data.attack:GetFocus() then
					mst:DeltaProgress(1)
				end
			end
		end,
	},

	difficulty = MASTERY_DIFFICULY.s.MEDIUM,
	rewards =
	{
	},
})

local function _increment_if_included_destructible(mst, inst, data)
	if #data.targets_hit >= 2 then
		local included_destructible = false
		local included_enemy = false
		for k,v in pairs(data.targets_hit) do
			if v:HasTag("prop_destructible") or v:HasTag("trap") then
				included_destructible = true
			elseif v:HasTag("mob") or v:HasTag("boss") then
				included_enemy = true
			end
		end

		if included_destructible and included_enemy then
			mst:DeltaProgress(1)
		end
	end
end
Mastery.AddHammerMastery("hammer_focus_hits_destructibles",
{
	-- Use props to get focus hits
	max_progress = 15,
	event_triggers =
	{
		["heavy_attack"] = _increment_if_included_destructible,
		["light_attack"] = _increment_if_included_destructible,
	},
	difficulty = MASTERY_DIFFICULY.s.MEDIUM,
})

Mastery.AddHammerMastery("hammer_thump",
{
	-- Kill multiple enemies with hammer_thump skill
	tuning = {
		enemies = 3,
	},
	event_triggers =
	{
		["skill"] = function(mst, inst, data)
			local attack_name = data.attack_id
			local enemy_count = powerutil.CountEnemiesInTargetsHit(data.targets_hit)

			if attack_name == "THUMP_TIER2" and enemy_count >= mst:GetVar("enemies") then
				mst:DeltaProgress(1)
			end
		end,
	},

	difficulty = MASTERY_DIFFICULY.s.MEDIUM,
})
Mastery.AddHammerMastery("hammer_golf_swing",
{
	-- Hit multiple enemies with Golf Swing
	tuning = {
		enemies = 3,
	},
	event_triggers =
	{
		["heavy_attack"] = function(mst, inst, data)
			local attack_name = data.attack_id
			local enemy_count = powerutil.CountEnemiesInTargetsHit(data.targets_hit)

			if attack_name == "GOLF_SWING_FULL" and enemy_count >= mst:GetVar("enemies") then
				mst:DeltaProgress(1)
			end
		end,
	},

	difficulty = MASTERY_DIFFICULY.s.MEDIUM,	
})

Mastery.AddHammerMastery("hammer_hitstreak_basic",
{
	-- Get a hitstreak
	max_progress = 10,
	tuning = {
		hitstreak = 10,
	},
	event_triggers =
	{
		['hitstreak_killed'] = function(mst, inst, data)
			if not powerutil.IsCombatRoom() then
				return
			end

			if data.hitstreak >= mst:GetVar("hitstreak") then
				mst:DeltaProgress(1)
			end
		end,
	},

	difficulty = MASTERY_DIFFICULY.s.EASY,	
})

Mastery.AddHammerMastery("hammer_hitstreak_fading_L",
{
	-- Get a hitstreak containing more than one Fading Light's
	tuning = {
		hitstreak = 20,
		fading_lights = 2,
	},
	event_triggers =
	{
		max_progress = 10,
		["hitstreak_killed"] = function(mst, inst, data)
			if not powerutil.IsCombatRoom() then
				return
			end

			local hitstreak = data.hitstreak
			if hitstreak >= mst:GetVar("hitstreak") then
				local fading_lights = 0
				for i,attack_id in ipairs(data.attacks) do
					if attack_id == "FADING_LIGHT" then
						fading_lights = fading_lights + 1
					end
				end

				if fading_lights >= mst:GetVar("fading_lights") then
					mst:DeltaProgress(1)
				end
			end
		end,
	},

	
	rewards =
	{
		MetaProgress.Reward(Cosmetic, Cosmetic.Slots.PLAYER_BODYPART, "thin_brow_mer_1"),
		MetaProgress.Reward(Cosmetic, Cosmetic.Slots.PLAYER_BODYPART, "thin_brow_ogre_1"),
		MetaProgress.Reward(Cosmetic, Cosmetic.Slots.PLAYER_BODYPART, "thin_brow_canine_1"),
	},

	difficulty = MASTERY_DIFFICULY.s.MEDIUM,
})

Mastery.AddHammerMastery("hammer_hitstreak_advanced",
{
	-- Get a hitstreak
	max_progress = 10,
	tuning = {
		hitstreak = 50,
	},
	event_triggers =
	{
		['hitstreak_killed'] = function(mst, inst, data)
			if not powerutil.IsCombatRoom() then
				return
			end

			if data.hitstreak >= mst:GetVar("hitstreak") then
				mst:DeltaProgress(1)
			end
		end,
	},

	rewards =
	{
		MetaProgress.Reward(Cosmetic, Cosmetic.Slots.PLAYER_BODYPART, "ogre_droopy_eyes"),
		MetaProgress.Reward(Cosmetic, Cosmetic.Slots.PLAYER_BODYPART, "mer_plump_eyes"),
		MetaProgress.Reward(Cosmetic, Cosmetic.Slots.PLAYER_BODYPART, "canine_half_moon_eyes"),
	},

	difficulty = MASTERY_DIFFICULY.s.HARD,
})


-- BASIC MOVES
Mastery.AddHammerMastery("hammer_fading_light",
{
	-- Kill enemies with fading light
	event_triggers =
	{
		["kill"] = function(mst, inst, data)
			local attack_name = data.attack:GetNameID()
			if attack_name == "FADING_LIGHT" then
				mst:DeltaProgress(1)
			end
		end,
	},
	hide = true,
})

Mastery.AddHammerMastery("hammer_heavy_slam",
{
	-- Kill enemies with Lariat
	event_triggers =
	{
		["kill"] = function(mst, inst, data)
			local attack_name = data.attack:GetNameID()
			if attack_name == "HEAVY_SLAM" then
				mst:DeltaProgress(1)
			end
		end,
	},
	hide = true,
})

Mastery.AddHammerMastery("hammer_lariat",
{
	-- Kill enemies with Lariat
	event_triggers =
	{
		["kill"] = function(mst, inst, data)
			local attack_name = data.attack:GetNameID()
			if attack_name == "LARIAT" then
				mst:DeltaProgress(1)
			end
		end,
	},
	hide = true,
})


-- ADVANCED MOVES
Mastery.AddHammerMastery("hammer_hitstreak_dodge_L",
{
	-- Start a hit streak with Dodge xx L
	tuning = {
		hitstreak = 10,
	},
	event_triggers =
	{
		["hitstreak_killed"] = function(mst, inst, data)
			if not powerutil.IsCombatRoom() then
				return
			end

			local hitstreak = data.hitstreak
			if hitstreak >= mst:GetVar("hitstreak") then
				local first_attack = data.attacks[1]
				if first_attack == "LIGHT_ATTACK_3" then
					mst:DeltaProgress(1)
				end
			end
		end,
	},
	hide = true,
})

Mastery.AddHammerMastery("hammer_counterattack",
{
	-- Kill enemies while they are attacking
	event_triggers =
	{
		["kill"] = function(mst, inst, data)
			if not powerutil.IsCombatRoom() then
				return
			end

			local target = data.attack:GetTarget()
			target = SGCommon.Fns.SanitizeTarget(target)
			if target and target.sg and target.sg.laststate and target.sg.laststate.tags then
				if table.contains(target.sg.laststate.tags, "attack") then
					mst:DeltaProgress(1)
				end
			end
		end,
	},

	rewards =
	{
		
	},
	hide = true,
})