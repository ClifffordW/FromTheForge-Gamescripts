local MarkableNPC = Class(function(self, inst)
	self.inst = inst
	self.mark_conditions = {}
end)

function MarkableNPC:OnPostSpawn()
	TheWorld.components.npcmarkmanager:AddMarkableNPC(self.inst)
end

function MarkableNPC:OnRemoveEntity()
	self:OnRemoveFromEntity()
end

function MarkableNPC:OnRemoveFromEntity()
	TheWorld.components.npcmarkmanager:RemoveMarkableNPC(self.inst)
end

function MarkableNPC:AddMarkCondition(key, fn)
	self.mark_conditions[key] = fn
end

function MarkableNPC:RemoveMarkCondition(key)
	self.mark_conditions[key] = nil
end

function MarkableNPC:EvaluateMarksForPlayer(player)
	for key, fn in pairs(self.mark_conditions) do
		if fn(player) then
			return true
		end
	end
	return false
end

return MarkableNPC