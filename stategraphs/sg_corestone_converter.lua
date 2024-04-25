local Enum = require "util.enum"
local MetaProgressStore = require "prefabs.customscript.metaprogressstore"
local SGCommon = require "stategraphs.sg_common"
local soundutil = require "util.soundutil"
local fmodtable = require "defs.sound.fmodtable"

local StateName = Enum {
	"idle",
	"deposit",
	"rewards_pending",
	"present",
	"deactivated",
	"not_enough_exp"
}

local Anim = Enum {
	"idle",
	"convert_loop",
	"present",
	"deactivated",
}

local events =
{
	EventHandler("corestone_converter_deactivate", function(inst) inst.sg:GoToState(StateName.s.deactivated) end),
	EventHandler("interactable_pulse", function(inst, value) 
		soundutil.SetInstanceParameter(inst, "idle_LP", "town_building_interactable", value)
		soundutil.SetInstanceParameter(inst, "idle_LP", "town_building_interactable_pulse", value)
	end),
}

local states =  {
	State {
		name = StateName.s.idle,

		onenter = function(inst)
			SGCommon.Fns.PlayAnimOnAllLayers(inst, Anim.s.idle, true)
		end,

		events = {
			EventHandler(MetaProgressStore.Events.s.not_enough_exp, function(inst, params)
				inst.sg:GoToState(StateName.s.not_enough_exp)
			end),
			EventHandler(MetaProgressStore.Events.s.deposit, function(inst, params)
				inst.sg.mem.did_level = params.did_level
				inst.sg:GoToState(StateName.s.deposit)
			end),
			EventHandler(MetaProgressStore.Events.s.rewards_pending, function(inst)
				inst.sg:GoToState(StateName.s.rewards_pending)
			end),
			EventHandler(MetaProgressStore.Events.s.rewards_claimed, function(inst)
				inst.sg:GoToState(StateName.s.present)
			end),
		},

		onexit = function(inst)
		end,
	},

	State {
		name = StateName.s.not_enough_exp,
		tags = {"busy"},

		onenter = function(inst)
			SGCommon.Fns.PlayAnimOnAllLayers(inst, Anim.s.convert_loop, false)
		end,

		events = {
			EventHandler(MetaProgressStore.Events.s.rewards_claimed, function(inst)
				inst.sg.statemem.rewards_claimed = true
			end),
			EventHandler("animover", function(inst)
				inst.sg:GoToState(StateName.s.idle)
			end),
			EventHandler(MetaProgressStore.Events.s.not_enough_exp, function(inst)
				SGCommon.Fns.PlayAnimOnAllLayers(inst, Anim.s.convert_loop, false)
			end),
		},
	},

	State {
		name = StateName.s.deposit,
		tags = {"busy"},

		onenter = function(inst)
			inst.sg.statemem.deposit_count = 1
			SGCommon.Fns.PlayAnimOnAllLayers(inst, Anim.s.convert_loop, false)
		end,

		events = {
			EventHandler(MetaProgressStore.Events.s.rewards_claimed, function(inst)
				inst.sg.statemem.rewards_claimed = true
			end),
			EventHandler("animover", function(inst)
				inst.sg.statemem.deposit_count = inst.sg.statemem.deposit_count - 1
				if inst.sg.mem.did_level or inst.sg.statemem.rewards_claimed then
					inst.sg:GoToState(StateName.s.present)
				elseif inst.sg.statemem.deposit_count == 0 then
					inst.sg:GoToState(StateName.s.idle)
				else
					SGCommon.Fns.PlayAnimOnAllLayers(inst, Anim.s.convert_loop, false)
				end
			end),
			EventHandler(MetaProgressStore.Events.s.deposit, function(inst)
				-- TODO @chrisp #meta - verify that we want one anim loop per deposit, as opposed to animate when we
				-- deposit and continue animating if we deposit again
				inst.sg.statemem.deposit_count = inst.sg.statemem.deposit_count + 1
			end),
		},
	},

	State {
		name = StateName.s.rewards_pending,

		onenter = function(inst)
			inst.sg.mem.did_level = nil
			SGCommon.Fns.PlayAnimOnAllLayers(inst, Anim.s.convert_loop, false)
		end,

		events = {
			EventHandler(MetaProgressStore.Events.s.rewards_claimed, function(inst)
				inst.sg.statemem.rewards_claimed = true
			end),
			EventHandler("animover", function(inst)
				if inst.sg.statemem.rewards_claimed then
					inst.sg:GoToState(StateName.s.present)
				else
					SGCommon.Fns.PlayAnimOnAllLayers(inst, Anim.s.convert_loop, false)
				end
			end),
		},
	},

	State {
		name = StateName.s.present,
		tags = {"busy"},

		onenter = function(inst)
			SGCommon.Fns.PlayAnimOnAllLayers(inst, Anim.s.present, false)
		end,

		timeline = {
			FrameEvent(8, function(inst)
				inst:PushEvent(MetaProgressStore.Events.s.rewards_delivery_request)
			end),
		},

		events = {
			EventHandler("animover", function(inst)
				inst.sg:GoToState(StateName.s.idle)
			end),
		},
	},

	State {
		name = StateName.s.deactivated,
		tags = {"busy", "no_interact"},

		onenter = function(inst)
			SGCommon.Fns.PlayAnimOnAllLayers(inst, Anim.s.deactivated, false)
		end,
	}
}

return StateGraph("sg_corestone_converter", states, events, StateName.s.idle)
