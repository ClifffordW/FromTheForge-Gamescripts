------------------------------------------------------------------------------------------
--- Displays a puppet that's player selectable
local Clickable = require "widgets.clickable"
local Image = require "widgets.image"
local Panel = require "widgets.panel"
local Text = require "widgets.text"

local easing = require "util.easing"
----

local SelectableItemColor = Class(Clickable, function(self)
	Clickable._ctor(self, "SelectableItemColor")

	self.width = 80
	self.height = 88
	self.lock_size = self.width * 0.6

	-- Clickable hitbox
	self.hitbox = self:AddChild(Image("images/global/square.tex"))
		:SetName("Hitbox")
		:SetSize(self.width, self.height)
		:SetMultColor(UICOLORS.DEBUG)
		:SetMultColorAlpha(0.0)

	-- Tintable button image
	self.image = self:AddChild(Image("images/ui_ftf_character/ColorButton.tex"))
		:SetName("Image")
		:SetHiddenBoundingBox(true)
		:SetSize(self.width, self.height)

	-- Selection underline
	self.selection_underline = self:AddChild(Panel("images/ui_ftf_character/SelectionUnderline.tex"))
		:SetName("Selection underline")
		:SetHiddenBoundingBox(true)
		:SetNineSliceCoords(4, 0, 16, 15)
		:SetSize(self.width - 8, 15)
		:SetMultColorAlpha(0)
		:LayoutBounds("center", "below", self.image)
		:Offset(0, -5)

	-- Lock badge, if unavailable
	self.lock_badge = self:AddChild(Image("images/ui_ftf_character/LockBadge.tex"))
		:SetName("Lock badge")
		:SetHiddenBoundingBox(true)
		:SetSize(self.lock_size, self.lock_size)

	self.focus_brackets = self:AddChild(Panel("images/ui_ftf_crafting/RecipeFocus.tex"))
		:SetName("Focus brackets")
		:SetHiddenBoundingBox(true)
		:SetNineSliceCoords(54, 56, 54, 56)
		:SetSize(self.width + 30, self.height + 30)
		:SetMultColorAlpha(0)
		:LayoutBounds("center", "center", self.hitbox)
		:Offset(0, 0)

	return self
end)

function SelectableItemColor:OnFocusChange(has_focus)
	-- self.image:MoveTo(0, has_focus and 6 or 0, has_focus and 0.1 or 0.3, easing.outQuad)
	-- self.lock_badge:MoveTo(0, has_focus and 6 or 0, has_focus and 0.15 or 0.35, easing.outQuad)
	self.focus_brackets:AlphaTo(has_focus and 1 or 0, 0.1, easing.outQuad)
	return self
end

function SelectableItemColor:SetCost(cost)
	self.cost = cost
	return self
end

function SelectableItemColor:SetLocked(is_locked)
	self.is_locked = is_locked

	self.lock_badge:SetShown(self.is_locked)
	return self
end

function SelectableItemColor:SetImageColor(color)
	self.image:SetMultColor(table.unpack(color))
	return self
end

function SelectableItemColor:SetItemColorId(color_id)
	self.color_id = color_id
	return self
end

function SelectableItemColor:GetItemColorId()
	return self.color_id
end

function SelectableItemColor:SetSelected(is_selected)
	self.selected = is_selected
	self.selection_underline:AlphaTo(self.selected and 1 or 0, self.selected and 0.1 or 0.3, easing.outQuad)
	return self
end

function SelectableItemColor:IsSelected()
	return self.selected
end

return SelectableItemColor
