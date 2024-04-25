local kassert = require "util.kassert"

local Consumable = require"defs.consumable"
local Heart = require "defs.hearts"
local itemforge = require "defs.itemforge"
local biomes = require"defs.biomes"

require "util"

local HeartManager = Class(function(self, inst)
	self.inst = inst

	-- per heart pairing, which of the pairs is currently active?
		-- 0 = none active
		-- 1 = first active
		-- 2 = second active
	self.active_hearts = {}

	self.hearts = {}

	for slot, slot_data in pairs(Heart.Items) do
		self.active_hearts[slot] = 0
		self.hearts[slot] = {}
		for _, heart in pairs(slot_data) do
			self.hearts[slot][heart.idx] = heart
		end
	end

	-- a table that isn't saved, but stores what the player has done this visit to allow for more contextual quip tags.
	self.action_mem = {}

	self.heart_fx = nil -- visual heart fx

	self.is_carrying_heart = false -- do you have a heart that the well should react to?

	self.energywell = nil -- when we deposit a heart, keep a reference to the machine
	self.processing_state = ENERGY_WELL_PROCESSING_STATE.id.IDLE -- Remember what the well's state is, react when it changes.

	self._new_run_fn = function() self:_AddAllPowers() end
	self.inst:ListenForEvent("start_new_run", self._new_run_fn)

	self._on_inventory_changed = function() self:_RefreshInventory() end
	self.inst:ListenForEvent("inventory_stackable_changed", self._on_inventory_changed)
	self.inst:ListenForEvent("inventory_changed", self._on_inventory_changed)
end)

function HeartManager:_RefreshInventory()
	local hearts = self.inst.components.inventoryhoard:GetMaterialsWithTag("konjur_heart")
	self.is_carrying_heart = #hearts > 0
end

function HeartManager:OnPostLoadWorld()
	self:_RefreshInventory()
end

function HeartManager:SwapHeartInSlot(slot)
	if self:CanSwapHeartForSlot(slot) then
		local current = self:GetEquippedIdxForSlot(slot)
		local new = current == 1 and 2 or 1
		self:EquipHeart(slot, new)
	end
end

function HeartManager:CanSwapHeartForSlot(slot)
	local current = self:GetEquippedIdxForSlot(slot)
	if current == 0 then return false end

	local heart_levels = self:GetHeartLevelsForSlot(slot)
	if not heart_levels then return end

	for i, level in ipairs(heart_levels) do
		if level == 0 then
			return false
		end
	end

	return true
end

function HeartManager:EquipHeart(slot, idx, silent)
	local old_equip = self.active_hearts[slot]

	if old_equip and old_equip ~= 0 and old_equip ~= idx then
		self:_RemovePowerForSlot(slot)
	end

	self.active_hearts[slot] = idx
	self:_AddPowerForSlot(slot)

	TheDungeon:PushEvent("on_equip_heart", { player = self.inst, heart_data = { slot = slot, idx = idx, silent = silent } } )
end

function HeartManager:GetEquippedIdxForSlot(slot)
	local idx = self.active_hearts[slot]
	return idx
end

function HeartManager:GetEquippedHeartForSlot(slot)
	local idx = self.active_hearts[slot]
	return self.hearts[slot][idx]
end

function HeartManager:GetInactiveHeartForSlot(slot)
	local idx = self.active_hearts[slot]
	local inactive = idx == 1 and 2 or 1
	return self.hearts[slot][inactive]
end

function HeartManager:GetHeartLevelForLocation(location_id)
	local location = biomes.locations[location_id]
	if location.monsters and location.monsters.bosses then
		return self:GetHeartLevelForBoss(location.monsters.bosses[1])
	end
end

function HeartManager:GetHeartLevelForBoss(boss_prefab)
	for slot, hearts in pairs(self.hearts) do
		for i, heart in ipairs(hearts) do
			if heart.name == boss_prefab then
				return self:GetHeartLevel(slot, heart.idx)
			end
		end
	end
end

function HeartManager:GetHeartLevelForHeartID(heart_id)
	for slot, hearts in pairs(self.hearts) do
		for i, heart in ipairs(hearts) do
			if heart.heart_id == heart_id then
				return self:GetHeartLevel(slot, heart.idx)
			end
		end
	end
end

function HeartManager:IsBossHeartActive(boss_prefab)
	for slot, hearts in pairs(self.hearts) do
		for i, heart in ipairs(hearts) do
			if heart.name == boss_prefab then
				return self:GetEquippedHeartForSlot(slot) == heart
			end
		end
	end
