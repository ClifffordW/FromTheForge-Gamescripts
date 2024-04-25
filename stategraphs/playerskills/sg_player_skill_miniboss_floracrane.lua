local SGPlayerCommon = require "stategraphs.sg_player_common"
local SGCommon = require "stategraphs.sg_common"
local fmodtable = require "defs.sound.fmodtable"
local PlayerSkillState = require "playerskillstate"
local soundutil = require "util.soundutil"
local fmodtable = require "defs.sound.fmodtable"

local events = {}

local attack_data =
{
	-- These are split out mainly because of the hitflags + fx offset.
	HIGH =
	{
		HITFLAGS = Attack.HitFlags.AIR_HIGH,
		DAMAGE = 2,
		HITSTUN = 2,
		PUSHBACK = 1,
		HITSTOP = HitStopLevel.MEDIUM,
		COMBAT_FN = "DoKnockbackAttack",
		HIT_FX = "hits_player_skill",
		HIT_FX_OFFSET_Y = 4,
	},
	MID =
	{
		HITFLAGS = Attack.HitFlags.DEFAULT,
		DAMAGE = 2,
		HITSTUN = 2,
		PUSHBACK = 1.25,
		HITSTOP = HitStopLevel.MEDIUM,
		RADIUS = 3.25,
		COMBAT_FN = "DoKnockbackAttack",
		HIT_FX = "hits_player_skill",
		HIT_FX_OFFSET_Y = 2,
	},

	-- Only for fully charged focus attack.
	AOE =
	{
		HITFLAGS = Attack.HitFlags.GROUND,
		DAMAGE = 4,
		HITSTUN = 12,
		PUSHBACK = 1.5,
		HITSTOP = HitStopLevel.MAJOR,
		COMBAT_FN = "DoKnockdownAttack",
		HIT_FX = "hits_fire",
		HIT_FX_OFFSET_Y = 1.5,
	},
}

local function OnBodyHitBoxTriggered(inst, data)

	-- This function is NEVER a focus hit. This is just for the body hitting.

	local attack = attack_data[inst.sg.statemem.attack]
	local focushit = inst.sg.statemem.focus

	local damage_mod = attack.DAMAGE

	local hit = SGCommon.Events.OnHitboxTriggered(inst, data, {
		attack_id = "skill",
		damage_mod = damage_mod,
		hitstoplevel = attack.HITSTOP,
		pushback = attack.PUSHBACK,
		focus_attack = focushit,
		hitflags = attack.HITFLAGS,
		combat_attack_fn = "DoKnockbackAttack",
		hit_fx = attack.HIT_FX,
		disable_self_hitstop = true,
		hit_fx_offset_y = attack.HIT_FX_OFFSET_Y,
		set_dir_angle_to_target = true,
	})

	if hit then
		inst:PushEvent("skill_hit")
	end
end

local function OnAOEHitBoxTriggered(inst, data)
	local attack = attack_data.AOE

	local hit = SGCommon.Events.OnHitboxTriggered(inst, data, {
		attack_id = "skill",
		damage_mod = attack.DAMAGE,
		hitstoplevel = attack.HITSTOP,
		pushback = attack.PUSHBACK,
		focus_attack = true,
		hitflags = attack.HITFLAGS,
		combat_attack_fn = "DoKnockdownAttack",
		hit_fx = attack.HIT_FX,
		-- hit_fx_offset_x = 0,
		disable_self_hitstop = true,
		hit_fx_offset_y = attack.HIT_FX_OFFSET_Y,
		set_dir_angle_to_target = true,
	})

	if hit then
		inst:PushEvent("skill_hit")
	end
end

