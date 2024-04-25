local SGCommon = require "stategraphs.sg_common"
local SGPlayerCommon = require "stategraphs.sg_player_common"
local fmodtable = require "defs.sound.fmodtable"
local PlayerSkillState = require "playerskillstate"
local combatutil = require "util.combatutil"
local soundutil = require "util.soundutil"

local events = {}

local FOCUS_FLASH_DATA_THROWN  = { color = { 0/255, 100/255, 100/255 }, frames = 4 }

local function StartFocusParticles(inst)
	-- The ball itself has a particlesystem on it playing particles, but the ball throw actually doesn't get created here, only faked in the animation.
	-- This attaches a trail to the ball to fake the 'thrown' feeling.

	if inst.sg.mem.focustrail == nil then
		local pfx = SpawnPrefab("shotput_focus_trail", inst)
		pfx.entity:AddFollower()
		pfx.entity:SetParent(inst.entity)
		pfx.Follower:FollowSymbol(inst.GUID, "weapon_back01")
		inst.sg.mem.focustrail = pfx

		inst.sg.mem.focustrail:ListenForEvent("particles_stopcomplete", function()
			inst.sg.mem.focustrail:Remove()
			inst.sg.mem.focustrail = nil
		end)
	end
end

local function StopFocusParticles(inst)
	if inst.sg.mem.focustrail ~= nil then
		inst.sg.mem.focustrail.components.particlesystem:StopAndNotify()
	end
end

local function GetActiveProjectileCount(inst)
	if not inst.sg.mem.active_projectiles then
		return 0
	end

	local count = 0
	for _k,_v in pairs(inst.sg.mem.active_projectiles) do
		count = count + 1
	end
	dbassert(count <= inst.sg.mem.ammo_max, "Why do we have more projectiles than expected?")
	return count
end

local function GetAmmo(inst)
	local ammo = inst.sg.mem.ammo_max - GetActiveProjectileCount(inst)
	return ammo
end

local function HasAmmo(inst)
	return inst.sg.mem.ammo_max - GetActiveProjectileCount(inst) > 0
end

local ATTACKS =
{
	-- Attack damage is tuned the same as reverse heavy attack
	NORMAL =
	{
		DAMAGE = 1,
		HITSTUN = 2,
		PUSHBACK = 0.5,
		HITSTOP = HitStopLevel.LIGHT,
		FOCUS = false,
		COMBAT_FN = "DoKnockbackAttack",
		name_id = "SHOTPUT_SLAM",
	},

	FOCUS =
	{
		DAMAGE = 1.5,
		HITSTUN = 8,
		PUSHBACK = 1.25,
		HITSTOP = HitStopLevel.MEDIUM,
		FOCUS = true,
		COMBAT_FN = "DoKnockbackAttack",
		name_id = "SHOTPUT_SLAM_FOCUS",
	},
}

local function OnSlamHitBoxTriggered(inst, data)
	local attack = inst.sg.statemem.focus and ATTACKS.FOCUS or ATTACKS.NORMAL

	local hitstop = attack.HITSTOP -- used in multiple places below

	local hit = SGCommon.Events.OnHitboxTriggered(inst, data, {
		attack_id = "skill",
		attack_name_id = attack.name_id,
		damage_mod = attack.DAMAGE,
		hitstoplevel = hitstop,
		pushback = attack.PUSHBACK,
		focus_attack = attack.FOCUS,
		hitflags = Attack.HitFlags.GROUND,
		combat_attack_fn = attack.COMBAT_FN,
		spawn_hit_fx_fn = function(attacker, target, attack, xdata)
			local hitfx = "hits_player_jamball_up"
			local x_offset = 0
			local y_offset = 0
			inst.components.combat:SpawnHitFxForPlayerAttack(attack, hitfx, target, inst, x_offset, y_offset, attack:GetDir(), hitstop)
		end,
		set_dir_angle_to_target = true,
	})

	if hit then
		inst:PushEvent("skill_hit")
	end
end

