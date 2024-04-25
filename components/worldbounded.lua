local ACTIVATION_DURATION <const> = 1 -- second

-- A component to teleport constrain this entity to within the world bounds. It is dormant until activated
-- though, and will go dormant again after manifesting the constraint.
local WorldBounded = Class(function(self, inst)
	self.inst = inst
	self.activation_time_remaining = 0
end)

-- Start the WorldBounded component's Update(). Once it verifies that its entity is in world bounds, possibly having to
-- effect a teleport to make that happen, it will go dormant again.
function WorldBounded:Activate()
	self.activation_time_remaining = ACTIVATION_DURATION
	self.inst:StartUpdatingComponent(self)
end

function WorldBounded:OnUpdate(dt)
	local transform = self.inst.Transform
	local x, y, z = transform:GetWorldPosition()
	local map = TheWorld.Map
	if (map:IsWalkableAtXZ(x, z)) then
		-- Even though we are in walkable area, keep updating for a bit in case more collision resolution moves us.
		self.activation_time_remaining = self.activation_time_remaining - dt
		if self.activation_time_remaining <= 0 then
			self.inst:StopUpdatingComponent(self)
		end
	else
		self.activation_time_remaining = ACTIVATION_DURATION
		local dist_sq
		x, z, dist_sq = map:FindClosestXZOnWalkableBoundaryToXZ(x, z)
		transform:SetWorldPosition(x, y, z)
	end
end

return WorldBounded
