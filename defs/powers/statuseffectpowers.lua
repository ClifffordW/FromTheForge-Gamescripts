local Power = require("defs.powers.power")
local lume = require "util.lume"
local SGCommon = require "stategraphs.sg_common"
local monsterutil = require "util.monsterutil"
local audioid = require "defs.sound.audioid"
local fmodtable = require "defs.sound.fmodtable"
local soundutil = require "util.soundutil"
local powerutil = require "util.powerutil"
local ParticleSystemHelper = require "util.particlesystemhelper"

--local DebugDraw = require "util.debugdraw"

function Power.AddStatusEffectPower(id, data)
	if not data.power_category then
		data.power_category = Power.Categories.SUSTAIN
	end

	if data.clear_on_new_room then
		local previous_trigger = data.event_triggers ~= nil and data.event_triggers["exit_room"] or nil

		if data.event_triggers == nil then
			data.event_triggers = {}
		elseif previous_trigger ~= nil then
			print ("POWER ALREADY HAS AN EXIT ROOM TRIGGER EVENT, ATTEMPTING MERGE")
		end

		data.event_triggers["exit_room"] = function(pow, inst, data)
			if previous_trigger then
				previous_trigger(pow, inst, data)
			end
			inst.components.powermanager:RemovePower(pow.def, true)
		end
	end

	data.power_type = Power.Types.RELIC
	data.show_in_ui = false
	data.can_drop = false

	Power.AddPower(Power.Slots.STATUSEFFECT, id, "statuseffectpowers", data)
end

Power.AddPowerFamily("STATUSEFFECT", nil, 8)

local function PlaySmallifySound(inst)
	local params = {}
	local soundevent = fmodtable.Event.status_smallify_enemy
	if inst:HasTag("player") then
		soundevent = fmodtable.Event.status_smallify_friendly
	end
	params.fmodevent = soundevent
	params.sound_max_count = 3 -- intentional, we mean to track this
	soundutil.PlaySoundData(inst, params)
end

Power.AddStatusEffectPower("smallify",
{
	power_category = Power.Categories.SUPPORT,
	clear_on_new_room = true,

	tuning =
	{
		[Power.Rarity.COMMON] = { scale = 75, speed = 150, damage = 150 },
	},

	on_add_fn = function(pow, inst)
		if inst.components.scalable ~= nil then
			inst.components.scalable:AddScaleModifier(pow, pow.persistdata:GetVar("scale") * 0.01)
		end
		if inst.components.locomotor ~= nil then
			inst.components.locomotor:AddSpeedMult(pow.def.name, pow.persistdata:GetVar("speed") * 0.01)
		end
		inst.components.combat:SetDamageReceivedMult("smallify", pow.persistdata:GetVar("damage") * 0.01)
		PlaySmallifySound(inst)

		if inst.components.weight then
			inst.components.weight:AddWeightAddModifier("smallify", -10)
		end
		inst.SoundEmitter:SetPitchMultiplier(soundutil.PitchMult.id.SizeMushroom, 2)
	end,

	on_remove_fn = function(pow, inst)
		if inst.components.scalable ~= nil then
			inst.components.scalable:RemoveScaleModifier(pow)
		end
		if inst.components.locomotor ~= nil then
			inst.components.locomotor:RemoveSpeedMult(pow.def.name)
		end
		inst.components.combat:SetDamageReceivedMult("smallify", nil)

		if inst.components.weight then
			inst.components.weight:RemoveWeightAddModifier("smallify")
		end

		inst.SoundEmitter:SetPitchMultiplier(soundutil.PitchMult.id.SizeMushroom, 1)
	end,
})

local function RemoveJuggernautStacks(inst, pow)
	local remove_stack

	remove_stack = function(ent)
		ent.components.powermanager:DeltaPowerStacks(pow.def, -1)
		if ent.components.powermanager:GetPowerStacks(pow.def) > 0 then
			ent:DoTaskInTime(0.0667, remove_stack)
		end
	end

	remove_stack(inst)
end

local JUGGERNAUT_SIZE_GAIN_SEQUENCE =
{
	-- How much of the bonus size is added per frame while we transition from OLDSCALE to FINALSCALE
	0.5,
	0.5,
	0,
	0,
	0.5,
	0.5,
	0,
	0,
	0.5,
	0.5,
	0,
	0,
	0.5,
	0.5,
	1,
	1,
	0.5,
	0.5,
	1,
	1,
	1,
	1,
}

local function GetBonusSizeForAnimFrame(originalscale, finalsize, frame)
	return JUGGERNAUT_SIZE_GAIN_SEQUENCE[frame] * (finalsize - originalscale)
end

local function GainJuggernautSequence(inst, originalscale, finalscale, frame, pow)
	if pow.mem.force_remove_requested then
		return
	end

	if frame >= #JUGGERNAUT_SIZE_GAIN_SEQUENCE then
		-- Sequence Complete!
		inst.components.scalable:AddScaleModifier(pow, finalscale, pow)
		inst.SoundEmitter:SetPitchMultiplier(soundutil.PitchMult.id.SizeMushroom, 0.75)
		return
	end

	local bonus_size = GetBonusSizeForAnimFrame(originalscale, finalscale, frame)
	inst.components.scalable:AddScaleModifier(pow, originalscale + bonus_size, pow)

	-- print(frame, originalscale, finalscale, bonus_size)

	frame = frame + 1
	inst:DoTaskInAnimFrames(1, function() GainJuggernautSequence(inst, originalscale, finalscale, frame, pow) end)
end

local function PlayJuggernautSound(inst, pow)
	local params = {}
	local soundevent = fmodtable.Event.status_juggernaut_apply
	-- under the gun and not splitting these up for right now

	-- if inst:HasTag("player") then
	-- 	soundevent = fmodtable.Event.status_juggernaut_apply
	-- end
	params.fmodevent = soundevent
	soundutil.PlaySoundData(inst, params)
end

