local events =
{
}

-- A simplified version of the regular trap_acid, used during Thatcher's fight as a permanent acid
local function ConfigureTrap(inst, data)
	-- override preset trap data if it came with an event
	if data then
		inst.sg.mem.trapdata = data
	end

	inst:RemoveComponent("snaptogrid")

	inst:ListenForEvent("room_complete", function()
		local frames = math.random(10) -- Slight variation in timing so not everything happens at the exact same time
		inst:DoTaskInAnimFrames(frames, function(xinst)
			if xinst ~= nil and xinst:IsValid() then--and not xinst:HasTag("permanent") then
				xinst.sg:GoToState("pst")
			end
		end)
	end, TheWorld)

	inst:AddTag("permanent")

	inst.components.auraapplyer:SetEffect("acid")
	inst.components.auraapplyer:IgnoreAerialTargets(true)

	local hitbox_size = 8.0
	local beam_thickness = 8.0
	local footstep_aura_sizemod_x = 0.4
	local footstep_aura_sizemod_y = 0.4
	inst.components.auraapplyer:SetupBeamHitbox(-hitbox_size * footstep_aura_sizemod_x, hitbox_size * footstep_aura_sizemod_x, beam_thickness * footstep_aura_sizemod_y) -- Footstepper hitbox is a little smaller
end

local states =
{
		State({
		name = "init",
		tags = { },

		onenter = function(inst)
			-- When spawned by a mob, trap waits in this state until told otherwise from the mob itself, to give it time to configure the trap
			inst.sg:SetTimeoutTicks(1)
		end,

		ontimeout = function(inst)
			-- TODO: networking2022, find a better way to detect this condition since it can look medium/large briefly for small acid pools
			-- This hasn't been spawned by a mob, so skip straight to the "loop" state, because it was probably spawned by the trap spawner
			-- First, set up some data to use, since it didn't come from a mob:
			ConfigureTrap(inst)
			inst.components.auraapplyer:Enable()
			inst.sg:GoToState("land")
		end,
	}),

	State({
		name = "land",
		tags = { },

		onenter = function(inst, data)
			ConfigureTrap(inst, data)

			inst.sg:SetTimeoutAnimFrames(15) -- TODO: Investigate playing the animation (AnimState:PlayAnimation()) instead of playing it via FX. The former doesn't seem to work properly
		end,

		ontimeout = function(inst)
			inst.components.auraapplyer:Enable()
			inst.sg:GoToState("loop")
		end,
	}),

	State({
		name = "loop",
		tags = { "idle" },
	}),

	State({
		name = "pst",
		tags = { "hit", "busy" },

		onenter = function(inst, data)
			inst.components.auraapplyer:Disable()
			inst:DoTaskInTime(1, function()
				if GetDebugEntity() ~= inst then
					inst:DelayedRemove()
				end
			end)
		end,
	}),
}

return StateGraph("sg_trap_acid_stage", states, events, "init")
