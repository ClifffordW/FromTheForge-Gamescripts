-- THIS ENTITY SHOULD ALWAYS BE SPAWNED ON ALL LOCAL MACHINES, OTHERWISE IT WILL FAIL ADDING POWER

local Power = require "defs.powers"

local events =
{
}

local states =
{
	State({
		name = "idle",
		tags = { "idle" },

		onenter = function(inst)
			inst.sg:SetTimeoutAnimFrames(10)
			inst.sg.mem.active = true
		end,

		ontimeout = function(inst)
			inst.sg:GoToState("destroying")
		end,

		onupdate = function(inst)
			-- Because of some ordering stuff with this prefab, hitbox data may not be set up yet. Check first.
			if not inst.sg.mem.active then
				-- Wait until we have hitbox data to actually start the timeout, so that the attack always lasts the correct amount of frames.
				-- Doing this in onenter means -sometimes- the attack lasts slightly less long.

			end
		end,

		events =
		{
			-- EventHandler("hitboxtriggered", OnProximityHitBoxTriggered),
		},
	}),

	State({
		name = "destroying",
		tags = { },

		onenter = function(inst)
			inst:DelayedRemove()
		end,
	}),
}

return StateGraph("sg_playergroakvacuum", states, events, "idle")