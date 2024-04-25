local DungeonSave = require "savedata.dungeonsave"
local Placer = require "components.placer"
local PlayerSave = require "savedata.playersave"
local ProgressSave = require "savedata.progresssave"
local SaveData = require "savedata.savedata"
local SaveSlot = require"savedata.saveslot"
local playerutil = require "util.playerutil"
local SaveDataFormat = require "savedata.save_data_format"

local NUM_SAVE_SLOTS <const> = 4

local SaveSystem = Class(function(self)
	-- SAVE_SLOT_MANAGEMENT

	-- longer term data that we will need cross-session, such as which save slot was last used.
	self.save_management = SaveData("save_management", SaveDataFormat.id.SaveManagement)
		:CloudSync()

	-- saves which (local) character saves are currently active
	-- wiped when the game returns to menu or is closed.
	self.active_players = SaveData("active_players", SaveDataFormat.id.ActivePlayers)
		:CloudSync()

	self.save_slots = {}
	for i = 1, NUM_SAVE_SLOTS do
		local save_slot = SaveSlot(i)
		self.save_slots[i] = save_slot
	end

	--- MISC SAVE MANAGEMENT ---

	-- unknown how (or if) this will be used, am not going to touch it for now
	self.friends = SaveData("friends", SaveDataFormat.id.Friends)
		:CloudSync()

	-- holds some misc debug data and other data required for running the game properly
	-- TODO: evaluate what is using this and remove unnecessary use cases
	self.progress = ProgressSave("progress", SaveDataFormat.id.Progress)
		:CloudSync()

	-- Save cheat data that will persist between rooms (to force specific rooms
	-- or powers). Erased on startup, to prevent locally broken behaviour.
	self.cheats = SaveData("cheats", SaveDataFormat.id.Cheats)
	-- no CloudSync: not loaded after exe restart.

	-- Permanent data we never delete (even when player resets their save) to
	-- help distinguish smurf players in feedback. Put data in here you want to
	-- track with feedback, but don't use it in logic.
	-- 'permanent' SaveData has a nil SaveDataFormat implying it has no version
	-- number and is never run through the version-update process.
	self.permanent = SaveData("permanent")
		:CloudSync()

	-- Network data: Ban list, previously checked and favourited groups, etc.
	self.network = SaveData("network", SaveDataFormat.id.Network)
		:CloudSync()

	self.dungeon = DungeonSave("dungeon_temp", "dungeon")
	-- no CloudSync: not loaded after exe restart.
end)

