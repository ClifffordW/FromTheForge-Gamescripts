local Image = require("widgets/image")
local Text = require "widgets/text"
local Widget = require "widgets/widget"
local kassert = require "util.kassert"

--------------------------------------------------------------------
-- Basic tooltip, just a text label on a panelled background.

local Tooltip = Class(Widget, function(self, width)
	Widget._ctor(self)

	self.padding = 50

	-- Calculate content width
	width = width or DEFAULT_TT_WIDTH
	width = width - self.padding

	self.bg = self:AddChild(Image("images/ui_ftf_relic_selection/relic_bg_blank.tex"))
		:ApplyMultColor(0, 0, 0, TOOLTIP_BG_ALPHA)

	self.text = self:AddChild(Text(FONTFACE.DEFAULT, FONTSIZE.TOOLTIP))
		:SetAutoSize(width)
		:SetWordWrap(true)
		:LeftAlign()
		:OverrideLineHeight(FONTSIZE.TOOLTIP - 2) -- presumably to make them compact?
		:SetGlyphColor(UICOLORS.LIGHT_TEXT)

	self:Hide()
end)

Tooltip.LAYOUT_SCALE =
{
    [ScreenMode.s.MONITOR] = 1,
    [ScreenMode.s.TV] = 1.5,
    [ScreenMode.s.SMALL] = 1.5,
}

-- @returns whether the layout was successful (and should be displayed).
function Tooltip:LayoutWithContent(txt)
	kassert.typeof("string", txt)

	-- Update contents
	self.text:SetText(txt or "")

	-- Resize background to contents
	local w, h = self.text:GetSize()
	self.bg:SetSize(w + self.padding, h + self.padding)

	-- Layout
	self.text:LayoutBounds("center", "center", self.bg)

	return true
end

return Tooltip
