local Widget = require("widgets/widget")
local Text = require("widgets/text")
local Image = require("widgets/image")
local PowerDescriptionWidget = require("widgets/ftf/powerdescriptionwidget")

local itemforge = require("defs/itemforge")
local Consumable = require("defs/consumable")
local Power = require("defs/powers")

--------------------------------------------------------------------
-- A tooltip built specifically for showing heart data

local HeartTooltip = Class(Widget, function(self)
	Widget._ctor(self)
	self.bg_padding = 50
end)

function HeartTooltip:_ResizeBG()
	local w, h = self.container:GetSize()
	self.bg:SetSize(w+self.bg_padding, h+self.bg_padding)
	self.container:LayoutBounds("center", "center", self.bg)
end

-- data = {
-- 	player = which player to reference
-- 	heart_data = from the heartmanager.data.hearts table
--  show_upgrade = show what will happen if you upgrade
-- }

function HeartTooltip:LayoutWithContent( data )
	self:RemoveAllChildren()

	self.player = data.player
	self.heart_def = Consumable.FindItem(data.heart_data.heart_id)

	self.power_def = Power.FindPowerByName(data.heart_data.power)

	self.heart_level = self.player.components.heartmanager:GetHeartLevelForHeartID(data.heart_data.heart_id)

	self.current_stacks = self.heart_level * data.heart_data.stacks_per_level
	self.max_stacks = self.power_def.max_stacks

	self.max_level = math.round(self.max_stacks / data.heart_data.stacks_per_level)

	if self.heart_level == self.max_level then
		data.show_upgrade = false
	end

	self.power = itemforge.CreatePower(self.power_def)
	self.power.stacks = self.current_stacks

	self.bg = self:AddChild(Image("images/ui_ftf_relic_selection/relic_bg_blank.tex"))
		:ApplyMultColor(0, 0, 0, TOOLTIP_BG_ALPHA)

	self.container = self:AddChild(Widget())

	self.icon =	self.container:AddChild( Image(data.heart_data.icon) )
		:SetSize(200, 200)
		:Offset(20, -20)

	local heart_name = string.format("<#%s>%s</>", self.heart_def.rarity, self.power:GetLocalizedName())

	self.title = self.container:AddChild(Text(FONTFACE.DEFAULT, FONTSIZE.SCREEN_SUBTITLE, heart_name))
		:LeftAlign()
        :SetRegionSize(480, 70)
        :EnableWordWrap(true)
        :ShrinkToFitRegion(true)
		:LayoutBounds("after", "top", self.icon)
		:Offset(20, -10)

	local preview_stacks = nil

	if data.show_upgrade then
		preview_stacks = data.heart_data.stacks_per_level * (self.heart_level + 1)
	end

	self.power_desc = self.container:AddChild(PowerDescriptionWidget(500, FONTSIZE.SCREEN_TEXT))
		:SetPower(self.power, preview_stacks, true)
		:LayoutBounds("left", "below", self.title)
		:Offset(0, -5)

	local level_str = STRINGS.UI.HEARTTOOLTIP.HEART_LEVEL:subfmt({
				current = self.heart_level,
				max = self.max_level,
			})

	if data.show_upgrade then
		level_str = STRINGS.UI.HEARTTOOLTIP.HEART_LEVEL_UPGRADE:subfmt({
				new = self.heart_level + 1,
				max = self.max_level,
			})
	end

	-- current level widget
	self.container:AddChild(Text(FONTFACE.DEFAULT, FONTSIZE.SCREEN_TEXT, level_str, UICOLORS.DARK_TEXT))
		:RightAlign()
        :SetRegionSize(480, 70)
		:LayoutBounds("right", nil, self.title)
		:LayoutBounds(nil, "below", self.power_desc)

	self:_ResizeBG()

	return true
end

return HeartTooltip