local Clickable = require "widgets.clickable"
local TabGroup = require "widgets.tabgroup"
local Image = require "widgets.image"
local Panel = require "widgets.panel"
local ImageButton = require "widgets.imagebutton"
local TextButton = require "widgets.textbutton"
local ActionAvailableIcon = require("widgets/ftf/actionavailableicon")
local Text = require "widgets.text"
local Widget = require "widgets/widget"
local easing = require "util.easing"
require "class"
require "util"

local ExpandingTabGroup = Class(TabGroup, function(self)
	TabGroup._ctor(self, "ExpandingTabGroup")
	self.tab_spacing = 5
end)

-- A tab with a bg, icon and text label
-- When selected, the icon and text are shown
-- When not, just the icon shows
--
-- ┌──────────────────┐  ┌──────────┐  ┌──────────┐ ◄ bg alternates between tab_odd and tab_even
-- │ ┌──────┐         │  │ ┌──────┐ │  │ ┌──────┐ │
-- │ │      ├───────┐ │  │ │      │ │  │ │      │ │
-- │ │ icon │ label │ │  │ │ icon │ │  │ │ icon │ │
-- │ │      ├───────┘ │  │ │      │ │  │ │      │ │
-- │ └──────┘         │  │ └──────┘ │  │ └──────┘ │
-- └──────────────────┘  └──────────┘  └──────────┘
--      ▲ the selected tab is expanded
--
function ExpandingTabGroup:AddTab(icon, text)
	local tab = self.tabs_container:AddChild(Clickable())
	tab.tab_group = self

	tab.icon_max_height = 90
	tab.is_locked = false

	tab.is_even = #self.tabs_container.children % 2 ~= 0
	tab.bg = tab:AddChild(Panel(tab.is_even and "images/ui_ftf_research/research_tab_even.tex" or "images/ui_ftf_research/research_tab_odd.tex"))
		:SetNineSliceCoords(15, 0, 202, 150)
		:SetName("Background")
	tab.content = tab:AddChild(Widget())
		:SetName("Content")
	tab.icon = tab.content:AddChild(Image(icon))
		:SetName("Icon")
		:SetMultColor(WEBCOLORS.WHITE)
	tab.text = tab.content:AddChild(Text(FONTFACE.DEFAULT, 80))
		:SetName("Text")
		:SetGlyphColor(WEBCOLORS.WHITE)
		:SetText(text)
		:LeftAlign()
	tab.action_available_icon = tab:AddChild(ActionAvailableIcon())
		:SetName("Action available icon")
		:SetHiddenBoundingBox(true)
		:SetScale(1.2)
		:Hide()
	tab.text.offset = 8

	function tab:SetStarIcon()
		self.action_available_icon:ChangeToStar()
		return self
	end

	function tab:ShowAvailableActionIcon(show_icon)
		self.action_available_icon:SetShown(show_icon)
		return self
	end

	-- Locked tabs don't show text
	function tab:SetLocked(is_locked)
		self.is_locked = is_locked
		self:RelayoutTab()
		return self
	end

	function tab:RelayoutTab()
		-- Make sure the icon doesn't pass the icon_max_height
		local ic_w, ic_h = self.icon:GetSize()
		if ic_h > self.icon_max_height then
			local ratio = self.icon_max_height/ic_h
			self.icon:SetScale(ratio)
		end

		self.text:LayoutBounds("after", "center", self.icon)
			:Offset(self.text.offset, 0)
			:SetShown(self:IsSelected() and self.is_locked == false)
		local w, h = self.content:GetSize()
		self.bg:SetSize(w + 40, h + 30)
			:LayoutBounds("center", "center", self.content)
		self.action_available_icon:LayoutBounds("right", "top", self.bg)
			:Offset(self.is_even and 8 or 1, 11)
		if self.tab_group.onTabSizeChange then self.tab_group.onTabSizeChange() end
		return self
	end

	tab:RelayoutTab()

	self:_ApplyFancyTint(tab)
	return self:_HookupTab(tab)
