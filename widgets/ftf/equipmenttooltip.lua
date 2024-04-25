local Text = require "widgets/text"
local Widget = require "widgets/widget"
local Image = require("widgets/image")
local DisplayStat = require("widgets/ftf/displaystat")
local ItemWidget = require"widgets.ftf.itemwidget"
local PowerDescriptionWidget = require("widgets/ftf/powerdescriptionwidget")
local SkillWidget = require"widgets.ftf.skillwidget"

-- local EquipmentDescriptionWidget = require"widgets.ftf.equipmentdescriptionwidget"

local itemutil = require "util.itemutil"

local Power = require("defs.powers")
local itemforge = require "defs.itemforge"
--------------------------------------------------------------------
-- A tooltip built specifically for showing equipment data

local EquipmentStats = Class(Widget, function(self, hide_deltas)
	Widget._ctor(self)
	self.hide_deltas = hide_deltas
	self.stats_container = self:AddChild(Widget())
end)

function EquipmentStats:SetItem(item, player)
	self.stats_container:RemoveAllChildren()

	if item == nil then
		return self
	end

	local stats_delta, stats = player.components.inventoryhoard:DiffStatsAgainstEquipped(item, item:GetDef().slot)	

	if self.hide_deltas then
		for k, v in pairs(stats_delta) do
			stats_delta[k] = 0
		end
	end

	local stats_data = itemutil.BuildStatsTable(stats_delta, stats, item:GetDef().slot)

	--jcheng: for some reason, if we don't do this, the SetStyle_EquipmentPanel gives an incorrect
	-- value for the final value. BUT I don't want to change the algo because it's used elsewhere...
	for _, v in ipairs(stats_data) do
		if v.delta ~= 0 then
			v.value = v.value - v.delta
		end
	end
	self:AddStats(stats_data)

	return self
end

function EquipmentStats:AddStats(stats_data)
	local max_width = 320
	local icon_size = 110
	local text_size = 100
	local delta_size = 100

	for id, data in pairs(stats_data) do
		-- Display stat widget
		self.stats_container:AddChild(DisplayStat(max_width, icon_size, text_size, delta_size))
			:SetStyle_EquipmentPanel()
			:ShouldShowToolTip(false)
			:ShowName(false)
			:SetStat(data)
	end

	self.stats_container:LayoutChildrenInColumn(20)

	return self
end

local EquipmentTooltip = Class(Widget, function(self)
	Widget._ctor(self)
end)

function EquipmentTooltip:SetPlayer(player)
	self.player = player

	self.stats_desc
		:SetItem(self.item, player)
		:LayoutBounds("after", "top", self.title)
		:Offset(20, -20)

	local w, h = self.container:GetSize()
	self.bg:SetSize(w+50, h+50)

	self.container:LayoutBounds("center", "center", self.bg)
end

