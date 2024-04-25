require "util"

local itemcatalog = require"defs.itemcatalog"
local biomes = require"defs.biomes"
local MetaProgress = require"defs.metaprogression"

local lume = require "util.lume"
local itemutil = require"util.itemutil"

local Cosmetics = require "defs.cosmetics.cosmetics"
local Power = require"defs.powers"
local Flags = require"gen.flagslist"

--
-- C++ API for accessing player flags through ThePlayerData:
--
--  // Validity
-- ThePlayerData:IsValidForAllPlayers()	--> Returns whether the data for ALL players is valid (loaded/synced)
-- ThePlayerData:IsValid(PlayerID)		--> Returns whether the data for this player is valid (loaded/synced)
--
--  // UNLOCKS
-- ThePlayerData:ResetUnlocks(PlayerID, (optional)"Category")			--> Resets all unlocks (optionally for just one category)
-- ThePlayerData:SetIsUnlocked(PlayerID, "Category", "ID", true/false)	--> Set the unlock state
-- ThePlayerData:IsUnlocked(PlayerID, "Category", "ID")					--> Returns true/false
-- ThePlayerData:GetAllUnlocked(playerID, category)						--> Gets all unlocks in the given category
--
--	// ASCENSION
-- ThePlayerData:ResetAscension(playerID)												--> Resets all ascension levels
-- ThePlayerData:SetAscensionLevelCompleted(playerID, location, weapon_type, level )	--> Set the ascension level for the given location and weapon_type.
-- ThePlayerData:GetCompletedAscensionLevel(playerID, location, weapon_type)			--> returns the Ascension level for the given location and weapon_type. -1 if not set. 
-- ThePlayerData:GetAllAscensionData(playerID)											--> Returns player ascension data
--
--	// COSMETICS
-- ThePlayerData:ResetCosmetics(PlayerID)												--> Resets all cosmetics
-- ThePlayerData:SetCosmeticIsUnlocked(PlayerID, "Category", "ID", true/false)			--> Set the unlock state of a particular cosmetic
-- ThePlayerData:IsCosmeticUnlocked(PlayerID, "Category", "ID")							--> Returns true/false
-- ThePlayerData:GetAllUnlockedCosmetics(playerID, "Category")							--> Returns a table with the names of all unlocked cosmetics in the provided category
--
--	// HEARTLEVELS
-- ThePlayerData:ResetHeartLevels(PlayerID)												--> Resets all heart levels
-- ThePlayerData:SetHeartLevel(PlayerID, "Region", index, level)						--> Set the level of the heart
-- ThePlayerData:GetHeartLevel(PlayerID, "Region", index)								--> Returns the level
-- ThePlayerData:GetAllHeartLevelData(playerID)											--> Returns player heart level data
--
--	// LOAD & SAVE (combines Unlocks, Ascension and Cosmetics into one table
-- ThePlayerData:GetSaveData(playerID)				--> Returns a table with all saved data
-- ThePlayerData:SetLoadData(playerID, datatable)	--> Loads the save-data-table into the unlocks
-- 
-- ThePlayerData:GetSize(playerID)					--> Returns the size of the data for that player (for debug purposes)
--
--
--  // CALLBACKS:
--
-- In addition to the API above, lua will received a callback in networking.lua whenever the player data changes. 
--
-- (networking.lua)	OnNetworkPlayerDataChanged(playerID, isRemoteData) --> callback that happens when the data changes for the given playerID. isRemoteData signifies whether the data came from a remote machine, or a local machine (for example when loading player settings)
--



-- Total collection of everything the player's unlocked
local UnlockTracker = Class(function(self, inst)
	self.inst = inst

	self.inst:ListenForEvent("location_unlocked", function(_, location) self:UnlockLocation(location) end, TheWorld)

	local function OnSpawnEnemy(_, enemy)
		local normal_prefab = nil
		if enemy:HasTag("miniboss") then
			normal_prefab = string.gsub(enemy.prefab, "_miniboss", "")
		elseif enemy:HasTag("elite") then
			normal_prefab = string.gsub(enemy.prefab, "_elite", "")
		end
		self:UnlockEnemy(enemy.prefab)

		if normal_prefab ~= nil then
			self:UnlockEnemy(normal_prefab)
		end
	end

	self.inst:ListenForEvent("spawnenemy", OnSpawnEnemy, TheWorld)


	local function OnEnterRoom()
		if not TheWorld:HasTag("town") then
			local room_type = TheWorld:GetCurrentRoomType()
			local flag_string = ("pf_seen_room_%s"):format(room_type)
			self:UnlockFlag(flag_string)
		end
	end

	self.inst:ListenForEvent("enter_room", OnEnterRoom)
end)

