local Mastery = require "defs.mastery.mastery"
local MetaProgress = require "defs.metaprogression.metaprogress"
local Consumable = require"defs.consumable"
local Constructable = require"defs.constructable"
local Cosmetic = require "defs.cosmetics.cosmetics"
local powerutil = require "util.powerutil"

function Mastery.AddGeneralMastery(id, data)
	Mastery.AddMastery(Mastery.Slots.WEAPON_MASTERY, id, "GENERAL", data)
end

Mastery.AddGeneralMastery("perfect_dodge",
{
	max_progress = 10,
	update_thresholds =
	{
		-- Quick implementation of "update every time"
		0.1, 0.2, 0.3, 0.4, 0.5, 0.6, 0.7, 0.8, 0.9,
	},

	event_triggers =
	{
		["hitboxcollided_invincible"] = function(mst, inst, data)
			if inst.sg:HasStateTag("dodge") then
				mst:DeltaProgress(1)
			end
		end,
	},

	default_unlocked = true,
	difficulty = MASTERY_DIFFICULY.s.EASY,
	-- next_step = { "critical_hit" },
})

Mastery.AddGeneralMastery("quick_rise",
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
			mst:DeltaProgress(1)
		end,
	},

	default_unlocked = true,
	difficulty = MASTERY_DIFFICULY.s.EASY,
	-- next_step = { "dodge_cancel" },
})

Mastery.AddGeneralMastery("critical_hit",
{
	max_progress = 50,
	update_thresholds =
	{
		0.95,
		0.9,
		0.8,
		0.7,
		0.6,
		0.5,
		0.4,
		0.3,
		0.2,
		0.1,
		0.06, -- Update the first few times it happens
		0.04, -- Update the first few times it happens
		0.01, -- Update the first few times it happens
	},
	event_triggers =
	{
		["do_damage"] = function(mst, inst, attack)
			if not powerutil.IsCombatRoom() then
				return
			end

			if attack:GetCrit() then
				mst:DeltaProgress(1)
			end
		end,
	},
	difficulty = MASTERY_DIFFICULY.s.EASY,
})

Mastery.AddGeneralMastery("dodge_cancel",
{
	max_progress = 10,
	event_triggers =
	{
		["dodge_cancel"] = function(mst, inst, data)
			mst:DeltaProgress(1)
		end,
	},
	difficulty = MASTERY_DIFFICULY.s.EASY,
	-- next_step = { "dodge_cancel_on_hit" },
})

Mastery.AddGeneralMastery("dodge_cancel_on_hit",
{
	max_progress = 10,
		update_thresholds =
	{
		-- Quick implementation of "update every time"
		0.1, 0.2, 0.3, 0.4, 0.5, 0.6, 0.7, 0.8, 0.9
	},
	event_triggers =
	{
		["dodge_cancel"] = function(mst, inst, data)
			local valid = false

			local targets_hit = inst.components.hittracker.targets_hit -- Don't use GetTargetsHit() because dodging finishes the attack, hittracker.is_active is false and Get will return none
			if targets_hit then
				for _,target in ipairs(targets_hit) do
					if target:HasTag("mob") or target:HasTag("boss") then
						valid = true
						break
					end
				end
			end

			if valid then
				mst:DeltaProgress(1)
			end
		end,
	},

	difficulty = MASTERY_DIFFICULY.s.MEDIUM,
	rewards =
	{
	},
	-- next_step = { "hitstreak_props" },
})

Mastery.AddGeneralMastery("hitstreak_props",
{
	-- Get a high hitstreak featuring some hits against destructible props
	max_progress = 3,
	tuning =
	{
		hitstreak = 30,
		num_prophits = 3,
	},
	update_thresholds =
	{
		-- Quick implementation of "update every time"
		0.2, 0.4, 0.6, 0.8,
	},
	event_triggers =
	{
		["hitstreak_killed"] = function(mst, inst, data)
			if not powerutil.IsCombatRoom() then
				return
			end

			local THRESHOLD = mst:GetVar("num_prophits")
			local valid = false

			if data.hitstreak > mst:GetVar("hitstreak") then
				local count = 0

				local targets = data.targets
				for _,ent in ipairs(targets) do
					if ent:HasTag("prop") or ent:HasTag("trap") then
						count = count + 1
						if count >= THRESHOLD then
							valid = true
							break
						end
					end
				end

				if valid then
					mst:DeltaProgress(1)
				end
			end

			mst.mem.dodgecancels = 0
		end,
	},

	difficulty = MASTERY_DIFFICULY.s.MEDIUM,
	-- next_step = { "dodge_cancel_hitstreak" },
})

