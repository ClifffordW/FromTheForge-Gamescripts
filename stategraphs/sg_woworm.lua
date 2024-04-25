local EffectEvents = require "effectevents"
local SGCommon = require "stategraphs.sg_common"
local spawnutil = require "util.spawnutil"
local monsterutil = require "util.monsterutil"

local function OnHitBoxTriggered(inst, data)
	SGCommon.Events.OnHitboxTriggered(inst, data, {
		attackdata_id = "shellslam",
		hitstoplevel = HitStopLevel.MEDIUM,
		pushback = 1.4,
		combat_attack_fn = "DoKnockdownAttack",
		hit_fx = monsterutil.defaultAttackHitFX,
		hit_fx_offset_x = 0.5,
		hitflags = Attack.HitFlags.LOW_ATTACK,
	})
end

local function ChooseIdleBehavior(inst)
	return false
end

local function OnDeath(inst, data)
	EffectEvents.MakeEventFXDeath(inst, data.attack, "death_woworm")
	inst.components.lootdropper:DropLoot()

	local prefab_name = inst:HasTag("elite") and "woworm_shell_elite" or "woworm_shell"
	local inst_facing = inst.Transform:GetFacing()
	local shell = SpawnPrefab(prefab_name, inst)
	local x, y, z = inst.Transform:GetWorldPosition()
	x = (inst_facing == FACING_RIGHT) and x - 0.8 or x + 0.8
	z = z + 0.05
	shell.Transform:SetPosition(x, y, z)
	spawnutil.SetFacing(shell, inst_facing)
end

local events = {}
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

local states =
{
	State({
		name = "barf",
		tags = { "attack", "busy" },

		onenter = function(inst, target)
			inst.AnimState:PlayAnimation("puke")
		end,

		timeline =
		{
			FrameEvent(6, function(inst) spawnutil.SpawnAcidTrap(inst, "medium", 150, 3.5, true) end),
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
		name = "shellslam",
		tags = { "attack", "busy" },

		onenter = function(inst, target)
			inst.AnimState:PlayAnimation("shell_slam")
			inst.components.hitbox:StartRepeatTargetDelay()
			SGCommon.Fns.FaceTargetClampedAngle(inst, target, 5)
		end,

		timeline =
		{
			FrameEvent(4, function(inst) inst.Physics:MoveRelFacing(26/150) end),
			FrameEvent(6, function(inst) inst.Physics:MoveRelFacing(48/150) end),
			FrameEvent(8, function(inst) inst.Physics:MoveRelFacing(42/150) end),
			FrameEvent(10, function(inst) inst.Physics:MoveRelFacing(48/150) end),
			FrameEvent(12, function(inst) inst.Physics:MoveRelFacing(36/150) end),
			FrameEvent(14, function(inst) inst.Physics:MoveRelFacing(16/150) end),
			FrameEvent(20, function(inst)
				local target = inst.components.combat:GetTarget()
				SGCommon.Fns.FaceTargetClampedAngle(inst, target, 20)
				inst.Physics:SetMotorVel(24)
				inst.Physics:StartPassingThroughObjects()
			end),
			FrameEvent(24, function(inst)
				inst.Physics:Stop()
				inst.components.hitbox:PushOffsetCircle(1, 0, 3, HitPriority.MOB_DEFAULT)
				spawnutil.SpawnAcidTrap(inst, "large", 90, 1, true)
			end),
			FrameEvent(25, function(inst) inst.Physics:StopPassingThroughObjects() end),
		},

		events =
		{
			EventHandler("hitboxtriggered", OnHitBoxTriggered),
			EventHandler("animover", function(inst)
				inst.Transform:FlipFacingAndRotation()
				inst.sg:GoToState("idle")
			end),
		},

		onexit = function(inst)
			inst.components.attacktracker:CompleteActiveAttack()
			inst.components.hitbox:StopRepeatTargetDelay()
			inst.Physics:StopPassingThroughObjects()
			inst.Physics:Stop()
		end,
	}),
}

SGCommon.States.AddAttackPre(states, "barf")
SGCommon.States.AddAttackHold(states, "barf")
SGCommon.States.AddAttackPre(states, "shellslam")
SGCommon.States.AddAttackHold(states, "shellslam")

SGCommon.States.AddSpawnBattlefieldStates(states,
{
	anim = "spawn",
	fadeduration = 0.33,
	fadedelay = 0,
	timeline =
	{
		FrameEvent(0, function(inst) inst:PushEvent("leave_spawner") end),
		FrameEvent(1, function(inst) SGCommon.Fns.SetMotorVelScaled(inst, 2) end),
		FrameEvent(16, function(inst)
			inst.sg:RemoveStateTag("airborne")
			inst.sg:AddStateTag("caninterrupt")
			inst.Physics:Stop()
		end),
	},
	onexit_fn = function(inst)
		inst.Physics:Stop()
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

SGCommon.States.AddIdleStates(states)
SGCommon.States.AddWalkStates(states,
{
	looptimeline =
	{
		FrameEvent(12, function(inst) spawnutil.SpawnAcidTrap(inst, "small", 160, 0, true) end),
	},
	turnpretimeline =
	{
		FrameEvent(5, function(inst) spawnutil.SpawnAcidTrap(inst, "small", 160, 1, true) end),
	}
})
SGCommon.States.AddTurnStates(states)

SGCommon.States.AddMonsterDeathStates(states)

return StateGraph("sg_woworm", states, events, "idle")
