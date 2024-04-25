local Mastery = require "defs.mastery.mastery"
local MetaProgress = require "defs.metaprogression.metaprogress"
local Consumable = require"defs.consumable"
local Constructable = require"defs.constructable"
local Cosmetic = require "defs.cosmetics.cosmetics"
local powerutil = require "util.powerutil"

function Mastery.AddShotputMastery(id, data)
	--jcheng: wrap all the event triggers to check if we're using the right weapon first
	for k, fn in pairs(data.event_triggers) do
		data.event_triggers[k] = function(mst, inst, data)
			if inst.components.inventory:GetEquippedWeaponType() ~= WEAPON_TYPES.SHOTPUT then
				return
			end
			fn(mst, inst, data)
		end
	end

	Mastery.AddMastery(Mastery.Slots.WEAPON_MASTERY, id, WEAPON_TYPES.SHOTPUT, data)
end

-- Focus Hit Masteries

Mastery.AddShotputMastery("shotput_focus_thrown",
{
	max_progress = 10,
	event_triggers =
	{
		["do_damage"] = function(mst, inst, attack)
			local attack_name = attack:GetNameID()
			if attack_name == "SHOTPUT_PROJECTILE_THROWN" and attack:GetFocus() then
				mst:DeltaProgress(1)
			end
		end,
	},

	difficulty = MASTERY_DIFFICULY.s.EASY,

	rewards =
	{
	},
})

Mastery.AddShotputMastery("shotput_focus_spiked",
{
	max_progress = 10,
	event_triggers =
	{
		["do_damage"] = function(mst, inst, attack)
			local attack_name = attack:GetNameID()
			if attack_name == "SHOTPUT_PROJECTILE_SPIKED" or attack_name == "SHOTPUT_PROJECTILE_SPIKED_KICK" and attack:GetFocus() then
				mst:DeltaProgress(1)
			end
		end,
	},

	difficulty = MASTERY_DIFFICULY.s.EASY,

	rewards =
	{
	},
})


Mastery.AddShotputMastery("shotput_focus_kills",
{
	max_progress = 20,
	event_triggers =
	{
		["kill"] = function(mst, inst, data)
			if not powerutil.TargetIsEnemy(data.attack) then
				return
			end

			local attack = data.attack
			if attack:GetFocus() then
				mst:DeltaProgress(1)
			end
		end,
	},

	difficulty = MASTERY_DIFFICULY.s.MEDIUM,

	rewards =
	{
	},
})


Mastery.AddShotputMastery("shotput_focus_rebound",
{
	max_progress = 10,
	event_triggers =
	{
		["do_damage"] = function(mst, inst, attack)
			if not powerutil.TargetIsEnemyOrDestructibleProp(attack) then
				return
			end

			local attack_name = attack:GetNameID()
			if attack_name == "SHOTPUT_PROJECTILE_REBOUND" and attack:GetFocus() then
				mst:DeltaProgress(1)
			end
		end,
	},

	difficulty = MASTERY_DIFFICULY.s.MEDIUM,

	rewards =
	{
	},
})

Mastery.AddShotputMastery("shotput_recall",
{
	max_progress = 10,
	event_triggers =
	{
		["kill"] = function(mst, inst, data)
			local attack = data.attack

			if not powerutil.TargetIsEnemy(attack) then
				return
			end

			local attack_name = attack:GetNameID()
			if attack_name == "SHOTPUT_PROJECTILE_RECALLED" then
				mst:DeltaProgress(1)
			end
		end,
	},

	difficulty = MASTERY_DIFFICULY.s.MEDIUM,

	rewards =
	{
	},
})

Mastery.AddShotputMastery("shotput_juggle_melee_kill",
{
	max_progress = 10,
	event_triggers =
	{
		["kill"] = function(mst, inst, data)
			if not powerutil.TargetIsEnemy(data.attack) then
				return
			end

			local projectiles = inst.sg.mem.active_projectiles
			if not projectiles then return end

			local is_melee = data.attack and data.attack:GetNameID() == "SHOTPUT_PLAYER_MELEE"

			local is_airborne = false

			for projectile, _ in pairs(projectiles) do
				if projectile.sg:HasStateTag("airborne") then
					is_airborne = true
					break
				end
			end

			if is_melee and is_airborne then
				mst:DeltaProgress(1)
			end
		end,
	},

	difficulty = MASTERY_DIFFICULY.s.HARD,

	rewards =
	{
	},
})

