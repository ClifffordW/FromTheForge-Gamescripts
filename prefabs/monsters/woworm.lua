local monsterutil = require "util.monsterutil"
local prefabutil = require "prefabs.prefabutil"
local fmodtable = require "defs.sound.fmodtable"
local SGCommon = require "stategraphs.sg_common"

local assets =
{
	Asset("ANIM", "anim/woworm_bank.zip"),
	Asset("ANIM", "anim/woworm_build.zip"),
}
local elite_assets =
{
	Asset("ANIM", "anim/woworm_bank.zip"),
	Asset("ANIM", "anim/woworm_elite_build.zip"),
}
local shell_assets =
{
	Asset("ANIM", "anim/woworm_shell_bank.zip"),
	Asset("ANIM", "anim/woworm_shell_build.zip"),
}
local shell_elite_assets =
{
	Asset("ANIM", "anim/woworm_shell_bank.zip"),
	Asset("ANIM", "anim/woworm_elite_shell_build.zip"),
}

local prefabs =
{
	"fx_hurt_sweat",
	"fx_low_health_ring",
	GroupPrefab("fx_acid"),
	"trap_acid",
	"woworm_shell",
	"woworm_shell_elite",

	--Drops
	GroupPrefab("drops_generic"),
	GroupPrefab("drops_woworm"),
}
prefabutil.SetupDeathFxPrefabs(prefabs, "woworm")
prefabutil.SetupDeathFxPrefabs(prefabs, "woworm_elite")
local prefabs_shell = {}

local attacks =
{
	barf =
	{
		priority = 1,
		startup_frames = 20,
		cooldown = 5,
		initialCooldown = 0,
		pre_anim = "puke_pre",
		hold_anim = "puke_loop",
		start_conditions_fn = function(inst, data, trange)
			return trange:TestBeam(0, 3.5, 1)
		end
	}
}
export_timer_names_grab_attacks(attacks) -- This needs to be here to extract the names of cooldown timers for the network strings

local elite_attacks =
{
	shellslam =
	{
		priority = 1,
		startup_frames = 20,
		cooldown = 3,
		initialCooldown = 0,
		pre_anim = "shell_slam_pre",
		hold_anim = "shell_slam_loop",
		loop_hold_anim = true,
		start_conditions_fn = function(inst, data, trange)
			return trange:TestBeam(0, 6, 2)
		end
	}
}
export_timer_names_grab_attacks(elite_attacks) -- This needs to be here to extract the names of cooldown timers for the network strings

local function fn(prefabname, monstersize)
	local inst = CreateEntity()
	inst:SetPrefabName(prefabname)

	monsterutil.MakeBasicMonster(inst, monstersize, monsterutil.MonsterSize.MEDIUM)
	inst.HitBox:SetNonPhysicsRect(1)

	inst.components.scalable:SnapshotBaseSize()

	inst:AddTag("ACID_IMMUNE")
	inst.AnimState:SetBank("woworm_bank")
	inst.AnimState:SetBuild("woworm_build")
	inst.AnimState:PlayAnimation("idle", true)
	inst.AnimState:SetFrame(math.random(inst.AnimState:GetCurrentAnimationNumFrames()) - 1)

	inst:SetStateGraph("sg_woworm")
	inst:SetBrain("brain_basic_melee")

	inst.components.foleysounder:SetBodyfallSound(fmodtable.Event.woworm_bodyfall)
    inst.components.foleysounder:SetFootstepSound(fmodtable.Event.woworm_footstep)

	return inst
end

local function normal_fn(prefabname)
	local inst = fn(prefabname, 1)

	inst.components.attacktracker:AddAttacks(attacks)

	return inst
end

local function elite_fn(prefabname)
	local inst = fn(prefabname, 1.4)

	inst.AnimState:SetBuild("woworm_elite_build")
	inst.components.attacktracker:AddAttacks(elite_attacks)
	monsterutil.ExtendToEliteMonster(inst)

	return inst
