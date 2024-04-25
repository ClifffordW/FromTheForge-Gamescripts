local EffectEvents = require "effectevents"
local SGCommon = require "stategraphs.sg_common"
local monsterutil = require "util.monsterutil"

-------------------------- HITBOX TRIGGER FUNCTIONS --------------------------

-- SINGLE
local function OnBiteHitBoxTriggered(inst, data)
	SGCommon.Events.OnHitboxTriggered(inst, data, {
		attackdata_id = "bite",
		hitstoplevel = HitStopLevel.MEDIUM,
		pushback = 0.4,
		hitflags = Attack.HitFlags.LOW_ATTACK,
		combat_attack_fn = "DoKnockbackAttack",
		hit_fx = monsterutil.defaultAttackHitFX,
		hit_fx_offset_x = 0.5,
	})
end

local function OnRollHitBoxTriggered(inst, data)
	SGCommon.Events.OnHitboxTriggered(inst, data, {
		attackdata_id = inst.sg.statemem.active_attack or "roll",
		hitstoplevel = HitStopLevel.MEDIUM,
		hitflags = Attack.HitFlags.LOW_ATTACK,
		combat_attack_fn = "DoKnockbackAttack",
		hit_fx = monsterutil.defaultAttackHitFX,
		hit_fx_offset_x = 0.5,
		custom_attack_fn = function(attacker, attack)
			local hit = false
			if attacker.sg.statemem.knockbackonly then
				attack:SetPushback(1.25)
				hit = attacker.components.combat:DoKnockbackAttack(attack)
			else
				hit = attacker.components.combat:DoKnockdownAttack(attack)
			end

			if hit then
				attacker.sg.statemem.connected = true
			end

			return hit
		end,
	})

	if inst.sg.statemem.connected then
		local velocity = inst.Physics:GetMotorVel()
		inst.Physics:SetMotorVel(velocity * 0.25)
		if inst.sg.statemem.exit_state and inst.sg:GetTicksInState() % inst.AnimState:GetCurrentAnimationNumFrames() < inst.AnimState:GetCurrentAnimationNumFrames() * 0.5 then --if we just started the anim, stop rolling sooner and pop into the _pst
			inst.sg:GoToState(inst.sg.statemem.exit_state)
		end
		inst.sg.statemem.roll_finished = true
	end
end

-- DOUBLE
local function OnSlamHitBoxTriggered(inst, data)
	SGCommon.Events.OnHitboxTriggered(inst, data, {
		attackdata_id = "slam",
		hitstoplevel = HitStopLevel.MEDIUM,
		hitflags = inst.sg.statemem.hitflags or Attack.HitFlags.LOW_ATTACK,
		combat_attack_fn = "DoKnockbackAttack",
		hit_fx = monsterutil.defaultAttackHitFX,
		hit_fx_offset_x = 2,
	})
end

-- TRIPLE
local function OnSmashHitBoxTriggered(inst, data)
	SGCommon.Events.OnHitboxTriggered(inst, data, {
		attackdata_id = "smash",
		hitstoplevel = HitStopLevel.MEDIUM,
		dir_flipped = inst.sg.statemem.backhit,
		combat_attack_fn = "DoKnockdownAttack",
		hit_fx = monsterutil.defaultAttackHitFX,
	})
end

local function OnBodySlamHitBoxTriggered(inst, data)
	SGCommon.Events.OnHitboxTriggered(inst, data, {
		attackdata_id = "bodyslam",
		hitstoplevel = HitStopLevel.MEDIUM,
		dir_flipped = inst.sg.statemem.backhit,
		combat_attack_fn = "DoKnockdownAttack",
		hit_fx = monsterutil.defaultAttackHitFX,
	})
end
-------------------------- COMBINE (SINGLE) --------------------------

local function OnCombineRequest(inst, other)
	if inst.components.cabbagetower:GetMode() ~= 1 then
		return
	end

	if not inst.sg:HasStateTag("busy") then
		if other ~= nil and other:IsValid() and other:TryToTakeControl() and inst.components.combat:CanFriendlyTargetEntity(other) then
			other.components.timer:StartTimer("combine_cd", 9, true)
			inst.components.timer:StartTimer("combine_cd", 9, true)
			if inst.brain ~= nil then
				inst.brain.brain:SetCombineTarget(other)
			end
			SGCommon.Fns.TurnAndActOnTarget(inst, other, false, "calling")
		end
	end
end

local function OnCombine(inst, other)
	if inst.components.cabbagetower:GetMode() ~= 1 then
		return
	end

	if not inst.sg:HasStateTag("busy") then
		if other ~= nil and other:IsValid() and other:TryToTakeControl() and other.components.cabbagerollstracker ~= nil then
			local othernum = other.components.cabbagerollstracker:GetNum()
			local state =
				(othernum == 1 and "combine") or
				(othernum == 2 and "combine3") or
				nil
			if state ~= nil then
				other:PushEvent("combinewait")
				SGCommon.Fns.TurnAndActOnTarget(inst, other, false, state, other)
			end
		end
	end
end

-------------------------- IDLE BEHAVIOURS --------------------------

local function ChooseBattleCry(inst, data)
	if inst.components.cabbagetower:GetMode() > 1 then
		return false
	end

	if data.target ~= nil and data.target:IsValid() then
		if not inst.components.timer:HasTimer("whistle_cd") then
			if not inst:IsNear(data.target, 6) then
				SGCommon.Fns.TurnAndActOnTarget(inst, data.target, true, "whistle")
				return true
			end
		end
	end
	return false
end

local function ChooseIdleBehavior(inst)
	if inst.components.cabbagetower:GetMode() == 1 then
		if not inst.components.timer:HasTimer("idlebehavior_cd") then
			local target = inst.components.combat:GetTarget()
			if target ~= nil then
				if not inst.components.timer:HasTimer("taunt_cd") then
					if inst.components.health:GetPercent() < .75 and not inst:IsNear(target, 6) then
						SGCommon.Fns.TurnAndActOnTarget(inst, target, true, "taunt1")
						return true
					end
				end
			end
		end
	-- 2-stack doesn't have a taunt/idle behaviour implementation
	elseif inst.components.cabbagetower:GetMode() == 3 then
		local target = inst.components.combat:GetTarget()
		if target ~= nil then
			if not inst.components.timer:HasTimer("taunt_cd") then
				SGCommon.Fns.TurnAndActOnTarget(inst, target, true, "taunt3")
				return true
			end
		end
	end
	return false
end

-- For towers, this doesn't get played except for "instant death"
local function OnDeath(inst, data)
	inst.components.cabbagerollstracker:Unregister()

	--Spawn death fx
	EffectEvents.MakeEventFXDeath(inst, data.attack, "death_cabbageroll")
	--Spawn loot (lootdropper will attach hitstopper)
	if inst.components.cabbagetower:GetMode() == 1 then
		inst.components.lootdropper:DropLoot()
	end

	--[[Golden bonion test
	if (inst.sg.mem.golden_mob) then
		local pos = Vector2(inst.Transform:GetWorldXZ())
		for i = 1, 20 do
			local drop = SpawnPrefab("drop_konjur")
			drop.Transform:SetPosition(pos.x, 1, pos.y)
		end
	end
	--]]
end

-- For towers only; instead of dying, they split apart and put each roll into knockdown
local function OnDeathTask(inst)
	if inst.components.cabbagetower:GetMode() > 1 then
		if inst:IsLocal() and inst:HasTag("nokill") then
			inst.components.timer:StartTimer("knockdown", inst.components.combat.knockdownduration, true)
			SGCommon.Fns.OnKnockdown(inst)
		elseif not inst:IsLocal() then
			TheLog.ch.StateGraph:printf("Warning: %s EntityID %d tried to run OnDeathTask while remote",
				inst, inst:IsNetworked() and inst.Network:GetEntityID() or -1)
		end
	end
	inst.sg.mem.deathtask = nil
end

local function ShouldSplit(inst, data)
	if data and not data.hurt then return false end
	return inst.components.health:GetCurrent() <= 1 or inst.components.health:GetPercent() <= inst.components.cabbagetower:GetHealthSplitPercentage()
end

local function ModifyAnim(inst, default_name)
	if inst.components.cabbagetower:GetMode() == 2 then
		return "cabbageroll2_" .. default_name
	elseif inst.components.cabbagetower:GetMode() == 3 then
		return "cabbageroll3_" .. default_name
	end
end

local events =
{
	-- single only
	EventHandler("combine_req", OnCombineRequest),
	EventHandler("docombine", OnCombine),

	-- towers only
	EventHandler("attacked", function(inst, data)
		if inst.components.cabbagetower:GetMode() == 1 then
			return
		end

		if inst.sg.mem.deathtask ~= nil then
			inst.sg.mem.deathtask:Cancel()
			inst.sg.mem.deathtask = nil
		end
		if ShouldSplit(inst) then
			data.attack:SetKnockdownDuration(inst.components.combat:GetKnockdownDuration())
			SGCommon.Fns.OnKnockdown(inst, data)
		else
			SGCommon.Fns.OnAttacked(inst, data)
		end
	end),

	EventHandler("knockback", function(inst, data)
		if inst.components.cabbagetower:GetMode() == 1 then
			return
		end

		if inst.sg.mem.deathtask ~= nil then
			inst.sg.mem.deathtask:Cancel()
			inst.sg.mem.deathtask = nil
		end
		if ShouldSplit(inst) then
			data.attack:SetKnockdownDuration(inst.components.combat:GetKnockdownDuration())
			SGCommon.Fns.OnKnockdown(inst, data)
		else
			SGCommon.Fns.OnKnockback(inst, data)
		end
	end),

	EventHandler("knockdown", function(inst, data)
		if inst.components.cabbagetower:GetMode() == 1 then
			return
		end

		if inst.sg.mem.deathtask ~= nil then
			TheLog.ch.CabbageTowerSpam:printf("Cancelling death task...")
			inst.sg.mem.deathtask:Cancel()
			inst.sg.mem.deathtask = nil
		end
		SGCommon.Fns.OnKnockdown(inst, data)
	end),

	EventHandler("healthchanged", function(inst, data)
		if inst.components.cabbagetower:GetMode() == 1 then
			return
		end

		if ShouldSplit(inst, data) then
			if inst.sg.mem.deathtask == nil then
				inst.sg.mem.deathtask = inst:DoTaskInTicks(0, OnDeathTask)
			end
		end
	end),
}
monsterutil.AddMonsterCommonEvents(events,
{
	ondeath_fn = OnDeath,
})
monsterutil.AddOptionalMonsterEvents(events,
{
	battlecry_fn = ChooseBattleCry,
	idlebehavior_fn = ChooseIdleBehavior,
	spawn_battlefield = true,
})
SGCommon.Fns.AddCommonSwallowedEvents(events)

