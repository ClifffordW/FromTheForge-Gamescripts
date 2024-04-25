local bossutil = require "prefabs.bossutil"
local monsterutil = require "util.monsterutil"
local spawnutil = require "util.spawnutil"
local fmodtable = require "defs.sound.fmodtable"
local SGCommon = require("stategraphs/sg_common")

local assets =
{
	Asset("ANIM", "anim/thatcher_bank.zip"),
	Asset("ANIM", "anim/thatcher_build.zip"),
	Asset("ANIM", "anim/fx_shadow.zip"),
}

local prefabs =
{
	"fx_hurt_sweat",
	"fx_death_thatcher",
	GroupPrefab("fx_acid"),

	"thatcher_acidball",
	"trap_acid",
	"trap_acid_stage",

	"cine_boss_death_hit_hold",
	"cine_thatcher_death",
	"cine_thatcher_intro",

	--Drops
	GroupPrefab("drops_generic"),
	GroupPrefab("drops_thatcher"),
}

local FIRST_PHASE = 1
local SECOND_PHASE = 2
local THIRD_PHASE = 3

local attacks =
{
	swing_short =
	{
		priority = 1,
		damage_mod = 1.0,
		startup_frames = 16,
		cooldown = 2,
		initialCooldown = 1,
		pre_anim = "swing_short_pre",
		is_hitstun_pressure_attack = true,
		hitstun_pressure_attack_condition_fn = function(inst)
			local current_phase = inst.boss_coro:CurrentPhase()
			return current_phase == SECOND_PHASE
		end,
		start_conditions_fn = function(inst, data, trange)
			local current_phase = inst.boss_coro:CurrentPhase()
			return current_phase == SECOND_PHASE and trange:IsInRange(6)
		end,
	},

	swing_long =
	{
		priority = 1,
		damage_mod = 1.0,
		startup_frames = 24,
		cooldown = 2,
		initialCooldown = 1,
		pre_anim = "swing_short_pre",
		is_hitstun_pressure_attack = true,
		hitstun_pressure_attack_condition_fn = function(inst)
			local current_phase = inst.boss_coro:CurrentPhase()
			return current_phase == FIRST_PHASE
		end,
		start_conditions_fn = function(inst, data, trange)
			local current_phase = inst.boss_coro:CurrentPhase()
			return current_phase == FIRST_PHASE and trange:IsInRange(6)
		end,
	},

	swing_uppercut =
	{
		priority = 1,
		damage_mod = 1.2,
		start_conditions_fn = function(inst, data, trange)
			return false -- Follow-up attack from swing_short
		end,
	},

	-- Acid projectiles will reference this attack for its damage_mod!
	acid_spit =
	{
		priority = 2,
		damage_mod = 0.3,
		startup_frames = 32,
		cooldown = 4,
		initialCooldown = 12,
		pre_anim = "acid_pre",
		hold_anim = "acid_hold",
		start_conditions_fn = function(inst, data, trange)
			local current_phase = inst.boss_coro:CurrentPhase()
			return current_phase <= FIRST_PHASE
		end,
	},

	--[[hook =
	{
		priority = 1,
		damage_mod = 0.8,
		startup_frames = 27,
		cooldown = 3,
		initialCooldown = 2,
		pre_anim = "hook_pre",
		hold_anim = "hook_hold",
		start_conditions_fn = function(inst, data, trange)
			return false -- Phase 2 special attack called via the boss coroutine.
		end,
	},

	hook_uppercut =
	{
		priority = 1,
		damage_mod = 1.2,
		start_conditions_fn = function(inst, data, trange)
			return false -- Follow-up attack from hook
		end,
	},]]

	double_short_slash =
	{
		priority = 1,
		damage_mod = 1,
		startup_frames = 28,
		cooldown = 3,
		initialCooldown = 3,
		is_hitstun_pressure_attack = true,
		hitstun_pressure_attack_condition_fn = function(inst)
			local current_phase = inst.boss_coro:CurrentPhase()
			return current_phase == THIRD_PHASE
		end,
		pre_anim = "double_short_slash_pre",
		hold_anim = "double_short_slash_hold",
		start_conditions_fn = function(inst, data, trange)
			local current_phase = inst.boss_coro:CurrentPhase()
			return current_phase == THIRD_PHASE and trange:IsInRange(15)
		end,
	},

	--[[full_swing =
	{
		cooldown = 0,
		damage_mod = 0.3,
		startup_frames = 44,
		pre_anim = "full_swing_pre",
		hold_anim = "full_swing_loop",
		start_conditions_fn = function(inst, data, trange)
			return false -- Phase 1 special attack called via the boss coroutine.
		end,
	},]]

	full_swing_mobile =
	{
		cooldown = 0,
		damage_mod = 0.4,
		startup_frames = 90,
		pre_anim = "full_swing_mobile_pre",
		hold_anim = "full_swing_mobile_loop",
		loop_hold_anim = true,
		start_conditions_fn = function(inst, data, trange)
			return false -- Phase 1 special attack called via the boss coroutine.
		end,
	},

	dash_uppercut =
	{
		cooldown = 0,
		damage_mod = 1.2,
		startup_frames = 90,
		pre_anim = "shoryuken_pre",
		hold_anim = "shoryuken_loop",
		loop_hold_anim = true,
		start_conditions_fn = function(inst, data, trange)
			return false -- Phase 2 special attack called via the boss coroutine.
		end,
	},

	swing_smash =
	{
		priority = 1,
		damage_mod = 1.3,
		startup_frames = 90,
		cooldown = 5,
		initialCooldown = 3,
		pre_anim = "swing_smash_pre",
		hold_anim = "swing_smash_loop",
		loop_hold_anim = true,
		start_conditions_fn = function(inst, data, trange)
			return false -- Phase 3 special attack called via the boss coroutine.
		end,
	},

	--[[acid_coating =
	{
		start_conditions_fn = function(inst, data, trange)
			return false -- Special attack called via the boss coroutine.
		end,
	},]]

	acid_splash =
	{
		priority = 1,
		damage_mod = 0.3,
		startup_frames = 41,
		cooldown = 0,
		pre_anim = "acid_splash_pre",
		hold_anim = "acid_splash_hold",
		start_conditions_fn = function(inst, data, trange)
			return false -- Special attack called via the boss coroutine.
		end,
	},
}
export_timer_names_grab_attacks(attacks) -- This needs to be here to extract the names of cooldown timers for the network strings


