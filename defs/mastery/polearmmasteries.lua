local Mastery = require "defs.mastery.mastery"
local MetaProgress = require "defs.metaprogression.metaprogress"
local Consumable = require"defs.consumable"
local Constructable = require"defs.constructable"
local Cosmetic = require "defs.cosmetics.cosmetics"
local powerutil = require "util.powerutil"

function Mastery.AddPolearmMastery(id, data)

	--jcheng: wrap all the event triggers to check if we're using the right weapon first
	for k, fn in pairs(data.event_triggers) do
		data.event_triggers[k] = function(mst, inst, data)
			if inst.components.inventory:GetEquippedWeaponType() ~= WEAPON_TYPES.POLEARM then
				return
			end
			fn(mst, inst, data)
		end
	end

	Mastery.AddMastery(Mastery.Slots.WEAPON_MASTERY, id, WEAPON_TYPES.POLEARM, data)

end

local POLEARM_TIP_ATTACKS =
{
	"LIGHT_ATTACK_1",
	"LIGHT_ATTACK_2",
	"LIGHT_ATTACK_3",
	"REVERSE",
	"HEAVY_ATTACK",
	"MULTITHRUST",
}

-- FOCUS HITS
Mastery.AddPolearmMastery("polearm_focus_hits_tip",
{
	max_progress = 10,
	-- Get a focus hit with the tip of the spear
	event_triggers =
	{
		["do_damage"] = function(mst, inst, attack)
			local attack_name = attack:GetNameID()
			if attack:GetFocus() and table.contains(POLEARM_TIP_ATTACKS, attack_name) then
				mst:DeltaProgress(1)
			end
		end,
	},

	rewards =
	{
	},
	difficulty = MASTERY_DIFFICULY.s.EASY,
})

Mastery.AddPolearmMastery("polearm_drill_multiple_enemies_basic",
{
	max_progress = 5,
	-- Get a focus hit with the spinning drill
	event_triggers =
	{
		["do_damage"] = function(mst, inst, attack)
			local attack_id = attack:GetNameID()

			local hittracker = inst.components.hittracker
			local targets_hit = hittracker:GetTargetsHit()

			if attack_id == "DRILL" and #targets_hit > 1 then
				mst:DeltaProgress(1)
			end
		end,
	},
	rewards =
	{
	},
	difficulty = MASTERY_DIFFICULY.s.EASY,
})

Mastery.AddPolearmMastery("polearm_focus_kills",
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

	rewards =
	{
	},
	difficulty = MASTERY_DIFFICULY.s.MEDIUM,
})

Mastery.AddPolearmMastery("polearm_multithrust_focus",
{
	-- Multithrust where every hit is focus
	tuning = {
		num_hits = 7,
	},
	event_triggers =
	{
		["attack_state_start"] = function(mst, inst, data)
			-- Reset every attack start
			mst.mem.focushits = 0
			mst.mem.totalhits = 0
		end,

		["do_damage"] = function(mst, inst, attack)
			if attack:GetNameID() == "MULTITHRUST" then
				if powerutil.TargetIsEnemyOrDestructibleProp(attack) then
					if attack:GetFocus() then
						mst.mem.focushits = mst.mem.focushits + 1
					end
					mst.mem.totalhits = mst.mem.totalhits + 1
				end
			end
		end,

		["heavy_attack"] = function(mst, inst, data)
			if data.attack_id == "MULTITHRUST" then
				if mst.mem.totalhits == mst:GetVar("num_hits") and mst.mem.focushits == mst.mem.totalhits then
					mst:DeltaProgress(1)
				end
			end
			mst.mem.totalhits = 0
			mst.mem.focushits = 0
		end,
	},
	rewards =
	{
	},
	difficulty = MASTERY_DIFFICULY.s.HARD,
})

Mastery.AddPolearmMastery("polearm_shove_counterattack",
{
	event_triggers =
	{
		["skill"] = function(mst, inst, data)
			if data.targets_hit then
				for i,ent in ipairs(data.targets_hit) do
					if powerutil.EntityIsEnemyOrDestructibleProp(ent) then
						if ent.sg and ent.sg.laststate and ent.sg.laststate.tags ~= nil then
							if table.contains(ent.sg.laststate.tags, "attack") then
								mst:DeltaProgress(1)
							end
						end
					end
				end
			end
		end,
	},
	rewards =
	{
	},
	difficulty = MASTERY_DIFFICULY.s.MEDIUM,
})

