local EffectEvents = require "effectevents"
local SGCommon = require "stategraphs.sg_common"
local playerutil = require "util.playerutil"
local monsterutil = require "util.monsterutil"

local function OnDashHitboxTriggered(inst, data)
	SGCommon.Events.OnHitboxTriggered(inst, data, {
		attackdata_id = "dash",
		hitstoplevel = HitStopLevel.LIGHT,
		pushback = 0.5,
		combat_attack_fn = "DoKnockbackAttack",
		hit_fx = monsterutil.defaultAttackHitFX,
		hit_fx_offset_x = 0.5,
	})
end

local function OnSwipeHitboxTriggered(inst, data)
	local elite = inst:HasTag("elite")

	local hitstop = elite and HitStopLevel.MEDIUM or HitStopLevel.LIGHT
	local hitstun = elite and 4 or 2
	local pushback = elite and 0.5 or 1

	SGCommon.Events.OnHitboxTriggered(inst, data, {
		attackdata_id = "swipe",
		hitstoplevel = hitstop,
		pushback = pushback,
		combat_attack_fn = "DoKnockbackAttack",
		hitstun_anim_frames = hitstun,
		bypass_posthit_invincibility = true,
		hitflags = Attack.HitFlags.LOW_ATTACK,
		hit_fx = monsterutil.defaultAttackHitFX,
		hit_fx_offset_x = 0.5,
	})
end

local function OnDoubleKickHitboxTriggered(inst, data)
	SGCommon.Events.OnHitboxTriggered(inst, data, {
		attackdata_id = "double_kick",
		hitstoplevel = inst.sg.statemem.is_second_kick and HitStopLevel.MEDIUM or HitStopLevel.LIGHT,
		hitstun_anim_frames = 2,
		pushback = inst.sg.statemem.is_second_kick and 1.0 or 1.5,
		combat_attack_fn = "DoKnockbackAttack",
		hit_fx = monsterutil.defaultAttackHitFX,
		hit_fx_offset_x = 0.5,
	})

	-- Stop on hit to allow the 2nd hit a better chance to hit
	inst.Physics:Stop()
end

local function OnDiveHitboxTriggered(inst, data)
	SGCommon.Events.OnHitboxTriggered(inst, data, {
		attackdata_id = "dive",
		hitstoplevel = HitStopLevel.HEAVY,
		pushback = 1.5,
		combat_attack_fn = "DoKnockdownAttack",
		hit_fx = monsterutil.defaultAttackHitFX,
		hit_fx_offset_x = 0.5,
	})
end

local function ChooseIdleBehavior(inst)
	-- if not inst.components.timer:HasTimer("idlebehavior_cd") then
	-- 	local threat = playerutil.GetRandomLivingPlayer()
	-- 	if not threat then
	-- 		inst.sg:GoToState("idle_behaviour")
	-- 		return true
	-- 	end
	-- end
	return false
end

local function OnDeath(inst, data)
	--Spawn death fx
	EffectEvents.MakeEventFXDeath(inst, data.attack, "death_meowl")

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
	idlebehavior_fn = ChooseIdleBehavior,
	spawn_battlefield = true,
})
SGCommon.Fns.AddCommonSwallowedEvents(events)

local TAUNT_TIME <const> = 3
local DASH_SPEED <const> = 64
local TIRED_TIME <const> = 2

local function CheckRageModeAttackPst(inst)

	-- Target doesn't exist anymore; return to normal.
	if not inst.components.meowlsync:IsTargetAlive() then
		inst.sg:GoToState("rage_end_pst")
	end

	local num_rage_attacks = inst.components.meowlsync:GetRageAttackCount()
	if num_rage_attacks >= inst.components.meowlsync:GetMaxNumRageAttacks() then
		-- Go to dive attack if the target is still alive.
		inst.components.meowlsync:ResetRageAttackCount()
		inst.sg:GoToState("dive_pre")
	else
		-- Increment rage attack count.
		inst.components.meowlsync:AddRageAttackCount()
		inst.sg:GoToState("idle")
	end