function UnlockTracker:OnLoad(data)
	local playerID = self.inst.Network:GetPlayerID()
	if playerID ~= nil then
		-- Allow loading of legacy data, but it gets saved via other paths (see SaveSystem:LoadCharacterAsPlayerID, PlayerSave:Save)
		-- TODO: networking2022, remove this before Early Access
		if data then
			local msg = string.format("Unlock Tracker has loaded legacy data for %s. Save game to store in new location.", self.inst:GetCustomUserName())
			TheLog.ch.UnlockTracker:print("******************************************************************")
			TheLog.ch.UnlockTracker:print("SaveSystem / OnLoad: " .. msg)
			TheLog.ch.UnlockTracker:print("******************************************************************")
			TheFrontEnd:ShowTextNotification("images/ui_ftf/warning.tex", nil, msg, 12)
			ThePlayerData:SetLoadData(playerID, data)
		end

		-- The above line overrides the data table, so when we add new items that are supposed to unlocked by default they're locked
		-- Hence the line below
		self:GiveDefaultUnlocks()
		for location, weapon_types in pairs(self:GetAllAscensionData()) do
			local highest = -1
			for weapon_type, level in pairs(weapon_types) do
				if level > highest then
					highest = level
				end
			end
			self:_AlignUnlockLevels(location, highest)
		end
	end
end

function UnlockTracker:ResetUnlockTrackerToDefault()
	local playerID = self.inst.Network:GetPlayerID()
	if playerID ~= nil then
		ThePlayerData:ResetUnlocks(playerID)
		ThePlayerData:ResetAscensionLevels(playerID)
		ThePlayerData:ResetCosmetics(playerID)
		ThePlayerData:ResetHeartLevels(playerID)
		self:GiveDefaultUnlocks()
	end
end

-- Also Called directly in the player's load flow in OnSetOwner in player_side
function UnlockTracker:GiveDefaultUnlocks()
	-- loop through items and unlock items tagged as default_unlocked
	for slot, items in pairs(itemcatalog.All.Items) do
		for name, item in pairs(items) do
			if item.tags.default_unlocked then
				self:UnlockRecipe(name)
			end
		end
	end

	self:UnlockEnemy("basic") -- bit of a hack since basic armor is the only one that does not come from an enemy
	self:UnlockRecipe("basic")
	self:UnlockRecipe("armour_unlock_basic")

	self:UnlockRegion("town")

	self:UnlockWeaponType(WEAPON_TYPES.HAMMER)
	self:UnlockDefaultMetaProgress()

	self:UnlockDefaultCosmetics()
end

function UnlockTracker:UnlockDefaultMetaProgress()
	local default_def = MetaProgress.FindProgressByName("default")

	for _, unlock in ipairs(default_def.rewards) do
		unlock:UnlockRewardForPlayer(self.inst)
		-- self:UnlockPower(unlock.def.name)
	end
end

function UnlockTracker:UnlockDefaultCosmetics()
	for group_name, group in pairs(Cosmetics.Items) do
		for cosmetic_name, cosmetic_data in pairs (group) do

			if not cosmetic_data.locked then
				self:UnlockCosmetic(cosmetic_name, group_name)
			end
		end
	end
end

function UnlockTracker:Debug_UnlockAllPowers()
	for slot, powers in pairs(itemcatalog.Power.Items) do
		for id, def in pairs(powers) do
			self:UnlockPower(id)
		end
	end
end

function UnlockTracker:DEBUG_UnlockAllRecipes()
	
	-- Unlocking the armor requires having seen the mobs, so we unlock those too
	local Biomes = require"defs.biomes"
	for id, def in pairs(Biomes.locations) do
        if def.type == Biomes.location_type.DUNGEON then
			for _, mob in ipairs(def.monsters.mobs) do
				if string.match(mob, "trap") == nil then
					self:UnlockEnemy(mob)
				end
        	end

			for _, mob in ipairs(def.monsters.bosses) do
				if string.match(mob, "trap") == nil then
					self:UnlockEnemy(mob)
				end
        	end

			for _, mob in ipairs(def.monsters.minibosses) do
				if string.match(mob, "trap") == nil then
					self:UnlockEnemy(mob)
				end
        	end
        end
    end
	
	local recipes = require "defs.recipes"
	-- d_view(recipes)
	for slot, slot_recipes in pairs(recipes.ForSlot) do
		if next(slot_recipes) then
			for name, _ in pairs(slot_recipes) do
				self:UnlockRecipe(name)
			end
		end
	end
