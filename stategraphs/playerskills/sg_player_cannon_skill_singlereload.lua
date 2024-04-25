local SGCommon = require "stategraphs.sg_common"
local SGPlayerCommon = require "stategraphs.sg_player_common"
local soundutil = require "util.soundutil"
local fmodtable = require "defs.sound.fmodtable"
local PlayerSkillState = require "playerskillstate"
local combatutil = require "util.combatutil"
local powerutil = require "util.powerutil"

local events = {}

local states =
{
	PlayerSkillState({
		name = "skill_cannon_singlereload",
		tags = { "busy" },

		onenter = function(inst)
			if inst.sg.mem.ammo < inst.sg.mem.ammo_max then
				inst.sg:GoToState("skill_cannon_singlereload_yes_pre")
			else
				inst.sg:GoToState("skill_cannon_singlereload_no")
			end
		end,
	}),

	PlayerSkillState({
		name = "skill_cannon_singlereload_yes_pre",
		tags = { "busy" },

		onenter = function(inst)
			inst.AnimState:PlayAnimation("cannon_skill_single_reload_pre")
		end,

		timeline =
		{
		},

		events =
		{
			EventHandler("animover", function(inst)
				inst.sg:GoToState("skill_cannon_singlereload_yes_loop")
			end),
		},

		onexit = function(inst)
		end,
	}),

	PlayerSkillState({
		name = "skill_cannon_singlereload_yes_loop",
		tags = { "busy" },

		onenter = function(inst)
			inst.AnimState:PlayAnimation("cannon_skill_single_reload_loop")
		end,

		timeline =
		{
			FrameEvent(7, function(inst)
				inst.sg.statemem.canqueue_loopreload = true
			end),

			-- If they press the button in this window until "SetCanAttackOrAbility", they'll get a reload straight back into _loop
			-- Otherwise, this will handle them doing the full flow again:

			FrameEvent(9, function(inst)
				inst:PushEvent("cannon_reload", 1)
				inst.sg.statemem.can_loopreload = true
				if inst.sg.statemem.queued_loopreload then
					if inst.sg.mem.ammo < inst.sg.mem.ammo_max then
						inst.sg:GoToState("skill_cannon_singlereload_yes_loop")
					else
						inst.sg:GoToState("skill_cannon_singlereload_no")
					end
				end
			end),

			FrameEvent(11, SGPlayerCommon.Fns.SetCanAttackOrAbility),
		},

		events =
		{
			EventHandler("controlevent", function(inst, data)
				-- Handle "skill" presses manually here

				-- If they press the button when they're able to reload,
				-- 		if they have ammo go right into Loop
				-- 		if not, go to "no"
				if data.control == "skill" then
					if inst.sg.statemem.can_loopreload then
						SGCommon.Fns.FaceActionTarget(inst, data, true, true)

						if inst.sg.mem.ammo < inst.sg.mem.ammo_max then
							inst.sg:GoToState("skill_cannon_singlereload_yes_loop")
						else
							inst.sg:GoToState("skill_cannon_singlereload_no")
						end
					elseif inst.sg.statemem.canqueue_loopreload then
						inst.sg.statemem.queued_loopreload = true
					end
				end
			end),

			EventHandler("animover", function(inst)
				inst.sg:GoToState("skill_cannon_singlereload_pst")
			end),
		},

		onexit = function(inst)
		end,
	}),

	PlayerSkillState({
		name = "skill_cannon_singlereload_no",
		tags = { "busy" },

		onenter = function(inst)
			inst.AnimState:PlayAnimation("cannon_skill_single_reload_no")
			inst.AnimState:PushAnimation("cannon_skill_single_reload_no_pst")
		end,

		timeline =
		{
			FrameEvent(13, SGPlayerCommon.Fns.SetCanAttackOrAbility),
			FrameEvent(17, SGPlayerCommon.Fns.RemoveBusyState),
		},

		events =
		{
			EventHandler("animqueueover", function(inst)
				inst.sg:GoToState("skill_cannon_singlereload_pst")
			end),
		},

		onexit = function(inst)
		end,
	}),

	PlayerSkillState({
		name = "skill_cannon_singlereload_pst",
		tags = { "busy" },

		onenter = function(inst)
			inst.AnimState:PlayAnimation("cannon_skill_single_reload_pst")
		end,

		timeline =
		{
			FrameEvent(2, SGPlayerCommon.Fns.RemoveBusyState),
		},

		events =
		{
			EventHandler("animqueueover", function(inst)
				inst.sg:GoToState("idle")
			end),
		},

		onexit = function(inst)
		end,
	}),
}

return StateGraph("sg_player_cannon_skill_singlereload", states, events, "skill_cannon_singlereload")
