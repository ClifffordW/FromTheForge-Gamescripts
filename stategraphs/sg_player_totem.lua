local SGCommon = require("stategraphs/sg_common")

local events =
{
	SGCommon.Events.OnAttackedLeftRight(),
	SGCommon.Events.OnKnockback(),
	EventHandler("dying", function(inst, data)
		inst.sg:GoToState("despawn", data)
	end),
}

local states =
{
	State({
		name = "spawn",
		tags = { "busy" },

		onenter = function(inst, owner)
			inst.AnimState:PlayAnimation("spawn")
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
			inst:StartBuff()
			inst.AnimState:PlayAnimation("casting", true)
		end,
	}),

	State({
		name = "despawn",
		tags = { "busy" },

		onenter = function(inst, data)
			SGCommon.Fns.SpawnAtDist(inst, "fx_heal_burst", 0)
			
			if data and data.attack then
				inst.sg.statemem.attacker = data.attack:GetAttacker()
			end

			inst:Teardown(inst.sg.statemem.attacker)
		end,
	}),

	-- for some reason the SGCommon versions of these refused to work so I remade them

	State({ name = "hit" }),

	State({
		name = "hit_actual",
		tags = { "hit", "busy" },

		onenter = function(inst, data)
			local animname = data.right and "hit_r_hold" or "hit_l_hold"
			inst.AnimState:PlayAnimation(animname)
			inst.sg.statemem.right = data.right
			local attack = data.attack

			inst.sg:SetTimeoutAnimFrames(attack:GetHitstunAnimFrames())
		end,

		ontimeout = function(inst)
			inst.sg:GoToState("hit_pst", inst.sg.statemem.right)
		end,
	}),

	State({
		name = "hit_pst",
		tags = { "hit", "busy" },

		onenter = function(inst, right)
			local animname = right and "hit_r_pst" or "hit_l_pst"
			inst.AnimState:PlayAnimation(animname)
		end,

		timeline =
		{
			FrameEvent(0, function(inst)
				inst.sg:RemoveStateTag("busy")
			end),
		},

		events =
		{
			EventHandler("animover", function(inst)
				inst.sg:GoToState("idle")
			end),
		},
	})
}

return StateGraph("sg_player_totem", states, events, "spawn")