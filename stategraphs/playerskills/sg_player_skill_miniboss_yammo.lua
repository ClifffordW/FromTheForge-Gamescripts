local SGCommon = require "stategraphs.sg_common"
local SGPlayerCommon = require "stategraphs.sg_player_common"
local PlayerSkillState = require "playerskillstate"
local combatutil = require "util.combatutil"
local fmodtable = require "defs.sound.fmodtable"
local soundutil = require "util.soundutil"
local EffectEvents = require "effectevents"
local lume = require "util.lume"

local events = {}

local ATTACKS =
{
	-- Attack damage is tuned the same as reverse heavy attack
	NORMAL =
	{
		BASE_DAMAGE = 0.833,
		HITSTUN = 15,
		PUSHBACK = 1,
		HITSTOP = HitStopLevel.HEAVIER,
	},

	FOCUS =
	{
		BASE_DAMAGE = 4,
		HITSTUN = 20,
		PUSHBACK = 2,
		HITSTOP = HitStopLevel.MAJOR,
	},
}

local MAX_LOOPS = 3
local LOOPS_TO_COLORMULT =
{
	0.0,
	0.0,
	1,
}

local SIZESUFFIX_TO_HITBOX_DATA =
{
	["_sml"] =
	{
		length_mod = 1,
		thickness_mod = 1,
	},
	["_med"] =
	{
		length_mod = 2,
		thickness_mod = 1.25,
	},
	["_lrg"] =
	{
		length_mod = 3,
		thickness_mod = 1.5,
	},
}

local BONUS_DAMAGE_MOD_PER_LOOP = 0.5

