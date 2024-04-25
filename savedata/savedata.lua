local DataDumper = require "util.datadumper"
local VersionUpdaterRegistry = require "savedata.version_updater_registry"
local SaveDataFormat = require "savedata.save_data_format"
local Version = require "savedata.version"

-- Base class for handling save data to external files
local SaveData = Class(function(self, filename, format_id, save_pred)
	assert(filename ~= nil and filename:len() > 0)
	self.filename = filename
	assert(save_pred == nil or type(save_pred) == "function")
	if save_pred then
		TheLog.ch.SaveLoad:printf("%s has a save predicate.", filename)
	end
	self.format_id = format_id
	self.save_pred = save_pred
	self:Reset()
end)

function SaveData:CloudSync()
	-- Only the cloud folder is sync'd.
	self.filename = "cloud/" .. self.filename
	return self
end

function SaveData:SetValue(name, value)
	--Currently not bothering with deepcompare
	if self.persistdata[name] ~= value then
		self.persistdata[name] = value
		self.dirty = true
	end
	return self
end

function SaveData:IncrementValue(name)
	local v = (self:GetValue(name) or 0) + 1
	self:SetValue(name, v)
	return v
end

function SaveData:GetValue(name)
	return self.persistdata[name]
end

function SaveData:IsVersionless()
	return self.format_id == nil
end
function SaveData:CanSave()
	if self.save_pred then
		TheLog.ch.SaveLoad:printf("Calling save predicate for %s...", self.filename)
		return self.save_pred()
	end
	return true
end

function SaveData:Save(cb)
	if not self:CanSave() then
		TheLog.ch.SaveLoad:printf("[SaveData:Save] Skipping save: /%s (predicate did not pass)", self.filename)
		if cb ~= nil then
			cb(true) --success = true
		end
		return
	end

	if self.dirty then
		TheLog.ch.SaveLoad:print("Saving: /"..self.filename.."...")
		local PRETTY_PRINT = DEV_MODE
		local data = DataDumper(self.persistdata, nil, not PRETTY_PRINT)
		TheSim:SetPersistentString(self.filename, data, ENCODE_SAVES, function(success)
			TheLog.ch.SaveLoad:indent()
			if success then
				TheLog.ch.SaveLoad:print("Successfully saved: /"..self.filename)
				self.dirty = false
			else
				TheLog.ch.SaveLoad:print("Failed to save: /"..self.filename)
				dbassert(false)
			end
			TheLog.ch.SaveLoad:unindent()
			if cb ~= nil then
				cb(success)
			end
		end)
	else
		TheLog.ch.SaveLoad:printf("Skipping save: /%s (not dirty)", self.filename)
		if cb ~= nil then
			cb(true) --success = true
		end
	end
end

-- Only when you don't care about failures! Mostly just for debug.
function SaveData:Load_ResetOnFailure(cb)
	assert(cb, "Why bother if you don't have a callback?")
	self:Load(function(success)
		if not success then
			self:Reset()
		end
		cb(true)
	end)
end

function SaveData:PromptForSaveDeletion()
	assert(not SAVE_DATA_VERSION_UPDATE_ENABLED, "Failed to version-update save data " .. self.filename)

	if TheSaveSystem.can_prompt_for_save_deletion then
		-- This flag will have the MainMenu screen prompt for save game deletion.
		TheSaveSystem.bad_save_data = true
	else
		-- Crash.
		-- If in Release, then we have not provided sufficient version updaters.
		-- If in Dev, then we have gotten past the point where we can prompt the user to delete saves.
		assert(false, "Version update failed for " .. self.filename)
	end
