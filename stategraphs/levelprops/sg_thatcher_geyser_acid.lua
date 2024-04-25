local SGCommon = require("stategraphs/sg_common")
local monsterutil = require "util.monsterutil"
local spawnutil = require "util.spawnutil"
--local ParticleSystemHelper = require "util.particlesystemhelper"
local EffectEvents = require "effectevents"

local function OnFallingHitBoxTriggered(inst, data)
	SGCommon.Events.OnProjectileHitboxTriggered(inst, data, {
		attackdata_id = "acid_spit",
		hitstoplevel = HitStopLevel.MEDIUM,
		hitflags = Attack.HitFlags.LOW_ATTACK,
		pushback = 1.25,
		set_dir_angle_to_target = true,
		combat_attack_fn = "DoKnockbackAttack",
		hit_fx = monsterutil.defaultAttackHitFX,
		hit_fx_offset_x = 0.5,
	})
end

local function RemoveLandFX(inst)
	if inst == nil then return end
	if inst.sg.mem.land_fx and inst.sg.mem.land_fx:IsValid() then
		inst.sg.mem.land_fx:Remove()
	end
end

local FALL_HEIGHT <const> = 45
local HEIGHT_DAMAGE_THRESHOLD <const> = 3
local ACID_TRAP_LIFETIME_FRAMES <const> = 300

local states =
{
	State({
		name = "init",
		onenter = function(inst, prefab_to_spawn)
			if not prefab_to_spawn then return end

			EffectEvents.MakeEventSpawnLocalEntity(inst, prefab_to_spawn, "fall")
			inst:DelayedRemove()
		end,
	}),

	State({
		name = "idle",
		onenter = function(inst)
			inst.sg:SetTimeoutTicks(1)
		end,
		ontimeout = function(inst)
			-- This is placed here to allow for proper functionality if we directly debug spawn thatcher_geyser_acid_local.
			-- Spawning thatcher_geyser_acid should automatically enter the init state.
			inst.sg:GoToState("fall")
		end,
	}),

	State({
		name = "fall",
		tags = { "airborne_high", "airborne", "falling" },
		onenter = function(inst)
			inst.AnimState:PlayAnimation("acid_geyser_blob", true)

			-- Set to fall from above
			inst.components.fallingobject:SetLaunchHeight(FALL_HEIGHT)
			inst.components.fallingobject:SetGravity(-80)
			inst.components.fallingobject:Launch()

			-- Spawn ground target (temp? replace with a single shadow FX?)
			local x, y, z = inst.Transform:GetWorldPosition()
			local land_fx = SpawnPrefab("fx_ground_target_red_local", inst)
			local scale = inst.sg.mem.is_medium and 1 or 1.5
			land_fx.AnimState:SetScale(scale, scale, scale)
			land_fx.Transform:SetPosition( x, 0, z )
			inst.sg.mem.land_fx = land_fx

			inst.components.fallingobject:SetOnLand(RemoveLandFX)

			inst.components.hitbox:StartRepeatTargetDelay()
		end,

        events =
		{
            EventHandler("hitboxtriggered", OnFallingHitBoxTriggered),
			EventHandler("landed", function(inst)
				inst.sg:GoToState("land")
			end),
		},

        onupdate = function(inst)
			local pos = inst:GetPosition()
			if pos.y <= HEIGHT_DAMAGE_THRESHOLD and inst.sg:HasStateTag("falling") then
				inst.sg:RemoveStateTag("airborne_high")
				local radius = inst.sg.mem.is_medium and 1 or 1.5
				inst.components.hitbox:PushCircle(0.00, 0.00, radius, HitPriority.MOB_PROJECTILE)
			end
        end,

        onexit = function(inst)
			inst.components.hitbox:StopRepeatTargetDelay()
        end,
	}),

	State({
		name = "land",
		tags = { "idle" },

		onenter = function(inst)
			--inst.AnimState:SetScale(2, 2) -- Temp: remove later when proper art is in!

			--inst.AnimState:PlayAnimation("acid_geyser_blob_impact")
			inst.components.hitbox:StartRepeatTargetDelay()

			-- Spawn acid upon landing.
			if TheNet:IsHost() then
				local acid_size = "large"
				if inst.sg.mem.is_boss_acid then
					-- TODO: Clean this up once new acid is finalized
					--acid_size = "boss_permanent" -- Uncomment this & comment out below for old acid
					SGCommon.Fns.SpawnAtDist(inst, "trap_acid_stage", 0)
					return
				elseif inst.sg.mem.is_medium then
					acid_size = "medium"
				end

				local trap_lifetime = not inst.sg.mem.is_permanent and ACID_TRAP_LIFETIME_FRAMES or nil

				spawnutil.SpawnAcidTrap(inst, acid_size, trap_lifetime)
			end
		end,

		timeline =
		{
			FrameEvent(0, function(inst)
				local radius = inst.sg.mem.is_medium and 1.6 or 3.2
				inst.components.hitbox:PushCircle(0.00, 0.00, radius, HitPriority.MOB_PROJECTILE)
			end),
			FrameEvent(1, function(inst)
				local radius = inst.sg.mem.is_medium and 1.6 or 3.2
				inst.components.hitbox:PushCircle(0.00, 0.00, radius, HitPriority.MOB_PROJECTILE)
			end),
		},

        events =
		{
			EventHandler("hitboxtriggered", OnFallingHitBoxTriggered),
			EventHandler("animover", function(inst)
				inst.sg:GoToState("dead")
			end),
		},

		onexit = function(inst)
			inst.components.hitbox:StopRepeatTargetDelay()
		end
	}),

	State({
		name = "dead",
		tags = { "idle" },

		onenter = function(inst)
			inst:Hide()
			inst:DelayedRemove()
		end,
	}),
}

return StateGraph("sg_thatcher_geyser_acid", states, nil, "idle")
