local easing = require("util/easing")
local EffectEvents = require "effectevents"
local krandom = require "util.krandom"
local fmodtable = require "defs.sound.fmodtable"
local SGCommon = require "stategraphs.sg_common"
local soundutil = require "util.soundutil"

local events =
{
	EventHandler("thrown", function(inst, targetpos) inst.sg:GoToState("thrown", targetpos) end),
	EventHandler("clustered", function(inst, targetpos) inst.sg:GoToState("cluster", targetpos) end),
}

-- We randomly scale each mortar's expolosion to create offsets/visual variation. What's the min/max?
local EXPLOSION_RANDOM_SCALE_MIN = 0.7
local EXPLOSION_RANDOM_SCALE_MAX = 1.3
local HIT_TRAIL_LIFETIME_SECONDS = 2.5 --seconds

local MORTAR_HORIZONTAL_SPEEDMULT = 1
local CLUSTER_HORIZONTAL_SPEEDMULT = 1

local function CreateHitTrail(target, effectName, attachSymbol)
	local pfx = SpawnPrefab(effectName, target)
	pfx.entity:SetParent(target.entity)
	pfx.entity:AddFollower()
	if attachSymbol then
		pfx.Follower:FollowSymbol(target.GUID, attachSymbol)
	end

	pfx.OnTimerDone = function(source, data)
		if source == pfx and data ~= nil and data.name == "hitexpiry" then
			source.components.particlesystem:StopAndNotify()
		end
	end

	pfx.OnParticlesDone = function(source, data)
		if source == pfx then
			local parent = source.entity:GetParent()
			if parent and parent.hitTrailEntity == source then
				-- clear the entry if it is us, otherwise leave it alone
				-- another trail may have started while waiting for the emitter to stop
				parent.hitTrailEntity = nil
			end
			source:Remove()
		end
	end

	pfx:ListenForEvent("timerdone", pfx.OnTimerDone)
	pfx:ListenForEvent("particles_stopcomplete", pfx.OnParticlesDone)

	local timer = pfx:AddComponent("timer")
	timer:StartTimer("hitexpiry", HIT_TRAIL_LIFETIME_SECONDS)
end

local function OnExplodeHitBoxTriggered(inst, data)
	SGCommon.Events.OnHitboxTriggered(inst, data, {
		damage_mod = inst.damage_mod,
		pushback = inst.pushback,
		hitstun_anim_frames = inst.hitstun_animframes,
		hitstoplevel = HitStopLevel.HEAVIER,
		set_dir_angle_to_target = true,
		player_damage_mod = TUNING.TRAPS.DAMAGE_TO_PLAYER_MULTIPLIER,
		combat_attack_fn = "DoKnockdownAttack",
		spawn_hit_fx_fn = function(attacker, target, attack, xdata)
			attacker.components.combat:SpawnHitFxForPlayerAttack(attack, "hits_player_cannon_mortar", target, inst,
				xdata.hit_fx_offset_x, xdata.hit_fx_offset_y, attack:GetDir(), xdata.hitstoplevel)
		end,
		focus_attack = inst.focus or false,
		hit_fx_offset_x = 0,
		hit_fx_offset_y = 1.5,
		attack_id = inst.attacktype,
		disable_self_hitstop = true,
	})
end

