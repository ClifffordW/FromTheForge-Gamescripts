local monsterutil = require "util.monsterutil"
local prefabutil = require "prefabs.prefabutil"
local fmodtable = require "defs.sound.fmodtable"
local lume = require "util.lume"

local assets =
{
	Asset("ANIM", "anim/floracrane_bank.zip"),
	Asset("ANIM", "anim/floracrane_build.zip"),
	Asset("ANIM", "anim/fx_shadow.zip"),
}

local elite_assets =
{
	Asset("ANIM", "anim/floracrane_bank.zip"),
	Asset("ANIM", "anim/floracrane_elite_build.zip"),
}

local prefabs =
{
	"fx_hurt_sweat",
	"fx_low_health_ring",

	"slowpoke_spit",

	--Drops
	GroupPrefab("drops_generic"),
	GroupPrefab("drops_floracrane"),
}

local elite_prefabs = lume.merge(prefabs,
{
	"cine_play_miniboss_intro",
	"cine_floracrane_intro",
})

prefabutil.SetupDeathFxPrefabs(prefabs, "floracrane")
prefabutil.SetupDeathFxPrefabs(elite_prefabs, "floracrane_elite")

local attacks =
{
	flurry =
	{
		priority = 1,
		damage_mod = 0.4,
		startup_frames = 20,
		cooldown = 4,
		initialCooldown = 0,
		pre_anim = "flurry_pre",
		hold_anim = "flurry_loop",
		loop_hold_anim = true,
		start_conditions_fn = function(inst, data, trange)
			return trange:TestBeam(0, 5, 1.25)
		end
	},
	spear =
	{
		priority = 1,
		damage_mod = 1,
		startup_frames = 28,
		cooldown = 10,
		initialCooldown = 0,
		pre_anim = "spear_pre",
		hold_anim = "spear_hold",
		is_hitstun_pressure_attack = true,
		start_conditions_fn = function(inst, data, trange)
			return trange:TestBeam(-5, 5, 1)
		end
	}
}
export_timer_names_grab_attacks(attacks) -- This needs to be here to extract the names of cooldown timers for the network strings

local elite_attacks =
{
	dive_fast =
	{
		cooldown = 0.67,
		damage_mod = 1.2,
		startup_frames = 5,
		initialCooldown = 0,
		pre_anim = "dive_pre",
		hold_anim = "dive_hold",
		attack_state_override = "dive",
		start_conditions_fn = function(inst, data, trange)
			return false -- started through kick
		end
	},
	dive =
	{
		cooldown = 9,
		damage_mod = 1.2,
		startup_frames = 15,
		initialCooldown = 7.5,
		pre_anim = "dive2_pre",
		hold_anim = "dive2_hold",
		start_conditions_fn = function(inst, data, trange)
			return trange:IsBetweenRange(7, 18)
		end
	},
	spinning_bird_kick =
	{
		priority = 2,
		damage_mod = 0.5,
		startup_frames = 28,
		cooldown = 14,
		initialCooldown = 0,
		pre_anim = "spinning_bird_kick_pre",
		hold_anim = "spinning_bird_kick_hold",
		loop_hold_anim = true,
		is_hitstun_pressure_attack = true,
		start_conditions_fn = function(inst, data, trange)
			return trange:IsInRange(8)
		end
	},
	kick =
	{
		priority = 2,
		damage_mod = 1,
		startup_frames = 45,
		cooldown = 10, -- The entire kick sequence is about 7 seconds. Do it infrequently.
		initialCooldown = 0,
		pre_anim = "kick_pre",
		hold_anim = "kick_loop",
		loop_hold_anim = true,
		start_conditions_fn = function(inst, data, trange)
			return trange:TestBeam(0, 5, 0.75)
		end
	},

	-- For acid ball projectiles spawned on kick
	mortar =
	{
		damage_mod = 0.5,
		start_conditions_fn = function(inst, data, trange)
			return false
		end
	},
}
export_timer_names_grab_attacks(elite_attacks) -- This needs to be here to extract the names of cooldown timers for the network strings

local MONSTER_SIZE = 1.3

local function fn(prefabname)
	local inst = CreateEntity()
	inst:SetPrefabName(prefabname)

	monsterutil.MakeBasicMonster(inst, MONSTER_SIZE, monsterutil.MonsterSize.SMALL)

	inst:AddTag("spawn_walkable")

	inst.AnimState:SetBank("floracrane_bank")
	inst.AnimState:SetBuild("floracrane_build")
	--inst.AnimState:PlayAnimation("idle", true) --Was conflicting with a spawn animation flickering the idle for remote players
	--inst.AnimState:SetFrame(math.random(inst.AnimState:GetCurrentAnimationNumFrames()) - 1)

	inst.components.hitbox:SetHitFlags(HitGroup.ALL)

	inst.components.combat:SetFrontKnockbackOnly(true)
	inst.components.combat:SetVulnerableKnockdownOnly(true)
	inst.components.combat:SetBlockKnockback(true)

	inst.HitBox:SetNonPhysicsRect(MONSTER_SIZE * 0.75)

	inst:SetStateGraph("sg_floracrane")
	inst:SetBrain("brain_basic_melee")

	inst:AddTag("ACID_IMMUNE")
	inst:AddComponent("dropshadow")
	inst:AddComponent("cineactor")
	inst.components.cineactor:AfterEvent_PlayAsLeadActor("cine_play_miniboss_intro", "cine_floracrane_intro")

---- foley sounder
	inst.components.foleysounder:SetFootstepSound(fmodtable.Event.floracrane_footstep)
	inst.components.foleysounder:SetBodyfallSound(fmodtable.Event.floracrane_bodyfall)
	inst.components.foleysounder:SetFootstepStopSound(fmodtable.Event.floracrane_scrape)
    -- inst.components.foleysounder:SetHitStartSound(fmodtable.Event.AAAA_default_event)
    inst.components.foleysounder:SetKnockbackStartSound(fmodtable.Event.floracrane_hit)
    inst.components.foleysounder:SetKnockdownStartSound(fmodtable.Event.floracrane_knockdown)


	monsterutil.AddOffsetHitbox(inst, nil, "head_hitbox")
	monsterutil.AddOffsetHitbox(inst, nil, "leg_hitbox")

	inst:AddTag("nointerrupt")

	return inst
end

local function normal_fn(prefabname)
	local inst = fn(prefabname)

	inst.components.attacktracker:AddAttacks(attacks)

	return inst
end

local function elite_fn(prefabname)
	local inst = fn(prefabname)

	inst.AnimState:SetBuild("floracrane_elite_build")

	inst.components.attacktracker:AddAttacks(elite_attacks)

	monsterutil.ExtendToEliteMonster(inst)

	return inst
end

local function miniboss_fn(prefabname)
	local inst = elite_fn(prefabname)
	monsterutil.MakeMiniboss(inst)
	inst:AddComponent("boss")

	return inst
end

return Prefab("floracrane", normal_fn, assets, prefabs, nil, NetworkType_SharedHostSpawn)
	, Prefab("floracrane_elite", elite_fn, elite_assets, elite_prefabs, nil, NetworkType_SharedHostSpawn)
	, Prefab("floracrane_miniboss", miniboss_fn, elite_assets, elite_prefabs, nil, NetworkType_SharedHostSpawn)
