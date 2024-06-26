local Widget = require("widgets/widget")
local Clickable = require("widgets/clickable")
local Panel = require ("widgets/panel")
local Image = require ("widgets/image")
local Text = require ("widgets/text")
local ActionButton = require ("widgets/actionbutton")

local easing = require "util.easing"

----------------------------------------------------------------------
-- Fancier buttons for menus

local MenuButton = Class(Clickable, function(self, width, height)
	Clickable._ctor(self, "MenuButton")

    self:SetScales(1, 1.03, 1, 0.1, 0.2)

	self.width = width or 700
	self.height = height or 400

	self.padding = 60
	self.max_text_width = self.width - self.padding*2
	self.text_aligned_to_top = true -- false aligns to bottom

	self.bg = self:AddChild(Panel("images/ui_ftf_multiplayer/multiplayer_btn_friends.tex"))
		:SetName("Background")
		:SetNineSliceCoords(70, 180, 600, 190)
		:SetSize(self.width, self.height)

	self.text_container = self:AddChild(Widget())
		:SetName("Text container")

	self.title_label = self.text_container:AddChild(Text(FONTFACE.DEFAULT, FONTSIZE.MENU_BUTTON_TITLE))
		:SetGlyphColor(UICOLORS.BACKGROUND_DARK)
		:SetHAlign(ANCHOR_LEFT)
		:SetAutoSize(self.max_text_width)

	self.text_label = self.text_container:AddChild(Text(FONTFACE.DEFAULT, FONTSIZE.MENU_BUTTON_TEXT))
		:SetGlyphColor(UICOLORS.BACKGROUND_DARK)
		:SetHAlign(ANCHOR_LEFT)
		:SetAutoSize(self.max_text_width)

end)

function MenuButton:SetTexture(tex)
	self.bg:SetTexture(tex)
	return self
end

function MenuButton:SetNineSliceCoords(minx, miny, maxx, maxy)
	self.bg:SetNineSliceCoords(minx, miny, maxx, maxy)
	return self
end

function MenuButton:SetText(title, text)
	self.title_label:SetText(title)
		:SetShown(title)
	self.text_label:SetText(text)
		:SetShown(text)
	self:Layout()
	return self
end

function MenuButton:SetTextColor(title, text)
	if title then self.title_label:SetGlyphColor(title) end
	if text then self.text_label:SetGlyphColor(text) end
	return self
end

-- Try to resize to fit the title on a single line, but limited to 150% of original size.
function MenuButton:ResizeToFitTitle(horizontal_padding, vertical_padding)
	self.title_label:EnableWordWrap(false)
	local w,h = self.text_container:GetSize()

	w = w + (horizontal_padding or 140)
	h = h + (vertical_padding or 80)

	w = math.max(w, self.width)
	h = math.max(h, self.height, BUTTON_H)

	-- Don't let the button grow too large.
	w = math.min(w, self.width * 1.5)
	h = math.min(h, self.height * 1.5)
	self.title_label:EnableWordWrap(true) -- in case of size capping

	self.bg:SetSize(w,h)
	self:SetTextWidth(w - self.padding*2)
	return self
end

function MenuButton:SetTextWidth(max_width)
	self.max_text_width = max_width or (self.width - self.padding*2)
	self.title_label:SetAutoSize(self.max_text_width)
	self.text_label:SetAutoSize(self.max_text_width)
	self:Layout()
	return self
end

function MenuButton:SetTextAlignedToBottom()
	self.text_aligned_to_top = false
	self:Layout()
	return self
end

function MenuButton:AddImage(img, w, h)

	w = w or self.width
	h = h or self.width

	self.img = self:AddChild(Image(img))
		:SetName("Image")
		:SetSize(w, h)
		:LayoutBounds("center", "bottom", self.bg)

	return self
end

function MenuButton:Layout()
	self.text_container:LayoutChildrenInColumn(5, "left")
		:LayoutBounds("left", self.text_aligned_to_top and "top" or "bottom", self.bg)
		:Offset(self.padding, self.text_aligned_to_top and -self.padding or self.padding)
	return self
end

return MenuButton
