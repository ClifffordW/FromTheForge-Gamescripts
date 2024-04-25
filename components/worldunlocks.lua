local Equipment = require"defs.equipment"
local itemcatalog = require"defs.itemcatalog"

local lume = require "util.lume"
require "util"

--
-- C++ API for accessing world flags through TheWorldData:
--
-- TheWorldData:IsValid()							--> Returns whether the data for the world is valid (loaded/synced). (May return false on clients for a short period at the start of the game)
--
-- TheWorldData:ResetUnlocks()						--> (Host only) Resets all unlocks
-- TheWorldData:ResetUnlocks("Category")			--> (Host only) Resets all unlocks in this category
--
-- TheWorldData:SetIsUnlocked("Category", "ID", true/false)	--> Set the unlock state of item with name ID in category Category to true or false
-- TheWorldData:IsUnlocked("Category", "ID")		--> Returns true/false for the given category and item
--
-- TheWorldData:GetAllUnlocked(category)			--> Gets all unlocks in the given category
--
-- TheWorldData:GetSaveData()						--> Returns a table with all saved data
-- TheWorldData:SetLoadData(datatable)				--> Loads the save-data-table into the unlocks
--
-- TheWorldData:GetSize()							--> Returns the size of the world-data in bytes (for network optimization purposes)
--
--  // CALLBACKS:
--
-- In addition to the API above, lua will received a callback in networking.lua whenever the world data changes. 
--
-- (networking.lua)	OnNetworkWorldDataChanged(isRemoteData) --> callback that happens when the data changes. isRemoteData signifies whether the data came from a remote machine, or a local machine (for example after loading the worlddata)
--



-- Total collection of everything the player's unlocked
local WorldUnlocks = Class(function(self, inst)
	self.inst = inst
end)

function WorldUnlocks:OnSave()
	return TheWorldData:GetSaveData()
end

function WorldUnlocks:OnLoad(data)
	assert(data)
	TheWorldData:SetLoadData(data);
end

function WorldUnlocks:OnPostSpawn()
	self:GiveDefaultUnlocks()
end

function WorldUnlocks:ResetUnlocksToDefault()
	TheWorldData:ResetUnlocks();
	self:GiveDefaultUnlocks()
end

function WorldUnlocks:GiveDefaultUnlocks()
	-- Default location and region unlocks and handled in unlocktracker.
	-- When the player unlocks a location or region, it also unlocks it for TheWorld
end

function WorldUnlocks:IsUnlocked(id, category)
	return TheWorldData:IsUnlocked(category, id)
end

function WorldUnlocks:SetIsUnlocked(id, category, unlocked)
	TheWorldData:SetIsUnlocked(category, id, unlocked)
	if unlocked then
		self.inst:PushEvent("global_item_unlocked", {id = id, category = category})
	else
		self.inst:PushEvent("global_item_locked", {id = id, category = category})
	end
end

function WorldUnlocks:GetAllUnlocked(category)
	local result = TheWorldData:GetAllUnlocked(category)
	if result then 
		return deepcopy(result)
	end
end

------------------------------------------------------------------------------------------------------------
--------------------------------------------- ACCESS FUNCTIONS ---------------------------------------------
------------------------------------------------------------------------------------------------------------


--------------------------------------------- LOCATIONS ---------------------------------------------
function WorldUnlocks:IsLocationUnlocked(id)
	return self:IsUnlocked(id, UNLOCKABLE_CATEGORIES.s.LOCATION)
end

function WorldUnlocks:UnlockLocation(location)
	self:SetIsUnlocked(location, UNLOCKABLE_CATEGORIES.s.LOCATION, true)
	self.inst:PushEvent("location_unlocked", location)
end

function WorldUnlocks:LockLocation(location)
	self:SetIsUnlocked(location, UNLOCKABLE_CATEGORIES.s.LOCATION, false)
end

--------------------------------------------- FLAGS ---------------------------------------------
function WorldUnlocks:IsFlagUnlocked(id)
	return self:IsUnlocked(id, UNLOCKABLE_CATEGORIES.s.FLAG)
end

function WorldUnlocks:UnlockFlag(flag)
	self:SetIsUnlocked(flag, UNLOCKABLE_CATEGORIES.s.FLAG, true)
end

function WorldUnlocks:LockFlag(flag)
	self:SetIsUnlocked(flag, UNLOCKABLE_CATEGORIES.s.FLAG, false)
end

--------------------------------------------- REGIONS ---------------------------------------------
function WorldUnlocks:IsRegionUnlocked(id)
	return self:IsUnlocked(id, UNLOCKABLE_CATEGORIES.s.REGION)
end

function WorldUnlocks:UnlockRegion(region)
	self:SetIsUnlocked(region, UNLOCKABLE_CATEGORIES.s.REGION, true)
end

function WorldUnlocks:LockRegion(region)
	self:SetIsUnlocked(region, UNLOCKABLE_CATEGORIES.s.REGION, false)
end
----------------------------------------------------------------------------------------------------


function WorldUnlocks:DebugDrawEntity(ui, panel, colors)
	local networkui = require "dbui.debug_network"
	networkui:RenderNetworkWorldData(ui)
end

return WorldUnlocks
