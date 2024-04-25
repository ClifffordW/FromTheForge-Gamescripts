local Widget = require("widgets/widget")
local Image = require('widgets/image')
local ItemTooltip = require "widgets/itemtooltip"
local Text = require('widgets/text')

local LockedMetaRewardWidget = Class(Widget, function(self, size, owner, item, count, show_bg)
	Widget._ctor(self, "LockedMetaRewardWidget")
	self.owner = owner
	self.item = item
	self.def = item:GetDef()

	size = size or 70

	local icon = self:AddChild(Image(self.def.icon))
		:SetSize(size, size)

	if count then
		icon:AddChild(Text(FONTFACE.DEFAULT, 60, count, UICOLORS.LIGHT_TEXT))
			:EnableOutline(true)
			:EnableShadow(true)
			:LayoutBounds("after", "top", icon)
			:Offset(-25, -25)
	end

	-- self:SetToolTipClass(ItemTooltip)
	-- self:SetToolTip({ item = item, player = owner })

	if show_bg then
		local bg = self:AddChild(Image("images/ui_ftf_relic_selection/relic_bg_blank.tex"))
			:ApplyMultColor(0, 0, 0, TOOLTIP_BG_ALPHA)
			:SendToBack()

		local w, h = icon:GetSize()
		bg:SetSize(w+10, h)
		icon:LayoutBounds("center", "center", bg)
	end

	self:SetClickable(false)

end)

return LockedMetaRewardWidget