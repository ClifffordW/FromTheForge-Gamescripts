-- Ascension: Modifiers to increase difficulty

local biomes = require "defs.biomes"
local kassert = require "util.kassert"
local lume = require "util.lume"


-- See also AscensionModifierSource in tuning.lua.
local ascensions = {
	-- Elite enemies spawn
	{
		stringkey = STRINGS.ASCENSIONS.ADD_ELITES,
		icon = "images/map_ftf/frenzy_2.tex",
		func = function(inst)
			-- For creature tuning, see AscensionModifierSource in tuning.lua.
		end,
	},

	-- Enemies are more aggressive
	{
		stringkey = STRINGS.ASCENSIONS.AGGRESSIVE_ENEMIES,
		icon = "images/map_ftf/frenzy_3.tex",
		func = function(inst)
			-- For creature tuning, see AscensionModifierSource in tuning.lua.
		end,
	},

	-- Enemies have more health
	{
		stringkey = STRINGS.ASCENSIONS.ENEMY_HEALTH_BOOST,
		icon = "images/map_ftf/frenzy_4.tex",
		func = function(inst)
			-- For creature tuning, see AscensionModifierSource in tuning.lua.
		end,
	},

	-- More enemies spawn
	{
		stringkey = STRINGS.ASCENSIONS.MORE_ENEMIES,
		icon = "images/map_ftf/frenzy_5.tex",
		func = function(inst)
			-- For creature tuning, see AscensionModifierSource in tuning.lua.
		end,
	},

	-- Bosses have more health
	{
		stringkey = STRINGS.ASCENSIONS.BOSS_HEALTH_BOOST,
		icon = "images/map_ftf/frenzy_6.tex",
		func = function(inst)
			-- For creature tuning, see AscensionModifierSource in tuning.lua.
		end,
	},

	-- More elite enemies spawn
	{
		stringkey = STRINGS.ASCENSIONS.MORE_ELITES,
		icon = "images/map_ftf/frenzy_7.tex",
		func = function(inst)
			-- For creature tuning, see AscensionModifierSource in tuning.lua.
		end,
	},

	-- Elites are more aggressive
	{
		stringkey = STRINGS.ASCENSIONS.AGGRESSIVE_ELITES,
		icon = "images/map_ftf/frenzy_8.tex",
		func = function(inst)
			-- For creature tuning, see AscensionModifierSource in tuning.lua.
		end,
	},

	-- Bosses are more aggressive
	{
		stringkey = STRINGS.ASCENSIONS.AGGRESSIVE_BOSSES,
		icon = "images/map_ftf/frenzy_9.tex",
		func = function(inst)
			-- For creature tuning, see AscensionModifierSource in tuning.lua.
		end,
	},

	--]]
}

local AscensionManager = Class(function(self, inst)
	self.inst = inst -- This is TheDungeon.progression
	self.current = 0
	self.ascension_data = ascensions
	self.num_ascensions = #ascensions
	self.persistdata = {
		last_selected = {},
	}
end)

function AscensionManager:OnSave()
	local data = {}
	data.last_selected = self.persistdata.last_selected
	return data
end

function AscensionManager:OnLoad(data)
	print("------------------- AscensionManager:OnLoad(data)")
	-- If we don't deepcopy, then we'll write directly to TheSaveSystem which
	-- might be unpredictable!
	self.persistdata.last_selected = deepcopy(data.last_selected)

	-- Load the current level.
	self:_SetCurrentLevel(self:_GetDesiredLevel())
end

