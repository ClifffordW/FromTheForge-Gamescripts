local FollowPrompt = require("widgets/ftf/followprompt")
local HeartTooltip = require("widgets/ftf/hearttooltip")

local Consumable = require("defs/consumable")
local lume = require("util/lume")
local Enum = require "util.enum"

local EnergyWell = Class(function(self, inst)
	self.inst = inst

	-- after the player interacts with the machine
	-- it scans nearby and sees which players have a queued up heart
	-- once it notices them, it grabs the queued heart and begins to process it.
	-- networked
	self.processing_states = {
		[0] = ENERGY_WELL_PROCESSING_STATE.id.IDLE,
		[1] = ENERGY_WELL_PROCESSING_STATE.id.IDLE,
		[2] = ENERGY_WELL_PROCESSING_STATE.id.IDLE,
		[3] = ENERGY_WELL_PROCESSING_STATE.id.IDLE,
	}

	-- widgets shown beside players
	-- local
	self.active_widgets = {}

	self.inst:StartUpdatingComponent(self)
end)

-- Deposit Flow

function EnergyWell:RequestDepositHeartForPlayer(player)
	local heart = self:GetBestHeartToDeposit(player)
	player.components.heartmanager:QueueHeartDeposit(self, heart:GetDef())
end

function EnergyWell:SetProcessingState(id, state)
	if self.processing_states[id] == state then return end
	self.processing_states[id] = state

	if state == ENERGY_WELL_PROCESSING_STATE.id.ACTIVE then
		self.inst:PushEvent("deposit_heart")
	end
end

function EnergyWell:GetProcessingState(id)
	return self.processing_states[id]
end

-- Called at the end of the 'activate' state in the stategraph.
function EnergyWell:ConsumeProcessedHearts()
	for playerID, _ in pairs(self.processing_states) do
		if self:GetProcessingState(playerID) == ENERGY_WELL_PROCESSING_STATE.id.ACTIVE then
			self:SetProcessingState(playerID, ENERGY_WELL_PROCESSING_STATE.id.DONE)
		end
	end
end

function EnergyWell:OnUpdate()
	-- Every frame, scan all nearby players and see if they have deposited a heart.
	-- If they have, start doing the deposit presentation.
	local players = self.inst.components.playerproxradial:FindPlayersInRange()
	for _, player in ipairs(players) do
		local playerID = player.Network:GetPlayerID()
		local heart_def = player.components.heartmanager:GetQueuedHeart()
		if heart_def then
			if not self:IsProcessingHeartForPlayer(playerID) then
				self:SetProcessingState(playerID, ENERGY_WELL_PROCESSING_STATE.id.ACTIVE)
			end
		else
			self:SetProcessingState(playerID, ENERGY_WELL_PROCESSING_STATE.id.IDLE)
		end
	end
end

-- If we ever add more than 3 states to the ENERGY_WELL_PROCESSING_STATE enum, we need to increase this.
local MAX_SYNCED_NUM <const> = RequiredBitCount(4)

function EnergyWell:OnNetSerialize()
	local player_ids = TheNet:GetAllPlayerIDs()
	self.inst.entity:SerializeUInt(#player_ids, MAX_SYNCED_NUM)
	for _, player_id in ipairs(player_ids) do
		self.inst.entity:SerializeUInt(player_id, MAX_SYNCED_NUM)
		self.inst.entity:SerializeUInt(self.processing_states[player_id], MAX_SYNCED_NUM)
	end
end

function EnergyWell:OnNetDeserialize()
	local num = self.inst.entity:DeserializeUInt(MAX_SYNCED_NUM)
	for i = 1, num do
		local id = self.inst.entity:DeserializeUInt(MAX_SYNCED_NUM)
		local state = self.inst.entity:DeserializeUInt(MAX_SYNCED_NUM)
		self.processing_states[id] = state
	end
end

-- Util Functions

function EnergyWell:_GetHeartDef(heart)
	return Consumable.FindItem(heart.id)
end

function EnergyWell:IsProcessingHeartForPlayer(id)
	local state = self:GetProcessingState(id)
	return state ~= ENERGY_WELL_PROCESSING_STATE.id.IDLE
end

function EnergyWell:GetHeartsForPlayer(player)
	-- return a list of hearts this player has
	local hearts = player.components.inventoryhoard:GetMaterialsWithTag("konjur_heart")
	return hearts
end

function EnergyWell:GetBestHeartToDeposit(player)
	local hearts = self:GetHeartsForPlayer(player)
	hearts = lume.sort(hearts, function(a, b) return a.acquire_order < b.acquire_order end)
	return hearts[1]
end

function EnergyWell:IsAnyPlayerEligible(players)
	for _, player in ipairs(players) do
		local has_heart = player.components.heartmanager:IsCarryingHeart()
		if has_heart then
			return true, player:IsLocal()
		end
	end
	return false
end

-- Widget Functions

function EnergyWell:ShowHeartDepositDetails(player, heart)
	if self.active_widgets[player] then
		self:HideHeartDepositDetails(player)
	end

	local heart_data = player.components.heartmanager:GetHeartDataForHeartID(heart)

	self.active_widgets[player] = TheDungeon.HUD:AddWorldWidget(FollowPrompt(self.inst))
		:SetName("Heart Details")
		:SetTarget(player)
		:SetRegistration("right", "center")
		:SetOffsetFromTarget(Vector3(-0.6, 4.5, 0))
		:SetClickable(false)

	local tt = self.active_widgets[player]:AddChild(HeartTooltip())

	tt:LayoutWithContent({
		player = player,
		heart_data = heart_data,
		show_upgrade = true,
	})
end

function EnergyWell:HideHeartDepositDetails(player)
	if self.active_widgets[player] then
		self.active_widgets[player]:Remove()
		self.active_widgets[player] = nil
	end
end

return EnergyWell