local states =
{
	PlayerSkillState({
		name = "skill_miniboss_floracrane",
		tags = { "busy" },
		onenter = function(inst)
			inst.AnimState:PlayAnimation("skill_flora_dive_pre")
			if not inst.components.playercontroller:IsControlHeld("skill") then
				inst.sg.statemem.mustexit = true
			end

			-- sound cleanup
			inst.sg.mem.roar_sound = nil
		end,

		timeline =
		{
			FrameEvent(1, function(inst) inst.sg.mem.jump_sound = soundutil.PlayCodeSound(inst, fmodtable.Event.Skill_Floracrane_Jump,{ max_count = 1 }) end),
			FrameEvent(1, function(inst)
				-- this used to be Skill_Floracrane_Charge_LP but we're not reaaaally looping for very long here and it was causing issues
				-- so I don't assign a handle to it anymore and instead just fire a one-shot. Code for exiting the loop does still exist for later
				soundutil.PlayCodeSound(inst, fmodtable.Event.Skill_Floracrane_Charge,
				{
					max_count = 1,
					is_autostop = true,
					stopatexitstate = true,
					fmodparams = {
						skill_chargeLevel = 0,
					}
				})
			end),
			FrameEvent(3, function(inst)
				inst.sg:AddStateTag("airborne")
				inst.Physics:StartPassingThroughObjects()
			end),
			FrameEvent(4, function(inst) inst.sg:AddStateTag("airborne_high") end),
			FrameEvent(4, function(inst)
				inst.sg.mem.roar_sound = soundutil.PlayCodeSound(inst, fmodtable.Event.Skill_Floracrane_Jump_Roar)
			end),

			FrameEvent(16, function(inst)
				if inst.sg.statemem.mustexit or not inst.components.playercontroller:IsControlHeld("skill") then
					if inst.sg.mem.roar_sound then
						soundutil.KillSound(inst, inst.sg.mem.roar_sound)
						inst.sg.mem.roar_sound = nil
					end
					inst.sg:GoToState("skill_miniboss_floracrane_dive", false)
				end

				inst.sg.statemem.canexit = true
			end),
		},

		onupdate = function(inst)
			if not inst.components.playercontroller:IsControlHeld("skill") then
				if inst.sg.statemem.canexit then
					inst.sg:GoToState("skill_miniboss_floracrane_dive", false)
				end
				inst.sg.statemem.mustexit = true
			end
		end,

		onexit = function(inst)
			SGPlayerCommon.Fns.SafeStopPassingThroughObjects(inst)
			if inst.sg.mem.charge_lp_sound then
				soundutil.KillSound(inst, inst.sg.mem.charge_lp_sound)
				inst.sg.mem.charge_lp_sound = nil
			end
		end,

		events =
		{
			EventHandler("controlupevent", function(inst, data)
				if data.control == "skill" then
					if inst.sg.statemem.canexit then
						-- This is after frame 10, so let's exit now
						inst.sg:GoToState("skill_miniboss_floracrane_dive", false)
					else
						-- If the player has released SKILL before frame 15, then set a flag so that once we hit frame 15 we MUST exit.
						inst.sg.statemem.mustexit = true
					end
				end
			end),
			EventHandler("animover", function(inst)
				if inst.sg.statemem.mustexit then
					inst.sg:GoToState("skill_miniboss_floracrane_dive", false)
				else
					if inst.sg.mem.charge_lp_sound then
						soundutil.SetInstanceParameter(inst, inst.sg.mem.charge_lp_sound, "skill_chargeLevel", 1)
					end
					inst.sg:GoToState("skill_miniboss_floracrane_hold")
				end
			end),
		},
	}),

	PlayerSkillState({
		name = "skill_miniboss_floracrane_hold",
		tags = { "busy", "airborne", "airborne_high" },

		onenter = function(inst, loops)
			inst.AnimState:PlayAnimation("skill_flora_dive_hold")
			if inst.sg.mem.roar_sound then
				soundutil.SetInstanceParameter(inst, inst.sg.mem.roar_sound, "skill_chargeLevel", 1)
				inst.sg.mem.roar_sound = nil -- stop tracking
			end
		end,

		timeline =
		{
			FrameEvent(1, function(inst)
				soundutil.PlayCodeSound(inst, fmodtable.Event.Skill_Floracrane_Charged,
				{
					max_count = 1,
				})
			end),
		},

		onupdate = function(inst)
			if not inst.components.playercontroller:IsControlHeld("skill") then
				inst.sg:GoToState("skill_miniboss_floracrane_dive", false)
			end
		end,

		events =
		{
			EventHandler("animover", function(inst)
				if not inst.components.playercontroller:IsControlHeld("skill") then
					inst.sg:GoToState("skill_miniboss_floracrane_dive")
				else
					inst.sg:GoToState("skill_miniboss_floracrane_dive_focus")
				end
			end),
		},
	}),

	PlayerSkillState({
		name = "skill_miniboss_floracrane_dive",
		tags = { "busy", "airborne", "airborne_high" },
		onenter = function(inst)

			--NORMAL ATTACK, not focus attack.

			inst.AnimState:PlayAnimation("skill_flora_dive")
			SGCommon.Fns.SetMotorVelScaled(inst, 50)
			inst.Physics:StartPassingThroughObjects()
			inst.components.hitbox:StartRepeatTargetDelay()

			inst.sg.statemem.focus = false

			--sound
			if inst.sg.mem.jump_sound then
				soundutil.KillSound(inst, inst.sg.mem.jump_sound)
				inst.sg.mem.jump_sound = nil
			end

			if inst.sg.mem.charge_lp_sound then
				soundutil.KillSound(inst, inst.sg.mem.charge_lp_sound)
				inst.sg.mem.charge_lp_sound = nil
			end

			soundutil.PlayCodeSound(inst, fmodtable.Event.Skill_Floracrane_Dive,{
				max_count = 1,
				stopatexitstate = true
			})
			
		end,

		timeline =
		{
			FrameEvent(3, function(inst)
				inst.sg:RemoveStateTag("airborne_high")
				inst.sg:RemoveStateTag("airborne")
				inst.Physics:Stop()
				SGPlayerCommon.Fns.SafeStopPassingThroughObjects(inst)
				soundutil.PlayCodeSound(inst, fmodtable.Event.Skill_Floracrane_Impact,{
					max_count = 1,
					stopatexitstate = true,
				})
			end),

			FrameEvent(0, function(inst) inst.sg.statemem.attack = "HIGH" end),

			FrameEvent(0, function(inst) inst.components.hitbox:PushBeam(0, 1.5, 1.5, HitPriority.PLAYER_DEFAULT) end),
			FrameEvent(1, function(inst) inst.components.hitbox:PushBeam(0, 1.5, 1.5, HitPriority.PLAYER_DEFAULT) end),

			FrameEvent(2, function(inst) inst.sg.statemem.attack = "MID" end),
			FrameEvent(2, function(inst) inst.components.hitbox:PushBeam(-2, 1.5, 1.5, HitPriority.PLAYER_DEFAULT) end),
			FrameEvent(3, function(inst) inst.components.hitbox:PushBeam(-2, 1.5, 1.5, HitPriority.PLAYER_DEFAULT) end),
			FrameEvent(4, function(inst) inst.components.hitbox:PushBeam(-2, 1.5, 1.5, HitPriority.PLAYER_DEFAULT) end),

			FrameEvent(7, SGPlayerCommon.Fns.SetCanDodge),
			FrameEvent(7, SGPlayerCommon.Fns.SetCanHeavyDodgeSpecial),
		},

		onexit = function(inst)
			SGPlayerCommon.Fns.SafeStopPassingThroughObjects(inst)
			inst.components.hitbox:StopRepeatTargetDelay()
		end,

		events =
		{
			EventHandler("hitboxtriggered", OnBodyHitBoxTriggered),

			EventHandler("animover", function(inst)
				inst.sg:GoToState("skill_miniboss_floracrane_dive_pst", inst.sg.statemem.focus)
			end),
		},
	}),


	PlayerSkillState({
		name = "skill_miniboss_floracrane_dive_focus",
		tags = { "busy", "airborne", "airborne_high" },
		onenter = function(inst)
			inst.AnimState:PlayAnimation("skill_flora_dive")
			SGCommon.Fns.SetMotorVelScaled(inst, 50)
			inst.Physics:StartPassingThroughObjects()
			inst.components.hitbox:StartRepeatTargetDelay()

			inst.sg.statemem.hitboxfn = OnBodyHitBoxTriggered

			-- sound
			if inst.sg.mem.jump_sound then
				soundutil.KillSound(inst, inst.sg.mem.jump_sound)
				inst.sg.mem.jump_sound = nil
			end

			if inst.sg.mem.charge_lp_sound then
				soundutil.KillSound(inst, inst.sg.mem.charge_lp_sound)
				inst.sg.mem.charge_lp_sound = nil
			end

			soundutil.PlayCodeSound(inst, fmodtable.Event.Skill_Floracrane_Dive, {
				max_count = 1,
				stopatexitstate = true,
				fmodparams = {
					isFocusAttack = 1 or 0,
				}
			})
		end,

		timeline =
		{
			FrameEvent(3, function(inst)
				inst.sg:RemoveStateTag("airborne_high")
				inst.sg:RemoveStateTag("airborne")
				inst.Physics:Stop()
				SGPlayerCommon.Fns.SafeStopPassingThroughObjects(inst)
				soundutil.PlayCodeSound(inst, fmodtable.Event.Skill_Floracrane_Impact,
					{
						max_count = 1,
						stopatexitstate = true,
						fmodparams =
						{
							isFocusAttack = 1 or 0,
						}
					})
			end),

			FrameEvent(0, function(inst) inst.sg.statemem.attack = "HIGH" end),
			FrameEvent(0, function(inst) inst.components.hitbox:PushBeam(0, 1.5, 1.5, HitPriority.PLAYER_DEFAULT) end),
			FrameEvent(1, function(inst) inst.components.hitbox:PushBeam(0, 1.5, 1.5, HitPriority.PLAYER_DEFAULT) end),

			FrameEvent(2, function(inst) inst.sg.statemem.attack = "MID" end),
			FrameEvent(2, function(inst) inst.components.hitbox:PushBeam(-2, 1.5, 1.5, HitPriority.PLAYER_DEFAULT) end),
			FrameEvent(3, function(inst) inst.components.hitbox:PushBeam(-2, 1.5, 1.5, HitPriority.PLAYER_DEFAULT) end),
			FrameEvent(4, function(inst) inst.components.hitbox:StopRepeatTargetDelay() end),

			-- AOE is a different attack
			FrameEvent(5, function(inst)
				inst.components.hitbox:StartRepeatTargetDelay()

				inst.sg.statemem.hitboxfn = OnAOEHitBoxTriggered
				inst.sg.statemem.attack = "AOE"
				inst.components.hitbox:PushCircle(0, 0, 4.5, HitPriority.PLAYER_DEFAULT)
			end),

			FrameEvent(6, function(inst)
				inst.components.hitbox:PushCircle(0, 0, 4.5, HitPriority.PLAYER_DEFAULT)
			end),

			FrameEvent(7, SGPlayerCommon.Fns.SetCanDodge),
			FrameEvent(7, SGPlayerCommon.Fns.SetCanHeavyDodgeSpecial),
		},

		onexit = function(inst)
			SGPlayerCommon.Fns.SafeStopPassingThroughObjects(inst)
			inst.components.hitbox:StopRepeatTargetDelay()
		end,

		events =
		{
			EventHandler("hitboxtriggered", function(inst, data) inst.sg.statemem.hitboxfn(inst, data) end),

			EventHandler("animover", function(inst)
				inst.sg:GoToState("skill_miniboss_floracrane_dive_pst", inst.sg.statemem.focus)
			end),
		},
	}),

	PlayerSkillState({
		name = "skill_miniboss_floracrane_dive_pst",
		tags = { "busy" },
		onenter = function(inst, focus)
			inst.AnimState:PlayAnimation("skill_flora_dive_pst")
			SGPlayerCommon.Fns.SetCanDodge(inst)
			SGPlayerCommon.Fns.SetCanHeavyDodgeSpecial(inst)
		end,

		timeline =
		{
			FrameEvent(15, SGPlayerCommon.Fns.RemoveBusyState)
		},

		events =
		{
			EventHandler("animover", function(inst)
				inst.sg:GoToState("skill_pst")
			end),
		},
	}),
}

return StateGraph("sg_player_skill_miniboss_floracrane", states, events, "skill_miniboss_floracrane")
