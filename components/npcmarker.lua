local TYPE_TO_STRING =
{
	[QUEST_IMPORTANCE.s.HIGH] = "main",
	[QUEST_IMPORTANCE.s.DEFAULT] = "secondary",
	["BUSY"] = "busy",
}

local NPCMarker = Class(function(self, inst)
	self.inst = inst
	self.fx = nil
	self.importance = QUEST_IMPORTANCE.s.HIGH
	self.players = {}
end)

function NPCMarker:GetPlayers()
	return self.players
end

function NPCMarker:GetAnimString()
	return TYPE_TO_STRING[self.importance]
end

function NPCMarker:GetFX()
	return self.fx
end

function NPCMarker:SpawnMarkerFX()
	self.fx = SpawnPrefab("fx_quest_marker", self.inst)
	assert(self.fx)
	self.fx.AnimState:PlayAnimation("pre_"..self:GetAnimString())
	self.fx.AnimState:PushAnimation("loop_"..self:GetAnimString(), true)
	self.fx.entity:SetParent(self.inst.entity)
end

function NPCMarker:HideFX()
	self.hidden = true
	self.fx.AnimState:PlayAnimation("pst_"..self:GetAnimString())
end

function NPCMarker:ShowFX()
	self.hidden = false
	self.fx.AnimState:PlayAnimation("pre_"..self:GetAnimString())
	self.fx.AnimState:PushAnimation("loop_"..self:GetAnimString(), true)
end

function NPCMarker:DespawnMarkerFX(cb)
	if self.hidden then
		self.inst:Remove()
		if cb then
			cb()
		end
	else
		if self.fx then
			self.inst.despawning = true
			self.fx.AnimState:PlayAnimation("pst_"..self:GetAnimString())
			self.inst:ListenForEvent("animover", function()
				if cb then cb() end
				self.inst:Remove()
			end, self.fx)
		end
	end
end

function NPCMarker:SetBusy()
	self.importance = "BUSY"
	return self
end

function NPCMarker:IsPlayerTracked(player)
	return self.players[player] ~= nil
end

function NPCMarker:GetNumTrackedPlayers()
	return table.count(self.players)
end

function NPCMarker:AddTrackedPlayer(player)
	self.players[player] = true
	self:Refresh()
end

function NPCMarker:RemoveTrackedPlayer(player)
	self.players[player] = nil
	self:Refresh()
end

function NPCMarker:Refresh()
	if self.fx and not self.inst.despawning then
		self.fx.AnimState:PushAnimation("loop_"..self:GetAnimString(), true)
	end

	if not self.fx then
		self:SpawnMarkerFX()
	end
end

function NPCMarker:FollowNPC(npc_inst)
    self.inst.Follower:FollowSymbol(npc_inst.GUID, "head_follow")
    self.inst.Follower:SetOffset(0, -300, 0)

	self.follow_npc = npc_inst
    self.activate_fn = function() self:HideFX() end
    self.deactivate_fn = function() self:ShowFX() end

    self.inst:ListenForEvent("activate_convo_prompt", self.activate_fn, self.follow_npc)
    self.inst:ListenForEvent("deactivate_convo_prompt", self.deactivate_fn, self.follow_npc)
end

return NPCMarker