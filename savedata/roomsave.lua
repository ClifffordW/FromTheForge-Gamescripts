local SaveData = require "savedata.savedata"
local Lume = require "util.lume"
local SaveDataFormat = require "savedata.save_data_format"

local RoomSave = Class(SaveData, function(self, filename)
	SaveData._ctor(self, filename, SaveDataFormat.id.Room)
end)

-- Pull data from the current world that defines the current room and write it into our persistdata.
function RoomSave:PersistFromWorld(required_tags)
	local function HasRequiredTags(v)
		if not required_tags then
			return true
		end
		return Lume(required_tags):all(function(required_tag)
			return v:HasTag(required_tag)
		end
		):result()
	end

	local ents
	for _, v in pairs(Ents) do
		if v.persists
			and v.prefab ~= nil
			and v.entity:GetParent() == nil
			and v:IsLocal() -- Only save local entities
			and HasRequiredTags(v)
		then
			local record = v:GetSaveRecord()
			if ents == nil then
				ents = { [v.prefab] = { record } }
			else
				local t = ents[v.prefab]
				if t == nil then
					ents[v.prefab] = { record }
				else
					t[#t + 1] = record
				end
			end
		end
	end
	self:SetValue("ents", ents)

	self:SetValue("map",
	{
		prefab = TheWorld.prefab,
		scenegenprefab = TheSceneGen and TheSceneGen.prefab,
		data = TheWorld:GetPersistData(),
	})

	-- Save out the 'next' iterators of the encounter_deck. They are embedded in tables next to the lists
	-- that they index, so just save out the entire hierarchy rather than detangling now and retangling
	-- on load.
	local deck = TheDungeon:GetDungeonMap().encounter_deck
	self:SetValue("room_type_encounter_sets", deck and deck.room_type_encounter_sets)
end

return RoomSave