end

local function DoRageModeEyeColor(inst)
	-- Change eye colour to red
	local hsb = HSB(300, 220, 100)
	inst.AnimState:SetSymbolColorShift("eye_untex", table.unpack(hsb))

	-- Change eye bloom to red
	local r, g, b = HexToRGBFloats(StrToHex("9322D4C9"))
	local intensity = 0.6
	inst.AnimState:SetSymbolBloom("eye_untex", r, g, b, intensity)
end

local function ResetRageModeEyeColor(inst)
	inst.AnimState:ClearSymbolColorShift("eye_untex")
	inst.AnimState:SetSymbolBloom("eye_untex", 0, 0, 0, 0)
end

local states =
{
	State({
		name = "snowball",
		tags = { "attack", "busy" },

		onenter = function(inst, target)
			inst.AnimState:PlayAnimation("snowball")
			inst.sg.statemem.target = target
		end,

		timeline =
		{
			FrameEvent(24, function(inst)
				inst.components.attacktracker:CompleteActiveAttack()
				local snowball = SGCommon.Fns.SpawnAtDist(inst, "meowl_projectile", 3.5)
				if snowball then
					snowball:Setup(inst)
				end
			end),
			FrameEvent(25, function(inst)
				inst.sg:AddStateTag("caninterrupt")
			end),
		},

		events =
		{
			EventHandler("animover", function(inst)
				inst.sg:GoToState("idle")
			end),
		},

		onexit = function(inst)
			inst.components.attacktracker:CompleteActiveAttack()
		end,
	}),

	State({
		name = "taunt",
		tags = { "attack", "busy" },

		onenter = function(inst, target)
			inst.AnimState:PlayAnimation("taunt_loop", true)
			inst.sg.statemem.target = target
			inst.sg:SetTimeout(TAUNT_TIME)
		end,

		ontimeout = function(inst)
			inst.sg:GoToState("taunt_pst")
		end,

		events =
		{
			EventHandler("attacked", function(inst, data)
				inst.sg:GoToState("taunt_hit", data)
			end),
		},
	}),

	State({
		name = "taunt_pst",
		tags = { "busy" },

		onenter = function(inst)
			inst.AnimState:PlayAnimation("taunt_pst")
			inst.components.attacktracker:CompleteActiveAttack()
		end,

		events =
		{
			EventHandler("animover", function(inst)
				inst.sg:GoToState("idle")
			end),
		},
	}),

	State({
		name = "taunt_hit",
		tags = { "hit", "busy", "nointerrupt" },

		onenter = function(inst, data)
			local anim = data.front and "taunt_hit_hold" or "taunt_hit_back_hold"
			inst.AnimState:PlayAnimation(anim)
			inst.components.attacktracker:CompleteActiveAttack()
		end,

		events =
		{
			EventHandler("animover", function(inst)
				inst.sg:GoToState("taunt_hit_pst")
			end),
		},
	}),

	State({
		name = "taunt_hit_pst",
		tags = { "busy", "nointerrupt" },

		onenter = function(inst)
			inst.AnimState:PlayAnimation("taunt_hit_pst")
		end,

		timeline =
		{
			FrameEvent(6, function(inst)
				DoRageModeEyeColor(inst)
			end),
		},

		events =
		{
			EventHandler("animover", function(inst)
				inst.sg:GoToState("rage_loop")
			end),
		},

		onexit = function(inst)
			DoRageModeEyeColor(inst)
		end,
	}),

	State({
		name = "rage_loop",
		tags = { "busy", "nointerrupt" },

		onenter = function(inst)
			inst.AnimState:PlayAnimation("rage_loop", true)
		end,

		events =
		{
			EventHandler("animover", function(inst)
				inst.sg:GoToState("rage_pst")
			end),
		},
	}),

	State({
		name = "rage_pst",
		tags = { "busy", "nointerrupt" },

		onenter = function(inst)
			inst.AnimState:PlayAnimation("rage_pst")
		end,

		events =
		{
			EventHandler("animover", function(inst)
				inst.sg:GoToState("idle")
			end),
		},
	}),

	-- Dash
	State({
		name = "dash",
		tags = { "busy", "nointerrupt" },

		onenter = function(inst, target)
			if target then
				SGCommon.Fns.FaceTarget(inst, target, true)
			end
			inst.AnimState:PlayAnimation("dash")

			inst.components.hitbox:StartRepeatTargetDelay()
		end,

		timeline =
		{
			FrameEvent(3, function(inst)
				inst.Physics:StartPassingThroughObjects()
				SGCommon.Fns.SetMotorVelScaled(inst, DASH_SPEED)
				inst.sg.statemem.is_dashing = true
				inst.sg:AddStateTag("airborne")
			end),
			FrameEvent(8, function(inst)
				SGCommon.Fns.SetMotorVelScaled(inst, DASH_SPEED * 0.5)
			end),
			FrameEvent(9, function(inst)
				SGCommon.Fns.SetMotorVelScaled(inst, DASH_SPEED * 0.2)
			end),
			FrameEvent(10, function(inst)
				SGCommon.Fns.SetMotorVelScaled(inst, DASH_SPEED * 0.1)
			end),
			FrameEvent(11, function(inst)
				inst.Physics:Stop()
				inst.components.hitbox:StopRepeatTargetDelay()
				inst.components.attacktracker:CompleteActiveAttack()

				inst.sg.statemem.is_dashing = nil
				inst.sg:RemoveStateTag("airborne")
			end),
		},

		--[[onupdate = function(inst)
			if inst.sg.statemem.is_dashing then
				inst.components.hitbox:PushBeam(0.5, 3.0, 2, HitPriority.MOB_DEFAULT)
			end
		end,]]

		events =
		{
			--EventHandler("hitboxtriggered", OnDashHitboxTriggered),
			EventHandler("animover", function(inst)
				if not inst.components.meowlsync:IsTargetAlive() then
					inst.sg:GoToState("rage_end_pst")
				else
					inst.sg:GoToState("idle")
				end
			end),
		},

		onexit = function(inst)
			inst.components.hitbox:StopRepeatTargetDelay()
			inst.components.attacktracker:CompleteActiveAttack()
			inst.Physics:Stop()
			inst.Physics:StopPassingThroughObjects()
		end,
	}),

	-- Swipe
	State({
		name = "swipe",
		tags = { "attack", "busy", "airborne", "nointerrupt" },

		onenter = function(inst)
			inst.AnimState:PlayAnimation("swipe")
			inst.components.hitbox:StartRepeatTargetDelayAnimFrames(4)
		end,

		timeline =
		{
			-- Hitboxes
			FrameEvent(3, function(inst) inst.components.hitbox:PushBeam(0.50, 3.00, 1.50, HitPriority.MOB_DEFAULT) end),
			FrameEvent(4, function(inst) inst.components.hitbox:PushBeam(0.80, 3.50, 1.50, HitPriority.MOB_DEFAULT) end),
			FrameEvent(5, function(inst) inst.components.hitbox:PushBeam(0.00, 2.50, 1.50, HitPriority.MOB_DEFAULT) end),

			FrameEvent(7, function(inst) inst.components.hitbox:PushBeam(0.50, 3.00, 1.50, HitPriority.MOB_DEFAULT) end),
			FrameEvent(8, function(inst) inst.components.hitbox:PushBeam(0.80, 3.50, 1.50, HitPriority.MOB_DEFAULT) end),
			FrameEvent(9, function(inst) inst.components.hitbox:PushBeam(0.00, 2.50, 1.50, HitPriority.MOB_DEFAULT) end),

			FrameEvent(12, function(inst) inst.components.hitbox:PushBeam(0.50, 3.00, 1.50, HitPriority.MOB_DEFAULT) end),
			FrameEvent(13, function(inst) inst.components.hitbox:PushBeam(0.80, 3.50, 1.50, HitPriority.MOB_DEFAULT) end),
			FrameEvent(14, function(inst) inst.components.hitbox:PushBeam(-0.50, 2.50, 1.00, HitPriority.MOB_DEFAULT) end),

			FrameEvent(16, function(inst) inst.components.hitbox:PushBeam(0.50, 3.00, 1.50, HitPriority.MOB_DEFAULT) end),
			FrameEvent(17, function(inst) inst.components.hitbox:PushBeam(0.80, 3.50, 1.50, HitPriority.MOB_DEFAULT) end),
			FrameEvent(18, function(inst) inst.components.hitbox:PushBeam(0.00, 2.50, 1.50, HitPriority.MOB_DEFAULT) end),

			FrameEvent(21, function(inst) inst.components.hitbox:PushBeam(0.50, 3.00, 1.50, HitPriority.MOB_DEFAULT) end),
			FrameEvent(22, function(inst) inst.components.hitbox:PushBeam(0.80, 3.50, 1.50, HitPriority.MOB_DEFAULT) end),

			FrameEvent(3, function(inst)
				SGCommon.Fns.SetMotorVelScaled(inst, 1)
			end),
			FrameEvent(22, function(inst)
				inst.Physics:Stop()
			end),

			FrameEvent(27, function(inst)
				inst.sg:RemoveStateTag("airborne")
			end),
		},

		events =
		{
			EventHandler("hitboxtriggered", OnSwipeHitboxTriggered),
			EventHandler("animover", function(inst)
				CheckRageModeAttackPst(inst)
			end),
		},

		onexit = function(inst)
			inst.Physics:Stop()
			inst.components.hitbox:StopRepeatTargetDelay()
			inst.components.attacktracker:CompleteActiveAttack()
		end,
	}),

	-- Double kick
	State({
		name = "double_kick",
		tags = { "attack", "busy", "airborne", "nointerrupt" },

		onenter = function(inst)
			inst.AnimState:PlayAnimation("double_kick")
			inst.components.hitbox:StartRepeatTargetDelayAnimFrames(5)
			inst.Physics:StartPassingThroughObjects()
		end,

		timeline =
		{
			-- Hitboxes
			FrameEvent(2, function(inst) inst.components.hitbox:PushOffsetBeam(-1.00, 2.50, 1.50, -1.00, HitPriority.MOB_DEFAULT) end),
			FrameEvent(3, function(inst) inst.components.hitbox:PushOffsetBeam(0.50, 4.00, 1.50, -1.00, HitPriority.MOB_DEFAULT) end),
			FrameEvent(4, function(inst) inst.components.hitbox:PushOffsetBeam(0.50, 4.00, 1.50, -1.00, HitPriority.MOB_DEFAULT) end),
			FrameEvent(5, function(inst) inst.components.hitbox:PushOffsetBeam(0.50, 3.50, 1.50, -1.00, HitPriority.MOB_DEFAULT) end),
			FrameEvent(6, function(inst) inst.components.hitbox:PushOffsetBeam(0.50, 3.50, 1.50, -1.00, HitPriority.MOB_DEFAULT) end),
			FrameEvent(7, function(inst) inst.components.hitbox:PushOffsetBeam(0.50, 3.50, 1.50, -1.00, HitPriority.MOB_DEFAULT) end),

			FrameEvent(14, function(inst) inst.components.hitbox:PushOffsetBeam(0.00, 4.50, 1.50, -0.58, HitPriority.MOB_DEFAULT) end),
			FrameEvent(15, function(inst) inst.components.hitbox:PushOffsetBeam(0.00, 4.50, 1.50, -0.58, HitPriority.MOB_DEFAULT) end),
			FrameEvent(16, function(inst) inst.components.hitbox:PushOffsetBeam(0.00, 4.50, 1.50, -0.58, HitPriority.MOB_DEFAULT) end),
			FrameEvent(17, function(inst) inst.components.hitbox:PushOffsetBeam(0.00, 4.00, 1.50, -0.58, HitPriority.MOB_DEFAULT) end),
			FrameEvent(18, function(inst) inst.components.hitbox:PushOffsetBeam(0.00, 4.00, 1.50, -0.58, HitPriority.MOB_DEFAULT) end),
			FrameEvent(19, function(inst) inst.components.hitbox:PushOffsetBeam(0.00, 4.00, 1.50, -0.58, HitPriority.MOB_DEFAULT) end),

			-- Movement
			-- (Movement values are currently set to 2x animated movement speed)
			FrameEvent(2, function(inst) SGCommon.Fns.SetMotorVelScaled(inst, 60) end),
			FrameEvent(3, function(inst) SGCommon.Fns.SetMotorVelScaled(inst, 25.6) end),
			FrameEvent(5, function(inst) SGCommon.Fns.SetMotorVelScaled(inst, 2.2) end),
			FrameEvent(8, function(inst) SGCommon.Fns.SetMotorVelScaled(inst, 9.8) end),
			FrameEvent(11, function(inst) SGCommon.Fns.SetMotorVelScaled(inst, 2.6) end),
			FrameEvent(13, function(inst) SGCommon.Fns.SetMotorVelScaled(inst, 12.8) end),
			FrameEvent(14, function(inst)SGCommon.Fns.SetMotorVelScaled(inst, 89.6) end),
			FrameEvent(15, function(inst) SGCommon.Fns.SetMotorVelScaled(inst, 31.4) end),
			FrameEvent(17, function(inst) SGCommon.Fns.SetMotorVelScaled(inst, 1.6) end),
			FrameEvent(20, function(inst) SGCommon.Fns.SetMotorVelScaled(inst, 7.2) end),
			FrameEvent(22, function(inst) SGCommon.Fns.SetMotorVelScaled(inst, 16.4) end),
			FrameEvent(23, function(inst) SGCommon.Fns.SetMotorVelScaled(inst, 13.2) end),
			FrameEvent(25, function(inst) SGCommon.Fns.SetMotorVelScaled(inst, 7.6) end),
			FrameEvent(26, function(inst) inst.Physics:Stop() end),

			FrameEvent(8, function(inst)
				local target = inst.components.combat:GetTarget()
				if target then
					SGCommon.Fns.FaceTarget(inst, target, true)
				end

				inst.sg.statemem.is_second_kick = true
			end),

			FrameEvent(25, function(inst)
				inst.sg:RemoveStateTag("airborne")
				inst.Physics:StopPassingThroughObjects()
			end),
		},

		events =
		{
			EventHandler("hitboxtriggered", OnDoubleKickHitboxTriggered),
			EventHandler("animover", function(inst)
				CheckRageModeAttackPst(inst)
			end),
		},

		onexit = function(inst)
			inst.Physics:Stop()
			inst.Physics:StopPassingThroughObjects()
			inst.components.hitbox:StopRepeatTargetDelay()
			inst.components.attacktracker:CompleteActiveAttack()
		end,
	}),

	-- Dive
	State({
		name = "dive",
		tags = { "attack", "busy", "airborne_high", "nointerrupt" },

		onenter = function(inst)
			inst.AnimState:PlayAnimation("dive")
			inst.Physics:StartPassingThroughObjects()
			inst.components.hitbox:StartRepeatTargetDelay()
			local target = inst.components.combat:GetTarget()
			SGCommon.Fns.FaceTarget(inst, target, true)
			SGCommon.Fns.SetMotorVelScaled(inst, 10.0)
		end,

		timeline =
		{
			-- Hitboxes
			FrameEvent(3, function(inst) inst.components.hitbox:PushBeam(0.00, 2.00, 1.50, HitPriority.MOB_DEFAULT) end),
			FrameEvent(4, function(inst) inst.components.hitbox:PushBeam(0.00, 2.00, 1.50, HitPriority.MOB_DEFAULT) end),
			FrameEvent(5, function(inst) inst.components.hitbox:PushBeam(-0.50, 1.50, 1.50, HitPriority.MOB_DEFAULT) end),
			FrameEvent(6, function(inst) inst.components.hitbox:PushCircle(0.00, 0.00, 1.50, HitPriority.MOB_DEFAULT) end),
			FrameEvent(7, function(inst) inst.components.hitbox:PushCircle(0.00, 0.00, 2.50, HitPriority.MOB_DEFAULT) end),

			-- Movement
			FrameEvent(2, function(inst) SGCommon.Fns.SetMotorVelScaled(inst, 24.8) end),
			FrameEvent(3, function(inst) SGCommon.Fns.SetMotorVelScaled(inst, 38.5) end),
			FrameEvent(4, function(inst) SGCommon.Fns.SetMotorVelScaled(inst, 51.2) end),
			FrameEvent(5, function(inst) SGCommon.Fns.SetMotorVelScaled(inst, 58.4) end),
			FrameEvent(6, function(inst) SGCommon.Fns.SetMotorVelScaled(inst, 51.2) end),
			FrameEvent(7, function(inst) inst.Physics:Stop() end),

			FrameEvent(5, function(inst)
				inst.sg:RemoveStateTag("airborne_high")
				inst.sg:AddStateTag("airborne")
			end),
			FrameEvent(6, function(inst)
				inst.sg:RemoveStateTag("airborne")
				inst.Physics:StopPassingThroughObjects()
			end),
		},

		events =
		{
			EventHandler("hitboxtriggered", OnDiveHitboxTriggered),
			EventHandler("animover", function(inst)
				inst.sg:GoToState("tired_pre")
			end),
		},

		onexit = function(inst)
			inst.Physics:Stop()
			inst.Physics:StopPassingThroughObjects()
			inst.components.hitbox:StopRepeatTargetDelay()
			inst.components.attacktracker:CompleteActiveAttack()
		end,
	}),

	-- Tired states
	State({
		name = "tired_pre",
		tags = { "busy", "vulnerable", "knockback_becomes_knockdown" },

		onenter = function(inst)
			inst.AnimState:PlayAnimation("tired_pre")
		end,

		events =
		{
			EventHandler("animover", function(inst)
				inst.sg:GoToState("tired_loop")
			end),
		},
	}),

	State({
		name = "tired_loop",
		tags = { "busy", "vulnerable", "knockback_becomes_knockdown" },

		onenter = function(inst)
			inst.AnimState:PlayAnimation("tired_loop")
			inst.sg:SetTimeout(TIRED_TIME)
		end,

		ontimeout = function(inst)
			-- If target is dead, go back to idle
			if not inst.components.meowlsync:IsTargetAlive() then
				inst.sg:GoToState("tired_end_pst")
			else
				inst.sg:GoToState("tired_pst")
			end
		end,
	}),

	State({
		name = "tired_pst",
		tags = { "busy", "vulnerable", "knockback_becomes_knockdown" },

		onenter = function(inst)
			inst.AnimState:PlayAnimation("tired_pst")
		end,

		timeline =
		{
			-- Hitboxes
			FrameEvent(2, function(inst)
				inst.sg:RemoveStateTag("vulnerable")
				inst.sg:RemoveStateTag("knockback_becomes_knockdown")
			end),
		},

		events =
		{
			EventHandler("animover", function(inst)
				inst.sg:GoToState("idle")
			end),
		},
	}),

	State({
		name = "tired_end_pst",
		tags = { "busy" },

		onenter = function(inst)
			inst.AnimState:PlayAnimation("tired_end_pst")
			inst.components.meowlsync:SetRaged(false)
			ResetRageModeEyeColor(inst)
		end,

		events =
		{
			EventHandler("animover", function(inst)
				inst.sg:GoToState("idle")
			end),
		},
	}),

	State({
		name = "rage_end_pst",
		tags = { "busy" },

		onenter = function(inst)
			inst.AnimState:PlayAnimation("rage_end_pst")
			inst.components.meowlsync:SetRaged(false)
			ResetRageModeEyeColor(inst)
		end,

		events =
		{
			EventHandler("animover", function(inst)
				inst.sg:GoToState("idle")
			end),
		},
	}),
}

