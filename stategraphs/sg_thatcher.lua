local SGCommon = require "stategraphs.sg_common"
local SGBossCommon = require "stategraphs.sg_boss_common"
local TargetRange = require "targetrange"
local monsterutil = require "util.monsterutil"
local playerutil = require "util.playerutil"
local bossutil = require "prefabs.bossutil"
local spawnutil = require "util.spawnutil"
local audioid = require "defs.sound.audioid"
local fmodtable = require "defs.sound.fmodtable"
local soundutil = require "util.soundutil"

local function OnSwingShortHitBoxTriggered(inst, data)
	SGCommon.Events.OnHitboxTriggered(inst, data, {
		attackdata_id = "swing_short",
		hitstoplevel = HitStopLevel.HEAVY,
		pushback = 0.6,
		combat_attack_fn = "DoKnockdownAttack",
		hitflags = Attack.HitFlags.GROUND,
		hit_fx = "fx_hit_player_round",
		hit_fx_offset_x = 0.5,
	})
end

local function OnSwingLongHitBoxTriggered(inst, data)
	SGCommon.Events.OnHitboxTriggered(inst, data, {
		attackdata_id = "swing_long",
		hitflags = Attack.HitFlags.GROUND,
		hitstoplevel = HitStopLevel.HEAVY,
		set_dir_angle_to_target = true,
		pushback = 0.9,
		combat_attack_fn = "DoKnockdownAttack",
		hit_fx = "fx_hit_player_round",
		hit_fx_offset_x = 0.5,
	})
end

local function OnSwingUppercutHitBoxTriggered(inst, data)
	local hit = SGCommon.Events.OnHitboxTriggered(inst, data, {
		attackdata_id = "swing_long",
		hitstoplevel = HitStopLevel.HEAVY,
		hitflags = inst.sg.statemem.is_high and Attack.HitFlags.AIR_HIGH or Attack.HitFlags.DEFAULT,
		set_dir_angle_to_target = true,
		pushback = 3.0,
		combat_attack_fn = "DoKnockdownAttack",
		hit_fx = "fx_hit_player_round",
		hit_fx_offset_x = 0.5,
	})

	inst.sg.statemem.hit = hit
end

--[[local function OnHookHitBoxTriggered(inst, data)
	local hit = SGCommon.Events.OnHitboxTriggered(inst, data, {
		attackdata_id = "hook",
		hitstoplevel = inst.sg.statemem.is_hooking and HitStopLevel.LIGHT or HitStopLevel.HEAVY,
		set_dir_angle_to_target = not inst.sg.statemem.is_hooking,
		pushback = inst.sg.statemem.is_hooking and -2.0 or 0.5,
		combat_attack_fn =
			(inst.sg.statemem.do_basic_attack and "DoBasicAttack") or
			(inst.sg.statemem.is_hooking and "DoKnockbackAttack") or
			"DoKnockdownAttack",
		hit_fx = "fx_hit_player_round",
		hit_fx_offset_x = 0.5,
	})

	inst.sg.statemem.hit = inst.sg.statemem.is_hooking and hit
end

local function OnHookUppercutHitBoxTriggered(inst, data)
	local hit = SGCommon.Events.OnHitboxTriggered(inst, data, {
		attackdata_id = "hook_uppercut",
		hitstoplevel = HitStopLevel.HEAVY,
		set_dir_angle_to_target = true,
		pushback = 1.6,
		combat_attack_fn = "DoKnockdownAttack",
		hit_fx = "fx_hit_player_round",
		hit_fx_offset_x = 0.5,
	})

	inst.sg.statemem.hit = hit
end]]

local function OnDoubleShortSlashHitBoxTriggered(inst, data)
	SGCommon.Events.OnHitboxTriggered(inst, data, {
		attackdata_id = "double_short_slash",
		hitstoplevel = inst.sg.statemem.is_second_attack and HitStopLevel.HEAVY or HitStopLevel.LIGHT,
		set_dir_angle_to_target = true,
		pushback = inst.sg.statemem.is_second_attack and 1.2 or 0.6,
		combat_attack_fn = inst.sg.statemem.is_second_attack and "DoKnockdownAttack" or "DoKnockbackAttack",
		hit_fx = "fx_hit_player_round",
		hit_fx_offset_x = 0.5,
	})
end

--[[local function OnFullSwingHitBoxTriggered(inst, data)
	local hit = SGCommon.Events.OnHitboxTriggered(inst, data, {
		attackdata_id = "full_swing",
		hitstoplevel = inst.sg.statemem.is_last_attack and HitStopLevel.MEDIUM or HitStopLevel.LIGHT,
		set_dir_angle_to_target = true,
		pushback = inst.sg.statemem.is_last_attack and 1.0 or 0.4,
		combat_attack_fn = inst.sg.statemem.is_last_attack and "DoKnockdownAttack" or "DoKnockbackAttack",
		hit_fx = "fx_hit_player_round",
		hit_fx_offset_x = 0.5,
	})

	inst.sg.statemem.hit = hit
end]]

local function OnFullSwingMobileHitBoxTriggered(inst, data)
	local hit = SGCommon.Events.OnHitboxTriggered(inst, data, {
		attackdata_id = "full_swing",
		hitstoplevel = HitStopLevel.HEAVY,--inst.sg.statemem.is_last_attack and HitStopLevel.MEDIUM or HitStopLevel.LIGHT,
		set_dir_angle_to_target = true,
		hitstun_anim_frames = 2,
		pushback = 3.0,--inst.sg.statemem.is_last_attack and 1.0 or 0.4,
		combat_attack_fn = "DoKnockdownAttack",--inst.sg.statemem.is_last_attack and "DoKnockdownAttack" or "DoKnockbackAttack",
		hit_fx = "fx_hit_player_round",
		hit_fx_offset_x = 0.5,
	})

	inst.sg.statemem.hit = hit
end

-- Dash before dash uppercut
local function OnDashHitBoxTriggered(inst, data)
	-- Hit all targets & apply damage, but if hit a player, directly transition into the uppercut.
	local hit_player = false
	--local hit_other = {}

	for _, target in ipairs(data.targets) do
		--local is_player = false
		for _, playertag in ipairs(TargetTagGroups.Players) do
			if target:HasTag(playertag) then
				--is_player = true
				hit_player = true
				break
			end
		end

		--[[if is_player then
			hit_player = true
		else
			table.insert(hit_other, target) -- Hit a non-player/player ally
		end]]
	end

	--data.targets = hit_other

	local hit = SGCommon.Events.OnHitboxTriggered(inst, data, {
		attackdata_id = "dash_uppercut",
		damage_mod = 0.3,
		hitstoplevel = HitStopLevel.LIGHT,
		set_dir_angle_to_target = true,
		pushback = 0.8,
		combat_attack_fn = "DoKnockbackAttack",
		reduce_friendly_fire = true,
		hit_fx = "fx_hit_player_round",
		hit_fx_offset_x = 0.5,
	})

	inst.sg.statemem.hit = hit

	if hit_player then
		inst.sg:GoToState("dash_uppercut_atk")
	end
end

local function OnDashUppercutHitBoxTriggered(inst, data)
	local hit = SGCommon.Events.OnHitboxTriggered(inst, data, {
		attackdata_id = "dash_uppercut",
		hitstoplevel = HitStopLevel.HEAVY,
		hitflags = inst.sg.statemem.is_air_attack and Attack.HitFlags.AIR_HIGH or Attack.HitFlags.DEFAULT,
		set_dir_angle_to_target = true,
		pushback = 2.4,
		combat_attack_fn = "DoKnockdownAttack",
		reduce_friendly_fire = true,
		hit_fx = "fx_hit_player_round",
		hit_fx_offset_x = 0.5,
	})

	inst.sg.statemem.hit = hit
end

local function OnSwingSmashHitBoxTriggered(inst, data)
	SGCommon.Events.OnHitboxTriggered(inst, data, {
		attackdata_id = "swing_smash",
		damage_mod = inst.sg.statemem.is_attack_pre and 0.3 or 1,
		hitstoplevel = inst.sg.statemem.is_last_attack and HitStopLevel.HEAVY or HitStopLevel.LIGHT,
		hitflags = inst.sg.statemem.is_air_attack and Attack.HitFlags.AIR_HIGH or Attack.HitFlags.DEFAULT,
		set_dir_angle_to_target = true,
		pushback = inst.sg.statemem.is_last_attack and 2.5 or 0.4,
		combat_attack_fn = inst.sg.statemem.is_last_attack and "DoKnockdownAttack" or "DoKnockbackAttack",
		hit_fx = "fx_hit_player_round",
		hit_fx_offset_x = 0.5,
	})
end

local function OnAcidSplashHitBoxTriggered(inst, data)
	local hit = SGCommon.Events.OnHitboxTriggered(inst, data, {
		attackdata_id = "acid_splash",
		hitstoplevel = HitStopLevel.MEDIUM,
		hitflags = inst.sg.statemem.is_air_attack and Attack.HitFlags.AIR_HIGH or Attack.HitFlags.DEFAULT,
		pushback = 0.4,
		combat_attack_fn = "DoKnockbackAttack",
		hit_fx = "fx_hit_player_round",
		hit_fx_offset_x = 0.5,
	})
end

local function ChooseIdleBehavior(inst)
	if not inst.components.timer:HasTimer("idlebehavior_cd") then
		local threat = playerutil.GetRandomLivingPlayer()
		if not threat then
			inst.sg:GoToState("idle_behaviour")
			return true
		end
	end
	return false
end

local function SpawnAcidBall(inst, size, target_pos, offset_x, offset_y)
	if not TheWorld.Map:IsWalkableAtXZ(target_pos.x, target_pos.z) then return end

	local projectile = SpawnPrefab("thatcher_acidball", inst)
	projectile:Setup(inst)

	if inst.Transform:GetFacing() == FACING_LEFT then
		offset_x = offset_x and offset_x * -1 or 0
	end

	local offset = Vector3(offset_x or 0, offset_y or 0, 0)
	local x, z = inst.Transform:GetWorldXZ()
	projectile.Transform:SetPosition(x + offset.x, offset.y, z + offset.z)

	-- Make sure the target position in on the map. If not, place at the edge of the map taking into account the acid's size.
	--[[if not TheWorld.Map:IsWalkableAtXZ(target_pos.x, target_pos.z) then
		target_pos.x, target_pos.z = TheWorld.Map:FindClosestXZOnWalkableBoundaryToXZ(target_pos.x, target_pos.z)
		local acid_radius = size == "large" and 4 or 2
		local v = Vector3(target_pos.x, 0, target_pos.z)
		local to_point, len = v:normalized()
		len = math.abs(len - acid_radius)
		target_pos = to_point:scale(len)
	end]]

	projectile.sg:GoToState("ball", { targetpos = target_pos, size = size })
end

local acidSpitPatterns =
{
	-- Phase 1: a single acid in a big area
	{
		{ x = 10, z = 0 },
	},

	-- Phase 2: a straight line of acid
	{
		{ x = 5, z = 0 },
		{ x = 9, z = 0 },
		{ x = 13, z = 0 },
		{ x = 17, z = 0 },
		{ x = 21, z = 0 },
		{ x = 25, z = 0 },
	},

	-- Phase 3: a vertical column of acid
	{
		{ x = 12, z = -12 },
		{ x = 12, z = -8 },
		{ x = 12, z = -4 },
		{ x = 12, z = 0 },
		{ x = 12, z = 4 },
		{ x = 12, z = 8 },
		{ x = 12, z = 12 },
	},
}

local acidSpitSizes = { "large", "medium", "medium" }

local function SpawnAcidSpitPattern(inst)
	local spawn_offset_x = 4
	local spawn_offset_y = 3

	local current_phase = 2--inst.boss_coro:CurrentPhase() or 1

	local pos = inst:GetPosition()
	local facing = inst.Transform:GetFacing() == FACING_LEFT and -1 or 1
	local size = acidSpitSizes[current_phase] or "medium"

	for _, target_offset in ipairs(acidSpitPatterns[current_phase]) do
		local target_pos = pos + Vector3(target_offset.x * facing, 0, target_offset.z)
		SpawnAcidBall(inst, size, target_pos, spawn_offset_x, spawn_offset_y)
	end
end

local ACID_SPLASH_SPAWN_OFFSET_X <const> = 0
local ACID_SPLASH_SPAWN_OFFSET_Y <const> = 8

--[[local ACID_SPLASH_LINE_DIRECTIONS <const> = 8
local ACID_SPLASH_LINE_UNIT_DISTANCE <const> = 5
local ACID_SPLASH_LINE_UNITS <const> = 3]]

local ACID_SPLASH_CIRCLE_DIRECTIONS <const> = 6
local ACID_SPLASH_CIRCLE_UNIT_DISTANCE <const> = 4
local ACID_SPLASH_CIRCLE_UNITS <const> = 1

local ACID_SPLASH_GRID_ROWS <const> = 3
local ACID_SPLASH_GRID_COLUMNS <const> = 4
local ACID_SPLASH_GRID_UNIT_DISTANCE_X <const> = 7
local ACID_SPLASH_GRID_UNIT_DISTANCE_Z <const> = 3.5

local BACKGROUND_JUMP_POSITION <const> = Vector3(0, 0, 20)
local ACID_SPLASH_POSITION <const> = Vector3(0, 0, -4)
local ACID_SPIT_RANGE = 10

local acidSplashPatterns =
{
	-- Outward lines pattern
	--[[function(inst)
		local angle_delta = 360 / (ACID_SPLASH_LINE_DIRECTIONS or 360)
		local current_angle = 0
		local pos = inst:GetPosition()

		for i = 1, ACID_SPLASH_LINE_DIRECTIONS do
			local current_distance = ACID_SPLASH_LINE_UNIT_DISTANCE

			for j = 1, ACID_SPLASH_LINE_UNITS do
				local target_pos = pos + Vector3(math.cos(math.rad(current_angle)), 0, math.sin(math.rad(current_angle))) * current_distance
				SpawnAcidBall(inst, "small", target_pos, ACID_SPLASH_SPAWN_OFFSET_X, ACID_SPLASH_SPAWN_OFFSET_Y)

				current_distance = current_distance + ACID_SPLASH_LINE_UNIT_DISTANCE
			end

			current_angle = current_angle + angle_delta
		end
	end,]]

	-- n-sided pattern
	function(inst)
		local angle_delta = 360 / (ACID_SPLASH_CIRCLE_DIRECTIONS or 360)
		local current_angle = 0
		local pos = inst:GetPosition()

		SpawnAcidBall(inst, "medium", pos, 0, ACID_SPLASH_SPAWN_OFFSET_Y) -- Center point

		for i = 1, ACID_SPLASH_CIRCLE_DIRECTIONS do
			local current_distance = ACID_SPLASH_CIRCLE_UNIT_DISTANCE + 4

			for j = 1, ACID_SPLASH_CIRCLE_UNITS do
				local target_pos = pos + Vector3(math.cos(math.rad(current_angle)), 0, math.sin(math.rad(current_angle))) * current_distance
				SpawnAcidBall(inst, "medium", target_pos, ACID_SPLASH_SPAWN_OFFSET_X, ACID_SPLASH_SPAWN_OFFSET_Y)

				current_distance = current_distance + ACID_SPLASH_CIRCLE_UNIT_DISTANCE
			end

			current_angle = current_angle + angle_delta
		end
	end,

	-- Grid pattern
	function(inst)
		local start_x = -11
		local start_z = 3.3
		local pos = inst:GetPosition()

		for i = 1, ACID_SPLASH_GRID_ROWS do
			-- 'Checkerboard' the grid pattern
			local x = i % 2 == 0 and start_x + ACID_SPLASH_GRID_UNIT_DISTANCE_X / 2 or start_x
			local num_columns = i % 2 == 0 and ACID_SPLASH_GRID_COLUMNS - 1 or ACID_SPLASH_GRID_COLUMNS

			for j = 1, num_columns do
				local target_pos = pos + Vector3(x + ACID_SPLASH_GRID_UNIT_DISTANCE_X * (j - 1), 0, start_z - ACID_SPLASH_GRID_UNIT_DISTANCE_Z * (i - 1))
				SpawnAcidBall(inst, "small", target_pos, ACID_SPLASH_SPAWN_OFFSET_X, ACID_SPLASH_SPAWN_OFFSET_Y)
			end
		end
	end,
}

