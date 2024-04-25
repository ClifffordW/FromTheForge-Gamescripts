local Widget = require("widgets/widget")
local Image = require("widgets/image")
local Panel = require("widgets/panel")
local Text = require("widgets/text")
local iterator = require "util.iterator"
local Mastery = require "defs.masteries"
local ActionButton = require("widgets/actionbutton")
local MasteryWidget = require("widgets/ftf/masterywidget")
local GenericPlayerScreen = require("screens/town/genericplayerscreen")
local GenericPlayerPanel = require("widgets/ftf/genericplayerpanel")
local ExpandingTabGroup = require "widgets/expandingtabgroup"
local playerutil = require "util.playerutil"
local fmodtable = require "defs.sound.fmodtable"

local CATEGORIES =
{
	WEAPON_TYPES.HAMMER,
	WEAPON_TYPES.POLEARM,
	WEAPON_TYPES.CANNON,
	WEAPON_TYPES.SHOTPUT
}

local MasteryPanel = Class(GenericPlayerPanel, function(self, player)
	GenericPlayerPanel._ctor(self, player, STRINGS.UI.MASTERYSCREEN.TITLE)

	player:UnlockFlag("pf_unlocked_masteries")

	local contents = self:GetContents()

	--Make these show above the content, so we can move the tabs beneath them
	self.title_bg:SendToFront()
	self.title:SendToFront()

	self.categories_container = contents:AddChild(Widget())

	self.categories_bg = self.categories_container:AddChild(Panel("images/ui_ftf_research/research_tabs_bg.tex"))
		:SetName("Tabs background")
		:SetNineSliceCoords(26, 0, 195, 150)
		:SetMultColor(UICOLORS.LIGHT_BACKGROUNDS_MID)

	self.categories = self.categories_container:AddChild(ExpandingTabGroup("Categories"))
		:SetGridLayout(4) -- Max 4 columns
		:SetTabOnClick(function(tab_btn)
			self.selected_category = tab_btn.category
			self:RefreshCategories()
		end)

	self.category_buttons = {}

	for _, v in ipairs(CATEGORIES) do
		if player.components.unlocktracker:IsWeaponTypeUnlocked(v) then
			local category_btn = self.categories
				:AddTab(WEAPON_TYPE_TO_TEX[v])
				:SetToolTip(STRINGS.ITEM_CATEGORIES[v])
				:ShowToolTipOnFocus(true)
				:SetStarIcon()

			self.category_buttons[v] = category_btn

			category_btn.category = v
		end
	end

	--add two extra categories
	local category_btn = self.categories
		:AddTab("images/icons_ftf/inventory_sets.tex")
		:SetToolTip(STRINGS.UI.MASTERYSCREEN.GENERAL)
		:ShowToolTipOnFocus(true)
		:SetStarIcon()
	category_btn.category = "GENERAL"
	self.category_buttons["GENERAL"] = category_btn

	category_btn = self.categories
		:AddTab("images/icons_ftf/inventory_bosses.tex")
		:SetToolTip(STRINGS.UI.MASTERYSCREEN.OTHER)
		:ShowToolTipOnFocus(true)
		:SetStarIcon()
	category_btn.category = "OTHER"
	self.category_buttons["OTHER"] = category_btn

	for category, btn in pairs(self.category_buttons) do
		btn.claim_icon = btn:AddChild(Image("images/ui_ftf/warning.tex"))
			:SetScale(0.33)
			:LayoutBounds("right", "bottom", btn)
			:SetHiddenBoundingBox(true)
			:Offset(0, 0)
			:SetToolTip(STRINGS.UI.MASTERYSCREEN.CAN_CLAIM)
			:Hide()
	end

	self.categories:Layout()

	if self.categories:GetNumTabs() > 1 then
		self.categories:AddCycleIcons(60, 10, UICOLORS.LIGHT_TEXT_DARK)
	end

	local tabs_w, tabs_h = self.categories:GetSize()
	self.categories_bg
		:SetSize(tabs_w + 210, tabs_h + 160)
		:LayoutBounds("center", "center", self.categories_container)

	self.categories
		:LayoutBounds("center", "bottom", self.categories_bg)
		:Offset(0, 30)

	self.categories:SetNavFocusable(false)

	self.categories_container
		:LayoutBounds("center", "bottom", self.title_bg)
		:Offset(0, -tabs_h - 40)

	self.help_text = contents:AddChild(Text(FONTFACE.DEFAULT, FONTSIZE.SCREEN_TEXT, STRINGS.UI.MASTERYSCREEN.DESC, UICOLORS.LIGHT_TEXT_DARK))
		:SetWordWrap(true)
		:SetAutoSize(600)
		:LayoutBounds("center", "below", self.categories_container)
		:Offset(0, -20)

	self.masteries = contents:AddChild(Widget("Masteries"))

	self.forward_default_focus = function()
		return self.masteries:GetFirstChild()
	end
end)

