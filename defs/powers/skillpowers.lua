local Power = require("defs.powers.power")
local combatutil = require "util.combatutil"
local ParticleSystemHelper = require "util.particlesystemhelper"
local powerutil = require "util.powerutil"
local EffectEvents = require "effectevents"

function Power.AddSkillPower(id, data)
	if data.tooltips == nil then
		data.tooltips = {}
	end
	table.insert(data.tooltips, 1, "SKILL")

	data.power_type = Power.Types.SKILL
	data.can_drop = true
	data.selectable = false

	local skillstate_name = ("skill_%s"):format(id)

	local on_add_fn = data.on_add_fn
	data.on_add_fn = nil

	data.on_add_fn = function(pow, inst)
		inst.sg.mem.skillstate = skillstate_name
		if on_add_fn then
			on_add_fn(pow, inst)
		end
	end

	local on_remove_fn = data.on_remove_fn
	data.on_remove_fn = nil

	data.on_remove_fn = function(pow, inst)
		inst.sg.mem.skillstate = nil
		if on_remove_fn then
			on_remove_fn(pow, inst)
		end
	end

	if not data.event_triggers then
		data.event_triggers = {}
	end

	local enter_room_fn = data.event_triggers.enter_room
	data.event_triggers.enter_room = nil

	data.event_triggers.enter_room = function(pow, inst, data)
		inst.sg.mem.skillstate = skillstate_name
		if enter_room_fn then
			enter_room_fn(pow, inst, data)
		end
	end

	local loadout_changed_fn = data.event_triggers.loadout_changed
	data.event_triggers.loadout_changed = nil

	data.event_triggers.loadout_changed = function(pow, inst, data)
		inst.sg.mem.skillstate = skillstate_name
		if loadout_changed_fn then
			loadout_changed_fn(pow, inst, data)
		end
	end


	Power.AddPower(Power.Slots.SKILL, id, "skillpowers", data)
end

Power.AddPowerFamily("SKILL", nil, 1)

--TODO: commonize on_add_fn/enter_room setting skillstate to parry, OR make a GetSkillState in PowerManager

Power.AddSkillPower("parry",
{
	power_category = Power.Categories.SUPPORT,
	tags = { POWER_TAGS.PROVIDES_CRITCHANCE, POWER_TAGS.PARRY },
	required_tags = { POWER_TAGS.DO_NOT_DROP },

	tuning =
	{
		[Power.Rarity.COMMON] = { },
	},
})

Power.AddSkillPower("buffnextattack",
{
	power_category = Power.Categories.DAMAGE,
	tags = { POWER_TAGS.PROVIDES_CRITCHANCE },

	stackable = true,
	max_stacks = 100, -- 0 to 100 percent
	permanent = true,

	tooltips =
	{
		"CRITICAL_HIT",
	},

	tuning =
	{
		[Power.Rarity.COMMON] = { stackspertrigger = 10 },
	},

	on_stacks_changed_fn = function(pow, inst)
		inst.components.combat:SetCritChanceModifier("skill_buffnextattack", pow.persistdata.stacks*0.01)
		inst:PushEvent("update_power", pow.def)
	end,

	event_triggers =
	{
		["do_damage"] = function(pow, inst, attack)
			if attack:GetCrit() then -- Consume the buff once we've gotten a crit.
				if attack:GetProjectile() then -- This is a ranged attack. Consume the buff now.
					inst.components.powermanager:SetPowerStacks(pow.def, 0)
					inst:PushEvent("update_power", pow.def)
				else -- This is a melee attack. Consume the buff at the end of the attack, below in "attack_end". This is so the entire attack has crit.
					pow.persistdata.consumebuff = true
				end
			end
		end,

		-- melee attack logic
		["attack_end"] = function(pow, inst)
			if pow.persistdata.consumebuff then
				inst.components.powermanager:SetPowerStacks(pow.def, 0)
				pow.persistdata.consumebuff = false
				inst:PushEvent("update_power", pow.def)
			end
		end,

		["enter_room"] = function(pow, inst, data)
			inst.components.combat:SetCritChanceModifier("skill_buffnextattack", pow.persistdata.stacks*0.01)
			inst:PushEvent("update_power", pow.def)
		end,
	}
})

