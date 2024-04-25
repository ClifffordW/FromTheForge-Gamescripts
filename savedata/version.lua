--[[
Version of the save data file formats.

Breaking Saves:
- When you break saves, increment the Dev version by 1. This will inform other devs running the game with lower version
numbers that they need to delete their saves. Be sure to comment your version increment.
- Add an updater rule to version_updater_registry that will update saves from the current Release version to the next.
Probably a good idea to put a good comment here too.
- Test your updater by locally incrementing the Release version and setting SAVE_DATA_VERSION_UPDATE_ENABLED (in main.lua)
to true. Do not check this in though.
- When the Release build is being packaged up at the end of this release cycle, the release manager will contact you to
verify that your breaking change has a working associated updater rule.

Preparing a Release Build:
- Identify the devs that have made save-breaking releases by looking at the source control history of this file since
the last release. Anyone that bumped the Dev version probably introduced a breaking change. No one should have updated
the Release version.
- Check with all the identified devs to ensure that they have written appropriate rules in version_updater_registry to
update from the current Release version to the next.
- Increment the Release version by 1.
- Run the version_updater_test script against all the save data files in the save_data_archive folder (this all exists
right?). This ensures that all past versions can successfully update to the new Release version.
TODO @chrisp #save - this mode should have TEST_SAVE_DATA_VERSION_UPDATE set to true and load all the save files in
save_data_archive...you *could* do this manually
- Reset the Dev version to 0 by deleting all Dev version increments.

Implementation Notes:
- Keep the version numbers in a separate file so it is easy to see who has bumped versions via source control history.
- Give access to version numbers only via functions to prevent external code from modifying them.
- Do not mix the Release and Dev version into a single number as this creates untenable complexity.
]]

local MAX_DEV_VERSION <const> = 100

-- TODO @chrisp #save - @dbriscoe recommends using strict.readonly instead of functions
local Version = {}

function Version.Release()
	-- return 1 -- Prerelease internal version, introduced with prior versioning system.
	return 2 -- Early access release. First versioned release with new versioning system.
	-- Please comment each version.
end

local function Dev()
	local dev_version = 0 -- No dev changes since last release.

	local function IncrementVersion()
		dev_version = dev_version + 1
	end

	-- IncrementVersion() -- Example comment for what I changed to necessitate save game deletion.
	-- Please comment each version.

	-- On each release, all dev versions can be deleted.
	dbassert(
		dev_version < MAX_DEV_VERSION,
		"If dev_version gets to MAX_DEV_VERSION, the way that we compute our minor version breaks"
	)
	return dev_version
end

-- Return the floating point mixed Release.Dev version number.
function Version.Effective()
	return Version.Release() + (Dev() / MAX_DEV_VERSION)
end

-- Given a floating point mixed Release.Dev version number, return the Release version.
function Version.ReleaseFromEffective(version)
	return math.floor(version)
end

return Version
