local EffectEvents = require "effectevents"
local SGCommon = require "stategraphs.sg_common"
local monsterutil = require "util.monsterutil"

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
	EffectEvents.MakeEventFXDeath(inst, data.attack, "death_totolili")

	inst.components.lootdropper:DropLoot()
end

local function ProjectileAlive(projectile)
	return projectile and projectile:IsValid() and not projectile:IsInLimbo()
end

local function ProjectileDead(projectile)
	return projectile and (not projectile:IsValid() or projectile:IsInLimbo() or projectile.sg:GetCurrentState() == "death")
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

local TIMEOUT_LENGTH = 7

local states =
{
	State({
		name = "hop_back",
		tags = { "busy" },

		onenter = function(inst)
			inst.AnimState:PlayAnimation("hop_back")
			SGCommon.Fns.FaceTargetClampedAngle(inst, inst.sg.statemem.target, 15)

			--Jump the other way if back is against world bounds
			local x, y, z = inst.Transform:GetWorldPosition()
			local reverse_facing = inst.Transform:GetFacing() == FACING_LEFT and 1 or -1
			local x_offset = x + (8 * reverse_facing)
			if (not TheWorld.Map:IsWalkableAtXZ(x_offset, z)) then
				inst.Transform:FlipFacingAndRotation()
			end
		end,

		timeline =
		{
			FrameEvent(3, function(inst)
				inst.Physics:SetMotorVel(-26)
				inst.Physics:StartPassingThroughObjects()
			end),
			FrameEvent(12, function(inst)
				inst.Physics:Stop()
				inst.Physics:StopPassingThroughObjects()
			end),
		},

		events =
		{
			EventHandler("animover", function(inst)
				inst.sg:GoToState("lily_toss_pre")
			end),
		},

		onexit = function(inst)
			inst.Physics:StopPassingThroughObjects()
			inst.components.attacktracker:CompleteActiveAttack()
			inst.Physics:Stop()
		end,
	}),

	State({
		name = "lily_toss",
		tags = { "attack", "busy", "nointerrupt" },

		onenter = function(inst)
			inst.AnimState:PlayAnimation("lily_toss")
		end,

		timeline =
		{
			FrameEvent(9, function(inst)
				local projectile_prefab = inst:HasTag("elite") and "totolili_elite_projectile" or "totolili_projectile"
				local projectile = SGCommon.Fns.SpawnAtDist(inst, projectile_prefab, 2)
				if projectile then
					projectile:Setup(inst)
				end

				inst.sg:AddStateTag("caninterrupt")
				inst.sg.mem.projectile = projectile
			end),
		},

		events =
		{
			EventHandler("animover", function(inst)
				inst.sg.statemem.animover = true
				inst.sg:GoToState("lily_toss_loop")
			end),
		},

		onexit = function(inst)
			--totolili was knocked down before it could end this animation, remove projectile
			if (not inst.sg.statemem.animover and ProjectileAlive(inst.sg.mem.projectile)) then
				inst.sg.mem.projectile.sg:GoToState("death")
			end
		end
	}),

	State({
		name = "lily_toss_loop",
		tags = { "attack", "busy" },

		onenter = function(inst)
			inst.AnimState:PlayAnimation("lily_toss_loop", true)
			inst.sg:SetTimeout(TIMEOUT_LENGTH)
		end,

		onupdate = function(inst)
			if (ProjectileDead(inst.sg.mem.projectile)) then
				inst.sg:GoToState("lily_toss_pst")
			end
		end,

		ontimeout = function(inst)
			inst.sg:GoToState("lily_toss_pst")
		end,

		onexit = function(inst)
			inst.components.attacktracker:CompleteActiveAttack()

			--if totolili was knocked down or killed to exit this state, tell projectile to die
			if (ProjectileAlive(inst.sg.mem.projectile)) then
				inst.sg.mem.projectile.sg:GoToState("death")
			end
		end,
	}),

	State({
		name = "lily_toss_pst",
		tags = { "busy" },

		onenter = function(inst)
			inst.AnimState:PlayAnimation("lily_toss_pst")
		end,

		events =
		{
			EventHandler("animover", function(inst)
				inst.sg:GoToState("idle")
			end),
		},
	}),

	State({
		name = "lily_toss_spin",
		tags = { "attack", "busy", "nointerrupt" },

		onenter = function(inst)
			inst.AnimState:PlayAnimation("lily_toss_spin")
		end,

		timeline =
		{
			FrameEvent(30, function(inst)
				local projectile_prefab = inst:HasTag("elite") and "totolili_elite_projectile" or "totolili_projectile"
				local projectile = SGCommon.Fns.SpawnAtDist(inst, projectile_prefab, 2)
				if projectile then
					projectile:Setup(inst)
				end

				projectile.sg:GoToState("spiral")
				inst.sg:AddStateTag("caninterrupt")
				inst.sg.mem.projectile = projectile
			end),
		},

		events =
		{
			EventHandler("animover", function(inst)
				inst.sg.statemem.animover = true
				inst.sg:GoToState("lily_toss_spin_idle_loop")
			end),
		},

		onexit = function(inst)
			if (not inst.sg.statemem.animover) then
				inst.components.attacktracker:CompleteActiveAttack()

				if (ProjectileAlive(inst.sg.mem.projectile)) then
				inst.sg.mem.projectile.sg:GoToState("death")
				end
			end
		end
	}),

	State({
		name = "lily_toss_spin_idle_loop",
		tags = { "attack", "busy" },

		onenter = function(inst)
			inst.AnimState:PlayAnimation("lily_toss_spin_idle_loop", true)
			inst.sg:SetTimeout(TIMEOUT_LENGTH)
		end,

		onupdate = function(inst)
			if (inst:HasTag("elite") or ProjectileDead(inst.sg.mem.projectile)) then
				inst.sg:GoToState("lily_toss_spin_pst")
			end
		end,

		ontimeout = function(inst)
			inst.sg:GoToState("lily_toss_spin_pst")
		end,

		onexit = function(inst)
			inst.components.attacktracker:CompleteActiveAttack()

			--if totolili was knocked down or killed to exit this state, tell projectile to die
			if (not inst:HasTag("elite") and ProjectileAlive(inst.sg.mem.projectile)) then
				inst.sg.mem.projectile.sg:GoToState("death")
			end
		end,
	}),

	State({
		name = "lily_toss_spin_pst",
		tags = { "busy" },

		onenter = function(inst)
			inst.AnimState:PlayAnimation("lily_toss_spin_pst")
		end,

		events =
		{
			EventHandler("animover", function(inst)
				inst.sg:GoToState("idle")
			end),
		},
	}),
}

SGCommon.States.AddAttackPre(states, "lily_toss")
SGCommon.States.AddAttackHold(states, "lily_toss")

SGCommon.States.AddAttackPre(states, "lily_toss_spin")
SGCommon.States.AddAttackHold(states, "lily_toss_spin")

SGCommon.States.AddAttackPre(states, "hop_back",
{
	onenter_fn = function(inst) inst.sg:GoToState("hop_back") end
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

SGCommon.States.AddIdleStates(states)

SGCommon.States.AddLocomoteStates(states, "walk")

SGCommon.States.AddTurnStates(states)

SGCommon.States.AddMonsterDeathStates(states)

return StateGraph("sg_totolili", states, events, "idle")
