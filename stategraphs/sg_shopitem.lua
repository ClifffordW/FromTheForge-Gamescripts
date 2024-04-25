local SGCommon = require "stategraphs.sg_common"
local Enum = require "util.enum"
local Strict = require "util.strict"
local Power = require "defs.powers"
local ParticleSystemHelper = require "util.particlesystemhelper"

local STATES = Enum {
	"spawn",
	"idle",
	"despawn"
}

local STANDARD_ANIMATIONS <const> = {
	[STATES.s.spawn] = "pop",
	[STATES.s.idle] = "idle",
	[STATES.s.despawn] = "shatter",
}
Strict.strictify(STANDARD_ANIMATIONS)

local ALTERNATE_ANIMATIONS <const> = {
	[STATES.s.spawn] = "pop",
	[STATES.s.idle] = "idle",
	[STATES.s.despawn] = "despawn",
}
Strict.strictify(ALTERNATE_ANIMATIONS)


-- Do not strictify these, because we want to be able to check if one is nil.
local TEASER_PARTICLES = {
	[Power.Rarity.COMMON] = nil,
	[Power.Rarity.EPIC] = "power_drop_glow_epic_teaser",
	[Power.Rarity.LEGENDARY] = "power_drop_glow_legendary_teaser",
}
local ATTACHED_PARTICLES = {
	[Power.Rarity.COMMON] = "power_drop_generic",
	[Power.Rarity.EPIC] = "power_drop_glow_epic",
	[Power.Rarity.LEGENDARY] = "power_drop_glow_legendary",
}
local DESPAWN_PARTICLES = {
	[Power.Rarity.COMMON] = "power_drop_generic_despawn",
	[Power.Rarity.EPIC] = "power_drop_glow_epic_despawn",
	[Power.Rarity.LEGENDARY] = "power_drop_glow_legendary_despawn",
}

local function PlayAnimForState(inst, state, loop)
	local anim = inst.sg.mem.use_alternate_anims
		and ALTERNATE_ANIMATIONS[state]
		or STANDARD_ANIMATIONS[state]
	TheLog.ch.AnimSpam:printf("sg_shopitem:PlayAnim() %s -> %s", state, anim)
	SGCommon.Fns.PlayAnimOnAllLayers(inst, anim, loop)
end

-- This state graph is induced locally for the despawn state. When this occurs, the local instance has lost all state
-- that the original host-owned state graph had: do our best to resurrect that state.
local function InitializeForLocalPlayback(inst, params)
	local interactable = inst.components.interactable
	if interactable then
		interactable:SetInteractCondition_Never()
	end

	local source_ware_visualizer = params.instigator.components.warevisualizer
	if source_ware_visualizer then
		inst:PushEvent("initialized_ware", {
			ware_name = source_ware_visualizer.ware_name,
			power = source_ware_visualizer.power,
			power_type = source_ware_visualizer.power_type
		})
	end
end

local function OnHitBoxTriggered(inst, data)
	-- If it lands on any prop or anything, clear it out.
	local hit = SGCommon.Events.OnHitboxTriggered(inst, data, {
		attackdata_id = "pierce",
		hitstoplevel = inst:HasTag("elite") and HitStopLevel.HEAVY or HitStopLevel.LIGHT,
		pushback = 0,
		damage_override = 1000,
		disable_damage_number = true,
		hitstun_anim_frames = 0,
		combat_attack_fn = "DoBasicAttack",
		ignore_tags = { "player", "mob" },
	})
end

local events =
{
	EventHandler("despawn", function(inst) inst.sg:GoToState(STATES.s.despawn) end),
	EventHandler("spawned_local_entity", function(inst, params) InitializeForLocalPlayback(inst, params) end),
}

local states =
{
	State({
		name = STATES.s.spawn,
		tags = { "busy" },

		onenter = function(inst)
			PlayAnimForState(inst, STATES.s.spawn)
		end,

		timeline =
		{
			FrameEvent(1, function(inst)
				if inst.components.warevisualizer and inst.components.warevisualizer.rarity then
					inst.sg.mem.rarity = inst.components.warevisualizer.rarity

					if TEASER_PARTICLES[inst.sg.mem.rarity] then
						ParticleSystemHelper.MakeEventSpawnParticles(inst, { name = "power_drop_teaser_particles", particlefxname = TEASER_PARTICLES[inst.sg.mem.rarity], ischild = true, followsymbol = "swap_fx", offz = -0.5 })
					end

					if ATTACHED_PARTICLES[inst.sg.mem.rarity] then
						ParticleSystemHelper.MakeEventSpawnParticles(inst, { name = "power_drop_attached_particles", particlefxname = ATTACHED_PARTICLES[inst.sg.mem.rarity], ischild = true, followsymbol = "swap_fx", offz = -0.1 })
					end
				end
			end),

			-- Push some hitboxes as it lands, so that it clears out any props or traps that were there.
			FrameEvent(17, function(inst)
				inst.components.hitbox:PushCircle(0, 0, 3, HitPriority.MOB_DEFAULT)
			end),
			FrameEvent(18, function(inst)
				inst.components.hitbox:PushCircle(0, 0, 3, HitPriority.MOB_DEFAULT)
			end),
			FrameEvent(19, function(inst)
				inst.components.hitbox:PushCircle(0, 0, 3, HitPriority.MOB_DEFAULT)
			end),
		},

		events =
		{
			EventHandler("animover", function(inst)
				inst.sg:GoToState(STATES.s.idle)
			end),

			EventHandler("hitboxtriggered", OnHitBoxTriggered),
		},
	}),

	State({
		name = STATES.s.idle,
		tags = { "idle" },

		onenter = function(inst)
			PlayAnimForState(inst, STATES.s.idle, true)
			-- enable interaction
		end,

		onexit = function(inst)
			ParticleSystemHelper.MakeEventStopParticles(inst, { name = "power_drop_teaser_particles" })
			ParticleSystemHelper.MakeEventStopParticles(inst, { name = "power_drop_attached_particles" })
		end,
	}),

	State({
		name = STATES.s.despawn,
		tags = { "busy", "despawning" },

		onenter = function(inst)
			PlayAnimForState(inst,  STATES.s.despawn)

			if inst.sg.mem.rarity and DESPAWN_PARTICLES[inst.sg.mem.rarity] then
				ParticleSystemHelper.MakeOneShotAtPosition(inst:GetPosition(), DESPAWN_PARTICLES[inst.sg.mem.rarity], 3, inst, { offz = -0.1 })
			end
		end,

		events =
		{
			EventHandler("animover", function(inst)
				inst:DelayedRemove()
			end),
		},
	}),
}

SGRegistry:AddData("sg_shopitem", states)

return StateGraph("sg_shopitem", states, events, STATES.s.spawn)