end

function ExpandingTabGroup:AddFrenzyTab(icon, text, is_complete)
	local tab = self.tabs_container:AddChild(Clickable())
	tab.tab_group = self

	tab.icon_max_height = 90
	tab.is_locked = false

	local is_even = #self.tabs_container.children % 2 ~= 0
	tab.bg = tab:AddChild(Panel(is_even and "images/ui_ftf_research/research_tab_even.tex" or "images/ui_ftf_research/research_tab_odd.tex"))
		:SetNineSliceCoords(15, 0, 202, 150)
		:SetName("Background")
	tab.content = tab:AddChild(Widget())
		:SetName("Content")
	tab.icon = tab.content:AddChild(Image(icon))
		:SetName("Icon")
		:SetMultColor(WEBCOLORS.WHITE)
	tab.completed_back = tab.content:AddChild(Image("images/map_ftf/frenzy_level_complete_back.tex"))
		:SetName("Progress back")
		:SetMultColor(WEBCOLORS.WHITE)
		:SetHiddenBoundingBox(true)
	tab.completed_front = tab.content:AddChild(Image("images/map_ftf/frenzy_level_complete_front.tex"))
		:SetName("Progress front")
		:SetMultColor(WEBCOLORS.WHITE)
		:SetHiddenBoundingBox(true)
	tab.heart_back = tab.content:AddChild(Image("images/map_ftf/frenzy_level_heart_back.tex"))
		:SetName("Heart back")
		:SetMultColor(WEBCOLORS.WHITE)
		:SetHiddenBoundingBox(true)
	tab.heart_front = tab.content:AddChild(Image("images/map_ftf/frenzy_level_heart_front.tex"))
		:SetName("Heart front")
		:SetMultColor(WEBCOLORS.WHITE)
		:SetHiddenBoundingBox(true)

	-- Pulse the heart
	tab.heart_front:RunUpdater(
		Updater.Loop{
			Updater.Ease(function(v) tab.heart_front:SetScale(v, v) end, 0.9, 1.05, 0.6, easing.inQuad),
			Updater.Ease(function(v) tab.heart_front:SetScale(v, v) end, 1.05, 0.9, 0.8, easing.outQuad),
		}
	)

	tab.text = tab.content:AddChild(Text(FONTFACE.DEFAULT, 80))
		:SetName("Text")
		:SetGlyphColor(WEBCOLORS.WHITE)
		:SetText(text)
		:LeftAlign()
	tab.action_available_icon = tab:AddChild(ActionAvailableIcon())
		:SetName("Action available icon")
		:SetHiddenBoundingBox(true)
		:SetScale(1.2)
		:Hide()
	tab.text.offset = 8

	function tab:SetCompleted(is_completed)
		self.is_completed = is_completed
		self.completed_back:SetShown(self.is_completed)
		self.completed_front:SetShown(self.is_completed)
		self.heart_back:SetShown(not self.is_completed)
		self.heart_front:SetShown(not self.is_completed)
		return self
	end

	-- Locked tabs don't show text
	function tab:SetLocked(is_locked)
		self.is_locked = is_locked
		self:RelayoutTab()
		return self
	end

	function tab:RelayoutTab()
		-- Make sure the icon doesn't pass the icon_max_height
		local ic_w, ic_h = self.icon:GetSize()
		if ic_h > self.icon_max_height then
			local ratio = self.icon_max_height/ic_h
			self.icon:SetScale(ratio)
			local icon_w, icon_h = self.icon:GetSize()
			if self.completed_back then self.completed_back:SetSize(icon_w*0.4, icon_h*0.4):LayoutBounds("right", "bottom", self.icon):Offset(8, -5) end
			if self.completed_front then self.completed_front:SetSize(icon_w*0.4, icon_h*0.4):LayoutBounds("center", "center", self.completed_back) end
			if self.heart_back then self.heart_back:SetSize(icon_w*0.4, icon_h*0.4):LayoutBounds("right", "bottom", self.icon):Offset(8, -5) end
			if self.heart_front then self.heart_front:SetSize(icon_w*0.4, icon_h*0.4):LayoutBounds("center", "center", self.heart_back) end
		end

		self.text:LayoutBounds("after", "center", self.icon)
			:Offset(self.text.offset, 0)
			:SetShown(self:IsSelected() and self.is_locked == false)
		local w, h = self.content:GetSize()
		self.bg:SetSize(w + 40, h + 30)
			:LayoutBounds("center", "center", self.content)
		self.action_available_icon:LayoutBounds("right", "top", self.bg)
			:Offset(-15, 10)
		if self.tab_group.onTabSizeChange then self.tab_group.onTabSizeChange() end
		return self
	end

	tab:RelayoutTab()

	self:_ApplyFancyTint(tab)
	return self:_HookupTab(tab)