Power.AddSkillPower("bananapeel",
{
	power_category = Power.Categories.SUPPORT,
	tags = { POWER_TAGS.PROVIDES_CRITCHANCE },
	prefabs = { "banana_peel", "banana_skill_recharge" },

	tooltips =
	{
	},

	tuning =
	{
		[Power.Rarity.COMMON] = {
			heal = 3, -- How much does the banana heal?
			max_bananas = 3, -- How many bananas can I have
			damage_til_new_banana = 1000, -- How much damage do I have to do to get a re-stock of a banana?
		}, 
	},

	on_add_fn = function(pow, inst)
		if not pow.persistdata.did_init then
			pow.persistdata.bananas_left = pow.persistdata:GetVar("max_bananas")
			pow.persistdata.damage_dealt = 0

			pow.persistdata.did_init = true
		end

		inst:DoTaskInTicks(1, function(inst)
			inst:PushEvent("update_banana_counter", pow.def)
		end)

	end,

	event_triggers =
	{
		["bananaeat"] = function(pow, inst, data)
			local power_heal = Attack(inst, inst)
			power_heal:SetHeal(pow.persistdata:GetVar("heal"))
			power_heal:SetSource(pow.def.name)
			inst.components.combat:ApplyHeal(power_heal)

			pow.persistdata.bananas_left = math.max(0, pow.persistdata.bananas_left - 1)

			-- TheDungeon.HUD:MakePopText({ target = inst, button = pow.persistdata.bananas_left.." bananas", color = UICOLORS.GOLD, size = 150, fade_time = 1.5, y_offset = 10 })

			inst:PushEvent("update_banana_counter", pow.def)
		end,

		["do_damage"] = function(pow, inst, data)
			if not powerutil.TargetIsEnemyOrDestructibleProp(data) then
				return
			end

			local damage = data:GetDamage()
			pow.persistdata.damage_dealt = pow.persistdata.damage_dealt + damage

			local threshold = pow.persistdata:GetVar("damage_til_new_banana")

			if pow.persistdata.damage_dealt >= threshold then

				if pow.persistdata.bananas_left < pow.persistdata:GetVar("max_bananas") then
					-- They have dealt enough damage and have space for more bananas. Refill a banana stock!
					pow.persistdata.bananas_left = pow.persistdata.bananas_left + 1

					local target = data:GetTarget()
					local target_pos = target:GetPosition()
					TheDungeon.HUD:MakePopText({ target = target, button = pow.persistdata.bananas_left, color = HexToRGB(0xE0B32AFF), size = 100, fade_time = 2, y_offset = 450, x_offset = -25 })

					ParticleSystemHelper.MakeOneShotAtPosition(target_pos, "banana_skill_recharge", 2.25, inst)

					local difference = pow.persistdata.damage_dealt - threshold
					pow.persistdata.damage_dealt = difference


					inst:PushEvent("update_banana_counter", pow.def)
				end

				-- Don't let them build up a huge budget of surplus damage. 
				pow.persistdata.damage_dealt = math.min(threshold, pow.persistdata.damage_dealt)
			end
		end,

		["update_banana_counter"] = function(pow, inst, data)
			pow.persistdata.counter = pow.persistdata.bananas_left
			inst:PushEvent("update_power", pow.def)
		end,

	}
})

Power.AddSkillPower("throwstone",
{
	power_category = Power.Categories.DAMAGE,
	tags = { },
	prefabs = { "player_throwstone_projectile" },

	tooltips =
	{
	},

	tuning =
	{
		[Power.Rarity.COMMON] = { },
	},
})

-- POLEARM
Power.AddSkillPower("polearm_shove",
{
	power_category = Power.Categories.SUPPORT,
	prefabs = { "" },
	required_tags = { POWER_TAGS.POLEARM },

	tooltips =
	{
	},

	tuning =
	{
		[Power.Rarity.COMMON] = { },
	},
})

Power.AddSkillPower("polearm_vault",
{
	power_category = Power.Categories.SUPPORT,
	prefabs = { "" },
	required_tags = { POWER_TAGS.POLEARM },

	tooltips =
	{
	},

	tuning =
	{
		[Power.Rarity.COMMON] = { },
	},
})