function EquipmentTooltip:LayoutWithContent( data )
	self:RemoveAllChildren()

	self.item = data.item
	self.def = self.item:GetDef()
	self.hide_deltas = data.hide_deltas

	self.bg = self:AddChild(Image("images/ui_ftf_relic_selection/relic_bg_blank.tex"))
		:ApplyMultColor(0, 0, 0, TOOLTIP_BG_ALPHA)

	self.container = self:AddChild(Widget())

	self.slot_widget =	self.container:AddChild( ItemWidget(nil, nil, 200) )
		:DisableToolTip(true)
		:SetItem(self.item:GetDef(), 1)
		:HideQuantity()
		:Offset(20, -20)

	local def = self.item:GetDef()
	local rarity = def.rarity or "COMMON"
	local item_name = string.format("<#%s>%s</>", rarity, self.item:GetLocalizedName())

	local padding = 5

	self.title = self.container:AddChild(Text(FONTFACE.DEFAULT, FONTSIZE.SCREEN_SUBTITLE, item_name))
		:LeftAlign()
        :SetRegionSize(480, 70)
        :EnableWordWrap(true)
        :ShrinkToFitRegion(true)
		:LayoutBounds("after", "top", self.slot_widget)
		:Offset(20, -10)

	local desc_width = 500

	local showing_power = false
	if self.def.usage_data.power_on_equip then
		local usagelvl = self.item:GetUsageLevel()
		local power_def = Power.FindPowerByName(def.usage_data.power_on_equip)
		local power = itemforge.CreatePower(power_def)
		local current_stacks = power_def.stacks_per_usage_level and power_def.stacks_per_usage_level[usagelvl]
		power.stacks = current_stacks

		self.power_desc = self.container:AddChild(PowerDescriptionWidget(desc_width, FONTSIZE.SCREEN_TEXT, power, false, true))
			:LayoutBounds("left", "below", self.title)
			:Offset(0, -padding)

		showing_power = true
	end

	if not showing_power and self.def.usage_data.power then
		local power_def = Power.FindPowerByName(def.usage_data.power)
		local power = itemforge.CreatePower(power_def)

		self.power_desc = self.container:AddChild(PowerDescriptionWidget(desc_width, FONTSIZE.SCREEN_TEXT, power))
			:LayoutBounds("left", "below", self.title)
			:Offset(0, -padding)

		showing_power = true
	end

	local showing_skill = false
	if self.def.usage_data.skill_on_equip then
		showing_skill = true
		local skill_def = Power.FindPowerByName(def.usage_data.skill_on_equip)
		local skill = itemforge.CreatePower(skill_def)

		local icon_size = 133


		if not showing_power then
			-- we don't have much space to show this info
			icon_size = 66
			desc_width = desc_width - icon_size - padding
		end

		self.skill_icon = self.container:AddChild(SkillWidget(icon_size, data.player, skill))
		self.skill_text = self.container:AddChild(Widget("Skill Text"))
		self.skill_title = self.skill_text:AddChild(Text(FONTFACE.DEFAULT, self.text_size, skill_def.pretty.name, UICOLORS.LIGHT_TEXT))
		self.skill_desc = self.skill_text:AddChild(PowerDescriptionWidget(desc_width, self.text_size, skill, false, false))
			:LayoutBounds("left", "below", self.skill_title)
			:Offset(0, -padding)

		if showing_power then

			local s_w, s_h = self.slot_widget:GetSize()

			local d_x1, d_y1, d_x2, d_y2 = self:CalculateBoundingBox(self.title, self.power_desc)

			local d_w, d_h = math.abs(d_x2 - d_x1), math.abs(d_y2 - d_y1)

			d_h = d_h + 15 -- total of 15 px of padding for these widgets compared to slot

			if d_h > s_h then
				-- description is larger, layout relative to it.
				self.skill_text:LayoutBounds("left", "below", self.power_desc)
					:Offset(0, -padding)
				self.skill_icon:LayoutBounds(nil, "center", self.skill_text)
				self.skill_icon:LayoutBounds("center", nil, self.slot_widget)
			else
				-- slot widget is larger, layout relative to it.

				s_w, s_h = self.skill_icon:GetSize()
				d_w, d_h = self.skill_text:GetSize()

				if s_h > d_h then
					-- icon is larger, layout text relative to it
					self.skill_icon:LayoutBounds("center", "below", self.slot_widget)
						:Offset(0, -padding)
					self.skill_text:LayoutBounds("left", nil, self.power_desc)
					self.skill_text:LayoutBounds(nil, "center", self.skill_icon)
				else
					-- description is larger, layout icon relative to it

					self.skill_text:LayoutBounds("left", nil, self.power_desc)
					self.skill_text:LayoutBounds(nil, "below", self.slot_widget)
					self.skill_icon:LayoutBounds(nil, "center", self.skill_text)
					self.skill_icon:LayoutBounds("center", nil, self.slot_widget)

				end
			end

		else
			self.skill_icon:LayoutBounds("left", "below", self.title)
				:Offset(0, -padding)
			self.skill_text:LayoutBounds("after", "top", self.skill_icon)
				:Offset(padding, 0)
		end


	-- 	local skill_icon_size = 66

	-- 	self.skill_icon = self.skill_root:AddChild(SkillWidget(skill_icon_size, self:GetOwningPlayer(), power))
	-- 	self.skill_title = self.skill_root:AddChild(Text(FONTFACE.DEFAULT, self.text_size, power_def.pretty.name, UICOLORS.LIGHT_TEXT))
	-- 		:LayoutBounds("after", "top", self.skill_icon)
	-- 		:Offset(10, 0)
	-- 	self.skill_desc = self.skill_root:AddChild(Text(FONTFACE.DEFAULT, self.text_size, Power.GetDescForPower(power), UICOLORS.LIGHT_TEXT))
	-- 		:SetAutoSize(self.width - skill_icon_size)
	-- 		:LeftAlign()
	-- 		:LayoutBounds("left", "below", self.skill_title)
	-- 		:Offset(0, -10)

	end

	-- self.equipment_desc = self.container:AddChild(EquipmentDescriptionWidget(500, FONTSIZE.SCREEN_TEXT))
	-- 	:SetItem(self.item)
	-- 	:LayoutBounds("left", "below", self.title)
	-- 	:Offset(0, -5)

	local w, h = self.container:GetSize()
	self.bg:SetSize(w+50, h+50)
	-- self.bg:SizeToWidgets(50, self.container)

	self.container:LayoutBounds("center", "center", self.bg)

	self.stats_desc = self.container:AddChild(EquipmentStats(self.hide_deltas))

	self.stats_desc
		:SetScale(0.6)

	self:SetPlayer(data.player)

	return true
end

return EquipmentTooltip