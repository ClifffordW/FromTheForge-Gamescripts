local Consumable = require 'defs.consumable'
local lume = require "util.lume"
local kstring = require "util.kstring"
require "util.tableutil"

local EnergyWellPillar = {
	default = {},
}

local function BuildInteractLabel(inst, player)
	return STRINGS.UI.HEARTSCREEN.INTERACT.BTN_SWAP_HEARTSTONES
end

local function OnGainInteractFocus(inst, player)
	inst.components.energywellpillar:ShowCurrentHeartDetails(player)

	local biome_id = inst.components.energywellpillar:GetBiomeID()
	if player.components.heartmanager:CanSwapHeartForSlot(biome_id) then
		player.components.interactor:SetStatusText("energy_well", BuildInteractLabel(inst, player))
	end
end

local function OnLoseInteractFocus(inst, player)
	inst.components.energywellpillar:HideCurrentHeartDetails(player)
	player.components.interactor:SetStatusText("energy_well", nil)
end

local function OnInteract(inst, player, opts)
	local biome_id = inst.components.energywellpillar:GetBiomeID()

	if player.components.heartmanager:CanSwapHeartForSlot(biome_id) then
		player.components.heartmanager:SwapHeartInSlot(biome_id)
		inst.components.energywellpillar:ShowCurrentHeartDetails(player)
	end
	-- if we have an actual interact state, add the exit state here
	-- player.sg:GoToState('idle_accept') 
end

local function CanInteract(inst, player, is_focused)
	local biome_id = inst.components.energywellpillar:GetBiomeID()
	return player.components.heartmanager:GetEquippedIdxForSlot(biome_id) ~= 0
end

function EnergyWellPillar.default.CustomInit(inst, opts)
	assert(opts)
	inst:SetStateGraph("sg_energy_well_pillar")
	EnergyWellPillar.ConfigureEnergyWellPillar(inst, opts)
end

function EnergyWellPillar.ConfigureEnergyWellPillar(inst, opts)
	inst:AddComponent("energywellpillar")
		:SetBiomeID(opts.biome_id)

	inst:AddTag("energy_well_pillar")

	inst:AddComponent("interactable")

	inst.components.interactable:SetRadius(3)
		:SetInteractStateName("swap_heart")
		:SetInteractConditionFn(function(_, player, is_focused) return CanInteract(inst, player, is_focused) end)
		:SetOnInteractFn(function(_, player) OnInteract(inst, player, opts) end)
		:SetOnGainInteractFocusFn(OnGainInteractFocus)
		:SetOnLoseInteractFocusFn(OnLoseInteractFocus)
end

local function _CollectBiomeIDs()
	local biomes = require "defs.biomes"
	local biomes_ordered = {}

	for _, location in pairs(biomes.locations) do
		table.insert(biomes_ordered, location.region_id)
	end
	
	biomes_ordered = lume.unique(biomes_ordered)
	biomes_ordered = lume.sort(biomes_ordered, function(a, b) return a < b end)

	return biomes_ordered
end

-- Editor UI for trap spawners.
function EnergyWellPillar.PropEdit(editor, ui, params)
	local args = params.script_args or {}

	local biomes_ordered = _CollectBiomeIDs()
	local biome_id = args.biome_id or ""
	local biome_idx = lume.find(biomes_ordered, biome_id) or 1
	local changed, newvalue = ui:Combo("Biome:", biome_idx, biomes_ordered)

	if changed and newvalue ~= biome_idx then
		biome_idx = newvalue
		args.biome_id = biomes_ordered[biome_idx]
	end

end

return EnergyWellPillar
