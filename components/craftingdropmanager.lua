local mapgen = require "defs.mapgen"
local krandom = require "util.krandom"
local lume = require "util.lume"
-- local prefabutil = require "prefabs.prefabutil"
require "util.tableutil"

local CraftingDropManager = Class(function(self, inst)
	self.inst = inst
	local seed = TheDungeon:GetDungeonMap():GetRNG():Integer(2^32 - 1)
	TheLog.ch.Random:printf("CraftingDropManager Random Seed: %d", seed)
	self.rng = krandom.CreateGenerator(seed)

	self._on_room_complete_fn = function(_, _data) self:OnRoomComplete() end
	if not TheWorld:HasTag("town")
		and not TheWorld:HasTag("debug")
	then
		self.inst:ListenForEvent("room_complete", self._on_room_complete_fn)
	end
end)

local function ShouldSpawnLootInThisRoom()
	local worldmap = TheDungeon:GetDungeonMap()
	return not worldmap:IsCurrentRoomDungeonEntrance()
		and not worldmap:HasEnemyForCurrentRoom('boss')
		and worldmap:DoesCurrentRoomHaveCombat()
end

local function PickPowerDropSpawnPosition()
	local angle = math.rad(math.random(360))
	local dist_mod = math.random(3, 6)
	local target_offset = Vector2.unit_x:rotate(angle) * dist_mod
	return Vector3(target_offset.x, 0, target_offset.y)
end

local ENUM_TO_DROP =
{
	[mapgen.Reward.s.small_token] = "soul_drop_lesser",
	[mapgen.Reward.s.big_token] = "soul_drop_greater",
}

function CraftingDropManager:OnRoomComplete()
	if not TheNet:IsHost() then
		return
	end

	if not ShouldSpawnLootInThisRoom() then
		return
	end

	self.inst:RemoveEventCallback("room_complete", self._on_room_complete_fn)

	local reward = TheDungeon:GetDungeonMap():GetRewardForCurrentRoom()
	local drop = ENUM_TO_DROP[reward]
	if not drop then
		return
	end

	local spawners = TheWorld.components.powerdropmanager.spawners
	-- TODO @chrisp #loot - sort then shuffle? wut? I think this has just been left here in order to clone TheWorld.components.powerdropmanager.spawners
	table.sort(spawners, EntityScript.OrderByXZDistanceFromOrigin)
	self.rng:Shuffle(spawners)
	self:SpawnCraftingDrop(spawners[1], drop)
end

function CraftingDropManager:SpawnCraftingDrop(spawner, drop)
	local target_pos
	if spawner then
		target_pos = spawner:GetPosition()
	else
		-- Fallback to random position near the centre of the world if we
		-- didn't have enough spawners.
		TheLog.ch.Power:print("No room_loot for this power drop. Use self.spawners to place them to avoid appearing inside of something.")
		target_pos = PickPowerDropSpawnPosition()
	end

	local drop = SpawnPrefab(drop, self.inst)
	drop.Transform:SetPosition(target_pos:Get())
	drop.components.souldrop:PrepareToShowGem({
			appear_delay_ticks = TUNING.POWERS.DROP_SPAWN_INITIAL_DELAY_FRAMES,
		})
	return drop
end

local get_num_corestones = function(rng)
	dbassert(TheNet:IsHost(), "trying to find soul count when you're not the host")
	local difficulty = TheDungeon:GetCurrentDifficulty()
	local bag_name = "corestone_reward_"..difficulty
	local local_players = TheNet:GetLocalPlayerList()

	--pick from host player grabbag		
	if #local_players > 0 then
		local player = GetPlayerEntityFromPlayerID(local_players[1])
		if player then
			return player.components.grabbag:PickFromBag( bag_name, TUNING.CORESTONE_REWARD_MODIFIER[difficulty], rng )
		end
	end

	return rng:PickValue(TUNING.CORESTONE_REWARD_MODIFIER[difficulty])
end

-- Given that lesser souls have been chosen as the room reward, return the number that should be bundled into a
-- single pickup.
function CraftingDropManager:GetSoulDropCount(soul_type)
	if soul_type == "konjur_soul_lesser" then
		return get_num_corestones(self.rng)
	elseif soul_type == "konjur_soul_greater" then
		return 1
	elseif soul_type == "konjur_heart" then
		return 1
	else
		dbassert(false, "Unrecognized soul_type: "..soul_type)
	end
end

return CraftingDropManager
