local SaveData = require "savedata.savedata"
local RoomSave = require "savedata.roomsave"
local SaveDataFormat = require "savedata.save_data_format"

local DungeonSave = Class(SaveData, function(self, folder, file, save_pred)
	assert(folder ~= nil and file ~= nil and string.len(folder) > 0 and string.len(file) > 0)
	self.folder = folder
	self.file = file
	SaveData._ctor(self, self.folder.."/"..self.file, SaveDataFormat.id.Dungeon, save_pred)
end)

function DungeonSave:CloudSync()
	DungeonSave._base.CloudSync(self)
	-- Only the cloud folder is sync'd.
	self.folder = "cloud/" .. self.folder
	return self
end

function DungeonSave:ResolveRoomFolder()
	return self.folder.."/rooms"
end

function DungeonSave:ResolveRoomFilename(roomid)
	return string.format("%s/room%02d", self:ResolveRoomFolder(), roomid)
end

function DungeonSave:SaveCurrentRoom(roomid, cb, required_tags)
	if not self:CanSave(self) then
		TheLog.ch.SaveLoad:printf("[DungeonSave:SaveCurrentRoom] Skipping save: /%s (predicate did not pass)", self.file)
		if cb ~= nil then
			cb(true)
		end
		return
	end

	local filename = self:ResolveRoomFilename(roomid)
	TheLog.ch.WorldGen:print("Saving room: /"..filename.."...")
	local room_save = RoomSave(filename)
	room_save:PersistFromWorld(required_tags)
	room_save:Save(cb)
end

function DungeonSave:LoadRoom(roomid, cb)
	local filename = self:ResolveRoomFilename(roomid)
	TheLog.ch.WorldGen:print("Loading room: /"..filename.."...")
	local room_save = RoomSave(filename)
	room_save:Load(function(success)
		if success then
			TheLog.ch.WorldGen:print("Successfully loaded room: /"..filename)
			if cb then
				cb(room_save.persistdata)
			end
		else
			-- Not an error, we just haven't been here yet.
			TheLog.ch.WorldGen:print("No savedata, loading fresh room: /"..filename)
			if cb then
				cb(nil)
			end
		end
	end)
end

function DungeonSave:ClearAllRooms(cb)
	local folder = self:ResolveRoomFolder()
	TheLog.ch.WorldGen:print("Clearing rooms: /"..folder.."/*...")
	TheSim:EmptyPersistentDirectory(folder, function(success)
		if success then
			TheLog.ch.WorldGen:print("Successfully cleared rooms: /"..folder.."/*")
		else
			TheLog.ch.WorldGen:print("Failed to clear rooms: /"..folder.."/*")
			dbassert(false)
		end
		if cb then
			cb(success)
		end
	end)
end

function DungeonSave:Erase(cb)
	local _cb = MultiCallback()

	DungeonSave._base.Erase(self, _cb:AddInstance())
	self:ClearAllRooms(_cb:AddInstance())

	_cb:WhenAllComplete(cb)
end

return DungeonSave
