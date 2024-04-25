local SGCommon = require("stategraphs/sg_common")
local monsterutil = require("util.monsterutil")
local particlesystemhelper = require "util.particlesystemhelper"

local function OnDeath(inst, data)
	local fx_params =
	{
		particlefxname = "woworm_shell_shatter",
        offy = 1.4,
		use_entity_facing = true,
        stopatexitstate = true,
	}

    particlesystemhelper.MakeEventSpawnParticles(inst, fx_params)
end

local function ScaleOnVelocity(inst, num)
    return num * (math.abs(inst.Physics:GetVel()) / 16)
end

local function OnShellHitboxTriggered(inst, data)
    local isplayer = false
    for _, target in ipairs(data.targets) do
        if (target:HasTag("player")) then
            isplayer = true
            break
        end
    end
    local dmg = isplayer and 100 * TUNING.TRAPS.DAMAGE_TO_PLAYER_MULTIPLIER or 100
    local elitedmg = isplayer and 180 * TUNING.TRAPS.DAMAGE_TO_PLAYER_MULTIPLIER or 180
	SGCommon.Events.OnHitboxTriggered(inst, data, {
		set_dir_angle_to_target = true,
		damage_override = inst:HasTag("elite") and ScaleOnVelocity(inst, elitedmg) or ScaleOnVelocity(inst, dmg),
		hitstoplevel = inst.sg:HasStateTag("knockdown") and HitStopLevel.MAJOR or HitStopLevel.HEAVIER,
		hitflags = Attack.HitFlags.LOW_ATTACK,
		pushback = inst.sg:HasStateTag("knockdown") and 1.2 or 1,
		combat_attack_fn = inst.sg:HasStateTag("knockdown") and "DoKnockdownAttack" or "DoKnockbackAttack",
		hit_fx = monsterutil.defaultAttackHitFX,
	})
end

local events =
{
    EventHandler("hitboxtriggered", OnShellHitboxTriggered)
}

monsterutil.AddMonsterCommonEvents(events,
{
    no_quick_death_handler = true,
    ondying_data = {
        callback_fn = function(inst)
            inst.sg:ForceGoToState("dying")
        end,
    },
	ondeath_fn = OnDeath,
})

local states =
{
    State({
        name = "dying",
        tags = { "busy", "death" },

        onenter = function(inst)
            inst.AnimState:PlayAnimation("death")
            inst.sg:SetTimeoutAnimFrames(inst.AnimState:GetAnimationNumFrames("death"))
            if (inst.HitBox ~= nil) then
                if (inst.HitBox:IsEnabled()) then
                    inst:PushEvent("done_dying")
                end
                inst.HitBox:SetEnabled(false)
            end
        end,

        ontimeout = function(inst)
            SGCommon.Fns.OnMonsterDying(inst)
            inst:Remove()
        end,
    })
}
SGCommon.States.AddIdleStates(states)
SGCommon.States.AddHitStates(states)
SGCommon.States.AddKnockbackStates(states,
{
    movement_frames = 6,
    onenter_fn = function(inst, data)
        if (not inst:IsAlive()) then
            inst.sg:ForceGoToState("dying")
        end

        -- Inherit the attacker's hit flags, if there is one.
        local attacker = data ~= nil and data.attacker
        inst.sg.mem.preKnockbackHitFlags = inst.components.hitbox:GetHitFlags() -- Save hitflag status to reset later.
        local attackerHitFlags = attacker and attacker.components.hitbox:GetHitFlags() or HitGroup.ALL
        inst.components.hitbox:SetHitFlags(attackerHitFlags)

        inst.components.hitbox:StartRepeatTargetDelay()
    end,
    knockback_pst_frames = 12,
    knockback_pst_onupdate_fn = function(inst)
        inst.components.hitbox:PushBeam(0, -1.5, 1.5, HitPriority.MOB_DEFAULT)
    end,
    knockback_pst_timeline =
    {
        FrameEvent(1, function(inst)
            inst.Physics:StopPassingThroughObjects()
            inst.Physics:SetMotorVel(-inst.sg.statemem.knockback_speed * 0.5)
        end),
        FrameEvent(4, function(inst)
            inst.Physics:SetMotorVel(-inst.sg.statemem.knockback_speed * 0.3)
        end),
        FrameEvent(6, function(inst)
            inst.Physics:SetMotorVel(-inst.sg.statemem.knockback_speed * 0.2)
        end),
        FrameEvent(7, function(inst)
            inst.Physics:SetMotorVel(-inst.sg.statemem.knockback_speed * 0.1)
        end),
    },
    onexit_pst_fn = function(inst)
        inst.components.hitbox:StopRepeatTargetDelay()
        inst.components.hitbox:SetHitFlags(inst.sg.mem.preKnockdownHitFlags or HitGroup.ALL)
    end,
})
SGCommon.States.AddKnockdownStates(states,
{
    movement_frames = 17,
    onenter_hold_fn = function(inst, data)
        -- Inherit the attacker's hit flags, if there is one.
        local attacker = data ~= nil and data.attacker
        inst.sg.mem.preKnockdownHitFlags = inst.components.hitbox:GetHitFlags() -- Save hitflag status to reset later.
        local attackerHitFlags = attacker and attacker.components.hitbox:GetHitFlags() or HitGroup.ALL
        inst.components.hitbox:SetHitFlags(attackerHitFlags)

        inst.components.hitbox:StartRepeatTargetDelay()
    end,
    onenter_pre_fn = function(inst)
        inst.sg.statemem.getup = true
        inst.components.hitbox:StopRepeatTargetDelay()
        inst.components.hitbox:StartRepeatTargetDelay()
        inst.Physics:StartPassingThroughObjects()
    end,
    onenter_idle_fn = function(inst) inst:PushEvent("getup") end,
    knockdown_pre_onupdate_fn = function(inst)
        inst.components.hitbox:PushBeam(0, -1.5, 1.5, HitPriority.MOB_DEFAULT)
    end,
    onexit_pre_fn = function(inst)
        if (not inst:IsAlive()) then
            inst.Physics:Stop()
            inst.sg:ForceGoToState("dying")
        end
    end,

    knockdown_slide_on_getup = true,
    knockdown_getup_frames = 7,
    onenter_getup_fn = function(inst)
        inst.Physics:StartPassingThroughObjects()
    end,
    knockdown_getup_timeline =
    {
        FrameEvent(0, function(inst)
            inst.Physics:SetMotorVel(-inst.sg.mem.knockdown_speed * 0.5)
            inst.Physics:StopPassingThroughObjects()
        end),
        FrameEvent(3, function(inst)
            inst.Physics:SetMotorVel(-inst.sg.mem.knockdown_speed * 0.3)
        end),
        FrameEvent(5, function(inst)
            inst.Physics:SetMotorVel(-inst.sg.mem.knockdown_speed * 0.2)
        end),
        FrameEvent(6, function(inst)
            inst.Physics:SetMotorVel(-inst.sg.mem.knockdown_speed * 0.1)
        end),
    },
    knockdown_getup_onupdate_fn = function(inst)
        inst.components.hitbox:PushBeam(0, -1.5, 1.5, HitPriority.MOB_DEFAULT)
    end,
    onexit_pst_fn = function(inst)
        inst.components.hitbox:StopRepeatTargetDelay()
        inst.components.hitbox:SetHitFlags(inst.sg.mem.preKnockdownHitFlags or HitGroup.ALL)
    end,
})
SGCommon.States.AddMonsterDeathStates(states)

return StateGraph("sg_woworm_shell", states, events, "idle")