end

function UnlockTracker:OnWeaponTypeUnlocked(weapon_type)
	local locations = TheWorld:GetAllUnlocked(UNLOCKABLE_CATEGORIES.s.LOCATION)
	for _, location in ipairs(locations) do
		self:SetAscensionLevelCompleted(location, weapon_type, -1)
	end
end

function UnlockTracker:SetIsUnlocked(id, category, unlocked)
	assert(category ~= UNLOCKABLE_CATEGORIES.s.ASCENSION_LEVEL, "Ascension levels should use the SetAscensionLevelCompleted flow instead")

	local playerID = self.inst.Network:GetPlayerID()
	if playerID ~= nil then
		ThePlayerData:SetIsUnlocked(playerID, category, id, unlocked);

		if unlocked then
			self.inst:PushEvent("item_unlocked", {id = id, category = category})
		else
			self.inst:PushEvent("item_locked", {id = id, category = category})
		end
	end
end

function UnlockTracker:IsUnlocked(id, category)
	local playerID = self.inst.Network:GetPlayerID()
	if playerID ~= nil then
		return ThePlayerData:IsUnlocked(playerID, category, id);
	end

	return false
end

function UnlockTracker:GetAllUnlocked(category)

	local playerID = self.inst.Network:GetPlayerID()
	if playerID ~= nil then
		local result = ThePlayerData:GetAllUnlocked(playerID, category)
		assert(result)
		return deepcopy(result)
	end
end

------------------------------------------------------------------------------------------------------------
--------------------------------------------- ACCESS FUNCTIONS ---------------------------------------------
------------------------------------------------------------------------------------------------------------

--------------------------------------------- RECIPES ---------------------------------------------

function UnlockTracker:IsRecipeUnlocked(id)
	return self:IsUnlocked(id, UNLOCKABLE_CATEGORIES.s.RECIPE)
end

function UnlockTracker:UnlockRecipe(recipe)
	self:SetIsUnlocked(recipe, UNLOCKABLE_CATEGORIES.s.RECIPE, true)
	self.inst:PushEvent("recipe_unlocked", recipe)
end

function UnlockTracker:LockRecipe(recipe)
	self:SetIsUnlocked(recipe, UNLOCKABLE_CATEGORIES.s.RECIPE, false)
end

function UnlockTracker:IsMonsterArmourSetUnlocked(monster_id)
	local armour = itemutil.GetArmourForMonster(monster_id)
	for slot, def in pairs(armour) do
		if self:IsRecipeUnlocked(def.name) then
			return true
		end
	end
	return false
end

function UnlockTracker:UnlockMonsterArmourSet(monster_id)
	local armour = itemutil.GetArmourForMonster(monster_id)
	for slot, def in pairs(armour) do
		self:UnlockRecipe(def.name)
	end
	return false
end

--------------------------------------------- ENEMIES ---------------------------------------------

function UnlockTracker:IsEnemyUnlocked(id)
	return self:IsUnlocked(id, UNLOCKABLE_CATEGORIES.s.ENEMY)
end

function UnlockTracker:UnlockEnemy(enemy)
	self:SetIsUnlocked(enemy, UNLOCKABLE_CATEGORIES.s.ENEMY, true)
end

function UnlockTracker:LockEnemy(enemy)
	self:SetIsUnlocked(enemy, UNLOCKABLE_CATEGORIES.s.ENEMY, false)
end


--------------------------------------------- CONSUMABLES ---------------------------------------------

function UnlockTracker:IsConsumableUnlocked(id)
	return self:IsUnlocked(id, UNLOCKABLE_CATEGORIES.s.CONSUMABLE)
end

function UnlockTracker:UnlockConsumable(consumable)
	self:SetIsUnlocked(consumable, UNLOCKABLE_CATEGORIES.s.CONSUMABLE, true)
	self.inst:PushEvent("unlock_consumable", consumable)
end

function UnlockTracker:LockConsumable(consumable)
	self:SetIsUnlocked(consumable, UNLOCKABLE_CATEGORIES.s.CONSUMABLE, false)
end

--------------------------------------------- WEAPON CLASS ---------------------------------------------

