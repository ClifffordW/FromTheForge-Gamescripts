local ParticleSystemHelper = require "util.particlesystemhelper"

local assets =
{
}

local function setup_all(prefabname, left)
	local inst = CreateEntity()
	inst:SetPrefabName(prefabname)

	inst.entity:AddTransform()
	inst.Transform:SetTwoFaced()

	if left then
		inst.Transform:FlipFacingAndRotation()
	end

	inst.entity:AddHitBox()

	inst:AddComponent("hitbox")
	inst.components.hitbox:SetUtilityHitbox(true)
	inst.components.hitbox:SetHitGroup(HitGroup.PLAYER)
	inst.components.hitbox:SetHitFlags(HitGroup.CREATURES | HitGroup.RESOURCE)

	inst:AddComponent("powermanager")
	inst.components.powermanager:EnsureRequiredComponents()

	inst:AddComponent("auraapplyer")
	inst.components.auraapplyer:SetEffect("player_groak_suck")
	inst.components.auraapplyer:SetupBeamHitbox(2, 11.5, 1.5) -- This will be flipped by left/right
	inst.components.auraapplyer:Enable()

	local param =
	{
		name = "player_groak_skill_pfx",
		particlefxname = "groak_air_suck",
		ischild = true,
		use_entity_facing = true,
	}
	inst.particles = ParticleSystemHelper.MakeEventSpawnParticles(inst, param)
	inst.particles:ListenForEvent("particles_stopcomplete", function()
		if inst ~= nil and inst:IsValid() then
			inst.components.auraapplyer:Disable()
			inst:DelayedRemove()
		end
	end)

	inst:DoTaskInAnimFrames(20, function(inst)
		if inst ~= nil and inst:IsValid() then
			-- This is purely local, can not be transfered.
			inst.particles.components.particlesystem:StopAndNotify()
			-- ParticleSystemHelper.MakeEventStopParticles(inst, { name = "player_groak_skill_pfx" })

			inst.components.auraapplyer:Disable()
		end
	end)

	return inst
end

-- BASIC LEFT/RIGHT/DOWN/UP functions
local function left_fn(prefabname)
	local inst = setup_all(prefabname, true)


	return inst
end
local function right_fn(prefabname)
	local inst = setup_all(prefabname, false)

	return inst
end

-- These are all so that we can do one EffectEvents.MakeEventSpawnLocalEntity() call and not need to configure anything past that.
return Prefab("player_groak_vacuum_left", left_fn, assets),
	Prefab("player_groak_vacuum_right", right_fn, assets)