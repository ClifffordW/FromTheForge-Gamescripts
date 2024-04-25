local SGPlayerCommon = require "stategraphs.sg_player_common"
local soundutil = require "util.soundutil"
local fmodtable = require "defs.sound.fmodtable"
local PlayerSkillState = require "playerskillstate"

-- If the player taps Skill, they will just show the AOE preview and then back out of it.
-- If they hold Skill, they'll go into the actual heal state.

local function HasStocksRemaining(inst)
	local skillpower = inst.components.powermanager:GetPowerByName("miniboss_gourdo")
	return skillpower.persistdata.stocks_left > 0
end

local events = {}
local states =
{
	PlayerSkillState({
		name = "skill_miniboss_gourdo",
		tags = { "busy" },

		onenter = function(inst)
			if HasStocksRemaining(inst) then
				inst.sg:GoToState("skill_miniboss_gourdo_heal_pre")
			else
				inst.sg:GoToState("skill_miniboss_gourdo_no_heal")
			end
		end,
	}),

	PlayerSkillState({
		name = "skill_miniboss_gourdo_heal_pre",
		tags ={ "busy" },

		onenter = function(inst, looped)
			-- looped = we are getting here from holding the skill down for multiple pulses. if looped=false, this is a first press.
			inst.AnimState:PlayAnimation(looped and "skill_gourdo_heal_loop_pre" or "skill_gourdo_heal_pre")
			SGPlayerCommon.Fns.ShowAOEHealPreview(inst)
		end,

		timeline =
		{
			FrameEvent(4, function(inst) inst.sg.statemem.canexit = true end), -- if they release the button, after this point they can go back
			FrameEvent(4, function(inst)
				inst.sg.mem.roar_sound = soundutil.PlayCodeSound(inst,fmodtable.Event.Skill_Gourdo_Roar,{
					max_count = 1
				})
			end),

			-- Allow dodge canceling out of the startup, but once the banana has been eaten, don't allow dodging until the peel is down.
			FrameEvent(0, SGPlayerCommon.Fns.SetCanDodge),


			FrameEvent(9, SGPlayerCommon.Fns.SetCannotDodge),
			FrameEvent(9, function(inst)
				if inst.sg.mem.roar_sound then
					soundutil.SetInstanceParameter(inst, inst.sg.mem.roar_sound, "skill_chargeLevel", 1)
					inst.sg.mem.roar_sound = nil -- stop tracking
				end
			end),

			FrameEvent(15, function(inst)
				inst.sg.mem.roar_sound = soundutil.PlayCodeSound(inst,fmodtable.Event.Skill_Gourdo_Stand,{max_count = 1})
			end),

			FrameEvent(18, function(inst)
				inst.sg.statemem.mustheal = true
				inst:PushEvent("do_gourdo_skill_heal")
			end),
		},

		onupdate = function(inst)
			if not inst.components.playercontroller:IsControlHeld("skill")
				and inst.sg.statemem.canexit
				and not inst.sg.statemem.mustheal then

				inst.sg:GoToState("skill_miniboss_gourdo_heal_pre_cancel")
			end
		end,

		onexit = function(inst)

		end,

		events =
		{
			EventHandler("animover", function(inst)
				inst.sg:GoToState("skill_miniboss_gourdo_heal_loop")
			end),
		},
	}),

	PlayerSkillState({
		name = "skill_miniboss_gourdo_heal_pre_cancel",
		tags ={ "busy" },

		onenter = function(inst)
			inst.AnimState:PlayAnimation("skill_gourdo_heal_empty")
			inst.AnimState:SetFrame(9)
		end,

		timeline =
		{
			FrameEvent(0, SGPlayerCommon.Fns.SetCanDodge),
			FrameEvent(4, SGPlayerCommon.Fns.SetCanAttackOrAbility),
			FrameEvent(6, SGPlayerCommon.Fns.RemoveBusyState),
		},

		onexit = function(inst)
		end,

		events =
		{
			EventHandler("animover", function(inst)
				inst.sg:GoToState("skill_pst")
			end),
		},
	}),

	PlayerSkillState({
		name = "skill_miniboss_gourdo_heal_loop",
		tags ={ "busy" },

		onenter = function(inst)
			inst.AnimState:PlayAnimation("skill_gourdo_heal_loop")
		end,

		timeline =
		{
			FrameEvent(0, function(inst)
				inst:PushEvent("do_gourdo_skill_heal")
			end),


			FrameEvent(9, SGPlayerCommon.Fns.SetCanDodge),
			FrameEvent(9, function(inst) inst.sg.statemem.canloop = true end), -- if still holding skill, then loop back to start.
		},

		onupdate = function(inst)
			if inst.components.playercontroller:IsControlHeld("skill") then
				if HasStocksRemaining(inst) and inst.sg.statemem.canloop then
					inst.sg:GoToState("skill_miniboss_gourdo_heal_pre", true)
				end
			end
		end,

		onexit = function(inst)
		end,

		events =
		{
			EventHandler("animover", function(inst)
				inst.sg:GoToState("skill_miniboss_gourdo_heal_pst")
			end),
		},
	}),

	PlayerSkillState({
		name = "skill_miniboss_gourdo_heal_pst",
		tags ={ "busy" },

		onenter = function(inst)
			inst.AnimState:PlayAnimation("skill_gourdo_heal_pst")

			if HasStocksRemaining(inst) then
				inst.sg.statemem.skillcombostate = "skill_miniboss_gourdo_heal_pre"
				SGPlayerCommon.Fns.TryQueuedAction(inst, "skill")
			end
		end,

		timeline =
		{
			FrameEvent(7, SGPlayerCommon.Fns.SetCanDodge),
			FrameEvent(10, SGPlayerCommon.Fns.RemoveBusyState),
		},

		onexit = function(inst)
		end,

		events =
		{
			EventHandler("animqueueover", function(inst)
				inst.sg:GoToState("skill_pst")
			end),
		},
	}),

	PlayerSkillState({
		name = "skill_miniboss_gourdo_no_heal",
		tags = { "busy" },

		onenter = function(inst)
			inst.AnimState:PlayAnimation("skill_gourdo_heal_empty")
		end,

		timeline =
		{
			FrameEvent(10, SGPlayerCommon.Fns.SetCanDodge),
			FrameEvent(13, SGPlayerCommon.Fns.RemoveBusyState)
		},

		onexit = function(inst)
		end,

		events =
		{
			EventHandler("animqueueover", function(inst)
				inst.sg:GoToState("skill_pst")
			end),
		},
	}),
}

return StateGraph("sg_player_skill_miniboss_gourdo", states, events, "skill_miniboss_gourdo")
