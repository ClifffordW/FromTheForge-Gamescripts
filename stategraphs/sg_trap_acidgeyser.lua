local fmodtable = require "defs.sound.fmodtable"
local soundutil = require "util.soundutil"
local SGCommon = require "stategraphs.sg_common"
local spawnutil = require "util.spawnutil"
local krandom = require "util.krandom"

-- storing these values here for now, likely will move into trap.lua though
local INITIAL_COOLDOWN_TIME_MIN = 5
local INITIAL_COOLDOWN_TIME_MAX = 10
local COOLDOWN_TIME_MIN = 5
local COOLDOWN_TIME_MAX = 10
local MAX_SPAWNS = 1

local TARGET_AREA_RANGE = 3

local function CanSpawnAcid(inst)
	inst.sg.mem.num_spawns = inst.sg.mem.num_spawns or 1
	return not inst.sg.mem.room_complete
			-- and inst.sg.mem.num_spawns <= MAX_SPAWNS -- Comment this out to enable infinite spawns. TODO: Create a system that handles both temporary and permanent acid.
end

local events =
{
}

local states =
{
	State({
		name = "init",
		tags = { "idle" },

		onenter = function(inst)
			-- Spawn either a left or right acid geyser entity, then send events to control its states
			local is_left = math.random() < 0.5
			local prefab = is_left and "thatcher_acid_geyser_left" or "thatcher_acid_geyser_right"

			-- Delay spawning of the acid geyser prefab for a tick otherwise a hard crash occurs
			inst:DoTaskInTime(0, function()
				local acid_geyser = SGCommon.Fns.SpawnAtDist(inst, prefab, 0)
				inst.sg.mem.acid_geyser = acid_geyser
			end)

			inst:ListenForEvent("room_complete", function()
				-- Prevent further spawns when the room is complete
				inst.sg.mem.room_complete = true
			end, TheWorld)

			inst.sg.mem.num_spawns = inst.sg.mem.num_spawns or 1

			inst.sg:GoToState("idle")
		end,
	}),

	State({
		name = "idle",
		tags = { "idle" },

		onenter = function(inst)
			local delay = inst.sg.mem.num_spawns == 1 and
							math.random() + math.random(INITIAL_COOLDOWN_TIME_MIN, INITIAL_COOLDOWN_TIME_MAX - 1)
							or math.random() + math.random(COOLDOWN_TIME_MIN, COOLDOWN_TIME_MAX - 1)
			inst.sg:SetTimeout(delay)
		end,

		ontimeout = function(inst)
			if CanSpawnAcid(inst) then
				inst.sg:GoToState("drop_pre")
			end
		end,
	}),

	State({
		name = "drop_pre",
		tags = { "attack", "busy" },

		onenter = function(inst)
			if inst.sg.mem.acid_geyser then
				inst.sg.mem.acid_geyser:PushEvent("spawn_acid")
			end

			inst.sg:SetTimeout(1)
		end,

		ontimeout = function(inst)
			if not CanSpawnAcid(inst) then
				return
			end
			inst.sg:GoToState("drop")
		end,

		onexit = function(inst)
			if inst.sg.mem.acid_geyser then
				inst.sg.mem.acid_geyser:PushEvent("stop_acid")
			end
		end,
	}),

	State({
		name = "drop",
		tags = { "attack", "busy" },

		timeline =
		{
			FrameEvent(10, function(inst)
				local geyser_acid = SpawnPrefab("thatcher_geyser_acid", inst)
				if geyser_acid then
					-- Pick a random point around a random target player to drop at.
					local player = AllPlayers[math.random(1, #AllPlayers)]
					local target_pos = spawnutil.GetRandomPointAroundTarget(player, TARGET_AREA_RANGE)
					geyser_acid.Transform:SetPosition(target_pos:Get())

					--geyser_acid.sg.mem.is_permanent = true
					geyser_acid.sg.mem.is_medium = true
				end

				inst.sg.mem.num_spawns = inst.sg.mem.num_spawns + 1 or 1
				inst.sg:GoToState("idle")
			end),
		},
	}),
}

return StateGraph("sg_trap_acidgeyser", states, events, "init")