function AscensionManager:OnPostLoadWorld()
	-- I think this is the earliest callback after loading save data to apply
	-- ascension. If you need ascension already applied, see OnStartRoom
	-- callback or check GetCurrentLevel in your init (it will always be
	-- correct for the host because it's set before world creation).
	self:_ActivateAscension(self:_GetDesiredLevel())
end

function AscensionManager:_GetDesiredLevel()
	local biome_location = TheDungeon:GetDungeonMap():GetBiomeLocation()
	local level = TheNet:IsHost()
		and self:GetSelectedAscension(biome_location.id)
		or TheNet:GetAscensionLevel() -- client
	return level
end

function AscensionManager:Debug_SetAscension(level, location_id)
	location_id = location_id or TheDungeon:GetDungeonMap():GetBiomeLocation().id
	level = self:_ActivateAscension(level)
	self:StoreSelectedAscension(location_id, self.current)
	self.inst:WriteProgression()
	TheSaveSystem:SaveAll() -- Non debug use should use callback!
end

function AscensionManager:_SetCurrentLevel(level)
	level = math.min(level, self.num_ascensions)
	self.current = level
	return level
end

-- Applies the ascension level to the current world. Tuning is applied to
-- creatures when they spawn by querying the active ascension.
--
-- Use Debug_SetAscension for debug!
function AscensionManager:_ActivateAscension(level)
	-- Don't store the level because it might have come from the host.
	level = self:_SetCurrentLevel(level)
	--print("_ActivateAscension:", level)
	for i, asc in ipairs(ascensions) do
		--print(i)
		if i > level then
			break
		end
		--print(asc.stringkey)
		asc.func(TheWorld)
	end
end

-- Allow one higher than the highest completed for that location.
function AscensionManager:GetMaxAllowedLevelForParty(location)
	local best = self:GetHighestCompletedLevelForParty(location.id) or -1
	local allowed = lume.clamp(best + 1, 0, self.num_ascensions)

	-- TEMP cap max frenzy level at the last normal frenzy level
	allowed = math.min(allowed, NORMAL_FRENZY_LEVELS)

	return allowed
end

function AscensionManager:GetCurrentLevel()
	return self.current
end

function AscensionManager:GetSelectedAscension(location_id)
	kassert.typeof("string", location_id)

	printf("------------------- AscensionManager:GetSelectedAscension(%s) [%s]", location_id, self.persistdata.last_selected[location_id])

	return self.persistdata.last_selected[location_id] or 0
end

-- Prefer Debug_SetAscension for debug use!
function AscensionManager:StoreSelectedAscension(location_id, value)
	kassert.typeof("string", location_id)

	printf("------------------- AscensionManager:StoreSelectedAscension(%s, %d)", location_id, value)

	self.persistdata.last_selected[location_id] = value
end

-- The highest ascension that all party members have unlocked.
function AscensionManager:GetHighestCompletedLevelForParty(location_id)
	kassert.typeof("string", location_id)

	local highest_common_unlock = nil
	local limiting_player = nil

	for _, player in ipairs(AllPlayers) do
		local level = player.components.unlocktracker:GetCompletedAscensionLevel(location_id, player.components.inventory:GetEquippedWeaponType()) or -1
		if not highest_common_unlock or level < highest_common_unlock then
			highest_common_unlock = level
			limiting_player = player
		end
	end

	return highest_common_unlock, limiting_player
end

function AscensionManager:GetPartyAscensionData(location_id)
	kassert.typeof("string", location_id)

	local data = {}

	for _, player in ipairs(AllPlayers) do
		local playerID = player.Network:GetPlayerID()
		local weapon_type = player.components.inventory:GetEquippedWeaponType()
		local level = player.components.unlocktracker:GetCompletedAscensionLevel(location_id, weapon_type) or -1
		data[playerID] = { player = player, weapon_type = weapon_type, level = level }
	end

	return data
end

function AscensionManager:SetHighestCompletedAscension(player, location_id, weapon_type, num)
	player.components.unlocktracker:SetAscensionLevelCompleted(location_id, weapon_type, num)
end


function AscensionManager:CompleteCurrentAscension()
	local location_id = TheDungeon:GetDungeonMap().data.location_id

	for _, player in ipairs(AllPlayers) do
		local weapon_type = player.components.inventory:GetEquippedWeaponType()
		local level = player.components.unlocktracker:GetCompletedAscensionLevel(location_id, weapon_type)

		if self.current > level then
			-- players should only ever unlock 1 level at a time, even if the ascension they just completed is higher than that
			self:SetHighestCompletedAscension(player, location_id, weapon_type, level + 1)
		end
	end
end

function AscensionManager:DEBUG_UnlockAscension(location_id, num)
	num = num or #ascensions

	for _, player in ipairs(AllPlayers) do
		for _, weapon_type in pairs(WEAPON_TYPES) do
			if player.components.unlocktracker:IsWeaponTypeUnlocked(weapon_type) then
				self:SetHighestCompletedAscension(player, location_id, weapon_type, num)
			end
		end
	end

	self.persistdata.last_selected[location_id] = num
end

local dbg_location_id
function AscensionManager:DebugDrawEntity(ui, panel, colors)
	local location
	dbg_location_id, location = biomes._BiomeLocationPicker(ui, dbg_location_id)

	local highest, player = self:GetHighestCompletedLevelForParty(dbg_location_id)
	ui:Value("GetCurrentLevel", self:GetCurrentLevel())
	ui:Value("GetHighestCompletedLevelForParty limiting player", player)
	ui:Value("GetHighestCompletedLevelForParty", highest)
	ui:Value("GetMaxAllowedLevelForParty", self:GetMaxAllowedLevelForParty(location))
	ui:Value("GetSelectedAscension", self:GetSelectedAscension(dbg_location_id))
	panel:AppendTable(ui, self:GetPartyAscensionData(dbg_location_id), "GetPartyAscensionData")
	--~ self:GetLootEligibility(GetDebugPlayer(), dbg_location_id, weapon_type, level)
end

function AscensionManager:GetLootEligibility(player, location_id, weapon_type, level)
	local highest = player.components.unlocktracker:GetCompletedAscensionLevel(location_id, weapon_type)
	if not highest then return true end -- this player has never done ascension with this weapon/ location combo so they must be eligible
	return highest < level
end

-- TODO @H: Handle this by player
function AscensionManager:IsEligibleForHeart(player)
	local location_id = TheDungeon:GetDungeonMap().data.location_id
	local weapon_type = player.components.inventory:GetEquippedWeaponType()
	return self:GetLootEligibility(player, location_id, weapon_type, self:GetCurrentLevel())
end

return AscensionManager

--[[
Ideas:
Increase Difficulty 3 room spawn rate
Increase small enemy damage, Decrease enemy cooldown time
Increase big enemy damage, Decrease big enemy cooldown time
Increase boss damage, Decrease boss cooldown time
Potion heals for 75%
Start with 90% health
Increase normal enemy health by 2x
Increase big enemy health by 2x (Yammo)
Increase boss health by 2x
10% less max HP
Everything costs more.
Double boss.
Traps do extra damage to players
WaitForDefeatedCount and WaitForDefeatedPercentage modifier

--]]