--[[local function CreateHeadHitBox()
	local inst = CreateEntity()

	inst.entity:AddTransform()
	inst.entity:AddHitBox()

	inst:AddTag("CLASSIFIED")

	inst.persists = false

	inst.HitBox:SetNonPhysicsRect(1.8)
	inst.HitBox:SetEnabled(false)

	return inst
end]]

--[[local function RetargetFn(inst)
	if inst.sg:HasStateTag("dormant") then
		return
	end

	local target = inst.components.combat:GetTarget()
	if target == nil then
		target = inst:GetClosestPlayerInRange(12, true)
	elseif not inst:IsNear(target, 12) then
		target = inst:GetClosestPlayerInRange(4, true)
	end
	return target
end]]

local function OnCombatTargetChanged(inst, data)
	if data.old == nil and data.new ~= nil then
		inst.boss_coro:Start()
	end
end

local MONSTER_SIZE = 1.9

local function fn(prefabname)
	local inst = CreateEntity()
	inst:SetPrefabName(prefabname)

	monsterutil.MakeBasicMonster(inst, MONSTER_SIZE, monsterutil.MonsterSize.GIANT)

	inst.AnimState:SetBank("thatcher_bank")
	inst.AnimState:SetBuild("thatcher_build")

	TheFocalPoint.components.focalpoint:StartFocusSource(inst, FocusPreset.BOSS)

	monsterutil.AddOffsetHitbox(inst, 1.8)

	inst.components.combat:SetFrontKnockbackOnly(true)
	inst.components.combat:SetVulnerableKnockdownOnly(true)
	inst.components.combat:SetBlockKnockback(true)

	inst.components.attacktracker:AddAttacks(attacks)

	inst:SetStateGraph("sg_thatcher")
	inst:SetBrain("brain_thatcher")
	inst:SetBossCoro("bc_thatcher")

	monsterutil.ExtendToBossMonster(inst)

	inst:ListenForEvent("combattargetchanged", OnCombatTargetChanged)
	bossutil.SetupLastPlayerDeadEventHandlers(inst)

	inst:AddComponent("monstertranslator")

	inst:AddTag("ACID_IMMUNE")

	inst:AddComponent("cineactor")
	inst.components.cineactor:AfterEvent_PlayAsLeadActor("dying", "cine_boss_death_hit_hold", { "cine_thatcher_death" })
	inst.components.cineactor:QueueIntro("cine_thatcher_intro")

	---foleysounder
	inst.components.foleysounder:SetFootstepSound(fmodtable.Event.thatcher_footstep)
	inst.components.foleysounder:SetBodyfallSound(fmodtable.Event.thatcher_bodyfall)
	inst.components.foleysounder:SetFootstepStopSound(fmodtable.Event.thatcher_footstep_stop)
	-- inst.components.foleysounder:SetHitStartSound(fmodtable.Event.AAAA_default_event)
 --    inst.components.foleysounder:SetKnockbackStartSound(fmodtable.Event.AAAA_default_event)
 --    inst.components.foleysounder:SetKnockdownStartSound(fmodtable.Event.AAAA_default_event)

	return inst
end

