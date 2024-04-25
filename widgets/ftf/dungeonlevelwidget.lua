local Widget = require("widgets/widget")
local Text = require("widgets/text")
local Image = require("widgets/image")
local RadialProgress = require("widgets/radialprogress")
local UIAnim = require "widgets.uianim"
local fmodtable = require "defs.sound.fmodtable"
local soundutil = require "util.soundutil"
local audioid = require "defs.sound.audioid"
local easing = require "util.easing"
local MetaProgress = require("defs.metaprogression")

--   ┌─────────────────────────────────┐◄ only shows if self:ShowLargePresentation() is called
--   │ title_container                 │
--   └─────────────────────────────────┘
--              ┌───────────┐◄ badge_bg
--              │ badge     │  badge_radial
--              │           │  badge_overlay
--              │           │  badge_value
--              │           │
--              │           │
--              │           │
--              └───────────┘

local DungeonLevelWidget = Class(Widget, function(self, player)
	Widget._ctor(self, "DungeonLevelWidget")

	self.progress_color = HexToRGB(0xE0B8FFff)

	-- The badge itself
	self.badge = self:AddChild(Widget())
		:SetName("Badge")
	self.badge_bg = self.badge:AddChild(Image("images/ui_ftf_runsummary/DungeonLevelBg.tex"))
		:SetName("Badge bg")
	local ghost_color = deepcopy(self.progress_color)
	ghost_color[4] = ghost_color[4] * 0.25
	self.badge_radial_ghost = self.badge:AddChild(RadialProgress("images/ui_ftf_runsummary/DungeonLevelRadial.tex"))
		:SetName("Badge radial ghost")
		:SetSize(100 * HACK_FOR_4K, 100 * HACK_FOR_4K)
		:SetMultColor(ghost_color)
	self.badge_radial = self.badge:AddChild(RadialProgress("images/ui_ftf_runsummary/DungeonLevelRadial.tex"))
		:SetName("Badge radial")
		:SetSize(100 * HACK_FOR_4K, 100 * HACK_FOR_4K)
		:SetMultColor(self.progress_color)
	self.badge_overlay = self.badge:AddChild(Image("images/ui_ftf_runsummary/DungeonLevelOverlay.tex"))
		:SetName("Badge overlay")
	self.badge_glow = self.badge:AddChild(Image("images/glow.tex"))
		:SetName("Glow")
		:SetSize(110 * HACK_FOR_4K, 110 * HACK_FOR_4K)
		:SetMultColor(self.progress_color)
		:SetMultColorAlpha(0)
		:SetHiddenBoundingBox(true)
	self.badge_value = self.badge:AddChild(Text(FONTFACE.DEFAULT, 52 * HACK_FOR_4K, "", self.progress_color))
		:SetName("Value")
	self.should_play_sound = true

	if player then self:SetPlayer(player) end
	self:Layout()
end)

function DungeonLevelWidget:SetPlayer(player)
	self.player = player
	self.player_id = self.player:GetHunterId()
	self.faction = player:IsLocal() and 1 or 2 -- sets faction parameter to 1 for local players, 2 for remote
	return self
end

-- Large presentation for UI panels
-- Includes the title container, top bar with progress value, and bottom decorations
function DungeonLevelWidget:ShowLargePresentation(decor_color, title_color, title_font_size, text_width)
	if self.title_container then return self end

	self.decor_color = decor_color or UICOLORS.DARK_TEXT_DARKER
	self.title_color = title_color or UICOLORS.DARK_TEXT_DARKER

	self.title_container = self:AddChild(Widget())
		:SetName("Title container")

	local title_size = title_font_size or 88
	self.title = self.title_container:AddChild(Text(FONTFACE.DEFAULT, title_size, "", self.title_color))
		:SetName("Title container")
		:SetAutoSize(text_width or 450)
		:OverrideLineHeight(title_size * 0.9)

	self.bg = self:AddChild(Image("images/ui_ftf_runsummary/DungeonLevelDecor.tex"))
		:SetName("bg")
		:SetMultColor(self.decor_color)
		:MoveToBack()

	self:Layout()
	return self
end

