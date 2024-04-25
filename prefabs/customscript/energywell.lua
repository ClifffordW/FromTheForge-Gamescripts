local Consumable = require("defs.consumable")
local EffectEvents = require("effectevents")

local EnergyWell = {
	default = {},
}

local function _PlayerHasHeartstone(inst, player)
	return player.components.heartmanager:IsCarryingHeart()
end

local function OnInteract(inst, player, opts)
	if _PlayerHasHeartstone(inst, player) and not player.components.heartmanager:GetQueuedHeart() then
		inst.components.energywell:RequestDepositHeartForPlayer(player)
	end
end

local function CanInteract(inst, player, is_focused)
	-- only if they have a heartstone
	return _PlayerHasHeartstone(inst, player) and not player.components.heartmanager:GetQueuedHeart()
end

local function BuildInteractLabel(inst, player)
	if _PlayerHasHeartstone(inst, player) then
		-- if player has any heart, deposit the heart
		local to_deposit = inst.components.energywell:GetBestHeartToDeposit(player)
		local def = Consumable.FindItem(to_deposit.id)
		return STRINGS.UI.HEARTSCREEN.INTERACT.BTN_PLACE_IN_WELL:subfmt({
				heartstone = def.pretty.name,
			})
	end
end

local function OnPlayerApproach(inst)
	-- If any nearby player has a heart that can be deposited the well reacts
	local players = inst.components.playerproxradial:FindPlayersInRange()
	if inst.components.energywell:IsAnyPlayerEligible(players) then
		inst:PushEvent("heart_near")
		-- EffectEvents.MakeNetEventPushEventOnMinimalEntity(inst, "heart_near")
	end
end

local function OnPlayerLeave(inst)
	-- If no nearby players have a heart that can be deposited the well goes back to idle
	local players = inst.components.playerproxradial:FindPlayersInRange()
	if not inst.components.energywell:IsAnyPlayerEligible(players) then
		inst:PushEvent("heart_far")
		-- EffectEvents.MakeNetEventPushEventOnMinimalEntity(inst, "heart_far")
	end
end

function EnergyWell.default.CollectPrefabs(prefabs, args)
	local biomes = require"defs.biomes"
	for id, def in pairs(biomes.locations) do
	    if def.type == biomes.location_type.DUNGEON and not def.hide then
	    	for _, boss in ipairs(def.monsters.bosses) do
	    		table.insert(prefabs, "fx_konjur_heart_"..boss)
	    	end
	    end
	end
end

function EnergyWell.default.CustomInit(inst, opts)
	assert(opts)
	EnergyWell.ConfigureEnergyWell(inst, opts)
end

function EnergyWell.ConfigureEnergyWell(inst, opts)
	inst:AddComponent("energywell")

	inst:AddComponent("interactable")

	inst:AddComponent("playerproxradial")
	inst.components.playerproxradial:SetRadius(10)
	inst.components.playerproxradial:SetOnNearFn(OnPlayerApproach)
	inst.components.playerproxradial:SetOnFarFn(OnPlayerLeave)

	inst.components.interactable:SetRadius(5)
		:SetInteractStateName("deposit_heart")
		:SetInteractConditionFn(function(_, player, is_focused) return CanInteract(inst, player, is_focused) end)
		:SetOnInteractFn(function(_, player) OnInteract(inst, player, opts) end)
		:SetOnGainInteractFocusFn(function(_, player)
			player.components.interactor:SetStatusText("energy_well", BuildInteractLabel(inst, player))

			local to_deposit = inst.components.energywell:GetBestHeartToDeposit(player)
			inst.components.energywell:ShowHeartDepositDetails(player, to_deposit.id)

		end)
		:SetOnLoseInteractFocusFn(function(_, player)
			player.components.interactor:SetStatusText("energy_well", nil)
			inst.components.energywell:HideHeartDepositDetails(player)
		end)

	inst:SetStateGraph("sg_energy_well")		
end

return EnergyWell
