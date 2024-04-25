local fmodtable = require "defs.sound.fmodtable"
local soundutil = require "util.soundutil"
local spawnutil = require "util.spawnutil"
local SGCommon = require "stategraphs.sg_common"

-- storing these values here for now, likely will move into trap.lua though
local INITIAL_COOLDOWN_TIME_MIN = 5
local INITIAL_COOLDOWN_TIME_MAX = 10
local COOLDOWN_TIME_MIN = 10
local COOLDOWN_TIME_MAX = 20
local MAX_SPAWNS = 10

local MOB_PREFAB = "mothball"
local NUM_MOBS_TO_SPAWN_MIN = 2
local NUM_MOBS_TO_SPAWN_MAX = 4

local TARGET_AREA_RANGE = 10

local function SpawnMobs(source)
	for i = 1, math.random(NUM_MOBS_TO_SPAWN_MIN, NUM_MOBS_TO_SPAWN_MAX) do
		local ent = SpawnPrefab(MOB_PREFAB, source)
		if ent then
			local x, y, z = source.Transform:GetWorldPosition()

			ent.Transform:SetPosition(x, y, z)
			ent.Transform:SetRotation(math.random(0, 360))

			ent.sg:GoToState("spawn_battlefield")
		end
	end
end

local function CanSpawnMobs(inst)
	inst.sg.mem.num_spawns = inst.sg.mem.num_spawns or 1
	return inst.sg.mem.num_spawns <= MAX_SPAWNS
end

local events =
{
}

local states =
{
	State({
		name = "idle",
		tags = { "idle" },

		onenter = function(inst)
			if not inst.sg.mem.num_spawns then
				inst.sg.mem.num_spawns = 1
				inst:ListenForEvent("room_complete", function()
					-- Prevent further spawns when the room is complete
					inst.sg.mem.num_spawns = MAX_SPAWNS + 1
				end, TheWorld)
			end

			local delay = inst.sg.mem.num_spawns == 1 and
							math.random() + math.random(INITIAL_COOLDOWN_TIME_MIN, INITIAL_COOLDOWN_TIME_MAX - 1)
							or math.random() + math.random(COOLDOWN_TIME_MIN, COOLDOWN_TIME_MAX - 1)
			inst.sg:SetTimeout(delay)
		end,

		ontimeout = function(inst)
			if CanSpawnMobs(inst) then
				inst.sg:GoToState("drop_pre")
			end
		end,
	}),

	State({
		name = "drop_pre",
		tags = { "attack", "busy" },

		onenter = function(inst)
			-- TODO: networking2022, this only plays on the host
			-- Shake the camera for all players
			ShakeAllCameras(CAMERASHAKE.VERTICAL, 1.5, 0.02, 1)

			inst.sg.mem.rumble_sound_LP = soundutil.PlayCodeSound(
				inst,
				fmodtable.Event.earthquake_low_rumble_LP,
				{
					name = "rumble",
					max_count = 1,
				}
			)

			inst.sg:SetTimeout(1)
		end,

		ontimeout = function(inst)
			if not CanSpawnMobs(inst) then
				return
			end
			inst.sg:GoToState("drop")
		end,

		onexit = function(inst)
			if inst.sg.mem.rumble_sound_LP then
				soundutil.KillSound(inst, inst.sg.mem.rumble_sound_LP)
				inst.sg.mem.rumble_sound_LP = nil
			end
		end,
	}),

	State({
		name = "drop",
		tags = { "attack", "busy" },

		onenter = function(inst)
			local prefab = SpawnPrefab("swamp_stalactite_network", inst)
			if prefab then
				-- Pick a random spot around a random target player.
				local player = AllPlayers[math.random(1, #AllPlayers)]
				local pos = spawnutil.GetRandomPointAroundTarget(player, TARGET_AREA_RANGE)
				prefab.Transform:SetPosition(pos:Get())

				if not inst.sg.mem.has_listener then
					inst:ListenForEvent("stalactite_landed", function(_, source)
						if not CanSpawnMobs(inst) then
							return
						end

						SpawnMobs(source)
						inst.sg.mem.num_spawns = inst.sg.mem.num_spawns + 1 or 1
						inst.sg:GoToState("idle")
					end)
					inst.sg.mem.has_listener = true
				end
			end
		end,
	}),
}

return StateGraph("sg_trap_stalactite", states, events, "idle")