function DungeonLevelWidget:SetTitleFontSize(font_size)
	if not self.title_container then return self end
	local title_size = font_size or 88
	self.title:SetFontSize(font_size)
		:OverrideLineHeight(title_size * 0.9)
	self:Layout()
	return self
end

function DungeonLevelWidget:RefreshMetaProgress(biome_exploration)

	self.biome_exploration = biome_exploration
	self.meta_reward = self.biome_exploration.meta_reward
	self.meta_reward_def = self.biome_exploration.meta_reward_def
		or MetaProgress.FindProgressByName(TheDungeon:GetDungeonMap().data.location_id)


	self.meta_level = self.biome_exploration.meta_level
	self.meta_exp = self.biome_exploration.meta_exp
	self.meta_exp_max = self.biome_exploration.meta_exp_max

	if self.biome_exploration.meta_reward_log and #self.biome_exploration.meta_reward_log > 0 then
		self.meta_reward_log = self.biome_exploration.meta_reward_log
		self.meta_level = self.meta_reward_log[1].start_level
		self.meta_exp = self.meta_reward_log[1].start_exp
		self.meta_exp_max = MetaProgress.GetEXPForLevel(self.meta_reward_def, self.meta_level)
	end

	-- Set progress
	self:SetProgress(self.meta_level, self.meta_exp, self.meta_exp_max)

	-- And the name of the current dungeon
	self:SetBiomeTitle(self.meta_reward_def.pretty.name)

	return self
end

function DungeonLevelWidget:SetBiomeTitle(name)
	if self.title_container then
		self.title:SetText(name)

		self:Layout()
	end
	return self
end

function DungeonLevelWidget:SetProgress(level, exp, exp_max)

	-- Set current level
	self:SetLevelText(level)

	-- Set progress bar
	self:SetProgressData(exp, exp_max)

	self:Layout()
	return self
end

function DungeonLevelWidget:SetProgressGhost(xp, xp_grant, xp_target)
	local ghost_progress = (xp + xp_grant) / xp_target
	self.badge_radial_ghost:SetProgress(ghost_progress)
end
function DungeonLevelWidget:GetMetaLevel()
	return self.meta_level
end

function DungeonLevelWidget:ShouldPlaySound(should_play_sound)
	-- this defaults to true in initial setup (works for end run screen)
	-- but we set it to false when it's called from the map sidebar because it never animates there
	-- and therefore shouldn't play sound
	self.should_play_sound = should_play_sound
end

-- Callback:
-- on_progress_fn(current_level, move_up, reward_earned, sequence_done)
function DungeonLevelWidget:ShowMetaProgression(on_progress_fn, meta_reward_log)
	-- Let's loop through the levels gained, show the progress, and update the main screen
	local presentation = {}
	meta_reward_log = meta_reward_log or self.meta_reward_log
	if meta_reward_log then
		local level_data = meta_reward_log[1]

		local level_num = level_data.start_level

		-- Show bar increasing
		self:BarMovementPresentation(presentation, level_data, 0)

		-- If we leveled up, notify the parent
		if level_data.did_level then
			self:LevelUpPresentation(presentation, level_data)

			table.insert(presentation, Updater.Wait(0.2))
			table.insert(presentation, Updater.Do(function() on_progress_fn( {level_num = level_num, move_up = true} ) end))
			table.insert(presentation, Updater.Wait(0.4))

			-- you get the reward on achieving the level
			-- ie: leveling from 0 -> 1 grants you the reward for level 1
			local current_reward = MetaProgress.GetRewardForLevel(self.meta_reward_def, level_num + 1)
			table.insert(presentation,Updater.Do(function() on_progress_fn( {level_num = level_num, reward_earned = current_reward} ) end),
			table.insert(presentation, Updater.Wait(1.6)))
		end
	end

	return self:RunUpdater(Updater.Series(presentation))
end