-- Recall that sends ball into an upward arc
Power.AddSkillPower("shotput_recall",
{
	power_category = Power.Categories.SUPPORT,
	prefabs = { "" },
	required_tags = { POWER_TAGS.SHOTPUT },

	tooltips =
	{
	},

	tuning =
	{
		[Power.Rarity.COMMON] = { },
	},
})

-- Recall that sends ball into a fast, horizontal arc
Power.AddSkillPower("shotput_summon",
{
	power_category = Power.Categories.DAMAGE,
	prefabs = { "" },
	required_tags = { POWER_TAGS.SHOTPUT },

	tooltips =
	{
	},

	tuning =
	{
		[Power.Rarity.COMMON] = { },
	},
})

-- Bounce the ball off the ground
Power.AddSkillPower("shotput_slam",
{
	power_category = Power.Categories.DAMAGE,
	prefabs = { "" },
	required_tags = { POWER_TAGS.SHOTPUT },

	tooltips =
	{
	},

	tuning =
	{
		[Power.Rarity.COMMON] = { },
	},
})


-- Lob the ball a long distance
Power.AddSkillPower("shotput_lob",
{
	power_category = Power.Categories.SUPPORT,
	prefabs = { "" },
	required_tags = { POWER_TAGS.SHOTPUT },

	tooltips =
	{
	},

	tuning =
	{
		[Power.Rarity.COMMON] = { },
	},
})

-- Launch yourself in a tackle towards your ball
Power.AddSkillPower("shotput_seek",
{
	power_category = Power.Categories.DAMAGE,
	prefabs = { "" },
	required_tags = { POWER_TAGS.SHOTPUT },

	tooltips =
	{
	},

	tuning =
	{
		[Power.Rarity.COMMON] = { },
	},
})

-- HAMMER SKILLS
-- Slam hammer onto ground, knocking back any nearby enemies
Power.AddSkillPower("hammer_thump",
{
	power_category = Power.Categories.SUPPORT,
	prefabs = { "" },
	required_tags = { POWER_TAGS.HAMMER },
	tags = { POWER_TAGS.HAMMER_THUMP },

	tooltips =
	{
	},

	tuning =
	{
		[Power.Rarity.COMMON] = { },
	},
})

-- Toss out a buff totem
Power.AddSkillPower("hammer_totem",
{
	power_category = Power.Categories.DAMAGE,
	prefabs = { "player_totem" },
	required_tags = { POWER_TAGS.HAMMER },

	tooltips =
	{
	},

	tuning =
	{
		[Power.Rarity.COMMON] = { healthtocreate = 25, bonusdamagepercent = 50, radius = 10 },
	},
})

local function _hammer_exploding_heavy(pow, inst)
	local x,z = inst.Transform:GetWorldXZ()
	local ents = FindEnemiesInRange(x, z, pow.persistdata:GetVar("radius"))

	for i, ent in ipairs(ents) do
		inst:DoTaskInAnimFrames(math.random(3, 7), function()
			if ent:IsValid() then
				local power_attack = Attack(inst, ent)
				power_attack:SetDamage(inst.components.combat:GetBaseDamage())
				power_attack:SetDamageMod(pow.persistdata:GetVar("damage_mod"))
				power_attack:SetHitstunAnimFrames(10)
				power_attack:SetPushback(2)
				power_attack:SetSource(pow.def.name)
				-- TODO: add hitstop to the attack
				inst.components.combat:DoPowerAttack(power_attack)

				powerutil.SpawnPowerHitFx("hits_bomb", inst, ent, 0, 0, HitStopLevel.HEAVY)
			end
		end)
	end

	local params =
	{
		scalex = 0.5,
		scalez = 0.5,
		inheritrotation = true,
		offx = 3,
		offz = -0.1, -- Layer in front of hammer + player
	}
	powerutil.SpawnFxOnEntity("bomb_explosion", inst, params)
	inst:PushEvent("used_power", pow.def)

	pow.persistdata.active = false
end

