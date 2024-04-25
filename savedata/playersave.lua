local SaveData = require "savedata.savedata"
local SaveDataFormat = require "savedata.save_data_format"

-- TODO @chrisp #save - rename to CharacterSave?
local PlayerSave = Class(SaveData, function(self, idx, folder)
	local name = string.format("character_slot_%s", idx)

	if folder ~= nil then
		name = ("%s/%s"):format(folder, name)
	end

	SaveData._ctor(self, name, SaveDataFormat.id.Character)
end)

function PlayerSave:Save(player, cb)
	if player ~= nil then
		local data = player:GetPersistData()
		self:SetValue("player", data)

		-- TheLog.ch.SaveSystemSpam:printf("PlayerSave saving via\n%s", debugstack())
		local player_data = ThePlayerData:GetSaveData(player.Network:GetPlayerID())
		self:SetValue("playerdata", player_data)
	end

	PlayerSave._base.Save(self, cb)
end

return PlayerSave
