local Widget = require("widgets/widget")
local Text = require("widgets/text")
local HotkeyWidget = require "widgets.hotkeywidget"
local Image = require("widgets/image")
local Panel = require("widgets/panel")
local ExpandingTabGroup = require("widgets/expandingtabgroup")
local ImageButton = require("widgets/imagebutton")
local kstring = require "util.kstring"

local easing = require"util.easing"

local FrenzySelectionWidget = Class(Widget, function(self)
	Widget._ctor(self, "FrenzySelectionWidget")

	-- Background
	self.bg = self:AddChild(Image("images/map_ftf/frenzy_panel_bg.tex"))
		:SetName("Background")

	-- Details container
	self.details_container = self:AddChild(Widget())
		:SetName("Details container")

	-- Frenzy level selector
	self.tab_group_container = self:AddChild(Widget())
		:SetName("Tab group container")
		:SetScale(0.7)

	self.tabs_background = self.tab_group_container:AddChild(Panel("images/ui_ftf_research/research_tabs_bg.tex"))
		:SetName("Tabs background")
		:SetNineSliceCoords(26, 0, 195, 150)
		:SetMultColor(UICOLORS.LIGHT_BACKGROUNDS_MID)

	self.tab_group = self.tab_group_container:AddChild(ExpandingTabGroup())
		:SetName("Expanding tab group")
		:SetTabOnClick(function(active_tab) self:SetSelectedLevel(active_tab.level) end)
		:SetOnTabSizeChange(function() self:LayoutTabs() end)

	-- Level description
	self.description_bg = self:AddChild(Image("images/map_ftf/panel_title_bg.tex"))
		:SetName("Description background")

	self.level_description = self:AddChild(Text(FONTFACE.DEFAULT, FONTSIZE.SCREEN_TEXT, "", UICOLORS.LIGHT_TEXT_DARK))
		:SetName("Level description")
		:SetAutoSize(900)
		:LeftAlign()

	-- Locked info-label
	self.locked_info_label = self:AddChild(Text(FONTFACE.DEFAULT, FONTSIZE.SCREEN_TEXT, "", UICOLORS.LIGHT_TEXT_DARK))
		:SetName("Locked info-label")
		:SetText(STRINGS.UI.MAPSCREEN.LOCKED_INFO_LABEL)
		:Hide()

	self.selected_level = 0

end)

function FrenzySelectionWidget:SetPlayer(player)
	dbassert(player)
	self:SetOwningPlayer(player)
	self.tab_group:RefreshHotkeyIcon()
	if self:ShouldShow() then
		self:ShowUnlockedMode()
	else
		self:ShowLockedMode()
		self:Hide()
	end
	self:Layout()
	return self
end

function FrenzySelectionWidget:ShouldShow()
	local player = self:GetOwningPlayer()
	local ascension_data = player.components.unlocktracker:GetAllAscensionData()

	-- has the player completed the base level with ANY weapon type?

	for location, weapons in pairs(ascension_data) do
		for weapon, level in pairs(weapons) do
			if level >= 0 then
				return true
			end
		end
	end

	return false
end

function FrenzySelectionWidget:ShowUnlockedMode()

	self.tab_group_container:Show()
	self.details_container:Show()
	self.description_bg:Show()
	self.level_description:Show()
	self.locked_info_label:Hide()

	return self
end

-- Just a label saying ascension is locked
function FrenzySelectionWidget:ShowLockedMode()

	self.tab_group_container:Hide()
	self.details_container:Hide()
	self.description_bg:Hide()
	self.level_description:Hide()
	self.locked_info_label:Show()

	return self
end

function FrenzySelectionWidget:OnUpdate()
	-- called from MapSidebar:OnUpdate()

	local current_data = self:CollectPlayerData()

	-- player count changed ?
	local do_refresh = table.count(current_data) ~= table.count(self.player_data)

	if not do_refresh then
		for player, weapon in pairs(current_data) do
			local old_weapon = self.player_data[player]
			if not old_weapon or old_weapon ~= weapon then
				-- either no record of the player, or the player changed weapons
				do_refresh = true
				break
			end
		end
	end

	if do_refresh then
		self:SetLocation(self.location_data)
	end
end

function FrenzySelectionWidget:CollectPlayerData()
	local player_weapon_data = {}
	for _, player in ipairs(AllPlayers) do
		player_weapon_data[player] = player.components.inventory:GetEquippedWeaponType()
	end
	return player_weapon_data
end

