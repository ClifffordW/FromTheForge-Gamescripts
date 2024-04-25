-- lives on the world, and manages npc marks
-- this component collects all of the requested marks for players in the session
-- and then creates and manages the marks that appear above NPCs.

local NPCMarkManager = Class(function(self, inst)
	self.inst = inst

	self.markable_npcs = {}
	self.marked_npcs = {}
	self.tracked_players = {}

	self.inst:ListenForEvent("playerdeactivated", function(_, player) self:OnPlayerDeactivated(player) end)
	self.inst:ListenForEvent("refresh_markers", function(_, data) self:OnRefreshMarkers(data) end)
	self.inst:ListenForEvent("on_player_set", function(_, player) self:RefreshAllNPCMarkersForPlayer(player) end, TheDungeon)
end)

function NPCMarkManager:OnRefreshMarkers(data)
	if data.npc and data.player then
		self:RefreshNPCMarkersForPlayer(data.npc, data.player)
		return
	end

	if data.npc and not data.player then
		self:RefreshNPCMarkersForAllPlayers(data.npc)
		return
	end

	if not data.npc and data.player then
		self:RefreshAllNPCMarkersForPlayer(data.player)
		return
	end

	self:RefreshAllNPCMarkersForAllPlayers()
end

function NPCMarkManager:AddMarkableNPC(npc)
	self.markable_npcs[npc] = npc
	self:RefreshNPCMarkersForAllPlayers(npc)
end

function NPCMarkManager:RemoveMarkableNPC(npc)
	self.markable_npcs[npc] = nil
end

function NPCMarkManager:_SpawnMarkerForNPC(npc, player)
	local marker = self.marked_npcs[npc]

	if not self.marked_npcs[npc] then
		marker = SpawnPrefab("npcmarker", npc)
	    marker.entity:SetParent(npc.entity)
	    self.marked_npcs[npc] = marker
	end

	marker.components.npcmarker:FollowNPC(npc)
	marker.components.npcmarker:AddTrackedPlayer(player)
end

function NPCMarkManager:_RemoveMarkerForNPC(npc, player)
	local marker = self.marked_npcs[npc]
	marker.components.npcmarker:RemoveTrackedPlayer(player)

	if marker.components.npcmarker:GetNumTrackedPlayers() <= 0 then
		marker.components.npcmarker:DespawnMarkerFX(function() self.marked_npcs[npc] = nil end)
	end
end

function NPCMarkManager:RefreshNPCMarkersForPlayer(npc, player)
	-- refreshes the markers for ONE npc for ONE player
	local should_mark = npc.components.markablenpc:EvaluateMarksForPlayer(player)

	if should_mark then
		self:_SpawnMarkerForNPC(npc, player)
	elseif not should_mark and self.marked_npcs[npc] then
		if self.marked_npcs[npc].components.npcmarker:IsPlayerTracked(player) then
			self:_RemoveMarkerForNPC(npc, player)
		end
	end
end

function NPCMarkManager:RefreshAllNPCMarkersForPlayer(player)
	-- refreshes the markers for ALL markable npcs for ONE player
	for _, npc in pairs(self.markable_npcs) do
		self:RefreshNPCMarkersForPlayer(npc, player)
	end
end

function NPCMarkManager:RefreshNPCMarkersForAllPlayers(npc)
	-- refreshes the markers for ONE markable npc for ALL players

	-- only needs to update for local players, markers are not network synced.
    for _, playerID in ipairs(TheNet:GetLocalPlayerList()) do
        local player = GetPlayerEntityFromPlayerID(playerID)
        if player then
        	self:RefreshNPCMarkersForPlayer(npc, player)
        end
    end
end

function NPCMarkManager:RefreshAllNPCMarkersForAllPlayers()
	-- only needs to update for local players, markers are not network synced.
    for _, playerID in ipairs(TheNet:GetLocalPlayerList()) do
        local player = GetPlayerEntityFromPlayerID(playerID)
        if player then
        	self:RefreshAllNPCMarkersForPlayer(player)
        end
    end
end

function NPCMarkManager:IsNPCMarked(ent)
	for npc, marker in pairs(self.marked_npcs) do
		if npc == ent then
			return marker
		end
	end
end

function NPCMarkManager:OnPlayerDeactivated(player)
	for npc, marker in pairs(self.marked_npcs) do
		-- if the player no longer wants this npc to be marked, remove them.
		if marker.components.npcmarker:IsPlayerTracked(player) then
			self:_RemoveMarkerForNPC(npc, player)
		end
	end
end

return NPCMarkManager