Power.AddStatusEffectPower("juggernaut",
{
	power_category = Power.Categories.DAMAGE,
	tuning = {
		[Power.Rarity.LEGENDARY] = {
			damage = 1,
			scale = 1,
			damagereceivedmult = 0.5, -- 0.5% per stack -- maximum 100 stacks = 50% damage reduction
			speed = -0.7, -- 0.7% per stack, maximum reduction of -70%
			nointerruptstacks = 50, -- TODO #weight set this back to 25 or 50?
			knockdownstacks = 50,
		},
	},

	stackable = true,
	can_drop = false,
	selectable = false,
	clear_on_new_room = true,
	max_stacks = 100,

	on_add_fn = function(pow, inst)
		if inst.components.weight then
			inst.components.weight:AddWeightAddModifier("juggernaut", 10)
		end
	end,

	on_remove_fn = function(pow, inst)
		if inst.components.scalable ~= nil then
			inst.components.scalable:RemoveScaleModifier(pow)
		end
		inst.components.combat:RemoveDamageDealtMult(pow)
		inst.components.combat:SetDamageReceivedMult("superarmor", nil)

		if inst.components.locomotor then
			inst.components.locomotor:RemoveSpeedMult(pow.def.name)
		end

		if inst.components.weight then
			inst.components.weight:RemoveWeightAddModifier("juggernaut")
		end

		inst.SoundEmitter:SetPitchMultiplier(soundutil.PitchMult.id.SizeMushroom, 1)
	end,

	on_stacks_changed_fn = function(pow, inst, delta)
		-- TODO #weight figure out how much of this DamageDealt, DamageReceived, and Speed mults is inherent to 'weight', if any?

		if pow.mem.force_remove_requested then
			return
		end

		if inst.components.scalable ~= nil then
			if delta > 0 then
				local originalscale = inst.components.scalable:GetTotalScaleModifier()
				local newscale = 1 + (pow.persistdata.stacks * pow.persistdata:GetVar("scale") * 0.01)
				inst.components.hitstopper:PushHitStop(#JUGGERNAUT_SIZE_GAIN_SEQUENCE) -- Hitstop for an amount of frames it takes to do the whole sequence
				GainJuggernautSequence(inst, originalscale, newscale, 1, pow)
				PlayJuggernautSound(inst, pow)
			else
				inst.components.scalable:AddScaleModifier(pow, 1 + (pow.persistdata.stacks * pow.persistdata:GetVar("scale") * 0.01))
			end
		end
		inst.components.combat:SetDamageDealtMult(pow, 1 + (pow.persistdata.stacks * pow.persistdata:GetVar("damage") * 0.01))

		if inst.components.locomotor then
			inst.components.locomotor:AddSpeedMult(pow.def.name, pow.persistdata.stacks * pow.persistdata:GetVar("speed") * 0.01)
		end

		if inst.components.combat then
			local damage_mult = pow.persistdata.stacks * pow.persistdata:GetVar("damagereceivedmult") * 0.01
			inst.components.combat:SetDamageReceivedMult("superarmor", 1 - damage_mult)
		end
	end,

	damage_mod_fn = function(pow, attack, output_data)
		-- TODO: this doesn't work, because the attack function is already being run at this point. need to find some other way to make juggernaut hits all knock down.
		if pow.persistdata.stacks >= pow.persistdata:GetVar("knockdownstacks") then
			attack:SetIsKnockdown(true)
			attack:SetForceKnockdown(true)
		end
	end,

	remote_event_triggers =
	{
		room_complete = {
			fn = function(pow, inst, source, data)
				RemoveJuggernautStacks(inst, pow)
			end,
			source = function() return TheWorld end,
		},
	},

	event_triggers = {
		["newstate"] = function(pow, inst, data)
			if pow.persistdata.stacks >= pow.persistdata:GetVar("nointerruptstacks") then
				inst.sg:AddStateTag("nointerrupt")
			end
		end,

		["juggernaut_force_remove"] = function(pow, inst)
			pow.mem.force_remove_requested = true
			inst.components.powermanager:RemovePower(pow.def, true)
		end,
	}
})

Power.AddStatusEffectPower("freeze",
{
	power_category = Power.Categories.SUPPORT,
	clear_on_new_room = true,

	tuning =
	{
		[Power.Rarity.COMMON] = { time = 10 },
	},

	on_add_fn = function(pow, inst)
		pow.mem.original_mass = inst.Physics:GetMass()
		pow.mem.original_saturation = inst.AnimState:GetSaturation()

		SGCommon.Fns.SetSaturationOnAllLayers(inst, 0)

		inst.Physics:SetMass(0.1)

		inst:Pause()
		pow:StartPowerTimer(inst)
	end,

	on_remove_fn = function(pow, inst)
		inst.components.timer:StopTimer(pow.def.name)
		inst.Physics:SetMass(pow.mem.original_mass)
		SGCommon.Fns.SetSaturationOnAllLayers(inst,pow.mem.original_saturation)
		inst:Resume()
	end,

	event_triggers = {
		["timerdone"] = function(pow, inst, data)
			if data.name == pow.def.name then
				inst.components.powermanager:RemovePower(pow.def, true)
			end
		end,

		["attacked"] = function (pow, inst, data)
			inst.components.timer:StopTimer(pow.def.name)
			inst.components.powermanager:RemovePower(pow.def, true)
		end,
	}
})

Power.AddStatusEffectPower("poison",
{
	power_category = Power.Categories.DAMAGE,
	clear_on_new_room = true,

	tuning =
	{
		[Power.Rarity.COMMON] = { tick_time = 1, duration = 10, damage = 25 },
	},

	on_add_fn = function(pow, inst)
		pow.mem.tick_time_elapsed  = 0
		pow.mem.total_time_elapsed = 0

		pow.mem.tick_time = pow.persistdata:GetVar("tick_time")
		pow.mem.duration  = pow.persistdata:GetVar("duration")
		pow.mem.damage    = pow.persistdata:GetVar("damage")
	end,

	on_update_fn = function(pow, inst, dt)
		pow.mem.tick_time_elapsed = pow.mem.tick_time_elapsed + dt
		pow.mem.total_time_elapsed = pow.mem.total_time_elapsed + dt

		if pow.mem.tick_time_elapsed > pow.mem.tick_time then
			pow.mem.tick_time_elapsed = 0

			local poison_dmg = Attack(inst, inst)
			poison_dmg:SetDamage(pow.mem.damage)
			poison_dmg:SetIgnoresArmour(true)
			inst.components.combat:ApplyDamage(poison_dmg)
		end

		if pow.mem.total_time_elapsed >= pow.mem.duration then
			inst.components.powermanager:RemovePower(pow.def, true)
		end
	end
})

--------------------------------------------------------------------------
-- Hitstun pressure attack power

local HITSTUN_FRAMES_NR_BITS <const> = 8 -- Increase if there's an entity that takes in more than 256 frames of hitstun.
local HITSTUN_PRE_COOLDOWN_DELAY <const> = 0.2 -- Number of seconds to delay before cooling down hitstun pressure frames.

local function StartHitStunPressureCooldownDelay(pow, inst)
	local timer = inst.components.timer
	assert(timer, "Entity [" .. inst.prefab .. "] Does not have a timer component. Please add a timer component to the entity.")

	if timer:HasTimer(pow.def.name) then
		timer:SetTimeRemaining(pow.def.name, HITSTUN_PRE_COOLDOWN_DELAY)
	else
		inst.components.timer:StartTimer(pow.def.name, HITSTUN_PRE_COOLDOWN_DELAY)
	end

	pow.mem.is_in_cooldown = nil
	pow.mem._ontimerdonefn = function(_, data)
		if data and data.name == pow.def.name then
			pow.mem.is_in_cooldown = true
		end
	end
    inst:ListenForEvent("timerdone", pow.mem._ontimerdonefn)
end

local function OnHitStunPressureAttack(pow, inst, data)
	if not TheNet:IsHost() then
		return
	end

	assert(inst.components.combat, "Entity [" .. inst.prefab .. "] Does not have a combat component. Please add a combat component to the entity.")

	-- Add hitstun frames to the pressure buffer.
	local attack = data and data.attack
	local hitstunframes = attack and attack:GetHitstunAnimFrames() or 0
	pow.mem.current_hitstun_frames = pow.mem.current_hitstun_frames + hitstunframes
	--print("attacked by: ", attack:GetAttacker(), pow.mem.current_hitstun_frames, "/", inst.components.combat:GetHitStunPressureFrames())
	--printf_world(inst, "HITSTUN_PRESSURE: %s", pow.mem.current_hitstun_frames)

	local hitstun_pressure_frames = inst.components.combat:GetHitStunPressureFrames()
	if pow.mem.current_hitstun_frames >= hitstun_pressure_frames and
		not inst.sg:HasStateTag("attack") and
		not inst.sg:HasStateTag("busy") and
		not inst.sg:HasStateTag("knockdown") then
			pow.mem.is_in_cooldown = nil
			SGCommon.Fns.ChooseHitStunPressureAttack(inst, data)
	end

	StartHitStunPressureCooldownDelay(pow, inst)
end

-- To setup a hitstun pressure attack on an entity, it needs two things:
-- * Combat component needs to call SetHitStunPressureFrames() with a specified amount of hitstun pressure frames.
-- * Attacks specified as hitstun pressure attacks need is_hitstun_pressure_attack set to true in their attack data.
Power.AddStatusEffectPower("hitstunpressure",
{
	power_category = Power.Categories.SUPPORT,
	clear_on_new_room = true,

	tuning =
	{
		[Power.Rarity.COMMON] = { cooldownrate = 0.5 }, -- Cooldown is in ticks, vs. hitstunpressure in frames.
	},

	on_add_fn = function(pow, inst)
		pow.mem.current_hitstun_frames = 0
	end,

	on_net_serialize_fn = function(pow, e)
		local hitstun_frames = math.min(pow.mem.current_hitstun_frames, (2 ^ HITSTUN_FRAMES_NR_BITS)-1)
		e:SerializeUInt(hitstun_frames, HITSTUN_FRAMES_NR_BITS)
		e:SerializeBoolean(pow.mem.is_in_cooldown)
	end,

	on_net_deserialize_fn = function(pow, e)
		local incoming_hitstun_frames = e:DeserializeUInt(HITSTUN_FRAMES_NR_BITS)

		if not pow.mem.current_hitstun_frames then
			pow.mem.current_hitstun_frames = 0
		end

		-- Only update the number of hitstun frames if it's greater than the current value, or zero if reset.
		if incoming_hitstun_frames > pow.mem.current_hitstun_frames or incoming_hitstun_frames == 0 then
			pow.mem.current_hitstun_frames = incoming_hitstun_frames
		end
		pow.mem.is_in_cooldown = e:DeserializeBoolean()
	end,

	event_triggers = {
		["completeactiveattack"] = function(pow, inst)
			-- Reset current hitstun frames on attack completion
			pow.mem.current_hitstun_frames = 0
		end,

		["attacked"] = function (pow, inst, data)
			OnHitStunPressureAttack(pow, inst, data)
		end,
		["knockback"] = function (pow, inst, data)
			OnHitStunPressureAttack(pow, inst, data)
		end,
		["knockdown"] = function (pow, inst, data)
			OnHitStunPressureAttack(pow, inst, data)
		end,
	},

	on_update_fn = function(pow, inst, dt)
		if pow.mem.is_in_cooldown then
			pow.mem.current_hitstun_frames = math.max(0, pow.mem.current_hitstun_frames - pow.persistdata:GetVar("cooldownrate"))
			--print("COOLDOWN:", pow.mem.current_hitstun_frames)

			if pow.mem.current_hitstun_frames <= 0 then
				pow.mem.is_in_cooldown = nil
			end
		end
	end,
})

Power.AddStatusEffectPower("hammer_totem_buff",
{
	power_category = Power.Categories.SUPPORT,
	prefabs = { },
	required_tags = { },

	can_drop = false,

	tooltips =
	{
	},

	tuning =
	{
		[Power.Rarity.COMMON] = { damage = 25 },
	},

	damage_mod_fn = function(pow, attack, output_data)
		if attack:GetAttacker() ~= attack:GetTarget() then
			local totem_skill_def = Power.Items.SKILL.hammer_totem

			local damage = (totem_skill_def.tuning.COMMON.bonusdamagepercent * 0.01) * attack:GetDamage()
			output_data.damage_delta = output_data.damage_delta + damage
			return true
		end
	end,

	on_add_fn = function(pow, inst)
		if inst:HasTag("player") then
			if inst.sg.mem.totem_snapshot_lp then
				soundutil.SetLocalInstanceParameter(inst, inst.sg.mem.totem_snapshot_lp, "isLocalPlayerInTotem", 1)
				TheAudio:SetGlobalParameter(fmodtable.GlobalParameter.isLocalPlayerInTotem, 1)
			end
		end
		powerutil.AttachParticleSystemToEntity(pow, inst, "player_skill_totem_affected")
	end,

	on_remove_fn = function(pow, inst)
		powerutil.StopAttachedParticleSystem(inst, pow)
		if inst:HasTag("player") and inst.sg.mem.totem_snapshot_lp then
			soundutil.SetLocalInstanceParameter(inst, inst.sg.mem.totem_snapshot_lp, "isLocalPlayerInTotem", 0)
			TheAudio:SetGlobalParameter(fmodtable.GlobalParameter.isLocalPlayerInTotem, 0)
		end
	end,

	event_triggers =
	{
	}
})


local function CONFUSED_target_enemies(pow, inst)
	-- Store the old hitflags in the memory and make them able to attack anything
	pow.mem.old_hitflags = pow.mem.old_hitflags or inst.components.hitbox:GetHitFlags()
	inst.components.hitbox:SetHitFlags(HitGroup.ALL)

	-- Store the old target tags in the memory and clear them out, so we can replace them with Enemies only
	pow.mem.old_targettags = pow.mem.old_targettags or inst.components.combat:GetTargetTags()
	pow.mem.old_friendlytargettags = pow.mem.old_friendlytargettags or inst.components.combat:GetFriendlyTargetTags()
	inst.components.combat:ClearTargetTags()
	inst.components.combat:ClearFriendlyTargetTags()

	-- Add target tags to attack enemies
	inst.components.combat:AddTargetTags(TargetTagGroups.Enemies)
	inst.components.combat:AddFriendlyTargetTags(TargetTagGroups.Players)

	-- Pick a new target with the new target tags
	inst.components.combat:ForceRetarget()
end

local function CONFUSED_reset_targettags(pow, inst)
	inst.components.hitbox:SetHitFlags(pow.mem.old_hitflags)

	-- Clear out the temp target tags we set
	inst.components.combat:ClearTargetTags()
	inst.components.combat:ClearFriendlyTargetTags()

	-- Replace the target tags and friendly target tags with the ones that were there before
	for _,targettag in pairs(pow.mem.old_targettags) do
		inst.components.combat:AddTargetTags( { targettag } ) -- Target tags are in tables, so put the old tag in a table
	end
	for _,friendlytargettag in pairs(pow.mem.old_friendlytargettags) do
		inst.components.combat:AddFriendlyTargetTags({ friendlytargettag } ) -- Target tags are in tables, so put the old tag in a table
	end

	-- Pick a new target with the new target tags
	inst.components.combat:ForceRetarget()
end

local function PlayConfusedSound(inst)
	local params = {}
	local soundevent = fmodtable.Event.status_confused_enemy
	if inst:HasTag("player") then
		soundevent = fmodtable.Event.status_confused_friendly
	end
	params.fmodevent = soundevent
	params.sound_max_count = 3 -- intentional, we mean to track this
	soundutil.PlaySoundData(inst, params, nil, inst)
end

local confused_symbol_anchors =
{
	"head",
	"face",
	"body",
}

local TARGET_TAGS_BIT_COUNT = RequiredBitCount(10)

Power.AddStatusEffectPower("confused",
{
	--TODO: does not support player minions yet
	power_category = Power.Categories.SUPPORT,
	can_drop = false,
	clear_on_new_room = true,
	stackable = true,
	max_stacks = 8, -- loses decay_rate stacks each second.

	tuning =
	{
		[Power.Rarity.COMMON] = { player_decay_rate = 1, mob_decay_rate = 0.4, },
	},

	on_add_fn = function(pow, inst)
		if inst:HasTag("player") then
			powerutil.AttachParticleSystemToSymbol(pow, inst, "confused", "head01")
		elseif inst:HasTag("mob") then
			local animstate = inst.AnimState
			for _,symbol in ipairs(confused_symbol_anchors) do
				if animstate:BuildHasSymbol(symbol) then
					powerutil.AttachParticleSystemToSymbol(pow, inst, "confused", symbol)
					break
				end
			end
		end

		PlayConfusedSound(inst)

		if not pow.mem.active then
			pow.mem.stack_timer = 1
			pow.mem.active = true
			if inst:HasTag("mob") then
				CONFUSED_target_enemies(pow, inst)
			end
		end

		inst:PushEvent("update_power", pow.def)
	end,

	on_update_fn = function(pow, inst, dt)
		local decay_modifier = inst:HasTag("player") and pow:GetVar("player_decay_rate") or pow:GetVar("mob_decay_rate")

		pow.mem.stack_timer = pow.mem.stack_timer - (dt * decay_modifier)

		if pow.mem.stack_timer <= 0 then
			pow.mem.stack_timer = 1
			inst.components.powermanager:DeltaPowerStacks(pow:GetDef(), -1)
		end
	end,

	on_remove_fn = function(pow, inst)
		powerutil.StopAttachedParticleSystem(inst, pow)
		if inst:HasTag("player") then
		-- This is all handled in the eventlisteners, but leaving this here in case it's needed for anything.
		elseif inst:HasTag("mob") then
			CONFUSED_reset_targettags(pow, inst)
		end
	end,

	on_net_serialize_fn = function(pow, e)
		local hit_flags = pow.mem.old_hitflags or 0
		e:SerializeUInt(hit_flags, 5)

		local num_targettags = pow.mem.old_targettags and #pow.mem.old_targettags or 0
		e:SerializeUInt(num_targettags, TARGET_TAGS_BIT_COUNT)
		if num_targettags > 0 then
			for _, tag in ipairs(pow.mem.old_targettags) do
				e:SerializeString(tag)
			end
		end

		local num_friendlytargettags = pow.mem.old_friendlytargettags and #pow.mem.old_friendlytargettags or 0
		e:SerializeUInt(num_friendlytargettags, TARGET_TAGS_BIT_COUNT)
		if num_friendlytargettags > 0 then
			for _, tag in ipairs(pow.mem.old_friendlytargettags) do
				e:SerializeString(tag)
			end
		end
	end,

	on_net_deserialize_fn = function(pow, e)
		pow.mem.old_hitflags = e:DeserializeUInt(5)

		local num_targettags = e:DeserializeUInt(TARGET_TAGS_BIT_COUNT)
		if num_targettags > 0 then
			local target_tags = {}
			for i = 1, num_targettags do
				table.insert(target_tags, e:DeserializeString())
			end
			pow.mem.old_targettags = target_tags
		end

		local num_friendlytargettags = e:DeserializeUInt(TARGET_TAGS_BIT_COUNT)
		if num_friendlytargettags > 0 then
			local friendly_target_tags = {}
			for i = 1, num_friendlytargettags do
				table.insert(friendly_target_tags, e:DeserializeString())
			end
			pow.mem.old_friendlytargettags = friendly_target_tags
		end
	end,

	event_triggers = {
		-- TODO: on controlevent, mirror the player's data.dir if they're using a controller or keyboard-only, but not MKB
		["locomote"] = function(pow, inst, data)
			-- Mirror the player's inputs -- if they press up, replace it with a down. If they press left, replace it with a right.
			if pow.mem.active and inst:HasTag("player") then
				if data.dir ~= nil then
					if data.dir >= 0 then
						data.dir = data.dir - 180
					else
						data.dir = data.dir + 180
					end
				end
			end
		end,

		["dodge"] = function(pow, inst, data)
			-- TODO: fix visible 'turn' before mirrored dodge?

			-- If the player tries to roll left, roll them right instead. Same for up/down.
			if pow.mem.active and inst:HasTag("player") then
				local old_rot = inst.Transform:GetRotation()

				local new_rot
				if old_rot >= 0 then
					new_rot = old_rot - 180
				else
					new_rot = old_rot + 180
				end
				inst.Transform:SetRotation(new_rot)
			end
		end,
	}
})

local function DoAcidDamage(inst, pow, warning_parameter)
	if inst:HasTag("player") and TheWorld:HasTag("town") then
		-- Do not allow players to take acid damage in town. Other entities like training dummies/etc, can!
		return
	end

	local damage = TUNING.TRAPS.trap_acid.BASE_DAMAGE
	if inst:HasTag("mob") or inst:HasTag("boss") then
		-- Acid damage does a percentage damage of health to mobs up to a cap
		local percent_damage = math.floor(inst.components.health:GetMax() * TUNING.TRAPS.trap_acid.MOB_PERCENT_DAMAGE)
		damage = math.min(percent_damage, TUNING.TRAPS.trap_acid.MOB_MAX_DAMAGE)
	end

	-- self damage doesn't cause hit reactions
	local acid_attack = Attack(inst, inst)
	acid_attack:SetDamage(damage)
	acid_attack:SetSource(pow.def.name)
	acid_attack:SetID(pow.def.name)
	acid_attack:SetIgnoresArmour(true)
	inst.components.combat:DoPowerAttack(acid_attack)

	SGCommon.Fns.BlinkAndFadeColor(inst, { 255/255, 50/255, 50/255, 1 }, 8)

	print("Acid damage applied to", inst)
	soundutil.PlayCodeSound(inst, fmodtable.Event.Hit_acid,
		{
			instigator = inst,
			fmodparams = {
				acidWarning = warning_parameter
			},
		}
	 )
end

Power.AddStatusEffectPower("acid",
{
	-- Applies 'toxicity' over time, applied as an aura.
	-- Listens for 'foley_footstep' event and plays a 'footstep step' visual FX

	power_category = Power.Categories.DAMAGE,
	prefabs = { "" },
	required_tags = { },
	has_sources = true,

	tuning =
	{
		[Power.Rarity.COMMON] = { },
		-- TUNING in TUNING.TRAPS.trap_acid.BASE_DAMAGE
	},

	can_drop = false,

	tooltips =
	{
	},

	on_add_fn = function(pow, inst)
		local fx_data =
		{
			particlefxname = "dust_footstep_run_acidpool",
			name = "acid_pool_fx",
			ischild = true,
		}

		if inst:HasTag("ACID_IMMUNE") -- This is to prevent acidic monsters in the swamp from taking damage from acid traps and abilities. Ideally this would use the stats of the entities involved and combat system for ignoring attacks marked as acid, which isnt implemented at the time
			or inst.sg:HasStateTag("flying")
			or inst.sg:HasStateTag("airborne")
			or inst.sg:HasStateTag("airborne_high") then
				fx_data.particlefxname = "dust_footstep_simple_acidpool"
		else
			inst.components.powermanager:AddPowerByName("toxicity", TUNING.TRAPS.trap_acid.TOXICITY_STACKS_PER_TICK)
		end

		ParticleSystemHelper.MakeEventSpawnParticles(inst, fx_data)
	end,

	on_update_fn = function(pow, inst)
		local toxicity_def = Power.Items.STATUSEFFECT.toxicity
		local amount = TUNING.TRAPS.trap_acid.TOXICITY_STACKS_PER_TICK

		if inst.sg:HasStateTag("doubletoxicity") then -- Typically when entity is "lying down"
			local old = amount
			amount = amount * TUNING.TRAPS.trap_acid.KNOCKDOWN_STACKS_MULT
		end

		inst.components.powermanager:DeltaPowerStacks(toxicity_def, amount, false)
	end,

	on_remove_fn = function(pow, inst)
		ParticleSystemHelper.MakeEventStopParticles(inst, { name = "acid_pool_fx" })
	end,

	event_triggers = {
		["foley_footstep"] = function(pow, inst, data)
			SGCommon.Fns.SpawnAtDist(inst, "fx_acid_footstep", 0)
		end,
	}
})

Power.AddStatusEffectPower("toxicity",
{
	-- Goes from 0-1000
	-- At 1000, deals acid damage.
	-- Constantly decays at a set rate.
	-- Other sources may apply toxicity

	power_category = Power.Categories.DAMAGE,
	prefabs = { "" },
	required_tags = { },
	has_sources = true,

	stackable = true,
	max_stacks = 1000,
	show_in_ui = true,

	tuning =
	{
		[Power.Rarity.COMMON] = { decay_per_tick = 10 },
	},

	can_drop = false,

	tooltips =
	{
	},

	on_add_fn = function(pow, inst)
		pow.mem.ticksactive = 0
		if (not inst:HasTag("ACID_IMMUNE")) then
			local scale = (pow.persistdata.stacks or 0) / pow.def.max_stacks
			inst.components.coloradder:PushColor("acid", 0.51 * scale, 0.63 * scale, 0, 0)
		end
	end,

	on_remove_fn = function(pow, inst)
		if (not inst:HasTag("ACID_IMMUNE")) then
			inst.components.coloradder:PopColor("acid")
		end
	end,

	on_stacks_changed_fn = function (pow, inst)
		local scale = (pow.persistdata.stacks or 0) / pow.def.max_stacks
		inst.components.coloradder:PushColor("acid", 0.51 * scale, 0.63 * scale, 0, 0)
		--print("stacks changed:", pow.persistdata.stacks)
	end,

	on_update_fn = function(pow, inst)
		if pow.persistdata.stacks >= pow.def.max_stacks then
			if inst:HasTag("player") and inst:IsLocal() then
				if not pow.mem.acid_sound_warning_parameter then
					pow.mem.acid_sound_warning_parameter = 0
				else
					pow.mem.acid_sound_warning_parameter = pow.mem.acid_sound_warning_parameter + 1
				end
			end

			DoAcidDamage(inst, pow, pow.mem.acid_sound_warning_parameter)

			inst.components.powermanager:SetPowerStacks(pow.def, 1)
		else
			inst.components.powermanager:DeltaPowerStacks(pow.def, -pow.persistdata:GetVar("decay_per_tick"), false)
		end

		-- if pow.persistdata.stacks == 0 then
		-- 	inst.components.powermanager:RemovePower(pow.def, true)
		-- end
	end,

	event_triggers = {
	}
})

Power.AddStatusEffectPower("bodydamage",
{
	-- Applies a hitbox on the entity that does damage
	power_category = Power.Categories.DAMAGE,

	tuning =
	{
		[Power.Rarity.COMMON] = { move_speed_modifier = 0.5, speed = 6, swallow_point_offset = {2.5, 0, -1}, swallow_distance = 2 },
	},

	on_add_fn = function(pow, inst)
		inst.components.hitbox:StartRepeatTargetDelay()
	end,

	event_triggers = {
		["hitboxtriggered"] = function(pow, inst, data)
			local owner = inst.owner -- If the owner exists, use the owner's combat component. If they don't exist for some reason, use the flying entity.
			local source_is_mob = (inst.owner ~= nil and inst.owner:HasTag("mob"))
			SGCommon.Events.OnHitboxTriggered(owner or inst, data, {
				damage_mod = source_is_mob and 0.5 or 2,
				hitstoplevel = HitStopLevel.MEDIUM,
				pushback = 0.4,
				hitflags = Attack.HitFlags.LOW_ATTACK,
				combat_attack_fn = "DoKnockbackAttack",
				hit_fx = monsterutil.defaultAttackHitFX,
				hit_fx_offset_x = 0.5,
				reduce_friendly_fire = source_is_mob, -- only reduce friendly fire if this is mob-on-mob. If this is player-on-mob, do not.
			})
		end,
	},

	on_update_fn = function(pow, inst, dt)
		-- Have the hitbox lead the actual monster if it's moving
		local size = inst.Physics:GetSize()
		local vel = inst.Physics:GetMotorVel()
		local facing = vel < 0 and -1 or 1
		local offset_x = vel ~= 0 and 0.3 or 0
		inst.components.hitbox:PushBeam(-size + offset_x * facing, size + offset_x * facing, size * 0.8, HitPriority.MOB_DEFAULT)
	end,

	on_remove_fn = function(pow, inst)
		inst.components.hitbox:StopRepeatTargetDelay()
	end,
})

Power.AddStatusEffectPower("vulnerable",
{
	-- take extra damage, 1% per stack
	power_category = Power.Categories.DAMAGE,
	stackable = true,
	max_stacks = 100,
	tuning =
	{
		[Power.Rarity.COMMON] = {
			seconds = 5,
			damage = StackingVariable(1):SetPercentage(),
		},
	},

	on_stacks_changed_fn = function(pow, inst, delta)
		if delta > 0 then
			pow:StartPowerTimer(inst, pow.def.name, "seconds")
			-- very placeholder
			-- for a persistent effect, see ElectricPowers charged for an implementation example
			powerutil.SpawnFxOnEntity("electric_charge_start" .. GetEntitySizeSuffix(inst), inst, { ischild = true} )
		end
	end,

	defend_mod_fn = function(pow, attack, output_data)
		local damage_bonus = attack:GetDamage() * pow.persistdata:GetVar("damage")
		output_data.damage_delta = damage_bonus
		return true
	end,

	event_triggers = {
		["timerdone"] = function(pow, inst, data)
			if data.name == pow.def.name then
				inst.components.powermanager:RemovePower(pow.def, true)
			end
		end,
	}
})

local slowed_stacks_to_speedmult =
{
	{ 0 , 0 },
	{ 25 , -50 },
	{ 50 , -70 },
	{ 75 , -90 },
	{ 100 , -100 },
}

local function UpdateSlowedVisuals(inst, stacks, pow)
	if inst.components.bloomer ~= nil then
		-- Fully applied should be rgb 100, 80, 140

		-- Don't lerp to fully clear (255),  because we should see a clear pop when we become "nothing"
		local r = lume.lerp(100, 200, 1-stacks/100)
		local g = lume.lerp(80, 200, 1-stacks/100)
		local b = lume.lerp(140, 200, 1-stacks/100)
		inst.components.colormultiplier:PushColor("slowed", r/255, g/255, b/255, 1)

		pow.mem.emitter1:SetEmitRateMult(stacks/100)
		pow.mem.emitter2:SetEmitRateMult(stacks/100)
	end
end

Power.AddSeedPower("slowed",
{
	prefabs =
	{
		"sticky",
	},
	tuning = {
		[Power.Rarity.COMMON] = { stacksonlocomote = -1, stacksonattack_mob = -25, stacksonattack_player = -10, stacksondodge = -25, stackedonattacked = -10 }, -- TODO #seed might need to be different for player -- -stacksonlocomote 0.5, stacksonattack -10
	},

	stackable = true,
	max_stacks = 100, 	-- 50%, 50%, 75%, 100%
	show_in_ui = false,
	can_drop = false,
	selectable = false,

	get_counter_text = powerutil.GetCounterTextPercent,

	on_add_fn = function(pow, inst)
		pow.persistdata.counter = 0
		pow.persistdata.stacks = 1

		local pfx = SpawnPrefab("sticky", inst)
		pfx.entity:SetParent(inst.ent)
		pfx.entity:AddFollower()
		pfx.entity:SetParent(inst.entity)
		pow.mem.pfx = pfx
		pow.mem.emitter1 = pfx.components.particlesystem:GetEmitter(1)
		pow.mem.emitter2 = pfx.components.particlesystem:GetEmitter(2)

		inst:PushEvent("update_power", pow.def)

		pow.mem.isplayer = inst:HasTag("player")
		if pow.mem.isplayer then
			pow.mem.locomotetoggle = true -- Only update every second 'locomote' event for player
		end

		if inst.components.locomotor ~= nil then
			if pow.persistdata.stacks > 0 then
				local speedmult = PiecewiseFn(pow.persistdata.stacks or 1, slowed_stacks_to_speedmult)
				inst.components.locomotor:AddSpeedMult(pow.def.name, speedmult * 0.01)
			else
				inst.components.locomotor:RemoveSpeedMult(pow.def.name)
			end
		end
	end,

	on_stacks_changed_fn = function(pow, inst)
		pow.persistdata.counter = pow.persistdata.stacks
		inst:PushEvent("update_power", pow.def)

		if inst.components.locomotor ~= nil then
			if pow.persistdata.stacks > 0 then
				local speedmult = PiecewiseFn(pow.persistdata.stacks or 1, slowed_stacks_to_speedmult)
				inst.components.locomotor:AddSpeedMult(pow.def.name, speedmult * 0.01)
			else
				inst.components.locomotor:RemoveSpeedMult(pow.def.name)
			end
		end
	end,

	on_remove_fn = function(pow, inst)
		if inst.components.locomotor ~= nil then
			inst.components.locomotor:RemoveSpeedMult(pow.def.name)
		end
		inst.components.colormultiplier:PopColor("slowed")
		if pow.mem.pfx ~= nil and pow.mem.pfx:IsValid() then
			pow.mem.pfx.components.particlesystem:StopThenRemoveEntity()
		end
	end,

	event_triggers =
	{
		["enter_room"] = function(pow, inst, data)
			-- update the UI to show percentage
			inst.components.powermanager:SetPowerStacks(pow.def, 0)
		end,

		["update_power"] = function(pow, inst)
			UpdateSlowedVisuals(inst, pow.persistdata.stacks or 1, pow)
		end,

		["locomote"] = function(pow, inst)
			if pow.mem.isplayer then
				pow.mem.locomotetoggle = not pow.mem.locomotetoggle
				if not pow.mem.locomotetoggle then
					return
				end
			end

			inst.components.powermanager:DeltaPowerStacks(pow.def, pow.persistdata:GetVar("stacksonlocomote"))
		end,

		["completeactiveattack"] = function(pow, inst)
			if not pow.mem.isplayer then
				inst.components.powermanager:DeltaPowerStacks(pow.def, pow.persistdata:GetVar("stacksonattack_mob"))
			end
		end,

		["attack_start"] = function(pow, inst)
			if pow.mem.isplayer then
				inst.components.powermanager:DeltaPowerStacks(pow.def, pow.persistdata:GetVar("stacksonattack_player"))
			end
		end,

		["dodge"] = function(pow, inst)
			inst.components.powermanager:DeltaPowerStacks(pow.def, pow.persistdata:GetVar("stacksondodge"))
		end,

		-- ["attacked"] = function(pow, inst)
		-- 	inst.components.powermanager:DeltaPowerStacks(pow.def, pow.persistdata:GetVar("stackedonattacked"))
		-- end,
	},
})

Power.AddSeedPower("armoured",
{
	prefabs =
	{
	},
	tuning = {
		[Power.Rarity.COMMON] = { amount = 500 },
	},

	show_in_ui = false,
	can_drop = false,
	selectable = false,

	on_add_fn = function(pow, inst)
		inst:AddComponent("shield")
		inst.components.shield:SetMax(500)
		inst.components.shield:SetCurrent(500, true)
	end,

	on_remove_fn = function(pow, inst)
		inst:RemoveComponent("shield")
	end,

	event_triggers =
	{
	},
})

local cold_stacks_to_speedmult =
{
	{ 0 , 0 },
	{ 60 , -30 },
	{ 300 , -50 },
	{ 510 , -90 },
	{ 540 , -95 },
	{ 550 , -96 },
	{ 560 , -97 },
	{ 570 , -98 },
	{ 580 , -99 },
	{ 590 , -100 },
	{ 600 , -100 },
}

Power.AddStatusEffectPower("cold",
{
	-- 1 stack is equal to 1% frozen
	-- As we get more cold, we move slower.
	-- When we hit 100% cold, we become frozen.

	-- Attacks should add 'cold' or remove 'cold', and 'cold' will handle the rest based on number of stacks.

	prefabs =
	{
	},
	tuning = {
		[Power.Rarity.COMMON] = { },
	},

	stackable = true,
	max_stacks = 600,
	show_in_ui = true,
	can_drop = false,
	selectable = false,

	get_counter_text = powerutil.GetCounterTextPercent,

	on_add_fn = function(pow, inst)
		pow.persistdata.stacks = 1
		inst:PushEvent("update_power", pow.def)

		if inst.components.locomotor ~= nil then
			if pow.persistdata.stacks > 0 then
				local speedmult = PiecewiseFn(pow.persistdata.stacks or 1, cold_stacks_to_speedmult)
				inst.components.locomotor:AddSpeedMult(pow.def.name, speedmult * 0.01)
			else
				inst.components.locomotor:RemoveSpeedMult(pow.def.name)
			end
		end
	end,

	on_stacks_changed_fn = function(pow, inst)
		inst:PushEvent("update_power", pow.def)

		--print("COLD STACKS:", pow.persistdata.stacks)
		local scale = (pow.persistdata.stacks or 0) / pow.def.max_stacks
		inst.components.coloradder:PushColor("cold", 0, 0.75 * scale, scale, 0)

		if pow.persistdata.stacks >= pow.def.max_stacks then
			inst.components.powermanager:AddPowerByName("frozen", 100)
			inst.components.powermanager:RemovePower(pow.def, true)
		elseif inst.components.locomotor ~= nil then
			if pow.persistdata.stacks > 0 then
				local speedmult = PiecewiseFn(pow.persistdata.stacks or 1, cold_stacks_to_speedmult)
				inst.components.locomotor:AddSpeedMult(pow.def.name, speedmult * 0.01)
			else
				inst.components.locomotor:RemoveSpeedMult(pow.def.name)
			end
		end
	end,

	on_remove_fn = function(pow, inst)
		if inst.components.locomotor ~= nil then
			inst.components.locomotor:RemoveSpeedMult(pow.def.name)
		end

		inst.components.coloradder:PopColor("cold")
		-- if pow.mem.pfx ~= nil and pow.mem.pfx:IsValid() then
		-- 	pow.mem.pfx.components.particlesystem:StopThenRemoveEntity()
		-- end
	end,

	event_triggers =
	{
	},
})

local function ConvertDirToGeneralDirection(dir)
	local general_dir
	--[[
			-90
		-135	-45
	-180 			0
		 135	 45
			 90
	]]

	if dir >= 45 and dir <= 135 then
		general_dir = "DOWN"
	elseif dir <= -45 and dir >= -135 then
		general_dir = "UP"
	elseif (dir >= 0 and dir < 45) or (dir < 0 and dir > -45) then
		general_dir = "RIGHT"
	elseif (dir > 135) or (dir >= -180 and dir < -135) then
		general_dir = "LEFT"
	else
		assert(false, dir)
	end

	return general_dir
end

Power.AddStatusEffectPower("frozen",
{
	-- This entity has either been immediately frozen by adding this power, or because they reached 100 cold.
	-- In this state, they cannot gain more cold -- they only become

	-- Frozen should always begin at 100 stacks, and remove itself at 0 stacks.
	-- Remove stacks of frozen naturally by doing nothing, and remove stacks by pressing buttons.

	prefabs =
	{
	},
	tuning = {
		[Power.Rarity.COMMON] = { ticks_til_thaw = 30, shudder_amount_light = 10, shudder_amount_medium = 15, shudder_amount_heavy = 20 },
	},

	stackable = true,
	max_stacks = 100,
	show_in_ui = false,
	can_drop = false,
	selectable = false,

	get_counter_text = powerutil.GetCounterTextPercent,

	on_add_fn = function(pow, inst)
		if inst.sg:HasState("frozen") then
			inst.sg:GoToState("frozen")
			pow.persistdata.counter = 0
			pow.persistdata.stacks = 100
			inst.components.powermanager:SetPowerStacks(pow.def, 100)
			inst:PushEvent("update_power", pow.def)

			pow.mem.ticks_til_thaw = pow.persistdata:GetVar("ticks_til_thaw")
			pow.mem.shudder_toggle = false -- Flip back and forth to shudder back and forth

			inst.AnimState:Pause()
			inst.components.hitshudder:DoShudder(TUNING.HITSHUDDER_AMOUNT_MEDIUM, 10)
		else
			inst.components.powermanager:RemovePower(pow.def)
		end

	end,

	on_stacks_changed_fn = function(pow, inst)
		pow.persistdata.counter = pow.persistdata.stacks
		inst:PushEvent("update_power", pow.def)
	end,

	on_update_fn = function(pow, inst)
		--print("FROZEN STACKS:", pow.persistdata.stacks)

		inst.AnimState:Pause() -- In case anything else happens that unpauses it -- force this permanently.

		-- Remove a stack every "ticks_til_thaw" stacks by default
		pow.mem.ticks_til_thaw = pow.mem.ticks_til_thaw and pow.mem.ticks_til_thaw - 1 or pow.persistdata:GetVar("ticks_til_thaw")

		-- Automatically thaw periodically
		if pow.mem.ticks_til_thaw <= 0 then
			inst:PushEvent("thaw", { amount = 3 })
			pow.mem.ticks_til_thaw = pow.persistdata:GetVar("ticks_til_thaw")
		end

		-- Manually thaw if this is a player and they are pressing buttons
		if inst.components.playercontroller then
			local dir = inst.components.playercontroller:GetAnalogDir()
			local general_dir
			if dir ~= nil then
				general_dir = ConvertDirToGeneralDirection(dir)
				if general_dir ~= pow.mem.last_general_dir then
					inst:PushEvent("thaw", { amount = 4, shudder = true })
				end
			end

			pow.mem.last_general_dir = general_dir -- Store this so we have to flip directions, not just hold one direction.
		end
	end,

	on_remove_fn = function(pow, inst)
		-- Remove all Cold if it exists, so we start back from 0.
		local cold_power = inst.components.powermanager:GetPowerByName("cold")
		if cold_power then
			inst.components.powermanager:RemovePower(cold_power.def)
		end

		inst.components.hitshudder:DoShudder(TUNING.HITSHUDDER_AMOUNT_HEAVY, 10)
	end,

	on_net_serialize_fn = function(pow, e)
		local ticks_left = pow.mem.ticks_til_thaw
		e:SerializeUInt(ticks_left, 5) -- TODO #cold determine dynamically how many bits to serialize based on 'ticks_til_thaw'
	end,

	on_net_deserialize_fn = function(pow, e)
		pow.mem.ticks_til_thaw = e:DeserializeUInt(5)
	end,

	event_triggers =
	{
		["thaw"] = function(pow, inst, data)
			-- data = { amount, manual } (amount to reduce, whether or not we have pressed a button)
			inst.components.powermanager:DeltaPowerStacks(pow.def, -data.amount)

			if data.shudder then
				local shudder
				local percent = 1 - pow.persistdata.stacks / pow.def.max_stacks
				if percent >= 0.66 then
					shudder = pow:GetVar("shudder_amount_heavy") / 150
				elseif percent >= 0.33 then
					shudder = pow:GetVar("shudder_amount_medium") / 150
				else
					shudder = pow:GetVar("shudder_amount_light") / 150
				end

				-- Flip back and forth so we shudder back and forth
				shudder = pow.mem.shudder_toggle and shudder * -1 or shudder
				pow.mem.shudder_toggle = not pow.mem.shudder_toggle

				inst.Physics:MoveRelFacing(shudder)
			end
		end,

		["take_damage"] = function(pow, inst, attack)
			-- Getting attacked unpauses animstate, so repause it
			if attack:GetTarget() ~= attack:GetAttacker() then
				inst:PushEvent("thaw", { amount = 5, shudder = true })
			end
		end,

		["controlevent"] = function(pow, inst, data)
			if data.control == "dodge" then
				inst:PushEvent("thaw", { amount = 4, shudder = true })
			elseif data.control == "lightattack" then
				inst:PushEvent("thaw", { amount = 4, shudder = true })
			elseif data.control == "heavyattack" then
				inst:PushEvent("thaw", { amount = 4, shudder = true })
			elseif data.control == "skill" then
				inst:PushEvent("thaw", { amount = 4, shudder = true })
			end
		end
	},
})
