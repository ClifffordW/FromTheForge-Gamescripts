------------------------------------------------------------------------------------------
--- Displays a puppet that's player selectable
local Clickable = require "widgets.clickable"
local Widget = require "widgets.widget"
local Image = require "widgets.image"
local Panel = require "widgets.panel"
local Text = require "widgets.text"
local ImageCheckBox = require "widgets.imagecheckbox"
local ActionButton = require "widgets.actionbutton"
local fmodtable = require "defs.sound.fmodtable"

local easing = require "util.easing"
----

local SelectablePlayerTitle = Class(Clickable, function(self, width, height)
	Clickable._ctor(self, "SelectablePlayerTitle")

	self.width =  width or 400
	self.height = height or 250
	self.lock_size = 60

	self.normal_bg_color = HexToRGB(0xA5908333) -- 20%
	self.selected_bg_color = HexToRGB(0xFFFFFF80) -- 50%

	-- Clickable hitbox
	self.hitbox = self:AddChild(Image("images/global/square.tex"))
		:SetName("Hitbox")
		:SetSize(self.width, self.height)
		:SetMultColor(UICOLORS.DEBUG)
		:SetMultColorAlpha(0.0)

	-- Tintable button image
	self.image = self:AddChild(Image("images/ui_ftf_character/ItemBg.tex"))
		:SetName("Image")
		:SetHiddenBoundingBox(true)
		:SetSize(self.width, self.height)
		:SetMultColor(self.normal_bg_color)

	self.title_label = self:AddChild(Text(FONTFACE.DEFAULT, FONTSIZE.CHARACTER_CREATOR_TAB, "TITLE TITLE TITLE"))
		:LayoutBounds("center", "center")
		:SetHiddenBoundingBox(true)
		:SetGlyphColor(UICOLORS.BLACK)
		--:Offset(10, 0)

	-- Lock badge, if unavailable
	self.lock_badge = self:AddChild(Image("images/ui_ftf_character/LockBadge.tex"))
		:SetName("Lock badge")
		:SetHiddenBoundingBox(true)
		:SetSize(self.lock_size, self.lock_size)
		:LayoutBounds("right", "bottom", self.image)
		:Offset(-20, 20)

	-- Focus brackets
	self.focus_brackets = self:AddChild(Panel("images/ui_ftf_crafting/RecipeFocus.tex"))
		:SetName("Focus brackets")
		:SetHiddenBoundingBox(true)
		:SetNineSliceCoords(54, 56, 54, 56)
		:SetSize(self.width + 30, self.height + 30)
		:SetMultColorAlpha(0)
		:LayoutBounds("center", "center", self.hitbox)
		:Offset(0, 0)

	-- Setup interactions
	self:SetOnGainFocus(function() self:OnFocusChange(true) end)
	self:SetOnLoseFocus(function() self:OnFocusChange(false) end)

	return self
end)

function SelectablePlayerTitle:OnFocusChange(has_focus)
	self.focus_brackets:AlphaTo(has_focus and 1 or 0, has_focus and 0.1 or 0.3, easing.outQuad)
	return self
end

function SelectablePlayerTitle:SetTitle(def)
	self.title_key = def.title_key
	self.title_label:SetText(STRINGS.COSMETICS.TITLES[self.title_key])
	return self
end

function SelectablePlayerTitle:SetCost(cost)
	self.cost = cost
	return self
end

function SelectablePlayerTitle:GetTitleKey()
	return self.title_key
end

function SelectablePlayerTitle:SetLocked(is_locked)
	self.is_locked = is_locked

	self.lock_badge:SetShown(self.is_locked)
	if self.is_locked then
		self.title_label:SetGlyphColor(UICOLORS.LIGHT_TEXT_DARK)
		local str = STRINGS.COSMETICS.TITLES[self.title_key]
		local locked_str = ""
		for i=1, string.len(str) do
			local char = str:sub(i,i)
			if char ~= " " then
				locked_str = locked_str .. "?"
			else
				locked_str = locked_str .. " "
			end
		end

		self.title_label:SetText(locked_str)

	end
	return self
end

function SelectablePlayerTitle:SetSelected(is_selected)
	self.selected = is_selected
	self.image:TintTo(nil, self.selected and self.selected_bg_color or self.normal_bg_color, self.selected and 0.1 or 0.3, easing.outQuad)
	return self
end

function SelectablePlayerTitle:IsSelected()
	return self.selected
end

return SelectablePlayerTitle