Mastery.AddGeneralMastery("dodge_cancel_hitstreak",
{
	-- Get a high hitstreak featuring multiple dodge cancels
	max_progress = 5,
	tuning =
	{
		hitstreak = 20,
		dodgecancels = 3,
	},
	update_thresholds =
	{
		-- Quick implementation of "update every time"
		0.2, 0.4, 0.6, 0.8,
	},
	event_triggers =
	{
		["dodge_cancel"] = function(mst, inst, data)
			if not powerutil.IsCombatRoom() then
				return
			end

			local hitstreak = inst.components.combat:GetHitStreak()

			if hitstreak > 0 then
				if not mst.mem.dodgecancels then
					mst.mem.dodgecancels = 0
				end
				-- They are on a hitstreak currently, so increment our dodgecancel count
				mst.mem.dodgecancels = mst.mem.dodgecancels + 1
			end
		end,

		["hitstreak_killed"] = function(mst, inst, data)
			if data.hitstreak > mst:GetVar("hitstreak") and mst.mem.dodgecancels and mst.mem.dodgecancels >= mst:GetVar("dodgecancels") then
				mst:DeltaProgress(1)
			end

			mst.mem.dodgecancels = 0
		end,
	},

	difficulty = MASTERY_DIFFICULY.s.MEDIUM,
	-- next_step = { "dodge_cancel_perfect" },
})


Mastery.AddGeneralMastery("dodge_cancel_perfect",
{
	-- Get a Perfect Dodge Cancel
	max_progress = 5,
	update_thresholds =
	{
		-- Quick implementation of "update every time"
		0.2, 0.4, 0.6, 0.8,
	},
	event_triggers =
	{
		["hitboxcollided_invincible"] = function(mst, inst, data)
			if not powerutil.IsCombatRoom() then
				return
			end

			if inst.sg:HasStateTag("dodge") and mst.mem.dodgecanceled then
				-- They just perfect dodged, and they did a dodge cancel. This was a Perfect Dodge.
				mst:DeltaProgress(1)
			end
		end,

		["dodge_cancel"] = function(mst, inst, data)
			mst.mem.dodgecanceled = true
		end,

		["newstate"] = function(mst, inst, data)
			if not inst.sg:HasStateTag("dodge") then
				-- Reset dodgecancel state at the end of the dodge
				mst.mem.dodgecanceled = false
			end
		end,
	},

	rewards = 
	{
		MetaProgress.Reward(Cosmetic, Cosmetic.Slots.PLAYER_BODYPART, "canine_flat_teardrop_mouth_1"),
		MetaProgress.Reward(Cosmetic, Cosmetic.Slots.PLAYER_BODYPART, "ogre_apathetic_mouth_1"),
		MetaProgress.Reward(Cosmetic, Cosmetic.Slots.PLAYER_BODYPART, "mer_cute_mouth"),
	},

	difficulty = MASTERY_DIFFICULY.s.HARD,
	-- next_step = { "hitstreak_perfect_dodge" },
})

Mastery.AddGeneralMastery("hitstreak_perfect_dodge",
{
	-- Get a high hitstreak featuring a perfect dodge
	max_progress = 5,
	tuning =
	{
		hitstreak = 20,
	},
	update_thresholds =
	{
		-- Quick implementation of "update every time"
		0.2, 0.4, 0.6, 0.8,
	},
	event_triggers =
	{
		["hitboxcollided_invincible"] = function(mst, inst, data)
			if inst.sg:HasStateTag("dodge") then
				local hitstreak = inst.components.combat:GetHitStreak()

				if hitstreak > 0 then
					if not mst.mem.perfectdodges then
						mst.mem.perfectdodges = 0
					end
					-- They are on a hitstreak currently, so increment our perfectdodge count
					mst.mem.perfectdodges = mst.mem.perfectdodges + 1
				end
			end
		end,

		["hitstreak_killed"] = function(mst, inst, data)
			if data.hitstreak > mst:GetVar("hitstreak") and mst.mem.perfectdodges and mst.mem.perfectdodges > 0 then
				mst:DeltaProgress(1)
			end

			mst.mem.perfectdodges = 0
		end,
	},

	rewards =
	{
		MetaProgress.Reward(Cosmetic, Cosmetic.Slots.PLAYER_BODYPART, "mer_flipped_strands_hair_front"),
		MetaProgress.Reward(Cosmetic, Cosmetic.Slots.PLAYER_BODYPART, "ogre_fohawk_hair_1"),
		MetaProgress.Reward(Cosmetic, Cosmetic.Slots.PLAYER_BODYPART, "canine_shiba_hair_1"),
	},

	difficulty = MASTERY_DIFFICULY.s.HARD,
	-- next_step = { },
})
