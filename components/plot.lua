local fmodtable = require "defs.sound.fmodtable"
local audioid = require "defs.sound.audioid"
local ParticleSystemHelper = require "util.particlesystemhelper"

local Plot = Class(function(self, inst)
	self.inst = inst
	self.building = nil
	self.spawn_flag = nil
	self.npc_prefab = nil
	self.building_prefab_locked = nil
	self.building_prefab_unlocked = nil
	self.range = 0

	self.inst:Hide()
end)

function Plot:OnStopPlacing()
	if self.mark_fx then
		self.mark_fx:Remove()
		self.mark_fx = nil
	end
end

function Plot:IsOccupied()
	return self.building ~= nil
end

function Plot:SetBuildingPrefab(prefab)
	self.building_prefab_locked = ("%s_locked"):format(prefab)
	self.building_prefab_unlocked = ("%s_unlocked"):format(prefab)
end

function Plot:SetSpawnFlag(flag)
	if flag and string.len(flag) > 0 then
		self.spawn_flag = flag
	end
end

function Plot:SetNPCPrefab(prefab)
	self.npc_prefab = prefab
end

function Plot:OnPostLoadWorld()
	if TheDungeon:GetDungeonMap():IsDebugMap() then 
		self.inst:Show()
		return 
	end

	if not self.spawn_flag or not TheNet:IsHost() then return false end

	if TheWorld:IsFlagUnlocked(self.spawn_flag) then
		-- spawn unlocked building
		self:SpawnUnlockedBuilding()
	else
		-- spawn locked building
		self:SpawnLockedBuilding()
	end
end

function Plot:SpawnLockedBuilding()
	self:_SpawnBuilding(self.building_prefab_locked)
end

function Plot:SpawnUnlockedBuilding()
	self:_SpawnBuilding(self.building_prefab_unlocked)
	self.building.components.npchome:OnPostLoadWorld() -- spawns and positions NPC
end

function Plot:_SpawnBuilding(building_prefab)
	local building = SpawnPrefab(building_prefab)

	if not building then
		assert(false, string.format("[%s] tried to spawn building [%s] but failed", self.inst, building_prefab))
	end

	local x, z = self.inst.Transform:GetWorldXZ()
	building.components.snaptogrid:MoveToNearestGridPos(x, 0, z, true)

	self:SetBuilding(building)
end

function Plot:SetBuilding(building)
	self.building = building
	self.inst:Hide()
end

return Plot