-- TODO: networking2022, This was intentionally a copy/paste/modify of powerdrop.lua
-- Reconcile this with powerdrop.lua once we've sorted out what is common/different
local kstring = require "util.kstring"
local Power = require 'defs.powers'
local lume = require "util.lume"
local soundutil = require "util.soundutil"
local fmodtable = require "defs.sound.fmodtable"

local SoulDrop = Class(function(self, inst)
	self.inst = inst
	self.interact_radius = 2
	self.inst:AddComponent("roomlock")

	-- configuration
	self.spawn_order = 1 --if there are multiple power drops being spawned at once, what is the sequence of their appearance?
	self.appear_delay = 0 --after the prefab has been spawned, how many ticks until it appears?
	-- state
	self.prepared_id = 0 -- prepare can be called multiple times, so use a unique id to represent each call
	self.allowinteraction = false
	self.soul_count = 1

	-- SoulDrops now only spawn after the room is cleared, so we only need to
	-- block interaction when despawning.
	self.inst:ListenForEvent("despawn", function() self:PreventInteraction() end)
	self.inst:StartUpdatingComponent(self)
end)

function SoulDrop:OnEntityBecameLocal()
	-- Soul drops need to be registered with the host after the EntityID is assigned. OnEntityBecameLocal is a spot where it is guaranteed to have a valid EntityID
	if TheNet:IsHost() then
		TheNet:SpawnDropForAllPlayers(self.inst.Network:GetEntityID())
	end
end

function SoulDrop:OnNetSerialize()
	local e = self.inst.entity
	e:SerializeUInt(self.spawn_order, 4)
	e:SerializeUInt(self.appear_delay, 8)
	e:SerializeUInt(self.prepared_id, 8)
	e:SerializeBoolean(self.allowinteraction)
	e:SerializeUInt(self.soul_count, 3)
end

function SoulDrop:OnNetDeserialize()
	local e = self.inst.entity
	self.spawn_order = e:DeserializeUInt(4)
	self.appear_delay = e:DeserializeUInt(8)
	local old_prepared_id = self.prepared_id
	self.prepared_id = e:DeserializeUInt(8)
	local old_allowinteraction = self.allowinteraction
	self.allowinteraction = e:DeserializeBoolean()
	self.soul_count = e:DeserializeUInt(3)

	if old_prepared_id ~= self.prepared_id then
		self:PrepareToShowGem()
	end
	if old_allowinteraction ~= self.allowinteraction and self.allowinteraction then
		self:AllowInteraction()
	end
end

local function CheckInteractableConditions(inst, player)
	return inst.components.rotatingdrop:PlayerHasDrop(player)
end

function SoulDrop:SetOnPrepareToShowGem(fn)
	self.on_preparetoshowgem = fn
end

-- Configure everything about display here.
function SoulDrop:PrepareToShowGem(cfg, consumed_cb)
	if cfg then
		if not TheNet:IsHost() then
			return
		end
		self.appear_delay = assert(cfg.appear_delay_ticks)
		self.spawn_order = cfg.spawn_order or 1
		self.prepared_id = self.prepared_id + 1
	end
	self.on_preparetoshowgem(self.inst)
	self.consumed_cb = consumed_cb
end

function SoulDrop:GetAppearDelay()
	return self.appear_delay
end

function SoulDrop:GetSpawnOrder()
	return self.spawn_order
end

function SoulDrop:PreventInteraction()
	self.inst.components.interactable:SetInteractCondition_Never()
end

local function OnInteract(inst, player)
	inst.components.souldrop:_OnPickedUp(player)
end

function SoulDrop:AllowInteraction()
	-- This function may be called multiple times on the same SoulDrop!
	self.allowinteraction = true

	self.inst.components.interactable
		:SetInteractConditionFn(CheckInteractableConditions)
end