function DungeonLevelWidget:BarMovementPresentation(pres, data, remaining)
	local percent_delta = (data.end_exp - data.start_exp) / MetaProgress.GetEXPForLevel(self.meta_reward_def, data.start_level)

	local ease_time = (self.log_has_levelling and remaining == 0) and 3 or (1.5 * percent_delta)

	ease_time = math.max(ease_time, 0.75)
	local easefn = remaining == 0 and easing.outSine or easing.linear

	local progress

	local progress_min = data.start_exp
	local progress_max = data.end_exp
	local progress_delta = progress_max - progress_min

	table.insert(pres, Updater.Parallel({
		Updater.Do(function()
			self:SetProgressData(data.start_exp, MetaProgress.GetEXPForLevel(self.meta_reward_def, data.start_level))
			-- creating the looping XP bar sound
			if progress_delta > 0 and not self.did_level then
				self.meter_sound_LP = self:PlaySpatialSound(fmodtable.Event.endOfRun_XP_tick_LP,
					{
						faction_player_id = self.player_id,
						faction = self.faction,
						progress = progress,
					},true) --autostop
			end
		end),
		Updater.Ease(function(v)
			-- update the progress bar
			self:SetProgressData(v, self.meta_exp_max)
			progress = v / self.meta_exp_max
			if self.meter_sound_LP then
				if self.did_level then
					TheFrontEnd:GetSound():KillSound(self.meter_sound_LP)
					self.meter_sound_LP = nil
				else
					-- adjust pitch of sound according to where we are in the meter
					TheFrontEnd:GetSound():SetParameter(self.meter_sound_LP, "progress", progress)
				end
			end
		end, progress_min, progress_max, ease_time, easefn),
		Updater.Series({
			Updater.Wait(ease_time),
			Updater.Do(function()
				if self.meter_sound_LP then
					TheFrontEnd:GetSound():KillSound(self.meter_sound_LP)
					self.meter_sound_LP = nil
					self.did_level = nil
				end
			end),
		})
	}))

end

function DungeonLevelWidget:LevelUpPresentation(pres, data)
	table.insert(pres, Updater.Do(function()
		self.badge_glow:RunUpdater(Updater.Ease(function(v) self.badge_glow:SetMultColorAlpha(v) end, 0.9, 0, 1.2, easing.inQuad))
		self.badge_value:RunUpdater(Updater.Ease(function(v) self.badge_value:SetScale(v) end, 1.6, 1, 0.4, easing.inQuad))
		self.meta_exp_max = MetaProgress.GetEXPForLevel(self.meta_reward_def, self.meta_level)
		
		self.did_level = true -- i set this for sound so we can stop the xp tick loop and not recreate it
		self:PlaySpatialSound(fmodtable.Event.endOfRun_XP_levelUp, {faction_player_id = self.player_id, faction = self.faction})
		audioid.oneshot.stinger = self:PlaySpatialSound(fmodtable.Event.Mus_levelUp_Stinger, {faction = self.faction, faction_player_id = self.player_id})
	end))
end

function DungeonLevelWidget:SetLevelText(level)
	level = level + 1 -- it's a bit weird if we start at level 0... visually increase levels by 1

	if self.meta_reward and self.meta_reward:IsMaxLevel() then
		level = STRINGS.UI.DUNGEONSUMMARYSCREEN.MAX_META_LEVEL
	end
	
	self.badge_value:SetText(level)
	self:Layout()
end

function DungeonLevelWidget:SetProgressData(current, max)
	self.badge_radial:SetProgress(current/max)
	return self
end

function DungeonLevelWidget:Layout()

	self.badge_value:LayoutBounds("center", "center", self.badge_bg)
		:Offset(0 * HACK_FOR_4K, 3 * HACK_FOR_4K)

	if self.title_container then

		self.bg:LayoutBounds("center", "center", self.badge)

		self.title_container:LayoutBounds("center", "above", self.bg)
			:Offset(0, 12)
	end

	return self
end

function DungeonLevelWidget:OnVizChange(is_visible)
	if self.meter_sound_LP then
		if not is_visible then
			TheFrontEnd:GetSound():KillSound(self.meter_sound_LP)
			self.meter_sound_LP = nil
		end
	end
end

function DungeonLevelWidget:OnRemoved()
	if self.meter_sound_LP then
	TheFrontEnd:GetSound():KillSound(self.meter_sound_LP)
	self.meter_sound_LP = nil
	end
end

return DungeonLevelWidget