-- Stock a charge making your next Heavy Attack cause an explosion.
Power.AddSkillPower("hammer_explodingheavy",
{
	power_category = Power.Categories.SUPPORT,
	prefabs = { "" },
	required_tags = { POWER_TAGS.HAMMER },
	tags = { },

	tooltips =
	{
	},

	tuning =
	{
		[Power.Rarity.COMMON] = { radius = 10, damage_mod = 1.0 },
	},

	event_triggers =
	{
		-- If the player presses SKILL during a heavyattack, queue a Skill to be released when dealing damage.
		["stock_explodingheavy"] = function(pow, inst, data)
			pow.persistdata.active = true

			powerutil.AttachParticleSystemToSymbol(pow, inst, "unstable_equilibrium_trail", "swap_fx")

		end,

		["do_damage"] = function(pow, inst, data)
			if data.id == "heavy_attack" then
				if pow.persistdata.active then
					_hammer_exploding_heavy(pow, inst)
				end

				powerutil.StopAttachedParticleSystem(inst, pow)
				pow.persistdata.active = false
			end
		end,

		["hammer_heavy_hit_ground"] = function(pow, inst, data)
			if pow.persistdata.active then
				_hammer_exploding_heavy(pow, inst)
			end

			powerutil.StopAttachedParticleSystem(inst, pow)
			pow.persistdata.active = false
		end,
	}
})


-- CANNON SKILLS
Power.AddSkillPower("cannon_butt",
{
	power_category = Power.Categories.DAMAGE,
	prefabs = { },
	required_tags = { POWER_TAGS.CANNON },

	tooltips =
	{
	},

	tuning =
	{
		[Power.Rarity.COMMON] = { },
	},
})

Power.AddSkillPower("cannon_singlereload",
{
	power_category = Power.Categories.SUPPORT,
	prefabs = { },
	required_tags = { POWER_TAGS.CANNON },

	tooltips =
	{
	},

	tuning =
	{
		[Power.Rarity.COMMON] = { },
	},
})

-- BOSS SKILLS

local function SummonMegatreemonRoots(inst, x, z)
	local facingrot = inst.Transform:GetFacingRotation()
	local roots = {}

	for i=1,10 do
		inst:DoTaskInAnimFrames(i*2, function()
			local dist = i * 2
			local theta = math.rad(facingrot)
			local root = SpawnPrefab("megatreemon_growth_root_player")
			root.owner = inst
			root.Transform:SetPosition(x + dist * math.cos(theta), 0, z - dist * math.sin(theta))
			root:PushEvent("poke")

			table.insert(roots, root)
			if i == 10 then
				inst:PushEvent("projectile_launched", roots)
			end
		end)
	end
end

Power.AddSkillPower("megatreemon_weaponskill",
{
	power_category = Power.Categories.DAMAGE,
	prefabs =
	{
		'megatreemon_growth_root_player'
	},

	required_tags = { POWER_TAGS.DO_NOT_DROP },

	tooltips =
	{
	},

	tuning =
	{
		[Power.Rarity.COMMON] = { queued_blink = { 255/255, 255/255, 255/255, 1 }, blink_frames = 4 },
	},

	event_triggers =
	{
		-- If the player presses SKILL during a heavyattack, queue a Skill to be released when dealing damage.
		["controlevent"] = function(pow, inst, data)

			if inst.sg:HasStateTag("attack")
				and data.control == "skill"
				and inst.sg:HasStateTag("heavy_attack")
				and not inst.sg:HasStateTag("attack_recovery")
				and not pow.mem.attack_charged
				and not pow.mem.skill_executed
			then
				pow.mem.attack_charged = true
				local SGCommon = require "stategraphs.sg_common"
				local fmodtable = require "defs.sound.fmodtable"
				-- SGCommon.Fns.SpawnAtDist(inst, "fx_skill_megatree_launch", 0)
				inst.SoundEmitter:PlaySound(fmodtable.Event.Skill_Megatreek_Queue)
				SGCommon.Fns.BlinkAndFadeColor(inst, pow.persistdata:GetVar("queued_blink"), pow.persistdata:GetVar("blink_frames"))
			end
		end,

		["activate_skill"] = function(pow, inst, data)
			local x, z = inst.Transform:GetWorldXZ()
			SummonMegatreemonRoots(inst, x, z)
		end,

		["do_damage"] = function(pow, inst, data)
			local target = data:GetTarget()
			if data.id == "heavy_attack" then
				if pow.mem.attack_charged then
					local x, z
					if target ~= nil then
						x, z = target.Transform:GetWorldXZ()
					else
						x, z = inst.Transform:GetWorldXZ()
					end
					SummonMegatreemonRoots(inst, x, z)
				end
				pow.mem.attack_charged = false
			end
		end,

		["newstate"] = function(pow, inst, data)
			pow.mem.skill_executed = false
		end,
	}
})

