local Widget = require("widgets/widget")
local Text = require("widgets/text")
local Power = require("defs/powers")

local lume = require("util/lume")
local EquipmentStatDisplay = require("defs/equipmentstatdisplay")

local PowerVariableWidget = Class(Widget, function(self, width, text_size)
	Widget._ctor(self, "UpgradeableItem")

	self.text_size = text_size or 33
	self.width = width or 200

	self.label = self:AddChild(Text(FONTFACE.DEFAULT, self.text_size, "NAME", UICOLORS.LIGHT_TEXT))
		:LeftAlign()
	self.value = self:AddChild(Text(FONTFACE.DEFAULT, self.text_size, 1, UICOLORS.LIGHT_TEXT))
		:LeftAlign()
		:LayoutBounds("before", "center", self.label)
		:Offset(self.width, 0)
end)

function PowerVariableWidget:Refresh(power, var, compare_stacks)
	local name, old_val = power:GetPrettyVar(var)
	local str = ("%s"):format(old_val)

	if compare_stacks then
		local start_stacks = power.stacks
		power.stacks = compare_stacks
		local _, new_val = power:GetPrettyVar(var)
		power.stacks = start_stacks

		if new_val ~= old_val then
			str = ("%s  <#BONUS_LIGHT_BG><p img='images/ui_ftf/arrow_right.tex' color=0 scale=0.4>  %s</>"):format(old_val, new_val)
		end
	end

	self.label:SetText(("%s %s"):format(STRINGS.UI.BULLET_POINT, name))
	self.value:SetText(str)
	self:_Layout()
end

-- Creates a widget with equal-width columns for each level in a row
function PowerVariableWidget:GenerateMultiLevelHeaderWidget(stat_levels, current_level)
	local column_width, column_height = 110, 40
	local divider = "  <p img='images/ui_ftf/arrow_right.tex' color=0 scale=0.4>" -- Suffixed at the end of columns
	local row = Widget("Multi-level header widget container")

	local text = ""
	for level, v in ipairs(stat_levels) do
		text = ""

		if level == current_level then
			text = text .. "<#GEM>"
		end

		text = text .. STRINGS.ITEMS.GEMS.ILVL_TO_NAME[level]

		if level == current_level then
			text = text .. "</>"
		end

		-- Add an arrow on every level except the last one
		if level < #stat_levels then
			text = text .. divider
		end

		row:AddChild(Text(FONTFACE.DEFAULT, self.text_size or FONTSIZE.SCREEN_TEXT, text, UICOLORS.DARK_TEXT))
			:RightAlign()
			:SetRegionSize(column_width, column_height)

	end

	row:LayoutChildrenInRow(0)

	return row
end

-- Creates a widget with equal-width columns for each level in a row
function PowerVariableWidget:GenerateMultiLevelStatWidget(stat_id, stat_levels, current_level)
	local column_width, column_height = 110, 40
	local divider = "  <p img='images/ui_ftf/arrow_right.tex' color=0 scale=0.4>" -- Suffixed at the end of columns
	local row = Widget()
		:SetName("Multi-level stat widget container")

	local text = ""
	for level, v in ipairs(stat_levels) do
		text = ""

		if level == current_level then
			text = text .. "<#GEM>"
		end

		local value = stat_levels[level]
		if EquipmentStatDisplay[stat_id] and EquipmentStatDisplay[stat_id].percent then
			value = value * 100
			value = lume.round(value, 0.1)

			if lume.round(value) == value then
				value = lume.round(value)
			end

			value = value.."%"
		end
		text = text .. value

		if level == current_level then
			text = text .. "</>"
		end

		-- Add an arrow on every level except the last one
		if level < #stat_levels then
			text = text .. divider
		end

		row:AddChild(Text(FONTFACE.DEFAULT, self.text_size or FONTSIZE.SCREEN_TEXT, text, UICOLORS.LIGHT_TEXT_DARKER))
			:RightAlign()
			:SetRegionSize(column_width, column_height)

	end

	row:LayoutChildrenInRow(0)

	return row
end

function PowerVariableWidget:GenerateMultiLevelPowerWidget(stat_levels, current_level)

	local column_width, column_height = 110, 40
	local divider = "  <p img='images/ui_ftf/arrow_right.tex' color=0 scale=0.4>" -- Suffixed at the end of columns
	local row = Widget()
		:SetName("Multi-level stat widget container")

	local text = ""
	for level, v in ipairs(stat_levels) do
		text = ""

		if level == current_level then
			text = text .. "<#GEM>"
		end

		local value = stat_levels[level]
		text = text .. value

		if level == current_level then
			text = text .. "</>"
		end

		-- Add an arrow on every level except the last one
		if level < #stat_levels then
			text = text .. divider
		end

		row:AddChild(Text(FONTFACE.DEFAULT, self.text_size or FONTSIZE.SCREEN_TEXT, text, UICOLORS.LIGHT_TEXT))
			:RightAlign()
			:SetRegionSize(column_width, column_height)

	end

	row:LayoutChildrenInRow(0)

	return row
end

function PowerVariableWidget:SetGemStat(stat_id, stat_levels, current_level)
	self.label:SetText(STRINGS.UI.EQUIPMENT_STATS[string.upper(stat_id)].name)

	self.value:SetText("")
	if self.value_row then self.value_row:Remove() end
	self.value_row = self:AddChild(self:GenerateMultiLevelStatWidget(stat_id, stat_levels, current_level))

	self:_Layout()
	return self
end

function PowerVariableWidget:SetGemPower(power, stat_levels, gem)
	local rarity = power:GetRarity()
	local def = power:GetDef()

	local processed_stat_levels = {}
	for lvl,stacks in ipairs(stat_levels) do
		for name, val in pairs(def.tuning[rarity]) do
			local pretty = val:GetPrettyForStacks(stacks)
			table.insert(processed_stat_levels, pretty)
		end
	end

	local desc = STRINGS.ITEMS.GEMS[gem.id].stat_name

	self.label:SetText(desc) --)STRINGS.UI.EQUIPMENT_STATS[string.upper(stat_id)].name)

	self.value:SetText("")
	if self.value_row then self.value_row:Remove() end
	self.value_row = self:AddChild(self:GenerateMultiLevelPowerWidget(processed_stat_levels, gem:GetEffectiveItemLevel()))

	self:_Layout()
	return self
end

function PowerVariableWidget:_Layout()
	self.value:LayoutBounds("after", "center", self.label)
		:Offset(10, 0)
	if self.value_row then
		self.value_row:LayoutBounds("before", "center", self.label)
			:Offset(self.width * 0.5, 0)
	end
	return self
end

function PowerVariableWidget:SetFontColor(color)
	self.label:SetGlyphColor(color)
	self.value:SetGlyphColor(color)
end

return PowerVariableWidget