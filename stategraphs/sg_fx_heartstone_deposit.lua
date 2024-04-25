local ParticleSystemHelper = require "util.particlesystemhelper"

local events =
{
	EventHandler("despawn", function(inst) inst.sg:GoToState("despawn") end),
}

local states =
{
	State({
		name = "spawn",
		tags = { "busy" },

		onenter = function(inst)
			inst.AnimState:PlayAnimation("spawn_heart")
			inst.AnimState:SetFrame(43) -- skip most of the anim... temp?
		end,

		events =
		{
			EventHandler("animover", function(inst)
				inst.sg:GoToState("idle")
			end),
		},
	}),

	State({
		name = "idle",
		tags = { "idle" },

		onenter = function(inst)
			inst.AnimState:PushAnimation("idle_heart", true)
		end,
	}),

	State({
		name = "despawn",
		tags = { "busy" },

		onenter = function(inst)
			inst.AnimState:PlayAnimation("shatter_heart")
			ParticleSystemHelper.MakeOneShotAtPosition(inst:GetPosition(), "boss_heart_despawn", 0.1, inst, { offy = 3.5 })
		end,

		events =
		{
			EventHandler("animover", function(inst)
				inst:Remove()
			end),
		},
	}),
}

return StateGraph("sg_fx_heartstone_deposit", states, events, "spawn")
