local Mastery = require "defs.mastery.mastery"
local MetaProgress = require "defs.metaprogression.metaprogress"
local Consumable = require"defs.consumable"
local Constructable = require"defs.constructable"
local Cosmetic = require "defs.cosmetics.cosmetics"
local powerutil = require "util.powerutil"

function Mastery.AddCannonMastery(id, data)
	--jcheng: wrap all the event triggers to check if we're using the right weapon first
	for k, fn in pairs(data.event_triggers) do
		data.event_triggers[k] = function(mst, inst, data)
			if inst.components.inventory:GetEquippedWeaponType() ~= WEAPON_TYPES.CANNON then
				return
			end
		fn(mst, inst, data)
		end
	end

	Mastery.AddMastery(Mastery.Slots.WEAPON_MASTERY, id, WEAPON_TYPES.CANNON, data)
end

Mastery.AddCannonMastery("cannon_perfect_dodge",
{
	max_progress = 5,
	update_thresholds =
	{
		-- Quick implementation of "update every time"
		0.2, 0.4, 0.6, 0.8,
	},
	event_triggers =
	{
		["hitboxcollided_invincible"] = function(mst, inst, data)
			if inst.sg:HasStateTag("dodge") then
				mst:DeltaProgress(1)
			end
		end,
	},

	rewards =
	{
	},
	difficulty = MASTERY_DIFFICULY.s.HARD,
})

Mastery.AddCannonMastery("cannon_quick_rise",
{
	max_progress = 5,
	update_thresholds =
	{
		-- Quick implementation of "update every time"
		0.2, 0.4, 0.6, 0.8,
	},
	event_triggers =
	{
		["quick_rise"] = function(mst, inst, data)
			if inst.sg:HasStateTag("attack") then
				mst:DeltaProgress(1)
			end
		end,
	},

	rewards =
	{
	},
	difficulty = MASTERY_DIFFICULY.s.MEDIUM,
})

Mastery.AddCannonMastery("cannon_perfect_reload",
{
	max_progress = 5,
	update_thresholds =
	{
		-- Quick implementation of "update every time"
		0.2, 0.4, 0.6, 0.8,
	},
	event_triggers =
	{
		["start_cannonreload_fast"] = function(mst, inst)
			mst:DeltaProgress(1)
		end,
	},

	rewards =
	{
	},

	difficulty = MASTERY_DIFFICULY.s.EASY,
})

Mastery.AddCannonMastery("cannon_butt_reload",
{
	max_progress = 5,
	update_thresholds =
	{
		-- Quick implementation of "update every time"
		0.2, 0.4, 0.6, 0.8,
	},
	event_triggers =
	{
		["cannon_butt_reload"] = function(mst, inst)
			mst:DeltaProgress(1)
		end,
	},

	rewards =
	{
	},
	difficulty = MASTERY_DIFFICULY.s.EASY,
})


Mastery.AddCannonMastery("cannon_focus",
{
	max_progress = 10,
	event_triggers =
	{
		["do_damage"] = function(mst, inst, attack)
			local attack_id = attack:GetNameID()
			if attack:GetFocus() and (attack_id == "BLAST" or attack_id == "SHOOT") then
				mst.mem.focushit = true
			end
		end,

		["light_attack"] = function(mst, inst, data)
			if mst.mem.focushit then
				mst:DeltaProgress(1)
			end

			mst.mem.focushit = false
		end,
		["heavy_attack"] = function(mst, inst, data)
			if mst.mem.focushit then
				mst:DeltaProgress(1)
			end

			mst.mem.focushit = false
		end,
	},

	rewards =
	{
	},
	difficulty = MASTERY_DIFFICULY.s.MEDIUM,
})

Mastery.AddCannonMastery("cannon_focus_shockwave",
{
	max_progress = 5,
	event_triggers =
	{
		["do_damage"] = function(mst, inst, attack)
			if not powerutil.TargetIsEnemy(attack) then
				return
			end

			local attack_id = attack:GetNameID()
			if attack:GetFocus() and (attack_id == "SHOCKWAVE_MEDIUM" or attack_id == "SHOCKWAVE_WEAK") then
				mst.mem.focushit = true
			end
		end,

		["light_attack"] = function(mst, inst, data)
			if mst.mem.focushit then
				mst:DeltaProgress(1)
			end

			mst.mem.focushit = false
		end,
	},

	rewards =
	{
	},
	difficulty = MASTERY_DIFFICULY.s.EASY,
})

Mastery.AddCannonMastery("cannon_hitstreak_basic",
{
	-- Get a hitstreak
	max_progress = 10,
	tuning = 
	{
		hitstreak = 20,
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

Mastery.AddCannonMastery("cannon_hitstreak_heavy",
{
	-- Get a hitstreak containing more than one Heavy Attack
	max_progress = 10,
	tuning = 
	{
		hitstreak = 30,
		num_butts = 2,
		num_heavyhits = 15,
	},
	event_triggers =
	{
		["hitstreak_killed"] = function(mst, inst, data)
			if not powerutil.IsCombatRoom() then
				return
			end

			local hitstreak = data.hitstreak
			if hitstreak >= mst:GetVar("hitstreak") then
				local butts = 0
				local blasts = 0
				for i,attack_id in ipairs(data.attacks) do
					if attack_id == "CANNON_BUTT" then
						butts = butts + 1
					elseif attack_id == "BLAST" then
						blasts = blasts + 1
					end
				end

				if butts >= mst:GetVar("num_butts") and blasts >= mst:GetVar("num_heavyhits") then
					mst:DeltaProgress(1)
				end
			end
		end,
	},

	difficulty = MASTERY_DIFFICULY.s.HARD,

	rewards = 
	{
		MetaProgress.Reward(Cosmetic, Cosmetic.Slots.PLAYER_BODYPART, "ogre_slope_nose_1"),
		MetaProgress.Reward(Cosmetic, Cosmetic.Slots.PLAYER_BODYPART, "canine_clover_nose_1"),
		MetaProgress.Reward(Cosmetic, Cosmetic.Slots.PLAYER_BODYPART, "mer_small_nose"),
	},
})

Mastery.AddCannonMastery("cannon_hitstreak_advanced",
{
	-- Get a hitstreak containing more than one Heavy Attack
	max_progress = 5,
	tuning = 
	{
		hitstreak = 50,
	},
	event_triggers =
	{
		["hitstreak_killed"] = function(mst, inst, data)
			if not powerutil.IsCombatRoom() then
				return
			end

			local hitstreak = data.hitstreak
			if hitstreak >= mst:GetVar("hitstreak") then
				mst:DeltaProgress(1)
			end
		end,
	},

	rewards =
	{
		MetaProgress.Reward(Cosmetic, Cosmetic.Slots.PLAYER_BODYPART, "ogre_pointed_quiff_hair_1"),
		MetaProgress.Reward(Cosmetic, Cosmetic.Slots.PLAYER_BODYPART, "mer_flipped_strands_hair_1"),
		MetaProgress.Reward(Cosmetic, Cosmetic.Slots.PLAYER_BODYPART, "canine_tuxedo_hair_1"),
	},

	difficulty = MASTERY_DIFFICULY.s.HARD,
})