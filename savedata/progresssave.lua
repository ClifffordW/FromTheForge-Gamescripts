local SaveData = require "savedata.savedata"
local SaveDataFormat = require "savedata.save_data_format"

local ProgressSave = Class(SaveData, function(self, filename)
	SaveData._ctor(self, filename, SaveDataFormat.id.Progress)
end)

function ProgressSave:Save(cb)
	if TheDungeon then
		TheDungeon.progression:WriteProgression()
	end
	ProgressSave._base.Save(self, cb)
end

return ProgressSave
