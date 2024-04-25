local ParticleSystemHelper = require "util.particlesystemhelper"
local SGCommon = require "stategraphs.sg_common"
local EffectEvents = require "effectevents"

local assets =
{
}

local function OnExplodeHitBoxTriggered(inst, data)
	if not inst.owner or not inst:IsLocal() then
		return
	end

	local damage_mod = inst.damage_mod
	local hitstun_animframes = inst.hitstun_animframes
	local hitstoplevel = inst.hitstoplevel
	local pushback = inst.pushback
	local source = inst.source
	local attacktype = inst.attacktype
	local dir = inst.Transform:GetFacingRotation()

	for i = 1, #data.targets do
		local v = data.targets[i]

		if v ~= inst.source_projectile then

			local attack = Attack(inst.owner, v)
			attack:SetDamageMod(damage_mod)
			attack:SetDir(dir)
			attack:SetPushback(pushback)
			attack:SetHitstunAnimFrames(hitstun_animframes)
			attack:SetID(attacktype)
			attack:SetNameID("shotput_land_explosion")
			attack:SetHitFlags(Attack.HitFlags.LOW_ATTACK)

			local dist = inst:GetDistanceSqTo(v)

			local hit = false
			if dist <= 6 then
				inst.owner:ShakeCamera(CAMERASHAKE.FULL, .3, .02, .3)
				hit = inst.owner.components.combat:DoKnockdownAttack(attack)
			else
				inst.owner:ShakeCamera(CAMERASHAKE.VERTICAL, .3, .02, .3)
				hit = inst.owner.components.combat:DoKnockbackAttack(attack)
			end

			if hit then
				hitstoplevel = SGCommon.Fns.ApplyHitstop(attack, hitstoplevel, { disable_self_hitstop = true })

				-- This HitFx is bizarrely positioned in this case, so I'm commenting it out for now til there's time to fix.
				-- inst.owner.components.combat:SpawnHitFxForPlayerAttack(attack, "hits_player_jamball", v, inst.owner, 0, 0, dir, hitstoplevel)
				SpawnHurtFx(inst, v, 0, dir, hitstoplevel)
			end
		end
	end
end

local function Setup(inst, data)
	--[[
	data
		owner
		source_projectile
		damage_mod 
		hitstun_animframes
		hitstoplevel
		hitboxradius
		pushback
		owner
		attacktype
	]]

	inst.owner = data.owner
	inst.source_projectile = data.source_projectile
	inst.damage_mod = data.damage_mod
	inst.hitstun_animframes = data.hitstun_animframes
	inst.hitstoplevel = data.hitstoplevel
	inst.hitboxradius = data.hitboxradius
	inst.pushback = data.pushback
	inst.source = data.owner
	inst.attacktype = data.attacktype
end

local function setup_fn(prefabname)
	local inst = CreateEntity()
	inst:SetPrefabName(prefabname)

	inst.entity:AddTransform()
	inst.entity:AddHitBox()
	inst.entity:AddSoundEmitter()

	inst:AddComponent("hitbox")
	inst.components.hitbox:SetUtilityHitbox(true)
	inst.components.hitbox:SetHitGroup(HitGroup.PLAYER)
	inst.components.hitbox:SetHitFlags(HitGroup.CREATURES | HitGroup.RESOURCE)
	inst.components.hitbox:StartRepeatTargetDelay()

	inst.Setup = Setup

	inst:ListenForEvent("hitboxtriggered", OnExplodeHitBoxTriggered)

	inst:DoTaskInTicks(1, function(inst)
		-- Wait until position is set
		if inst ~= nil and inst:IsValid() then
			inst:DoDurationTaskForTicks(2, function(inst)
				if inst ~= nil and inst:IsValid() then
					inst.components.hitbox:PushCircle(0, 0, 3.5, HitPriority.MOB_DEFAULT)
				end
			end)

			inst:DoTaskInAnimFrames(10, function(inst)
				if inst ~= nil and inst:IsValid() then
					inst:DelayedRemove()
				end
			end)


			local focus = false -- inst.sg.mem.focus_sequence[GetRemainingAmmo(inst)]
			EffectEvents.MakeEventSpawnEffect(inst, {
				fxname= focus and "fx_cannon_sphere_aoe_focus" or "fx_cannon_sphere_aoe",
				offz=-0.1,
				scalex=1.0,
				scalez=1.0,
			})
			EffectEvents.MakeEventSpawnEffect(inst, {
				fxname=focus and "cannon_aoe_explosion_med_focus" or "cannon_aoe_explosion_med",
				offx=0.19,
				offy=0.45,
				offz=-0.1,
				scalex=1.5,
				scalez=1.5,
			})
			EffectEvents.MakeEventSpawnEffect(inst, {
				fxname= focus and "fx_cannon_smoke_aoe_focus" or "fx_cannon_smoke_aoe",
				offz=-0.1,
				scalex=1.5,
				scalez=1.5,
			})

			-- ParticleSystemHelper.MakeEventSpawnParticles(inst, {
			-- 	duration=90.0,
			-- 	particlefxname= focus and "cannon_burst_aoe_sphere_med_focus" or "cannon_burst_aoe_sphere_med",
			-- })
		end
	end)
	return inst
end

return Prefab("player_shotput_land_explosion", setup_fn, assets, nil, nil, NetworkType_SharedAnySpawn)