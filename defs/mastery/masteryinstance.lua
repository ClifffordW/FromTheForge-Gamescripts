local Mastery = require"defs.mastery.mastery"

-- Created by MasteryManager and passed as 'mst' within masteries.
Mastery.MasteryInstance = Class(function(self, mastery)
	self.def = mastery:GetDef()

	self.persistdata = mastery -- an ItemInstance
	self.persistdata.max_progress = self.def.max_progress
	self.persistdata.claimed = self.persistdata.claimed == nil and false or self.persistdata.claimed

	self.mem = {}
end)

function Mastery.MasteryInstance:SetManager(manager)
	self.manager = manager
end

function Mastery.MasteryInstance:GetManager()
	return self.manager
end

function Mastery.MasteryInstance:GetDef()
	return self.def
end

function Mastery.MasteryInstance:GetTuning()
	return self.persistdata:GetTuning()
end

function Mastery.MasteryInstance:GetVar(var)
	return self.persistdata:GetVar(var)
end

function Mastery.MasteryInstance:IsNew()
	return self:GetProgressPercent() == 0
end

function Mastery.MasteryInstance:IsClaimed()
	return self.persistdata.claimed
end

function Mastery.MasteryInstance:IsComplete()
	return self:GetProgressPercent() >= 1
end

function Mastery.MasteryInstance:GetProgress()
	return self.persistdata.progress or 0
end

function Mastery.MasteryInstance:GetMaxProgress()
	return self.persistdata.max_progress
end

function Mastery.MasteryInstance:GetProgressPercent()
	return self:GetProgress() / self:GetMaxProgress()
end

function Mastery.MasteryInstance:GetVar(var)
	return self.persistdata:GetVar(var)
end

function Mastery.MasteryInstance:ClaimRewards()
	self.persistdata.claimed = true
	self:GetManager():CreateNextMastery(self)

	self:GetManager():EvaluatePaths()

	TheWorld:PushEvent("refresh_markers", {player = self:GetManager().inst})

	return self.def.rewards
end

function Mastery.MasteryInstance:DeltaProgress(delta)
	if self.complete then
		return
	end

	local prev_progress = self:GetProgress()

	self.persistdata.progress = math.min(self:GetProgress() + delta, self:GetMaxProgress()) -- Cap progress at the maximum amount

	local manager = self:GetManager()
	if self:GetProgressPercent() >= 1 then
		manager:OnCompleteMastery(self)
	else
		manager:OnProgressUpdated(self)
	end

	local new_progress = self:GetProgress()

	local data = {
		mastery_instance = self,
		prev_progress = prev_progress,
		new_progress = new_progress,
	}

	self.manager.inst:PushEvent("mastery_progressed", data)
end