SGCommon.States.AddAttackPre(states, "snowball")
SGCommon.States.AddAttackHold(states, "snowball")

SGCommon.States.AddAttackPre(states, "taunt",
{
	addevents =
	{
		EventHandler("attacked", function(inst, data)
			if inst.sg.statemem.is_taunting then
				inst.components.meowlsync:SetRaged(true)
				inst.sg:GoToState("taunt_hit", data)
			end
		end),
	},

	timeline =
	{
		FrameEvent(8, function(inst)
			inst.sg.statemem.is_taunting = true
		end),
	},
})

SGCommon.States.AddAttackPre(states, "dash")
SGCommon.States.AddAttackHold(states, "dash")

SGCommon.States.AddAttackPre(states, "swipe",
{
	addtags = { "nointerrupt" },
	timeline =
	{
		FrameEvent(6, function(inst) inst.sg:AddStateTag("airborne") end),
	},
})
SGCommon.States.AddAttackHold(states, "swipe",
{
	addtags = { "airborne", "nointerrupt" },
})

SGCommon.States.AddAttackPre(states, "double_kick",
{
	addtags = { "nointerrupt" },
})
SGCommon.States.AddAttackHold(states, "double_kick",
{
	addtags = { "airborne", "nointerrupt" },
})

SGCommon.States.AddAttackPre(states, "dive",
{
	addtags = { "nointerrupt" },
	timeline =
	{
		FrameEvent(10, function(inst)
			inst.sg:AddStateTag("airborne")
			inst.Physics:StartPassingThroughObjects()

			local target = inst.components.combat:GetTarget()
			SGCommon.Fns.FaceTarget(inst, target, true)

			SGCommon.Fns.SetMotorVelScaled(inst, 10.0)
		end),
	},
	onexit_fn = function(inst)
		inst.Physics:Stop()
		inst.Physics:StopPassingThroughObjects()
	end,
})
SGCommon.States.AddAttackHold(states, "dive",
{
	addtags = { "airborne", "nointerrupt" },
	onenter_fn = function(inst)
		inst.Physics:StartPassingThroughObjects()
		SGCommon.Fns.SetMotorVelScaled(inst, 10.0)
	end,
	onexit_fn = function(inst)
		inst.Physics:Stop()
		inst.Physics:StopPassingThroughObjects()
	end,
})