local states =
{
	-- single "post-tower" knockdown states
	State({
		name = "knockdown_top",
		tags = { "knockdown", "busy", "airborne", "nointerrupt", "airborne_high" },

		onenter = function(inst)
			inst.AnimState:PlayAnimation("knockdown_top_pre")
			inst.AnimState:PushAnimation("knockdown_top_pst")
		end,

		timeline =
		{
			--physics
			FrameEvent(0, function(inst) inst.Physics:SetMotorVel(-6) end),
			FrameEvent(0, function(inst) inst.Physics:StartPassingThroughObjects() end),
			FrameEvent(23, function(inst) inst.Physics:SetMotorVel(-3) end),
			FrameEvent(24, function(inst) inst.Physics:SetMotorVel(-2) end),
			FrameEvent(25, function(inst) inst.Physics:SetMotorVel(-1) end),
			FrameEvent(26, function(inst) inst.Physics:SetMotorVel(-.5) end),
			FrameEvent(27, function(inst) inst.Physics:Stop() end),
			FrameEvent(23, function(inst) inst.Physics:StopPassingThroughObjects() end),
			--

			FrameEvent(21, function(inst)
				inst.sg:RemoveStateTag("airborne_high")
				inst.sg:RemoveStateTag("nointerrupt")
			end),
			FrameEvent(23, function(inst)
				inst.sg:RemoveStateTag("airborne")
				inst.sg:AddStateTag("caninterrupt")
			end),
		},

		events =
		{
			EventHandler("getup", function(inst)
				inst.sg.statemem.getup = true
			end),
			EventHandler("animqueueover", function(inst)
				inst.sg.statemem.knockdown = true
				inst.sg:GoToState(inst.sg.statemem.getup and "knockdown_getup" or "knockdown_idle")
			end),
		},

		onexit = function(inst)
			inst.Physics:Stop()
			inst.Physics:StopPassingThroughObjects()
		end,
	}),

	State({
		name = "knockdown_mid",
		tags = { "knockdown", "busy", "airborne", "nointerrupt" },

		onenter = function(inst)
			inst.AnimState:PlayAnimation("knockdown_pre")
		end,

		timeline =
		{
			--physics
			FrameEvent(0, function(inst) inst.Physics:SetMotorVel(-3) end),
			FrameEvent(0, function(inst) inst.Physics:StartPassingThroughObjects() end),
			FrameEvent(18, function(inst) inst.Physics:SetMotorVel(-2) end),
			FrameEvent(18, function(inst) inst.Physics:StopPassingThroughObjects() end),
			FrameEvent(19, function(inst) inst.Physics:SetMotorVel(-1) end),
			FrameEvent(20, function(inst) inst.Physics:SetMotorVel(-.5) end),
			FrameEvent(21, function(inst) inst.Physics:Stop() end),
			--

			FrameEvent(16, function(inst)
				inst.sg:RemoveStateTag("nointerrupt")
			end),
			FrameEvent(18, function(inst)
				inst.sg:RemoveStateTag("airborne")
				inst.sg:AddStateTag("caninterrupt")
			end),
		},

		events =
		{
			EventHandler("getup", function(inst)
				inst.sg.statemem.getup = true
			end),
			EventHandler("animqueueover", function(inst)
				inst.sg.statemem.knockdown = true
				inst.sg:GoToState(inst.sg.statemem.getup and "knockdown_getup" or "knockdown_idle")
			end),
		},

		onexit = function(inst)
			inst.Physics:Stop()
			inst.Physics:StopPassingThroughObjects()
		end,
	}),

	State({
		name = "knockdown_btm",
		tags = { "knockdown", "busy", "nointerrupt" },

		onenter = function(inst)
			inst.AnimState:PlayAnimation("knockdown_btm_pre")
			inst.AnimState:PushAnimation("knockdown_btm_pst")
		end,

		timeline =
		{
			--physics
			FrameEvent(0, function(inst) inst.Physics:SetMotorVel(-6) end),
			FrameEvent(12, function(inst) inst.Physics:SetMotorVel(-3) end),
			FrameEvent(14, function(inst) inst.Physics:SetMotorVel(-2) end),
			FrameEvent(15, function(inst) inst.Physics:SetMotorVel(-1) end),
			FrameEvent(16, function(inst) inst.Physics:SetMotorVel(-.5) end),
			FrameEvent(17, function(inst) inst.Physics:Stop() end),
			--

			FrameEvent(6, function(inst)
				inst.sg:RemoveStateTag("nointerrupt")
			end),
			FrameEvent(12, function(inst)
				inst.sg:AddStateTag("caninterrupt")
			end),
		},

		events =
		{
			EventHandler("getup", function(inst)
				inst.sg.statemem.getup = true
			end),
			EventHandler("animqueueover", function(inst)
				inst.sg.statemem.knockdown = true
				inst.sg:GoToState(inst.sg.statemem.getup and "knockdown_getup" or "knockdown_idle")
			end),
		},

		onexit = function(inst)
			inst.Physics:Stop()
		end,
	}),

	-- idle behaviours
	-- unused single state
	State({
		name = "angry",
		tags = { "busy" },

		onenter = function(inst)
			inst.AnimState:PlayAnimation("behavior")
		end,

		timeline =
		{
			--physics
			FrameEvent(4, function(inst) inst.Physics:MoveRelFacing(10 / 150) end),
			FrameEvent(5, function(inst) inst.Physics:MoveRelFacing(10 / 150) end),
			FrameEvent(34, function(inst) inst.Physics:MoveRelFacing(-10 / 150) end),
			FrameEvent(36, function(inst) inst.Physics:MoveRelFacing(-10 / 150) end),
			--

			FrameEvent(5, function(inst)
				inst.components.timer:StartTimer("angry_cd", 12, true)
				inst.components.timer:StartTimer("idlebehavior_cd", 8, true)
			end),
			FrameEvent(22, function(inst)
				inst.sg:AddStateTag("caninterrupt")
			end),
			FrameEvent(47, function(inst)
				inst.sg:RemoveStateTag("busy")
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
		name = "whistle",
		tags = { "busy" },

		onenter = function(inst)
			inst.AnimState:PlayAnimation("behavior3")
		end,

		timeline =
		{
			--physics
			FrameEvent(2, function(inst) inst.Physics:MoveRelFacing(20 / 150) end),
			FrameEvent(41, function(inst) inst.Physics:MoveRelFacing(-20 / 150) end),
			--

			FrameEvent(2, function(inst)
				inst.components.timer:StartTimer("whistle_cd", 12, true)
				inst.components.timer:StartTimer("idlebehavior_cd", 8, true)
			end),
			FrameEvent(28, function(inst)
				inst.sg:AddStateTag("caninterrupt")
			end),
			FrameEvent(46, function(inst)
				inst.sg:RemoveStateTag("busy")
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
		name = "calling",
		tags = { "busy", "cancombine" },

		onenter = function(inst)
			inst.AnimState:PlayAnimation("gather")
		end,

		timeline =
		{
			FrameEvent(10, function(inst)
				if inst.sg.statemem.queuedcombine ~= nil and inst.sg.statemem.queuedcombine:IsValid() then
					inst.sg.statemem.queuedcombine:PushEvent("combinewait")
				else
					inst.sg.statemem.queuedcombine = nil
				end
			end),
			FrameEvent(30, function(inst)
				inst.sg:AddStateTag("caninterrupt")
			end),
			FrameEvent(35, function(inst)
				if inst.sg.statemem.queuedcombine ~= nil and inst.sg.statemem.queuedcombine:IsValid() then
					inst.sg.statemem.queuedcombine:PushEvent("combinewait")
				else
					inst.sg.statemem.queuedcombine = nil
				end
			end),
			FrameEvent(55, function(inst)
				inst.sg:RemoveStateTag("busy")
				OnCombine(inst, inst.sg.statemem.queuedcombine)
			end),
		},

		events =
		{
			EventHandler("docombine", function(inst, other)
				if inst.sg:HasStateTag("busy") then
					if other ~= nil then
						inst.sg.statemem.queuedcombine = other
						other:PushEvent("combinewait")
					end
				else
					OnCombine(inst, other)
				end
			end),
			EventHandler("animover", function(inst)
				inst.sg:GoToState("idle")
			end),
		},
	}),

	State({
		name = "taunt1",
		tags = { "busy", "caninterrupt" },

		onenter = function(inst)
			inst.AnimState:PlayAnimation("behavior2")
		end,

		timeline =
		{
			--physics
			FrameEvent(4, function(inst) inst.Physics:MoveRelFacing(6 / 150) end),
			FrameEvent(6, function(inst) inst.Physics:MoveRelFacing(8 / 150) end),
			FrameEvent(8, function(inst) inst.Physics:MoveRelFacing(8 / 150) end),
			FrameEvent(40, function(inst) inst.Physics:MoveRelFacing(-22 / 150) end),
			--

			FrameEvent(6, function(inst)
				inst.components.timer:StartTimer("taunt_cd", 12, true)
				inst.components.timer:StartTimer("idlebehavior_cd", 8, true)
			end),
			FrameEvent(44, function(inst)
				inst.sg:RemoveStateTag("busy")
			end),
		},

		events =
		{
			EventHandler("animover", function(inst)
				inst.sg:GoToState("idle")
			end),
		},

		onexit = function(inst)
			inst.components.hitbox:StopRepeatTargetDelay()
		end,
	}),

	-- triple taunt
	State({
		name = "taunt3",
		tags = { "busy" },

		onenter = function(inst)
			inst.AnimState:PlayAnimation("cabbageroll3_behavior1")
		end,

		timeline =
		{
			--physics
			FrameEvent(5, function(inst) inst.Physics:MoveRelFacing(30 / 150) end),
			FrameEvent(5, function(inst) inst.Physics:SetSize(1.1) end),
			FrameEvent(6, function(inst) inst.Physics:MoveRelFacing(30 / 150) end),
			FrameEvent(6, function(inst) inst.Physics:SetSize(1.3) end),
			FrameEvent(34, function(inst) inst.Physics:SetSize(370 / 300) end),
			FrameEvent(34, function(inst) inst.Physics:MoveRelFacing(-10 / 150) end),
			FrameEvent(36, function(inst) inst.Physics:SetSize(1.1) end),
			FrameEvent(36, function(inst) inst.Physics:MoveRelFacing(-20 / 150) end),
			FrameEvent(38, function(inst) inst.Physics:SetSize(.9) end),
			FrameEvent(38, function(inst) inst.Physics:MoveRelFacing(-30 / 150) end),
			--

			--head hitbox
			FrameEvent(6, function(inst) inst.components.offsethitboxes:SetEnabled("offsethitbox", true) end),
			FrameEvent(6, function(inst) inst.components.offsethitboxes:Move("offsethitbox", .1) end),
			FrameEvent(34, function(inst) inst.components.offsethitboxes:Move("offsethitbox", 25/150) end),
			FrameEvent(36, function(inst) inst.components.offsethitboxes:SetEnabled("offsethitbox", false) end),
			--

			FrameEvent(5, function(inst)
				inst.components.timer:StartTimer("taunt_cd", 12, true)
			end),
			FrameEvent(38, function(inst)
				inst.sg:AddStateTag("caninterrupt")
			end),
			FrameEvent(42, function(inst)
				inst.sg:RemoveStateTag("busy")
			end),
		},
	}),

	-- single attacks
	State({
		name = "bite",
		tags = { "attack", "busy" },

		onenter = function(inst, target)
			inst.AnimState:PlayAnimation("bite")
			inst.sg.statemem.speedmult = 1
			if target ~= nil and target:IsValid() then
				local facingrot = inst.Transform:GetFacingRotation()
				local diff
				local dir = inst:GetAngleTo(target)
				diff = ReduceAngle(dir - facingrot)

				if math.abs(diff) < 90 then
					local x, z = inst.Transform:GetWorldXZ()
					local x1, z1 = target.Transform:GetWorldXZ()
					local dx = math.abs(x1 - x)
					local dz = math.abs(z1 - z)
					local dx1 = math.max(0, dx - inst.Physics:GetSize() - target.Physics:GetSize())
					local dz1 = math.max(0, dz - inst.Physics:GetDepth() - target.Physics:GetDepth())
					local mult = math.max(dx1 ~= 0 and dx1 / dx or 0, dz1 ~= 0 and dz1 / dz or 0)
					local dist = math.sqrt(dx * dx + dz * dz) * mult

					inst.sg.statemem.speedmult = math.clamp(dist / 2.5, .25, 2.0)
				end
			end
		end,

		timeline =
		{
			--physics
			FrameEvent(1, function(inst) inst.Physics:MoveRelFacing(18 / 150) end),
			FrameEvent(2, function(inst) SGCommon.Fns.SetMotorVelScaled(inst, 5 * inst.sg.statemem.speedmult) end),
			FrameEvent(3, function(inst) SGCommon.Fns.SetMotorVelScaled(inst, 6 * inst.sg.statemem.speedmult) end),
			FrameEvent(11, function(inst) inst.sg.statemem.speedmult = math.sqrt(inst.sg.statemem.speedmult) end),
			FrameEvent(11, function(inst) SGCommon.Fns.SetMotorVelScaled(inst, 3 * inst.sg.statemem.speedmult) end),
			FrameEvent(13, function(inst) SGCommon.Fns.SetMotorVelScaled(inst, 2 * inst.sg.statemem.speedmult) end),
			FrameEvent(14, function(inst) SGCommon.Fns.SetMotorVelScaled(inst, 1 * inst.sg.statemem.speedmult) end),
			FrameEvent(15, function(inst) SGCommon.Fns.SetMotorVelScaled(inst, .5 * inst.sg.statemem.speedmult) end),
			FrameEvent(16, function(inst) inst.Physics:Stop() end),
			--

			FrameEvent(2, function(inst)
				inst.sg:AddStateTag("airborne")
				inst.Physics:StartPassingThroughObjects()
			end),
			FrameEvent(13, function(inst)
				inst.sg:RemoveStateTag("airborne")
				inst.Physics:StopPassingThroughObjects()
				inst.components.attacktracker:CompleteActiveAttack()
				inst.components.hitbox:StartRepeatTargetDelay()
				inst.components.hitbox:PushBeam(0, 1.5, 1.3, HitPriority.MOB_DEFAULT)
			end),
			FrameEvent(14, function(inst)
				inst.components.hitbox:PushBeam(0, 1.3, 1.2, HitPriority.MOB_DEFAULT)
			end),
			FrameEvent(15, function(inst)
				inst.components.hitbox:PushBeam(0, 1.2, 1.1, HitPriority.MOB_DEFAULT)
			end),
			FrameEvent(23, function(inst)
				inst.sg:AddStateTag("caninterrupt")
			end),
			FrameEvent(29, function(inst)
				inst.sg:RemoveStateTag("busy")
			end),
		},

		events =
		{
			EventHandler("hitboxtriggered", OnBiteHitBoxTriggered),
			EventHandler("animover", function(inst)
				inst.sg:GoToState("idle")
			end),
		},

		onexit = function(inst)
			inst.Physics:StopPassingThroughObjects()
			inst.Physics:Stop()
			inst.components.hitbox:StopRepeatTargetDelay()
			inst.components.attacktracker:CompleteActiveAttack()
		end,
	}),

	State({
		name = "roll",
		tags = { "attack", "busy" },

		onenter = function(inst, target)
			inst.AnimState:PlayAnimation("roll_loop", true)
			inst.sg.statemem.target = target
			inst.sg.statemem.knockbackonly = true
			SGCommon.Fns.SetMotorVelScaled(inst, 10)
			inst.sg:SetTimeoutAnimFrames(TUNING.cabbageroll.roll_animframes)
			inst.sg.statemem.roll_finished = false
			inst.Physics:StartPassingThroughObjects()
			inst.sg.statemem.exit_state = "roll_pst"
			inst.sg.statemem.active_attack = "roll"
		end,

		onupdate = function(inst)
			if inst.sg.statemem.hitting then
				inst.components.hitbox:PushBeam(0.25, 1.25, 1.25, HitPriority.MOB_DEFAULT)
			end
		end,

		timeline =
		{
			--physics
			FrameEvent(0, function(inst)
				local facingrot = inst.Transform:GetFacingRotation()
				local target = inst.sg.statemem.target
				local diff
				if target ~= nil and target:IsValid() then
					local dir = inst:GetAngleTo(target)
					diff = ReduceAngle(dir - facingrot)
					if math.abs(diff) >= 90 then
						diff = nil
					end
				end
				if diff == nil then
					local dir = inst.Transform:GetRotation()
					diff = ReduceAngle(dir - facingrot)
				end
				diff = math.clamp(diff, -30, 30)
				inst.Transform:SetRotation(facingrot + diff)
			end),
			--
			FrameEvent(0, function(inst)
				inst.sg:AddStateTag("airborne")
				inst.components.hitbox:StartRepeatTargetDelay()
				inst.components.attacktracker:CompleteActiveAttack()
			end),

			FrameEvent(2, function(inst)
				inst.sg.statemem.hitting = true
			end),
		},

		events =
		{
			EventHandler("hitboxtriggered", OnRollHitBoxTriggered),
			EventHandler("animover", function(inst)
				if inst.sg.statemem.roll_finished then
					inst.sg:GoToState(inst.sg.statemem.exit_state)
				end
			end),
		},


		ontimeout = function(inst)
			inst.sg.statemem.roll_finished = true -- don't transition yet... set a flag that it -can- transition on the next anim loop
		end,

		onexit = function(inst)
			inst.components.hitbox:StopRepeatTargetDelay()
			inst.Physics:StopPassingThroughObjects()
			inst.components.attacktracker:CompleteActiveAttack()
		end,
	}),

	State({
		name = "roll_pst",
		tags = { "busy", "airborne" },

		onenter = function(inst)
			inst.AnimState:PlayAnimation("roll_pst")
		end,

		timeline =
		{
			--physics
			FrameEvent(0, function(inst) SGCommon.Fns.SetMotorVelScaled(inst, 5) end),
			FrameEvent(3, function(inst) SGCommon.Fns.SetMotorVelScaled(inst, 4) end),
			FrameEvent(4, function(inst) SGCommon.Fns.SetMotorVelScaled(inst, 3) end),
			FrameEvent(5, function(inst) SGCommon.Fns.SetMotorVelScaled(inst, 2) end),
			FrameEvent(6, function(inst) SGCommon.Fns.SetMotorVelScaled(inst, 1) end),
			FrameEvent(7, function(inst) SGCommon.Fns.SetMotorVelScaled(inst, .5) end),
			FrameEvent(8, function(inst) inst.Physics:Stop() end),

			--
			FrameEvent(0, function(inst)
				inst.sg:RemoveStateTag("airborne")
			end),

			FrameEvent(5, function(inst)
				inst.sg:AddStateTag("caninterrupt")
			end),
			FrameEvent(10, function(inst)
				inst.sg:RemoveStateTag("busy")
			end),
		},

		events =
		{
			EventHandler("animover", function(inst)
				inst.sg:GoToState("idle")
			end),
			EventHandler("hitboxtriggered", OnRollHitBoxTriggered),
		},

		onexit = function(inst) inst.Physics:Stop() end,
	}),

	State({
		name = "elite_roll",
		tags = { "attack", "busy" },

		onenter = function(inst, target)
			inst.AnimState:PlayAnimation("elite_roll_loop", true)
			inst.sg.statemem.target = target
			inst.sg.statemem.knockbackonly = true
			SGCommon.Fns.SetMotorVelScaled(inst, 30, SGCommon.SGSpeedScale.LIGHT) -- This attack is already so fast, don't let speedmult scale it much more
			inst.sg:SetTimeoutAnimFrames(inst.tuning.roll_animframes)
			inst.sg.statemem.roll_finished = false
			inst.Physics:StartPassingThroughObjects()
			inst.sg.statemem.active_attack = "elite_roll"
			inst.sg.statemem.exit_state = "elite_roll_pst"
		end,

		onupdate = function(inst)
			if inst.sg.statemem.hitting then
				inst.components.hitbox:PushBeam(0.25, 1.25, 1.25, HitPriority.MOB_DEFAULT)
			end
		end,

		timeline =
		{
			-- --physics
			FrameEvent(0, function(inst)
				local facingrot = inst.Transform:GetFacingRotation()
				local target = inst.sg.statemem.target
				local diff
				if target ~= nil and target:IsValid() then
					local dir = inst:GetAngleTo(target)
					diff = ReduceAngle(dir - facingrot)
					if math.abs(diff) >= 90 then
						diff = nil
					end
				end
				if diff == nil then
					local dir = inst.Transform:GetRotation()
					diff = ReduceAngle(dir - facingrot)
				end
				diff = math.clamp(diff, -30, 30)
				inst.Transform:SetRotation(facingrot + diff)
			end),

			--
			FrameEvent(0, function(inst)
				inst.sg:AddStateTag("airborne")
				inst.components.hitbox:StartRepeatTargetDelay()
				inst.components.attacktracker:CompleteActiveAttack()
			end),

			FrameEvent(2, function(inst)
				inst.sg.statemem.hitting = true
			end),
		},

		events =
		{
			EventHandler("hitboxtriggered", OnRollHitBoxTriggered),
			EventHandler("animover", function(inst)
				if inst.sg.statemem.roll_finished then
					inst.sg:GoToState("elite_roll_pst")
				end
			end),
		},


		ontimeout = function(inst)
			inst.sg.statemem.roll_finished = true -- don't transition yet... set a flag that it -can- transition on the next anim loop
		end,

		onexit = function(inst)
			inst.components.hitbox:StopRepeatTargetDelay()
			inst.Physics:StopPassingThroughObjects()
			inst.components.attacktracker:CompleteActiveAttack()
		end,
	}),

	State({
		name = "elite_roll_pst",
		tags = { "busy", "airborne" },

		onenter = function(inst)
			inst.AnimState:PlayAnimation("elite_roll_pst")
		end,

		timeline =
		{
			--physics
			FrameEvent(0, function(inst) SGCommon.Fns.SetMotorVelScaled(inst, 5, SGCommon.SGSpeedScale.LIGHT) end),
			FrameEvent(3, function(inst) SGCommon.Fns.SetMotorVelScaled(inst, 4, SGCommon.SGSpeedScale.LIGHT) end),
			FrameEvent(4, function(inst) SGCommon.Fns.SetMotorVelScaled(inst, 3, SGCommon.SGSpeedScale.LIGHT) end),
			FrameEvent(5, function(inst) SGCommon.Fns.SetMotorVelScaled(inst, 2, SGCommon.SGSpeedScale.LIGHT) end),
			FrameEvent(6, function(inst) SGCommon.Fns.SetMotorVelScaled(inst, 1, SGCommon.SGSpeedScale.LIGHT) end),
			FrameEvent(7, function(inst) SGCommon.Fns.SetMotorVelScaled(inst, .5, SGCommon.SGSpeedScale.LIGHT) end),
			FrameEvent(8, function(inst) inst.Physics:Stop() end),

			--
			FrameEvent(0, function(inst)
				inst.sg:RemoveStateTag("airborne")
			end),

			FrameEvent(5, function(inst)
				inst.sg:AddStateTag("caninterrupt")
			end),
			FrameEvent(10, function(inst)
				inst.sg:RemoveStateTag("busy")
			end),
		},

		events =
		{
			EventHandler("animover", function(inst)
				inst.sg:GoToState("idle")
			end),
			EventHandler("hitboxtriggered", OnRollHitBoxTriggered),
		},

		onexit = function(inst) inst.Physics:Stop() end,
	}),

	-- single attacks, post-bodyslam from 3-tower
	State({
		name = "bodyslam_top",
		tags = { "busy" },

		onenter = function(inst)
			inst.AnimState:PlayAnimation("bodyslam_top")
		end,

		timeline =
		{
			--physics
			FrameEvent(0, function(inst) SGCommon.Fns.SetMotorVelScaled(inst, 7) end),
			FrameEvent(10, function(inst) SGCommon.Fns.SetMotorVelScaled(inst, 5) end),
			FrameEvent(18, function(inst) SGCommon.Fns.SetMotorVelScaled(inst, 2) end),
			FrameEvent(19, function(inst) SGCommon.Fns.SetMotorVelScaled(inst, 1) end),
			FrameEvent(20, function(inst) inst.Physics:Stop() end),
			FrameEvent(20, function(inst) inst.Physics:MoveRelFacing(-10 / 150) end),
			FrameEvent(22, function(inst) inst.Physics:MoveRelFacing(-10 / 150) end),
			--
			FrameEvent(2, function(inst)
				inst.sg:AddStateTag("airborne")
			end),
			FrameEvent(10, function(inst)
				inst.sg:RemoveStateTag("airborne")
			end),
			FrameEvent(22, function(inst)
				inst.sg:RemoveStateTag("caninterrupt")
			end),
			FrameEvent(24, function(inst)
				inst.sg:RemoveStateTag("busy")
			end),
		},

		events =
		{
			EventHandler("animover", function(inst)
				inst.sg:GoToState("idle")
			end),
		},

		onexit = function(inst)
			inst.Physics:Stop()
			inst.components.hitbox:StopRepeatTargetDelay()
		end,
	}),

	State({
		name = "bodyslam_mid",
		tags = { "busy", "airborne", "nointerrupt" },

		onenter = function(inst)
			inst.AnimState:PlayAnimation("bodyslam_mid")
		end,

		timeline =
		{
			--physics
			FrameEvent(0, function(inst) SGCommon.Fns.SetMotorVelScaled(inst, 2) end),
			FrameEvent(4, function(inst) SGCommon.Fns.SetMotorVelScaled(inst, 1.5) end),
			FrameEvent(10, function(inst) SGCommon.Fns.SetMotorVelScaled(inst, 1) end),
			FrameEvent(12, function(inst) SGCommon.Fns.SetMotorVelScaled(inst, .5) end),
			FrameEvent(19, function(inst) inst.Physics:Stop() end),
			--

			FrameEvent(12, function(inst)
				inst.sg:RemoveStateTag("nointerrupt")
			end),
			FrameEvent(19, function(inst)
				inst.sg:RemoveStateTag("airborne")
			end),
			FrameEvent(23, function(inst)
				inst.sg:RemoveStateTag("caninterrupt")
			end),
			FrameEvent(27, function(inst)
				inst.sg:RemoveStateTag("busy")
			end),
		},

		events =
		{
			EventHandler("animover", function(inst)
				inst.sg:GoToState("idle")
			end),
		},

		onexit = function(inst) inst.Physics:Stop() end,
	}),

	State({
		name = "bodyslam_btm",
		tags = { "busy" },

		onenter = function(inst)
			inst.AnimState:PlayAnimation("bodyslam_btm")
		end,

		timeline =
		{
			--physics
			FrameEvent(0, function(inst) SGCommon.Fns.SetMotorVelScaled(inst, -3.5) end),
			--
			FrameEvent(2, function(inst)
				inst.sg:AddStateTag("airborne")
			end),
		},

		events =
		{
			EventHandler("animover", function(inst)
				inst.sg.statemem.pst = true
				inst:FlipFacingAndRotation()
				inst.sg:GoToState("bodyslam_btm_pst")
			end),
		},

		onexit = function(inst)
			if not inst.sg.statemem.pst then
				inst.Physics:Stop()
			end
		end,
	}),

	State({
		name = "bodyslam_btm_pst",
		tags = { "busy", "airborne" },

		onenter = function(inst)
			inst.AnimState:PlayAnimation("bodyslam_btm_flip_pst")
		end,

		timeline =
		{
			--physics
			FrameEvent(0, function(inst) SGCommon.Fns.SetMotorVelScaled(inst, -3.5) end),
			FrameEvent(2, function(inst) SGCommon.Fns.SetMotorVelScaled(inst, 2.5) end),
			FrameEvent(10, function(inst) SGCommon.Fns.SetMotorVelScaled(inst, 2) end),
			FrameEvent(11, function(inst) SGCommon.Fns.SetMotorVelScaled(inst, 1) end),
			FrameEvent(12, function(inst) SGCommon.Fns.SetMotorVelScaled(inst, .5) end),
			FrameEvent(13, function(inst) inst.Physics:Stop() end),
			FrameEvent(15, function(inst) inst.Physics:MoveRelFacing(-10 / 150) end),
			--

			FrameEvent(2, function(inst)
				inst.sg:RemoveStateTag("airborne")
			end),
			FrameEvent(12, function(inst)
				inst.sg:RemoveStateTag("caninterrupt")
			end),
			FrameEvent(15, function(inst)
				inst.sg:RemoveStateTag("busy")
			end),
		},

		events =
		{
			EventHandler("animover", function(inst)
				inst.sg:GoToState("idle")
			end),
		},

		onexit = function(inst) inst.Physics:Stop() end,
	}),

	-- unused?
	State({
		name = "catapult",
		tags = { "attack", "busy", "airborne", "nointerrupt" },

		onenter = function(inst, btm)
			inst.AnimState:PlayAnimation("catapult")
			if btm ~= nil and btm:IsValid() then
				inst.sg.statemem.btm = btm
				inst.components.hitstopper:AttachChild(btm)
			end
		end,

		onupdate = function(inst)
			if inst.sg.statemem.hitting then
				if inst.sg.statemem.btm ~= nil then
					if inst.sg.statemem.btm:IsValid() then
						inst.components.hitbox:PushBeam(-3, 1, 1, HitPriority.MOB_DEFAULT)
						return
					end
					inst.sg.statemem.btm = nil
				end
				inst.components.hitbox:PushBeam(-1, 1, 1, HitPriority.MOB_DEFAULT)
			end
		end,

		timeline =
		{
			--physics
			FrameEvent(0, function(inst) SGCommon.Fns.SetMotorVelScaled(inst, 32) end),
			FrameEvent(4, function(inst) SGCommon.Fns.SetMotorVelScaled(inst, 26) end),
			FrameEvent(5, function(inst) SGCommon.Fns.SetMotorVelScaled(inst, 22) end),
			FrameEvent(6, function(inst) SGCommon.Fns.SetMotorVelScaled(inst, 18) end),
			FrameEvent(14, function(inst) SGCommon.Fns.SetMotorVelScaled(inst, 8) end),
			FrameEvent(22, function(inst) SGCommon.Fns.SetMotorVelScaled(inst, 2) end),
			FrameEvent(23, function(inst) SGCommon.Fns.SetMotorVelScaled(inst, 1) end),
			FrameEvent(24, function(inst) inst.Physics:Stop() end),
			FrameEvent(24, function(inst) inst.Physics:MoveRelFacing(-10 / 150) end),
			FrameEvent(26, function(inst) inst.Physics:MoveRelFacing(-10 / 150) end),
			--

			FrameEvent(0, function(inst)
				inst.components.hitbox:StartRepeatTargetDelay()
				inst.sg.statemem.hitting = true
			end),
			FrameEvent(2, function(inst)
				if inst.sg.statemem.btm ~= nil then
					inst.components.hitstopper:DetachChild(inst.sg.statemem.btm)
					inst.sg.statemem.btm = nil
				end
			end),
			FrameEvent(4, function(inst)
				inst.sg:RemoveStateTag("airborne")
			end),
			FrameEvent(6, function(inst)
				inst.sg:AddStateTag("airborne")
			end),
			FrameEvent(10, function(inst)
				inst.sg:RemoveStateTag("nointerrupt")
			end),
			FrameEvent(14, function(inst)
				inst.sg:RemoveStateTag("airborne")
			end),
			FrameEvent(16, function(inst)
				inst.sg.statemem.knockbackonly = true
			end),
			FrameEvent(22, function(inst)
				inst.sg.statemem.hitting = false
			end),
			FrameEvent(26, function(inst)
				inst.sg:AddStateTag("caninterrupt")
			end),
			FrameEvent(28, function(inst)
				inst.sg:RemoveStateTag("busy")
			end),
		},

		events =
		{
			EventHandler("hitboxtriggered", OnRollHitBoxTriggered),
			EventHandler("animover", function(inst)
				inst.sg:GoToState("idle")
			end),
		},

		onexit = function(inst)
			inst.Physics:Stop()
			inst.components.hitbox:StopRepeatTargetDelay()
			if inst.sg.statemem.btm ~= nil then
				inst.components.hitstopper:DetachChild(inst.sg.statemem.btm)
			end
		end,
	}),

	-- single attack, post-throw from 2-tower
	-- TODO: networking2022, there is still a hierarchical dependency here that needs to be maintained across the network
	State({
		name = "thrown",
		tags = { "attack", "busy", "airborne", "nointerrupt" },

		onenter = function(inst, btm)
			inst.AnimState:PlayAnimation("thrown")
			if btm ~= nil and btm:IsValid() then
				inst.sg.statemem.btm = btm
				inst.components.hitstopper:AttachChild(btm)
			end
			inst.Physics:StartPassingThroughObjects()
		end,

		onupdate = function(inst)
			if inst.sg.statemem.hitting then
				if inst.sg.statemem.btm ~= nil then
					if inst.sg.statemem.btm:IsValid() then
						inst.components.hitbox:PushBeam(-2, 1.5, 1, HitPriority.MOB_DEFAULT)
						return
					end
					inst.sg.statemem.btm = nil
				end
				inst.components.hitbox:PushBeam(0.20, 1.50, 1.00, HitPriority.MOB_DEFAULT)
			end
		end,

		timeline =
		{
			--physics
			FrameEvent(0, function(inst) SGCommon.Fns.SetMotorVelScaled(inst, 24) end),
			FrameEvent(4, function(inst) SGCommon.Fns.SetMotorVelScaled(inst, 20) end),
			FrameEvent(5, function(inst) SGCommon.Fns.SetMotorVelScaled(inst, 18) end),
			FrameEvent(6, function(inst) SGCommon.Fns.SetMotorVelScaled(inst, 16) end),
			FrameEvent(14, function(inst) SGCommon.Fns.SetMotorVelScaled(inst, 8) end),
			FrameEvent(22, function(inst) SGCommon.Fns.SetMotorVelScaled(inst, 2) end),
			FrameEvent(23, function(inst) SGCommon.Fns.SetMotorVelScaled(inst, 1) end),
			FrameEvent(24, function(inst) inst.Physics:Stop() end),
			FrameEvent(24, function(inst) inst.Physics:MoveRelFacing(-10 / 150) end),
			FrameEvent(26, function(inst) inst.Physics:MoveRelFacing(-10 / 150) end),
			--

			FrameEvent(0, function(inst)
				inst.components.hitbox:StartRepeatTargetDelay()
				inst.sg.statemem.hitting = true
			end),
			FrameEvent(2, function(inst)
				if inst.sg.statemem.btm ~= nil then
					inst.components.hitstopper:DetachChild(inst.sg.statemem.btm)
					inst.sg.statemem.btm = nil
				end
			end),
			FrameEvent(4, function(inst)
				inst.sg:RemoveStateTag("airborne")
			end),
			FrameEvent(6, function(inst)
				inst.sg:AddStateTag("airborne")
			end),
			FrameEvent(10, function(inst)
				inst.sg:RemoveStateTag("caninterrupt")
			end),
			FrameEvent(14, function(inst)
				inst.sg:RemoveStateTag("airborne")
				inst.Physics:StopPassingThroughObjects()
			end),
			FrameEvent(16, function(inst)
				inst.sg.statemem.knockbackonly = true
			end),
			FrameEvent(22, function(inst)
				inst.sg.statemem.hitting = false
			end),
			FrameEvent(26, function(inst)
				inst.sg:AddStateTag("caninterrupt")
			end),
			FrameEvent(28, function(inst)
				inst.sg:RemoveStateTag("busy")
			end),
		},

		events =
		{
			EventHandler("hitboxtriggered", OnRollHitBoxTriggered),
			EventHandler("animover", function(inst)
				inst.sg:GoToState("idle")
			end),
		},

		onexit = function(inst)
			inst.Physics:Stop()
			inst.Physics:StartPassingThroughObjects()
			inst.components.hitbox:StopRepeatTargetDelay()
		end,
	}),

	State({
		name = "throw_pst",
		tags = { "attack", "busy", "airborne", "nointerrupt" },

		onenter = function(inst, speed)
			inst.AnimState:PlayAnimation("throw_pst")
			inst.sg.statemem.speed = speed or 4
			inst.Physics:StartPassingThroughObjects()
		end,

		timeline =
		{
			--physics
			FrameEvent(0, function(inst) SGCommon.Fns.SetMotorVelScaled(inst, inst.sg.statemem.speed) end),
			FrameEvent(4, function(inst) SGCommon.Fns.SetMotorVelScaled(inst, 1) end),
			FrameEvent(5, function(inst) SGCommon.Fns.SetMotorVelScaled(inst, .5) end),
			FrameEvent(6, function(inst) inst:SnapToFacingRotation() end),
			FrameEvent(6, function(inst) SGCommon.Fns.SetMotorVelScaled(inst, 4) end),
			FrameEvent(11, function(inst) SGCommon.Fns.SetMotorVelScaled(inst, 3) end),
			FrameEvent(14, function(inst) SGCommon.Fns.SetMotorVelScaled(inst, 2) end),
			FrameEvent(17, function(inst) SGCommon.Fns.SetMotorVelScaled(inst, 1) end),
			FrameEvent(21, function(inst) inst.Physics:Stop() end),
			--

			FrameEvent(2, function(inst)
				inst.sg:RemoveStateTag("nointerrupt")
			end),
			FrameEvent(4, function(inst)
				inst.sg:RemoveStateTag("airborne")
				inst.Physics:StopPassingThroughObjects()
			end),
			FrameEvent(25, function(inst)
				inst.sg:AddStateTag("caninterrupt")
			end),
			FrameEvent(27, function(inst)
				inst.sg:RemoveStateTag("busy")
			end),
		},

		events =
		{
			EventHandler("animover", function(inst)
				inst.sg:GoToState("idle")
			end),
		},

		onexit = function(inst)
			inst.Physics:Stop()
			inst.Physics:StopPassingThroughObjects()
		end,
	}),

	-- single, combine states
	State({
		name = "combine",
		tags = { "busy" },

		onenter = function(inst, target)
			inst.AnimState:PlayAnimation("combine")
			if target ~= nil and target:IsValid() then
				local dist = math.sqrt(inst:GetDistanceSqTo(target))
				--constant speed over 14 frames
				inst.sg.statemem.speed = math.min(6, dist / 14 * 30)
				inst.sg.statemem.target = target
			else
				inst.sg.statemem.speed = 6
			end
		end,

		timeline =
		{
			--physics
			FrameEvent(3, function(inst)
				local target = inst.sg.statemem.target
				if target ~= nil and target:IsValid() then
					local dir = inst:GetAngleTo(target)
					local facingrot = inst.Transform:GetFacingRotation()
					if DiffAngle(dir, facingrot) < 90 then
						inst.Transform:SetRotation(dir)
					end
				else
					inst.sg.statemem.target = nil
				end
			end),
			FrameEvent(3, function(inst) inst.Physics:StartPassingThroughObjects() end),
			FrameEvent(3, function(inst) inst.Physics:SetMotorVel(inst.sg.statemem.speed) end), -- TODO #speedmult will changing this make them way more likely to miss?
			--

			FrameEvent(6, function(inst)
				inst.sg:AddStateTag("airborne")
				inst.sg:AddStateTag("nointerrupt")
			end),
		},

		events =
		{
			EventHandler("animover", function(inst)
				local target = inst.sg.statemem.target
				if target ~= nil and target:IsValid() then
					if (target:TryToTakeControl() and
						(not target.sg:HasStateTag("busy")
							or target.sg:HasStateTag("caninterrupt")
							or target.sg:HasStateTag("cancombine"))
							and target:IsNear(inst, .5)) then

						-- calculate absolute hp before Set[Double/Triple] as that changes things on target
						local hp = inst.components.health:GetCurrent() + target.components.health:GetCurrent()

						target.components.cabbagetower:SetDouble(inst)
						target.sg:GoToState("combine2")

						target.components.health:SetCurrent(hp, true)
						target.components.cabbagetower:SetStartingHealthPercentage(target.components.health:GetPercent())

						local tgt = target.components.combat:GetTarget() or inst.components.combat:GetTarget()
						target.components.combat:SetTarget(tgt)

						target.Transform:SetRotation(inst.Transform:GetFacingRotation())
						target.Transform:SetRotation(inst.Transform:GetRotation())
						return
					end
				end

				inst.sg.statemem.combining = true
				inst.sg:GoToState("combine_miss", inst.sg.statemem.speed)
			end),
		},

		onexit = function(inst)
			if not inst.sg.statemem.combining then
				inst.Physics:Stop()
			end
			inst.Physics:StopPassingThroughObjects()
		end,
	}),

	State({
		name = "combine_miss",
		tags = { "busy", "airborne", "nointerrupt" },

		onenter = function(inst, speed)
			inst.AnimState:PlayAnimation("combine_miss")
			inst.sg.statemem.speed = speed or 0
			inst.sg.statemem.speedmult = math.min(2, inst.sg.statemem.speed / 2) / 2
		end,

		timeline =
		{
			--physics
			FrameEvent(0, function(inst) inst.Physics:SetMotorVel(inst.sg.statemem.speed) end),
			FrameEvent(3, function(inst) inst.Physics:SetMotorVel(2 * inst.sg.statemem.speedmult) end),
			FrameEvent(4, function(inst) inst.Physics:SetMotorVel(1 * inst.sg.statemem.speedmult) end),
			FrameEvent(5, function(inst) inst.Physics:SetMotorVel(.5 * inst.sg.statemem.speedmult) end),
			FrameEvent(6, function(inst) inst.Physics:Stop() end),
			--

			FrameEvent(1, function(inst)
				inst.sg:RemoveStateTag("nointerrupt")
			end),
			FrameEvent(3, function(inst)
				inst.sg:RemoveStateTag("airborne")
			end),
			FrameEvent(7, function(inst)
				inst.sg:AddStateTag("caninterrupt")
			end),
			FrameEvent(11, function(inst)
				inst.sg:RemoveStateTag("busy")
			end),
		},

		events =
		{
			EventHandler("animover", function(inst)
				inst.sg:GoToState("idle")
			end),
		},

		onexit = function(inst) inst.Physics:Stop() end,
	}),

	State({
		name = "combine3",
		tags = { "busy" },

		onenter = function(inst, target)
			inst.AnimState:PlayAnimation("combine3")
			if target ~= nil and target:IsValid() and target:TryToTakeControl() then
				local dist = math.sqrt(inst:GetDistanceSqTo(target))
				--constant speed over 16 frames
				inst.sg.statemem.speed = math.min(6, dist / 16 * 30)
				inst.sg.statemem.target = target
			else
				inst.sg.statemem.speed = 6
			end
		end,

		timeline =
		{
			--physics
			FrameEvent(3, function(inst)
				local target = inst.sg.statemem.target
				if target ~= nil and target:IsValid() and target:TryToTakeControl() then
					local dir = inst:GetAngleTo(target)
					local facingrot = inst.Transform:GetFacingRotation()
					if DiffAngle(dir, facingrot) < 90 then
						inst.Transform:SetRotation(dir)
					end
				else
					inst.sg.statemem.target = nil
				end
			end),
			FrameEvent(3, function(inst) inst.Physics:StartPassingThroughObjects() end),
			FrameEvent(3, function(inst) inst.Physics:SetMotorVel(inst.sg.statemem.speed) end),
			--

			FrameEvent(6, function(inst)
				inst.sg:AddStateTag("airborne")
				inst.sg:AddStateTag("nointerrupt")
			end),
			FrameEvent(7, function(inst) inst.sg:AddStateTag("airborne_high") end),
			FrameEvent(17, function(inst) inst.sg:RemoveStateTag("airborne_high") end),
		},

		events =
		{
			EventHandler("animover", function(inst)
				local target = inst.sg.statemem.target
				if target ~= nil and target:IsValid() then
					if (target:TryToTakeControl() and
						(not target.sg:HasStateTag("busy")
							or target.sg:HasStateTag("caninterrupt")
							or target.sg:HasStateTag("cancombine"))
							and target:IsNear(inst, .5)) then

						-- calculate absolute hp before Set[Double/Triple] as that changes things on target
						local hp = inst.components.health:GetCurrent() + target.components.health:GetCurrent()

						target.components.cabbagetower:SetTriple(inst)
						target.sg:GoToState("combine3")

						target.components.health:SetCurrent(hp, true)
						target.components.cabbagetower:SetStartingHealthPercentage(target.components.health:GetPercent())

						local tgt = target.components.combat:GetTarget() or inst.components.combat:GetTarget()
						target.components.combat:SetTarget(tgt)

						--my facing/rotation
						target.Transform:SetRotation(inst.Transform:GetFacingRotation())
						target.Transform:SetRotation(inst.Transform:GetRotation())
						return
					end
				end

				inst.sg.statemem.combining = true
				inst.sg:GoToState("combine3_miss", inst.sg.statemem.speed)
			end),
		},

		onexit = function(inst)
			if not inst.sg.statemem.combining then
				inst.Physics:Stop()
			end
			inst.Physics:StopPassingThroughObjects()
		end,
	}),

	State({
		name = "combine3_miss",
		tags = { "busy", "airborne", "nointerrupt" },

		onenter = function(inst, speed)
			inst.AnimState:PlayAnimation("combine3_miss")
			inst.sg.statemem.speed = speed or 0
			inst.sg.statemem.speedmult = math.min(2, inst.sg.statemem.speed / 2) / 2
		end,

		timeline =
		{
			--physics
			FrameEvent(0, function(inst) inst.Physics:SetMotorVel(inst.sg.statemem.speed) end),
			FrameEvent(2, function(inst) inst.Physics:SetMotorVel(2 * inst.sg.statemem.speedmult) end),
			FrameEvent(3, function(inst) inst.Physics:SetMotorVel(1 * inst.sg.statemem.speedmult) end),
			FrameEvent(4, function(inst) inst.Physics:SetMotorVel(.5 * inst.sg.statemem.speedmult) end),
			FrameEvent(5, function(inst) inst.Physics:Stop() end),
			--

			FrameEvent(1, function(inst)
				inst.sg:RemoveStateTag("nointerrupt")
			end),
			FrameEvent(2, function(inst)
				inst.sg:RemoveStateTag("airborne")
			end),
			FrameEvent(6, function(inst)
				inst.sg:AddStateTag("caninterrupt")
			end),
			FrameEvent(10, function(inst)
				inst.sg:RemoveStateTag("busy")
			end),
		},

		events =
		{
			EventHandler("animover", function(inst)
				inst.sg:GoToState("idle")
			end),
		},

		onexit = function(inst) inst.Physics:Stop() end,
	}),

	-- double attacks

	-- unused
	State({
		name = "catapult_pst",
		tags = { "attack", "busy" },

		onenter = function(inst)
			inst.AnimState:PlayAnimation("catapult_pst")
		end,

		timeline =
		{
			--head hitbox
			FrameEvent(0, function(inst)inst.components.offsethitboxes:SetEnabled("offsethitbox", true) end),
			FrameEvent(0, function(inst) inst.components.offsethitboxes:Move("offsethitbox", 2.1) end),
			FrameEvent(2, function(inst) inst.components.offsethitboxes:Move("offsethitbox", 2.3) end),
			FrameEvent(6, function(inst) inst.components.offsethitboxes:Move("offsethitbox", 1.8) end),
			FrameEvent(8, function(inst) inst.components.offsethitboxes:Move("offsethitbox", .8) end),
			FrameEvent(10, function(inst) inst.components.offsethitboxes:SetEnabled("offsethitbox", false) end),
			--

			FrameEvent(14, function(inst)
				inst.sg:AddStateTag("caninterrupt")
			end),
			FrameEvent(16, function(inst)
				inst.sg:RemoveStateTag("busy")
			end),
		},

		events =
		{
			EventHandler("animover", function(inst)
				inst.sg:GoToState("idle")
			end),
		},

		onexit = function(inst) inst.components.offsethitboxes:SetEnabled("offsethitbox", false) end,
	}),

	State({
		name = "slam",
		tags = { "attack", "busy" },

		onenter = function(inst, target)
			inst.AnimState:PlayAnimation("slam")
			inst.sg.statemem.target = target
		end,

		timeline =
		{
			FrameEvent(6, function(inst)
				inst.components.offsethitboxes:SetEnabled("offsethitbox", true)
				inst.components.offsethitboxes:Move("offsethitbox", 3)
				inst.components.attacktracker:CompleteActiveAttack()
				inst.components.hitbox:StartRepeatTargetDelayAnimFrames(10)
				inst.components.hitbox:PushBeam(1.5, 3.8, 1, HitPriority.MOB_DEFAULT)
			end),

			FrameEvent(7, function(inst) -- hit 1
				inst.components.hitbox:PushBeam(1.9, 5, 1, HitPriority.MOB_DEFAULT)
			end),
			FrameEvent(8, function(inst) -- hit 1
				inst.components.hitbox:PushBeam(1.9, 5, 1, HitPriority.MOB_DEFAULT)
			end),

			FrameEvent(12, function(inst) -- bounce 1 start
				inst.sg:AddStateTag("airborne")
				inst.Physics:StartPassingThroughObjects()
				SGCommon.Fns.SetMotorVelScaled(inst, 7)
				inst.components.offsethitboxes:SetEnabled("offsethitbox", false)
			end),

			FrameEvent(28, function(inst) -- bounce 1 end
				inst.sg:RemoveStateTag("airborne")
				inst.Physics:StopPassingThroughObjects()
				inst.Physics:Stop()
				inst.components.offsethitboxes:SetEnabled("offsethitbox", true)
				inst.components.offsethitboxes:Move("offsethitbox", 3)
			end),

			FrameEvent(26, function(inst) -- hit 2 air
				inst.sg.statemem.hitflags = Attack.HitFlags.AIR_HIGH
				inst.components.hitbox:PushBeam(0.90, 2.50, 1.00, HitPriority.MOB_DEFAULT)
			end),
			FrameEvent(27, function(inst) -- hit 2 air
				inst.components.hitbox:PushBeam(0.70, 3.80, 1.00, HitPriority.MOB_DEFAULT)
			end),
			FrameEvent(28, function(inst) -- hit 2
				inst.sg.statemem.hitflags = nil
				inst.components.hitbox:PushBeam(1.60, 4.40, 1.00, HitPriority.MOB_DEFAULT)
			end),
			FrameEvent(29, function(inst) -- hit 2
				inst.components.hitbox:PushBeam(1.60, 5.00, 1.00, HitPriority.MOB_DEFAULT)
			end),

			FrameEvent(32, function(inst) -- bounce 2 start
				inst.sg:AddStateTag("airborne")
				inst.Physics:StartPassingThroughObjects()
				SGCommon.Fns.SetMotorVelScaled(inst, 6)
				inst.components.offsethitboxes:Move("offsethitbox", 0)
				inst.components.offsethitboxes:SetEnabled("offsethitbox", false)
			end),
			FrameEvent(44, function(inst) -- bounce 2 end
				inst.sg:RemoveStateTag("airborne")
				inst.Physics:StopPassingThroughObjects()
				inst.Physics:Stop()
			end),

			FrameEvent(55, function(inst) inst.sg:RemoveStateTag("busy") end), -- not busy
		},

		events =
		{
			EventHandler("hitboxtriggered", OnSlamHitBoxTriggered),
			EventHandler("animover", function(inst)
				inst.sg:GoToState("idle")
			end),
		},

		onexit = function(inst)
			inst.components.offsethitboxes:SetEnabled("offsethitbox", false)
			inst.Physics:Stop()
			inst.Physics:StopPassingThroughObjects()
			inst.components.hitbox:StopRepeatTargetDelay()
			inst.components.attacktracker:CompleteActiveAttack()
		end,
	}),

	State({
		name = "throw",
		tags = { "attack", "busy" },

		onenter = function(inst, target)
			inst.AnimState:PlayAnimation("throw")
			inst.sg.statemem.target = target
			inst.sg.mem.speed = inst.sg.mem.speed or 4
		end,

		timeline =
		{
			FrameEvent(4, function(inst) inst.sg:AddStateTag("airborne") end),
			FrameEvent(6, function(inst) inst.sg:AddStateTag("airborne_high") end),


			--physics
			FrameEvent(4, function(inst) inst.Physics:StartPassingThroughObjects() end),
			FrameEvent(4, function(inst) SGCommon.Fns.SetMotorVelScaled(inst, inst.sg.mem.speed) end),
			--
		},

		events =
		{
			EventHandler("animover", function(inst)
				local facingrot = inst.Transform:GetFacingRotation()
				local rot = inst.Transform:GetRotation()
				local hp = inst.components.health:GetPercent()
				local target = inst.components.combat:GetTarget()
				local rolls = {}

				local diff = ReduceAngle(rot - facingrot)
				diff = math.clamp(diff, -15, 15)
				rot = facingrot + diff

				local top = inst.components.cabbagetower:RemoveTopRoll()

				if top then
					top:TakeControl()
					top.components.cabbagetower:SetSingle()
					SGCommon.Fns.MoveToDist(inst, top, 3)
					top.sg:GoToState("thrown", inst)
					table.insert(rolls, top)
				end

				inst.sg:GoToState("idle")
				inst.components.cabbagetower:SetSingle()
				inst.sg:GoToState("throw_pst", inst.sg.mem.speed)
				table.insert(rolls, inst)

				for _, spawn in ipairs(rolls) do
					spawn.Transform:SetRotation(rot)
					spawn.components.health:SetPercent(hp, true)
					spawn.components.combat:SetTarget(target)
					spawn.components.hitbox:CopyRepeatTargetDelays(inst)
				end
			end),
		},

		onexit = function(inst)
			inst.Physics:Stop()
			inst.Physics:StopPassingThroughObjects()
			inst.components.attacktracker:CompleteActiveAttack()
		end,
	}),

	-- double combine reveal
	State({
		name = "combine2", -- TODO: previously "combine" but conflicts with single combine
		tags = { "busy" },

		onenter = function(inst)
			inst.AnimState:PlayAnimation("cabbageroll2_combine")
		end,

		timeline =
		{
			--physics
			FrameEvent(2, function(inst) inst.Physics:MoveRelFacing(20 / 150) end),
			--

			FrameEvent(8, function(inst)
				inst.sg:AddStateTag("caninterrupt")
			end),
			FrameEvent(10, function(inst)
				inst.sg:RemoveStateTag("busy")
			end),
		},

		events =
		{
			EventHandler("animover", function(inst)
				inst.sg:GoToState("idle")
			end),
		},
	}),	

	-- triple attacks
	State({
		name = "smash",
		tags = { "attack", "busy" },

		onenter = function(inst)
			inst.AnimState:PlayAnimation("smash")
		end,

		timeline =
		{
			-- Forward Strike

			FrameEvent(8, function(inst)
				inst.components.offsethitboxes:SetEnabled("offsethitbox", true)
				inst.components.offsethitboxes:Move("offsethitbox", 2.1)
			end),
			FrameEvent(9, function(inst)
				inst.sg.statemem.backpush = false
				inst.components.hitbox:StopRepeatTargetDelay()
				inst.components.hitbox:StartRepeatTargetDelay()
				local length = inst:HasTag("elite") and 6.4 or 6.1
				inst.components.hitbox:PushBeam(1, length, 1, HitPriority.MOB_DEFAULT)
				inst.components.offsethitboxes:Move("offsethitbox", 2.5)
			end),
			FrameEvent(10, function(inst)
				local length = inst:HasTag("elite") and 6.4 or 6.1
				inst.components.hitbox:PushBeam(1, length, 1, HitPriority.MOB_DEFAULT)
			end),
			FrameEvent(11, function(inst)
				local length = inst:HasTag("elite") and 6.4 or 6.1
				inst.components.hitbox:PushBeam(1, length, 1, HitPriority.MOB_DEFAULT)
			end),

			-- Backward Strike

			FrameEvent(15, function(inst)
				inst.sg:AddStateTag("knockback_becomes_knockdown")
			end),
			FrameEvent(18, function(inst) inst.components.offsethitboxes:Move("offsethitbox", 0) end),
			FrameEvent(20, function(inst) inst.components.offsethitboxes:Move("offsethitbox", -2.2) end),
			FrameEvent(22, function(inst) inst.components.offsethitboxes:Move("offsethitbox", -2.3) end),

			FrameEvent(21, function(inst)
				inst.sg.statemem.backhit = true
				inst.components.hitbox:StopRepeatTargetDelay()
				inst.components.hitbox:StartRepeatTargetDelay()
				local length = inst:HasTag("elite") and -6.0 or -5.5
				inst.components.hitbox:PushBeam(0, length, 1, HitPriority.MOB_DEFAULT)
			end),
			FrameEvent(22, function(inst)
				local length = inst:HasTag("elite") and -6.0 or -5.5
				inst.components.hitbox:PushBeam(0, length, 1, HitPriority.MOB_DEFAULT)
			end),
			FrameEvent(23, function(inst)
				local length = inst:HasTag("elite") and -6.0 or -5.5
				inst.components.hitbox:PushBeam(0, length, 1, HitPriority.MOB_DEFAULT)
			end),

			FrameEvent(32, function(inst) inst.components.offsethitboxes:SetEnabled("offsethitbox", false) end),
			FrameEvent(44, function(inst)
				inst.components.attacktracker:CompleteActiveAttack()
				inst.sg:AddStateTag("caninterrupt")
			end),
			FrameEvent(56, function(inst)
				inst.sg:RemoveStateTag("busy")
			end),
		},

		events =
		{
			EventHandler("hitboxtriggered", OnSmashHitBoxTriggered),
			EventHandler("animover", function(inst)
				inst.sg:GoToState("idle")
			end),
		},

		onexit = function(inst)
			inst.components.offsethitboxes:SetEnabled("offsethitbox", false)
			inst.components.hitbox:StopRepeatTargetDelay()
			inst.components.attacktracker:CompleteActiveAttack()
		end,
	}),

	State({
		name = "bodyslam",
		tags = { "attack", "busy" },

		onenter = function(inst, target)
			inst.AnimState:PlayAnimation("bodyslam")
			inst.sg.statemem.target = target
			local jump_time = 18/30 -- # of frames in the air / frames in a second
			local jump_dist = 5 -- desired distance for jump to travel
			if target ~= nil and target:IsValid() then
				local facingrot = inst.Transform:GetFacingRotation()
				local dir = inst:GetAngleTo(target)
				local diff = ReduceAngle(dir - facingrot)
				if math.abs(diff) > 90 then
					jump_dist = 3 -- desired distance for jump to travel
					inst.sg.statemem.jump_speed = jump_dist/jump_time
				else
					diff = math.clamp(diff, -60, 60)
					inst.Transform:SetRotation(facingrot + diff)

					local dist = math.sqrt(inst:GetDistanceSqTo(target))
					inst.sg.statemem.speedmult = math.clamp(dist / (64 / 30), .5, 2.5)

					jump_dist = math.min(jump_dist, dist) -- desired distance for jump to travel
					inst.sg.statemem.jump_speed = jump_dist/jump_time
				end
			else
				inst.sg.statemem.jump_speed = jump_dist/jump_time
			end
		end,

		timeline =
		{

			FrameEvent(2, function(inst) SGCommon.Fns.SetMotorVelScaled(inst, inst.sg.statemem.jump_speed) end),

			FrameEvent(2, function(inst)
				inst.sg:AddStateTag("airborne")
				inst.Physics:StartPassingThroughObjects()
				inst.components.attacktracker:CompleteActiveAttack()
			end),

			FrameEvent(20, function(inst)
				inst.sg:RemoveStateTag("airborne")
				inst.Physics:StopPassingThroughObjects()
				inst.Physics:Stop()
				inst.components.hitbox:StartRepeatTargetDelay()
				inst.components.hitbox:PushBeam(-2.5, 2.65, 1, HitPriority.MOB_DEFAULT)
			end),

			FrameEvent(21, function(inst)
				inst.components.hitbox:PushBeam(-2.5, 2.65, 1, HitPriority.MOB_DEFAULT)
			end),
		},

		events =
		{
			EventHandler("hitboxtriggered", OnBodySlamHitBoxTriggered),
			EventHandler("animover", function(inst)
				local rot = inst.Transform:GetFacingRotation()
				local hp = inst.components.health:GetPercent()
				local target = inst.components.combat:GetTarget()
				local rolls = {}

				local top = inst.components.cabbagetower:RemoveTopRoll()
				if top then
					top:TakeControl()
					top.components.cabbagetower:SetSingle()
					SGCommon.Fns.MoveToDist(inst, top, 346 / 150)
					top.sg:GoToState("bodyslam_top")
					table.insert(rolls, top)
				end

				local btm = inst.components.cabbagetower:RemoveTopRoll()
				if btm then
					btm:TakeControl()
					btm.components.cabbagetower:SetSingle()
					SGCommon.Fns.MoveToDist(inst, btm, -312 / 150)
					btm.sg:GoToState("bodyslam_btm")
					table.insert(rolls, btm)
				end

				inst.sg:GoToState("idle")
				inst.components.cabbagetower:SetSingle()
				inst.sg:GoToState("bodyslam_mid")

				for _, spawn in ipairs(rolls) do
					spawn.Transform:SetRotation(rot + math.random(-20, 20))
					spawn.components.health:SetPercent(hp, true)
					spawn.components.hitbox:CopyRepeatTargetDelays(inst)
					spawn.components.combat:SetTarget(target)
				end
			end),
		},

		onexit = function(inst)
			inst.Physics:Stop()
			inst.Physics:StopPassingThroughObjects()
			inst.components.hitbox:StopRepeatTargetDelay()
			inst.components.attacktracker:CompleteActiveAttack()
		end,
	}),

	-- triple combine reveal
	State({
		name = "combine3",
		tags = { "busy" },

		onenter = function(inst)
			inst.AnimState:PlayAnimation("cabbageroll3_combine3")
		end,

		timeline =
		{
			--physics
			FrameEvent(16, function(inst) inst.Physics:MoveRelFacing(20 / 150) end),
			--

			FrameEvent(21, function(inst)
				inst.sg:AddStateTag("caninterrupt")
			end),
			FrameEvent(27, function(inst)
				inst.sg:RemoveStateTag("busy")
			end),
		},

		events =
		{
			EventHandler("animover", function(inst)
				inst.sg:GoToState("idle")
			end),
		},
	}),

	-- double knockdown (break apart)
	State({
		name = "knockdown2",
		tags = { "hit", "knockdown", "busy", "nointerrupt" },

		onenter = function(inst, data)
			inst.AnimState:PlayAnimation("cabbageroll2_knockdown")
			local timeout_animframes = data and data.attack:GetHitstunAnimFrames() or 5
			inst.sg:SetTimeoutAnimFrames(timeout_animframes)
			if inst.components.hitshudder then
				inst.components.hitshudder:DoShudder(TUNING.HITSHUDDER_AMOUNT_HEAVY, timeout_animframes)
			end
		end,

		ontimeout = function(inst)
			inst.sg:GoToState("idle")
		end,

		onexit = function(inst)
			local x, z = inst.Transform:GetWorldXZ()
			local rot = inst.Transform:GetFacingRotation()
			local target = inst.components.combat:GetTarget()
			local hp = inst.components.health:GetPercent()
			hp = math.max(0.01, hp)

			local animframes = inst.components.timer:GetAnimFramesRemaining("knockdown") or 0
			local paused = inst.components.timer:IsPaused("knockdown")

			local mid = inst.components.cabbagetower:RemoveTopRoll()
			if mid then
				mid:TakeControl()
				mid.components.cabbagetower:SetSingle()
				mid.sg:GoToState("knockdown_mid")
				mid.Transform:SetPosition(x, 0, z)
				mid.Transform:SetRotation(rot + math.random(-20, 20))
				mid.components.health:SetPercent(hp, true)
				mid.components.combat:SetTarget(target)

				mid.components.timer:StartTimerAnimFrames("knockdown", animframes + math.random(3, 8))
				if paused then
					mid.components.timer:PauseTimer("knockdown")
				end

				mid.Network:FlushAllHistory()
			end

			local tower_sg = inst.sg
			inst.components.cabbagetower:SetSingle()
			-- not the case with uber roll
			-- at this point, inst.sg is now sg_cabbageroll, NOT sg_cabbagerolls!
			-- assert(tower_sg.retired and tower_sg ~= inst.sg)

			inst.sg:GoToState("knockdown_btm")
			inst.components.health:SetPercent(hp, true)

			inst.components.timer:StartTimerAnimFrames("knockdown", animframes + math.random(3, 8))
			if paused then
				inst.components.timer:PauseTimer("knockdown")
			end
		end,
	}),

	-- triple knockdown (break apart)
	State({
		name = "knockdown3",
		tags = { "hit", "knockdown", "busy", "nointerrupt" },

		onenter = function(inst, data)
			inst.AnimState:PlayAnimation("cabbageroll3_knockdown")
			local timeout_animframes = data and data.attack:GetHitstunAnimFrames() or 5
			inst.sg:SetTimeoutAnimFrames(timeout_animframes)
			if inst.components.hitshudder then
				inst.components.hitshudder:DoShudder(TUNING.HITSHUDDER_AMOUNT_HEAVY, timeout_animframes)
			end
		end,

		ontimeout = function(inst)
			inst.sg:GoToState("idle")
		end,

		onexit = function(inst)
			local x, z = inst.Transform:GetWorldXZ()
			local rot = inst.Transform:GetFacingRotation()
			local target = inst.components.combat:GetTarget()
			local hp = inst.components.health:GetPercent()
			hp = math.max(0.01, hp)

			local rolls = {}
			local animframes = inst.components.timer:GetAnimFramesRemaining("knockdown") or 0
			-- Top Roll

			local top = inst.components.cabbagetower:RemoveTopRoll()
			if top then
				top:TakeControl()
				top.components.cabbagetower:SetSingle()
				top.sg:GoToState("knockdown_top")
				table.insert(rolls, top)
			end

			local mid = inst.components.cabbagetower:RemoveTopRoll()
			if mid then
				mid:TakeControl()
				mid.components.cabbagetower:SetSingle()
				mid.sg:GoToState("knockdown_mid")
				table.insert(rolls, mid)
			end

			for _, spawn in ipairs(rolls) do
				spawn.Transform:SetPosition(x, 0, z)
				spawn.Transform:SetRotation(rot + math.random(-20, 20))
				spawn.components.health:SetPercent(hp, true)
				spawn.components.combat:SetTarget(target)
				spawn.components.timer:StartTimerAnimFrames("knockdown", animframes + math.random(3, 8), true)
				spawn.Network:FlushAllHistory()
			end

			inst.components.cabbagetower:SetSingle()
			inst.sg:GoToState("knockdown_btm")
			inst.components.health:SetPercent(hp, true)
		end,
	}),
}

-- single attacks
SGCommon.States.AddAttackPre(states, "bite")
SGCommon.States.AddAttackHold(states, "bite")
SGCommon.States.AddAttackPre(states, "roll")
SGCommon.States.AddAttackHold(states, "roll")
SGCommon.States.AddAttackPre(states, "elite_roll")
SGCommon.States.AddAttackHold(states, "elite_roll")

-- double attacks
SGCommon.States.AddAttackPre(states, "slam")
SGCommon.States.AddAttackHold(states, "slam")
SGCommon.States.AddAttackPre(states, "throw",
{
	timeline =
	{
		FrameEvent(1, function(inst) inst.Physics:MoveRelFacing(10 / 150) end),
		FrameEvent(4, function(inst)
			inst.sg.mem.speed = 4
			local target = inst.sg.statemem.target
			if target ~= nil and target:IsValid() then
				local x, z = inst.Transform:GetWorldXZ()
				local x1, z1 = target.Transform:GetWorldXZ()
				if x1 > x then
					x1 = math.max(x, x1 - target.HitBox:GetSize() - 1)
				else
					x1 = math.min(x, x1 + target.HitBox:GetSize() + 1)
				end
				local dir = inst:GetAngleToXZ(x1, z1)
				local facingrot = inst.Transform:GetFacingRotation()
				if DiffAngle(dir, facingrot) < 90 then
					inst.Transform:SetRotation(dir)

					--constant speed over 14 frames
					local dist = math.sqrt(DistSq2D(x, z, x1, z1))
					inst.sg.mem.speed = math.min(6, dist / 14 * 30)
				end
			else
				inst.sg.statemem.target = nil
			end
		end),
		FrameEvent(4, function(inst) inst.Physics:MoveRelFacing(20 / 150) end),
		FrameEvent(4, function(inst) SGCommon.Fns.SetMotorVelScaled(inst, inst.sg.mem.speed) end),
		--
	},
	onexit_fn = function(inst)
		inst.Physics:Stop()
	end,
})
SGCommon.States.AddAttackHold(states, "throw")

-- triple attacks
SGCommon.States.AddAttackPre(states, "smash")
SGCommon.States.AddAttackHold(states, "smash")
SGCommon.States.AddAttackPre(states, "bodyslam")
SGCommon.States.AddAttackHold(states, "bodyslam")

SGCommon.States.AddHitStates(states, SGCommon.Fns.ChooseAttack,
{
	modifyanim = ModifyAnim,
})

-- double and triple have bespoke idle states with a lot of overlap
-- and one extra onupdate hack that can hopefully go away...
SGCommon.States.AddIdleStates(states,
{
	modifyanim = ModifyAnim,
})

SGCommon.States.AddKnockbackStates(states,
{
	ignore_default_timeline = true,
	modifyanim = ModifyAnim,
	-- movement_frames = 9 -- 9 for cabbageroll, 13 for towers
	movement_fn = function(inst)
		return (inst.components.cabbagetower:GetMode() == 1) and 9 or 13
	end,
	knockback_pst_timeline =
	{
		-- stop moving backwards, dependent on tower type
		FrameEvent(9, function(inst)
			if inst.components.cabbagetower:GetMode() == 1 then
				inst.Physics:Stop()
			end
		end),
		FrameEvent(13, function(inst)
			if inst.components.cabbagetower:GetMode() > 1 then
				inst.Physics:Stop()
			end
		end),
	},

})

-- towers use special knockdown functions to break them apart
-- default knockdown implementation is used for singles
SGCommon.States.AddKnockdownStates(states,
{
	chooser_fn = function(inst, _data)
		if inst.components.cabbagetower:GetMode() == 2 then
			return "knockdown2"
		elseif inst.components.cabbagetower:GetMode() == 3 then
			return "knockdown3"
		end
		return -- nil return to continue executing default knockdown state
	end,

	movement_frames = 18,
	knockdown_pre_timeline =
	{
		FrameEvent(0, function(inst)
			inst.Physics:StartPassingThroughObjects()
			SGCommon.Fns.StartJumpingOverHoles(inst)
		end),
		FrameEvent(16, function(inst)
			inst.Physics:StopPassingThroughObjects()
			SGCommon.Fns.StopJumpingOverHoles(inst)
		end),
	},

	knockdown_pre_onexit = function(inst)
		inst.Physics:StopPassingThroughObjects()
	end,

	knockdown_getup_timeline =
	{
		FrameEvent(2, function(inst) SGCommon.Fns.SetMotorVelScaled(inst, 6, SGCommon.SGSpeedScale.LIGHT) end),
		FrameEvent(4, function(inst) SGCommon.Fns.SetMotorVelScaled(inst, 5, SGCommon.SGSpeedScale.LIGHT) end),
		FrameEvent(6, function(inst) SGCommon.Fns.SetMotorVelScaled(inst, 4, SGCommon.SGSpeedScale.LIGHT) end),
		FrameEvent(9, function(inst) SGCommon.Fns.SetMotorVelScaled(inst, 3, SGCommon.SGSpeedScale.LIGHT) end),
		FrameEvent(11, function(inst) SGCommon.Fns.SetMotorVelScaled(inst, 2, SGCommon.SGSpeedScale.LIGHT) end),
		FrameEvent(13, function(inst) SGCommon.Fns.SetMotorVelScaled(inst, 1, SGCommon.SGSpeedScale.LIGHT) end),
		FrameEvent(14, function(inst) inst.Physics:Stop() end),
		FrameEvent(18, function(inst) inst.Physics:MoveRelFacing(-24 / 150) end),
		--

		FrameEvent(2, function(inst)
			inst.sg:RemoveStateTag("knockdown")
			inst.sg:AddStateTag("airborne")
			inst.sg:AddStateTag("nointerrupt")
		end),
		FrameEvent(11, function(inst)
			inst.sg:RemoveStateTag("nointerrupt")
		end),
		FrameEvent(14, function(inst)
			inst.sg:RemoveStateTag("airborne")
		end),
		FrameEvent(20, function(inst)
			inst.sg:AddStateTag("caninterrupt")
		end),
	},	
})

SGCommon.States.AddKnockdownHitStates(states,
{
	hit_pst_busy_frames = 8,
})

SGCommon.States.AddSpawnBattlefieldStates(states,
{
	chooser_fn = function(inst)
		if inst.components.cabbagetower:GetMode() == 1 then
			return "spawn_battlefield_1"
		elseif inst.components.cabbagetower:GetMode() == 2 then
			return "spawn_battlefield_2"
		elseif inst.components.cabbagetower:GetMode() == 3 then
			return "spawn_battlefield_3"
		else
			dbassert(false)
			return "idle"
		end
	end,

	choices =
	{
		spawn_battlefield_1 =
		{
			anim = "spawn",

			fadeduration = 0.5,
			fadedelay = 0.1,

			timeline =
			{
				FrameEvent(1, function(inst) inst.Physics:SetMotorVel(10) end),
				FrameEvent(5, function(inst) inst.Physics:SetMotorVel(5) end),
				FrameEvent(8, function(inst) inst.Physics:SetMotorVel(4) end),
				FrameEvent(9, function(inst) inst.Physics:SetMotorVel(3) end),
				FrameEvent(10, function(inst) inst.Physics:SetMotorVel(2) end),
				FrameEvent(11, function(inst) inst.Physics:SetMotorVel(1) end),
				FrameEvent(12, function(inst) inst.Physics:SetMotorVel(.5) end),
				FrameEvent(16, function(inst) inst.Physics:Stop() end),
				--
				FrameEvent(16, function(inst)
					inst.sg:RemoveStateTag("airborne")
				end),
				FrameEvent(16, function(inst)
					inst.sg:AddStateTag("caninterrupt")
				end),
				FrameEvent(27, function(inst)
					inst.sg:RemoveStateTag("busy")
				end),

				FrameEvent(2, function(inst) inst:PushEvent("leave_spawner") end),
			},
			onexit_fn = function(inst)
				inst.Physics:Stop()
			end,
		},

		spawn_battlefield_2 =
		{
			anim = "cabbageroll2_spawn2",

			fadeduration = 0.2,
			fadedelay = 0.1,

			timeline =
			{
				FrameEvent(0, function(inst) inst.sg:RemoveStateTag("nointerrupt") end),
				FrameEvent(0, function(inst) SGCommon.Fns.SetMotorVelScaled(inst, 5) end),
				FrameEvent(16, function(inst) inst.Physics:Stop() end),

				FrameEvent(2, function(inst) inst:PushEvent("leave_spawner") end),

				FrameEvent(27, function(inst) inst.sg:RemoveStateTag("busy") end),
			},
		},

		spawn_battlefield_3 =
		{
			anim = "cabbageroll3_spawn3",

			fadeduration = 0.5,
			fadedelay = 0.1,

			timeline =
			{
				FrameEvent(0, function(inst) inst.sg:RemoveStateTag("nointerrupt") end),
				FrameEvent(0, function(inst) SGCommon.Fns.SetMotorVelScaled(inst, 5) end),
				FrameEvent(16, function(inst) inst.Physics:Stop() end),

				FrameEvent(2, function(inst) inst:PushEvent("leave_spawner") end),

				FrameEvent(49, function(inst) inst.sg:RemoveStateTag("busy") end),
			},
		},
	},
})

SGCommon.States.AddWalkStates(states,
{
	modifyanim = ModifyAnim,
	-- modifyaltmode = true,
	onenterpre = function(inst) inst.Physics:Stop() end,
	pretimeline =
	{
		FrameEvent(1, function(inst) 
			if inst.components.cabbagetower:GetMode() == 1 then
				inst.Physics:SetMotorVel(inst.components.locomotor:GetWalkSpeed())
			end
		end),
		FrameEvent(2, function(inst)
			if inst.components.cabbagetower:GetMode() > 1 then
				inst.Physics:SetMotorVel(inst.components.locomotor:GetWalkSpeed())
			end
		end),

	},

	onenterturnpre = function(inst) inst.Physics:Stop() end,
	onenterturnpst = function(inst) inst.Physics:Stop() end,
	turnpsttimeline =
	{
		FrameEvent(1, function(inst) inst.Physics:SetMotorVel(inst.components.locomotor:GetWalkSpeed()) end),
		FrameEvent(4, function(inst)
			inst.sg:RemoveStateTag("busy") -- TODO: only for mode 1 and 2??
		end),
	},
})

SGCommon.States.AddTurnStates(states, {
	modifyanim = ModifyAnim,
	onenterpre = function(inst)
		if inst.components.cabbagetower:GetMode() < 3 then
			inst.sg:AddStateTag("cancombine")
		end
	end,
	onenterpst = function(inst)
		if inst.components.cabbagetower:GetMode() < 3 then
			inst.sg:AddStateTag("cancombine")
		end
	end,
})

SGCommon.States.AddMonsterDeathStates(states)
SGRegistry:AddData("sg_cabbageroll", states)

local fns =
{
	OnResumeFromRemote = function(sg)
		if sg.inst.components.cabbagetower:GetMode() > 1 and
			sg.inst.components.health:GetPercent() <= sg.inst.components.cabbagetower:GetHealthSplitPercentage() then
			TheLog.ch.StateGraph:printf("%s EntityID %d resuming into knockdown due to split",
				sg.inst,
				sg.inst:IsNetworked() and sg.inst.Network:GetEntityID() or -1)
			return "knockdown"
		end
	end,
}

return StateGraph("sg_cabbageroll", states, events, "idle", fns)