-- MOB-SPECIFIC SKILLS
local YAMMO_thresholds =
{
	LRG = 200,
	MED = 75,
	SML = 0,
}

local YAMMO_states =
{
	"skill_miniboss_yammo",
	"skill_miniboss_yammo_loop",
	"skill_miniboss_yammo_swing",
	"skill_miniboss_yammo_swing_focus",
}

local YAMMO_state_to_fxdata =
{
	["skill_miniboss_yammo"] =
	{
		fxname = "fx_player_skills_yammo_pre",
		inheritrotation = true,
	},
	["skill_miniboss_yammo_loop"] = 
	{
		fxname = "fx_player_skills_yammo_loop",
		inheritrotation = true,
		ischild = true,
		followsymbol = "swap_fx2", -- TODO: if followsymbol used, scaling fx doesn't work and needs follower support
	},
	["skill_miniboss_yammo_swing"] =
	{
		fxname = "fx_player_skills_yammo_swing",
		inheritrotation = true,
		ischild = true,
	},
	["skill_miniboss_yammo_swing_focus"] =
	{
		fxname = "fx_player_skills_yammo_swing_focus",
		inheritrotation = true,
		ischild = true,
	},
}

local function RemoveAndClearPowMemFx(pow, name)
	if pow.mem[name] then
		if pow.mem[name]:IsValid() then
			pow.mem[name]:Remove()
		end
		pow.mem[name] = nil
	end
end

local function GetYammoFxSizeSuffix(pow)
	local dmg = pow.mem.damageabsorbed
	local size
	if dmg >= YAMMO_thresholds.LRG then
		size = "_lrg"
	elseif dmg > YAMMO_thresholds.MED then
		size = "_med"
	else
		size = "_sml"
	end

	return size
end
local function UpdateYammoFxByDamage(pow)
	if pow.mem.fx and pow.mem.fx:IsValid() then
		local size = GetYammoFxSizeSuffix(pow)
		-- pow.mem.fx.AnimState:SetScale(scale, scale)
	end
end

