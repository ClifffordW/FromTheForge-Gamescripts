local Image = require("widgets/image")
local slotutil = require "defs.slotutil"
local Power = require "defs.powers"
local PowerIconWidget = require("widgets/powericonwidget")
local RoomBonusButtonTitle = require("widgets/ftf/roombonusbuttontitle")
local SkillIconWidget = require("widgets/skilliconwidget")
local Text = require("widgets/text")
local Widget = require("widgets/widget")
local easing = require "util.easing"


--- Common base for displaying a power and its description in a clickable button.
--
-- Doesn't have any player-specific functionality or screen logic. Just
-- displays a power and its information.
local WorldPowerTooltip = Class(Widget, function(self, width, height)
	Widget._ctor(self, "WorldPowerTooltip")

    -- Set default size
    self.width = width or 600
    self.height = height or 250
    self.x_padding = 45
    self.y_padding = 30

	self.image = self:AddChild(Image("images/ui_ftf_relic_selection/relic_bg_blank.tex"))
		:SetSize(self.width, self.height)
		:ApplyMultColor(0, 0, 0, TOOLTIP_BG_ALPHA)

    -- Add text contents
    self.textContainer = self.image:AddChild(Widget())

	self.title = self.textContainer:AddChild(Text(FONTFACE.DEFAULT, FONTSIZE.INWORLD_POWER_DESCRIPTION))
		:SetText("Title")

	self.description = self.textContainer:AddChild(Text(FONTFACE.DEFAULT, FONTSIZE.INWORLD_POWER_DESCRIPTION))
		:SetGlyphColor(UICOLORS.LIGHT_TEXT)
		:LeftAlign()
		:EnableWordWrap(true)
		:SetRegionSize(self.width * 0.85, self.height)
		-- :ShrinkToFitRegion(true)
		:SetVAlign(ANCHOR_TOP)
		:SetShadowColor(UICOLORS.BLACK)
		:SetOutlineColor(UICOLORS.BLACK)
		:EnableShadow()
		:EnableOutline()
		:SetShadowOffset(1, -1)
end)

function WorldPowerTooltip:SetTooltip(key)
	local tt = slotutil.GetToolTipTable(key)

	self.title:SetText(tt.NAME)
	self.description:SetText(tt.DESC)

	self:_Layout()
end

function WorldPowerTooltip:_Layout()
	local w, h = self.width, self.height

	self.description:SetRegionSize(w * 0.85, h)

	if self.description:GetLines() == 1 then
		self.image:SetSize(w, h * 0.75)
	elseif self.description:GetLines() == 2 then
		self.image:SetSize(w, h)
	elseif self.description:GetLines() == 3 then
		self.image:SetSize(w, h * 1.175)
	elseif self.description:GetLines() == 4 then
		self.image:SetSize(w, h * 1.35)
	else
		error("Tooltips of more than 4 lines not supported: ".. self.description:GetLines())
	end

	self.textContainer:LayoutBounds("left", "top", self.image)
		:Offset(self.x_padding, -self.y_padding)

	self.title:LayoutBounds("left", "top", self.textContainer)
	self.description:LayoutBounds("left", "below", self.title)

end

function WorldPowerTooltip:RefreshLayout()
	self.description:LayoutBounds("left", "below", self.title)
end

function WorldPowerTooltip:GetPower()
	return self.power
end

return WorldPowerTooltip