end

local function make_shell(prefabname, basescale, basehealth, thismass)
	local inst = CreateEntity()
	inst:SetPrefabName(prefabname)

	inst.entity:AddTransform()
	inst.entity:AddAnimState()
	inst.entity:AddSoundEmitter()
	inst.entity:AddHitBox()

	inst.HitBox:SetNonPhysicsRect(1)
	inst.HitBox:SetHitGroup(HitGroup.NEUTRAL)

	inst.AnimState:SetBank("woworm_shell_bank")
	inst.AnimState:SetBuild("woworm_shell_build")
	inst.AnimState:SetShadowEnabled(true)
	inst.AnimState:SetRimEnabled(true)
	inst.AnimState:SetRimSize(3)
	inst.AnimState:SetRimSteps(3)
	inst.Transform:SetTwoFaced()

	local scale_range = basescale + (math.random(10) / 100)
	inst.AnimState:SetScale(scale_range, scale_range)

	MakeSmallMonsterPhysics(inst, 1, thismass)
	inst:AddTag("medium")
	inst.knockdown_distance = 16
	inst.knockback_distance = 8
	inst.serializeHistory = true

	inst:SetStateGraph("sg_woworm_shell")

	inst:AddComponent("combat")
	inst.components.combat:SetHasKnockback(true)
	inst.components.combat:SetHasKnockdown(true)

	inst:AddComponent("health")
	inst.components.health:SetMax(basehealth, true)
	inst.components.health:SetHealable(false)

	inst:AddComponent("timer")
	inst:AddComponent("hitbox")
	inst:AddComponent("hitshudder")
	inst:AddComponent("pushbacker")
	inst:AddComponent("coloradder")
	--inst:AddComponent("hitstunvisualizer")

	inst.components.hitbox:SetHitGroup(HitGroup.NEUTRAL)
	inst.components.hitbox:SetHitFlags(HitGroup.ALL)

	inst:AddTag("prop_destructible")
	inst:AddTag("prop")
	inst:AddTag("ACID_IMMUNE")

	--Hide the cracked shell symbols otherwise they appear behind the shell symbol when cracked
	inst.AnimState:HideSymbol("shell_cracked2")
	inst.AnimState:HideSymbol("shell_cracked")

	inst:ListenForEvent("healthchanged", function(_, data)
		local currpercent = data.new / data.max
		local animbuild = inst:HasTag("elite") and "woworm_elite_shell_build" or "woworm_shell_build"
		if (currpercent <= 0) then --Playing the death animation with another symbol set makes the animation invisible
			inst.AnimState:OverrideSymbol("shell", animbuild, "shell")
		elseif (currpercent < 0.33) then
			inst.AnimState:OverrideSymbol("shell", animbuild, "shell_cracked2")
		elseif (currpercent < 0.66) then
			inst.AnimState:OverrideSymbol("shell", animbuild, "shell_cracked")
		else
			inst.AnimState:OverrideSymbol("shell", animbuild, "shell")
		end
	end)

	return inst
end

local function shell_fn(prefabname)
	local inst = make_shell(prefabname, 0.9, TUNING.woworm.shell_health, 1000)

	return inst
end

local function shell_elite_fn(prefabname)
	local inst = make_shell(prefabname, 1.1, TUNING.woworm_elite.shell_health, 1400)
	inst.AnimState:SetBuild("woworm_elite_shell_build")
	inst:AddTag("elite")

	return inst
end

return Prefab("woworm", normal_fn, assets, prefabs, nil, NetworkType_SharedHostSpawn),
		Prefab("woworm_elite", elite_fn, elite_assets, prefabs, nil, NetworkType_SharedHostSpawn),
		Prefab("woworm_shell", shell_fn, shell_assets, prefabs_shell, nil, NetworkType_SharedAnySpawn),
		Prefab("woworm_shell_elite", shell_elite_fn, shell_elite_assets, prefabs_shell, nil, NetworkType_SharedAnySpawn)

