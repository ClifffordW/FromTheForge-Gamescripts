--[[local SGCommon = require("stategraphs/sg_common")
local ParticleSystemHelper = require "util.particlesystemhelper"
local EffectEvents = require "effectevents"]]
local fmodtable = require "defs.sound.fmodtable"
local soundutil = require "util.soundutil"

local function PlayAnimation(inst, basename, looping)
	if not basename then
		print("No base anim name specified for thatcher_acid_geyser in state", inst.sg.currentstate.name)
		return
	end

	-- Return the anim base name with a 'l_' or 'r_' prefix to distinguish between the left & right versions.
	local animname = inst.is_right and 'r_' .. basename or 'l_' .. basename
	animname = inst.is_center and "c_" .. basename or animname
	inst.AnimState:PlayAnimation(animname, looping)
end

local events =
{
	EventHandler("spawn_acid", function(inst)
		inst.sg:GoToState("warning")
	end),
	EventHandler("stop_acid", function(inst)
		inst.sg:GoToState("pst")
	end),
}

local states =
{
    State({
		name = "idle",
		tags = { "idle" },

		onenter = function(inst)
			PlayAnimation(inst, "idle", true)
		end,
	}),

	State({
		name = "warning",
		tags = { "busy" },

		onenter = function(inst, data)
			PlayAnimation(inst, "warning")

			-- TODO: networking2022, this only plays on the host
			-- Shake the camera for all players
			ShakeAllCameras(CAMERASHAKE.VERTICAL, 1.0, 0.02, 0.5)

			inst.sg.mem.rumble_sound_LP = soundutil.PlayCodeSound(
				inst,
				fmodtable.Event.earthquake_low_rumble_LP,
				{
					name = "rumble",
					stopatexitstate = true,
					is_autostop = true,
					max_count = 1,
				}
			)
		end,

		events =
		{
			EventHandler("animover", function(inst)
				inst.sg:GoToState("pre")
			end),
		},
	}),

	State({
		name = "pre",
		tags = { "busy" },

		onenter = function(inst, data)
			PlayAnimation(inst, "pre")
		end,

		events =
		{
			EventHandler("animover", function(inst)
				inst.sg:GoToState("loop")
			end),
		},
	}),

	State({
		name = "loop",
		tags = { "busy" },

		onenter = function(inst, data)
			PlayAnimation(inst, "loop", true)
		end,

		events =
		{
			EventHandler("animover", function(inst)
				-- Exit out when the room is clear
				if TheWorld.components.roomclear:IsRoomComplete() then
					inst.sg:GoToState("pst")
				end
			end),
		}
	}),

	State({
		name = "pst",
		tags = { "busy" },

		onenter = function(inst)
			PlayAnimation(inst, "pst")

			if inst.sg.mem.rumble_sound_LP then
				soundutil.KillSound(inst, inst.sg.mem.rumble_sound_LP)
				inst.sg.mem.rumble_sound_LP = nil
			end
		end,

		events =
		{
			EventHandler("animover", function(inst)
				inst.sg:GoToState("idle")
			end),
		},
	}),
}

return StateGraph("sg_thatcher_acid_geyser", states, events, "idle")
