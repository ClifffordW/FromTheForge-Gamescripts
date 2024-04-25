local SGCommon = require "stategraphs.sg_common"
local SGPlayerCommon = require "stategraphs.sg_player_common"
local PlayerSkillState = require "playerskillstate"
local combatutil = require "util.combatutil"
local fmodtable = require "defs.sound.fmodtable"
local soundutil = require "util.soundutil"
local EffectEvents = require "effectevents"

local events = {}

local function _spawn_vacuum_pfb(inst)
	local facing = inst.Transform:GetFacing()
	if facing == FACING_RIGHT then
		local prefab = "player_groak_vacuum_right"
		EffectEvents.MakeEventSpawnLocalEntity(inst, prefab, "idle")
	elseif facing == FACING_LEFT then
		local prefab = "player_groak_vacuum_left"
		EffectEvents.MakeEventSpawnLocalEntity(inst, prefab, "idle")
	end
end

local states =
{
	PlayerSkillState({
		name = "skill_miniboss_groak",
		tags = { "busy" },

		onenter = function(inst)
			inst.AnimState:PlayAnimation("skill_groak_vacuum_pre")
		end,

		timeline =
		{
		},

		events =
		{
			EventHandler("animqueueover", function(inst)
				inst.sg:GoToState("skill_miniboss_groak_vacuum")
			end),
		},
	}),

	PlayerSkillState({
		name = "skill_miniboss_groak_vacuum",
		tags = { "busy" },

		onenter = function(inst)
			inst.AnimState:PlayAnimation("skill_groak_vacuum")
		end,

		timeline =
		{
			FrameEvent(0, function(inst) _spawn_vacuum_pfb(inst) end),
			FrameEvent(3, function(inst)
				inst.sg.statemem.lightcombostate = "default_light_attack"
				inst.sg.statemem.heavycombostate = "default_heavy_attack"

				if not SGPlayerCommon.Fns.TryQueuedAction(inst, "lightattack") then
					SGPlayerCommon.Fns.TryQueuedAction(inst, "heavyattack")
				end

				SGPlayerCommon.Fns.SetCanDodge(inst)
			end),
		},

		onexit = function(inst)
		end,

		events =
		{
			EventHandler("animover", function(inst)
				inst.sg:GoToState("skill_miniboss_groak_pst")
			end),
		},
	}),

	PlayerSkillState({
		name = "skill_miniboss_groak_pst",
		tags = { "busy" },

		onenter = function(inst)
			inst.AnimState:PlayAnimation("skill_groak_vacuum_pst")
		end,

		timeline =
		{
			FrameEvent(0, function(inst)
				inst.sg.statemem.lightcombostate = "default_light_attack"
				inst.sg.statemem.heavycombostate = "default_heavy_attack"

				if not SGPlayerCommon.Fns.TryQueuedAction(inst, "lightattack") then
					SGPlayerCommon.Fns.TryQueuedAction(inst, "heavyattack")
				end
			end),
			FrameEvent(4, SGPlayerCommon.Fns.SetCanDodge),
		},

		events =
		{
			EventHandler("animover", function(inst)
				inst.sg:GoToState("skill_pst")
			end),
		},
	}),
}

return StateGraph("sg_player_skill_miniboss_groak", states, events, "skill_miniboss_groak")