local states =
{
	PlayerSkillState({
		name = "skill_shotput_slam",
		tags = { "busy", "airborne" },

		onenter = function(inst)
			inst.AnimState:PlayAnimation("shotput_skill_slam_pre")
			local ammo = GetAmmo(inst)
			local should_stop_at_exit = ammo == 0
			local full_ammo = ammo == inst.sg.mem.ammo_max
			soundutil.PlayCodeSound(inst, fmodtable.Event.Skill_Shotput_Slam_Jump,
				{
					name = "shotput_slam_jump",
					max_count = 1,
					stopatexitstate = should_stop_at_exit,
					fmodparams =
					{
						shotputAmmo = ammo,
					}
				}
			)
		end,

		timeline =
		{
			FrameEvent(2, function(inst)
				inst.sg:AddStateTag("airborne_high")
			end),
		},

		onexit = function(inst)
		end,

		events =
		{
			EventHandler("animover", function(inst)
				inst.sg:GoToState("skill_shotput_slam_normal")
			end),
		},
	}),

	PlayerSkillState({
		name = "skill_shotput_slam_normal",
		tags = { "attack", "busy", "airborne", "airborne_high" },

		onenter = function(inst, frames)
			inst:PushEvent("attack_state_start")
			inst.AnimState:PlayAnimation("shotput_skill_slam")
			soundutil.PlayCodeSound(inst, fmodtable.Event.Skill_Shotput_Slam_Throw,
				{
					name = "shotput_slam_throw",
					max_count = 1,
					fmodparams = {
						shoutputAmmo = GetAmmo(inst),
					}
				}
			)
			

			inst.components.hitbox:StartRepeatTargetDelay()
			inst.components.playercontroller:OverrideControlQueueTicks("skill", 30)
			inst.components.playercontroller:OverrideControlQueueTicks("heavyattack", 30)
			inst.components.playercontroller:OverrideControlQueueTicks("lightattack", 30)

		end,

		timeline =
		{
			FrameEvent(3, function(inst)
				-- This is the last frame that we'll allow a "catch" and still hit.
				inst.sg.statemem.hadammoatstartofthrow = HasAmmo(inst)
				inst.sg.statemem.ballisthrown = true

				if inst.sg.statemem.hadammoatstartofthrow then
					SGCommon.Fns.PlayGroundImpact(inst, { impact_type = GroundImpactFXTypes.id.ParticleSystem, impact_size = GroundImpactFXSizes.id.Large })

					soundutil.PlayCodeSound(inst, fmodtable.Event.Skill_Shotput_Slam_Bounce, { name = "shotput_slam_bounce", max_count = 1 })
					soundutil.KillSound(inst, "shotput_slam_jump")
					soundutil.KillSound(inst, "shotput_slam_throw")

					combatutil.StartMeleeAttack(inst)
					inst.components.hitbox:PushCircle(0, 0, 1.5, HitPriority.PLAYER_DEFAULT)
					inst.components.hitbox:PushBeam(0, 2.25, 1, HitPriority.PLAYER_DEFAULT)
				end
			 end),

			FrameEvent(4, function(inst)
				if inst.sg.statemem.hadammoatstartofthrow then
					combatutil.EndMeleeAttack(inst)
				end
			 end),

			FrameEvent(11, function(inst)
				inst.sg.statemem.ballisthrown = false
			end),

			FrameEvent(11, function(inst)
				inst.sg.statemem.skillcombostate = "skill_shotput_slam_focus"
				SGPlayerCommon.Fns.TryQueuedAction(inst, "skill")
			end),
			FrameEvent(12, SGPlayerCommon.Fns.SetCanDodge)
		},

		onupdate = function(inst)
			if inst.sg.statemem.ballisthrown and not inst.sg.statemem.hadammoatstartofthrow then
				inst.AnimState:HideSymbol("feature01")
				inst.AnimState:HideSymbol("shadow_untex")
				inst.AnimState:HideSymbol("weapon_back01")
			else
				inst.AnimState:ShowSymbol("feature01")
				inst.AnimState:ShowSymbol("shadow_untex")
				inst.AnimState:ShowSymbol("weapon_back01")
			end
		end,

		onexit = function(inst)
			inst.components.playercontroller:OverrideControlQueueTicks("skill", nil)
			inst.components.playercontroller:OverrideControlQueueTicks("heavyattack", nil)
			inst.components.playercontroller:OverrideControlQueueTicks("lightattack", nil)
			inst.components.hitbox:StopRepeatTargetDelay()

			if HasAmmo(inst) then
				inst.AnimState:ShowSymbol("feature01")
				inst.AnimState:ShowSymbol("shadow_untex")
				inst.AnimState:ShowSymbol("weapon_back01")
			end
		end,

		events =
		{
			EventHandler("hitboxtriggered", OnSlamHitBoxTriggered),
			EventHandler("animover", function(inst)
				inst.sg:GoToState("skill_shotput_slam_pst")
			end),
		},
	}),


	PlayerSkillState({
		name = "skill_shotput_slam_focus",
		tags = { "attack", "busy", "airborne", "airborne_high" },

		onenter = function(inst, frames)
			inst:PushEvent("attack_state_start")
			inst.AnimState:PlayAnimation("shotput_skill_slam")
			inst.sg.statemem.focus = true

			inst.sg.statemem.hasammo = HasAmmo(inst)

			inst.components.hitbox:StartRepeatTargetDelay()

			if inst.sg.statemem.hasammo then
				SGCommon.Fns.BlinkAndFadeColor(inst, FOCUS_FLASH_DATA_THROWN.color, FOCUS_FLASH_DATA_THROWN.frames)
				StartFocusParticles(inst)
			end

			inst.components.playercontroller:OverrideControlQueueTicks("skill", 30)
			inst.components.playercontroller:OverrideControlQueueTicks("heavyattack", 30)
			inst.components.playercontroller:OverrideControlQueueTicks("lightattack", 30)

			if GetAmmo(inst) > 0 then
				soundutil.PlayCodeSound(inst, fmodtable.Event.Skill_Shotput_Slam_Throw,
					{
						name = "shotput_slam_throw",
						max_count = 1,
						fmodparams = {
							isFocusAttack = 1,
							shotputAmmo = GetAmmo(inst),
						}
					}
				)
				soundutil.KillSound(inst, "shotput_slam_bounce")
			else
				soundutil.PlayCodeSound(inst, fmodtable.Event.Skill_Shotput_Slam_Throw,
					{
						name = "shotput_slam_throw",
						max_count = 1,
						fmodparams = {
							shotputAmmo = GetAmmo(inst),
						}
					}
				)
			end
		end,

		timeline =
		{
			FrameEvent(3, function(inst)
				inst.sg.statemem.hadammoatstartofthrow = HasAmmo(inst)
				inst.sg.statemem.ballisthrown = true

				if inst.sg.statemem.hadammoatstartofthrow then
					SGCommon.Fns.PlayGroundImpact(inst, { impact_type = GroundImpactFXTypes.id.ParticleSystem, impact_size = GroundImpactFXSizes.id.Large })

					combatutil.StartMeleeAttack(inst)
					inst.components.hitbox:PushCircle(0, 0, 1.65, HitPriority.PLAYER_DEFAULT)
					inst.components.hitbox:PushBeam(-0.5, 2.4, 1.25, HitPriority.PLAYER_DEFAULT)
				end
			 end),

			FrameEvent(5, function(inst)
				if inst.sg.statemem.hadammoatstartofthrow then
					soundutil.PlayCodeSound(inst, fmodtable.Event.Skill_Shotput_Slam_Bounce,
						{
							name = "shotput_slam_bounce",
							max_count = 1,
							fmodparams = {
								isFocusAttack = 1,
							}
						})
					soundutil.KillSound(inst, "shotput_slam_jump")
					soundutil.KillSound(inst, "shotput_slam_throw")
					combatutil.EndMeleeAttack(inst)
				end
			 end),

			FrameEvent(10, function(inst)
				if inst.sg.statemem.hadammoatstartofthrow then
					StopFocusParticles(inst)
				end
			end),

			FrameEvent(12, SGPlayerCommon.Fns.SetCanDodge)
		},

		onupdate = function(inst)
			if inst.sg.statemem.ballisthrown and not inst.sg.statemem.hadammoatstartofthrow then
				inst.AnimState:HideSymbol("feature01")
				inst.AnimState:HideSymbol("shadow_untex")
				inst.AnimState:HideSymbol("weapon_back01")
			else
				inst.AnimState:ShowSymbol("feature01")
				inst.AnimState:ShowSymbol("shadow_untex")
				inst.AnimState:ShowSymbol("weapon_back01")
			end
		end,

		onexit = function(inst)
			inst.components.playercontroller:OverrideControlQueueTicks("skill", nil)
			inst.components.playercontroller:OverrideControlQueueTicks("heavyattack", nil)
			inst.components.playercontroller:OverrideControlQueueTicks("lightattack", nil)
			inst.components.hitbox:StopRepeatTargetDelay()

			if HasAmmo(inst) then
				inst.AnimState:ShowSymbol("feature01")
				inst.AnimState:ShowSymbol("shadow_untex")
				inst.AnimState:ShowSymbol("weapon_back01")
			end
		end,

		events =
		{
			EventHandler("hitboxtriggered", OnSlamHitBoxTriggered),
			EventHandler("animover", function(inst)
				inst.sg:GoToState("skill_shotput_slam_pst")
			end),
		},
	}),

	PlayerSkillState({
		name = "skill_shotput_slam_pst",
		tags = { "busy", "airborne" },

		onenter = function(inst, chargetier)
			inst.AnimState:PlayAnimation("shotput_skill_slam_pst")
		end,

		timeline =
		{
			FrameEvent(2, function(inst)
				inst.sg:RemoveStateTag("airborne")
			end),

			FrameEvent(3, SGPlayerCommon.Fns.SetCanDodge),
			FrameEvent(5, SGPlayerCommon.Fns.SetCanAttackOrAbility),

			FrameEvent(11, SGPlayerCommon.Fns.RemoveBusyState),
		},

		events =
		{
			EventHandler("animover", function(inst)
				inst.sg:GoToState("idle")
			end),
		},
	}),
}

return StateGraph("sg_player_shotput_skill_slam", states, events, "skill_shotput_slam")