local CLUSTER_POS_OFFSET =
{
	-- When shooting multiple projectiles in a cluster, what positioning should they have?
	-- Level 1
	{ x =  0,  z = 0  },
	{ x =  0,  z = -2  },
	{ x =  0,  z = 2  },
	{ x =  -2,  z = 0  },
	{ x =  2,  z = 0  },

	-- Level 2
	{ x =  -1,  z =  1  },
	{ x =   1,  z = -1  },

	-- Level 3
	{ x =   -1 , z = -1  },
	{ x =    1,  z =  1  },
}
local function MakeClusters(inst, num_bombs)
	local bullets = {}

	if num_bombs then
		inst.owner.sg.mem.bombs_left_to_explode = num_bombs
	end

	local player = inst.owner

	local delay_between_cluster = 1
	for i = 1, num_bombs do
		local delay = (i-1) * delay_between_cluster

		local x, y, z = inst.Transform:GetWorldPosition()

		inst:DoTaskInAnimFrames(delay, function(inst)
			if inst ~= nil and inst:IsValid() then
				local bomb = SpawnPrefab("player_cannon_mortar_projectile", inst)

				-- Set the starting position of this mortar
				bomb.Transform:SetPosition(x, y, z)

				--owner, damage_mod, hitstun_animframes, hitboxradius, pushback, focus, attacktype, numberinbatch, maxinbatch
				bomb:Setup(inst.owner, inst.damage_mod * 0.5, inst.hitstun_animframes, inst.hitboxradius, inst.pushback, inst.focus, "heavy_attack", i, num_bombs)

				-- Randomize the scale + rotation speed between a min/max for variance purposes
				local randomscale = krandom.Float(0.5, 0.6)
				local randomrotationspeed = krandom.Float(0.5, 1.5)
				bomb.AnimState:SetScale(randomscale, randomscale, randomscale)
				bomb.AnimState:SetDeltaTimeMultiplier(randomrotationspeed)
				bomb.owner = player
				bomb.num_bombs = num_bombs
				-- play fewer but 'chunkier' cluster explosion sounds if they are focus shots
				-- we do not do this with the regular mortar explosions at present
				if inst.focus then
					bomb.num_bombs_for_sound = math.ceil(num_bombs / 2)
				end

				-- for some reason I didn't feel like doing multiple events this time
				bomb.sound_event = fmodtable.Event.Skill_Cannon_ClusterShot_Explode_Counter
				bomb.focus = soundutil.CoerceFmodParamToNumber(inst.focus)

				-- Set up the target
				local aim_x = x or 1
				local aim_z = z or 1
				local aim_offset = CLUSTER_POS_OFFSET[i]
				local target_pos = Vector3(aim_x + aim_offset.x, 0, aim_z + aim_offset.z)

				table.insert(bullets, bomb)
				bomb:PushEvent("clustered", target_pos)
				local impactSequenceProgress = num_bombs == 1 and 1 or (i - 1) / (num_bombs - 1)
				local focus_attack = (bomb.focus and (impactSequenceProgress >= .5)) and 1 or 0

				-- if we have more than 3 bombs, only play a tail every other bomb to save voices
				if num_bombs >= 3 then
					if not (i % 2 == 0) then
						soundutil.PlayCodeSound(bomb,fmodtable.Event.Skill_Cannon_ClusterShot_Tail,
						{
							instigator = inst.owner,
							fmodparams =
							{
								impactSequenceProgress = impactSequenceProgress,
								isFocus = focus_attack,
							}
						}
					)
					end
				else
					soundutil.PlayCodeSound(bomb,fmodtable.Event.Skill_Cannon_ClusterShot_Tail,
					{
						instigator = player,
						fmodparams =
						{
							impactSequenceProgress = impactSequenceProgress,
							isFocus = focus_attack,
						}
					}
				)
				end
			end

			if i == num_bombs then
				if inst ~= nil and inst:IsValid() then
					inst:Remove()
				end
			end
		end)
	end