Mastery.AddPolearmMastery("polearm_single_hit",
{
	-- Kill an enemy in a single hit
	max_progress = 10,
	on_add_fn = function(mst, inst, is_upgrade)
		mst.mem.targets_health = {}
	end,

	event_triggers =
	{
		["do_damage"] = function(mst, inst, attack)
			local target = attack:GetTarget()
			local health = target.components.health

			if health then
				mst.mem.targets_health[inst] = health:GetCurrent() -- Store their health on this hit, so we can compare later and see if they died in one hit.
			end
		end,

		["kill"] = function(mst, inst, data)
			local target = data.attack:GetTarget()

			if powerutil.TargetIsEnemy(data.attack) then
				if mst.mem.targets_health[inst] and target.components.health then
					local health = mst.mem.targets_health[inst]
					local max_health = target.components.health:GetMax()

					if health == max_health	then
						mst:DeltaProgress(1)
					end
				end
			end
		end,
	},
	rewards =
	{
	},
	difficulty = MASTERY_DIFFICULY.s.MEDIUM,
})

Mastery.AddPolearmMastery("polearm_hitstreak_basic",
{
	tuning =
	{
		hitstreak = 20,
	},
	max_progress = 10,
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
	},
	difficulty = MASTERY_DIFFICULY.s.EASY,	
})

Mastery.AddPolearmMastery("polearm_hitstreak_advanced",
{
	-- Get a hitstreak containing more than one Drill's
	max_progress = 5,
	tuning =
	{
		hitstreak = 40,
		num_drills = 3,
	},
	event_triggers =
	{
		["hitstreak_killed"] = function(mst, inst, data)
			if not powerutil.IsCombatRoom() then
				return
			end

			local hitstreak = data.hitstreak
			if hitstreak >= mst:GetVar("hitstreak") then
				local drills = 0
				for i,attack_id in ipairs(data.attacks) do
					if attack_id == "DRILL" then
						drills = drills + 1
					end
				end

				if drills >= mst:GetVar("num_drills") then
					mst:DeltaProgress(1)
				end
			end
		end,
	},
	rewards =
	{
	},
	difficulty = MASTERY_DIFFICULY.s.MEDIUM,
})

Mastery.AddPolearmMastery("polearm_hitstreak_expert",
{
	-- Get a long hitstreak
	max_progress = 5,
	tuning =
	{
		hitstreak = 100,
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
		MetaProgress.Reward(Cosmetic, Cosmetic.Slots.PLAYER_BODYPART, "mer_guppy_ears_1"),
		MetaProgress.Reward(Cosmetic, Cosmetic.Slots.PLAYER_BODYPART, "canine_bat_ears_1"),
		MetaProgress.Reward(Cosmetic, Cosmetic.Slots.PLAYER_BODYPART, "ogre_round_notch_ears"),
	},

	difficulty = MASTERY_DIFFICULY.s.HARD,
})

-- BASIC MOVES
Mastery.AddPolearmMastery("polearm_fading_light",
{
	-- Kill enemies with Fading Light
	event_triggers =
	{
		["kill"] = function(mst, inst, data)
			local attack_name = data.attack:GetNameID()
			if attack_name == "REVERSE" then
				mst:DeltaProgress(1)
			end
		end,
	},
	hide = true,
})

Mastery.AddPolearmMastery("polearm_drill",
{
	-- Kill enemies with Spinning Drill
	event_triggers =
	{
		["kill"] = function(mst, inst, data)
			local attack_name = data.attack:GetNameID()
			if attack_name == "DRILL" then
				mst:DeltaProgress(1)
			end
		end,
	},

	hide = true,
})

Mastery.AddPolearmMastery("polearm_multithrust",
{
	-- Kill enemies with Multithrust
	event_triggers =
	{
		["kill"] = function(mst, inst, data)
			local attack_name = data.attack:GetNameID()
			if attack_name == "MULTITHRUST" then
				mst:DeltaProgress(1)
			end
		end,
	},
	hide = true,
})

Mastery.AddPolearmMastery("polearm_heavy_attack",
{
	-- Kill enemies with Heavy Attack
	event_triggers =
	{
		["kill"] = function(mst, inst, data)
			local attack_name = data.attack:GetNameID()
			if attack_name == "HEAVY_ATTACK" then
				mst:DeltaProgress(1)
			end
		end,
	},
	hide = true,
})

-- ADVANCED MOVES

Mastery.AddPolearmMastery("polearm_drill_multiple_enemies_advanced",
{
	-- Start a hit streak with Dodge xx L
	tuning =
	{
		num_targets = 5,
	},
	event_triggers =
	{
		["light_attack"] = function(mst, inst, data)
			local attack_id = data.attack_id
			local targets_hit = data.targets_hit
			
			if attack_id == "DRILL" and #targets_hit >= mst:GetVar("num_targets") then
				mst:DeltaProgress(1)
			end
		end,
	},
	hide = true,
})

-- Mastery.AddPolearmMastery("polearm_counterattack",
-- {
-- 	-- Kill enemies while they are attacking
-- 	tags = { },
-- 	tuning = {
-- 	},
-- 	event_triggers =
-- 	{
-- 		["kill"] = function(mst, inst, data)
-- 			local target = data.attack:GetTarget()
-- 			if table.contains(target.sg.laststate.tags, "attack") then
-- 				mst:DeltaProgress(1)
-- 			end
-- 		end,
-- 	},
-- })