function UnlockTracker:IsWeaponTypeUnlocked(id)
	return self:IsUnlocked(id, UNLOCKABLE_CATEGORIES.s.WEAPON_TYPE)
end

function UnlockTracker:UnlockWeaponType(weapon_type)
	self:SetIsUnlocked(weapon_type, UNLOCKABLE_CATEGORIES.s.WEAPON_TYPE, true)
	self:OnWeaponTypeUnlocked(weapon_type)
end

function UnlockTracker:LockWeaponType(weapon_type)
	self:SetIsUnlocked(weapon_type, UNLOCKABLE_CATEGORIES.s.WEAPON_TYPE, false)
end

--------------------------------------------- POWERS ---------------------------------------------

function UnlockTracker:IsPowerUnlocked(id)
	return self:IsUnlocked(id, UNLOCKABLE_CATEGORIES.s.POWER)
end

function UnlockTracker:UnlockPower(power)
	self:SetIsUnlocked(power, UNLOCKABLE_CATEGORIES.s.POWER, true)
end

function UnlockTracker:LockPower(power)
	self:SetIsUnlocked(power, UNLOCKABLE_CATEGORIES.s.POWER, false)
end

--------------------------------------------- COSMETICS ---------------------------------------------

function UnlockTracker:GetAllUnlockedCosmetics(category)
	local playerID = self.inst.Network:GetPlayerID()
	if playerID ~= nil then
		local cosmeticstable = ThePlayerData:GetAllUnlockedCosmetics(playerID, category)

		-- Convert to a table of only names: (as that is what the code originally did)
		if cosmeticstable then
			local unlocked_cosmetics = {}
			for name, _ in pairs(cosmeticstable) do
				table.insert(unlocked_cosmetics, name)
			end
			return unlocked_cosmetics
		end
	end
end

function UnlockTracker:IsCosmeticUnlocked(id, category)
	local playerID = self.inst.Network:GetPlayerID()
	if playerID ~= nil then
		return ThePlayerData:IsCosmeticUnlocked(playerID, category, id) or false -- Added or false to stop this from returning nil instead of false
	end
	return false
end

function UnlockTracker:UnlockCosmetic(id, category)
	local playerID = self.inst.Network:GetPlayerID()
	if playerID ~= nil then
		ThePlayerData:SetCosmeticIsUnlocked(playerID, category, id, true)
	end
	self.inst:PushEvent("cosmetic_unlocked", {id = id, category = category})
end

function UnlockTracker:LockCosmetic(id, category)
	local playerID = self.inst.Network:GetPlayerID()
	if playerID ~= nil then
		ThePlayerData:SetCosmeticIsUnlocked(playerID, category, id, false)
	end
	self.inst:PushEvent("cosmetic_locked", {id = id, category = category})
end


--------------------------------------------- FLAG ---------------------------------------------

function UnlockTracker:IsFlagUnlocked(id)
	return self:IsUnlocked(id, UNLOCKABLE_CATEGORIES.s.FLAG)
end

function UnlockTracker:UnlockFlag(flag)
	self:SetIsUnlocked(flag, UNLOCKABLE_CATEGORIES.s.FLAG, true)
end

function UnlockTracker:LockFlag(flag)
	self:SetIsUnlocked(flag, UNLOCKABLE_CATEGORIES.s.FLAG, false)
end

--------------------------------------------- LOCATION ---------------------------------------------

function UnlockTracker:IsLocationUnlocked(location)
	return self:IsUnlocked(location, UNLOCKABLE_CATEGORIES.s.LOCATION)
end

function UnlockTracker:UnlockLocation(location)
	self:SetIsUnlocked(location, UNLOCKABLE_CATEGORIES.s.LOCATION, true)
	TheWorld:UnlockLocation(location)
end

function UnlockTracker:LockLocation(location)
	self:SetIsUnlocked(location, UNLOCKABLE_CATEGORIES.s.LOCATION, false)
end


--------------------------------------------- REGIONS ---------------------------------------------

function UnlockTracker:IsRegionUnlocked(id)
	return self:IsUnlocked(id, UNLOCKABLE_CATEGORIES.s.REGION)
end

function UnlockTracker:UnlockRegion(region)
	self:SetIsUnlocked(region, UNLOCKABLE_CATEGORIES.s.REGION, true)
	TheWorld:UnlockRegion(region)
end

