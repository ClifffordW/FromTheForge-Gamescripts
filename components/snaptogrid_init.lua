local SnapToGrid_Init = Class(function(self, inst)
	self.inst = inst
	self.inst:DoTaskInTime(0, function() 
		local x, z = self.inst.Transform:GetWorldXZ()
		self.inst.components.snaptogrid:SetNearestGridPos(x, 0, z)
	end)
end)

return SnapToGrid_Init
