local Widget = require "widgets/widget"
local FollowPrompt = require "widgets.ftf.followprompt"
local Text = require "widgets.text"
local ItemWidget = require"widgets.ftf.itemwidget"
local Image = require"widgets.image"

local WeaponRackTooltip = Class(FollowPrompt, function(self, player)
	FollowPrompt._ctor(self, player)

	self:SetOffsetFromTarget(Vector3(0, 6, 0))
		:SetClickable(false)

	self.bg = self:AddChild(Image("images/ui_ftf_relic_selection/relic_bg_blank.tex"))
		:ApplyMultColor(0, 0, 0, TOOLTIP_BG_ALPHA)

	self.container = self:AddChild(Widget())

	self.slot_widget =	self.container:AddChild(ItemWidget(nil, nil, 200))
		:DisableToolTip(true)
		:HideQuantity()
		:Offset(20, -20)

	self.title = self.container:AddChild(Text(FONTFACE.DEFAULT, FONTSIZE.SCREEN_SUBTITLE))
		:LeftAlign()
        :SetRegionSize(480, 70)
        :EnableWordWrap(true)
        :ShrinkToFitRegion(true)

	self.price_text = self.container:AddChild(Text(FONTFACE.DEFAULT, FONTSIZE.SCREEN_SUBTITLE))
        :SetRegionSize(200, 70)
        :EnableWordWrap(true)
        :ShrinkToFitRegion(true)

	self.flavor = self.container:AddChild(Text(FONTFACE.DEFAULT, FONTSIZE.SCREEN_TEXT, "", UICOLORS.LIGHT_TEXT_DARK))
		:LeftAlign()
		:SetAutoSize(480)

	-- self.equipment_desc = self.container:AddChild(EquipmentDescriptionWidget(500, FONTSIZE.SCREEN_TEXT))
end)

function WeaponRackTooltip:SetPriceText(price_text)
	self.price_text:SetText(price_text)
end

function WeaponRackTooltip:SetItemDef(item_def)
	local rarity = item_def.rarity or "COMMON"
	local item_name = string.format("<#%s>%s</>", rarity, item_def.pretty.name)

	self.title:SetText(item_name)
		:LayoutBounds("after", "top", self.slot_widget)
		:Offset(20, -10)

	self.price_text:LayoutBounds("center", "below", self.slot_widget)
		:Offset(0, -5)

	self.slot_widget:SetItem(item_def)

	self.flavor:SetText(string.format("<i>%s</>", item_def.pretty.desc))
		:LayoutBounds("left", "below", self.title)

	self:Layout()
end

function WeaponRackTooltip:Layout()
	local w, h = self.container:GetSize()
	self.bg:SetSize(w + 50, h + 50)
	self.bg:SetPosition(0, 0)
	self.container:LayoutBounds("center", "center", self.bg)
end

function WeaponRackTooltip:SetProgress(progress)
	local next_reward = progress:GetNextReward()
	if next_reward then
		self:SetItemDef(next_reward.def)
	end
	self:Layout()
end

function WeaponRackTooltip:RefreshMetaProgress(meta_progress)
end

function WeaponRackTooltip:OnExpGranted(exp_events, on_progress_fn)
end

return WeaponRackTooltip