end

function ExpandingTabGroup:SetTheme_DarkOnLight()
	self._base.SetTheme_DarkOnLight(self)

	-- Add more colors
	self.colors.text_normal = UICOLORS.DARK_TEXT
	self.colors.text_focus = UICOLORS.BLACK
	self.colors.text_disabled = UICOLORS.BLACK
	self.colors.text_selected = UICOLORS.BLACK
	self.colors.bg_normal = UICOLORS.LIGHT_TEXT
	self.colors.bg_focus = UICOLORS.FOCUS
	self.colors.bg_disabled = UICOLORS.DISABLED
	self.colors.bg_selected = UICOLORS.DARK_TEXT

	return self
end

function ExpandingTabGroup:_ApplyFancyTint(tab)
	tab:SetOnGainFocus(function()
		tab.bg:TintTo(nil, self.colors.bg_focus, 0.05, easing.inQuad)
		tab.icon:TintTo(nil, self.colors.text_focus, 0.05, easing.inQuad)
		tab.text:TintTo(nil, self.colors.text_focus, 0.05, easing.inQuad)
		if tab.heart_back then tab.heart_back:TintTo(nil, self.colors.text_focus, 0.05, easing.inQuad) end
		if tab.completed_back then tab.completed_back:TintTo(nil, self.colors.text_focus, 0.05, easing.inQuad) end
		if tab.completed_front then tab.completed_front:TintTo(nil, self.colors.bg_focus, 0.05, easing.inQuad) end
	end)
	tab:SetOnLoseFocus(function()
		tab.bg:TintTo(nil, tab:IsSelected() and self.colors.bg_selected or self.colors.bg_normal, 0.3, easing.outQuad)
		tab.icon:TintTo(nil, tab:IsSelected() and self.colors.text_selected or self.colors.text_normal, 0.3, easing.outQuad)
		tab.text:TintTo(nil, tab:IsSelected() and self.colors.text_selected or self.colors.text_normal, 0.3, easing.outQuad)
		if tab.heart_back then tab.heart_back:TintTo(nil, tab:IsSelected() and self.colors.text_selected or self.colors.text_normal, 0.3, easing.outQuad) end
		if tab.completed_back then tab.completed_back:TintTo(nil, tab:IsSelected() and self.colors.text_selected or self.colors.text_normal, 0.3, easing.outQuad) end
		if tab.completed_front then tab.completed_front:TintTo(nil, tab:IsSelected() and self.colors.bg_selected or self.colors.bg_normal, 0.3, easing.outQuad) end
	end)
	tab:SetOnDown(function()
		tab.bg:TintTo(nil, self.colors.bg_selected, 0.05, easing.inQuad)
		tab.icon:TintTo(nil, self.colors.text_selected, 0.05, easing.inQuad)
		tab.text:TintTo(nil, self.colors.text_selected, 0.05, easing.inQuad)
		if tab.heart_back then tab.heart_back:TintTo(nil, self.colors.text_selected, 0.05, easing.inQuad) end
		if tab.completed_back then tab.completed_back:TintTo(nil, self.colors.text_selected, 0.05, easing.inQuad) end
		if tab.completed_front then tab.completed_front:TintTo(nil, self.colors.bg_selected, 0.05, easing.inQuad) end
	end)
	tab:SetOnUp(function()
		-- No change is needed, since the OnSelect or OnUnSelect will be triggered and change the tints
	end)
	tab:SetOnSelect(function()
		tab:RelayoutTab()
		if tab.hover or tab:HasFocus() then
			tab.bg:TintTo(nil, self.colors.bg_focus, 0.05, easing.inQuad)
			tab.icon:TintTo(nil, self.colors.text_focus, 0.05, easing.inQuad)
			tab.text:TintTo(nil, self.colors.text_focus, 0.05, easing.inQuad)
			if tab.heart_back then tab.heart_back:TintTo(nil, self.colors.text_focus, 0.05, easing.inQuad) end
			if tab.completed_back then tab.completed_back:TintTo(nil, self.colors.text_focus, 0.05, easing.inQuad) end
			if tab.completed_front then tab.completed_front:TintTo(nil, self.colors.bg_focus, 0.05, easing.inQuad) end
		else
			tab.bg:TintTo(nil, tab:IsSelected() and self.colors.bg_selected or self.colors.bg_normal, 0.3, easing.outQuad)
			tab.icon:TintTo(nil, tab:IsSelected() and self.colors.text_selected or self.colors.text_normal, 0.3, easing.outQuad)
			tab.text:TintTo(nil, tab:IsSelected() and self.colors.text_selected or self.colors.text_normal, 0.3, easing.outQuad)
			if tab.heart_back then tab.heart_back:TintTo(nil, self.colors.text_selected, 0.3, easing.outQuad) end
			if tab.completed_back then tab.completed_back:TintTo(nil, self.colors.text_selected, 0.3, easing.outQuad) end
			if tab.completed_front then tab.completed_front:TintTo(nil, self.colors.bg_selected, 0.3, easing.outQuad) end
		end
	end)
	tab:SetOnUnSelect(function()
		tab:RelayoutTab()
		tab.bg:TintTo(nil, self.colors.bg_normal, 0.3, easing.outQuad)
		tab.icon:TintTo(nil, self.colors.text_normal, 0.3, easing.outQuad)
		tab.text:TintTo(nil, self.colors.text_normal, 0.3, easing.outQuad)
		if tab.heart_back then tab.heart_back:TintTo(nil, self.colors.text_normal, 0.3, easing.outQuad) end
		if tab.completed_back then tab.completed_back:TintTo(nil, self.colors.text_normal, 0.3, easing.outQuad) end
		if tab.completed_front then tab.completed_front:TintTo(nil, self.colors.bg_normal, 0.3, easing.outQuad) end
	end)

	-- Snap to initial color
	tab.bg:TintTo(nil, self.colors.bg_normal, 0, easing.outQuad)
	tab.icon:TintTo(nil, self.colors.text_normal, 0, easing.outQuad)
	tab.text:TintTo(nil, self.colors.text_normal, 0, easing.outQuad)
	if tab.heart_back then tab.heart_back:TintTo(nil, self.colors.text_normal, 0, easing.outQuad) end
	if tab.completed_back then tab.completed_back:TintTo(nil, self.colors.text_normal, 0, easing.outQuad) end
	if tab.completed_front then tab.completed_front:TintTo(nil, self.colors.bg_normal, 0, easing.outQuad) end

	return tab
end

function ExpandingTabGroup:SetOnTabSizeChange(fn)
	self.onTabSizeChange = fn
	return self
end

return ExpandingTabGroup
