local SGCommon = require "stategraphs.sg_common"
local SGPlayerCommon = require "stategraphs.sg_player_common"
local fmodtable = require "defs.sound.fmodtable"
local PlayerSkillState = require "playerskillstate"
local combatutil = require "util.combatutil"

local events = {}

local CHARGE_THRESHOLD_TIER1 = 8 -- How many frames have we held the attack for? 3 different damage tiers based on how long you held.
local CHARGE_THRESHOLD_TIER2 = 16 -- These thresholds match the other hammer attacks
local FOCUS_TARGETS_THRESHOLD = 1 -- When more than this amount of targets are struck in one swing, every subsequent hit should be a focus

local states =
{
	PlayerSkillState({
		name = "skill_hammer_explodingheavy",
		tags = { "busy" },

		onenter = function(inst)
			inst.AnimState:PlayAnimation("hammer_skill_unstable_pre")
		end,

		timeline =
		{
		},

		onexit = function(inst)

		end,

		events =
		{

			EventHandler("animover", function(inst)
				inst.sg:GoToState("skill_hammer_explodingheavy_activate")
			end),
		},
	}),

	PlayerSkillState({
		name = "skill_hammer_explodingheavy_activate",
		tags = { "busy" },

		onenter = function(inst)
			inst.AnimState:PlayAnimation("hammer_skill_unstable")
		end,

		timeline =
		{
			FrameEvent(0, function(inst)
				inst:PushEvent("stock_explodingheavy")
			end),
		},

		onexit = function(inst)
		end,

		events =
		{
			EventHandler("animover", function(inst)
				inst.sg:GoToState("skill_hammer_explodingheavy_pst")
			end),
		},
	}),

	PlayerSkillState({
		name = "skill_hammer_explodingheavy_pst",
		tags = { "busy" },

		onenter = function(inst)
			inst.AnimState:PlayAnimation("hammer_skill_unstable_pst")
		end,

		timeline =
		{
			FrameEvent(2, SGPlayerCommon.Fns.SetCanDodge),
			FrameEvent(2, SGPlayerCommon.Fns.SetCanAttackOrAbility),
			FrameEvent(5, SGPlayerCommon.Fns.RemoveBusyState),
		},

		onexit = function(inst)

		end,

		events =
		{

			EventHandler("animover", function(inst)
				inst.sg:GoToState("idle")
			end),
		},
	}),
}

return StateGraph("sg_player_hammer_skill_explodingheavy", states, events, "skill_hammer_explodingheavy")
