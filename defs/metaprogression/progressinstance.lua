local MetaProgress = require "defs.metaprogression.metaprogress"

MetaProgress.ProgressInstance = Class(function(self, progress)
	self.persistdata = progress -- holds information like exp gained towards reward
	self.def = progress:GetDef() -- the def of what the rewards are
	self.mem = {} -- temp memory... do we need this for rewards?

	self.pending_level = self.persistdata.exp >= MetaProgress.GetEXPForLevel(self.def, self.persistdata.level)
		and MetaProgress.GetRewardForLevel(self.def, self.persistdata.level + 1) ~= nil
end)

function MetaProgress.ProgressInstance:GetLocalizedName()
	return self.persistdata:GetLocalizedName()
end

function MetaProgress.ProgressInstance:GetEXP()
	return self.persistdata.exp
end

function MetaProgress.ProgressInstance:GetLevel()
	return self.persistdata.level
end

function MetaProgress.ProgressInstance:GetMaxLevel()
	return #self.def.rewards
end

function MetaProgress.ProgressInstance:IncreaseLevel()
	local old = self:GetLevel()
	local new = old + 1

	if self:IsMaxLevel() then
		new = old -- don't go above max level
	end

	self.persistdata.level = new
	self.persistdata.exp = 0
	self.pending_level = false
end

function MetaProgress.ProgressInstance:_DEBUG_RESET_PROGRESS()
	self.persistdata.level = 0
	self.persistdata.exp = 0
end

function MetaProgress.ProgressInstance:DeltaExperience(delta)
	local until_level = self:GetEXPUntilNextLevel()

	local actual_delta = math.min(delta, until_level)

	self.persistdata.exp = self.persistdata.exp + actual_delta
	local remaining = delta - actual_delta
	local used = delta - remaining

	return used, remaining
end

function MetaProgress.ProgressInstance:GetEXPForLevel(level)
	return MetaProgress.GetEXPForLevel(self.def, level)
end

function MetaProgress.ProgressInstance:GetRewardForLevel(level)
	return MetaProgress.GetRewardForLevel(self.def, level)
end

function MetaProgress.ProgressInstance:GetNextReward()
	local level = self:GetLevel()
	local next_reward = self:GetRewardForLevel(level + 1)
	return next_reward
end

function MetaProgress.ProgressInstance:GetPendingRewardDef()
	if not self.pending_level then
		assert("Trying to get a pending MetaProgress reward def when we aren't actually pending one.")
	end

	local level = self:GetLevel() + 1 -- We haven't actually leveled until we've collected the reward.
	local reward = MetaProgress.GetRewardForLevel(self.def, level)

	return reward
end

function MetaProgress.ProgressInstance:GetEXPUntilNextLevel()
	local level = self:GetLevel()
	local needed = self:GetEXPForLevel(level)
	return needed - self:GetEXP()
end

function MetaProgress.ProgressInstance:IsPendingLevel()
	return self.pending_level
end

function MetaProgress.ProgressInstance:IsMaxLevel()
	return self:GetLevel() == self:GetMaxLevel()
end

function MetaProgress.ProgressInstance:OnPendingLevelClaimed()
	self:IncreaseLevel()
end

function MetaProgress.ProgressInstance:GrantExperienceIfPossible(exp)
	local level_up_log = {}

	local start_level = self:GetLevel()
	local start_exp = self:GetEXP()

	local was_pending_level = self.pending_level

	if not was_pending_level then
		self:DeltaExperience(exp)
	end

	local end_exp = self:GetEXP()
	local did_level = not was_pending_level and self:GetEXPUntilNextLevel() <= 0 -- they did not just level if they were already pending a level

	table.insert(level_up_log, {
		start_level = start_level,
		was_pending_level = was_pending_level,
		did_level = did_level,
		start_exp = start_exp,
		end_exp = end_exp,
		is_max_level = self:IsMaxLevel()
	})

	if did_level then
		self.pending_level = true -- Set this true for the future
	end

	return level_up_log
end

function MetaProgress.ProgressInstance:PreviewExperienceGain(exp)
	local start_level = self:GetLevel()
	local start_exp = self:GetEXP()
	local remaining_exp = self:GetEXPUntilNextLevel()

	if exp >= remaining_exp then
		exp = exp - remaining_exp
		local level = start_level + 1

		while exp >= self:GetEXPForLevel(level) do
			exp = exp - self:GetEXPForLevel(level)
			level = level + 1
		end

		return level, exp
	else
		return start_level, start_exp + exp
	end
end