Power.AddSkillPower("miniboss_yammo",
{
	power_category = Power.Categories.DAMAGE,
	required_tags = { POWER_TAGS.DO_NOT_DROP },
	prefabs =
	{
		"fx_player_skills_yammo_pre_sml",
		"fx_player_skills_yammo_pre_med",
		"fx_player_skills_yammo_pre_lrg",

		"fx_player_skills_yammo_loop_sml",
		"fx_player_skills_yammo_loop_med",
		"fx_player_skills_yammo_loop_lrg",

		"fx_player_skills_yammo_swing_sml",
		"fx_player_skills_yammo_swing_med",
		"fx_player_skills_yammo_swing_lrg",

		"fx_player_skills_yammo_swing_focus_sml",
		"fx_player_skills_yammo_swing_focus_med",
		"fx_player_skills_yammo_swing_focus_lrg",

		"fx_player_skills_yammo_pulse_sml",
		"fx_player_skills_yammo_pulse_med",
		"fx_player_skills_yammo_pulse_lrg",
	},
	tooltips =
	{
	},

	tuning =
	{
		[Power.Rarity.COMMON] = { },
	},

	on_add_fn = function(pow, inst)
		pow.mem.damageabsorbed = 0
		pow.mem.tier = GetYammoFxSizeSuffix(pow)
		pow.mem.state_id = 0
	end,

	on_remove_fn = function(pow, inst)
		RemoveAndClearPowMemFx(pow, "fx")
	end,

	event_triggers =
	{
		["take_damage"] = function(pow, inst, attack)
			if inst.sg:HasStateTag("yammo_skill_absorbstate") then
				local old_tier = pow.mem.tier

				-- Pulsing 
				local attackdamage = attack:GetDamage()
				pow.mem.damageabsorbed = pow.mem.damageabsorbed + attackdamage
				pow.mem.tier = GetYammoFxSizeSuffix(pow)

				local pulse_fxdata =
				{
					fxname = "fx_player_skills_yammo_pulse"..GetYammoFxSizeSuffix(pow),
					inheritrotation = true,
					ischild = true,
					followsymbol = "swap_fx2", -- TODO: if followsymbol used, scaling fx doesn't work and needs follower support
				}
				EffectEvents.HandleEventSpawnEffect(inst, pulse_fxdata)

				if old_tier ~= pow.mem.tier then
					-- We're into a new tier, so clear out the old looping FX and bring in a new one.
					RemoveAndClearPowMemFx(pow, "fx")

					local state = inst.sg:GetCurrentState()
					local size_suffix = GetYammoFxSizeSuffix(pow)
					local looping_fx_data = deepcopy(YAMMO_state_to_fxdata[state])

					looping_fx_data.fxname = looping_fx_data.fxname..size_suffix
					pow.mem.fx = EffectEvents.HandleEventSpawnEffect(inst, looping_fx_data)
				end
			end
		end,

		["newstate"] = function(pow, inst, data)
			-- Debug forcing different versions:
			-- pow.mem.damageabsorbed = 500 -- MODIFY THIS TO TRY DIFFERENT AMOUNTS
			-- pow.mem.tier = GetYammoFxSizeSuffix(pow)

			if not inst.sg:HasStateTag("yammo_skill_absorbstate") and not inst.sg:HasStateTag("attack") then
				-- We've entered a state which is not an absorbtion state, and not yammo's attack states
				pow.mem.damageabsorbed = 0
				pow.mem.state_id = 0
				pow.mem.tier = GetYammoFxSizeSuffix(pow)
				RemoveAndClearPowMemFx(pow, "fx")
			end

			local state = inst.sg:GetCurrentState()
			if YAMMO_state_to_fxdata[state] ~= nil then
				local old_state_id = pow.mem.state_id
				pow.mem.state_id = table.arrayfind(YAMMO_states, state)

				-- Clear out old one if it's not relevant anymore
				if pow.mem.state_id ~= old_state_id then
					RemoveAndClearPowMemFx(pow, "fx")
					local fxdata = deepcopy(YAMMO_state_to_fxdata[state])
					local size_suffix = GetYammoFxSizeSuffix(pow)

					fxdata.fxname = fxdata.fxname..size_suffix
					pow.mem.fx = EffectEvents.HandleEventSpawnEffect(inst, fxdata)
				end

				UpdateYammoFxByDamage(pow)
			end
		end,
	},

	on_net_serialize_fn = function(pow, e)
		e:SerializeBoolean(pow.mem.fx and pow.mem.fx:IsValid())
		e:SerializeUInt(math.clamp(pow.mem.damageabsorbed, 0, 2000), 11)
		e:SerializeUInt(pow.mem.state_id or 0, 3)
	end,

	on_net_deserialize_fn = function(pow, e)
		local has_fx = e:DeserializeBoolean()
		local absorbed = e:DeserializeUInt(11)
		local state_id = e:DeserializeUInt(3)

		local old_tier = pow.mem.tier
		local old_absorbed = pow.mem.damageabsorbed

		local inst = Ents[e:GetGUID()]
		local is_local_or_transferable = inst:IsLocal() or inst:IsTransferable()
		if is_local_or_transferable then
			return
		end

		if pow.mem.state_id and pow.mem.state_id ~= state_id then
			RemoveAndClearPowMemFx(pow, "fx")
		end

		pow.mem.state_id = state_id
		pow.mem.damageabsorbed = absorbed
		pow.mem.tier = GetYammoFxSizeSuffix(pow) -- Just calculate and store the tier locally based on the damage amount that was sent.

		if has_fx then 
			if not pow.mem.fx and state_id > 0 then

				-- We should have FX, but we don't have any. Make a new one.

				local state = YAMMO_states[state_id]
				local fxdata = deepcopy(YAMMO_state_to_fxdata[state])
				local size_suffix = pow.mem.tier

				fxdata.fxname = fxdata.fxname..size_suffix
				pow.mem.fx = EffectEvents.HandleEventSpawnEffect(inst, fxdata)

			elseif old_absorbed and absorbed > old_absorbed and state_id > 0 then

				-- We've taken damage since last time, play a 'pulse' fx and update our size.

				local hit_fxdata =
				{
					fxname = "fx_player_skills_yammo_pulse"..GetYammoFxSizeSuffix(pow),
					inheritrotation = true,
					ischild = true,
					followsymbol = "swap_fx2", -- TODO: if followsymbol used, scaling fx doesn't work and needs follower support
				}
				EffectEvents.HandleEventSpawnEffect(inst, hit_fxdata)

				if old_tier ~= pow.mem.tier then
					-- We're into a new tier, so clear out the old looping FX and bring in a new one.
					RemoveAndClearPowMemFx(pow, "fx")

					local state = YAMMO_states[state_id]
					local looping_fx_data = deepcopy(YAMMO_state_to_fxdata[state])
					local size_suffix = pow.mem.tier

					looping_fx_data.fxname = looping_fx_data.fxname..size_suffix
					pow.mem.fx = EffectEvents.HandleEventSpawnEffect(inst, looping_fx_data)
				end
			end
		elseif not has_fx and pow.mem.fx then
			RemoveAndClearPowMemFx(pow, "fx")
		end
	end,
})

