-- When on a dungeon run, the system decides which NPCs will spawn mid-run based on currently active quests.
	-- On each room exit, evaluate player quests and pick a best NPC to spawn.
	-- If the next room has the valid conditions to spawn that NPC, it will spawn.

local mapgen = require "defs.mapgen"


local MeetingManager = Class(function(self, inst)
	self.inst = inst

	self.dungeon_spawn_requests = {}

	local _on_roomunlocked = function() self:EvaluateSpawnNPC_Dungeon(TheDungeon:GetDungeonMap():GetBiomeLocation()) end
    self.inst:ListenForEvent("room_unlocked", _on_roomunlocked, TheWorld)

	self._on_spawner_remove = function(source) self.spawner = nil end
end)

function MeetingManager:OnStartRoom()
	if self.spawner then
		-- At this point, we've loaded the spawn requests saved from
		-- start_new_run. Players (and their quest managers) haven't spawned,
		-- but that should be okay.
		self:_TrySpawnNPC_Dungeon(self.spawner)
	end
end

function MeetingManager:RequestDungeonNPC(prefab, priority, locations)
    --~ TheLog.ch.Quest:printf("MeetingManager:RequestDungeonNPC: %s p=%s locations=%s", prefab, priority, table.inspect(locations))
	for _, location in ipairs(locations) do
		local tbl = self.dungeon_spawn_requests[location] or {}
		tbl[prefab] = (tbl[prefab] or 0) + priority
		self.dungeon_spawn_requests[location] = tbl
	end
end

function MeetingManager:EvaluateForNewRun(biome_location)
	dbassert(biome_location, "We won't know if someone was supposed to spawn in this dungeon.")
	TheDungeon.progression.components.runmanager:SetHasMetTownNPCInDungeon(false)
	self:EvaluateSpawnNPC_Dungeon(biome_location)
end

function MeetingManager:EvaluateSpawnNPC_Dungeon(biome_location)
	-- loop through all local players and evaluate their quests.
	-- we do this on every room exit just in case quest state has changed and there is a new best option.
	self.dungeon_spawn_requests = {}
	-- pushing this event populates the spawn_requests table
	TheDungeon:PushEvent("evaluate_npc_spawns_dungeon", biome_location)
end

function MeetingManager:WantsQuestRoom()
	local quest_requests = self.dungeon_spawn_requests[mapgen.roomtypes.RoomType.s.quest]
	local has_request = quest_requests and next(quest_requests) ~= nil
	return has_request
end

function MeetingManager:RegisterSpawner(spawner)
	assert(not self.spawner, "We don't handle multiple npc spawners.")
	self.spawner = spawner
	self.inst:ListenForEvent("onremove", self._on_spawner_remove, self.spawner)
end

function MeetingManager:_TrySpawnNPC_Dungeon(spawner)
	local room_type = TheWorld:GetCurrentRoomType()

	local ent
	if self.dungeon_spawn_requests[room_type] then
		local best, highest = nil, nil

		for prefab, priority in pairs(self.dungeon_spawn_requests[room_type]) do
			if not best then best = prefab end
			if not highest or priority > highest then
				highest = priority
				best = prefab
			end
		end

		local npc_node = TheDungeon.progression.components.castmanager:GetNpcNodeFromPrefabName(best)
		if npc_node and npc_node.inst then
			-- Already exists in world. Possibly placed in level or from savedata.
			return
		end

		ent = SpawnPrefab(best)
		local x, z = spawner.Transform:GetWorldXZ()
		ent.Transform:SetPosition(x, 0, z)
		ent:FaceXZ(0, 0)
	end

    TheLog.ch.Quest:printf("MeetingManager:_TrySpawnNPC_Dungeon: [%s] in %s", ent, room_type)
end

function MeetingManager:OnSave()
	return {
		dungeon = deepcopy(self.dungeon_spawn_requests)
	}
end

function MeetingManager:OnLoad(data)
	if data ~= nil then
		self.dungeon_spawn_requests = deepcopy(data.dungeon)
	end
end

return MeetingManager
