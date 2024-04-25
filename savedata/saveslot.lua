local DungeonSave = require "savedata.dungeonsave"
local PlayerSave = require "savedata.playersave"
local SaveData = require "savedata.savedata"
local SaveDataFormat = require "savedata.save_data_format"

local NUM_CHARACTER_SLOTS <const> = 4

local SaveSlot = Class(function(self, slot)
	local folder_name = ("slot_%s"):format(slot)

	-- saves for each player character within this slot
	self.character_slots = {}
	for i = 1, NUM_CHARACTER_SLOTS do
		self.character_slots[i] = PlayerSave(i, ("%s/characters"):format(folder_name))
			:CloudSync()
	end

	-- Information about the save slot, such as which character was last selected when playing this slot.
	self.about_slot = SaveData(("%s/about_slot"):format(folder_name), SaveDataFormat.id.About)
		:CloudSync()

	-- the town for this slot
	self.town_save = DungeonSave(folder_name, "town", function()
		local isHost = TheNet:IsHost() -- can return true for legacy purposes when "offline"
		local isInGame = TheNet:IsInGame() -- need to test if not in a game session (i.e. if the host disconnects before the client)
		TheLog.ch.SaveLoad:printf("    Checking - is host: %s, in game: %s", isHost, isInGame)
		return isHost and isInGame
	end)
		:CloudSync()
end)

function SaveSlot:GetCharacterSaves()
	return self.character_slots
end

function SaveSlot:GetTownSave()
	return self.town_save
end

function SaveSlot:GetAboutSlot()
	return self.about_slot
end

function SaveSlot:Load(mcb)
	for i, save in ipairs(self.character_slots) do
		save:Load(mcb:AddInstance())
	end
	self.town_save:Load(mcb:AddInstance())
	self.about_slot:Load(mcb:AddInstance())
end

function SaveSlot:Erase(mcb)
	for _, save in pairs(self.character_slots) do
		save:Erase(mcb:AddInstance())
	end
	self.town_save:Erase(mcb:AddInstance())
	self.about_slot:Erase(mcb:AddInstance())
end

return SaveSlot
