require "class"

-- Component for all bosses so we can setup some of their state.
local Boss = Class(function(self, inst)
	self.inst = inst

	self.activate_fn = function() self:ActivateBoss() end
end)

function Boss:OnPostSpawn()
	-- Push "bossactivated" on damage, to guarantee it displays. Late-joining
	-- players or debug spawns will never get a cine_end event. Don't register
	-- until PostSpawn so initial health config doesn't trigger.
	self.inst:ListenForEvent("healthchanged", self.activate_fn)

	if self.inst.components.cineactor then
		self.inst:ListenForEvent("cine_end", function()
			-- If the cine didn't have a uibosshealthbar, then delay and then
			-- show healthbar.
			self:_DelayedActivate(1)
		end)
	else
		self:_DelayedActivate(2)
	end
end

function Boss:_DelayedActivate(delay)
	self:_CancelTask()
	self.activate_task = self.inst:DoTaskInTime(delay, function(inst_)
		self:ActivateBoss()
	end)
end

function Boss:_CancelTask()
	if self.activate_task then
		self.activate_task:Cancel()
		self.activate_task = nil
	end
end

function Boss:ActivateBoss()
	self:_CancelTask()
	if self.has_activated then
		return
	end

	local music
	if (self.inst:HasTag("miniboss")) then
		--This is jank but to get a list of all minibosses passed in at the same time how the healthbars expect, find them in the world, mainly for remotes and late join
		--In the future bosshealthbar.lua could be updated to accept multiple calls from separate entities to set up each healthbar to remove this
		local x,z = self.inst.Transform:GetWorldXZ()
		local minibosses = FindTargetTagGroupEntitiesInRange(x, z, 100, {"miniboss"})
		for i = 1, #minibosses do
			--If we've already set the healthbars up then dont do it again, causes them to re-animate
			if (minibosses[i].components.boss.has_activated) then	
				return
			end
		end
		TheWorld:PushEvent("minibossactivated", minibosses)
	else
		TheWorld:PushEvent("bossactivated", self.inst)
	end

	self.has_activated = true

end

return Boss
