local SGCommon = require "stategraphs.sg_common"
local Power = require "defs.powers.power"

local lume = require "util.lume"
local fmodtable = require "defs.sound.fmodtable"
local soundutil = require "util.soundutil"
local EffectEvents = require "effectevents"
---------------------------------------------------------------------------------------
-- Custom script for auto-generated prop prefabs
---------------------------------------------------------------------------------------

-- Totem specialized script for prop prefab
-- This was originally based off traps, and many functions were pulled from sg_player_hammer_skill_totem

local totem = {
	default = {},
}

function totem.default.CollectPrefabs(prefabs, args)
	table.insert(prefabs, "hammer_totem_buff")
	table.insert(prefabs, "fx_dust_up2")
	table.insert(prefabs, "fx_ground_heal_area")
	table.insert(prefabs, "skill_player_totem_spawn_rings")
	table.insert(prefabs, "skill_player_totem_death")
	table.insert(prefabs, "fx_ground_totem_area_pst")
end

local function HealKiller(inst, killer)
	if killer ~= nil and killer:IsValid() and killer.components.combat ~= nil then
		TheLog.ch.Totem:printf("Heal Killer")
		local totem_skill_def = Power.FindPowerByName("hammer_totem")
		local healthtocreate = totem_skill_def.tuning.COMMON.healthtocreate

		local power_heal = Attack(inst, killer)
		power_heal:SetHeal(healthtocreate)
		power_heal:SetSource(totem_skill_def.name)
		killer.components.combat:ApplyHeal(power_heal)
	end
end

local function KillTotem(inst, attacker)
	--cleanup loop
	if inst.owner then
		soundutil.KillSound(inst.owner, inst.owner.sg.mem.totem_snapshot_lp)
		inst.owner.sg.mem.totem_snapshot_lp = nil
	end

	TheAudio:SetGlobalParameter(fmodtable.GlobalParameter.isLocalPlayerInTotem, 0)

	--sound if you don't hear anything it's because this is -inf dB in the FMOD project
	local params = {}
	params.fmodevent = fmodtable.Event.Skill_Hammer_Totem_Death
	soundutil.PlaySoundData(inst, params)

	if inst and inst:IsValid() then
		-- need to test for valid attack data in case it was outright removed instead of killed
		-- don't allow double heals since this teardown happens on both local and remote
		if attacker and attacker:IsValid() and inst:IsLocal() then
			HealKiller(inst, attacker)
		end

		if inst.radius and inst.radius:IsValid() then
			inst.radius:Remove()
		end

		if inst.owner and inst.owner:IsLocal() then
			inst.owner.sg.mem.hammerskilltotem = nil
		end

		SGCommon.Fns.SpawnAtDist(inst, "skill_player_totem_death", 0)
		SGCommon.Fns.PlayGroundImpact(inst, { impact_size = GroundImpactFXSizes.id.Large })

		inst.components.auraapplyer:Disable()
		if inst:IsLocal() then
			inst:DoTaskInTicks(0, function()
				inst:Remove() -- need to delay like mobs to allow combat to finish
				SGCommon.Fns.SpawnAtDist(inst, "fx_ground_totem_area_pst", 0)
			end)
		end
	end
end

local function StartLoopingTotemSnapshot(inst)
	--sound
	local params = {}
	params.fmodevent = fmodtable.Event.Skill_Hammer_Totem_Snapshot_LP
	inst.owner.sg.mem.totem_snapshot_lp = soundutil.PlaySoundData(inst.owner, params)
end

local function StartBuff(inst)
	if inst.components.auraapplyer:IsEnabled() then return end
	
	inst.components.auraapplyer:Enable()

    local fx_params =
    {
        name = "totem_area",
        fxname = "fx_ground_totem_area",
        ischild = true,
        scalex = 5.5,
		scalez = 5.5,
		orientation = ANIM_ORIENTATION.OnGroundFixed,
    }

    EffectEvents.MakeEventSpawnEffect(inst, fx_params)
end

local function HandleSetup(inst, owner)
	inst.owner = owner
	StartLoopingTotemSnapshot(inst)
end

local function Setup(inst, owner)
	if inst:ShouldSendNetEvents() then
		TheSim:HandleEntitySetup(inst.GUID, owner.GUID)
	else
		HandleSetup(inst, owner)
	end
end

local function StopBuff(inst)
	inst.components.auraapplyer:Disable()
end

local function HandleTeardown(inst, attacker)
	StopBuff(inst)
	KillTotem(inst, attacker)
end

local function Teardown(inst, attacker)
	if inst:ShouldSendNetEvents() then
		TheNetEvent:EntityTeardownFunction(inst.GUID, attacker and attacker.GUID or nil)
	else
		HandleTeardown(inst, attacker)
	end
end

local function DoSpawn(inst)
	local fx = SGCommon.Fns.SpawnChildAtDist(inst, "skill_player_totem_spawn_rings", 0)
	fx:ListenForEvent("onremove", function() fx:Remove() end, inst)
	fx:DoTaskInTime(3, function(_inst)
		if fx and fx:IsValid() then
			fx:Remove()
		end
	end)
end

function totem.default.CustomInit(inst, opts)
	inst.entity:AddHitBox()

	inst:AddComponent("hitbox")
	inst.components.hitbox:SetHitGroup(HitGroup.ALL)
	inst.components.hitbox:SetHitFlags(HitGroup.ALL)

	inst:AddComponent("combat")

	inst:AddComponent("health")
	inst.components.health:SetMax(800, true)

	inst:AddComponent("powermanager")

	local totem_skill_def = Power.FindPowerByName("hammer_totem")

	inst:AddComponent("auraapplyer")
	inst.components.auraapplyer:SetEffect("hammer_totem_buff")
	inst.components.auraapplyer:SetRadius(totem_skill_def.tuning.COMMON.radius)

	-- Entity lifetime function configuration
	inst.Setup = Setup
	inst.HandleSetup = HandleSetup
	inst.Teardown = Teardown
	inst.HandleTeardown = HandleTeardown

	inst.StartBuff = StartBuff
	inst.StopBuff = StopBuff

	DoSpawn(inst)

	inst:SetStateGraph("sg_player_totem")
end

function totem.PropEdit(editor, ui, params)
    -- You can hit them, so require sound.
    params.sound = true
end

return totem