assert(MAX_LOOPS == #LOOPS_TO_COLORMULT)

local FOCUS_LOOPS_THRESHOLD = 3 -- Become focus after this many loops

local function OnSwingHitBoxTriggered(inst, data)
	local loops = inst.sg.statemem.yammoloops or 0
	local focus = loops ~= nil and loops >= FOCUS_LOOPS_THRESHOLD
	local attack_data = ATTACKS[focus and "FOCUS" or "NORMAL"]

	local power = inst.components.powermanager:GetPowerByName("miniboss_yammo")

	local base_damage = math.floor((attack_data.BASE_DAMAGE + (loops * BONUS_DAMAGE_MOD_PER_LOOP))  * inst.components.combat:GetBaseDamage())
	local bonus_damage = power and power.mem.damageabsorbed or 0
	local total_damage = math.floor(base_damage + bonus_damage)

	local pushback = attack_data.PUSHBACK
	local dir = inst.Transform:GetFacingRotation()

	local bonus_hitstop = math.min(3, math.ceil(( bonus_damage / 1000)) * 3) -- 5 possible extra frames, depending on how much damage was taken
	local hitstoplevel = attack_data.HITSTOP + bonus_hitstop
	local hitstun = attack_data.HITSTUN + bonus_hitstop

	local bonus_shake = ( bonus_damage /1000 ) * 0.2
	-- print("base_damage:", base_damage, "bonus damage mod:", loops * BONUS_DAMAGE_MOD_PER_LOOP, "bonus_damage:", bonus_damage, "bonus_hitstop:", bonus_hitstop, "hitstoplevel:", hitstoplevel, "hitstun:", hitstun)

	local hit = false

	for i = 1, #data.targets do
		local v = data.targets[i]

		local attack = Attack(inst, v)
		attack:SetDamageMod(0)
		attack:SetOverrideDamage(total_damage)
		attack:SetDir(dir)
		attack:SetHitstunAnimFrames(hitstun)
		attack:SetPushback(pushback)
		attack:SetFocus(focus)
		attack:SetID("skill")
		attack:SetNameID("YAMMO_SKILL")
		attack:SetHitFlags(inst.sg.statemem.hitflags or Attack.HitFlags.LOW_ATTACK)

		hit = inst.components.combat:DoKnockdownAttack(attack)
		if focus then
			inst:ShakeCamera(CAMERASHAKE.FULL, .3 + bonus_shake, .02 + (bonus_shake*0.1), .3)
		else
			inst:ShakeCamera(CAMERASHAKE.FULL, .15 + bonus_shake, .01 + (bonus_shake*0.05), .3)
		end

		if hit then
			hitstoplevel = SGCommon.Fns.ApplyHitstop(attack, hitstoplevel)

			inst:PushEvent("skill_hit")

			inst.components.combat:SpawnHitFxForPlayerAttack(attack, "hits_player_skill", v, inst, 0, 1.25, dir,
				hitstoplevel)
			-- SpawnHurtFx(inst, v, hitfx_x_offset, dir, hitstoplevel)
		end
	end

	if hit then -- sound presentation
		if inst.sg.mem.roar_sound then
			soundutil.KillSound(inst, inst.sg.mem.roar_sound)
			inst.sg.mem.roar_sound = nil
		end

		if inst.sg.mem.whoosh_sound then
			soundutil.KillSound(inst, inst.sg.mem.whoosh_sound)
			inst.sg.mem.whoosh_sound = nil
		end

		if inst.sg.mem.punch_whoosh_sound then
			if #data.targets > 1 then -- shorten punch whoosh release if we're hitting multiple things to clear space
				soundutil.SetInstanceParameter(inst, inst.sg.mem.punch_whoosh_sound, "local_discreteBinary", 1)
			end
			soundutil.KillSound(inst, inst.sg.mem.punch_whoosh_sound)
			inst.sg.mem.punch_whoosh_sound = nil
		end

		local delay_intervals_in_frames = { 0, 4, 3, 2 } -- delay_map[num_targets] = delay_frames

		-- filter out targets that don't have a sound emitter
		local targets = lume.filter(data.targets, function(v)
			return v.SoundEmitter
		end)

		local num_targets = math.floor(#targets)

		local function get_delay_frames(num_targets)
			local max_targets = #delay_intervals_in_frames
			local max_delay = delay_intervals_in_frames[#delay_intervals_in_frames]

			if num_targets > max_targets then
				return max_delay
			else
				return delay_intervals_in_frames[num_targets]
			end
		end

		-- play sounds for each target hit, with delays calculated based on the number of targets
		for i = 1, num_targets do
			local target = targets[i]
			local delay_frames = get_delay_frames(num_targets)
			delay_frames = (i == 1) and 0 or (i - 1) * delay_frames

			local impactSequenceProgress = num_targets == 1 and 1 or (i - 1) / (num_targets - 1)
			target:DoTaskInAnimFrames(delay_frames, function()
				soundutil.PlayCodeSound(target, fmodtable.Event.Skill_Yammo_Punch_Hit,
					{
						max_count = 1,
						fmodparams = {
							impactSequenceProgress = impactSequenceProgress,
							skill_chargeLevel = loops / MAX_LOOPS,
							isFocusAttack = focus and 1 or 0,
							local_discreteBinary = hitstoplevel > HitStopLevel.HEAVIER and 1 or 0
						}
					})
			end)
		end
	end

	if hit then
		inst:PushEvent("yammo_skill")
		SGPlayerCommon.Fns.SetHitConfirmCancelWindows(inst,
		{
			dodgedelay = 1,

			lightdelay = 14,
			lightcombostate = "default_light_attack",

			heavydelay = 14,
			heavycombostate = "default_heavy_attack",

			skilldelay = 14,
			skillcombostate = inst.sg.mem.skillstate,
		})
	end
end

local function _get_color(loops)
	local colormult = LOOPS_TO_COLORMULT[loops]
	local color = {}
	color[1] = TUNING.FLICKERS.WEAPONS.HAMMER.CHARGE_COMPLETE.COLOR[1] * colormult
	color[2] = TUNING.FLICKERS.WEAPONS.HAMMER.CHARGE_COMPLETE.COLOR[2] * colormult
	color[3] = TUNING.FLICKERS.WEAPONS.HAMMER.CHARGE_COMPLETE.COLOR[3] * colormult
	color[4] = 1.0

	return color
end

local states =
{
	PlayerSkillState({
		name = "skill_miniboss_yammo",
		tags = { "busy", "nointerrupt", "yammo_skill_absorbstate" },

		onenter = function(inst)
			inst.AnimState:PlayAnimation("skill_yammo_pre")
			if not inst.components.playercontroller:IsControlHeld("skill") then
				inst.sg.statemem.mustexit = true
			end

			SGPlayerCommon.Fns.SetCanDodge(inst)
		end,

		timeline =
		{
			FrameEvent(4, function(inst)
				if inst.sg.statemem.mustexit then
					inst.sg:GoToState("skill_miniboss_yammo_swing", { loops = 0 }) -- We released early, so just go right to the swing
				else
					inst.sg.statemem.canexit = true -- Releasing past this point means we can attack.
				end
			end),

			FrameEvent(5, function(inst)
				if inst.sg.statemem.canexit then
					inst.sg.mem.roar_sound = soundutil.PlayCodeSound(inst, fmodtable.Event.Skill_Yammo_Punch_Roar,
						{
							max_count = 1,
						})
				end
			end),
		},

		events =
		{
			EventHandler("controlupevent", function(inst, data)
				if data.control == "skill" then
					if inst.sg.statemem.canexit then
						-- This is after frame 4, so let's exit now
						inst.sg:GoToState("skill_miniboss_yammo_swing", { loops = 0 } )
					else
						-- If the player has released SKILL before frame 4, then set a flag so that once we hit frame 4 we MUST exit.
						inst.sg.statemem.mustexit = true
					end
				end
			end),

			EventHandler("animover", function(inst)
				if inst.sg.statemem.mustexit then
					inst.sg:GoToState("skill_miniboss_yammo_swing", { loops = 0 } )
				else
					-- They're still holding the button, so let's start charging.
					inst.sg:GoToState("skill_miniboss_yammo_loop", { loops = 0 })
				end
			end),
		},
	}),

	PlayerSkillState({
		name = "skill_miniboss_yammo_loop",
		tags = { "busy", "nointerrupt", "yammo_skill_absorbstate" },

		onenter = function(inst, data)
			-- data = loops
			inst.AnimState:PlayAnimation("skill_yammo_loop", true)

			inst.sg.statemem.yammoloops = data.loops or 0
			if inst.sg.statemem.yammoloops > 0 then
				inst.sg.statemem.color = _get_color(inst.sg.statemem.yammoloops)
			end

			SGPlayerCommon.Fns.SetCanDodge(inst)

			-- inst.sg.statemem.windup_sound_lp = soundutil.PlayCodeSound(inst,fmodtable.Event.Skill_Yammo_WindUp_LP,
			-- 	{
			-- 		instigator = inst,
			-- 		max_count = 1,
			-- 		is_autostop = true,
			-- 	}
			-- )
		end,

		timeline =
		{
			FrameEvent(0, function(inst)
				if inst.sg.statemem.yammoloops >= FOCUS_LOOPS_THRESHOLD then
					SGCommon.Fns.FlickerSymbolBloom(inst, "swap_fx2", inst.sg.statemem.color, TUNING.FLICKERS.WEAPONS.HAMMER.CHARGE_COMPLETE.FLICKERS, TUNING.FLICKERS.WEAPONS.HAMMER.CHARGE_COMPLETE.FADE, TUNING.FLICKERS.WEAPONS.HAMMER.CHARGE_COMPLETE.TWEENS)
				end

				inst.sg.statemem.yammoloops = math.min(inst.sg.statemem.yammoloops + 1, MAX_LOOPS)

				if inst.sg.statemem.yammoloops >= MAX_LOOPS then
					inst.sg.statemem.fullycharged = true
				end

				inst.sg.mem.whoosh_sound = soundutil.PlayCodeSound(inst, fmodtable.Event.Skill_Yammo_WindUp_Whoosh,
					{
						max_count = 1,
						fmodparams = { skill_chargeLevel = inst.sg.statemem.yammoloops / MAX_LOOPS },
					}
				)

				-- if inst.sg.statemem.windup_sound_lp then
				-- 	soundutil.SetInstanceParameter(inst.sg.statemem.windup_sound_lp, "skill_chargeLevel", inst.sg.statemem.fullycharged and 1 or inst.sg.statemem.yammoloops / MAX_LOOPS)
				-- end

			end),

			FrameEvent(4, function(inst)
				if inst.sg.statemem.yammoloops >= FOCUS_LOOPS_THRESHOLD then
					-- FOCUS PING?
				end
			end),
		},

		onupdate = function(inst)
			if inst.sg.statemem.fx then
				local x, y, z = inst.AnimState:GetSymbolPosition("swap_fx2", 0, 0, 0)
				inst.sg.statemem.fx.Transform:SetPosition(x, y, z)
			end

			if not inst.components.playercontroller:IsControlHeld("skill") then
				local state
				if inst.sg.statemem.fullycharged then
					state = "skill_miniboss_yammo_swing_focus"
				else
					state = "skill_miniboss_yammo_swing"
				end

				inst.sg:GoToState(state, { loops = inst.sg.statemem.yammoloops})

				-- if inst.sg.statemem.windup_sound_lp then
				-- 	soundutil.KillSound(inst, inst.sg.statemem.windup_sound_lp)
				-- 	inst.sg.statemem.windup_sound_lp = nil
				-- end
			end
		end,

		onexit = function(inst)
			if inst.sg.mem.whoosh_sound then
				inst.sg.mem.whoosh_sound = nil
			end
			if inst.sg.statemem.fx ~= nil and inst.sg.statemem.fx:IsValid() then
				inst.sg.statemem.fx:Remove()
			end
		end,

		events =
		{
			EventHandler("controlupevent", function(inst, data)
				if data.control == "skill" then
					if inst.sg.statemem.canexit then
						-- This is after frame 4, so let's exit now
						inst.sg:GoToState(inst.sg.statemem.fullycharged and "skill_miniboss_yammo_swing_focus" or "skill_miniboss_yammo_swing", { loops = inst.sg.statemem.yammoloops })
					else
						-- If the player has released SKILL before frame 4, then set a flag so that once we hit frame 4 we MUST exit.
						inst.sg.statemem.mustexit = true
					end
				end
			end),

			EventHandler("animover", function(inst)
				if inst.sg.statemem.fullycharged or not inst.components.playercontroller:IsControlHeld("skill") then
					inst.sg:GoToState(inst.sg.statemem.fullycharged and "skill_miniboss_yammo_swing_focus" or "skill_miniboss_yammo_swing", { loops = inst.sg.statemem.yammoloops })
				else
					inst.sg:GoToState("skill_miniboss_yammo_loop", { loops = inst.sg.statemem.yammoloops })
				end
			end),
		},
	}),

	PlayerSkillState({
		name = "skill_miniboss_yammo_swing",
		tags = { "busy", "nointerrupt", "attack" },

		onenter = function(inst, data)
			inst.AnimState:PlayAnimation("skill_yammo_swing")
			-- inst.AnimState:SetFrame(4) -- ADJUSTED ALL VALUES BELOW BY -4. Faster startup! TODO: review once all content has been adjusted

			inst.sg.statemem.yammoloops = data.loops or 0

			inst.sg.mem.punch_whoosh_sound = soundutil.PlayCodeSound(inst,fmodtable.Event.Skill_Yammo_Punch_Whoosh,
				{
					max_count = 1,
					fmodparams = { skill_chargeLevel = inst.sg.statemem.yammoloops / MAX_LOOPS },
				}
			)

			if inst.sg.mem.roar_sound then
				soundutil.KillSound(inst, inst.sg.mem.roar_sound)
				inst.sg.mem.roar_sound = nil
			end

			inst:PushEvent("attack_state_start")
			inst.sg.statemem.attack_id = "YAMMO_SKILL"


			local power = inst.components.powermanager:GetPowerByName("miniboss_yammo")
			local tier = power.mem.tier
			dbassert(tier, "Yammo skill must have a tier. Didn't!")
			inst.sg.statemem.hitboxdata = SIZESUFFIX_TO_HITBOX_DATA[tier]

			inst.components.hitbox:StartRepeatTargetDelay()
		end,

		timeline =
		{
			FrameEvent(1, function(inst)
				combatutil.StartMeleeAttack(inst)
				inst.components.hitbox:PushBeam(-1.5, 0.25 * inst.sg.statemem.hitboxdata.length_mod, 1.5 * inst.sg.statemem.hitboxdata.thickness_mod, HitPriority.PLAYER_DEFAULT)
			end),
			FrameEvent(2, function(inst)
				inst.components.hitbox:PushBeam(0, 2 * inst.sg.statemem.hitboxdata.length_mod, 1.5 * inst.sg.statemem.hitboxdata.thickness_mod, HitPriority.PLAYER_DEFAULT)
			end),
			FrameEvent(3, function(inst)
				inst.components.hitbox:PushBeam(0, 2.5 * inst.sg.statemem.hitboxdata.length_mod, 2 * inst.sg.statemem.hitboxdata.thickness_mod, HitPriority.PLAYER_DEFAULT)
			end),
			FrameEvent(4, function(inst)
				inst.components.hitbox:PushBeam(0, 2.5 * inst.sg.statemem.hitboxdata.length_mod, 2 * inst.sg.statemem.hitboxdata.thickness_mod, HitPriority.PLAYER_DEFAULT)
			end),
			FrameEvent(5, function(inst)
				combatutil.EndMeleeAttack(inst)
			end),

			FrameEvent(9, SGPlayerCommon.Fns.SetCanDodge),
			FrameEvent(16, SGPlayerCommon.Fns.SetCanAttackOrAbility), -- Quite late, because on hitconfirm the cancels are better
			FrameEvent(19, SGPlayerCommon.Fns.RemoveBusyState)
		},

		onexit = function(inst)
			inst.components.hitbox:StopRepeatTargetDelay()
			local power = inst.components.powermanager:GetPowerByName("miniboss_yammo")
			power.mem.damageabsorbed = 0
		end,

		events =
		{
			EventHandler("hitboxtriggered", OnSwingHitBoxTriggered),

			EventHandler("animqueueover", function(inst)
				inst.sg:GoToState("skill_pst")
			end),
		},
	}),

	PlayerSkillState({
		name = "skill_miniboss_yammo_swing_focus",
		tags = { "busy", "nointerrupt", "attack" },

		onenter = function(inst, data)
			inst.AnimState:PlayAnimation("skill_yammo_swing")
			-- inst.AnimState:SetFrame(4) -- ADJUSTED ALL VALUES BELOW BY -4. Faster startup! TODO: review once all content has been adjusted

			inst.sg.statemem.yammoloops = data.loops or 0

			inst.sg.mem.punch_whoosh_sound = soundutil.PlayCodeSound(inst,fmodtable.Event.Skill_Yammo_Punch_Whoosh,
				{
					max_count = 1,
					fmodparams = { skill_chargeLevel = inst.sg.statemem.yammoloops / MAX_LOOPS },
				}
			)

			if inst.sg.mem.roar_sound then
				soundutil.KillSound(inst, inst.sg.mem.roar_sound)
				inst.sg.mem.roar_sound = nil
			end

			inst:PushEvent("attack_state_start")
			inst.sg.statemem.attack_id = "YAMMO_SKILL"
			inst.components.hitbox:StartRepeatTargetDelay()

			local power = inst.components.powermanager:GetPowerByName("miniboss_yammo")
			local tier = power.mem.tier
			dbassert(tier, "Yammo skill must have a tier. Didn't!")
			inst.sg.statemem.hitboxdata = SIZESUFFIX_TO_HITBOX_DATA[tier]
		end,

		timeline =
		{
			FrameEvent(1, function(inst)
				combatutil.StartMeleeAttack(inst)
				inst.components.hitbox:PushBeam(-1.5, 0.25 * inst.sg.statemem.hitboxdata.length_mod, 1.5 * inst.sg.statemem.hitboxdata.thickness_mod, HitPriority.PLAYER_DEFAULT)
			end),
			FrameEvent(2, function(inst)
				inst.components.hitbox:PushBeam(0, 2 * inst.sg.statemem.hitboxdata.length_mod, 1.5 * inst.sg.statemem.hitboxdata.thickness_mod, HitPriority.PLAYER_DEFAULT)
			end),
			FrameEvent(3, function(inst)
				inst.components.hitbox:PushBeam(0, 2.5 * inst.sg.statemem.hitboxdata.length_mod, 2 * inst.sg.statemem.hitboxdata.thickness_mod, HitPriority.PLAYER_DEFAULT)
			end),
			FrameEvent(4, function(inst)
				inst.components.hitbox:PushBeam(0, 2.5 * inst.sg.statemem.hitboxdata.length_mod, 2 * inst.sg.statemem.hitboxdata.thickness_mod, HitPriority.PLAYER_DEFAULT)
			end),
			FrameEvent(5, function(inst)
				combatutil.EndMeleeAttack(inst)
			end),

			FrameEvent(9, SGPlayerCommon.Fns.SetCanDodge),
			FrameEvent(16, SGPlayerCommon.Fns.SetCanAttackOrAbility), -- Quite late, because on hitconfirm the cancels are better
			FrameEvent(19, SGPlayerCommon.Fns.RemoveBusyState)
		},

		onexit = function(inst)
			inst.components.hitbox:StopRepeatTargetDelay()
			local power = inst.components.powermanager:GetPowerByName("miniboss_yammo")
			power.mem.damageabsorbed = 0
		end,

		events =
		{
			EventHandler("hitboxtriggered", OnSwingHitBoxTriggered),

			EventHandler("animqueueover", function(inst)
				inst.sg:GoToState("skill_pst")
			end),
		},
	}),
}

return StateGraph("sg_player_skill_miniboss_yammo", states, events, "skill_miniboss_yammo")