function MasteryPanel:OnOpenPanel()
	self.categories:OpenTabAtIndex(1)
end

MasteryPanel.CONTROL_MAP =
{
	{
		control = Controls.Digital.MENU_TAB_PREV,
		hint = function(self, left, right)
			table.insert(right, loc.format(LOC"UI.CONTROLS.PREV_TAB", Controls.Digital.MENU_TAB_PREV))
		end,
		fn = function(self)
			self.categories:NextTab(-1)
			TheFrontEnd:GetSound():PlaySound(fmodtable.Event.input_down)
			return true
		end,
	},
	{
		control = Controls.Digital.MENU_TAB_NEXT,
		hint = function(self, left, right)
			table.insert(right, loc.format(LOC"UI.CONTROLS.NEXT_TAB", Controls.Digital.MENU_TAB_NEXT))
		end,
		fn = function(self)
			self.categories:NextTab(1)
			TheFrontEnd:GetSound():PlaySound(fmodtable.Event.input_down)
			return true
		end,
	},
}

function MasteryPanel:RefreshNewStatus()
	local player = self:GetOwningPlayer()

	for category, btn in pairs(self.category_buttons) do
		btn:ShowAvailableActionIcon(false)
		btn.claim_icon:Hide()
	end

	for _, mastery_group in pairs(Mastery.Items) do

		local mastery_compare = function(k1, k2)
			return mastery_group[k1].order < mastery_group[k2].order
		end

		for _, mastery in iterator.sorted_pairs(mastery_group, mastery_compare) do
			local mastery_inst = player.components.masterymanager:GetMasteryByName(mastery.name)
			if not mastery.hide then
				-- also update if you have any unclaimed or new masteries to be notified about
				if mastery_inst and self.category_buttons[mastery.mastery_type] then
					if not player.components.hasseen:HasSeenMastery(mastery.name) then
						self.category_buttons[mastery.mastery_type]:ShowAvailableActionIcon(true)
					end

					if mastery_inst:IsComplete() and not mastery_inst:IsClaimed() then
						self.category_buttons[mastery.mastery_type].claim_icon:Show()
					end
				end
			end
		end
	end
end

function MasteryPanel:RefreshCategories(force_select_mastery)
	self.masteries:RemoveAllChildren()

	local player = self:GetOwningPlayer()

	player.components.masterymanager:EvaluatePaths() -- do we need to give you anything new?

	local size = 135 * HACK_FOR_4K

	for _, mastery_group in pairs(Mastery.Items) do
		local mastery_compare = function(k1, k2)
			return mastery_group[k1].order < mastery_group[k2].order
		end

		for _, mastery in iterator.sorted_pairs(mastery_group, mastery_compare) do
			if mastery.mastery_type == self.selected_category and not mastery.hide then
				self.masteries:AddChild(MasteryWidget(player, size))
							:SetClaimFn( function() self:RefreshCategories(mastery) end )
							:SetMasteryData(mastery)
							:SetOnGainFocusFn(function() self:RefreshNewStatus() end)
							:SetToolTipLayoutFn(function(w, tooltip)
								-- Show the tooltip below the widget for mouse, and at the bottom
								-- of the panel for controller
								if w:GetOwningPlayer() and w:GetOwningPlayer().components.playercontroller:IsRelativeNavigation() then
									tooltip:LayoutBounds("center", "below", self.masteries)
										:Offset(0, 40)
								end
							end)
			end
		end
	end

	self:RefreshNewStatus()

	local spacing = 20
	local rows = #self.masteries:GetChildren() > 12 and 3 or 2
	local scale = #self.masteries:GetChildren() > 12 and 0.9 or 1

	self.masteries:SetScale(scale)

	self.masteries
		:LayoutInDiagonal(rows, 20, -(size-spacing)/2)
		:LayoutBounds("center", "below", self.help_text)
		:Offset(0, -30)

	local hunter_id = self:GetOwningPlayer():GetHunterId()

	if #self.masteries.children > 0 then
		if force_select_mastery ~= nil then
			for _, mastery_widget in ipairs(self.masteries.children) do
				if mastery_widget.def == force_select_mastery then
					mastery_widget:SetFocus(hunter_id)
				end
			end
		else
			self:FindDefaultFocus():SetFocus(hunter_id)
		end
	end
end

function MasteryPanel:Refresh()
	for _, v in ipairs(self.masteries:GetChildren()) do
		v:Refresh()
	end
end

local MasteryScreen = Class(GenericPlayerScreen, function(self, initiating_player)
	GenericPlayerScreen._ctor(self, initiating_player, "MasteryScreen")

	playerutil.DoForAllLocalPlayers(function(player)
		self:AddPanel(MasteryPanel(player))
	end)
end)

return MasteryScreen