function FrenzySelectionWidget:SetLocation(data)
	local player = self:GetOwningPlayer()

	-- Remove old tabs
	self.tab_group:RemoveAllTabs()

	-- Get all data
	local ascensionmanager = TheDungeon.progression.components.ascensionmanager
	self.location_data = data
	local num_ascensions = ascensionmanager.num_ascensions

	-- Data about the player viewing the screen
	local unlocktracker = player.components.unlocktracker
	local equipped_weapon_type = player.components.inventory:GetEquippedWeaponType()
	local max_seen_level = unlocktracker:GetHighestSeenAscension()
	self.highest_personal_ascension_level = unlocktracker:GetCompletedAscensionLevel(self.location_data.id, equipped_weapon_type)

	-- Data about the party
	local highest_common_ascension_level, limiting_player = ascensionmanager:GetHighestCompletedLevelForParty(self.location_data.id)
	local max_allowed_level_for_party = ascensionmanager:GetMaxAllowedLevelForParty(self.location_data)
	self.player_data = self:CollectPlayerData()

	-- Since ascensions are tracked in two separate systems (unlocktracker and
	-- ascensionmanager, it's possible that they're not in sync (especially
	-- with debug). So ensure we show widgets for the maximum.
	local max_displayed_level = math.max(max_seen_level, max_allowed_level_for_party)

	-- this widget only displays the NORMAL frenzy levels. Don't go past that.
	max_displayed_level = math.min(max_displayed_level, NORMAL_FRENZY_LEVELS)
	max_seen_level = math.min(max_seen_level, NORMAL_FRENZY_LEVELS)

	---------------------------------------------------------------------------------------
	-- Add empty level widget for base-difficulty
	local tab = self.tab_group:AddFrenzyTab("images/map_ftf/frenzy_level_0.tex", STRINGS.UI.DUNGEONSELECTIONSCREEN.FRENZY_WIDGET.BASE_DIFFICULTY_TITLE)
	tab.level = 0
	tab:SetCompleted(self.highest_personal_ascension_level >= 0)

	---------------------------------------------------------------------------------------

	---------------------------------------------------------------------------------------
	-- Add new level widgets

	for level, level_data in ipairs(ascensionmanager.ascension_data) do
		-- Show only levels the player has seen
		if level <= max_allowed_level_for_party then
			local frenzy_string = kstring.subfmt(STRINGS.UI.DUNGEONSELECTIONSCREEN.FRENZY_WIDGET.FRENZY_LEVEL_TITLE, { level = level })
			tab = self.tab_group:AddFrenzyTab("images/map_ftf/frenzy_level_" .. level .. ".tex", frenzy_string)
			tab.level = level
			tab:SetCompleted(level <= self.highest_personal_ascension_level)

		-- elseif level <= NORMAL_FRENZY_LEVELS then -- Show locked ones
		-- 	tab = self.tab_group:AddFrenzyTab("images/map_ftf/frenzy_locked.tex", "Frenzy Lvl " .. level)
		-- 	tab:SetLocked(true)
		-- 	tab.level = level
		end
	end

	---------------------------------------------------------------------------------------

	-- If there's more than one player, display whether one is limiting the others

	if max_seen_level > max_allowed_level_for_party then
		local limiting_weapon_type = limiting_player.components.inventory:GetEquippedWeaponType()
		local limited_level = highest_common_ascension_level >= 0 and highest_common_ascension_level or STRINGS.ASCENSIONS.NO_LEVEL_INFO
		local args = {
			weapon = STRINGS.ITEM_CATEGORIES[limiting_weapon_type],
			highest_level = limited_level,
			limiting_player = limiting_player:GetCustomUserName(),
		}
		if limiting_player == self:GetOwningPlayer() then
			self.level_limit_string = STRINGS.ASCENSIONS.LEVEL_LIMIT_INFO_SELF:subfmt(args)
		else
			self.level_limit_string = STRINGS.ASCENSIONS.LEVEL_LIMIT_INFO:subfmt(args)
		end
	else
		self.level_limit_string = ""
	end

	self.tab_group:AddCycleIcons(65, 70)
	self.tab_group:SelectTab(max_allowed_level_for_party + 1, true)

	self:Layout()
	return self
end

function FrenzySelectionWidget:SetSelectedLevel(level)
	local ascensionmanager = TheDungeon.progression.components.ascensionmanager

	local max_allowed_level = ascensionmanager:GetMaxAllowedLevelForParty(self.location_data)
	level = math.clamp(level, 0, max_allowed_level)

	self.selected_level = level
	self.tab_group:SelectTab(self.selected_level + 1, false)

	-- Update level details
	self.details_container:RemoveAllChildren()

	if level > 0 then

		local left_details = self.details_container:AddChild(Widget("Left Container"))
		local right_details = self.details_container:AddChild(Widget("Right Container"))
		local detail_columns = { right_details, left_details }

		local active_mods = ascensionmanager.GetActiveModsPerLevel(level)

		for id, str in ipairs(FRENZY_MODIFIERS:Ordered()) do
			local column = id%2 + 1 -- returns 1 or 2 depending on if the mod_id is even or odd

			local text = ""

			if active_mods[id] then
				text = ascensionmanager.GetModDescription(id, active_mods[id])
			end

			detail_columns[column]:AddChild(Text(FONTFACE.DEFAULT, 42))
				:SetGlyphColor(UICOLORS.LIGHT_TEXT_DARK)
				:SetText(text)
				:LeftAlign()
				:SetRegionSize(560, 70)
		        :ShrinkToFitRegion(true)
		        :LayoutBounds("below", "left")
		end

		left_details:LayoutChildrenInColumn(0, "left")
		right_details:LayoutChildrenInColumn(0, "left")

		right_details:LayoutBounds("after", "top", left_details)
	else
		self.details_container:AddChild(Text(FONTFACE.DEFAULT, 42))
			:SetGlyphColor(UICOLORS.LIGHT_TEXT_DARK)
			:SetText(STRINGS.ASCENSIONS.NONE)
			:LeftAlign()
	end

	-- Is this level completed?
	local completed = self.selected_level <= self.highest_personal_ascension_level
	if completed then
		self.level_completed_string = STRINGS.ASCENSIONS.LEVEL_COMPLETED
	else
		self.level_completed_string = STRINGS.ASCENSIONS.LEVEL_AVAILABLE
	end

	self.level_description:SetText(self.level_completed_string .. "\n" .. self.level_limit_string)
	ascensionmanager:StoreSelectedAscension(self.location_data.id, level)

	if self.onSelectLevelFn then
		self.onSelectLevelFn()
	end

	self:Layout()
end

function FrenzySelectionWidget:BuildTooltipString()
	-- TODO: TEMP INFO, THIS SHOULD BE PRESENTED IN A BETTER WAY
	local data = TheDungeon.progression.components.ascensionmanager:GetPartyAscensionData(self.location_data.id)
	local str = "Highest Frenzy Completed:"
	for id = 0, 3 do
		local player_data = data[id]
		if player_data then
			local highest = player_data.level >= 0 and player_data.level or "None"
			str = str..string.format("\n%s %s: %s [%s]", STRINGS.UI.BULLET_POINT, player_data.player:GetCustomUserName(), highest, STRINGS.ITEM_CATEGORIES[player_data.weapon_type])
		end
	end
	return str
end

function FrenzySelectionWidget:SetOnSelectLevelFn(fn)
	self.onSelectLevelFn = fn
	return self
end

function FrenzySelectionWidget:DeltaLevel(delta)
	if not self:IsVisible() then
		-- Not visible, then not interactable.
		return
	end
	-- TODO(ui): POSTVS We should probably call Click on buttons directly
	-- to get the same sound behaviour as mouse clicks, but that currently
	-- doesn't play sound. Too big to change now.
	TheFrontEnd:GetSound():PlaySound(self.controldown_sound)
	self:SetSelectedLevel(self.selected_level + delta)
end

function FrenzySelectionWidget:LayoutTabs()
	self.tab_group:Layout()
	local tabs_w, tabs_h = self.tab_group:GetSize()
	self.tabs_background:SetSize(tabs_w + 100, tabs_h + 60)
	self.tab_group:LayoutBounds("center", "center", self.tabs_background)
	self.tab_group_container:LayoutBounds("center", "top", self.bg)
		:Offset(0, -37)
	return self
end

function FrenzySelectionWidget:Layout()

	self:LayoutTabs()

	-- Layout details
	self.details_container:LayoutChildrenInAutoSizeGrid(2, 30, 5)
	self.details_container:LayoutBounds("center", "below", self.tab_group_container)
		:Offset(0, -20)

	-- Layout text description
	local description_w, description_h = self.level_description:GetSize()
	self.description_bg:SetScale(1, 1)
		:SetSize(description_w + 80, description_h + 30)
		:LayoutBounds("center", "bottom", self.bg)
		:Offset(0, 30)
		:SetScale(1, -1)
		:SetShown(self.level_description:HasText())
	self.level_description:LayoutBounds("center", "center", self.description_bg)
		:Offset(0, 0)
		:SetShown(self.level_description:HasText())

	return self
end

return FrenzySelectionWidget
