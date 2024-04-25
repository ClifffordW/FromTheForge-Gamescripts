local monsterutil = require "util.monsterutil"
local prefabutil = require "prefabs.prefabutil"
local fmodtable = require "defs.sound.fmodtable"

local assets =
{
	Asset("ANIM", "anim/swarmy_bank.zip"),
	Asset("ANIM", "anim/swarmy_build.zip"),
	Asset("ANIM", "anim/fx_swarmy_hair.zip"),
	Asset("ANIM", "anim/fx_warmy_dash_trail.zip"),
}

local elite_assets =
{
	Asset("ANIM", "anim/swarmy_bank.zip"),
	Asset("ANIM", "anim/swarmy_elite_build.zip"),
	Asset("ANIM", "anim/fx_swarmy_hair.zip"),
	Asset("ANIM", "anim/fx_warmy_dash_trail.zip"),
}

local prefabs =
{
	"fx_hurt_sweat",
	"fire_ground",
	"hits_fire",
	"trap_acid",

	--Drops
	GroupPrefab("drops_generic"),
	GroupPrefab("drops_swarmy")
}
prefabutil.SetupDeathFxPrefabs(prefabs, "swarmy")
prefabutil.SetupDeathFxPrefabs(prefabs, "swarmy_elite")

local attacks =
{
	acid_dash =
	{
		priority = 1,
		cooldown = 5,
		damage_mod = 0.6,
		initialCooldown = 0,
		startup_frames = 9,
		max_attacks_per_target = 1,
		pre_anim = "acid_dash_pre",
		hold_anim = "acid_dash_hold",
		start_conditions_fn = function(inst, data, trange)
			local result = false
			if trange:IsBetweenRange(0, 9) then
				result = monsterutil.MaxAttacksPerTarget(inst, data)
			end
			return result
		end
	},
	acid_burst =
	{
		priority = 1,
		damage_mod = 1,
		cooldown = 2,
		initialCooldown = 0,
		start_conditions_fn = function(inst, data, trange)
			return false -- entered through stategraph
		end
	},
}
export_timer_names_grab_attacks(attacks) -- This needs to be here to extract the names of cooldown timers for the network strings
local elite_attacks =
{
	uppercut =
	{
		priority = 2,
		cooldown = 5,
		damage_mod = 0.7, -- 2x hits possible
		initialCooldown = 0,
		startup_frames = 23, --pre plus hold
		loop_hold_anim = true,
		pre_anim = "uppercut_pre",
		hold_anim = "uppercut_loop",
		start_conditions_fn = function(inst, data, trange)
			return trange:TestBeam(0, 4, 1)
		end
	},
}

local BLOOM_COLOR = nil-- 0xFF00FF00
local BLOOM_INTENSITY = 1

local function CreateHair()
	local inst = CreateEntity()

	inst.entity:AddTransform()
	inst.entity:AddAnimState()
	inst.entity:AddFollower()

	inst:AddTag("FX")
	--[[Non-networked entity]]
	inst.persists = false

	inst.Transform:SetTwoFaced()

	inst.AnimState:SetBank("fx_swarmy_hair")
	inst.AnimState:SetBuild("fx_swarmy_hair")
	inst.AnimState:PlayAnimation("loop", true)
	inst.lastframe = inst.AnimState:GetCurrentAnimationNumFrames() - 1
	if BLOOM_COLOR ~= nil then
		local r, g, b = HexToRGBFloats(BLOOM_COLOR)
		inst.AnimState:SetBloom(r, g, b, BLOOM_INTENSITY)
	else
		inst.AnimState:SetBloom(BLOOM_INTENSITY)
	end

	return inst
end

local function DetachTrail(inst)
	local x, z = inst.Transform:GetWorldXZ()
	inst.entity:SetParent()
	inst.Transform:SetPosition(x, 0, z)
end

local function CreateDashTrail(variation)
	local inst = CreateEntity()

	inst.entity:AddTransform()
	inst.entity:AddAnimState()

	inst:AddTag("FX")
	inst:AddTag("NOCLICK")
	--[[Non-networked entity]]
	inst.persists = false

	inst.Transform:SetTwoFaced()

	inst.AnimState:SetBank("fx_warmy_dash_trail")
	inst.AnimState:SetBuild("fx_warmy_dash_trail")
	inst.AnimState:PlayAnimation(tostring(variation))
	if BLOOM_COLOR ~= nil then
		local r, g, b = HexToRGBFloats(BLOOM_COLOR)
		inst.AnimState:SetBloom(r, g, b, BLOOM_INTENSITY)
	else
		inst.AnimState:SetBloom(BLOOM_INTENSITY)
	end

	inst:DoTaskInTicks(2, DetachTrail)
	inst:ListenForEvent("animover", inst.Remove)

	return inst
end

local function SpawnDashTrail(inst, variation)
	--local fx = CreateDashTrail(variation)
	--fx.entity:SetParent(inst.entity)
	--fx.Transform:SetRotation(inst.Transform:GetFacingRotation())
	--return fx
end

local function fn(prefabname)
	local inst = CreateEntity()
	inst:SetPrefabName(prefabname)

	monsterutil.MakeBasicMonster(inst)
	inst:AddTag("ACID_IMMUNE")

	inst.AnimState:SetBank("swarmy_bank")
	inst.AnimState:SetBuild("swarmy_build")

	inst.hair = CreateHair()
	inst.hair.entity:SetParent(inst.entity)
	inst.hair.Follower:FollowSymbol(inst.GUID, "fire1")

	inst:SetStateGraph("sg_swarmy")
	inst:SetBrain("brain_swarmy")

	local frame = math.random(inst.AnimState:GetCurrentAnimationNumFrames()) - 1
	inst.AnimState:SetFrame(frame)

	if BLOOM_COLOR ~= nil then
		local r, g, b = HexToRGBFloats(BLOOM_COLOR)
		inst.AnimState:SetLayerBloom("temp_fire", r, g, b, BLOOM_INTENSITY)
	else
		inst.AnimState:SetLayerBloom("temp_fire", BLOOM_INTENSITY)
	end

	local particles = SpawnPrefab("acid_follow_v1", inst)
	particles.entity:SetParent(inst.entity)
	particles.entity:AddFollower()
	particles.Follower:FollowSymbol(inst.GUID, "fire1")
	particles.components.particlesystem:SetFinalOffset(-1)

	inst.SpawnDashTrail = SpawnDashTrail

	inst.components.foleysounder:SetFootstepSound(fmodtable.Event.swarmy_footstep)
	inst.components.foleysounder:SetBodyfallSound(fmodtable.Event.swarmy_bodfall)

	return inst
end

function normal_fn(prefabname)
	local inst = fn(prefabname)

	inst.components.attacktracker:AddAttacks(attacks)

	return inst
end

function elite_fn(prefabname)
	local inst = fn(prefabname)

	inst.AnimState:SetBuild("swarmy_elite_build")
	inst.components.attacktracker:AddAttacks(attacks)
	inst.components.attacktracker:AddAttacks(elite_attacks)
	monsterutil.ExtendToEliteMonster(inst)

	return inst
end

return Prefab("swarmy", normal_fn, assets, prefabs, nil, NetworkType_SharedHostSpawn),
		Prefab("swarmy_elite", elite_fn, elite_assets, prefabs, nil, NetworkType_SharedHostSpawn)
