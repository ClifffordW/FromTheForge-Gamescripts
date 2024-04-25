local Widget = require "widgets/widget"
local FollowPrompt = require "widgets.ftf.followprompt"
local DungeonLevelWidget = require "widgets.ftf.dungeonlevelwidget"

local MetaProgressStoreWidget = Class(FollowPrompt, function(self, player, xp_grant)
	FollowPrompt._ctor(self, player)

	-- How much xp is granted per transaction.
	self.xp_grant = xp_grant

	self:SetOffsetFromTarget(Vector3(0, 6, 0))
		:SetClickable(false)

	self.container = self:AddChild(Widget())

	self.dungeon_level = self.container:AddChild(DungeonLevelWidget(player))
end)

function MetaProgressStoreWidget:SetPriceText(price_text)
	-- Does nothing, but metaprogresstore.lua assumes this function is here
end

function MetaProgressStoreWidget:SetProgress(progress)
	local xp = progress:GetEXP()
	local xp_target = progress:GetEXPForLevel(progress:GetLevel())

	local meta_progress = {
		meta_reward = progress,
		meta_reward_def = progress.def,
		meta_level = progress:GetLevel(),
		meta_exp = xp,
		meta_exp_max = xp_target,
	}

	self.dungeon_level:RefreshMetaProgress(meta_progress)

	self.dungeon_level:SetProgressGhost(xp, self.xp_grant, xp_target)
end

function MetaProgressStoreWidget:RefreshMetaProgress(meta_progress)
	self.dungeon_level:RefreshMetaProgress(meta_progress)
end

function MetaProgressStoreWidget:OnExpGranted(exp_events, on_progress_fn)
	local updater = self.dungeon_level:ShowMetaProgression(on_progress_fn, exp_events)
	return self:RunUpdater(Updater.Series {
		Updater.While(function()
			return not updater:IsDone()
		end),
		Updater.Do(function()
			-- Fire a final callback at the end.
			on_progress_fn({})
		end)
	})
end

return MetaProgressStoreWidget