end

function HeartManager:GetHeartLevelsForSlot(slot)
	return { self:GetHeartLevel(slot, 1), self:GetHeartLevel(slot, 2) }
end

function HeartManager:GetHeartDataForSlotIdx(slot, idx)
	return self.hearts[slot][idx]
end

function HeartManager:GetHeartDataForHeartID(heart_id)
	for slot, hearts in pairs(self.hearts) do
		for i, heart in ipairs(hearts) do
			if heart.heart_id == heart_id then
				return heart
			end
		end
	end
end

function HeartManager:GetSlotAndIdxFromID(id)
	local heart_slot = nil
	local heart_idx = nil

	-- Put the Heart definitions into those slots
	for slot, slot_data in pairs(Heart.Items) do
		for _, heart_def in pairs(slot_data) do
			if heart_def.heart_id == id then
				heart_slot = slot
				heart_idx = heart_def.idx
				break
			end
		end
	end

	return heart_slot, heart_idx
end

function HeartManager:GetHeartLevel(slot, idx)
	local playerID = self.inst.Network:GetPlayerID()
	if playerID ~= nil then
		return ThePlayerData:GetHeartLevel(playerID, slot, idx)
	end
	return 0
end

function HeartManager:SetHeartLevel(slot, idx, level, silent)
	local old_level = self:GetHeartLevel(slot, idx)

	level = math.min(4, level)

	local playerID = self.inst.Network:GetPlayerID()
	if playerID ~= nil then
		ThePlayerData:SetHeartLevel(playerID, slot, idx, level)
	end

	if not silent and old_level ~= level and self.active_hearts[slot] == idx then -- If the level has changed And we have this heart currently equipped
		self:_UpdatePowerForSlot(slot)
	end
end

function HeartManager:LevelUpHeart(slot, idx)
	local old_level = self:GetHeartLevel(slot, idx)
	local new_level = old_level + 1
	self:SetHeartLevel(slot, idx, new_level)

	local level_data = { 
		slot = slot,
		idx = idx,
		old_level = old_level,
		new_level = new_level,
		new_heart = old_level == 0,
	}

	return level_data
end

function HeartManager:_AddAllPowers()
	for slot,idx in pairs(self.active_hearts) do
		if idx ~= 0 then
			self:_AddPowerForSlot(slot)
		end
	end
end

function HeartManager:_AddPowerForSlot(slot)
	local active_idx = self.active_hearts[slot]
	local heart = self.hearts[slot][active_idx]

	local stacks = self:GetHeartLevel(slot, active_idx) * heart.stacks_per_level

	self.inst.components.powermanager:AddPowerByName(heart.power, stacks)
end

function HeartManager:_UpdatePowerForSlot(slot)
	local active_idx = self.active_hearts[slot]

	local heart = self.hearts[slot][active_idx]
	local level = self:GetHeartLevel(slot, active_idx)

	local pow_def = self.inst.components.powermanager:GetPowerByName(heart.power).def

	local new_stacks = level * heart.stacks_per_level

	self.inst.components.powermanager:SetPowerStacks(pow_def, new_stacks)
end

function HeartManager:_RemovePowerForSlot(slot)
	local active_idx = self.active_hearts[slot]
	local heart = self.hearts[slot][active_idx]

	self.inst.components.powermanager:RemovePowerByName(heart.power, true)
end

function HeartManager:IsCarryingHeart()
	return self.is_carrying_heart
end

function HeartManager:OnSave()
	return shallowcopy(self.active_hearts)
end

function HeartManager:OnLoad(data)
	if data ~= nil then

		if data.active_hearts then
			-- keeps older dev saves working
			for slot, active in pairs(data.active_hearts) do
				self.active_hearts[slot] = active
			end

			if data.heart_levels then
				for slot, levels in pairs(data.heart_levels) do
					for i, v in ipairs(levels) do
						self:SetHeartLevel(slot, i, v, true)
					end
				end
			end
		else
			self.active_hearts = shallowcopy(data)
		end

		-- adds any new slots that might've been created since
		for _, slot in pairs(Heart.Slots) do
			self.active_hearts[slot] = self.active_hearts[slot] or 0
		end
	end
end


-- Network Flow For Heart Deposits

-- active_heart can only be 0, 1 or 2 but this num is a bit higher to also allow for counting # of slots
local SERIALIZED_ACTIVE_HEART_BIT_COUNT <const> = RequiredBitCount(4)