-- Hitstreak Masteries
Mastery.AddShotputMastery("shotput_hitstreak_basic",
{
	-- Get a hitstreak
	max_progress = 10,
	tuning = {
		hitstreak = 15,
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

-- This is quite easy to complete right now because spiking the ball counts
Mastery.AddShotputMastery("shotput_hitstreak_melee",
{
	max_progress = 10,
	tuning = {
		hitstreak = 30,
		melee = 10,
		striker = 10,
	},
	event_triggers =
	{
		['hitstreak_killed'] = function(mst, inst, data)
			if not powerutil.IsCombatRoom() then
				return
			end

			local hitstreak = data.hitstreak
			if hitstreak >= mst:GetVar("hitstreak") then
				local melee_hits = 0
				local ball_hits = 0
				for i,attack_id in ipairs(data.attacks) do
					if attack_id == "SHOTPUT_PLAYER_MELEE" then
						melee_hits = melee_hits + 1
					elseif string.find(attack_id, "SHOTPUT_PROJECTILE") then
						ball_hits = ball_hits + 1
					end
				end

				if melee_hits >= mst:GetVar("melee") and ball_hits >= mst:GetVar("striker") then
					mst:DeltaProgress(1)
				end
			end
		end,
	},

	difficulty = MASTERY_DIFFICULY.s.MEDIUM,
})

Mastery.AddShotputMastery("shotput_hitstreak_master",
{
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
		MetaProgress.Reward(Cosmetic, Cosmetic.Slots.PLAYER_BODYPART, "ogre_horns_bull_ornament_1"),
		MetaProgress.Reward(Cosmetic, Cosmetic.Slots.PLAYER_BODYPART, "mer_freckles_ornament_1"),
		MetaProgress.Reward(Cosmetic, Cosmetic.Slots.PLAYER_BODYPART, "canine_triangle_ornament_1"),
	},

	difficulty = MASTERY_DIFFICULY.s.HARD,
})

-- Hidden Masteries

Mastery.AddShotputMastery("shotput_juggle_10",
{
	hide = true,
	max_progress = 3,
	event_triggers =
	{
		["do_shotput_juggle"] = function(mst, inst, juggle_count)
			if juggle_count%10 == 0 then
				mst:DeltaProgress(1)
			end
		end,
	},

	difficulty = MASTERY_DIFFICULY.s.EASY,

	rewards =
	{
	},
})

Mastery.AddShotputMastery("shotput_spiked_kick_knockdown",
{
	hide = true,
	max_progress = 10,
	event_triggers =
	{
		["kill"] = function(mst, inst, data)
			if not powerutil.IsCombatRoom() then
				return
			end

			local attack = data.attack
			local attack_name = attack:GetNameID()

			if attack_name == "SHOTPUT_PROJECTILE_SPIKED_KICK" and attack:GetFocus() then
				mst:DeltaProgress(1)
			end
		end,
	},

	difficulty = MASTERY_DIFFICULY.s.EASY,

	rewards =
	{
	},
})


Mastery.AddShotputMastery("shotput_hitstreak_recall",
{
	hide = true,
	max_progress = 10,
	event_triggers =
	{
		['hitstreak_killed'] = function(mst, inst, data)
			if not powerutil.IsCombatRoom() then
				return
			end

			local hitstreak = data.hitstreak
			if hitstreak >= 20 then
				local rebound_hits = 0
				for i,attack_id in ipairs(data.attacks) do
					if attack_id == "SHOTPUT_PROJECTILE_RECALLED" then
						rebound_hits = rebound_hits + 1
					end
				end

				if rebound_hits >= 2 then
					mst:DeltaProgress(1)
				end
			end
		end,
	},

	difficulty = MASTERY_DIFFICULY.s.EASY,	
})
