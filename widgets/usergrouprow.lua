local Clickable = require "widgets.clickable"
local Image = require "widgets.image"
local Text = require "widgets.text"
local fmodtable = require "defs.sound.fmodtable"

local UserGroupRow = Class(Clickable, function(self, width)
    Clickable._ctor(self, "UserGroupRow")

	-- Default values
	self.state = false
	self.width = width or 400
	self.icon_size = 60
	self.text_width = self.width - self.icon_size*2 - 20

	self.group_icon = self:AddChild(Image("images/ui_ftf_options/toggle_bg.tex"))
		:SetSize(self.icon_size, self.icon_size)
		:SetMultColor(UICOLORS.LIGHT_TEXT_DARK)
		:SetMultColorAlpha(0.15)

	self.group_name = self:AddChild(Text(FONTFACE.DEFAULT, FONTSIZE.SCREEN_TEXT))
		:SetGlyphColor(UICOLORS.LIGHT_TEXT_DARK)
		:SetWordWrap(true)
		:SetAutoSize(self.text_width)
		:LeftAlign()

	self.toggle_icon = self:AddChild(Image("images/ui_ftf_options/checkbox_unchecked.tex"))
		:SetSize(self.icon_size, self.icon_size)
		:SetMultColor(UICOLORS.LIGHT_TEXT_DARK)

	self:SetOnClick(function()
		self:SetValue(not self.state)
		if self.state then
			TheFrontEnd:GetSound():PlaySound(self.toggleon_sound)
		else
			TheFrontEnd:GetSound():PlaySound(self.toggleoff_sound)
		end
	end)

	self:SetControlDownSound(nil)
	self:SetControlUpSound(nil)

	self.toggleon_sound =  fmodtable.Event.ui_toggle_on
	self.toggleoff_sound = fmodtable.Event.ui_toggle_off

	self:Layout()
end)

function UserGroupRow:SetOnChangedFn(fn)
	self.onchangedfn = fn
	return self
end

-- Formerly GetValue
function UserGroupRow:IsChecked()
	return self.state
end

function UserGroupRow:SetValue(state)
	self.state = state
	self.toggle_icon:SetTexture(self.state and "images/ui_ftf_options/checkbox_checked.tex" or "images/ui_ftf_options/checkbox_unchecked.tex")
	self.group_name:SetGlyphColor(self.state and UICOLORS.BACKGROUND_LIGHT or UICOLORS.LIGHT_TEXT_DARK)
	self.toggle_icon:SetMultColor(self.state and UICOLORS.BACKGROUND_LIGHT or UICOLORS.LIGHT_TEXT_DARK)
	return self
end

function UserGroupRow:SetText(text)
	self.group_name:SetText(text)
	self:Layout()
	return self
end

function UserGroupRow:SetIcon(texture)
	if texture then
		self.group_icon:SetTexture(texture)
			:SetMultColor(UICOLORS.WHITE)
	else
		self.group_icon:SetTexture("images/ui_ftf_options/toggle_bg.tex")
			:SetMultColor(UICOLORS.LIGHT_TEXT_DARK)
			:SetMultColorAlpha(0.15)
	end
	return self
end

function UserGroupRow:Layout()
	self.group_icon:SetPos(0, 0)
	self.group_name:LayoutBounds("after", "center", self.group_icon):Offset(10, 0)
	self.toggle_icon:LayoutBounds("before", "center", self.group_icon):Offset(self.width, 0)
	return self
end

return UserGroupRow