end
-- Open the file, load the data, interpret it as a Lua table, update it to the current VERSION if necessary, then
-- invoke the callback.
function SaveData:Load(cb)
	TheLog.ch.SaveLoad:print("Loading: /"..self.filename.."...")
	TheSim:GetPersistentString(self.filename, function(success, data)
		TheLog.ch.SaveLoad:indent()
		if not success then
			TheLog.ch.SaveLoad:printf("SaveData [/%s] file failed to open (does not exist?).", self.filename)
		elseif string.len(data) == 0 then
			TheLog.ch.SaveLoad:printf("SaveData [/%s] file is empty.", self.filename)
		else
			success, data = RunInSandbox(data)
			if not success then
				TheLog.ch.SaveLoad:printf("SaveData [/%s] data failed to parse", self.filename)
			elseif data then
				TheLog.ch.SaveLoad:printf("SaveData [/%s] data parsed successfully", self.filename)

				self.dirty = false

				if not self:IsVersionless() then
					-- Initialize unversioned data to 0.
					data.version = data.version or 0

					-- Chop the dev version in release.
					if SAVE_DATA_VERSION_UPDATE_ENABLED then
						data.version = Version.ReleaseFromEffective(data.version)
					end

					-- Data saved with Dev version will never match in release builds because Effective() resolves
					-- to the integer Release version and a saved Dev version wiil be a floating point Release.Dev.
					success = data.version == Version.Effective()

					-- Only attempt a version update in release builds. In dev builds, always require a save deletion.
					if not success and SAVE_DATA_VERSION_UPDATE_ENABLED then
						local version_updated, updated_data = self:VersionUpdate(data)
						if version_updated then
							data = updated_data
							self.dirty = true
							success = true
						end
					end
				end

				if success then
					self.persistdata = data
				end
			end

			if not success then
				-- If we tried to update and failed, our game is still in a runnable state, but our save data has been
				-- ignored. The user needs to be informed.
				self:PromptForSaveDeletion()
			end
		end
		TheLog.ch.SaveLoad:unindent()

		if cb then
			cb(success)
		end
	end)
end

function SaveData:VersionUpdate(data)
	TheLog.ch.SaveLoad:printf(
		"Updating version of SaveData [%s], with format [%s] from [%d] to [%d]",
		self.filename,
		SaveDataFormat:FromId(self.format_id),
		data.version,
		Version.Release()
	)

	assert(data.version ~= Version.Release(), "If the versions match, why are we updating?")

	-- Clone the data and mutate the clone. If any failures occur, we still have a pristine copy of the original data
	-- to fall back on.
	local updated_data = deepcopy(data)

	-- Apply updates in the order that they appear in the VersionUpdaterRegistry.
	TheLog.ch.SaveLoad:indent()
	for _, version_updater in ipairs(VersionUpdaterRegistry) do
		if updated_data.version == version_updater.from_version then
			TheLog.ch.SaveLoad:printf("Incrementally updating version from [%d] to [%d].", updated_data.version,
				version_updater.to_version)

			-- Updating the data of each SaveDataFormat is optional.
			local fn = version_updater.fns[self.format_id]
			if fn then
				fn(updated_data)
			end

			-- Note that to_version is not necessarily an increment by 1.
			updated_data.version = version_updater.to_version
			-- If we have finished, we can break early. More updaters is weird, but maybe due to dev-QoL updaters.
			if updated_data.version == Version.Release() then
				break
			end
		end
	end
	TheLog.ch.SaveLoad:unindent()

	if updated_data.version ~= Version.Release() then
		TheLog.ch.SaveLoad:print("Version update failed.")
		-- Return false and stick with the untouched data.
		return false
	else
		TheLog.ch.SaveLoad:print("Version update succeeded.")
		return true, updated_data
	end
end

function SaveData:Reset()
	local empty_persistdata = {}
	-- Freshly constructed SaveData are always of the most recent version.
	if not self:IsVersionless() then
		empty_persistdata.version = Version.Effective()
	end
	if not deepcompare(self.persistdata, empty_persistdata) then
		self.persistdata = empty_persistdata
		self.dirty = true
	end
end

function SaveData:Erase(cb)
	self:Reset()
	TheLog.ch.SaveLoad:print("Deleting: /"..self.filename.."...")
	TheSim:CheckPersistentStringExists(self.filename, function(exists)
		if exists then
			TheSim:ErasePersistentString(self.filename, function(success)
				if success then
					TheLog.ch.SaveLoad:print("Successfully deleted: /"..self.filename)
					self.dirty = true
				else
					TheLog.ch.SaveLoad:print("failed to delete: /"..self.filename)
					dbassert(false)
				end
				if cb ~= nil then
					cb(success)
				end
			end)
		else
			TheLog.ch.SaveLoad:print("File not found: /"..self.filename)
			dbassert(self.dirty)
			if cb ~= nil then
				cb(true)
			end
		end
	end)
end

return SaveData