local function SpawnAcidSplash(inst)
	local current_phase = inst.boss_coro:CurrentPhase() > 1 and inst.boss_coro:CurrentPhase() - 1 or 1
	acidSplashPatterns[current_phase](inst)
	--local pattern = math.random(1, #acidSplashPatterns)
	--acidSplashPatterns[pattern](inst)
end

local function LookForAcidGeysers(inst)
	-- Look for acid geysers to spawn acid from; save the list to statemem.acid_geysers for faster access later.
	if not inst.sg.statemem.acid_geysers then
		local ents = TheSim:FindEntitiesXZ(0, 0, 100, { "acid_geyser" })
		inst.sg.statemem.acid_geysers = ents
	end
end

local function StopAcidGeysers(inst)
	LookForAcidGeysers(inst)
	for _, acid_geyser in ipairs(inst.sg.statemem.acid_geysers) do
		acid_geyser:PushEvent("stop_acid")
	end
end

local function StartAcidGeysers(inst, duration)
	LookForAcidGeysers(inst)

	for _, acid_geyser in ipairs(inst.sg.statemem.acid_geysers) do
		acid_geyser:PushEvent("spawn_acid")
	end

	-- Tell acid geysers to stop spewing out acid. If duration is set to negative, don't stop unless we manually call StopAcidGeysers()
	duration = duration or 1
	if duration >= 0 then
		inst:DoTaskInTime(duration, function(inst)
			StopAcidGeysers(inst)
		end)
	end
end

local function SpawnGeyserAcid(inst, pos_index, key, is_medium)
	local projectile = SpawnPrefab("thatcher_geyser_acid", inst)
	local pattern = inst.boss_coro:GetGeyserAcidPattern(key)
	local spawn_pos = spawnutil.GetStartPointFromWorld(table.unpack(pattern[pos_index])) or inst:GetPosition()
	projectile.Transform:SetPosition(spawn_pos:Get())

	projectile.sg.mem.is_medium = is_medium
end

local function SpawnGeyserAcidPermanent(inst, pos_index, phase)
	local projectile = SpawnPrefab("thatcher_geyser_acid", inst)
	local pattern = inst.boss_coro:GetPermanentAcidPattern(phase)
	local spawn_pos = spawnutil.GetStartPointFromWorld(table.unpack(pattern[pos_index])) or inst:GetPosition()
	projectile.Transform:SetPosition(spawn_pos:Get())

	projectile.sg.mem.is_boss_acid = true
	projectile.sg.mem.is_permanent = true
end

local DOUBLE_SHORT_SLASH_POSITION_OFFSET = 10

local FULL_SWING_MOVE_SPEED = 4
local FULL_SWING_MOBILE_LOOPS <const> = 5

local UPPERCUT_DASH_MOVE_SPEED = 40

local SWING_SMASH_STUCK_FRAMES <const> = 81

local PHASE_2 <const> = 2
local PHASE_3 <const> = 3

local events =
{
	EventHandler("dodge", function(inst, dir)
		if not (inst.sg:HasStateTag("busy") or inst.components.timer:HasTimer("dodge_cd")) then
			if dir == nil then
				local target = inst.components.combat:GetTarget()
				if target ~= nil then
					local facing = inst.Transform:GetFacing()
					local x, z = inst.Transform:GetWorldXZ()
					local x1, z1 = target.Transform:GetWorldXZ()
					local dx = x1 - x
					local dz = z1 - z
					local absdz = math.abs(dz)
					local right = x > x1 or (x == x1 and facing == FACING_LEFT)
					if absdz < inst.Physics:GetDepth() + target.Physics:GetDepth() + 2 then
						--Too close, so dodge horizontally to avoid clipping
						dir = right and 0 or 180
					else
						local turn = right == (facing == FACING_RIGHT)
						local dist = turn and 6.85 or 6.25
						if absdz < dist then
							local xdist = math.sqrt(dist * dist - dz * dz)
							if xdist + math.abs(dx) > inst.Physics:GetSize() + target.Physics:GetSize() + 1 then
								--Close enough to dodge diagonally without clipping
								dir = math.deg(math.atan(-dz, right and xdist or -xdist))
							end
						end
					end
				else
					dir = inst.Transform:GetFacingRotation() + 180
				end
			end
			if dir ~= nil then
				if DiffAngle(inst.Transform:GetFacingRotation(), dir) < 90 then
					inst.Transform:SetRotation(dir)
					inst.sg:GoToState("turn_dodge_pre")
				else
					inst.Transform:SetRotation(dir + 180)
					inst.sg:GoToState("dodge")
				end
			end
		end
	end),

	EventHandler("fullswing", function(inst)
		local target = inst.components.combat:GetTarget()
		if target then
			SGCommon.Fns.FaceActionTarget(inst, target, true)
		end
		bossutil.DoEventTransition(inst, "full_swing_pre")
	end),
	EventHandler("fullswing_mobile", function(inst)
		local target = inst.components.combat:GetTarget()
		if target then
			SGCommon.Fns.FaceActionTarget(inst, target, true)
		end
		bossutil.DoEventTransition(inst, "full_swing_mobile_pre")
	end),
	--[[EventHandler("hook", function(inst)
		local target = inst.components.combat:GetTarget()
		if target then
			SGCommon.Fns.FaceActionTarget(inst, target, true)
		end
		bossutil.DoEventTransition(inst, "hook_pre")
	end),]]
	EventHandler("dash_uppercut", function(inst)
		local target = inst.components.combat:GetTarget()
		if target then
			SGCommon.Fns.FaceActionTarget(inst, target, true)
		end
		bossutil.DoEventTransition(inst, "dash_uppercut_pre")
	end),
	EventHandler("swing_smash", function(inst)
		local target = inst.components.combat:GetTarget()
		if target then
			SGCommon.Fns.FaceActionTarget(inst, target, true)
		end
		bossutil.DoEventTransition(inst, "swing_smash_pre")
	end),
	EventHandler("acid_splash", function(inst)
		local target = inst.components.combat:GetTarget()
		if target then
			SGCommon.Fns.FaceActionTarget(inst, target, true)
		end
		bossutil.DoEventTransition(inst, "acid_splash_pre")
	end),
	EventHandler("acid_coating", function(inst)
		local target = inst.components.combat:GetTarget()
		if target then
			SGCommon.Fns.FaceActionTarget(inst, target, true)
		end
		bossutil.DoEventTransition(inst, "acid_coating")
	end),

	-- Check to enter transition states
	EventHandler("boss_phase_changed", function(inst, phase)
		inst.boss_coro:SetMusicPhase(phase)

		local target = inst.components.combat:GetTarget()
		if target then
			SGCommon.Fns.TurnAndActOnTarget(inst, target, true, "phase_transition", target)
		else
			inst.sg:GoToState("phase_transition")
		end
	end),

	EventHandler("dying", function(inst)
		-- Clear any text overlays if present
		inst.components.monstertranslator:ClearMonsterString()
	end),
}
monsterutil.AddBossCommonEvents(events,
{
	locomote_data = { run = true, turn = true },
})
monsterutil.AddOptionalMonsterEvents(events,
{
	idlebehavior_fn = ChooseIdleBehavior,
})

local states =
{
	State({
		name = "introduction",
		tags = { "busy", "nointerrupt" },

		onenter = function(inst, attack_fn)
			inst.AnimState:PlayAnimation("intro")
			inst.sg.statemem.start_pos = Vector3(0, 0, 5)

			inst.sg:SetTimeoutAnimFrames(172)

			-- Timing for spawning permanent acid, to be in sync with audio. Acid spawn & land takes around 14 frames.
			-- 1st drop at frame 28 of the following animation, so start at frame 184 (172 + 14)
			inst:DoTaskInAnimFrames(184, function(inst)
				SpawnGeyserAcidPermanent(inst, 1)
				SpawnGeyserAcidPermanent(inst, 2)

				SpawnGeyserAcidPermanent(inst, 3)
				SpawnGeyserAcidPermanent(inst, 4)
			end)
			-- 2nd drop 19 frames later
			inst:DoTaskInAnimFrames(199, function(inst)
				SpawnGeyserAcid(inst, 1, "intro")
				SpawnGeyserAcid(inst, 2, "intro")
			end)
		end,

		timeline =
		{
			-- Tell acid geysers to spew out acid.
			FrameEvent(115, function(inst)
				StartAcidGeysers(inst)
			end),
		},

		events =
		{
			EventHandler("cine_skipped", function(inst)
				local pos = inst.sg.statemem.start_pos
				inst.Transform:SetPosition(pos.x, pos.y, pos.z)
				inst.sg:GoToState("idle")
			end),
		},

		ontimeout = function(inst)
			inst.sg:GoToState("introduction2")
		end,

		onexit = function(inst)
			local pos = inst.sg.statemem.start_pos or Vector3.zero
			inst.Transform:SetPosition(pos:unpack())
		end,
	}),

	State({
		name = "introduction2",
		tags = { "busy", "nointerrupt" },

		onenter = function(inst, attack_fn)
			inst.AnimState:PlayAnimation("intro_part2")
		end,

		events =
		{
			EventHandler("cine_skipped", function(inst)
				inst.sg:GoToState("idle")
			end),
		},
	}),

	State({
		name = "taunt",
		tags = { "busy", "nointerrupt" },

		onenter = function(inst, data)
			inst.AnimState:PlayAnimation("behavior1")
			inst.components.timer:StartTimer("taunt_cd", 12 + math.random() * 5, true)

			inst.components.monstertranslator:DisplayMonsterString("thatcher", "THATCHER_TAUNT_1")
		end,

		timeline =
		{
			FrameEvent(42, function(inst)
				inst.sg:RemoveStateTag("nointerrupt")
			end),
		},

		events =
		{
			EventHandler("animover", function(inst)
				inst.sg:GoToState("idle")
			end),
		},
	}),

	State({
		name = "dodge",
		tags = { "busy", "nointerrupt" },

		onenter = function(inst)
			inst.AnimState:PlayAnimation("backhop")
			inst.components.timer:StartTimer("dodge_cd", 4, true)
		end,

		timeline =
		{
			--physics
			FrameEvent(1, function(inst) inst.Physics:SetMotorVel(-8) end),
			FrameEvent(2, function(inst) inst.Physics:SetMotorVel(-12) end),
			FrameEvent(3, function(inst) inst.Physics:SetMotorVel(-18) end),
			FrameEvent(6, function(inst) inst.Physics:SetMotorVel(-16) end),
			FrameEvent(8, function(inst) inst.Physics:SetMotorVel(-12) end),
			FrameEvent(13, function(inst) inst.Physics:SetMotorVel(-6) end),
			FrameEvent(14, function(inst) inst.Physics:SetMotorVel(-5) end),
			FrameEvent(15, function(inst) inst.Physics:SetMotorVel(-4) end),
			FrameEvent(16, function(inst) inst.Physics:SetMotorVel(-3) end),
			FrameEvent(17, function(inst) inst.Physics:SetMotorVel(-2) end),
			FrameEvent(18, function(inst) inst.Physics:SetMotorVel(-1) end),
			FrameEvent(19, function(inst) inst.Physics:SetMotorVel(-.5) end),
			FrameEvent(20, function(inst) inst.Physics:Stop() end),
			--

			FrameEvent(2, function(inst)
				inst.sg:AddStateTag("airborne")
			end),
			FrameEvent(13, function(inst)
				inst.sg:RemoveStateTag("airborne")
			end),
		},

		events =
		{
			EventHandler("animover", function(inst)
				inst.sg:GoToState("idle")
			end),
		},

		onexit = function(inst) inst.Physics:Stop() end,
	}),

	State({
		name = "turn_dodge_pre",
		tags = { "turning", "busy", "nointerrupt" },

		onenter = function(inst)
			inst.AnimState:PlayAnimation("turn_backhop_pre")
			inst.components.timer:StartTimer("dodge_cd", 4, true)
		end,

		timeline =
		{
			--physics
			FrameEvent(1, function(inst) inst.Physics:SetMotorVel(14) end),
			FrameEvent(2, function(inst) inst.Physics:SetMotorVel(18) end),
			FrameEvent(4, function(inst) inst.Physics:SetMotorVel(16) end),
			--

			FrameEvent(4, function(inst)
				inst.sg:AddStateTag("airborne")
				inst.sg:AddStateTag("nointerrupt")
			end),
		},

		events =
		{
			EventHandler("animover", function(inst)
				inst.sg.statemem.dodging = true
				inst:FlipFacingAndRotation()
				inst.sg:GoToState("turn_dodge_pst")
			end),
		},

		onexit = function(inst)
			if not inst.sg.statemem.dodging then
				inst.Physics:Stop()
			end
		end,
	}),

	State({
		name = "turn_dodge_pst",
		tags = { "busy", "airborne", "nointerrupt" },

		onenter = function(inst)
			inst.AnimState:PlayAnimation("turn_backhop_pst")
		end,

		timeline =
		{
			--physics
			FrameEvent(0, function(inst) inst.Physics:SetMotorVel(-14) end),
			FrameEvent(3, function(inst) inst.Physics:SetMotorVel(-12) end),
			FrameEvent(8, function(inst) inst.Physics:SetMotorVel(-6) end),
			FrameEvent(9, function(inst) inst.Physics:SetMotorVel(-5) end),
			FrameEvent(10, function(inst) inst.Physics:SetMotorVel(-4) end),
			FrameEvent(11, function(inst) inst.Physics:SetMotorVel(-3) end),
			FrameEvent(12, function(inst) inst.Physics:SetMotorVel(-2) end),
			FrameEvent(13, function(inst) inst.Physics:SetMotorVel(-1) end),
			FrameEvent(14, function(inst) inst.Physics:SetMotorVel(-.5) end),
			FrameEvent(15, function(inst) inst.Physics:Stop() end),
			--

			FrameEvent(8, function(inst)
				inst.sg:RemoveStateTag("airborne")
				inst.sg:RemoveStateTag("nointerrupt")
			end),
		},

		events =
		{
			EventHandler("animover", function(inst)
				inst.sg:GoToState("idle")
			end),
		},

		onexit = function(inst)
			inst.Physics:Stop()
		end,
	}),

	State({
		name = "phase_transition",
		tags = { "busy", "nointerrupt" },

		onenter = function(inst)
			inst.AnimState:PlayAnimation("phase_transition")
			monsterutil.RemoveStatusEffects(inst)
			inst.components.attacktracker:CancelActiveAttack()

			inst.components.monstertranslator:DisplayMonsterString("thatcher", "THATCHER_PHASE_TRANSITION_1")
		end,

		timeline =
		{
			FrameEvent(72, function(inst)
				inst.sg:AddStateTag("airborne")

				inst.HitBox:SetEnabled(false)
			end),
		},

		events =
		{
			EventHandler("animover", function(inst)
				inst.Transform:SetPosition(BACKGROUND_JUMP_POSITION:Get())
				inst:DoTaskInTime(1, function()
					inst.sg:GoToState("phase_transition_part2")
				end)
			end),
		},
	}),

	State({
		name = "phase_transition_part2",
		tags = { "busy", "nointerrupt" },

		onenter = function(inst)
			-- Face left so positioning on the rock is centered.
			inst.Transform:SetRotation(180)

			inst.AnimState:PlayAnimation("phase_transition_part2")
			inst.components.combat:SetDamageReceivedMult("phase_transition", 0)

			inst.HitBox:SetInvincible(true)
			inst.HitBox:SetEnabled(false)
			inst.Physics:SetEnabled(false)

			inst.components.monstertranslator:DisplayMonsterString("thatcher", "THATCHER_PHASE_TRANSITION_2")

			local current_phase = inst.boss_coro:CurrentPhase()

			-- Timing for spawning permanent acid; stagger from the start of when the acid geysers shoot acid.
			-- Start 70 frames after the geyers shoot out acid.
			inst:DoTaskInAnimFrames(144, function()
				if current_phase == PHASE_2 or not inst.sg.mem.phase2_transition_complete then
					SpawnGeyserAcidPermanent(inst, 1, 2)
					SpawnGeyserAcidPermanent(inst, 2, 2)
				end
				if current_phase == PHASE_3 then
					SpawnGeyserAcidPermanent(inst, 1)
					SpawnGeyserAcidPermanent(inst, 2)
				end
			end)

			inst:DoTaskInAnimFrames(149, function()
				if current_phase == PHASE_2 or not inst.sg.mem.phase2_transition_complete then
					SpawnGeyserAcidPermanent(inst, 3, 2)
					SpawnGeyserAcidPermanent(inst, 4, 2)
				end
				if current_phase == PHASE_3 then
					SpawnGeyserAcidPermanent(inst, 3)
					SpawnGeyserAcidPermanent(inst, 4)
					SpawnGeyserAcidPermanent(inst, 5)
					SpawnGeyserAcidPermanent(inst, 6)
				end
			end)

			inst:DoTaskInAnimFrames(154, function()
				if current_phase == PHASE_2 or not inst.sg.mem.phase2_transition_complete then
					SpawnGeyserAcidPermanent(inst, 5, 2)
					SpawnGeyserAcidPermanent(inst, 6, 2)
				end
				if current_phase == PHASE_3 then
					SpawnGeyserAcidPermanent(inst, 7)
					SpawnGeyserAcidPermanent(inst, 8)
				end
			end)

			inst:DoTaskInAnimFrames(159, function()
				if current_phase == PHASE_2 or not inst.sg.mem.phase2_transition_complete then
					SpawnGeyserAcidPermanent(inst, 7, 2)
					SpawnGeyserAcidPermanent(inst, 8, 2)
				end
				if current_phase == PHASE_3 then
					SpawnGeyserAcidPermanent(inst, 9)
				end
			end)

			inst:DoTaskInAnimFrames(164, function()
				if current_phase == PHASE_2 or not inst.sg.mem.phase2_transition_complete then
					SpawnGeyserAcidPermanent(inst, 9, 2)
					SpawnGeyserAcidPermanent(inst, 10, 2)
				end
			end)
		end,

		timeline =
		{
			FrameEvent(74, function(inst)
				StartAcidGeysers(inst, 1.5)
			end),
			FrameEvent(115, function(inst)
				inst.sg:AddStateTag("airborne")
			end),
		},

		events =
		{
			EventHandler("animover", function(inst)
				local center_pt = spawnutil.GetStartPointFromWorld(0.5, 0.5)
				inst.Transform:SetPosition(center_pt:Get())
				inst.sg:GoToState("phase_transition_pst")
			end),
		},

		onexit = function(inst)
			inst.HitBox:SetInvincible(false)
			inst.HitBox:SetEnabled(true)
			inst.Physics:SetEnabled(true)
			inst.components.combat:RemoveDamageReceivedMult("phase_transition")

			-- Set this flag so that we've already done the phase 2 acid spawning. Needed in case Thatcher skips the transition to phase 2
			local current_phase = inst.boss_coro:CurrentPhase()
			if current_phase == PHASE_2 then
				inst.sg.mem.phase2_transition_complete = true
			end
		end,
	}),

	State({
		name = "phase_transition_pst",
		tags = { "busy", "nointerrupt", "airborne" },

		onenter = function(inst)
			inst.AnimState:PlayAnimation("phase_transition_part3")

			inst.HitBox:SetInvincible(true)
			inst.HitBox:SetEnabled(false)
			inst.Physics:SetEnabled(false)
		end,

		timeline =
		{
			FrameEvent(20, function(inst)
				inst.sg:RemoveStateTag("airborne")
				inst.HitBox:SetInvincible(false)
				inst.HitBox:SetEnabled(true)
				inst.Physics:SetEnabled(true)
			end),
		},

		events =
		{
			EventHandler("animover", function(inst)
				inst.sg:GoToState("idle")
			end),
		},

		onexit = function(inst)
			inst.HitBox:SetInvincible(false)
			inst.HitBox:SetEnabled(true)
			inst.Physics:SetEnabled(true)
			monsterutil.ReinitializeStatusEffects(inst)
		end,
	}),

	State({
		name = "swing_short",
		tags = { "attack", "busy", "nointerrupt" },

		onenter = function(inst)
			inst.AnimState:PlayAnimation("swing_short")
			inst.components.hitbox:StartRepeatTargetDelay()
		end,

		timeline =
		{
			--physics
			FrameEvent(0, function(inst) inst.Physics:SetMotorVel(7) end),
			FrameEvent(8, function(inst) inst.Physics:SetMotorVel(4) end),
			FrameEvent(9, function(inst) inst.Physics:SetMotorVel(3) end),
			FrameEvent(10, function(inst) inst.Physics:SetMotorVel(2) end),
			FrameEvent(11, function(inst) inst.Physics:SetMotorVel(1) end),
			FrameEvent(12, function(inst) inst.Physics:SetMotorVel(.5) end),
			FrameEvent(13, function(inst) inst.Physics:Stop() end),
			--

			--head hitbox
			FrameEvent(4, function(inst) inst.components.offsethitboxes:SetEnabled("offsethitbox", true) end),
			FrameEvent(4, function(inst) inst.components.offsethitboxes:Move("offsethitbox", 1.1) end),
			FrameEvent(6, function(inst) inst.components.offsethitboxes:Move("offsethitbox", 2) end),
			FrameEvent(8, function(inst) inst.components.offsethitboxes:Move("offsethitbox", 1.8) end),
			FrameEvent(10, function(inst) inst.components.offsethitboxes:Move("offsethitbox", 1.6) end),
			FrameEvent(12, function(inst) inst.components.offsethitboxes:Move("offsethitbox", 1.5) end),
			--

			FrameEvent(4, function(inst)
				--inst.components.hitbox:PushOffsetBeam(-8.50, -6.00, 2.50, 1.00, HitPriority.BOSS_DEFAULT)
				inst.components.hitbox:PushOffsetBeam(-6.00, 4.20, 2.38, -1.38, HitPriority.BOSS_DEFAULT)
			end),
			FrameEvent(5, function(inst)
				inst.components.hitbox:PushOffsetBeam(2.50, 10.00, 3.40, 0.90, HitPriority.BOSS_DEFAULT)
				inst.components.hitbox:PushOffsetBeam(8.50, 11.00, 1.60, 5.90, HitPriority.BOSS_DEFAULT)
			end),
			FrameEvent(6, function(inst)
				--inst.components.hitbox:PushOffsetBeam(-2.85, 0.00, 2.75, 3.25, HitPriority.BOSS_DEFAULT)
				inst.components.hitbox:PushOffsetBeam(0.00, 8.70, 4.25, 3.25, HitPriority.BOSS_DEFAULT)
				inst.components.hitbox:PushOffsetBeam(8.70, 10.00, 2.25, 2.25, HitPriority.BOSS_DEFAULT)
			end),
			FrameEvent(7, function(inst)
				--inst.components.hitbox:PushOffsetBeam(-3.00, 0.00, 2.50, 3.50, HitPriority.BOSS_DEFAULT)
				inst.components.hitbox:PushOffsetBeam(0.00, 8.00, 3.00, 3.00, HitPriority.BOSS_DEFAULT)
			end),
			FrameEvent(8, function(inst)
				--inst.components.hitbox:PushOffsetBeam(-5.60, 0.00, 3.00, 3.00, HitPriority.BOSS_DEFAULT)
				inst.components.hitbox:PushOffsetBeam(0.00, 5.20, 3.00, 4.01, HitPriority.BOSS_DEFAULT)
				--inst.sg:AddStateTag("vulnerable")
			end),
		},

		events =
		{
			EventHandler("hitboxtriggered", OnSwingShortHitBoxTriggered),
			EventHandler("animover", function(inst)
				inst.sg:GoToState("swing_up")
			end),
		},

		onexit = function(inst)
			inst.Physics:Stop()
			inst.components.offsethitboxes:SetEnabled("offsethitbox", false)
			inst.components.hitbox:StopRepeatTargetDelay()
		end,
	}),

	State({
		name = "swing_long",
		tags = { "attack", "busy", "nointerrupt"},

		onenter = function(inst)
			inst.AnimState:PlayAnimation("swing_long")
			inst.components.hitbox:StartRepeatTargetDelay()
		end,

		timeline =
		{
			--physics
			FrameEvent(0, function(inst) inst.Physics:SetMotorVel(4) end),
			FrameEvent(6, function(inst) inst.Physics:SetMotorVel(6) end),
			FrameEvent(10, function(inst) inst.Physics:SetMotorVel(10) end),
			FrameEvent(11, function(inst) inst.Physics:SetMotorVel(8) end),
			FrameEvent(13, function(inst) inst.Physics:SetMotorVel(4) end),
			FrameEvent(14, function(inst) inst.Physics:SetMotorVel(3) end),
			FrameEvent(15, function(inst) inst.Physics:SetMotorVel(2) end),
			FrameEvent(16, function(inst) inst.Physics:SetMotorVel(1) end),
			FrameEvent(17, function(inst) inst.Physics:SetMotorVel(.5) end),
			FrameEvent(18, function(inst) inst.Physics:Stop() end),
			--

			--head hitbox
			FrameEvent(9, function(inst) inst.components.offsethitboxes:SetEnabled("offsethitbox", true) end),
			FrameEvent(9, function(inst) inst.components.offsethitboxes:Move("offsethitbox", 1.7) end),
			FrameEvent(11, function(inst) inst.components.offsethitboxes:Move("offsethitbox", 2.8) end),
			FrameEvent(13, function(inst) inst.components.offsethitboxes:Move("offsethitbox", 2.2) end),
			FrameEvent(15, function(inst) inst.components.offsethitboxes:Move("offsethitbox", 1.5) end),
			--

			FrameEvent(6, function(inst)
				--inst.components.hitbox:PushOffsetBeam(-12.50, -11.00, 1.40, 2.40, HitPriority.BOSS_DEFAULT)
				inst.components.hitbox:PushOffsetBeam(-11.00, -5.50, 1.50, 1.50, HitPriority.BOSS_DEFAULT)
			end),
			FrameEvent(7, function(inst)
				--inst.components.hitbox:PushOffsetBeam(-12.50, -11.00, 1.40, 2.40, HitPriority.BOSS_DEFAULT)
				inst.components.hitbox:PushOffsetBeam(-11.00, -5.50, 1.50, 1.50, HitPriority.BOSS_DEFAULT)
			end),
			FrameEvent(8, function(inst)
				--inst.components.hitbox:PushOffsetBeam(-8.50, -6.00, 2.50, 1.00, HitPriority.BOSS_DEFAULT)
				inst.components.hitbox:PushOffsetBeam(-6.00, 4.20, 2.38, -1.38, HitPriority.BOSS_DEFAULT)
			end),
			FrameEvent(9, function(inst)
				inst.components.hitbox:PushOffsetBeam(2.50, 11.50, 3.40, 0.90, HitPriority.BOSS_DEFAULT)
				inst.components.hitbox:PushOffsetBeam(8.50, 12.50, 1.60, 5.90, HitPriority.BOSS_DEFAULT)
			end),
			FrameEvent(10, function(inst)
				--inst.components.hitbox:PushOffsetBeam(-4.40, 0.00, 2.50, 3.50, HitPriority.BOSS_DEFAULT)
				inst.components.hitbox:PushOffsetBeam(0.00, 10.00, 3.75, 3.75, HitPriority.BOSS_DEFAULT)
				inst.components.hitbox:PushOffsetBeam(10.00, 12.50, 3.00, 3.50, HitPriority.BOSS_DEFAULT)
			end),
			FrameEvent(11, function(inst)
				--inst.components.hitbox:PushOffsetBeam(-3.50, 0.00, 2.50, 3.50, HitPriority.BOSS_DEFAULT)
				inst.components.hitbox:PushOffsetBeam(0.00, 10.00, 3.00, 3.00, HitPriority.BOSS_DEFAULT)
			end),
			FrameEvent(12, function(inst)
				--inst.sg:AddStateTag("vulnerable")
				--inst.components.hitbox:PushOffsetBeam(-6.50, 0.00, 3.00, 3.00, HitPriority.BOSS_DEFAULT)
				inst.components.hitbox:PushOffsetBeam(0.00, 5.20, 3.00, 4.01, HitPriority.BOSS_DEFAULT)
			end),
		},

		events =
		{
			EventHandler("hitboxtriggered", OnSwingLongHitBoxTriggered),
			EventHandler("animover", function(inst)
				inst.sg:GoToState("swing_pst", inst.sg.statemem.hit)
			end),
		},

		onexit = function(inst)
			inst.Physics:Stop()
			inst.components.offsethitboxes:SetEnabled("offsethitbox", false)
			inst.components.hitbox:StopRepeatTargetDelay()
			inst.components.attacktracker:CompleteActiveAttack()
		end,
	}),

	State({
		name = "swing_up",
		tags = { "attack", "busy", "nointerrupt" },

		onenter = function(inst)
			inst.AnimState:PlayAnimation("swing_uppercut")

			local target = inst.components.combat:GetTarget()
			if target then
				SGCommon.Fns.FaceActionTarget(inst, target, true)
			end
		end,

		timeline =
		{
			--physics
			FrameEvent(0, function(inst) inst.Physics:SetMotorVel(10) end),
			FrameEvent(6, function(inst) inst.Physics:SetMotorVel(8) end),
			FrameEvent(10, function(inst) inst.Physics:SetMotorVel(6) end),
			FrameEvent(13, function(inst) inst.Physics:Stop() end),
			FrameEvent(16, function(inst) inst.Physics:SetMotorVel(4) end),
			FrameEvent(22, function(inst) inst.Physics:SetMotorVel(6) end),
			FrameEvent(25, function(inst) inst.Physics:SetMotorVel(5) end),
			FrameEvent(28, function(inst) inst.Physics:SetMotorVel(4) end),
			FrameEvent(30, function(inst) inst.Physics:SetMotorVel(8) end),
			FrameEvent(33, function(inst) inst.Physics:SetMotorVel(6) end),
			FrameEvent(34, function(inst) inst.Physics:SetMotorVel(5) end),
			FrameEvent(35, function(inst) inst.Physics:SetMotorVel(4) end),
			FrameEvent(36, function(inst) inst.Physics:SetMotorVel(3) end),
			FrameEvent(37, function(inst) inst.Physics:SetMotorVel(2) end),
			FrameEvent(38, function(inst) inst.Physics:SetMotorVel(1) end),
			FrameEvent(39, function(inst) inst.Physics:SetMotorVel(.5) end),
			FrameEvent(40, function(inst) inst.Physics:Stop() end),
			--

			--headhitbox
			FrameEvent(0, function(inst) inst.components.offsethitboxes:SetEnabled("offsethitbox", true) end),
			FrameEvent(0, function(inst) inst.components.offsethitboxes:Move("offsethitbox", .7) end),
			FrameEvent(2, function(inst) inst.components.offsethitboxes:SetEnabled("offsethitbox", false) end),
			FrameEvent(28, function(inst) inst.components.offsethitboxes:SetEnabled("offsethitbox", true) end),
			FrameEvent(28, function(inst) inst.components.offsethitboxes:Move("offsethitbox", 2.5) end),
			FrameEvent(30, function(inst) inst.components.offsethitboxes:Move("offsethitbox", 3) end),
			FrameEvent(32, function(inst) inst.components.offsethitboxes:SetEnabled("offsethitbox", false) end),
			FrameEvent(51, function(inst) inst.components.offsethitboxes:SetEnabled("offsethitbox", true) end),
			FrameEvent(51, function(inst) inst.components.offsethitboxes:Move("offsethitbox", .7) end),
			FrameEvent(53, function(inst) inst.components.offsethitboxes:Move("offsethitbox", .4) end),
			FrameEvent(55, function(inst) inst.components.offsethitboxes:SetEnabled("offsethitbox", false) end),
			--

			FrameEvent(28, function(inst)
				--inst.components.hitbox:PushOffsetBeam(-6.60, -5.20, 1.55, 0.55, HitPriority.BOSS_DEFAULT)
				inst.components.hitbox:PushOffsetBeam(-5.20, -2.10, 1.50, -0.85, HitPriority.BOSS_DEFAULT)
			end),
			FrameEvent(29, function(inst)
				--inst.components.hitbox:PushOffsetBeam(-6.60, -5.20, 1.55, 0.55, HitPriority.BOSS_DEFAULT)
				inst.components.hitbox:PushOffsetBeam(-5.20, -2.10, 1.50, -0.85, HitPriority.BOSS_DEFAULT)
			end),
			FrameEvent(30, function(inst)
				--inst.components.hitbox:PushOffsetBeam(-5.50, -3.60, 2.20, 0.30, HitPriority.BOSS_DEFAULT)
				--inst.components.hitbox:PushOffsetBeam(-3.60, -1.50, 2.90, -0.90, HitPriority.BOSS_DEFAULT)
				--inst.components.hitbox:PushOffsetBeam(-1.50, 8.20, 3.00, -1.60, HitPriority.BOSS_DEFAULT)

				inst.components.hitbox:PushOffsetBeam(1.20, 8.20, 3.00, -1.60, HitPriority.BOSS_DEFAULT)
				inst.components.hitbox:PushOffsetBeam(8.20, 10.10, 2.65, -0.15, HitPriority.BOSS_DEFAULT)
				inst.components.hitbox:PushOffsetBeam(10.10, 11.50, 2.10, 1.10, HitPriority.BOSS_DEFAULT)
			end),
			FrameEvent(31, function(inst)
				--inst.components.hitbox:PushOffsetBeam(-1.50, 0.60, 1.95, -0.95, HitPriority.BOSS_DEFAULT)
				--inst.components.hitbox:PushOffsetBeam(0.60, 8.20, 3.00, -1.60, HitPriority.BOSS_DEFAULT)

				inst.components.hitbox:PushOffsetBeam(4.50, 8.20, 3.00, -1.60, HitPriority.BOSS_DEFAULT)
				inst.components.hitbox:PushOffsetBeam(8.20, 10.10, 2.70, -0.20, HitPriority.BOSS_DEFAULT)
				inst.components.hitbox:PushOffsetBeam(10.10, 11.50, 2.20, 1.00, HitPriority.BOSS_DEFAULT)
			end),
			FrameEvent(32, function(inst)
				inst.components.hitbox:PushOffsetBeam(4.50, 7.50, 2.60, -0.60, HitPriority.BOSS_DEFAULT)
				inst.components.hitbox:PushOffsetBeam(7.50, 10.00, 2.45, 0.15, HitPriority.BOSS_DEFAULT)
				inst.components.hitbox:PushOffsetBeam(10.00, 11.50, 1.80, 0.80, HitPriority.BOSS_DEFAULT)
				inst.components.hitbox:PushOffsetBeam(11.50, 12.50, 1.05, 1.55, HitPriority.BOSS_DEFAULT)
			end),
			FrameEvent(33, function(inst)
				inst.sg.statemem.is_high = true
				inst.components.hitbox:PushOffsetBeam(1.80, 7.50, 2.60, -0.60, HitPriority.BOSS_DEFAULT)
				inst.components.hitbox:PushOffsetBeam(7.50, 10.00, 2.45, 0.15, HitPriority.BOSS_DEFAULT)
				inst.components.hitbox:PushOffsetBeam(10.00, 11.50, 1.80, 0.80, HitPriority.BOSS_DEFAULT)
				inst.components.hitbox:PushOffsetBeam(11.50, 12.50, 1.05, 1.55, HitPriority.BOSS_DEFAULT)
			end),
		},

		events =
		{
			EventHandler("hitboxtriggered", OnSwingUppercutHitBoxTriggered),
			EventHandler("animover", function(inst)
				if inst.sg.statemem.hit and not inst.components.timer:HasTimer("taunt_cd") then
					inst.sg:GoToState("taunt")
				else
					inst.sg:GoToState("idle")
				end
			end),
		},

		onexit = function(inst)
			inst.Physics:Stop()
			inst.components.offsethitboxes:SetEnabled("offsethitbox", false)
			inst.components.hitbox:StopRepeatTargetDelay()
			inst.components.attacktracker:CompleteActiveAttack()
		end,
	}),

	State({
		name = "swing_pst",
		tags = { "attack", "busy", "nointerrupt" },

		onenter = function(inst, hit)
			inst.AnimState:PlayAnimation("swing_pst")
			inst.sg.statemem.hit = hit
			--inst.sg:AddStateTag("vulnerable")
		end,

		timeline =
		{
			--head hitbox
			FrameEvent(0, function(inst) inst.components.offsethitboxes:SetEnabled("offsethitbox", true) end),
			FrameEvent(0, function(inst) inst.components.offsethitboxes:Move("offsethitbox", 1.3) end),
			FrameEvent(2, function(inst) inst.components.offsethitboxes:Move("offsethitbox", 1.1) end),
			FrameEvent(4, function(inst) inst.components.offsethitboxes:Move("offsethitbox", .6) end),
			FrameEvent(6, function(inst) inst.components.offsethitboxes:Move("offsethitbox", .4) end),
			FrameEvent(8, function(inst) inst.components.offsethitboxes:SetEnabled("offsethitbox", false) end),
			--

			--[[FrameEvent(2, function(inst)
				inst.sg:RemoveStateTag("vulnerable")
			end),]]
			FrameEvent(8, function(inst)
				inst.sg:AddStateTag("caninterrupt")
			end),
		},

		events =
		{
			EventHandler("animover", function(inst)
				if inst.sg.statemem.hit and not inst.components.timer:HasTimer("taunt_cd") then
					inst.sg:GoToState("taunt")
				else
					inst.sg:GoToState("idle")
				end
			end),
		},

		onexit = function(inst)
			inst.components.offsethitboxes:SetEnabled("offsethitbox", false)
		end,
	}),

	--[[State({
		name = "hook",
		tags = { "attack", "busy", "nointerrupt" },

		onenter = function(inst)
			inst.AnimState:PlayAnimation("hook")
			inst.components.hitbox:StartRepeatTargetDelay()
		end,

		timeline =
		{
			-- physics
			FrameEvent(17, function(inst) inst.Physics:SetMotorVel(4) end),
			FrameEvent(20, function(inst) inst.Physics:Stop() end),

			-- hitbox
			FrameEvent(14, function(inst)
				inst.components.hitbox:PushOffsetBeam(-6.00, 2.00, 2.20, -0.60, HitPriority.BOSS_DEFAULT)
			end),
			FrameEvent(16, function(inst)
				inst.components.hitbox:PushOffsetBeam(-8.00, -2.00, 2.20, 2.00, HitPriority.BOSS_DEFAULT)
			end),
			FrameEvent(17, function(inst)
				inst.components.hitbox:PushOffsetBeam(-8.00, 0.00, 3.00, 3.80, HitPriority.BOSS_DEFAULT)
			end),
			FrameEvent(18, function(inst)
				inst.components.hitbox:PushOffsetBeam(-5.00, 4.90, 2.50, 4.20, HitPriority.BOSS_DEFAULT)
			end),
			FrameEvent(19, function(inst)
				inst.components.hitbox:PushOffsetBeam(-2.00, 8.40, 2.50, 3.80, HitPriority.BOSS_DEFAULT)
			end),
			FrameEvent(21, function(inst)
				inst.sg.statemem.do_basic_attack = true
				inst.components.hitbox:PushOffsetBeam(2.00, 10.50, 3.00, 2.00, HitPriority.BOSS_DEFAULT)
			end),
			FrameEvent(23, function(inst)
				inst.components.hitbox:PushOffsetBeam(4.00, 10.50, 2.50, 1.00, HitPriority.BOSS_DEFAULT)
			end),
			FrameEvent(24, function(inst)
				inst.sg.statemem.do_basic_attack = false
				inst.components.hitbox:StopRepeatTargetDelay()
			end),

			FrameEvent(32, function(inst)
				inst.sg.statemem.is_hooking = true
				inst.components.hitbox:StartRepeatTargetDelay()
			end),
			FrameEvent(33, function(inst)
				inst.components.hitbox:PushBeam(3.00, 6.00, 2.00, HitPriority.BOSS_DEFAULT)
			end),
		},

		events =
		{
			EventHandler("hitboxtriggered", OnHookHitBoxTriggered),
			EventHandler("animover", function(inst)
				if inst.sg.statemem.hit then
					inst.sg:GoToState("hook_uppercut")
				else
					inst.sg:GoToState("idle")
				end
			end),
		},

		onexit = function(inst)
			inst.Physics:Stop()
			inst.components.hitbox:StopRepeatTargetDelay()
			inst.components.attacktracker:CompleteActiveAttack()
		end,
	}),

	State({
		name = "hook_uppercut",
		tags = { "attack", "busy", "nointerrupt" },

		onenter = function(inst)
			inst.AnimState:PlayAnimation("hook_shoryuken")
			inst.components.hitbox:StartRepeatTargetDelay()
		end,

		timeline =
		{
			-- tags
			FrameEvent(22, function(inst) inst.sg.AddStateTag("flying_high") end),
			FrameEvent(41, function(inst) inst.sg.RemoveStateTag("flying_high") end),

			-- physics
			-- Code Generated by PivotTrack.jsfl
			FrameEvent(9, function(inst) inst.Physics:MoveRelFacing(160/150) end),
			FrameEvent(11, function(inst) inst.Physics:MoveRelFacing(44/150) end),
			FrameEvent(13, function(inst) inst.Physics:MoveRelFacing(20/150) end),
			FrameEvent(15, function(inst) inst.Physics:MoveRelFacing(12/150) end),
			FrameEvent(18, function(inst) inst.Physics:MoveRelFacing(124/150) end),
			FrameEvent(20, function(inst) inst.Physics:MoveRelFacing(180/150) end),
			FrameEvent(22, function(inst) inst.Physics:MoveRelFacing(180/150) end),
			FrameEvent(24, function(inst) inst.Physics:MoveRelFacing(84/150) end),
			FrameEvent(26, function(inst) inst.Physics:MoveRelFacing(36/150) end),
			FrameEvent(28, function(inst) inst.Physics:MoveRelFacing(52/150) end),
			FrameEvent(31, function(inst) inst.Physics:MoveRelFacing(48/150) end),
			FrameEvent(34, function(inst) inst.Physics:MoveRelFacing(52/150) end),
			FrameEvent(37, function(inst) inst.Physics:MoveRelFacing(52/150) end),
			FrameEvent(39, function(inst) inst.Physics:MoveRelFacing(36/150) end),
			FrameEvent(41, function(inst) inst.Physics:MoveRelFacing(14/150) end),
			-- End Generated Code

			-- hitbox
			FrameEvent(24, function(inst)
				inst.components.hitbox:PushBeam(1.80, 9.00, 2.40, HitPriority.BOSS_DEFAULT)
			end),
			FrameEvent(25, function(inst)
				inst.components.hitbox:PushBeam(4.00, 14.50, 2.40, HitPriority.BOSS_DEFAULT)
			end),
		},

		events =
		{
			EventHandler("hitboxtriggered", OnHookUppercutHitBoxTriggered),
			EventHandler("animover", function(inst)
				if inst.sg.statemem.hit and not inst.components.timer:HasTimer("taunt_cd") then
					inst.sg:GoToState("taunt")
				else
					inst.sg:GoToState("idle")
				end
			end),
		},

		onexit = function(inst)
			inst.Physics:Stop()
			inst.components.hitbox:StopRepeatTargetDelay()
			inst.components.attacktracker:CompleteActiveAttack()
			inst:PushEvent("hook_over")
		end,
	}),]]

	State({
		name = "double_short_slash_reposition",
		tags = { "attack", "busy", "nointerrupt" },

		onenter = function(inst)
			inst.Physics:Stop()

			-- Check the positioning of thatcher to its target & determine what state to play:
			local target = inst.components.combat:GetTarget()
			if target then
				local minx, minz, maxx, maxz = TheWorld.Map:GetWalkableBounds()
				local targetpos = target:GetPosition()
				local pos = inst:GetPosition()
				local is_left_side_closer = pos.x - minx < maxx - pos.x
				local target_offset_facing = 0

				if is_left_side_closer then
					target_offset_facing = 1
					-- In between the side of the level & target; fly through the player & turn around.
					if (pos.x >= minx and pos.x <= targetpos.x) then
						inst.AnimState:PlayAnimation("hop_forward")
					-- The target is in between thatcher & the side of the level, but too close to the side; jump backwards.
					elseif (targetpos.x >= minx and targetpos.x <= pos.x) then
						inst.AnimState:PlayAnimation("backhop")
					end
				else -- right side is closer
					target_offset_facing = -1
					if (pos.x <= maxx and pos.x >= targetpos.x) then
						inst.AnimState:PlayAnimation("hop_forward")
					elseif (targetpos.x <= maxx and targetpos.x >= pos.x) then
						inst.AnimState:PlayAnimation("backhop")
					end
				end

				local move_pos = Vector3(targetpos.x + DOUBLE_SHORT_SLASH_POSITION_OFFSET * target_offset_facing, 0, targetpos.z)
				inst.sg.statemem.movetotask = SGCommon.Fns.MoveToPoint(inst, move_pos, 0.35)
				inst.Physics:StartPassingThroughObjects()
				inst.sg:SetTimeoutAnimFrames(150)
			else
				inst.sg:GoToState("double_short_slash_pre")
			end
		end,

		ontimeout = function(inst)
			TheLog.ch.StateGraph:printf("Warning: Thatcher state %s timed out.", inst.sg.currentstate.name)
			inst.sg:GoToState("double_short_slash_pre")
		end,

		events =
		{
			EventHandler("movetopoint_complete", function(inst)
				local target = inst.components.combat:GetTarget()
				if target then
					SGCommon.Fns.TurnAndActOnTarget(inst, target, true, "double_short_slash_pre", target)
				else
					inst.sg:GoToState("double_short_slash_pre")
				end

			end),
		},

		onexit = function(inst)
			if inst.sg.statemem.movetotask then
				inst.sg.statemem.movetotask:Cancel()
				inst.sg.statemem.movetotask = nil
			end
			inst.Physics:StopPassingThroughObjects()
		end,
	}),

	State({
		name = "double_short_slash",
		tags = { "attack", "busy", "nointerrupt" },

		onenter = function(inst)
			inst.AnimState:PlayAnimation("double_short_slash")
			inst.components.hitbox:StartRepeatTargetDelay()
		end,

		timeline =
		{
			-- physics
			-- Code Generated by PivotTrack.jsfl
			-- MoveRelFacing -> SetMotorVel = (distance: <num>/(150 * frame diff to next)) / (time: 1/30 secs/frame)
			FrameEvent(2, function(inst) inst.Physics:SetMotorVel(22) end),
			FrameEvent(3, function(inst) inst.Physics:SetMotorVel(24) end),
			FrameEvent(4, function(inst) inst.Physics:SetMotorVel(14.5) end),

			FrameEvent(8, function(inst) inst.Physics:SetMotorVel(16) end),
			FrameEvent(11, function(inst) inst.Physics:SetMotorVel(9) end),
			FrameEvent(13, function(inst) inst.Physics:SetMotorVel(3) end),

			FrameEvent(23, function(inst) inst.Physics:SetMotorVel(4) end),
			FrameEvent(25, function(inst) inst.Physics:SetMotorVel(16) end),
			FrameEvent(26, function(inst) inst.Physics:SetMotorVel(12) end),
			FrameEvent(28, function(inst) inst.Physics:SetMotorVel(0) end),
			-- End Generated Code

			-- hitbox
			FrameEvent(13, function(inst)
				inst.components.hitbox:PushBeam(2.50, 7.00, 2.00, HitPriority.BOSS_DEFAULT)
			end),
			FrameEvent(14, function(inst)
				inst.components.hitbox:PushOffsetBeam(1.50, 6.00, 2.40, -1.50, HitPriority.BOSS_DEFAULT)
				inst.components.hitbox:PushOffsetBeam(6.00, 7.00, 2.25, -0.25, HitPriority.BOSS_DEFAULT)
				inst.components.hitbox:PushOffsetBeam(7.00, 7.50, 1.25, 1.25, HitPriority.BOSS_DEFAULT)
			end),
			FrameEvent(15, function(inst)
				inst.components.hitbox:PushOffsetBeam(0.00, 5.00, 2.20, -1.30, HitPriority.BOSS_DEFAULT)
				inst.components.hitbox:PushOffsetBeam(5.00, 6.00, 2.25, -0.25, HitPriority.BOSS_DEFAULT)
				inst.components.hitbox:PushOffsetBeam(6.00, 7.00, 1.75, 0.75, HitPriority.BOSS_DEFAULT)
			end),
			FrameEvent(16, function(inst)
				inst.components.hitbox:PushOffsetBeam(0.00, 5.00, 2.20, -1.30, HitPriority.BOSS_DEFAULT)
				inst.components.hitbox:PushOffsetBeam(5.00, 6.00, 2.25, -0.25, HitPriority.BOSS_DEFAULT)
			end),
			FrameEvent(17, function(inst)
				inst.components.hitbox:PushOffsetBeam(0.00, 5.00, 2.20, -1.30, HitPriority.BOSS_DEFAULT)
			end),

			FrameEvent(18, function(inst)
				inst.components.hitbox:StopRepeatTargetDelay()
			end),

			FrameEvent(22, function(inst)
				inst.sg.statemem.is_second_attack = true
				inst.components.hitbox:StartRepeatTargetDelay()

				-- Face target, but clamped to within a specified angle
				local facingrot = inst.Transform:GetFacingRotation()
				local target = inst.components.combat:GetTarget()
				local diff = nil
				if target and target:IsValid() then
					local dir = inst:GetAngleTo(target)
					diff = ReduceAngle(dir - facingrot)
					if math.abs(diff) >= 90 then
						diff = nil
					end
					if diff == nil then
						local dir = inst.Transform:GetRotation()
						diff = ReduceAngle(dir - facingrot)
					end
					diff = math.clamp(diff, -45, 45)
					inst.Transform:SetRotation(facingrot + diff)
				end
			end),
			FrameEvent(23, function(inst)
				inst.components.hitbox:PushOffsetBeam(-2.00, 2.00, 2.40, -0.20, HitPriority.BOSS_DEFAULT)
			end),
			FrameEvent(24, function(inst)
				inst.components.hitbox:PushOffsetBeam(-2.00, 2.00, 2.40, -0.20, HitPriority.BOSS_DEFAULT)
			end),
			FrameEvent(25, function(inst)
				inst.components.hitbox:PushOffsetBeam(1.80, 8.00, 3.30, -0.30, HitPriority.BOSS_DEFAULT)
				inst.components.hitbox:PushOffsetBeam(8.00, 9.50, 2.75, 0.75, HitPriority.BOSS_DEFAULT)
				inst.components.hitbox:PushOffsetBeam(9.50, 10.50, 2.25, 1.25, HitPriority.BOSS_DEFAULT)
			end),
			FrameEvent(26, function(inst)
				inst.components.hitbox:PushOffsetBeam(-0.50, 1.50, 2.00, 4.00, HitPriority.BOSS_DEFAULT)
				inst.components.hitbox:PushOffsetBeam(1.50, 8.00, 5.05, 1.45, HitPriority.BOSS_DEFAULT)
				inst.components.hitbox:PushOffsetBeam(8.00, 9.50, 4.00, 2.00, HitPriority.BOSS_DEFAULT)
				inst.components.hitbox:PushOffsetBeam(9.50, 10.50, 3.25, 2.25, HitPriority.BOSS_DEFAULT)
				inst.components.hitbox:PushOffsetBeam(10.50, 11.50, 1.50, 3.50, HitPriority.BOSS_DEFAULT)
			end),
		},

		events =
		{
			EventHandler("hitboxtriggered", OnDoubleShortSlashHitBoxTriggered),
			EventHandler("animover", function(inst)
				if inst.sg.statemem.hit and not inst.components.timer:HasTimer("taunt_cd") then
					inst.sg:GoToState("taunt")
				else
					inst.sg:GoToState("idle")
				end
			end),
		},

		onexit = function(inst)
			inst.Physics:Stop()
			inst.components.hitbox:StopRepeatTargetDelay()
			inst.components.attacktracker:CompleteActiveAttack()
		end,
	}),

	--[[State({
		name = "full_swing",
		tags = { "attack", "busy", "nointerrupt" },

		onenter = function(inst)
			inst.AnimState:PlayAnimation("full_swing")
			inst.components.hitbox:StartRepeatTargetDelay()
		end,

		timeline =
		{
			-- hitbox

			-- Swing 1
			FrameEvent(12, function(inst)
				inst.components.hitbox:PushOffsetBeam(-11.00, -3.00, 2.00, 1.00, HitPriority.BOSS_DEFAULT)
			end),
			FrameEvent(14, function(inst)
				inst.components.hitbox:PushOffsetBeam(-8.50, 4.50, 4.00, -1.00, HitPriority.BOSS_DEFAULT)
			end),
			FrameEvent(16, function(inst)
				inst.components.hitbox:PushBeam(2.00, 11.50, 3.00, HitPriority.BOSS_DEFAULT)
			end),
			FrameEvent(18, function(inst)
				inst.components.hitbox:PushOffsetBeam(5.00, 13.00, 4.00, 3.00, HitPriority.BOSS_DEFAULT)
			end),
			FrameEvent(20, function(inst)
				inst.components.hitbox:PushOffsetBeam(1.00, 12.00, 2.00, 5.00, HitPriority.BOSS_DEFAULT)
			end),
			FrameEvent(21, function(inst)
				inst.components.hitbox:PushOffsetBeam(-0.50, 7.00, 2.00, 5.50, HitPriority.BOSS_DEFAULT)
			end),
			FrameEvent(22, function(inst)
				inst.components.hitbox:PushOffsetBeam(-11.50, 0.00, 3.00, 4.00, HitPriority.BOSS_DEFAULT)
			end),
			FrameEvent(24, function(inst)
				inst.components.hitbox:PushOffsetBeam(-9.00, -3.50, 3.00, 2.00, HitPriority.BOSS_DEFAULT)
			end),
			FrameEvent(26, function(inst)
				inst.components.hitbox:PushOffsetBeam(-12.00, -4.50, 3.00, 1.00, HitPriority.BOSS_DEFAULT)
			end),

			-- Swing 2
			FrameEvent(27, function(inst)
				inst.components.hitbox:StopRepeatTargetDelay()

				inst.sg.statemem.is_last_attack = true
				inst.components.hitbox:StartRepeatTargetDelay()
			end),

			FrameEvent(28, function(inst)
				inst.components.hitbox:PushOffsetBeam(-11.00, -3.00, 2.00, 1.00, HitPriority.BOSS_DEFAULT)
			end),
			FrameEvent(30, function(inst)
				inst.components.hitbox:PushOffsetBeam(-8.50, 4.50, 4.00, -1.00, HitPriority.BOSS_DEFAULT)
			end),
			FrameEvent(32, function(inst)
				inst.components.hitbox:PushBeam(2.00, 11.50, 3.00, HitPriority.BOSS_DEFAULT)
			end),
			FrameEvent(34, function(inst)
				inst.components.hitbox:PushOffsetBeam(5.00, 13.00, 4.00, 3.00, HitPriority.BOSS_DEFAULT)
			end),
			FrameEvent(36, function(inst)
				inst.components.hitbox:PushOffsetBeam(1.00, 12.00, 2.00, 5.00, HitPriority.BOSS_DEFAULT)
			end),
			FrameEvent(37, function(inst)
				inst.components.hitbox:PushOffsetBeam(-0.50, 7.00, 2.00, 5.50, HitPriority.BOSS_DEFAULT)
			end),
			FrameEvent(38, function(inst)
				inst.components.hitbox:PushOffsetBeam(-11.50, 0.00, 3.00, 4.00, HitPriority.BOSS_DEFAULT)
			end),
			FrameEvent(40, function(inst)
				inst.components.hitbox:PushOffsetBeam(-9.00, -3.50, 3.00, 2.00, HitPriority.BOSS_DEFAULT)
			end),
			FrameEvent(42, function(inst)
				inst.components.hitbox:PushOffsetBeam(-12.00, -4.50, 3.00, 1.00, HitPriority.BOSS_DEFAULT)
			end),

			-- Finish
			FrameEvent(44, function(inst)
				inst.components.hitbox:PushOffsetBeam(-11.00, -3.00, 2.00, 1.00, HitPriority.BOSS_DEFAULT)
			end),
			FrameEvent(46, function(inst)
				inst.components.hitbox:PushOffsetBeam(-7.00, -1.00, 2.50, -1.50, HitPriority.BOSS_DEFAULT)
			end),
		},

		events =
		{
			EventHandler("hitboxtriggered", OnFullSwingHitBoxTriggered),
			EventHandler("animover", function(inst)
				if inst.sg.statemem.hit and not inst.components.timer:HasTimer("taunt_cd") then
					inst.sg:GoToState("taunt")
				else
					inst.sg:GoToState("idle")
				end
			end),
		},

		onexit = function(inst)
			inst.Physics:Stop()
			inst.components.hitbox:StopRepeatTargetDelay()
			inst.components.attacktracker:CompleteActiveAttack()
			inst:PushEvent("fullswing_over")
		end,
	}),]]

	State({
		name = "full_swing_mobile",
		tags = { "attack", "busy", "nointerrupt" },

		onenter = function(inst)
			inst.AnimState:PlayAnimation("full_swing_mobile_attack_pre")
			inst.components.hitbox:StartRepeatTargetDelay()

			local target = inst.components.combat:GetTarget()
			SGCommon.Fns.FaceTarget(inst, target, true)

			inst.components.monstertranslator:DisplayMonsterString("thatcher", "THATCHER_SPECIAL_1_2")
		end,

		timeline =
		{
			-- hitbox

			-- Swing 1
			FrameEvent(12, function(inst)
				--inst.components.hitbox:PushOffsetBeam(-12.50, -11.00, 1.40, 2.40, HitPriority.BOSS_DEFAULT)
				inst.components.hitbox:PushOffsetBeam(-11.00, -5.50, 1.50, 1.50, HitPriority.BOSS_DEFAULT)
			end),
			FrameEvent(13, function(inst)
				--inst.components.hitbox:PushOffsetBeam(-12.50, -11.00, 1.40, 2.40, HitPriority.BOSS_DEFAULT)
				inst.components.hitbox:PushOffsetBeam(-11.00, -5.50, 1.50, 1.50, HitPriority.BOSS_DEFAULT)
			end),
		},

		events =
		{
			EventHandler("animover", function(inst)
				inst.sg:GoToState("full_swing_mobile_loop")
			end),
		},
	}),

	State({
		name = "full_swing_mobile_loop",
		tags = { "attack", "busy", "nointerrupt" },

		onenter = function(inst, is_last_swing)
			inst.AnimState:PlayAnimation("full_swing_mobile_attack_loop", true)
			inst.components.hitbox:StartRepeatTargetDelay()
			inst.sg.mem.num_loops = inst.sg.mem.num_loops or 1

			inst.sg.statemem.is_last_attack = is_last_swing
			SGCommon.Fns.SetMotorVelScaled(inst, FULL_SWING_MOVE_SPEED)
		end,

		timeline =
		{
			-- hitbox

			-- Swing 1
			FrameEvent(0, function(inst)
				--inst.components.hitbox:PushOffsetBeam(-8.50, -6.00, 2.50, 1.00, HitPriority.BOSS_DEFAULT)
				inst.components.hitbox:PushOffsetBeam(-6.00, 2.80, 2.68, -1.07, HitPriority.BOSS_DEFAULT)
			end),
			FrameEvent(1, function(inst)
				--inst.components.hitbox:PushOffsetBeam(-8.50, -6.00, 2.50, 1.00, HitPriority.BOSS_DEFAULT)
				inst.components.hitbox:PushOffsetBeam(-6.00, 2.80, 2.68, -1.07, HitPriority.BOSS_DEFAULT)
			end),
			FrameEvent(2, function(inst)
				inst.components.hitbox:PushOffsetBeam(2.00, 6.00, 3.33, -0.33, HitPriority.BOSS_DEFAULT)
				inst.components.hitbox:PushBeam(6.00, 9.60, 3.00, HitPriority.BOSS_DEFAULT)
				inst.components.hitbox:PushOffsetBeam(9.60, 10.60, 2.30, 1.20, HitPriority.BOSS_DEFAULT)
			end),
			FrameEvent(3, function(inst)
				inst.components.hitbox:PushOffsetBeam(1.90, 7.00, 0.75, 0.75, HitPriority.BOSS_DEFAULT)
				inst.components.hitbox:PushOffsetBeam(2.00, 6.00, 3.33, -0.33, HitPriority.BOSS_DEFAULT)
				inst.components.hitbox:PushBeam(6.00, 9.60, 3.00, HitPriority.BOSS_DEFAULT)
				inst.components.hitbox:PushOffsetBeam(9.60, 10.60, 2.30, 1.20, HitPriority.BOSS_DEFAULT)
			end),
			FrameEvent(4, function(inst)
				inst.components.hitbox:PushOffsetBeam(1.90, 5.00, 1.00, 1.50, HitPriority.BOSS_DEFAULT)
				inst.components.hitbox:PushBeam(5.00, 9.00, 2.50, HitPriority.BOSS_DEFAULT)
				inst.components.hitbox:PushOffsetBeam(9.00, 10.00, 2.60, 1.40, HitPriority.BOSS_DEFAULT)
				inst.components.hitbox:PushOffsetBeam(10.00, 12.20, 2.95, 3.55, HitPriority.BOSS_DEFAULT)
			end),
			FrameEvent(5, function(inst)
				inst.components.hitbox:PushOffsetBeam(1.90, 5.00, 1.00, 1.50, HitPriority.BOSS_DEFAULT)
				inst.components.hitbox:PushBeam(5.00, 9.00, 2.50, HitPriority.BOSS_DEFAULT)
				inst.components.hitbox:PushOffsetBeam(9.00, 10.00, 2.60, 1.40, HitPriority.BOSS_DEFAULT)
				inst.components.hitbox:PushOffsetBeam(10.00, 12.20, 2.95, 3.55, HitPriority.BOSS_DEFAULT)
			end),
			FrameEvent(6, function(inst)
				--inst.components.hitbox:PushOffsetBeam(9.50, 11.50, 2.75, 2.75, HitPriority.BOSS_DEFAULT)
				inst.components.hitbox:PushOffsetBeam(7.50, 9.50, 2.00, 5.50, HitPriority.BOSS_DEFAULT)
				inst.components.hitbox:PushOffsetBeam(4.00, 7.50, 2.00, 7.00, HitPriority.BOSS_DEFAULT)
				inst.components.hitbox:PushOffsetBeam(3.00, 4.00, 2.25, 6.25, HitPriority.BOSS_DEFAULT)
				inst.components.hitbox:PushOffsetBeam(1.00, 3.00, 2.50, 4.50, HitPriority.BOSS_DEFAULT)
			end),
			FrameEvent(7, function(inst)
				--inst.components.hitbox:PushOffsetBeam(9.50, 11.50, 2.75, 2.75, HitPriority.BOSS_DEFAULT)
				inst.components.hitbox:PushOffsetBeam(7.50, 9.50, 2.00, 5.50, HitPriority.BOSS_DEFAULT)
				inst.components.hitbox:PushOffsetBeam(4.00, 7.50, 2.00, 7.00, HitPriority.BOSS_DEFAULT)
				inst.components.hitbox:PushOffsetBeam(3.00, 4.00, 2.25, 6.25, HitPriority.BOSS_DEFAULT)
				inst.components.hitbox:PushOffsetBeam(1.00, 3.00, 2.50, 4.50, HitPriority.BOSS_DEFAULT)
			end),
			FrameEvent(8, function(inst)
				--inst.components.hitbox:PushOffsetBeam(4.50, 8.00, 1.00, 9.00, HitPriority.BOSS_DEFAULT)
				inst.components.hitbox:PushOffsetBeam(1.00, 4.50, 2.75, 7.75, HitPriority.BOSS_DEFAULT)
				inst.components.hitbox:PushOffsetBeam(0.00, 1.00, 2.25, 6.25, HitPriority.BOSS_DEFAULT)
				inst.components.hitbox:PushOffsetBeam(-2.00, 0.00, 2.50, 4.50, HitPriority.BOSS_DEFAULT)
			end),
			FrameEvent(9, function(inst)
				--inst.components.hitbox:PushOffsetBeam(4.50, 8.00, 1.00, 9.00, HitPriority.BOSS_DEFAULT)
				inst.components.hitbox:PushOffsetBeam(1.00, 4.50, 2.75, 7.75, HitPriority.BOSS_DEFAULT)
				inst.components.hitbox:PushOffsetBeam(0.00, 1.00, 2.25, 6.25, HitPriority.BOSS_DEFAULT)
				inst.components.hitbox:PushOffsetBeam(-2.00, 0.00, 2.50, 4.50, HitPriority.BOSS_DEFAULT)
			end),
			FrameEvent(10, function(inst)
				--inst.components.hitbox:PushOffsetBeam(0.00, 3.00, 1.00, 11.00, HitPriority.BOSS_DEFAULT)
				inst.components.hitbox:PushOffsetBeam(-1.50, 0.00, 5.25, 6.75, HitPriority.BOSS_DEFAULT)
				inst.components.hitbox:PushOffsetBeam(-4.50, -1.50, 1.50, 10.50, HitPriority.BOSS_DEFAULT)
			end),
			FrameEvent(11, function(inst)
				--inst.components.hitbox:PushOffsetBeam(0.00, 3.00, 1.00, 11.00, HitPriority.BOSS_DEFAULT)
				inst.components.hitbox:PushOffsetBeam(-1.50, 0.00, 5.25, 6.75, HitPriority.BOSS_DEFAULT)
				inst.components.hitbox:PushOffsetBeam(-4.50, -1.50, 1.50, 10.50, HitPriority.BOSS_DEFAULT)
			end),
			FrameEvent(12, function(inst)
				inst.components.hitbox:PushOffsetBeam(-9.00, -8.00, 1.50, 6.50, HitPriority.BOSS_DEFAULT)
				inst.components.hitbox:PushOffsetBeam(-8.00, -5.00, 2.00, 8.00, HitPriority.BOSS_DEFAULT)
				inst.components.hitbox:PushOffsetBeam(-5.00, -3.00, 2.30, 8.70, HitPriority.BOSS_DEFAULT)
				inst.components.hitbox:PushOffsetBeam(-3.00, -2.00, 2.25, 4.25, HitPriority.BOSS_DEFAULT)
			end),
			FrameEvent(13, function(inst)
				inst.components.hitbox:PushOffsetBeam(-9.00, -8.00, 1.50, 6.50, HitPriority.BOSS_DEFAULT)
				inst.components.hitbox:PushOffsetBeam(-8.00, -5.00, 2.00, 8.00, HitPriority.BOSS_DEFAULT)
				inst.components.hitbox:PushOffsetBeam(-5.00, -3.00, 2.30, 8.70, HitPriority.BOSS_DEFAULT)
				inst.components.hitbox:PushOffsetBeam(-3.00, -2.00, 2.25, 4.25, HitPriority.BOSS_DEFAULT)
			end),
			FrameEvent(14, function(inst)
				inst.components.hitbox:PushOffsetBeam(-11.00, -10.00, 2.50, 5.50, HitPriority.BOSS_DEFAULT)
				inst.components.hitbox:PushOffsetBeam(-10.00, -8.00, 2.50, 7.00, HitPriority.BOSS_DEFAULT)
				inst.components.hitbox:PushOffsetBeam(-8.00, -6.00, 2.25, 6.25, HitPriority.BOSS_DEFAULT)
				inst.components.hitbox:PushOffsetBeam(-6.00, -5.00, 1.50, 4.50, HitPriority.BOSS_DEFAULT)
				inst.components.hitbox:PushOffsetBeam(-5.00, -4.00, 1.50, 3.00, HitPriority.BOSS_DEFAULT)
				inst.components.hitbox:PushOffsetBeam(-4.00, -2.00, 0.75, 1.75, HitPriority.BOSS_DEFAULT)
			end),
			FrameEvent(15, function(inst)
				inst.components.hitbox:PushOffsetBeam(-11.00, -10.00, 2.50, 5.50, HitPriority.BOSS_DEFAULT)
				inst.components.hitbox:PushOffsetBeam(-10.00, -8.00, 2.50, 7.00, HitPriority.BOSS_DEFAULT)
				inst.components.hitbox:PushOffsetBeam(-8.00, -6.00, 2.25, 6.25, HitPriority.BOSS_DEFAULT)
				inst.components.hitbox:PushOffsetBeam(-6.00, -5.00, 1.50, 4.50, HitPriority.BOSS_DEFAULT)
				inst.components.hitbox:PushOffsetBeam(-5.00, -4.00, 1.50, 3.00, HitPriority.BOSS_DEFAULT)
				inst.components.hitbox:PushOffsetBeam(-4.00, -2.00, 0.75, 1.75, HitPriority.BOSS_DEFAULT)
			end),
			FrameEvent(16, function(inst)
				inst.components.hitbox:PushOffsetBeam(-12.00, -11.00, 3.75, 5.25, HitPriority.BOSS_DEFAULT)
				inst.components.hitbox:PushOffsetBeam(-11.00, -9.00, 5.00, 5.00, HitPriority.BOSS_DEFAULT)
				inst.components.hitbox:PushOffsetBeam(-9.00, -5.50, 2.50, 1.50, HitPriority.BOSS_DEFAULT)
				inst.components.hitbox:PushOffsetBeam(-5.50, -2.80, 1.00, 0.50, HitPriority.BOSS_DEFAULT)
			end),
			FrameEvent(17, function(inst)
				inst.components.hitbox:PushOffsetBeam(-12.00, -11.00, 3.75, 5.25, HitPriority.BOSS_DEFAULT)
				inst.components.hitbox:PushOffsetBeam(-11.00, -9.00, 5.00, 5.00, HitPriority.BOSS_DEFAULT)
				inst.components.hitbox:PushOffsetBeam(-9.00, -5.50, 2.50, 1.50, HitPriority.BOSS_DEFAULT)
				inst.components.hitbox:PushOffsetBeam(-5.50, -2.80, 1.00, 0.50, HitPriority.BOSS_DEFAULT)
			end),
		},

		events =
		{
			EventHandler("hitboxtriggered", OnFullSwingMobileHitBoxTriggered),
			EventHandler("animover", function(inst)

				if inst.sg.mem.num_loops and inst.sg.mem.num_loops >= FULL_SWING_MOBILE_LOOPS then
					inst.sg.mem.num_loops = nil
					inst.sg:GoToState("full_swing_mobile_pst", inst.sg.statemem.hit)
				else
					inst.sg.mem.num_loops = (inst.sg.mem.num_loops or 0) + 1
					local is_last_swing = inst.sg.mem.num_loops == FULL_SWING_MOBILE_LOOPS
					inst.sg:GoToState("full_swing_mobile_loop", is_last_swing)
				end
			end),
		},

		onexit = function(inst)
			inst.Physics:Stop()
			inst.components.hitbox:StopRepeatTargetDelay()
		end,
	}),

	State({
		name = "full_swing_mobile_pst",
		tags = { "attack", "busy", "nointerrupt" },

		onenter = function(inst, hit)
			inst.AnimState:PlayAnimation("full_swing_mobile_attack")
			inst.components.hitbox:StopRepeatTargetDelay()
			inst.components.attacktracker:CompleteActiveAttack()
			inst:PushEvent("fullswing_mobile_over")

			inst.sg.statemem.hit = hit
		end,

		events =
		{
			EventHandler("animover", function(inst)
				if inst.sg.statemem.hit and not inst.components.timer:HasTimer("taunt_cd") then
					inst.sg:GoToState("taunt")
				else
					inst.sg:GoToState("idle")
				end
			end),
		},
	}),

	State({
		name = "dash_uppercut_reposition",
		tags = { "attack", "busy", "nointerrupt" },

		onenter = function(inst)
			-- Determine which hop animation and to play and target position depending on its current position & facing.
			local facing = inst.Transform:GetFacing() == FACING_LEFT and -1 or 1
			local pos = inst:GetPosition()

			local midpoint = spawnutil.GetStartPointFromWorld(0.5, 0.5)
			local targetpercent = pos.x < midpoint.x and 0.25 or 0.75
			local targetpos = spawnutil.GetStartPointFromWorld(targetpercent, 0.4)

			if facing < 0 and targetpercent > 0.5 or facing >= 0 and targetpercent < 0.5 then
				inst.AnimState:PlayAnimation("backhop")
			else
				inst.AnimState:PlayAnimation("hop_forward")
			end

			-- Moving to an non-walkable point. Re-position.
			if not TheWorld.Map:IsWalkableAtXZ(targetpos.x, targetpos.z) then
				targetpos = TheWorld.Map:FindClosestPointOnWalkableBoundary(targetpos)
			end

			inst.Physics:StartPassingThroughObjects()

			-- Move to a point in front/back from where the player is standing, within acid spit range
			inst.sg.statemem.movetotask = SGCommon.Fns.MoveToPoint(inst, targetpos, 0.35)
			inst.sg:SetTimeoutAnimFrames(150)
		end,

		ontimeout = function(inst)
			TheLog.ch.StateGraph:printf("Warning: Thatcher state %s timed out.", inst.sg.currentstate.name)
			inst.sg:GoToState("dash_uppercut_pre")
		end,

		events =
		{
			EventHandler("movetopoint_complete", function(inst)
				local target = inst.components.combat:GetTarget()
				if target then
					SGCommon.Fns.TurnAndActOnTarget(inst, target, true, "dash_uppercut_pre", target)
				else
					inst.sg:GoToState("dash_uppercut_pre")
				end

			end),
		},

		onexit = function(inst)
			if inst.sg.statemem.movetotask then
				inst.sg.statemem.movetotask:Cancel()
				inst.sg.statemem.movetotask = nil
			end
			inst.Physics:StopPassingThroughObjects()
		end,
	}),

	State({
		name = "dash_uppercut",
		tags = { "attack", "busy", "nointerrupt" },

		onenter = function(inst)
			inst.AnimState:PlayAnimation("shoryuken_dash_pre")
			inst.components.hitbox:StartRepeatTargetDelay()

			inst.components.monstertranslator:DisplayMonsterString("thatcher", "THATCHER_SPECIAL_2_2")
		end,

		timeline =
		{
			FrameEvent(18, function(inst)
				--inst.components.hitbox:PushBeam(0.50, 7.00, 2.50, HitPriority.BOSS_DEFAULT)
				inst.components.hitbox:PushCircle(1.50, 0.00, 2.50, HitPriority.BOSS_DEFAULT)
			end),
			FrameEvent(19, function(inst)
				--inst.components.hitbox:PushBeam(0.50, 7.00, 2.50, HitPriority.BOSS_DEFAULT)
				inst.components.hitbox:PushCircle(1.50, 0.00, 2.50, HitPriority.BOSS_DEFAULT)
			end),
			FrameEvent(20, function(inst)
				--inst.components.hitbox:PushBeam(0.50, 7.00, 2.50, HitPriority.BOSS_DEFAULT)
				inst.components.hitbox:PushCircle(1.50, 0.00, 2.50, HitPriority.BOSS_DEFAULT)
			end),

			FrameEvent(18, function(inst)
				local target = inst.components.combat:GetTarget()
				SGCommon.Fns.FaceTarget(inst, target, true)

				inst.Physics:StartPassingThroughObjects()
				SGCommon.Fns.SetMotorVelScaled(inst, UPPERCUT_DASH_MOVE_SPEED)
			end),
		},

		events =
		{
			EventHandler("hitboxtriggered", OnDashHitBoxTriggered),
			EventHandler("hitboxcollided_invincible_target", function(inst)
				-- If close to a player but haven't hit them because they dodged, transition into the uppercut
				if not inst.sg:GetCurrentState().name ~= "dash_uppercut_atk" then
					inst.sg:GoToState("dash_uppercut_atk")
				end
			end),
			EventHandler("animover", function(inst)
				inst.sg:GoToState("dash_uppercut_loop")
			end),
		},

		onexit = function(inst)
			inst.Physics:Stop()
			inst.Physics:StopPassingThroughObjects()
		end,
	}),

	State({
		name = "dash_uppercut_loop",
		tags = { "attack", "busy", "nointerrupt" },

		onenter = function(inst)
			inst.AnimState:PlayAnimation("shoryuken_dash_loop", true)
			inst.sg:SetTimeout(5)

			inst.Physics:StartPassingThroughObjects()
			SGCommon.Fns.SetMotorVelScaled(inst, UPPERCUT_DASH_MOVE_SPEED)

			-- StartRepeatTargetDelay called in dash_uppercut & stopped in this state.
		end,

		onupdate = function(inst)
			--inst.components.hitbox:PushBeam(0.50, 7.00, 2.50, HitPriority.BOSS_DEFAULT)
			inst.components.hitbox:PushCircle(1.50, 0.00, 2.50, HitPriority.BOSS_DEFAULT)
		end,

		events =
		{
			EventHandler("hitboxtriggered", OnDashHitBoxTriggered),
			EventHandler("hitboxcollided_invincible_target", function(inst)
				-- If close to a player but haven't hit them because they dodged, transition into the uppercut
				if not inst.sg:GetCurrentState().name ~= "dash_uppercut_atk" then
					inst.sg:GoToState("dash_uppercut_atk")
				end
			end),
			EventHandler("mapcollision", function(inst)
				inst.sg.statemem.is_map_collision = true
				inst.sg:GoToState("dash_uppercut_atk")
			end),
		},

		ontimeout = function(inst)
			inst.sg:GoToState("dash_uppercut_atk")
		end,

		onexit = function(inst)
			inst.Physics:Stop()

			-- If we came here via the mapcollision event handler, we need to delay running Physics:StopPassingThroughObjects() for a tick otherwise a hard crash occurs.
			if inst.sg.statemem.is_map_collision then
				inst:DoTaskInTime(0, function() inst.Physics:StopPassingThroughObjects() end)
			else
				inst.Physics:StopPassingThroughObjects()
			end
			inst.components.hitbox:StopRepeatTargetDelay()
		end,
	}),

	State({
		name = "dash_uppercut_atk",
		tags = { "attack", "busy", "nointerrupt" },

		onenter = function(inst)
			inst.AnimState:PlayAnimation("shoryuken")
			inst.components.hitbox:StartRepeatTargetDelay()
			inst.Physics:StartPassingThroughObjects()
		end,

		timeline =
		{
			-- physics
			FrameEvent(11, function(inst) inst.Physics:SetMotorVel(44) end),
			FrameEvent(12, function(inst) inst.Physics:SetMotorVel(22) end),
			FrameEvent(14, function(inst) inst.Physics:SetMotorVel(10) end),
			FrameEvent(16, function(inst) inst.Physics:SetMotorVel(4.4) end),
			FrameEvent(18, function(inst) inst.Physics:SetMotorVel(4.2) end),
			FrameEvent(21, function(inst) inst.Physics:SetMotorVel(3.9) end),
			FrameEvent(24, function(inst) inst.Physics:SetMotorVel(2.9) end),
			FrameEvent(27, function(inst) inst.Physics:SetMotorVel(6.4) end),
			FrameEvent(29, function(inst) inst.Physics:SetMotorVel(4.4) end),
			FrameEvent(31, function(inst) inst.Physics:SetMotorVel(3.4) end),
			FrameEvent(32, function(inst) inst.Physics:Stop() end),

			-- hitbox
			FrameEvent(9, function(inst)
				inst.components.hitbox:PushBeam(-7.50, -2.00, 2.00, HitPriority.BOSS_DEFAULT)
			end),
			FrameEvent(10, function(inst)
				inst.components.hitbox:PushBeam(-7.50, -2.00, 2.00, HitPriority.BOSS_DEFAULT)
			end),
			FrameEvent(11, function(inst)
				inst.components.hitbox:PushBeam(-5.20, 0.50, 2.00, HitPriority.BOSS_DEFAULT)
			end),
			FrameEvent(12, function(inst)
				inst.components.hitbox:PushOffsetBeam(-7.50, -2.00, 2.50, -1.50, HitPriority.BOSS_DEFAULT)
				inst.components.hitbox:PushOffsetBeam(-2.00, 1.00, 2.50, -0.50, HitPriority.BOSS_DEFAULT)
			end),
			FrameEvent(13, function(inst)
				inst.components.hitbox:PushOffsetBeam(-4.50, -2.00, 2.50, -1.50, HitPriority.BOSS_DEFAULT)
				inst.components.hitbox:PushOffsetBeam(-2.00, 3.50, 2.75, -0.75, HitPriority.BOSS_DEFAULT)
			end),
			FrameEvent(14, function(inst)
				inst.components.hitbox:PushOffsetBeam(-1.00, 5.00, 2.50, -1.00, HitPriority.BOSS_DEFAULT)
				inst.components.hitbox:PushBeam(5.00, 7.00, 2.50, HitPriority.BOSS_DEFAULT)
				inst.components.hitbox:PushOffsetBeam(7.00, 9.00, 2.50, 1.00, HitPriority.BOSS_DEFAULT)
				inst.components.hitbox:PushOffsetBeam(9.00, 10.00, 1.50, 2.00, HitPriority.BOSS_DEFAULT)
			end),
			FrameEvent(15, function(inst)
				inst.components.hitbox:PushOffsetBeam(-1.00, 5.00, 2.50, -1.00, HitPriority.BOSS_DEFAULT)
				inst.components.hitbox:PushBeam(5.00, 7.00, 2.50, HitPriority.BOSS_DEFAULT)
				inst.components.hitbox:PushOffsetBeam(7.00, 9.00, 2.50, 1.00, HitPriority.BOSS_DEFAULT)
				inst.components.hitbox:PushOffsetBeam(9.00, 10.00, 1.50, 2.00, HitPriority.BOSS_DEFAULT)
			end),
			FrameEvent(16, function(inst)
				inst.components.hitbox:PushOffsetBeam(5.00, 12.00, 3.00, 1.00, HitPriority.BOSS_DEFAULT)
			end),
			FrameEvent(17, function(inst)
				inst.components.hitbox:PushOffsetBeam(5.00, 12.00, 3.00, 1.00, HitPriority.BOSS_DEFAULT)
			end),

			FrameEvent(31, function(inst)
				inst.components.hitbox:PushCircle(1.00, 0.00, 1.50, HitPriority.BOSS_DEFAULT)
			end),
			FrameEvent(32, function(inst)
				inst.components.hitbox:PushCircle(1.00, 0.00, 2.25, HitPriority.BOSS_DEFAULT)
			end),
			FrameEvent(33, function(inst)
				inst.components.hitbox:PushCircle(1.00, 0.00, 3.00, HitPriority.BOSS_DEFAULT)
			end),
			FrameEvent(34, function(inst)
				inst.components.hitbox:PushCircle(1.00, 0.00, 3.00, HitPriority.BOSS_DEFAULT)
			end),

			-- i-frames
			FrameEvent(9, function(inst)
				inst.HitBox:SetEnabled(false)
			end),
			FrameEvent(14, function(inst)
				inst.HitBox:SetEnabled(true)
			end),

			-- State tags, hitflags
			FrameEvent(11, function(inst)
				inst.sg:AddStateTag("airborne")
			end),
			FrameEvent(14, function(inst)
				inst.sg:AddStateTag("airborne_high")
			end),
			FrameEvent(16, function(inst)
				inst.sg.statemem.is_air_attack = true
			end),
			FrameEvent(29, function(inst)
				inst.sg:RemoveStateTag("airborne_high")
			end),
			FrameEvent(31, function(inst)
				inst.sg.statemem.is_air_attack = nil
				inst.sg:RemoveStateTag("airborne")
			end),
		},

		events =
		{
			EventHandler("hitboxtriggered", OnDashUppercutHitBoxTriggered),
			EventHandler("animover", function(inst)
				if inst.sg.statemem.hit and not inst.components.timer:HasTimer("taunt_cd") then
					inst.sg:GoToState("taunt")
				else
					inst.sg:GoToState("idle")
				end
			end),
		},

		onexit = function(inst)
			inst.Physics:Stop()
			inst.Physics:StopPassingThroughObjects()
			inst.HitBox:SetEnabled(true)
			inst.components.hitbox:StopRepeatTargetDelay()
			inst.components.attacktracker:CompleteActiveAttack()
			inst:PushEvent("dash_uppercut_over")
		end,
	}),

	State({
		name = "swing_smash_reposition",
		tags = { "attack", "busy", "nointerrupt" },

		onenter = function(inst)
			-- Determine which hop animation and to play and target position depending on its current position & facing.
			local facing = inst.Transform:GetFacing() == FACING_LEFT and -1 or 1
			local pos = inst:GetPosition()

			local midpoint = spawnutil.GetStartPointFromWorld(0.5, 0.5)
			local targetpercent = pos.x < midpoint.x and 0.25 or 0.75
			local targetpos = spawnutil.GetStartPointFromWorld(targetpercent, 0.4)

			if facing < 0 and targetpercent > 0.5 or facing >= 0 and targetpercent < 0.5 then
				inst.AnimState:PlayAnimation("backhop")
			else
				inst.AnimState:PlayAnimation("hop_forward")
			end

			-- Moving to an non-walkable point. Re-position.
			if not TheWorld.Map:IsWalkableAtXZ(targetpos.x, targetpos.z) then
				targetpos = TheWorld.Map:FindClosestPointOnWalkableBoundary(targetpos)
			end

			inst.Physics:StartPassingThroughObjects()

			-- Move to a point in front/back from where the player is standing, within acid spit range
			inst.sg.statemem.movetotask = SGCommon.Fns.MoveToPoint(inst, targetpos, 0.35)
			inst.sg:SetTimeoutAnimFrames(150)
		end,

		ontimeout = function(inst)
			TheLog.ch.StateGraph:printf("Warning: Thatcher state %s timed out.", inst.sg.currentstate.name)
			inst.sg:GoToState("swing_smash_pre")
		end,

		events =
		{
			EventHandler("movetopoint_complete", function(inst)
				local target = inst.components.combat:GetTarget()
				if target then
					SGCommon.Fns.TurnAndActOnTarget(inst, target, true, "swing_smash_pre", target)
				else
					inst.sg:GoToState("swing_smash_pre")
				end

			end),
		},

		onexit = function(inst)
			if inst.sg.statemem.movetotask then
				inst.sg.statemem.movetotask:Cancel()
				inst.sg.statemem.movetotask = nil
			end
			inst.Physics:StopPassingThroughObjects()
		end,
	}),

	State({
		name = "swing_smash",
		tags = { "attack", "busy", "nointerrupt" },

		onenter = function(inst)
			inst.AnimState:PlayAnimation("swing_smash")
			inst.components.hitbox:StartRepeatTargetDelay()

			inst.components.monstertranslator:DisplayMonsterString("thatcher", "THATCHER_SPECIAL_3_2")
			inst:SnapToFacingRotation()
		end,

		timeline =
		{
			-- physics
			-- Code Generated by PivotTrack.jsfl
			-- MoveRelFacing -> SetMotorVel = (distance: <num>/(150 * frame diff to next)) / (time: 1/30 secs/frame)
			FrameEvent(14, function(inst) inst.Physics:SetMotorVel(5) end),
			FrameEvent(16, function(inst) inst.Physics:SetMotorVel(10) end),
			FrameEvent(18, function(inst) inst.Physics:SetMotorVel(5) end),

			FrameEvent(27, function(inst) inst.Physics:SetMotorVel(8) end),
			FrameEvent(28, function(inst) inst.Physics:SetMotorVel(12) end),
			FrameEvent(30, function(inst) inst.Physics:SetMotorVel(14) end),
			FrameEvent(32, function(inst) inst.Physics:SetMotorVel(9) end),
			FrameEvent(34, function(inst) inst.Physics:SetMotorVel(8) end),

			FrameEvent(44, function(inst) inst.Physics:SetMotorVel(12) end),
			FrameEvent(46, function(inst) inst.Physics:SetMotorVel(14) end),
			FrameEvent(48, function(inst) inst.Physics:SetMotorVel(13) end),
			FrameEvent(50, function(inst) inst.Physics:SetMotorVel(9) end),
			FrameEvent(52, function(inst) inst.Physics:SetMotorVel(10) end),
			FrameEvent(54, function(inst) inst.Physics:SetMotorVel(5) end),
			FrameEvent(56, function(inst) inst.Physics:SetMotorVel(12) end),
			FrameEvent(58, function(inst) inst.Physics:SetMotorVel(14) end),
			FrameEvent(60, function(inst) inst.Physics:SetMotorVel(14) end),
			FrameEvent(61, function(inst) inst.Physics:SetMotorVel(11) end),
			FrameEvent(62, function(inst) inst.Physics:SetMotorVel(0) end),
			-- End Generated Code

			-- hitbox
			-- Swing 1
			FrameEvent(10, function(inst)
				--inst.components.hitbox:PushOffsetBeam(-12.50, -11.00, 1.40, 2.40, HitPriority.BOSS_DEFAULT)
				inst.components.hitbox:PushOffsetBeam(-11.00, -5.50, 1.50, 1.50, HitPriority.BOSS_DEFAULT)
			end),
			FrameEvent(11, function(inst)
				--inst.components.hitbox:PushOffsetBeam(-12.50, -11.00, 1.40, 2.40, HitPriority.BOSS_DEFAULT)
				inst.components.hitbox:PushOffsetBeam(-11.00, -5.50, 1.50, 1.50, HitPriority.BOSS_DEFAULT)
			end),
			FrameEvent(12, function(inst)
				--inst.components.hitbox:PushOffsetBeam(-8.50, -6.00, 2.50, 1.00, HitPriority.BOSS_DEFAULT)
				inst.components.hitbox:PushOffsetBeam(-6.00, 5.50, 2.38, -1.38, HitPriority.BOSS_DEFAULT)
			end),
			FrameEvent(13, function(inst)
				--inst.components.hitbox:PushOffsetBeam(-8.50, -6.00, 2.50, 1.00, HitPriority.BOSS_DEFAULT)
				inst.components.hitbox:PushOffsetBeam(-6.00, 5.50, 2.38, -1.38, HitPriority.BOSS_DEFAULT)
			end),
			FrameEvent(14, function(inst)
				inst.components.hitbox:PushOffsetBeam(3.00, 6.00, 3.33, -0.33, HitPriority.BOSS_DEFAULT)
				inst.components.hitbox:PushBeam(6.00, 9.60, 3.00, HitPriority.BOSS_DEFAULT)
				inst.components.hitbox:PushOffsetBeam(9.60, 11.00, 2.30, 1.20, HitPriority.BOSS_DEFAULT)
			end),
			FrameEvent(15, function(inst)
				inst.components.hitbox:PushOffsetBeam(3.00, 6.00, 3.33, -0.33, HitPriority.BOSS_DEFAULT)
				inst.components.hitbox:PushBeam(6.00, 9.60, 3.00, HitPriority.BOSS_DEFAULT)
				inst.components.hitbox:PushOffsetBeam(9.60, 11.00, 2.30, 1.20, HitPriority.BOSS_DEFAULT)
				inst.components.hitbox:PushOffsetBeam(11.00, 11.80, 1.50, 2.00, HitPriority.BOSS_DEFAULT)
			end),
			FrameEvent(16, function(inst)
				inst.components.hitbox:PushOffsetBeam(1.90, 5.00, 1.00, 1.50, HitPriority.BOSS_DEFAULT)
				inst.components.hitbox:PushBeam(5.00, 8.00, 2.50, HitPriority.BOSS_DEFAULT)
				inst.components.hitbox:PushOffsetBeam(8.00, 10.00, 3.10, 1.90, HitPriority.BOSS_DEFAULT)
				inst.components.hitbox:PushOffsetBeam(10.00, 11.50, 3.25, 3.25, HitPriority.BOSS_DEFAULT)
			end),
			FrameEvent(17, function(inst)
				inst.components.hitbox:PushOffsetBeam(1.90, 5.00, 1.00, 1.50, HitPriority.BOSS_DEFAULT)
				inst.components.hitbox:PushBeam(5.00, 8.00, 2.50, HitPriority.BOSS_DEFAULT)
				inst.components.hitbox:PushOffsetBeam(8.00, 10.00, 3.10, 1.90, HitPriority.BOSS_DEFAULT)
				inst.components.hitbox:PushOffsetBeam(10.00, 11.50, 3.25, 3.25, HitPriority.BOSS_DEFAULT)
			end),
			FrameEvent(18, function(inst)
				--inst.components.hitbox:PushOffsetBeam(9.50, 11.50, 2.75, 2.75, HitPriority.BOSS_DEFAULT)
				inst.components.hitbox:PushOffsetBeam(7.50, 9.50, 2.00, 5.50, HitPriority.BOSS_DEFAULT)
				inst.components.hitbox:PushOffsetBeam(4.00, 7.50, 2.00, 7.00, HitPriority.BOSS_DEFAULT)
				inst.components.hitbox:PushOffsetBeam(3.00, 4.00, 2.25, 6.25, HitPriority.BOSS_DEFAULT)
				inst.components.hitbox:PushOffsetBeam(1.00, 3.00, 2.50, 4.50, HitPriority.BOSS_DEFAULT)
			end),
			FrameEvent(19, function(inst)
				--inst.components.hitbox:PushOffsetBeam(9.50, 11.50, 2.75, 2.75, HitPriority.BOSS_DEFAULT)
				inst.components.hitbox:PushOffsetBeam(7.50, 9.50, 2.00, 5.50, HitPriority.BOSS_DEFAULT)
				inst.components.hitbox:PushOffsetBeam(4.00, 7.50, 2.00, 7.00, HitPriority.BOSS_DEFAULT)
				inst.components.hitbox:PushOffsetBeam(3.00, 4.00, 2.25, 6.25, HitPriority.BOSS_DEFAULT)
				inst.components.hitbox:PushOffsetBeam(1.00, 3.00, 2.50, 4.50, HitPriority.BOSS_DEFAULT)
			end),
			FrameEvent(20, function(inst)
				inst.components.hitbox:PushOffsetBeam(-10.00, -9.00, 2.75, 3.25, HitPriority.BOSS_DEFAULT)
				inst.components.hitbox:PushOffsetBeam(-9.00, -8.00, 2.75, 4.75, HitPriority.BOSS_DEFAULT)
				inst.components.hitbox:PushOffsetBeam(-8.00, -5.00, 2.30, 4.30, HitPriority.BOSS_DEFAULT)
				inst.components.hitbox:PushOffsetBeam(-5.00, -3.00, 1.75, 2.75, HitPriority.BOSS_DEFAULT)
				inst.components.hitbox:PushOffsetBeam(-3.00, -2.00, 1.75, 1.75, HitPriority.BOSS_DEFAULT)
			end),
			FrameEvent(21, function(inst)
				inst.components.hitbox:PushOffsetBeam(-10.00, -9.00, 2.75, 3.25, HitPriority.BOSS_DEFAULT)
				inst.components.hitbox:PushOffsetBeam(-9.00, -8.00, 2.75, 4.75, HitPriority.BOSS_DEFAULT)
				inst.components.hitbox:PushOffsetBeam(-8.00, -5.00, 2.30, 4.30, HitPriority.BOSS_DEFAULT)
				inst.components.hitbox:PushOffsetBeam(-5.00, -3.00, 1.75, 2.75, HitPriority.BOSS_DEFAULT)
				inst.components.hitbox:PushOffsetBeam(-3.00, -2.00, 1.75, 1.75, HitPriority.BOSS_DEFAULT)

				inst.components.hitbox:StopRepeatTargetDelay()
			end),

			-- Swing 2
			FrameEvent(22, function(inst)
				inst.components.hitbox:StartRepeatTargetDelay()
				inst.components.hitbox:PushOffsetBeam(-11.00, -10.00, 3.25, 4.75, HitPriority.BOSS_DEFAULT)
				inst.components.hitbox:PushOffsetBeam(-10.00, -8.00, 4.50, 4.50, HitPriority.BOSS_DEFAULT)
				inst.components.hitbox:PushOffsetBeam(-8.00, -4.50, 2.00, 1.00, HitPriority.BOSS_DEFAULT)
				inst.components.hitbox:PushOffsetBeam(-4.50, -1.80, 1.00, 0.50, HitPriority.BOSS_DEFAULT)
			end),
			FrameEvent(23, function(inst)
				inst.components.hitbox:PushOffsetBeam(-11.00, -10.00, 3.00, 3.00, HitPriority.BOSS_DEFAULT)
				inst.components.hitbox:PushOffsetBeam(-10.00, -8.00, 3.25, 1.75, HitPriority.BOSS_DEFAULT)
				inst.components.hitbox:PushOffsetBeam(-8.00, -4.50, 2.25, -0.25, HitPriority.BOSS_DEFAULT)
				inst.components.hitbox:PushOffsetBeam(-4.50, -1.80, 1.25, -0.75, HitPriority.BOSS_DEFAULT)
			end),
			FrameEvent(24, function(inst)
				inst.components.hitbox:PushOffsetBeam(-4.00, -3.00, 2.00, -1.00, HitPriority.BOSS_DEFAULT)
				inst.components.hitbox:PushOffsetBeam(-3.00, 4.80, 2.60, -1.60, HitPriority.BOSS_DEFAULT)
			end),
			FrameEvent(25, function(inst)
				inst.components.hitbox:PushOffsetBeam(-3.00, -2.00, 2.25, -1.25, HitPriority.BOSS_DEFAULT)
				inst.components.hitbox:PushOffsetBeam(-2.00, 6.00, 2.75, -1.75, HitPriority.BOSS_DEFAULT)
				inst.components.hitbox:PushOffsetBeam(6.00, 7.00, 2.00, -1.00, HitPriority.BOSS_DEFAULT)
			end),
			FrameEvent(26, function(inst)
				inst.components.hitbox:PushOffsetBeam(1.90, 5.00, 2.50, -2.00, HitPriority.BOSS_DEFAULT)
				inst.components.hitbox:PushOffsetBeam(5.00, 8.00, 2.50, -1.50, HitPriority.BOSS_DEFAULT)
				inst.components.hitbox:PushOffsetBeam(8.00, 9.00, 2.25, -0.75, HitPriority.BOSS_DEFAULT)
				inst.components.hitbox:PushOffsetBeam(9.00, 10.00, 2.25, -0.25, HitPriority.BOSS_DEFAULT)
				inst.components.hitbox:PushOffsetBeam(10.00, 11.00, 2.50, 1.00, HitPriority.BOSS_DEFAULT)
				inst.components.hitbox:PushOffsetBeam(11.00, 12.00, 2.50, 2.00, HitPriority.BOSS_DEFAULT)
			end),
			FrameEvent(27, function(inst)
				inst.components.hitbox:PushBeam(1.90, 5.00, 1.00, HitPriority.BOSS_DEFAULT)
				inst.components.hitbox:PushOffsetBeam(5.00, 8.00, 2.50, -1.50, HitPriority.BOSS_DEFAULT)
				inst.components.hitbox:PushOffsetBeam(8.00, 9.00, 2.25, -0.75, HitPriority.BOSS_DEFAULT)
				inst.components.hitbox:PushOffsetBeam(9.00, 10.00, 2.25, -0.25, HitPriority.BOSS_DEFAULT)
				inst.components.hitbox:PushOffsetBeam(10.00, 11.00, 2.50, 1.00, HitPriority.BOSS_DEFAULT)
				inst.components.hitbox:PushOffsetBeam(11.00, 12.00, 2.38, 2.12, HitPriority.BOSS_DEFAULT)
			end),
			FrameEvent(28, function(inst)
				inst.components.hitbox:PushOffsetBeam(1.90, 5.00, 1.00, 1.50, HitPriority.BOSS_DEFAULT)
				inst.components.hitbox:PushBeam(5.00, 8.00, 2.50, HitPriority.BOSS_DEFAULT)
				inst.components.hitbox:PushOffsetBeam(8.00, 10.00, 3.10, 1.90, HitPriority.BOSS_DEFAULT)
				inst.components.hitbox:PushOffsetBeam(10.00, 11.00, 3.25, 3.25, HitPriority.BOSS_DEFAULT)
				inst.components.hitbox:PushOffsetBeam(11.00, 11.50, 2.50, 4.00, HitPriority.BOSS_DEFAULT)
			end),
			FrameEvent(29, function(inst)
				inst.components.hitbox:PushOffsetBeam(1.90, 5.00, 1.00, 1.50, HitPriority.BOSS_DEFAULT)
				inst.components.hitbox:PushBeam(5.00, 8.00, 2.50, HitPriority.BOSS_DEFAULT)
				inst.components.hitbox:PushOffsetBeam(8.00, 10.00, 3.10, 1.90, HitPriority.BOSS_DEFAULT)
				inst.components.hitbox:PushOffsetBeam(10.00, 11.00, 3.25, 3.25, HitPriority.BOSS_DEFAULT)
				inst.components.hitbox:PushOffsetBeam(11.00, 11.50, 2.50, 4.00, HitPriority.BOSS_DEFAULT)
			end),
			FrameEvent(30, function(inst)
				--inst.components.hitbox:PushOffsetBeam(9.50, 11.50, 2.75, 2.75, HitPriority.BOSS_DEFAULT)
				inst.components.hitbox:PushOffsetBeam(7.50, 9.50, 2.00, 5.50, HitPriority.BOSS_DEFAULT)
				inst.components.hitbox:PushOffsetBeam(4.00, 7.50, 2.00, 7.00, HitPriority.BOSS_DEFAULT)
				inst.components.hitbox:PushOffsetBeam(3.00, 4.00, 2.25, 6.25, HitPriority.BOSS_DEFAULT)
				inst.components.hitbox:PushOffsetBeam(1.00, 3.00, 2.50, 4.50, HitPriority.BOSS_DEFAULT)
			end),
			FrameEvent(31, function(inst)
				--inst.components.hitbox:PushOffsetBeam(9.50, 11.50, 2.75, 2.75, HitPriority.BOSS_DEFAULT)
				inst.components.hitbox:PushOffsetBeam(7.50, 9.50, 2.00, 5.50, HitPriority.BOSS_DEFAULT)
				inst.components.hitbox:PushOffsetBeam(4.00, 7.50, 2.00, 7.00, HitPriority.BOSS_DEFAULT)
				inst.components.hitbox:PushOffsetBeam(3.00, 4.00, 2.25, 6.25, HitPriority.BOSS_DEFAULT)
				inst.components.hitbox:PushOffsetBeam(1.00, 3.00, 2.50, 4.50, HitPriority.BOSS_DEFAULT)
			end),
			FrameEvent(32, function(inst)
				inst.components.hitbox:PushOffsetBeam(-10.50, -9.50, 2.75, 3.25, HitPriority.BOSS_DEFAULT)
				inst.components.hitbox:PushOffsetBeam(-9.50, -8.00, 2.00, 5.00, HitPriority.BOSS_DEFAULT)
				inst.components.hitbox:PushOffsetBeam(-8.00, -5.00, 2.00, 4.50, HitPriority.BOSS_DEFAULT)
				inst.components.hitbox:PushOffsetBeam(-5.00, -3.00, 1.75, 2.75, HitPriority.BOSS_DEFAULT)
				inst.components.hitbox:PushOffsetBeam(-3.00, -2.00, 1.75, 1.75, HitPriority.BOSS_DEFAULT)
			end),
			FrameEvent(33, function(inst)
				inst.components.hitbox:PushOffsetBeam(-10.50, -9.50, 2.75, 3.25, HitPriority.BOSS_DEFAULT)
				inst.components.hitbox:PushOffsetBeam(-9.50, -8.00, 2.00, 5.00, HitPriority.BOSS_DEFAULT)
				inst.components.hitbox:PushOffsetBeam(-8.00, -5.00, 2.00, 4.50, HitPriority.BOSS_DEFAULT)
				inst.components.hitbox:PushOffsetBeam(-5.00, -3.00, 1.75, 2.75, HitPriority.BOSS_DEFAULT)
				inst.components.hitbox:PushOffsetBeam(-3.00, -2.00, 1.75, 1.75, HitPriority.BOSS_DEFAULT)
			end),
			FrameEvent(34, function(inst)
				inst.components.hitbox:PushOffsetBeam(-12.00, -10.00, 3.75, 3.75, HitPriority.BOSS_DEFAULT)
				inst.components.hitbox:PushOffsetBeam(-10.00, -8.00, 3.75, 2.25, HitPriority.BOSS_DEFAULT)
				inst.components.hitbox:PushOffsetBeam(-8.00, -5.00, 1.50, 0.50, HitPriority.BOSS_DEFAULT)
				inst.components.hitbox:PushOffsetBeam(-5.00, -2.00, 0.75, -0.25, HitPriority.BOSS_DEFAULT)
			end),
			FrameEvent(35, function(inst)
				inst.components.hitbox:PushOffsetBeam(-11.50, -10.00, 2.25, 0.75, HitPriority.BOSS_DEFAULT)
				inst.components.hitbox:PushBeam(-10.00, -8.00, 2.50, HitPriority.BOSS_DEFAULT)
				inst.components.hitbox:PushOffsetBeam(-8.00, -5.00, 2.50, -0.50, HitPriority.BOSS_DEFAULT)
				inst.components.hitbox:PushOffsetBeam(-5.00, -2.00, 2.50, -1.00, HitPriority.BOSS_DEFAULT)
			end),
			FrameEvent(36, function(inst)
				--inst.components.hitbox:PushOffsetBeam(-8.50, -6.00, 2.50, 1.00, HitPriority.BOSS_DEFAULT)
				inst.components.hitbox:PushOffsetBeam(-6.00, 1.20, 2.25, -2.25, HitPriority.BOSS_DEFAULT)
			end),

			-- Final attack
			FrameEvent(60, function(inst)
				inst.components.hitbox:StopRepeatTargetDelay()

				inst.sg.statemem.is_last_attack = true
				inst.components.hitbox:StartRepeatTargetDelay()
			end),
			FrameEvent(61, function(inst)
				inst.sg.statemem.is_air_attack = true
				inst.components.hitbox:PushBeam(2.00, 7.50, 2.00, HitPriority.BOSS_DEFAULT)
			end),
			FrameEvent(62, function(inst)
				inst.sg.statemem.is_air_attack = nil
				inst.components.hitbox:PushCircle(4.00, 0.00, 5.00, HitPriority.BOSS_DEFAULT)
			end),
			FrameEvent(63, function(inst)
				inst.components.hitbox:PushCircle(4.00, 0.00, 5.50, HitPriority.BOSS_DEFAULT)
			end),
			FrameEvent(64, function(inst)
				inst.components.hitbox:PushCircle(4.00, 0.00, 6.00, HitPriority.BOSS_DEFAULT)
			end),

			-- Tags
			FrameEvent(44, function(inst)
				inst.sg:AddStateTag("airborne")
				inst.Physics:StartPassingThroughObjects()
			end),
			FrameEvent(46, function(inst)
				inst.sg:AddStateTag("airborne_high")
			end),
			FrameEvent(77, function(inst)
				inst.sg:RemoveStateTag("airborne_high")
			end),
			FrameEvent(80, function(inst)
				inst.sg:RemoveStateTag("airborne")
				inst.Physics:StopPassingThroughObjects()
			end),
		},

		events =
		{
			EventHandler("hitboxtriggered", OnSwingSmashHitBoxTriggered),
			EventHandler("animover", function(inst)
				inst.sg:GoToState("swing_smash_stuck_loop")
			end),
		},

		onexit = function(inst)
			inst.Physics:Stop()
			inst.Physics:StopPassingThroughObjects()
			inst.components.hitbox:StopRepeatTargetDelay()
			inst.components.attacktracker:CompleteActiveAttack()
		end,
	}),

	State({
		name = "swing_smash_stuck_loop",
		tags = { "attack", "busy", "nointerrupt", "vulnerable" },

		onenter = function(inst)
			inst.AnimState:PlayAnimation("swing_smash_stuck_loop", true)
			inst.sg:SetTimeoutAnimFrames(SWING_SMASH_STUCK_FRAMES)
		end,

		ontimeout = function(inst)
			inst.sg:GoToState("swing_smash_pst")
		end,
	}),

	State({
		name = "swing_smash_pst",
		tags = { "attack", "busy", "nointerrupt" },

		onenter = function(inst)
			inst.AnimState:PlayAnimation("swing_smash_pst")
		end,

		events =
		{
			EventHandler("animover", function(inst)
				inst.sg:GoToState("idle")
			end),
		},

		onexit = function(inst)
			inst:PushEvent("swing_smash_over")
		end,
	}),

	State({
		name = "acid_spit_reposition",
		tags = { "attack", "busy", "nointerrupt" },

		onenter = function(inst)
			-- Determine which hop animation to play depending on its current position & facing
			local facing = inst.Transform:GetFacing() == FACING_LEFT and -1 or 1
			local pos = inst:GetPosition()

			local target = inst.components.combat:GetTarget()
			if target then
				local targetpos = target:GetPosition()
				local dist_to_target = pos:dist(targetpos)
				if dist_to_target < ACID_SPIT_RANGE then
					inst.AnimState:PlayAnimation("backhop")
				elseif dist_to_target < ACID_SPIT_RANGE then
					inst.AnimState:PlayAnimation("hop_forward")
				end

				-- Too close to the edge; move to the other side
				local reposition_pt = Vector3(targetpos.x - ACID_SPIT_RANGE * facing, 0, targetpos.z)
				if not TheWorld.Map:IsWalkableAtXZ(reposition_pt.x, reposition_pt.z) then
					reposition_pt = Vector3(targetpos.x + ACID_SPIT_RANGE * facing, 0, targetpos.z)
					-- There's also an edge on the other side; move up to the edge
					if not TheWorld.Map:IsWalkableAtXZ(reposition_pt.x, reposition_pt.z) then
						reposition_pt = TheWorld.Map:FindClosestPointOnWalkableBoundary(reposition_pt)
					else
						inst.Physics:StartPassingThroughObjects()
					end
				end

				-- Move to a point in front/back from where the player is standing, within acid spit range
				inst.sg.statemem.movetotask = SGCommon.Fns.MoveToPoint(inst, reposition_pt, 0.25)
				inst.sg:SetTimeoutAnimFrames(150)
			else
				inst.sg:GoToState("acid_spit_pre")
				return
			end
		end,

		ontimeout = function(inst)
			TheLog.ch.StateGraph:printf("Warning: Thatcher state %s timed out.", inst.sg.currentstate.name)
			inst.sg:GoToState("acid_spit_pre")
		end,

		events =
		{
			EventHandler("movetopoint_complete", function(inst)
				local target = inst.components.combat:GetTarget()
				if target then
					SGCommon.Fns.TurnAndActOnTarget(inst, target, true, "acid_spit_pre", target)
				else
					inst.sg:GoToState("acid_spit_pre")
				end

			end),
		},

		onexit = function(inst)
			if inst.sg.statemem.movetotask then
				inst.sg.statemem.movetotask:Cancel()
				inst.sg.statemem.movetotask = nil
			end
			inst.Physics:StopPassingThroughObjects()
		end,
	}),

	State({
		name = "acid_spit",
		tags = { "attack", "busy", "nointerrupt" },

		onenter = function(inst)
			inst.AnimState:PlayAnimation("acid_spit")
		end,

		timeline =
		{
			--head hitbox
			FrameEvent(22, function(inst) inst.components.offsethitboxes:SetEnabled("offsethitbox", true) end),
			FrameEvent(22, function(inst) inst.components.offsethitboxes:Move("offsethitbox", .8) end),
			FrameEvent(24, function(inst) inst.components.offsethitboxes:Move("offsethitbox", 1) end),
			FrameEvent(26, function(inst) inst.components.offsethitboxes:Move("offsethitbox", 1.2) end),
			FrameEvent(28, function(inst) inst.components.offsethitboxes:SetEnabled("offsethitbox", false) end),

			-- Spit acid
			FrameEvent(4, function(inst)
				SpawnAcidSpitPattern(inst)
			end),
		},

		events =
		{
			EventHandler("animover", function(inst)
				inst.sg:GoToState("idle")
			end),
		},

		onexit = function(inst)
			inst.components.attacktracker:CompleteActiveAttack()
		end,
	}),

	State({
		name = "acid_coating",
		tags = { "attack", "busy", "nointerrupt" },

		onenter = function(inst)
			inst.AnimState:PlayAnimation("acid_coating")
		end,

		timeline =
		{
			-- Spawn acid
			FrameEvent(32, function(inst)
			end),
		},

		events =
		{
			EventHandler("animover", function(inst)
				inst.sg:GoToState("idle")
			end),
		},

		onexit = function(inst)
			inst.components.attacktracker:CompleteActiveAttack()
			inst:PushEvent("acid_coating_over")
		end,
	}),

	State({
		name = "acid_splash_reposition",
		tags = { "attack", "busy", "nointerrupt" },

		onenter = function(inst)
			-- Determine which hop animation to play depending on its current position & facing
			local facing = inst.Transform:GetFacing() == FACING_LEFT and -1 or 1
			local pos = inst:GetPosition()

			-- back hop
			if (pos.x > ACID_SPLASH_POSITION.x and facing > 0) or pos.x < ACID_SPLASH_POSITION.x and facing < 0 then
				inst.AnimState:PlayAnimation("backhop")
			-- forward hop
			else
				inst.AnimState:PlayAnimation("hop_forward")
			end

			-- Move to target point.
			inst.sg.statemem.movetotask = SGCommon.Fns.MoveToPoint(inst, ACID_SPLASH_POSITION, 0.25)
			inst.sg:SetTimeoutAnimFrames(150)
		end,

		ontimeout = function(inst)
			TheLog.ch.StateGraph:printf("Warning: Thatcher state %s timed out.", inst.sg.currentstate.name)
			inst.sg:GoToState("acid_splash_pre")
		end,

		events =
		{
			EventHandler("movetopoint_complete", function(inst)
				local target = inst.components.combat:GetTarget()
				if target then
					SGCommon.Fns.TurnAndActOnTarget(inst, target, true, "acid_splash_pre", target)
				else
					inst.sg:GoToState("acid_splash_pre")
				end

			end),
		},

		onexit = function(inst)
			if inst.sg.statemem.movetotask then
				inst.sg.statemem.movetotask:Cancel()
				inst.sg.statemem.movetotask = nil
			end
		end,
	}),

	State({
		name = "acid_splash",
		tags = { "attack", "busy", "nointerrupt" },

		onenter = function(inst)
			inst.AnimState:PlayAnimation("acid_splash")
			inst.components.hitbox:StartRepeatTargetDelayAnimFrames(3)
		end,

		timeline =
		{
			--head hitbox
			FrameEvent(0, function(inst) inst.components.offsethitboxes:SetEnabled("offsethitbox", true) end),
			FrameEvent(0, function(inst) inst.components.offsethitboxes:Move("offsethitbox", 1.1) end),
			FrameEvent(3, function(inst) inst.components.offsethitboxes:SetEnabled("offsethitbox", false) end),
			--

			-- Spawn acid
			FrameEvent(35, function(inst)
				SpawnAcidSplash(inst)
			end),

			-- Overhead spin
			FrameEvent(23, function(inst)
				inst.components.hitbox:PushOffsetBeam(-4.00, 1.00, 2.00, -1.00, HitPriority.BOSS_DEFAULT)
			end),
			FrameEvent(24, function(inst)
				inst.components.hitbox:PushOffsetBeam(-5.50, -0.50, 2.00, -1.00, HitPriority.BOSS_DEFAULT)
			end),
			FrameEvent(25, function(inst)
				inst.components.hitbox:PushOffsetBeam(-3.50, -0.50, 2.50, -0.50, HitPriority.BOSS_DEFAULT)
			end),
			FrameEvent(26, function(inst)
				inst.sg.statemem.is_air_attack = true
				inst.components.hitbox:PushOffsetBeam(-3.50, 2.50, 2.50, -0.50, HitPriority.BOSS_DEFAULT)
			end),
			FrameEvent(27, function(inst)
				inst.components.hitbox:PushCircle(0.00, 0.00, 4.00, HitPriority.BOSS_DEFAULT)
			end),
			FrameEvent(28, function(inst)
				inst.components.hitbox:PushCircle(-0.50, 0.00, 4.00, HitPriority.BOSS_DEFAULT)
			end),
			FrameEvent(29, function(inst)
				inst.components.hitbox:PushCircle(-1.00, 0.00, 4.00, HitPriority.BOSS_DEFAULT)
			end),
			FrameEvent(30, function(inst)
				inst.components.hitbox:PushCircle(-0.50, 0.00, 4.00, HitPriority.BOSS_DEFAULT)
			end),
			--[[FrameEvent(31, function(inst)
				inst.sg.statemem.overhead_spin = true -- Handle frames 31 - 62 in onupdate
			end),
			FrameEvent(63, function(inst)
				inst.sg.statemem.overhead_spin = nil
				inst.components.hitbox:PushCircle(0.50, 0.00, 4.00, HitPriority.BOSS_DEFAULT)
			end),
			FrameEvent(64, function(inst)
				inst.components.hitbox:PushCircle(0.50, 0.00, 4.00, HitPriority.BOSS_DEFAULT)
			end),
			FrameEvent(65, function(inst)
				inst.components.hitbox:PushCircle(0.50, 0.00, 4.00, HitPriority.BOSS_DEFAULT)
			end),]]

			-- Forward & top spin
			FrameEvent(66, function(inst)
				inst.components.hitbox:PushBeam(1.00, 3.50, 2.50, HitPriority.BOSS_DEFAULT)
			end),
			FrameEvent(67, function(inst)
				inst.components.hitbox:PushBeam(1.00, 4.00, 2.00, HitPriority.BOSS_DEFAULT)
			end),
			FrameEvent(68, function(inst)
				inst.components.hitbox:PushBeam(2.00, 5.00, 4.00, HitPriority.BOSS_DEFAULT)
			end),
			FrameEvent(69, function(inst)
				inst.components.hitbox:PushBeam(2.00, 5.00, 4.00, HitPriority.BOSS_DEFAULT)
			end),
			FrameEvent(70, function(inst)
				inst.components.hitbox:PushBeam(0.00, 4.50, 3.00, HitPriority.BOSS_DEFAULT)
			end),
			FrameEvent(71, function(inst)
				inst.components.hitbox:PushBeam(1.00, 4.00, 3.00, HitPriority.BOSS_DEFAULT)
			end),
			FrameEvent(72, function(inst)
				inst.components.hitbox:PushOffsetBeam(-4.00, 0.00, 2.75, 1.25, HitPriority.BOSS_DEFAULT)
			end),
			FrameEvent(73, function(inst)
				inst.components.hitbox:PushOffsetBeam(-3.00, 2.00, 2.00, 2.50, HitPriority.BOSS_DEFAULT)
			end),
			FrameEvent(74, function(inst)
				inst.components.hitbox:PushOffsetBeam(-2.00, 3.00, 2.50, -0.50, HitPriority.BOSS_DEFAULT)
			end),

			-- Back & below spin
			FrameEvent(75, function(inst)
				inst.components.hitbox:PushBeam(-4.50, -1.00, 3.50, HitPriority.BOSS_DEFAULT)
			end),
			FrameEvent(76, function(inst)
				inst.components.hitbox:PushBeam(-4.50, -1.00, 3.00, HitPriority.BOSS_DEFAULT)
			end),
			FrameEvent(77, function(inst)
				inst.components.hitbox:PushBeam(-4.50, -1.00, 3.00, HitPriority.BOSS_DEFAULT)
			end),
			FrameEvent(78, function(inst)
				inst.components.hitbox:PushBeam(-4.50, -1.00, 2.00, HitPriority.BOSS_DEFAULT)
			end),
			FrameEvent(79, function(inst)
				inst.components.hitbox:PushBeam(-5.00, -1.00, 3.50, HitPriority.BOSS_DEFAULT)
			end),
			FrameEvent(80, function(inst)
				inst.components.hitbox:PushOffsetBeam(-3.00, -1.00, 3.00, -1.00, HitPriority.BOSS_DEFAULT)
			end),
			FrameEvent(81, function(inst)
				inst.components.hitbox:PushOffsetBeam(-3.00, -0.50, 3.50, -1.00, HitPriority.BOSS_DEFAULT)
			end),
			FrameEvent(82, function(inst)
				inst.components.hitbox:PushOffsetBeam(-3.50, -0.50, 3.00, -1.00, HitPriority.BOSS_DEFAULT)
			end),
			FrameEvent(83, function(inst)
				inst.components.hitbox:PushOffsetBeam(-0.50, 2.50, 2.75, -0.75, HitPriority.BOSS_DEFAULT)
			end),
			FrameEvent(84, function(inst)
				inst.components.hitbox:PushOffsetBeam(-0.50, 2.50, 2.25, -0.75, HitPriority.BOSS_DEFAULT)
			end),
		},

		--[[onupdate = function(inst)
			if inst.sg.statemem.overhead_spin then
				inst.components.hitbox:PushCircle(0.00, 0.00, 4.00, HitPriority.BOSS_DEFAULT)
			end
		end,]]

		events =
		{
			EventHandler("hitboxtriggered", OnAcidSplashHitBoxTriggered),
			EventHandler("animover", function(inst)
				inst.sg:GoToState("idle")
			end),
		},

		onexit = function(inst)
			inst.components.attacktracker:CompleteActiveAttack()
			inst.components.offsethitboxes:SetEnabled("offsethitbox", false)
			inst.components.hitbox:StopRepeatTargetDelay()
			inst:PushEvent("acid_splash_over")
		end,
	}),
}

local nointerrupttags = { "nointerrupt" }

SGCommon.States.AddIdleStates(states, { num_idle_behaviours = 3, })
SGCommon.States.AddTurnStates(states)

SGCommon.States.AddLocomoteStates(states, "run",
{
	isRunState = true,
	addtags = nointerrupttags,
})

SGCommon.States.AddHitStates(states)
SGCommon.States.AddKnockbackStates(states, { movement_frames = 12 })
SGCommon.States.AddKnockdownStates(states, { movement_frames = 12 })
SGCommon.States.AddKnockdownHitStates(states)

SGCommon.States.AddAttackPre(states, "swing_short", { alwaysforceattack = true })
--SGCommon.States.AddAttackHold(states, "swing_short", { alwaysforceattack = true })

SGCommon.States.AddAttackPre(states, "swing_long", { alwaysforceattack = true })
--SGCommon.States.AddAttackHold(states, "swing_long", { alwaysforceattack = true })

SGCommon.States.AddAttackPre(states, "acid_spit",
{
	alwaysforceattack = true,
	reposition_state = "acid_spit_reposition",
})
SGCommon.States.AddAttackHold(states, "acid_spit", { alwaysforceattack = true })

--SGCommon.States.AddAttackPre(states, "hook", { alwaysforceattack = true })
--SGCommon.States.AddAttackHold(states, "hook", { alwaysforceattack = true })

SGCommon.States.AddAttackPre(states, "double_short_slash",
{
	alwaysforceattack = true,
	reposition_state = "double_short_slash_reposition",
})
SGCommon.States.AddAttackHold(states, "double_short_slash", { alwaysforceattack = true })

--SGCommon.States.AddAttackPre(states, "full_swing", { alwaysforceattack = true })
--SGCommon.States.AddAttackHold(states, "full_swing", { alwaysforceattack = true })

local function FaceTargetOrMiddle(inst)
	-- Always face the target
	local target = inst.components.combat:GetTarget()
	if target then
		SGCommon.Fns.FaceTarget(inst, target, true)
	else
		-- Face towards the middle
		local center_pt = spawnutil.GetStartPointFromWorld(0.5, 0.5)
		local pos = inst:GetPosition()
		if pos.x > center_pt.x then
			inst.Transform:SetRotation(-180)
		else
			inst.Transform:SetRotation(0)
		end
	end
end

SGCommon.States.AddAttackPre(states, "full_swing_mobile",
{
	alwaysforceattack = true,
	onenter_fn = function(inst)
		inst.components.monstertranslator:DisplayMonsterString("thatcher", "THATCHER_SPECIAL_1_1", 75)

		-- Spawn temporary acid before doing its special attack.
		StartAcidGeysers(inst)

		inst:DoTaskInAnimFrames(60, function()
			SpawnGeyserAcid(inst, 1, "intro")
			SpawnGeyserAcid(inst, 2, "intro")
		end)
	end,
})
SGCommon.States.AddAttackHold(states, "full_swing_mobile", { alwaysforceattack = true })

SGCommon.States.AddAttackPre(states, "dash_uppercut",
{
	alwaysforceattack = true,
	reposition_state = "dash_uppercut_reposition",

	onenter_fn = function(inst)
		inst.components.monstertranslator:DisplayMonsterString("thatcher", "THATCHER_SPECIAL_2_1", 75)

		-- Spawn temporary acid before doing its special attack.
		StartAcidGeysers(inst)

		inst:DoTaskInAnimFrames(60, function()
			SpawnGeyserAcid(inst, 1, "phase2", true)
		end)

		inst:DoTaskInAnimFrames(70, function()
			SpawnGeyserAcid(inst, 2, "phase2", true)
			SpawnGeyserAcid(inst, 3, "phase2", true)
			SpawnGeyserAcid(inst, 4, "phase2", true)
			SpawnGeyserAcid(inst, 5, "phase2", true)
		end)
	end,
})
SGCommon.States.AddAttackHold(states, "dash_uppercut",
{
	alwaysforceattack = true,
	update_fn = FaceTargetOrMiddle,
})

SGCommon.States.AddAttackPre(states, "swing_smash", {
	alwaysforceattack = true,
	reposition_state = "swing_smash_reposition",

	onenter_fn = function(inst)
		inst.components.hitbox:StartRepeatTargetDelay()

		inst.components.monstertranslator:DisplayMonsterString("thatcher", "THATCHER_SPECIAL_3_1", 75)

		-- Spawn temporary acid before doing its special attack.
		StartAcidGeysers(inst)

		inst:DoTaskInAnimFrames(60, function()
			SpawnGeyserAcid(inst, 1, "phase3", true)
			SpawnGeyserAcid(inst, 2, "phase3", true)
			SpawnGeyserAcid(inst, 3, "phase3", true)
			SpawnGeyserAcid(inst, 4, "phase3", true)
		end)

		inst:DoTaskInAnimFrames(65, function()
			SpawnGeyserAcid(inst, 5, "phase3", true)
			SpawnGeyserAcid(inst, 6, "phase3", true)
			SpawnGeyserAcid(inst, 7, "phase3", true)
			SpawnGeyserAcid(inst, 8, "phase3", true)
		end)

		inst:DoTaskInAnimFrames(70, function()
			SpawnGeyserAcid(inst, 9, "phase3", true)
			SpawnGeyserAcid(inst, 10, "phase3", true)
			SpawnGeyserAcid(inst, 11, "phase3", true)
			SpawnGeyserAcid(inst, 12, "phase3", true)
		end)

		inst:DoTaskInAnimFrames(75, function()
			SpawnGeyserAcid(inst, 13, "phase3", true)
			SpawnGeyserAcid(inst, 14, "phase3", true)
			SpawnGeyserAcid(inst, 15, "phase3", true)
			SpawnGeyserAcid(inst, 16, "phase3", true)
		end)

		inst.sg.statemem.is_attack_pre = true
	end,
	timeline =
	{
		FrameEvent(7, function(inst)
			inst.components.hitbox:PushBeam(-3.80, 0.80, 2.00, HitPriority.BOSS_DEFAULT)
		end),
		FrameEvent(8, function(inst)
			inst.components.hitbox:PushBeam(-3.80, 0.80, 2.00, HitPriority.BOSS_DEFAULT)
		end),
		FrameEvent(9, function(inst)
			inst.components.hitbox:PushBeam(-7.00, -2.00, 3.00, HitPriority.BOSS_DEFAULT)
		end),
		FrameEvent(10, function(inst)
			inst.components.hitbox:PushBeam(-7.00, -2.00, 3.00, HitPriority.BOSS_DEFAULT)
		end),
		FrameEvent(11, function(inst)
			inst.sg.statemem.is_air_attack = true
			inst.components.hitbox:PushBeam(-7.00, -2.00, 3.00, HitPriority.BOSS_DEFAULT)
		end),
		FrameEvent(12, function(inst)
			inst.components.hitbox:PushBeam(-7.00, -2.00, 3.00, HitPriority.BOSS_DEFAULT)
		end),
		FrameEvent(13, function(inst)
			inst.components.hitbox:PushBeam(-6.00, 2.00, 3.00, HitPriority.BOSS_DEFAULT)
		end),
		FrameEvent(14, function(inst)
			inst.components.hitbox:PushBeam(-6.00, 2.00, 3.00, HitPriority.BOSS_DEFAULT)
		end),
	},
	addevents =
	{
		EventHandler("hitboxtriggered", OnSwingSmashHitBoxTriggered),
	},
	onexit_fn = function(inst)
		inst.components.hitbox:StopRepeatTargetDelay()
	end,
})
SGCommon.States.AddAttackHold(states, "swing_smash",{
	alwaysforceattack = true,
	update_fn = FaceTargetOrMiddle,
})

SGCommon.States.AddAttackPre(states, "acid_splash",
{
	alwaysforceattack = true,
	reposition_state = "acid_splash_reposition",
})
SGCommon.States.AddAttackHold(states, "acid_splash",
{
	alwaysforceattack = true,
	onenter_fn = function(inst)
		inst.components.offsethitboxes:SetEnabled("offsethitbox", true)
		inst.components.offsethitboxes:Move("offsethitbox", 1.1)
	end,
	onexit_fn = function(inst)
		inst.components.offsethitboxes:SetEnabled("offsethitbox", false)
	end,
})

SGCommon.States.AddMonsterDeathStates(states)
SGBossCommon.States.AddBossStates(states)

SGRegistry:AddData("sg_thatcher", states)

return StateGraph("sg_thatcher", states, events, "idle")
