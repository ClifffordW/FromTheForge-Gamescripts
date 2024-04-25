local Text = require "widgets/text"
local Widget = require "widgets/widget"
local Image = require("widgets/image")

local PowerDescriptionWidget = require("widgets/ftf/powerdescriptionwidget")

local SkillIconWidget = require("widgets/skilliconwidget")
local PowerIconWidget = require("widgets/powericonwidget")
local FoodIconWidget = require("widgets/foodiconwidget")

local Power = require("defs.powers")
local itemforge = require "defs.itemforge"
local itemutil = require "util.itemutil"
local slotutil = require "defs.slotutil"

--------------------------------------------------------------------
-- A tooltip built specifically for showing power data & keywords related to the power.

local PowerKeyWordTooltip = Class(Widget, function(self)
	Widget._ctor(self)
end)

function PowerKeyWordTooltip:LayoutWithContent(data)
	self:RemoveAllChildren()

	self.keyword = slotutil.GetToolTipTable(data.keyword)

	self.bg = self:AddChild(Image("images/ui_ftf_relic_selection/relic_bg_blank.tex"))
		:ApplyMultColor(0, 0, 0, TOOLTIP_BG_ALPHA)
	
	self.container = self:AddChild(Widget())	

	self.title = self.container:AddChild(Text(FONTFACE.DEFAULT, FONTSIZE.TOOLTIP, self.keyword.NAME))
		:LeftAlign()
	
	self.description = self.container:AddChild(Text(FONTFACE.DEFAULT, FONTSIZE.SCREEN_TEXT, self.keyword.DESC))
		:SetGlyphColor(UICOLORS.LIGHT_TEXT)
		:LeftAlign()
		:EnableWordWrap(true)
		:SetAutoSize(data.width or 500)
		:SetVAlign(ANCHOR_TOP)
		:SetShadowColor(UICOLORS.BLACK)
		:SetOutlineColor(UICOLORS.BLACK)
		:EnableShadow()
		:EnableOutline()
		:SetShadowOffset(1, -1)
		:LayoutBounds("left", "below", self.title)

	local w, h = self.container:GetSize()
	self.bg:SetSize(w+25, h+25)
	self.container:LayoutBounds("center", "center", self.bg)	

	return true
end

local PowerTooltip = Class(Widget, function(self)
	Widget._ctor(self)

	self.padding = 5
end)

function PowerTooltip:LayoutWithContent( data )
	self:RemoveAllChildren()

	self.tooltips = nil -- will be recreated if we need this

	self.power = data.power
	self.def = self.power:GetDef()

	self.bg = self:AddChild(Image("images/ui_ftf_relic_selection/relic_bg_blank.tex"))
		:ApplyMultColor(0, 0, 0, TOOLTIP_BG_ALPHA)

	self.container = self:AddChild(Widget())

	local widget_type = PowerIconWidget
    if self.def.power_type == Power.Types.SKILL then
        widget_type = SkillIconWidget
    elseif self.def.power_type == Power.Types.FOOD then
        widget_type = FoodIconWidget
    end

	self.icon_widget = self.container:AddChild(widget_type())
		:SetScaleToMatchWidth(150)
		:SetPower(self.power)


	self.title = self.container:AddChild(Text(FONTFACE.DEFAULT, FONTSIZE.SCREEN_SUBTITLE, self.power:GetLocalizedName()))
		:LeftAlign()
        :SetRegionSize(480, 70)
        :EnableWordWrap(true)
        :ShrinkToFitRegion(true)
		:LayoutBounds("after", "top", self.icon_widget)
		:Offset(20, 0)

	local desc_width = 500

	self.power_desc = self.container:AddChild(PowerDescriptionWidget(desc_width, FONTSIZE.SCREEN_TEXT, self.power))
		:LayoutBounds("left", "below", self.title)
		:Offset(0, -self.padding)

	local w, h = self.container:GetSize()
	self.bg:SetSize(w+50, h+50)
	self.container:LayoutBounds("center", "center", self.bg)

	local tooltips = self.def.tooltips
	if tooltips and #tooltips > 0 then
		self.tooltips = self:AddChild(Widget("Keyword Tooltips"))
		for i,keyword in ipairs(tooltips) do
			local keyword_widget = PowerKeyWordTooltip()
			keyword_widget:LayoutWithContent({ keyword = keyword })
			self.tooltips:AddChild(keyword_widget)
		end

		self.tooltips:LayoutChildrenInColumn(self.padding, "left")
		self.tooltips:Hide()

		-- self.tooltips:LayoutBounds("after", "top", self.bg)

	end

	return true
end

function PowerTooltip:OnLayout(layout_x, layout_y)

	if self.tooltips then

		if layout_x == "before" then
			self.tooltips:LayoutChildrenInColumn(self.padding, "right")
		end

		self.tooltips:LayoutBounds(layout_x, layout_y, self.bg)
			:Show()
	end

end

return PowerTooltip