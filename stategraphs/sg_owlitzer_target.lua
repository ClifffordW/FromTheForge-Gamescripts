local SGCommon = require("stategraphs/sg_common")

local events =
{
	EventHandler("lock_on", function(inst)
		inst.sg:GoToState("locked")
	end),

	EventHandler("done_attack", function(inst)
		inst.sg:GoToState("pst")
	end),
}

local states =
{

	State({
		name = "init",

		onenter = function(inst)
			inst.AnimState:PlayAnimation("in")
		end,

		events =
		{
			EventHandler("animover", function(inst)
				inst.sg:GoToState("targeting")
			end),
		},
	}),

	State({
		name = "targeting",

		onenter = function(inst)
			inst.AnimState:PlayAnimation("search_loop", true)
		end,
	}),

	State({
		name = "locked",

		onenter = function(inst)
			SGCommon.Fns.BlinkAndFadeColor(inst, { 1, 1, 1, 1 }, 10)
			inst.AnimState:PlayAnimation("switch")
			inst.AnimState:PushAnimation("lock_on_loop", true)
		end,
	}),

	State({
		name = "pst",

		onenter = function(inst)
			inst.AnimState:PlayAnimation("out")
		end,

		events =
		{
			EventHandler("animover", function(inst)
				inst.sg:GoToState("despawn")
			end),
		},
	}),

	State({
		name = "despawn",
		onenter = function(inst)
			inst:DoTaskInTime(0, function()
				inst.fx:Remove()
				inst:Remove()
			end)
		end,
	}),
}

return StateGraph("sg_owlitzer_target", states, events, "init")
