local NpcHome = Class(function(self, inst)
	self.inst = inst

	self.autospawn_npc_prefab = nil
	self.npc = nil

	self.spawn_offset = { x = 0, z = 0 }

	self._ononremove = function(npc) self:OnRemoveNPC(npc) end
end)

function NpcHome:OnPostLoadWorld()
	if not TheDungeon:GetDungeonMap():IsDebugMap() then
		self:_AutoSpawnNPC()
	end
end

function NpcHome:_AutoSpawnNPC()
	if self.autospawn_npc_prefab and self:GetNPC() == nil then
		local npc = SpawnPrefab(self.autospawn_npc_prefab)
		self:SetAsHomeForNPC(npc)

		-- you almost always approach from the left, npcs should look left.
		npc:FlipFacingAndRotation() 
	end
end

function NpcHome:SetAsHomeForNPC(npc)
	dbassert(self.npc == nil)
	self.npc = npc
	self.npc.components.npc:SetHome(self.inst)
	self.inst:ListenForEvent("onremove", self._ononremove, self.npc)
	self:_ApplyOffsetToNpc()
end

function NpcHome:_ApplyOffsetToNpc()
	local x, z = self:GetSpawnXZ(self.npc)
	self.npc.Transform:SetPosition(x, 0, z)
end

function NpcHome:OnRemoveNPC(npc)
	dbassert(self.npc == npc)
	self.inst:RemoveEventCallback("onremove", self._ononremove, self.npc)
	self.npc = nil
end

function NpcHome:GetNPC()
	return self.npc
end

function NpcHome:OnRemoveEntity()
	if self.npc and self.npc:IsValid() then
		self.npc:Remove()
		self.npc = nil
	end
end

function NpcHome:SetAutoSpawnNPCPrefab(prefab)
	self.autospawn_npc_prefab = prefab
end

function NpcHome:SetSpawnXZOffset(x, z)
	self.spawn_offset = { x = x, z = z }
end

function NpcHome:GetSpawnXZ(npc)
	if self.spawn_pos_fn then
		return self.spawn_pos_fn(self.inst, npc)
	else
		local x, z = self.inst.Transform:GetWorldXZ()
		return x + self.spawn_offset.x, z + self.spawn_offset.z
	end
end

function NpcHome:SetSpawnPosFn(fn)
	self.spawn_pos_fn = fn
end

function NpcHome:DebugDrawEntity(ui, panel, colors)
	local offset = self.spawn_offset or table.empty
	local pos = Vector2(offset.x or 0, offset.z or 0)
	if ui:DragVec2f("Spawn Offset", pos, 0.01, -10, 10) then
		self:SetSpawnXZOffset(pos:unpack())
		local npc = self:GetNPC()
		if npc then
			self:_ApplyOffsetToNpc()
		end
	end
end

return NpcHome
