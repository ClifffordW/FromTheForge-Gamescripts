-- Separate file to be shared between sg_megatreemon (used for hosts) and rootattacker (used for clients)

local SGCommon = require "stategraphs.sg_common"
local monsterutil = require "util.monsterutil"
local fmodtable = require "defs.sound.fmodtable"
local soundutil = require "util.soundutil"

local MegaTreemonShared = {}

function MegaTreemonShared.OnFlailHitBoxTriggered(inst, data)
	local damage_mod = 0.25
	SGCommon.Events.OnHitboxTriggered(inst, data, {
		hitstoplevel = HitStopLevel.HEAVY,
		set_dir_angle_to_target = true,
		damage_mod = damage_mod,
		pushback = 1.5,
		combat_attack_fn = "DoKnockbackAttack",
		hit_fx = monsterutil.defaultAttackHitFX,
		hit_fx_offset_x = 0.5,
		keep_it_local = true,
	})

	--sound for reduced damage
	local params = {}
	params.fmodevent = fmodtable.Event.Hit_reduced
	params.sound_max_count = 1
	local handle = soundutil.PlaySoundData(inst, params)
	soundutil.SetInstanceParameter(inst, handle, "damage_received_mult", damage_mod)
end

function MegaTreemonShared.OnSwipeHitBoxTriggered(inst, data)
	SGCommon.Events.OnHitboxTriggered(inst, data, {
		attackdata_id = "swipe",
		hitstoplevel = HitStopLevel.HEAVY,
		set_dir_angle_to_target = true,
		combat_attack_fn = "DoKnockdownAttack",
		hit_fx = monsterutil.defaultAttackHitFX,
		hit_fx_offset_x = 0.5,
	})
end

function MegaTreemonShared.OnPokeRootHitBoxTriggered(inst, data)
	SGCommon.Events.OnHitboxTriggered(inst, data, {
		hitstoplevel = HitStopLevel.LIGHT,
		set_dir_angle_to_target = true,
		damage_mod = 0.5,
		pushback = 0.1,
		hitflags = Attack.HitFlags.LOW_ATTACK,
		combat_attack_fn = "DoKnockbackAttack",
		hit_fx = monsterutil.defaultAttackHitFX,
		keep_it_local = true,
	})
end

function MegaTreemonShared.OnAttackRootHitBoxTriggered(inst, data)
	SGCommon.Events.OnHitboxTriggered(inst, data, {
		attackdata_id = "root",
		hitstoplevel = HitStopLevel.HEAVY,
		set_dir_angle_to_target = true,
		damage_mod = 0.75,
		pushback = 0.5,
		hitflags = Attack.HitFlags.LOW_ATTACK,
		combat_attack_fn = "DoKnockdownAttack",
		hit_fx = monsterutil.defaultAttackHitFX,
		keep_it_local = true,
	})
end

return MegaTreemonShared