Power.AddSkillPower("miniboss_floracrane",
{
	power_category = Power.Categories.DAMAGE,
	required_tags = { POWER_TAGS.DO_NOT_DROP },
	prefabs =
	{
	},
	tooltips =
	{
	},

	tuning =
	{
		[Power.Rarity.COMMON] = { },
	},
})

Power.AddSkillPower("miniboss_groak",
{
	power_category = Power.Categories.SUPPORT,
	required_tags = { POWER_TAGS.DO_NOT_DROP },
	prefabs =
	{
		"player_groak_vacuum_left",
		"player_groak_vacuum_right",
	},
	tooltips =
	{
	},

	tuning =
	{
		[Power.Rarity.COMMON] = { },
	},
})

Power.AddSkillPower("miniboss_gourdo",
{
	power_category = Power.Categories.SUPPORT,
	required_tags = { POWER_TAGS.DO_NOT_DROP },
	prefabs = { "acquire_gourdo_skill_item" },

	tooltips =
	{
	},

	tuning =
	{
		[Power.Rarity.COMMON] = {
			max_stocks = 3, -- How many bananas can I have
			damage_til_new_stock = 1000, -- How much damage do I have to do to get a re-stock of a banana?

			heal = 20, -- How much does each stock heal?
			radius = TUNING.POTION_AOE_RANGE,
		},
	},

	on_add_fn = function(pow, inst)
		if not pow.persistdata.did_init then
			pow.persistdata.stocks_left = pow.persistdata:GetVar("max_stocks")
			pow.persistdata.damage_dealt = 0

			pow.persistdata.did_init = true
		end

		inst:DoTaskInTicks(1, function(inst)
			inst:PushEvent("update_stock_counter", pow.def)
		end)

	end,

	event_triggers =
	{
		["do_gourdo_skill_heal"] = function(pow, inst, data)
			local radius = pow.persistdata:GetVar("radius")
			local amount = pow.persistdata:GetVar("heal")
			local id = "gourdo_skill_heal"


			local power_heal = Attack(inst, inst)
			power_heal:SetHeal(amount)
			power_heal:SetID(id)
			inst.components.combat:ApplyHeal(power_heal)

			local SGPlayerCommon = require "stategraphs.sg_player_common"
			SGPlayerCommon.Fns.DoAOEHeal(inst, radius, amount, id)

			pow.persistdata.stocks_left = math.max(0, pow.persistdata.stocks_left - 1)

			inst:PushEvent("update_stock_counter", pow.def)
		end,

		["do_damage"] = function(pow, inst, data)
			if not powerutil.TargetIsEnemyOrDestructibleProp(data) then
				return
			end

			local damage = data:GetDamage()
			pow.persistdata.damage_dealt = pow.persistdata.damage_dealt + damage

			local threshold = pow.persistdata:GetVar("damage_til_new_stock")

			if pow.persistdata.damage_dealt >= threshold then

				if pow.persistdata.stocks_left < pow.persistdata:GetVar("max_stocks") then
					-- They have dealt enough damage and have space for more bananas. Refill a banana stock!
					pow.persistdata.stocks_left = pow.persistdata.stocks_left + 1

					local target = data:GetTarget()
					local target_pos = target:GetPosition()
					
					powerutil.SpawnFxOnEntity("acquire_gourdo_skill_item", inst, { ischild = true, offy = -1, scalex = 1.5, scalez = 1.5 })

					local difference = pow.persistdata.damage_dealt - threshold
					pow.persistdata.damage_dealt = difference

					inst:PushEvent("update_stock_counter", pow.def)
				end

				-- Don't let them build up a huge budget of surplus damage. 
				pow.persistdata.damage_dealt = math.min(threshold, pow.persistdata.damage_dealt)
			end
		end,

		["update_stock_counter"] = function(pow, inst, data)
			pow.persistdata.counter = pow.persistdata.stocks_left
			inst:PushEvent("update_power", pow.def)
		end,

	}
})