local function _GetDropForPlayer(inst, player)
	local player_drop = inst.components.rotatingdrop:GetDropForPlayer(player)
	if player_drop ~= nil then
		-- if this player has a player-specific drop, return the type of it
		return player_drop.soul_type
	else
		-- otherwise, return the general type of the parent drop
		return inst.soul_type
	end
end

local function _BuildInteractString(inst, player)
	local drop = _GetDropForPlayer(inst, player)
	local material = STRINGS.ITEMS.MATERIALS[drop]
	local soul_count = inst.components.souldrop.soul_count
	local name = soul_count == 1
		and material.name
		or material.name_multiple_fmt:subfmt({count = soul_count})
	return STRINGS.ITEMS.MATERIALS.TAKE_SOUL_BUTTON_NAME:subfmt({name = name})
end

function SoulDrop:ConfigureInteraction()
	self.inst.components.interactable:SetRadius(self.interact_radius)
		:SetInteractCondition_Never() -- until AllowInteraction is called
		:SetInteractStateName("powerup_interact")
		:SetAbortStateName("powerup_abort")
		:SetOnInteractFn(OnInteract)
		:SetOnGainInteractFocusFn(function(_, player)
			player.components.interactor:SetStatusText("souldrop", _BuildInteractString(self.inst, player))
		end)
		:SetOnLoseInteractFocusFn(function(_, player)
			player.components.interactor:SetStatusText("souldrop", nil)
		end)
end

function SoulDrop:OnFullyConsumed()
	self.inst:PushEvent("despawn")
	self.inst:RemoveComponent("roomlock")

	if self.consumed_cb then
		self.consumed_cb()
	end
end

function SoulDrop:_OnPickedUp(interacting_player)
	local playerid = interacting_player.Network:GetPlayerID()

	-- returns NIL if the power drop isn't activated yet. Otherwise the playerIDs of the remaining players.
	local remainingPlayers = TheNet:GetRemainingPlayersForDrop(self.inst.Network:GetEntityID())

	if remainingPlayers and table.contains(remainingPlayers, playerid) then
		TheNet:PickupDrop(self.inst.Network:GetEntityID(), playerid)
	end
end

function SoulDrop:OnUpdate(_dt)
	-- sync/refresh player drops in rotatingdrop

	-- returns NIL if the power drop isn't activated yet. Otherwise the playerIDs of the remaining players. 
	local remainingPlayers = TheNet:GetRemainingPlayersForDrop(self.inst.Network:GetEntityID())

	-- Only start removing picked up drops when the drop was activated.
	if not remainingPlayers then
		return
	end

	local pickedUpDrops = self.inst.components.rotatingdrop:GetPickedUpDrops(remainingPlayers)
	if not pickedUpDrops then
		return
	end

	for player, drop in pairs(pickedUpDrops) do
		dbassert(self.inst.components.rotatingdrop:PlayerHasDrop(player))
		local playerID = player.Network:GetPlayerID()

		TheLog.ch.SoulDrop:printf("SoulDrop:OnUpdate took_drop (ID %d) for PlayerID %d (guid=%d)", self.inst.Network:GetEntityID(), playerID or -1, player.GUID)
		self.inst:PushEvent("took_drop", player)

		if player:IsLocal() then
			if drop.soul_type and drop.soul_type == "konjur_soul_lesser" then
				soundutil.PlayCodeSound(player,fmodtable.Event.corestone_accept)
			end

			-- If the player initiated the pickup with input, they will be in the "powerup_interact" state and will
			-- respond to this event by transitioning to the "konjur_accept" state. If the player was granted the soul
			-- via the timeouts from C++ (m_dropTimeouts), then they are granted their soul without animated response.
			player:PushEvent("took_soul")
		end
	end	
end

function SoulDrop:GetDebugString()
	return string.format(
		"Allow Interaction[%s] Picked[%s]",
		self.allowinteraction or "false",
		self.picked or "false")
end

return SoulDrop