function UnlockTracker:LockRegion(region)
	self:SetIsUnlocked(region, UNLOCKABLE_CATEGORIES.s.REGION, false)
end

--------------------------------------------- ASCENSION LEVEL ---------------------------------------------
function UnlockTracker:_AlignUnlockLevels(location, level)
	-- If the level you just unlocked is BELOW the threshold for super frenzy, we want it to be completed for all weapon types.
	-- Once you being doing super frenzies, we no longer want the levels to be aligned across all weapons.
	local playerID = self.inst.Network:GetPlayerID()
	if playerID ~= nil then
		level = math.min(level, NORMAL_FRENZY_LEVELS)
		for _, weapon_type in pairs(WEAPON_TYPES) do
			ThePlayerData:SetAscensionLevelCompleted(playerID, location, weapon_type, level)
		end
	end
end

function UnlockTracker:SetAscensionLevelCompleted(location, weapon_type, level)
	-- TheLog.ch.UnlockTracker:printf("SetAscensionLevelCompleted: location %s weapon_type %s level %d",
	-- 	location, weapon_type, level)
	local playerID = self.inst.Network:GetPlayerID()
	if playerID ~= nil then
		ThePlayerData:SetAscensionLevelCompleted(playerID, location, weapon_type, level)
	end
	self:_AlignUnlockLevels(location, level)
end

function UnlockTracker:GetCompletedAscensionLevel(location, weapon_type)
	assert(WEAPON_TYPES[weapon_type], "Invalid weapon type: check WEAPON_TYPES in constants.lua")
	-- print ("UnlockTracker:GetCompletedAscensionLevel", UNLOCKABLE_CATEGORIES.s.ASCENSION_LEVEL, location, weapon_type)

	local playerID = self.inst.Network:GetPlayerID()
	if playerID ~= nil then
		return ThePlayerData:GetCompletedAscensionLevel(playerID, location, weapon_type)
	end

	return -1;
end

function UnlockTracker:GetAllAscensionData()
	local playerID = self.inst.Network:GetPlayerID()
	if playerID ~= nil then
		return ThePlayerData:GetAllAscensionData(playerID)
	end
end


--------------------------------------------- HEART LEVEL ---------------------------------------------
function UnlockTracker:SetHeartLevel(region, index, level)
	-- TheLog.ch.UnlockTracker:printf("SetAscensionLevelCompleted: location %s weapon_type %s level %d",
	-- 	location, weapon_type, level)
	local playerID = self.inst.Network:GetPlayerID()
	if playerID ~= nil then
		ThePlayerData:SetHeartLevel(playerID, region, index, level)
	end
end

function UnlockTracker:GetHeartLevel(region, index)
	local playerID = self.inst.Network:GetPlayerID()
	if playerID ~= nil then
		return ThePlayerData:GetHeartLevel(playerID, region, index)
	end

	return 0;
end

function UnlockTracker:GetAllHeartLevelData()
	local playerID = self.inst.Network:GetPlayerID()
	if playerID ~= nil then
		return ThePlayerData:GetAllHeartLevelData(playerID)
	end
end

------------------------------------------------------------------------------------------------------------
-- Goes through the locations and weapons and returns the highest ascension level
-- this player has seen, so it always shows in the UI, even if locked for a particular
-- weapon or location
function UnlockTracker:GetHighestSeenAscension()
	local highest_completed = -1
	for location_id, weapons in pairs(self:GetAllAscensionData()) do
		for weapon_type, ascension_level in pairs(weapons) do
			if ascension_level > highest_completed then
				highest_completed = ascension_level
			end
		end
	end
	return highest_completed + 1
end


function UnlockTracker:DebugDrawEntity(ui, panel, colors)
	local networkui = require "dbui.debug_network"

	local playerID = self.inst.Network:GetPlayerID()
	if playerID ~= nil then
		networkui:RenderNetworkPlayerDataUnlocksForPlayer(ui, playerID)
	end
end


------------------------------------------------------------------------------------------------------------
------------------------------------------------------------------------------------------------------------
------------------------------------------------------------------------------------------------------------

return UnlockTracker


-- NOT YET NEEDED
-- function UnlockTracker:UnlockArmour(armour)
-- 	self:SetIsUnlocked(armour, UNLOCKABLE_CATEGORIES.s.ARMOUR, true)
-- end

-- function UnlockTracker:LockArmour(armour)
-- 	self:SetIsUnlocked(armour, UNLOCKABLE_CATEGORIES.s.ARMOUR, false)
-- end