----------------------------------------------------------------------------------
--   _____                   _____ _       _
--  /  ___|                 /  ___| |     | |
--  \ `--.  __ ___   _____  \ `--.| | ___ | |_ ___
--   `--. \/ _` \ \ / / _ \  `--. \ |/ _ \| __/ __|
--  /\__/ / (_| |\ V /  __/ /\__/ / | (_) | |_\__ \
--  \____/ \__,_| \_/ \___| \____/|_|\___/ \__|___/
----------------------------------------------------------------------------------

function SaveSystem:SetActiveSaveSlot(slot)
	self.save_management:SetValue("active_save_slot", slot)
	self.save_management:Save()
end

function SaveSystem:GetActiveSaveSlot()
	return self.save_management:GetValue("active_save_slot") or 1
end

function SaveSystem:GetActiveCharacterSaves()
	local active_slot = self:GetSaveSlot(self:GetActiveSaveSlot())
	return active_slot:GetCharacterSaves()
end

function SaveSystem:GetActiveTownSave()
	local active_slot = self:GetSaveSlot(self:GetActiveSaveSlot())
	return active_slot:GetTownSave()
end

function SaveSystem:GetActiveAboutSlot()
	local active_slot = self:GetSaveSlot(self:GetActiveSaveSlot())
	return active_slot:GetAboutSlot()
end

function SaveSystem:SetLastSelectedCharacterSlot(slot, mcb_instance)
	self:GetActiveAboutSlot():SetValue("last_selected_character_slot", slot)
	if mcb_instance then
		self:GetActiveAboutSlot():Save(mcb_instance)
	end
end

function SaveSystem:GetLastSelectedCharacterSlot()
	return self:GetActiveAboutSlot():GetValue("last_selected_character_slot") or 1
end

function SaveSystem:SetLastSelectedLocation(id, mcb_instance)
	self:GetActiveAboutSlot():SetValue("last_selected_location", id)
	if mcb_instance then
		self:GetActiveAboutSlot():Save(mcb_instance)
	end
end

function SaveSystem:GetLastSelectedLocation()
	return self:GetActiveAboutSlot():GetValue("last_selected_location")
end

function SaveSystem:GetSaveSlot(slot)
	return self.save_slots[slot]
end

function SaveSystem:GetAllSaveSlots()
	return self.save_slots
end

function SaveSystem:GetSaveSlotName(slot)
	local str = ("slot_name"):format(slot)
	return self:GetSaveSlot(slot):GetAboutSlot():GetValue(str) or ("SLOT %s"):format(slot)
end

function SaveSystem:SetSaveSlotName(slot, name, cb)
	local str = ("slot_name"):format(slot)
	self:GetSaveSlot(slot):GetAboutSlot():SetValue(str, name)
	self:GetSaveSlot(slot):GetAboutSlot():Save(cb)
end

----------------------------------------------------------------------------------
-- ______ _                         _____                   _____ _       _
-- | ___ \ |                       /  ___|                 /  ___| |     | |
-- | |_/ / | __ _ _   _  ___ _ __  \ `--.  __ ___   _____  \ `--.| | ___ | |_ ___
-- |  __/| |/ _` | | | |/ _ \ '__|  `--. \/ _` \ \ / / _ \  `--. \ |/ _ \| __/ __|
-- | |   | | (_| | |_| |  __/ |    /\__/ / (_| |\ V /  __/ /\__/ / | (_) | |_\__ \
-- \_|   |_|\__,_|\__, |\___|_|    \____/ \__,_| \_/ \___| \____/|_|\___/ \__|___/
--                 __/ |
--                |___/
----------------------------------------------------------------------------------

function SaveSystem:ErasePlayerSave(slot, mcb)
	local character_saves = TheSaveSystem:GetActiveCharacterSaves()
	character_saves[slot]:Erase(mcb:AddInstance())
end

function SaveSystem:IsSlotActive(slot)
	local local_players = TheNet:GetLocalPlayerList()
	for _, id in pairs(local_players) do
		-- because playerID starts at 0 instead of 1, they must be tostring'd or the tables behave strangely.
		if self.active_players:GetValue(tostring(id)) == slot then
			return true
		end
	end
	return false
end

function SaveSystem:IsPlayerActive(id)
	-- because playerID starts at 0 instead of 1, they must be tostring'd or the tables behave strangely.
	return self.active_players:GetValue(tostring(id)) ~= nil
end

function SaveSystem:OnLocalPlayerLeave(id)
	-- because playerID starts at 0 instead of 1, they must be tostring'd or the tables behave strangely.
	self.active_players:SetValue(tostring(id), nil)
	self.active_players:Save()
end

function SaveSystem:LoadCharacterAsPlayerID(slot, id)
	-- because playerID starts at 0 instead of 1, they must be tostring'd or the tables behave strangely.
	self.active_players:SetValue(tostring(id), slot)
	self.active_players:Save()

	-- If there is only one local player (or the local player list doesn't
	-- exist yet), that player must be the "main" local player.
	if playerutil.CountLocalPlayers() == 1 then
		self:SetLastSelectedCharacterSlot(slot)
	end

	local character_saves = self:GetActiveCharacterSaves()

	if character_saves[slot] then
		local player_data = character_saves[slot]:GetValue("playerdata")
		if player_data then
			-- TheLog.ch.SaveSystemSpam:printf("PlayerData loading via\n%s", debugstack())
			ThePlayerData:SetLoadData(id, player_data)
		end
	end

	return character_saves[slot]
end

function SaveSystem:SaveCharacterForPlayerID(playerID, cb)
	-- called when character screen is exited
	local player = GetPlayerEntityFromPlayerID(playerID)
	-- because playerID starts at 0 instead of 1, they must be tostring'd or the tables behave strangely.
	local slot = self:GetCharacterForPlayerID(playerID)

	-- if not slot then --[[error here]] end
	
	-- Cannot save playerdata here, because this function is bypassed for dungeon room-to-room navigation (SaveAll is used)
	-- Instead, see PlayerSave:Save
	-- TheLog.ch.SaveSystemSpam:printf("PlayerSave saving via\n%s", debugstack())
	-- local player_data = ThePlayerData:GetSaveData(playerID)
	-- self:GetSaveForCharacterSlot(slot):SetValue("playerdata", player_data)

	self:GetSaveForCharacterSlot(slot):Save(player, cb)
end

function SaveSystem:GetCharacterForPlayerID(playerID)
	-- because playerID starts at 0 instead of 1, they must be tostring'd or the tables behave strangely.
	local slot = self.active_players:GetValue(tostring(playerID))
	return slot
end

function SaveSystem:GetSaveForCharacterSlot(slot)
	local character_saves = self:GetActiveCharacterSaves()
	return character_saves[slot]
end

function SaveSystem:GetSaveForPlayerEntity(player)
	local playerID = player.Network:GetPlayerID()
	local slot = self:GetCharacterForPlayerID(playerID)
	return self:GetSaveForCharacterSlot(slot)
end

----------------------------------------------------------------------------------
--  _____                     _____                   _____ _       _
-- |_   _|                   /  ___|                 /  ___| |     | |
--   | | _____      ___ __   \ `--.  __ ___   _____  \ `--.| | ___ | |_ ___
--   | |/ _ \ \ /\ / / '_ \   `--. \/ _` \ \ / / _ \  `--. \ |/ _ \| __/ __|
--   | | (_) \ V  V /| | | | /\__/ / (_| |\ V /  __/ /\__/ / | (_) | |_\__ \
--   \_/\___/ \_/\_/ |_| |_| \____/ \__,_| \_/ \___| \____/|_|\___/ \__|___/
----------------------------------------------------------------------------------

function SaveSystem:SaveActiveTownSlotRoom(room_id, cb)
	self:GetActiveTownSave():SaveCurrentRoom(room_id, cb, {Placer.DECOR_TAG})
end

function SaveSystem:SaveActiveTownSlot(mcb_instance)
	self:GetActiveTownSave():Save(mcb_instance:AddInstance())
	self:GetActiveAboutSlot():Save(mcb_instance:AddInstance())
end

----------------------------------------------------------------------------------

function SaveSystem:SaveAll(cb)
	local _cb = MultiCallback()

	self:SaveAllExcludingRoom(_cb:AddInstance())
	self:SaveCurrentRoom(_cb:AddInstance())

	_cb:WhenAllComplete(cb)
end

function SaveSystem:SaveAllExcludingRoom(cb)
	local _cb = MultiCallback()

	self.active_players:Save(_cb:AddInstance())

	for _, playerID in pairs(TheNet:GetLocalPlayerList()) do
		local player = GetPlayerEntityFromPlayerID(playerID)

		if player then
			-- because playerID starts at 0 instead of 1, they must be tostring'd or the tables behave strangely.
			local slot = self:GetCharacterForPlayerID(playerID)

			if slot then
				-- if not slot then --[[error here]] end
				self:GetSaveForCharacterSlot(slot):Save(player, _cb:AddInstance())
			end
		end
	end

	self:SaveActiveTownSlot(_cb)

	self.cheats:Save(_cb:AddInstance())
	self.permanent:Save(_cb:AddInstance())
	self.friends:Save(_cb:AddInstance())
	self.progress:Save(_cb:AddInstance())
	self.dungeon:Save(_cb:AddInstance())
	self.network:Save(_cb:AddInstance())

	_cb:WhenAllComplete(cb)
end

function SaveSystem:SaveCurrentRoom(cb)
	local worldmap = TheDungeon and TheDungeon:GetDungeonMap()
	if worldmap then
		local room_id = worldmap:GetCurrentRoomId()
		if TheDungeon:IsInTown() then
			self:SaveActiveTownSlotRoom(room_id, cb)
		else
			self.dungeon:SaveCurrentRoom(room_id, cb)
		end
	elseif cb ~= nil then
		cb(false)
	end
end

function SaveSystem:LoadAll(cb)
	local eraser = MultiCallback()

	if RUN_GLOBAL_INIT then
		-- active players is only supposed to persist for a single play session, and should be erased on startup
		self.active_players:Erase(eraser:AddInstance())

		-- Erase cheats on first startup to prevent mysterious behaviour
		-- between runs. You can change them in your localexec.
		self.cheats:Erase(eraser:AddInstance())
	end

	-- Wait until we have erased files that we may now try to load.
	eraser:WhenAllComplete(function(eraser_success)
		local loader = MultiCallback()

		if not RUN_GLOBAL_INIT then
			-- We frequently delete cheats, so we don't care if they fail to load.
			self.cheats:Load_ResetOnFailure(loader:AddInstance())
		end

		self.save_management:Load(loader:AddInstance())

		for i, slot in ipairs(self.save_slots) do
			slot:Load(loader)
		end

		self.active_players:Load(loader:AddInstance())
		self.permanent:Load(loader:AddInstance())
		self.friends:Load(loader:AddInstance())
		self.progress:Load(loader:AddInstance())
		self.dungeon:Load(loader:AddInstance())
		self.network:Load(loader:AddInstance())

		loader:WhenAllComplete(cb)
	end)
end

function SaveSystem:EraseAll(cb)
	local _cb = MultiCallback()

	self.save_management:Erase(_cb:AddInstance())

	for i, slot in ipairs(self.save_slots) do
		slot:Erase(_cb)
	end

	self.active_players:Erase(_cb:AddInstance())

	self.cheats:Erase(_cb:AddInstance())
	-- Never erase permanent (see above). self.permanent:Erase()
	self.network:Erase(_cb:AddInstance())
	self.friends:Erase(_cb:AddInstance())
	self.progress:Erase(_cb:AddInstance())
	self.dungeon:Erase(_cb:AddInstance())

	_cb:WhenAllComplete(cb)
end

return SaveSystem
