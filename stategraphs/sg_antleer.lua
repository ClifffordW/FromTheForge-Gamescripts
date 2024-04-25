local EffectEvents = require "effectevents"
local SGCommon = require "stategraphs.sg_common"
local monsterutil = require "util.monsterutil"

local function OnMapCollision(inst)
	-- Transition into pst if collided with map physics.
	inst:DoTaskInTime(0, function()
		inst.sg:GoToState("charge_pst", true) -- Delay until the next tick, or a hard crash occurs.
	end)
end

local function OnChargeHitboxTriggered(inst, data)
	SGCommon.Events.OnHitboxTriggered(inst, data, {
		attackdata_id = inst.sg.statemem.attack_id or "charge",
		hitstoplevel = HitStopLevel.HEAVY,
		pushback = 2,
		combat_attack_fn = "DoKnockdownAttack",
		hit_fx = monsterutil.defaultAttackHitFX,
		hit_fx_offset_x = 0.5,
		reduce_friendly_fire = true,
	})

	-- Transition into pst if it hit a player.
	local hit_player = false
	for _, target in ipairs(data.targets) do
		for _, playertag in ipairs(TargetTagGroups.Players) do
			if target:HasTag(playertag) then
				hit_player = true
				break
			end
		end
	end

	if hit_player then
		inst.sg:GoToState("charge_pst", true)
	end
end

local function OnChargePstHitboxTriggered(inst, data)
	SGCommon.Events.OnHitboxTriggered(inst, data, {
		attackdata_id = inst.sg.statemem.attack_id or "charge",
		damage_mod = 0.8,
		hitstoplevel = HitStopLevel.MEDIUM,
		pushback = 1.5,
		combat_attack_fn = "DoKnockbackAttack",
		hit_fx = monsterutil.defaultAttackHitFX,
		hit_fx_offset_x = 0.5,
		reduce_friendly_fire = true,
	})
end

local function OnDeath(inst, data)
	--Spawn death fx
	--EffectEvents.MakeEventFXDeath(inst, data.attack, "death_antleer")
	--Spawn loot (lootdropper will attach hitstopper)
	inst.components.lootdropper:DropLoot()
end

local events =
{
}
monsterutil.AddMonsterCommonEvents(events,
{
	ondeath_fn = OnDeath,
})
monsterutil.AddOptionalMonsterEvents(events,
{
	--idlebehavior_fn = ChooseIdleBehavior,
	--battlecry_fn = ChooseBattleCry,
	spawn_perimeter = true,
})
SGCommon.Fns.AddCommonSwallowedEvents(events)

local CHARGE_SPEED = 20

local states =
{
	State({
		name = "charge",
		tags = { "attack", "busy", "nointerrupt" },

		onenter = function(inst)
			inst.AnimState:PlayAnimation("charge_run_pre")
			inst.AnimState:PushAnimation("charge_run_loop", true)

			inst.sg:SetTimeout(3)

			local target = inst.components.combat:GetTarget()
			if target then
				SGCommon.Fns.FaceTarget(inst, target, true)
				inst.sg.statemem.target = target
			end

			inst.components.hitbox:StartRepeatTargetDelay()
		end,

		onupdate = function(inst)
			if inst.sg.statemem.charging then
				inst.components.hitbox:PushBeam(0.5, 3.0, 2, HitPriority.MOB_DEFAULT)
			end
		end,

		timeline =
		{
			FrameEvent(6, function(inst)
				inst.sg.statemem.charging = true
				SGCommon.Fns.SetMotorVelScaled(inst, CHARGE_SPEED)
				inst.Physics:StartPassingThroughObjects()
			end),
		},

		events =
		{
			EventHandler("hitboxtriggered", OnChargeHitboxTriggered),
			EventHandler("mapcollision", OnMapCollision),
		},

		ontimeout = function(inst)
			inst.sg:GoToState("charge_pst")
		end,

		onexit = function(inst)
			inst.Physics:Stop()
			inst.Physics:StopPassingThroughObjects()
			inst.components.hitbox:StopRepeatTargetDelay()
			inst.components.attacktracker:CompleteActiveAttack()
		end,
	}),

	State({
		name = "charge_pst",
		tags = { "attack", "busy", "nointerrupt" },

		onenter = function(inst, ishit)
			inst.AnimState:PlayAnimation("charge_run_pst")
			inst.components.hitbox:StartRepeatTargetDelay()

			inst.sg.statemem.ishit = ishit
		end,

		timeline = {
			FrameEvent(0, function(inst) SGCommon.Fns.SetMotorVelScaled(inst, CHARGE_SPEED) end),
			FrameEvent(2, function(inst) SGCommon.Fns.SetMotorVelScaled(inst, CHARGE_SPEED * 0.8) end),
			FrameEvent(4, function(inst) SGCommon.Fns.SetMotorVelScaled(inst, CHARGE_SPEED * 0.6) end),
			FrameEvent(6, function(inst) SGCommon.Fns.SetMotorVelScaled(inst, CHARGE_SPEED * 0.4) end),
			FrameEvent(8, function(inst) SGCommon.Fns.SetMotorVelScaled(inst, CHARGE_SPEED * 0.2) end),
			FrameEvent(10, function(inst) SGCommon.Fns.SetMotorVelScaled(inst, CHARGE_SPEED * 0) end),

			FrameEvent(0, function(inst)
				if inst.sg.statemem.ishit then
					inst.components.hitbox:PushCircle(2.0, 0, 3.0, HitPriority.MOB_DEFAULT)
				end
			end),
		},

		events = {
			EventHandler("hitboxtriggered", OnChargePstHitboxTriggered),
			EventHandler("animover", function(inst)
				inst.sg:GoToState("idle")
			end)
		},

		onexit = function(inst)
			inst.Physics:Stop()
			inst.components.hitbox:StopRepeatTargetDelay()
		end
	}),
}

SGCommon.States.AddAttackPre(states, "charge",
{
	tags = { "attack", "busy", "nointerrupt" }
})
SGCommon.States.AddAttackHold(states, "charge",
{
	tags = { "attack", "busy", "nointerrupt" }
})

SGCommon.States.AddHitStates(states, SGCommon.Fns.ChooseAttack)

--[[SGCommon.States.AddSpawnPerimeterStates(states,
{
	pre_anim = "spawn_jump_pre",
	hold_anim = "spawn_jump_hold",
	land_anim = "spawn_jump_land",
	pst_anim = "spawn_jump_pst",

	pst_timeline =
	{
		FrameEvent(0, function(inst) inst.Physics:MoveRelFacing(71/150) end),
	},

	fadeduration = 0.5,
	fadedelay = 0.5,
	jump_time = 0.66,
})]]

SGCommon.States.AddWalkStates(states,
{
	addtags = { "nointerrupt" },
})

SGCommon.States.AddTurnStates(states,
{
	addtags = { "nointerrupt" },
})

SGCommon.States.AddIdleStates(states,
{
	addtags = { "nointerrupt" },
})

--[[SGCommon.States.AddKnockbackStates(states,
{
	movement_frames = 12
})]]

SGCommon.States.AddKnockdownStates(states,
{
	movement_frames = 11,
	knockdown_size = 1.45,
})

SGCommon.States.AddKnockdownHitStates(states)

SGCommon.States.AddMonsterDeathStates(states)

local fns =
{
	OnResumeFromRemote = SGCommon.Fns.ResumeFromRemoteHandleKnockingAttack,
}

SGRegistry:AddData("sg_antleer", states)

return StateGraph("sg_antleer", states, events, "idle", fns)
