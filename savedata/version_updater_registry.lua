local SaveDataFormat = require "savedata.save_data_format"

-- A list of version updaters that will be applied to save data in order.
-- Incoming data will match the from_version and will be granted the to_version after a successful update.
-- Update functions specified in the 'fns' table must be keyed by SaveDataFormat.id.
-- 'to_version' can be more than 1 ahead of the 'from_version'
-- You can have a function for every SaveDataFormat in a single updater.
-- An updater with an empty 'fns' table is valid.
local VersionUpdaterRegistry = {
	--[[
	-- Example updater.
	{
		from_version = 0,
		to_version = 1,
		fns = {
			[SaveDataFormat.id.Room] = function(data)
				-- Prefab 'shrub_town' has been renamed to 'town_shrub'.
				data.ents.town_shrub = data.ents.shrub_town
				data.ents.shrub_town = nil
			end
		}
	},
	]]
	-- Empty updater to initialize unversioned files to 1, the internal pre-EA "release".
	{
		from_version = 0,
		to_version = 1,
		fns = {}
	},
	{
		from_version = 1,
		to_version = 2,
		fns = {}
	},
}

return VersionUpdaterRegistry
