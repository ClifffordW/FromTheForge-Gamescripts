local biomes = require "defs.biomes"

local HuntUnlocker = Class(function(self, inst)
	self.inst = inst
	self:SetHuntUnlockOrder(biomes.location_unlock_order)
	self.inst:ListenForEvent("end_current_run", function() self:EvaluateHuntUnlocks() end)
end)

function HuntUnlocker:SetHuntUnlockOrder(unlock_order)
	self.hunt_unlock_order = unlock_order
end

function HuntUnlocker:GetHuntUnlockOrder()
	return self.hunt_unlock_order
end

function HuntUnlocker:OnPostSetOwner()
	-- the owner's data has all been loaded.
	self:EvaluateHuntUnlocks()
end

function HuntUnlocker:UnlockHunt(hunt, default_unlocked)
	self.inst:UnlockRegion(hunt.region_id)
	self.inst:UnlockLocation(hunt.id)

	if default_unlocked then
		-- don't do reveal presentation of locations that are unlocked by default
		self.inst:UnlockFlag(("pf_%s_reveal"):format(hunt.id))
	end
end

function HuntUnlocker:HasCompletedHunt(hunt)
	-- could call a custom function defined inside the hunt data
	-- for now we will just check if you've ever killed the boss
	local location_boss = hunt.monsters.bosses[1]
	return self.inst.components.progresstracker:GetNumKills(location_boss) > 0
end

function HuntUnlocker:EvaluateHuntUnlocks()

	for unlock_order_idx, hunts in ipairs(self.hunt_unlock_order) do
		if unlock_order_idx == 1 then

			for _, hunt in ipairs(hunts) do
				-- always unlock the hunts in the first entry
				self:UnlockHunt(hunt, true)
			end

		else

			local previous_hunts = self.hunt_unlock_order[unlock_order_idx - 1]
			local all_complete = true

			for _, previous_hunt in ipairs(previous_hunts) do
				if not self:HasCompletedHunt(previous_hunt) then
					all_complete = false
				end
			end

			if all_complete then
				-- if you've done all the hunts in the previous list then unlock these hunts.
				for _, hunt in ipairs(hunts) do
					self:UnlockHunt(hunt)
				end
			else
				-- don't keep checking future hunts unless you've done everything up to this point.
				break
			end
		end
	end
end

return HuntUnlocker