end
local states =
{
	State({
		name = "idle",
	}),

	State({
		name = "thrown",
		tags = { "airborne" },
		onenter = function(inst, targetpos)
			local anim = inst.focus and "mortar_focus" or "mortar"
			inst.AnimState:PlayAnimation(anim, true)

			inst.sg.statemem.targetpos = targetpos

			-- Set up the complex projectile function, and get it flying.
			local x, y, z = inst.Transform:GetWorldPosition()
		    local dx = targetpos.x - x
		    local dz = targetpos.z - z
		    local rangesq = dx * dx + dz * dz
		    local maxrange = 20
		    local speed = easing.linear(rangesq, 20, 3, maxrange * maxrange) * (inst.numclusterbombs ~= nil and CLUSTER_HORIZONTAL_SPEEDMULT or MORTAR_HORIZONTAL_SPEEDMULT)
		    inst.components.complexprojectile:SetHorizontalSpeed(speed)
		    inst.components.complexprojectile:SetGravity(-40)
		    inst.components.complexprojectile:Launch(targetpos)
		    inst.components.complexprojectile.onhitfn = function() -- When it lands, go to "explode"
				inst.sg:GoToState("explode", targetpos)
			end

			-- Leave an indicator for where the shot is going to land
			local circle = SpawnPrefab("fx_ground_target_purple", inst)
			circle.Transform:SetPosition( targetpos.x, 0, targetpos.z )
			inst.sg.statemem.landing_pos = circle

			inst.sg.statemem.last_y = y
		end,

		onupdate = function(inst)
			if inst.numclusterbombs ~= nil then
				local dist = inst:GetDistanceSqToXZ(inst.sg.statemem.targetpos.x, inst.sg.statemem.targetpos.z)
				if dist < 1 then
					inst.sg:GoToState("explode_into_clusters")
				end
			end
		end,

		onexit = function(inst)
			if inst.sg.statemem.landing_pos then
				inst.sg.statemem.landing_pos:Remove()
			end
		end,
	}),

	State({
		name = "explode_into_clusters",
		onenter = function(inst, focus)
			-- Hide it under the explosion FX
			inst:Hide()
			inst.components.complexprojectile.onhitfn = nil
			
			local isFocusAttack = soundutil.CoerceFmodParamToNumber(inst.focus)
			soundutil.PlayCodeSound(inst,fmodtable.Event.Skill_Cannon_ClusterShot_Burst,
				{
					name = "cluster_shot_burst",
					instigator = inst.owner,
					max_count = 1,
					is_autostop = false, -- this thing gets destroyed immediately but we still want the sound to play
					fmodparams =
					{
						isFocusAttack = isFocusAttack,
						numBombs = inst.numclusterbombs,
					}
				}
			)

			MakeClusters(inst, inst.numclusterbombs)

			local expl_prefab = inst.focus and "cannon_mortar_explosion_focus" or "cannon_mortar_explosion"
			EffectEvents.MakeEventSpawnEffect(inst, { fxname = expl_prefab, scalex = 0.5, scaley = 0.5, scalez = 0.5 } )
		end,

		onexit = function(inst)
		end,

		timeline =
		{
		},

		events =
		{
			EventHandler("hitboxtriggered", OnExplodeHitBoxTriggered),
		}
	}),

	State({
		name = "cluster",
		onenter = function(inst, targetpos)
			-- Hide it under the explosion FX
			local anim = inst.focus and "mortar_focus" or "mortar"
			inst.AnimState:PlayAnimation(anim, true)

			inst.sg.statemem.targetpos = targetpos

			-- Set up the complex projectile function, and get it flying.
			local x, y, z = inst.Transform:GetWorldPosition()
		    local dx = targetpos.x - x
		    local dz = targetpos.z - z
		    local rangesq = dx * dx + dz * dz
		    local maxrange = 20
		    local speed = easing.linear(rangesq, 20, 3, maxrange * maxrange)
		    inst.components.complexprojectile:SetHorizontalSpeed(speed)
		    inst.components.complexprojectile:SetGravity(-80)
		    inst.components.complexprojectile:Launch(targetpos)
		    inst.components.complexprojectile.onhitfn = function() -- When it lands, go to "explode"
				inst.sg:GoToState("explode", targetpos)
			end

			-- Leave an indicator for where the shot is going to land
			local circle = SpawnPrefab("fx_ground_target_purple", inst)
			circle.Transform:SetPosition( targetpos.x, 0, targetpos.z )
			circle.AnimState:SetScale(0.25, 0.25)
			inst.sg.statemem.landing_pos = circle
		end,

		onexit = function(inst)
			if inst.sg.statemem.landing_pos then
				inst.sg.statemem.landing_pos:Remove()
			end
		end,

		timeline =
		{

		},

		events =
		{
			EventHandler("hitboxtriggered", OnExplodeHitBoxTriggered),
		}
	}),

	State({
		name = "explode",
		onenter = function(inst, pos)
			-- Hide it under the explosion FX
			inst:Hide()
			local bomb = inst
			local player = bomb.owner

			if not player.sg.mem.bomb_explode_sound then
				player.sg.mem.bomb_explode_sound = soundutil.PlayCodeSound(bomb,bomb.sound_event,
					{
						instigator = player,
						is_autostop = false,
						fmodparams =
						{
							isFocusAttack = bomb.focus,
							numBombs = inst.num_bombs_for_sound or inst.num_bombs,
						}
					}
				)
			end

			if player.sg.mem.bombs_left_to_explode then
				player.sg.mem.bombs_left_to_explode = player.sg.mem.bombs_left_to_explode - 1
				if player.sg.mem.bombs_left_to_explode <= 0 then
					player.sg.mem.bombs_left_to_explode = nil
					player.sg.mem.bomb_explode_sound = nil
				end
			end

			local explo_scale = krandom.Float(EXPLOSION_RANDOM_SCALE_MIN, EXPLOSION_RANDOM_SCALE_MAX)
			local scorch_scale = 0.75 + krandom.Float(0.3)
			local scorch_rot = math.round(krandom.Float(1) * 360)
			local scorch_fade_scale = krandom.Float(0.5, 1.25)
			EffectEvents.MakeNetEventScorchMark(inst, inst.focus, explo_scale, scorch_scale, scorch_rot, scorch_fade_scale)

			inst.sg.statemem.hitboxradius = inst.hitboxradius or 1.5
		end,

		timeline = {
			FrameEvent(0, function(inst)
				inst.components.hitbox:StartRepeatTargetDelay()
				inst.components.hitbox:PushCircle(0, 0, inst.sg.statemem.hitboxradius, HitPriority.MOB_DEFAULT)
			end),
			FrameEvent(1, function(inst) inst.components.hitbox:PushCircle(0, 0, inst.sg.statemem.hitboxradius, HitPriority.MOB_DEFAULT) end),
			FrameEvent(2, function(inst) inst:Remove() end),
		},

		events = {
			EventHandler("hitboxtriggered", OnExplodeHitBoxTriggered),
		},

		onexit = function(inst)
			if inst.owner.sg.mem.bombs_left_to_explode <= 0 then
				inst.owner.sg.mem.bombs_left_to_explode = nil
				inst.owner.sg.mem.bomb_explode_sound = nil
			end
		end,
	})
}

return StateGraph("sg_player_cannon_mortar_projectile", states, events, "idle")
