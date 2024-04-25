local SGCommon = require "stategraphs.sg_common"
local Enum = require "util.enum"
local soundutil = require "util.soundutil"
local fmodtable = require "defs.sound.fmodtable"
local ParticleSystemHelper = require "util.particlesystemhelper"

local EnergyWellState = Enum{ 
	"IDLE", 
	"EXCITED",
}

local function SetEnergyWellState(inst, state)
	inst.energy_well_state = state
end

local function GetEnergyWellState(inst)
	return inst.energy_well_state
end

local is_eligible_player_local

local function GoToEnergyWellState(inst, energy_well_state)
	if inst.sg:HasStateTag("busy") then return end

	if GetEnergyWellState(inst) == energy_well_state then
		-- If you're already in this state, we don't have to do anything
		return true
	end

	local transition_state = ("%s_transition"):format(energy_well_state):lower()

	inst.sg:GoToState(transition_state)
end

local function _GetValidPlayers(inst)
	local players = inst.components.playerproxradial:FindPlayersInRange()
	return inst.components.energywell:IsAnyPlayerEligible(players)
end

local function _ValidateState(inst)
	-- Check if the state you're in is still valid!
	-- If it isn't, transition into the proper state.
	-- if it is, return true so we can do our own logic afterwards.

	local any_player_eligible, is_local = _GetValidPlayers(inst)
	is_eligible_player_local = is_local

	if not any_player_eligible and GetEnergyWellState(inst) == EnergyWellState.s.EXCITED then
		GoToEnergyWellState(inst, EnergyWellState.s.IDLE)
		return
	elseif any_player_eligible and GetEnergyWellState(inst) == EnergyWellState.s.IDLE then
		GoToEnergyWellState(inst, EnergyWellState.s.EXCITED)
		return
	end

	return true
end

local function SpawnActivateFX(inst)
	ParticleSystemHelper.MakeOneShotAtPosition(inst:GetPosition(), "town_energywell_activate_layer", 0.1, inst, nil)
end

local events =
{
	EventHandler("heart_near", function(inst) GoToEnergyWellState(inst, EnergyWellState.s.EXCITED) end),
	EventHandler("heart_far", function(inst) GoToEnergyWellState(inst, EnergyWellState.s.IDLE) end),
	EventHandler("deposit_heart", function(inst) 
		if not inst.sg:HasStateTag("nointerrupt") then 
			inst.sg:GoToState("activate")
		end 
	end),

	-- This event fires when the heart is actually consumed (and so we need to check the state again)
	EventHandler("on_deposit_heart", function(inst)	_ValidateState(inst) end),
}

local states =
{
	State{
		name = "init",
		onenter = function(inst)
			SetEnergyWellState(inst, EnergyWellState.s.IDLE)
			inst.sg:GoToState("idle")
		end,
	},

	State{
		name = "idle",

		onenter = function(inst)
			if _ValidateState(inst) then
				SGCommon.Fns.PlayAnimOnAllLayers(inst, "idle")
			end
		end,

		events =
		{
			EventHandler("animover", function(inst)
				inst.sg:GoToState("idle")
			end),
		},
	},

	State{
		-- leads into the excited state from idle
		name = "excited_transition",
        tags = {"busy"},

        onenter = function(inst, data)
            SGCommon.Fns.PlayAnimOnAllLayers(inst, "open")

            SetEnergyWellState(inst, EnergyWellState.s.EXCITED)
        end,

        events =
        {
            EventHandler("animover", function(inst)
            	inst.sg:GoToState("excited")
            end)
        },
	},

	State{
		name = "excited",

		onenter = function(inst)
			if _ValidateState(inst) then
				SGCommon.Fns.PlayAnimOnAllLayers(inst, "excited")
			end
		end,

		events =
		{
			EventHandler("animover", function(inst)
				inst.sg:GoToState("excited")
			end),
		},
	},

	State{
		-- leads into the idle state from excited
		name = "idle_transition",
        tags = {"busy"},

        onenter = function(inst, data)
            SGCommon.Fns.PlayAnimOnAllLayers(inst, "close")
			
            SetEnergyWellState(inst, EnergyWellState.s.IDLE)
        end,

        events =
        {
            EventHandler("animover", function(inst)
            	inst.sg:GoToState("idle")
            end)
        },
	},

	State{
		name = "activate",

		tags = {"nointerrupt"},

		onenter = function(inst)
			SpawnActivateFX(inst)
			SGCommon.Fns.PlayAnimOnAllLayers(inst, "activate")
		end,

		onexit = function(inst)
			inst.components.energywell:ConsumeProcessedHearts()
			-- TheDungeon:PushEvent("deposit_heart_finished")
		end,

        events =
        {
        	EventHandler("deposit_heart", SpawnActivateFX),
            EventHandler("animover", function(inst)
            	inst.sg:GoToState("excited")
            end)
        },
	}
}

return StateGraph("sg_energy_well", states, events, "init")