---------------------------------------------------------------------------------------
-- Acid projectile
local acid_prefabs =
{
	--GroupPrefab("fx_battoad"),
	"fx_ground_target_red",
	"fx_thatcher_acid_blob",
	GroupPrefab("fx_acid"),
}

local debug_thatcher
local function OnEditorSpawn_dosetup(inst, editor)
	debug_thatcher = debug_thatcher or DebugSpawn("thatcher")
	debug_thatcher:Stupify("OnEditorSpawn")
	inst:Setup(debug_thatcher)
	debug_thatcher.Physics:SetEnabled(false)
	debug_thatcher:Hide()
end

local function acid_fn(prefabname)
	local inst = spawnutil.CreateComplexProjectile(
	{
		name = prefabname,
		hits_targets = true,
		stategraph = "sg_thatcher_acidball",
		fx_prefab = "fx_thatcher_acid_blob",
	})

	local scale = (math.random() - 0.5) * 0.4 + 0.8 -- 0.8 +/- 0.2
	inst.AnimState:SetScale(scale, scale) -- random scale to add some visual variance with spawned acid projectiles

	inst.Setup = monsterutil.BasicProjectileSetup
	inst.OnEditorSpawn = OnEditorSpawn_dosetup

	return inst
end

---------------------------------------------------------------------------------------
-- Geyser acid projectile
local function geyser_acid_local_fn(prefabname)
	local inst = spawnutil.CreateProjectile(
	{
		name = prefabname,
		hits_targets = true,
		hit_group = HitGroup.NONE,
		hit_flags = HitGroup.CHARACTERS,
		no_healthcomponent = true,
		stategraph = "levelprops/sg_thatcher_geyser_acid",
		fx_prefab = "fx_acid_projectile",
		motor_vel = 0,
	})

	inst.Setup = monsterutil.BasicProjectileSetup

	inst.AnimState:SetScale(2, 2) -- Temp(?): should we scale the actual FX instead?

	inst.Physics:SetSnapToGround(false)
	inst.Physics:SetEnabled(false)

	inst.components.combat:SetBaseDamage(inst, TUNING.TRAPS["trap_acid"].BASE_DAMAGE)

	inst:AddComponent("fallingobject")

	inst.OnSetSpawnInstigator = function(_, instigator)
		-- Set the owner if it isn't a trap that spawns stalactites (e.g. Thatcher)
		local has_owner = instigator and instigator.owner and not instigator.owner:HasTag("trap")
		inst.owner = has_owner and instigator.owner or nil
	end

	inst.OnEditorSpawn = OnEditorSpawn_dosetup

	return inst
end

local function geyser_acid_medium_local_fn(prefabname)
	local inst = geyser_acid_local_fn(prefabname)
	inst.sg.mem.is_medium = true
	return inst
end

local function geyser_acid_permanent_local_fn(prefabname)
	local inst = geyser_acid_local_fn(prefabname)
	inst.sg.mem.is_permanent = true
	inst.sg.mem.is_boss_acid = true
	return inst
end

local function geyser_acid_fn(prefabname)
	-- For networking, spawn local versions of this on each networked machine.
	local inst = CreateEntity()
	inst:SetPrefabName(prefabname)

	inst.entity:AddTransform()
	inst.entity:AddAnimState()

	inst.AnimState:SetBank("fx_acid")
	inst.AnimState:SetBuild("fx_acid")

	inst:SetStateGraph("levelprops/sg_thatcher_geyser_acid")

	inst.OnSetSpawnInstigator = function(_, instigator)
		inst.owner = instigator ~= nil and instigator.components.combat and instigator or nil
	end

	-- Delay until the next update so that everything is initialized.
	inst:DoTaskInTime(0, function()
		local acid_prefab = "thatcher_geyser_acid_local"
		if inst.sg.mem.is_permanent then
			acid_prefab = "thatcher_geyser_acid_permanent_local"
		elseif inst.sg.mem.is_medium then
			acid_prefab = "thatcher_geyser_acid_medium_local"
		end
		inst.sg:GoToState("init", acid_prefab)
	end)

	return inst
end

---------------------------------------------------------------------------------------

return Prefab("thatcher", fn, assets, prefabs, nil, NetworkType_HostAuth)
	, Prefab("thatcher_acidball", acid_fn, nil, acid_prefabs, nil, NetworkType_HostAuth)
	, Prefab("thatcher_geyser_acid_local", geyser_acid_local_fn, assets, prefabs, nil, NetworkType_Minimal)
	, Prefab("thatcher_geyser_acid_medium_local", geyser_acid_medium_local_fn, assets, prefabs, nil, NetworkType_Minimal)
	, Prefab("thatcher_geyser_acid_permanent_local", geyser_acid_permanent_local_fn, assets, prefabs, nil, NetworkType_Minimal)
	, Prefab("thatcher_geyser_acid", geyser_acid_fn, nil, acid_prefabs, nil, NetworkType_SharedHostSpawn)