-- SKILL-SPECIFIC PLAYER POWERS

-- Parry
Power.AddPlayerPower("moment37",
{
	power_category = Power.Categories.DAMAGE,
	required_tags = { POWER_TAGS.PARRY },

	prefabs = { },
	tuning =
	{
		[Power.Rarity.EPIC] = { time = 5 }, -- Tuned to be the length of the EVO Moment 37 parry, not including the kill combo
		[Power.Rarity.LEGENDARY] = { time = 9 }, -- Include the kill combo.
	},

	on_add_fn = function(pow, inst)
		inst:PushEvent("update_power", pow.def)
	end,

	event_triggers =
	{
		["parry"] = function(pow, inst, data)
			inst.components.combat:SetCritChanceModifier(pow.def.name, 1)
			pow:StartPowerTimer(inst)
			inst:PushEvent("used_power", pow.def)
		end,
		["timerdone"] = function(pow, inst, data)
			if data.name == pow.def.name then
				inst.components.combat:RemoveCritChanceModifier(pow.def.name)
			end
		end,
	},

	on_remove_fn = function(pow, inst)
		inst.components.timer:StopTimer(pow.def.name)
		inst.components.locomotor:RemoveSpeedMult(pow.def.name)
	end,
})

-- Hammer_thump: Deal 100 damage per consecutive hit.
Power.AddPlayerPower("jury_and_executioner",
{
	power_category = Power.Categories.DAMAGE,
	required_tags = { POWER_TAGS.HAMMER_THUMP },

	prefabs = { },
	stackable = true,
	permanent = true,
	max_stacks = 10,
	tuning =
	{
		[Power.Rarity.LEGENDARY] = { time = 1.25, damage_per_consecutive_hit = 100 },
	},

	on_add_fn = function(pow, inst)
		-- inst:PushEvent("update_power", pow.def)
	end,

	event_triggers =
	{
		["hammer_thumped"] = function(pow, inst, data)
			inst.components.powermanager:DeltaPowerStacks(pow.def, 1) -- Gain a stack, then set a timer to reset all stacks.
			pow:StartPowerTimer(inst)
			inst:PushEvent("used_power", pow.def)
			inst:PushEvent("update_power", pow.def)
		end,
		["timerdone"] = function(pow, inst, data)
			if data.name == pow.def.name then
				inst.components.powermanager:SetPowerStacks(pow.def, 1)
				inst:PushEvent("update_power", pow.def)
			end
		end,

		["update_power"] = function(pow, inst)
			if pow.persistdata.stacks > 0 then
				pow.persistdata.counter = (pow.persistdata.stacks-1) * pow.persistdata:GetVar("damage_per_consecutive_hit")
			else
				pow.persistdata.counter = 0
			end
		end,
	},

	on_remove_fn = function(pow, inst)
		inst.components.timer:StopTimer(pow.def.name)
	end,
})

-- BANANA Skill power: Sam's Bananas
-- Bananas heal for 50 HP. Never get Stuffed.
-- Name is reference to this person: https://klei.slack.com/archives/C05BFEBEP1D/p1686886234035829
