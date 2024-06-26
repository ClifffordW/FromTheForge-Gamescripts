local SGCommon = require "stategraphs.sg_common"
local SGPlayerCommon = require "stategraphs.sg_player_common"
local fmodtable = require "defs.sound.fmodtable"
local PlayerSkillState = require "playerskillstate"
local combatutil = require "util.combatutil"

local events = {}

local ATTACKS =
{
	SHOVE =
	{
		DMG_NORM = 0.5,
		HITSTUN = 5,
		PB_NORM = 1.5,
		HS_NORM = HitStopLevel.MEDIUM,
		HS_FOCUS = HitStopLevel.MEDIUM,
	}
}

local ON_HIT_DODGE_WINDOW_FRAMES = 5 -- When the shove connects, how many frames can we cancel into a dodge?
local ON_HIT_LIGHTATTACK_WINDOW_FRAMES = 8 -- When the shove connects, how many frames can we cancel into a dodge?
local ON_HIT_HEAVYATTACK_WINDOW_FRAMES = 5 -- When the shove connects, how many frames can we cancel into a dodge?

local function OnShoveHitBoxTriggered(inst, data)
	--TODO(jambell): commonize?
	local ATTACK_DATA = ATTACKS.SHOVE

	local hit = false
	local dir = inst.Transform:GetFacingRotation()
	for i = 1, #data.targets do
		local v = data.targets[i]

		local hitstoplevel = ATTACK_DATA.HS_NORM
		local damage_mod = ATTACK_DATA.DMG_NORM
		local pushback = ATTACK_DATA.PB_NORM
		local hitstun = ATTACK_DATA.HITSTUN

		local attack = Attack(inst, v)
		attack:SetDamageMod(damage_mod)
		attack:SetDir(dir)
		attack:SetPushback(pushback)
		attack:SetHitstunAnimFrames(hitstun)
		attack:SetID(inst.sg.mem.attack_type)

		inst.components.combat:DoKnockdownAttack(attack)

		hitstoplevel = SGCommon.Fns.ApplyHitstop(attack, hitstoplevel)

		local hitfx_x_offset = 1.25
		local hitfx_y_offset = 1.5

		local distance = inst:GetDistanceSqTo(v)
		if distance >= 30 then
			hitfx_x_offset = hitfx_x_offset + 1.5
		elseif distance >= 25 then
			hitfx_x_offset = hitfx_x_offset + 1
		end

		if v.sg ~= nil and v.sg:HasStateTag("block") then
			SpawnHitFx("hits_player_block", inst, v, 0, 0, dir, hitstoplevel)
		else
			SpawnHitFx("hits_player_unarmed", inst, v, hitfx_x_offset, hitfx_y_offset, dir, hitstoplevel) -- replace with .statemem.attackfx, set it per state
		end

		SpawnHurtFx(inst, v, 0, dir, hitstoplevel)
		hit = true
	end

	if hit then
		inst.SoundEmitter:PlaySound(fmodtable.Event.Hit_shove)
		inst.components.playercontroller:OverrideControlQueueTicks("dodge", ON_HIT_DODGE_WINDOW_FRAMES * ANIM_FRAMES)
		inst:DoTaskInAnimFrames(ON_HIT_DODGE_WINDOW_FRAMES, function()
			-- DESIGN: Allow dodge-cancelling if we hit anything, but not immediately.
			if inst.sg:HasStateTag("busy") then -- In case we've gone into a different state
				SGPlayerCommon.Fns.SetCanDodge(inst)
				SGPlayerCommon.Fns.TryQueuedAction(inst, "dodge")
			end
			inst.components.playercontroller:OverrideControlQueueTicks("dodge", nil)
		end)

		inst.components.playercontroller:OverrideControlQueueTicks("lightattack", ON_HIT_LIGHTATTACK_WINDOW_FRAMES * ANIM_FRAMES)
		inst:DoTaskInAnimFrames(ON_HIT_LIGHTATTACK_WINDOW_FRAMES, function()
			-- DESIGN: Allow L-cancelling if we hit anything, but not immediately.
			if inst.sg:HasStateTag("busy") then -- In case we've gone into a different state
				inst.sg.statemem.lightcombostate = "default_light_attack"
				SGPlayerCommon.Fns.TryQueuedAction(inst, "lightattack")
			end
			inst.components.playercontroller:OverrideControlQueueTicks("lightattack", nil)
		end)

		inst.components.playercontroller:OverrideControlQueueTicks("heavyattack", ON_HIT_HEAVYATTACK_WINDOW_FRAMES * ANIM_FRAMES)
		inst:DoTaskInAnimFrames(ON_HIT_HEAVYATTACK_WINDOW_FRAMES, function()
			-- DESIGN: Allow L-cancelling if we hit anything, but not immediately.
			if inst.sg:HasStateTag("busy") then -- In case we've gone into a different state
				inst.sg.statemem.heavycombostate = "default_heavy_attack"
				SGPlayerCommon.Fns.TryQueuedAction(inst, "heavyattack")
			end
			inst.components.playercontroller:OverrideControlQueueTicks("heavyattack", nil)
		end)
	end
end

local states =
{
	PlayerSkillState({
		name = "skill_polearm_shove",
		tags = { "attack", "busy" },

		onenter = function(inst)
			inst:PushEvent("attack_state_start")
			inst.AnimState:PlayAnimation("polearm_shove")
			inst.components.hitbox:StartRepeatTargetDelay()
		end,

		timeline =
		{
			FrameEvent(5, function(inst)
				combatutil.StartMeleeAttack(inst)
				inst.components.hitbox:PushBeam(0, 3, 1, HitPriority.PLAYER_DEFAULT)
				inst.components.hitbox:PushBeam(0.5, 1, 2.5, HitPriority.PLAYER_DEFAULT)
			end),
			FrameEvent(6, function(inst) inst.components.hitbox:PushBeam(0, 3, 1, HitPriority.PLAYER_DEFAULT) end),
			FrameEvent(7, function(inst) inst.components.hitbox:PushBeam(0, 3, 1, HitPriority.PLAYER_DEFAULT) end),

			FrameEvent(7, function(inst)
				combatutil.EndMeleeAttack(inst)
				SGPlayerCommon.Fns.SetCanDodge(inst)
			end),
			FrameEvent(9, function(inst)
				inst.sg.statemem.lightcombostate = "default_light_attack"
				inst.sg.statemem.heavycombostate = "default_heavy_attack"
				SGPlayerCommon.Fns.TryQueuedAction(inst, "lightattack", "heavyattack")
			end),
		},

		events =
		{
			EventHandler("hitboxtriggered", OnShoveHitBoxTriggered),
			EventHandler("animover", function(inst)
				inst.sg:GoToState("idle")
			end),
		},

		onexit = function(inst)
			inst.components.hitbox:StopRepeatTargetDelay()
		end,
	}),
}

return StateGraph("sg_player_polearm_skill_shove", states, events, "skill_polearm_shove")