function HeartManager:OnNetSerialize()
	self.inst.entity:SerializeUInt(table.count(self.active_hearts), SERIALIZED_ACTIVE_HEART_BIT_COUNT)
	for slot, active_idx in pairs(self.active_hearts) do
		self.inst.entity:SerializeString(slot, "PlayerData")	-- Use the  PlayerData string registry
		self.inst.entity:SerializeUInt(active_idx, SERIALIZED_ACTIVE_HEART_BIT_COUNT)
	end

	self.inst.entity:SerializeBoolean(self.is_carrying_heart)

	local queued_heart = self:GetQueuedHeart()
	self.inst.entity:SerializeBoolean(queued_heart ~= nil)
	if queued_heart then
		self.inst.entity:SerializeString(queued_heart.name)
	end
end

function HeartManager:OnNetDeserialize()
	local num = self.inst.entity:DeserializeUInt(SERIALIZED_ACTIVE_HEART_BIT_COUNT)
	for i = 1, num do
		local slot = self.inst.entity:DeserializeString("PlayerData")	-- Use the  PlayerData string registry
		local active = self.inst.entity:DeserializeUInt(SERIALIZED_ACTIVE_HEART_BIT_COUNT)
		self.active_hearts[slot] = active
	end

	self.is_carrying_heart = self.inst.entity:DeserializeBoolean()

	local has_queued_heart = self.inst.entity:DeserializeBoolean()
	if has_queued_heart then
		local heart_id = self.inst.entity:DeserializeString()
		self.queued_heart_def = Consumable.FindItem(heart_id)
	else
		self.queued_heart_def = nil
	end
end

function HeartManager:QueueHeartDeposit(energywell, heart_def)
	dbassert(self.queued_heart_def == nil, "Tried to deposit a heart with one already queued up")

	self.energywell = energywell
	self.queued_heart_def = heart_def

	self.inst:StartUpdatingComponent(self)
end

function HeartManager:OnUpdate()
	if self.energywell ~= nil then
		local processing_state = self.energywell:GetProcessingState(self.inst.Network:GetPlayerID())
		local local_state = self.processing_state

		if processing_state ~= local_state then
			if processing_state == ENERGY_WELL_PROCESSING_STATE.id.DONE then
				self:DoQueuedDeposit()
			end
			self.processing_state = processing_state
		end
	else
		self:RemoveHeartFX()
		self.processing_state = ENERGY_WELL_PROCESSING_STATE.id.IDLE
		self.queued_heart_def = nil
		self.inst:StopUpdatingComponent(self)
	end
end

function HeartManager:DoQueuedDeposit()
	if self:GetQueuedHeart() == nil then return end

	local level_details = self:ConsumeQueuedHeart()

	table.insert(self.action_mem, level_details)

	if level_details.new_heart then
		self:EquipHeart(level_details.slot, level_details.idx, true)

		-- this is run rarely, no need to always have it loaded
		local quest_helper = require "questral.game.rotwoodquestutil"
		-- resets the quip that Flitt has chosen.
		-- this allows him to comment on the heart you just added to the well
		-- even if you already spoke to him during this visit.
		quest_helper.ResetChosenQuipForNPC(self.inst, "npc_scout")
	end

	self.energywell = nil
end

function HeartManager:ConsumeQueuedHeart()
	dbassert(self.queued_heart_def ~= nil, "Tried to consume a heart with none queued up")

	self.inst:UnlockFlag(("pf_deposited_%s"):format(self.queued_heart_def.name))

	self.inst.components.inventoryhoard:RemoveStackable(self.queued_heart_def, 1)
	local slot, idx = self:GetSlotAndIdxFromID(self.queued_heart_def.name)
	self.queued_heart_def = nil

	return self:LevelUpHeart(slot, idx)
end

function HeartManager:GetQueuedHeart()
	return self.queued_heart_def
end

function HeartManager:SpawnHeartFX()
	if self.heart_fx then
		self:RemoveHeartFX()
	end

	local heart_def = self:GetQueuedHeart()

	-- spawn a heart fx at your current location
	local heart = SpawnPrefab("fx_"..heart_def.name)
	dbassert(heart ~= nil, "Failed to spawn Heart FX for "..heart_def.name)
	local pos = self.inst:GetPosition()
	pos.y = pos.y + 2
	heart.Transform:SetPosition(pos:Get())
	self.heart_fx = heart
end

function HeartManager:RemoveHeartFX()
	if not self.heart_fx then return end
	self.heart_fx:Despawn()
	self.heart_fx = nil
end

return HeartManager
