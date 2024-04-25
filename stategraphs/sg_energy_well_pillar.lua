local SGCommon = require "stategraphs.sg_common"

local events =
{
	EventHandler("activate_well", function(inst, data)
		if not data.is_init then
			inst.sg:GoToState("powerup")
		else
			inst.sg:GoToState("idle")
		end
	end),

	EventHandler("deactivate_well", function(inst, data)
		inst.sg:GoToState("powerdown")
	end),

	EventHandler("switch_heart", function(inst)
		if not inst.sg:HasStateTag("busy") then
			inst.sg:GoToState("switch")
		end
	end),

	-- the well is already active, but a new heart was added
	EventHandler("add_heart", function(inst)
		if not inst.sg:HasStateTag("busy") then
			inst.sg:GoToState("new_heart")
		end
	end),
}

local states =
{
	State{
		name = "off",

		onenter = function(inst)
			-- if is on, go right to idle
			SGCommon.Fns.PlayAnimOnAllLayers(inst, "off")
		end,
	},

	State{
		name = "powerup",
		tags = {"busy"},
		onenter = function(inst)
			SGCommon.Fns.PlayAnimOnAllLayers(inst, "power_first")
			inst.components.energywellpillar:RefreshSymbolsForAllPlayers()
		end,

		events =
		{
			EventHandler("animover", function(inst)
				inst.sg:GoToState("idle")
			end),
		},
	},

	State{
		name = "powerdown",
		tags = {"busy"},
		onenter = function(inst)
			SGCommon.Fns.PlayAnimOnAllLayers(inst, "power_off")
		end,

		timeline =
		{
			FrameEvent(45, function(inst) inst.components.energywellpillar:RefreshSymbolsForAllPlayers() end),
		},

		events =
		{
			EventHandler("animover", function(inst)
				inst.sg:GoToState("off")
			end),
		},
	},

	State{
		name = "idle",

		onenter = function(inst)
			SGCommon.Fns.PlayAnimOnAllLayers(inst, "idle", true)
			inst.components.energywellpillar:RefreshSymbolsForAllPlayers()
		end,
	},

	State{
		name = "switch",
		tags = {"busy"},
		onenter = function(inst)
			SGCommon.Fns.PlayAnimOnAllLayers(inst, "switch")
			inst.components.energywellpillar:RefreshSymbolsForAllPlayers()
		end,

		events =
		{
			EventHandler("animover", function(inst)
				inst.sg:GoToState("idle")
			end),
		},
	},

	State{
		name = "new_heart",
		tags = {"busy"},
		onenter = function(inst)
			SGCommon.Fns.PlayAnimOnAllLayers(inst, "power_activate")
		end,

		timeline =
		{
			FrameEvent(36, function(inst)
				inst.components.energywellpillar:RefreshSymbolsForAllPlayers()
			end),
		},

		events =
		{
			EventHandler("animover", function(inst)
				inst.sg:GoToState("idle")
			end),
		},
	},
}

return StateGraph("sg_energy_well_pillar", states, events, "off")