SGCommon.States.AddSpawnBattlefieldStates(states,
{
	anim = "spawn",
	fadeduration = 0.33,
	fadedelay = 0,
	onenter_fn = function(inst)
		local vel = math.random(5, 8)
		SGCommon.Fns.SetMotorVelScaled(inst, vel)
	end,
	timeline =
	{
		FrameEvent(0, function(inst) inst:PushEvent("leave_spawner") end),

		FrameEvent(18, function(inst)
			inst.Physics:Stop()
			inst.Physics:StopPassingThroughObjects()
		end),
	},
	onexit_fn = function(inst)
		inst.Physics:Stop()
		inst.Physics:StopPassingThroughObjects()
	end,
})

SGCommon.States.AddHitStates(states)
SGCommon.States.AddKnockbackStates(states,
{
	movement_frames = 7,
})
SGCommon.States.AddKnockdownStates(states,
{
	movement_frames = 12,
})
SGCommon.States.AddKnockdownHitStates(states)

SGCommon.States.AddIdleStates(states,
{
	modifyanim = function(inst)
		local animname = "" -- Default is idle; no need to append anything,
		if inst.components.meowlsync:IsRaged() then
			animname = "rage_"
		end
		return animname
	end,
})

SGCommon.States.AddLocomoteStates(states, "walk")

SGCommon.States.AddTurnStates(states)

SGCommon.States.AddMonsterDeathStates(states)

return StateGraph("sg_meowl", states, events, "idle")
