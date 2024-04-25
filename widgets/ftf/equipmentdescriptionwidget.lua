local Widget = require("widgets/widget")
local Text = require("widgets/text")
local Image = require("widgets/image")
local itemforge = require "defs.itemforge"
local Power = require("defs.powers")
local lume = require("util/lume")
local SkillWidget = require"widgets.ftf.skillwidget"
local PowerVariableWidget = require"widgets.ftf.powervariablewidget"
local PowerDescriptionWidget = require("widgets/ftf/powerdescriptionwidget")

------------------------------------------------------------------------------------

------------------------------------------------------------------------------------

local EquipmentDescriptionWidget = Class(Widget, function(self, width, text_size, font_color)
	Widget._ctor(self, "EquipmentDescriptionWidget")

	self.width = width
	self.powervariable_width_modifier = 1.3
	self.text_size = text_size or 35
	self.font_color = font_color or UICOLORS.LIGHT_TEXT
	self.secondary_text_size = self.text_size

	self.power_root = self:AddChild(Widget("Power Root"))
	self.skill_root = self:AddChild(Widget("Skill Desc"))

end)

function EquipmentDescriptionWidget:SetItemDef(usagelvl, def, preview_upgrade)
	self:RemoveAllChildren()

	-- self.skill_root:RemoveAllChildren()
	-- self.power_root:RemoveAllChildren()

	if def.usage_data.power_on_equip then
		local power_def = Power.FindPowerByName(def.usage_data.power_on_equip)
		local power = itemforge.CreatePower(power_def)
		local current_stacks = power_def.stacks_per_usage_level and power_def.stacks_per_usage_level[usagelvl]
		local next_stacks = power_def.stacks_per_usage_level and power_def.stacks_per_usage_level[usagelvl + 1]
		power.stacks = current_stacks

		self.power_desc = self:AddChild(PowerDescriptionWidget(self.width, self.text_size, power, preview_upgrade and next_stacks or false, true))
			:SetFontColor(self.font_color)
			:SetVariableFontColor(self.font_color)
	end

	if def.usage_data.skill_on_equip then
		local power_def = Power.FindPowerByName(def.usage_data.skill_on_equip)
		local power = itemforge.CreatePower(power_def)

		local skill_icon_size = 66
		self.skill_icon = self:AddChild(SkillWidget(skill_icon_size, self:GetOwningPlayer(), power))
		self.skill_title = self:AddChild(Text(FONTFACE.DEFAULT, self.text_size, power_def.pretty.name, self.font_color))
			:LayoutBounds("after", "top", self.skill_icon)
			-- :Offset(10, 0)
		self.skill_desc = self:AddChild(PowerDescriptionWidget(self.width - skill_icon_size, self.text_size, power, false, false))
			:SetFontColor(self.font_color)
			:SetVariableFontColor(self.font_color)
			:LayoutBounds("left", "below", self.skill_title)
			:Offset(0, -10)

	-- 	self.skill_desc = self.skill_root:AddChild(Text(FONTFACE.DEFAULT, self.text_size, Power.GetDescForPower(power), UICOLORS.LIGHT_TEXT))
	-- 		:SetAutoSize(self.width - skill_icon_size)
	-- 		:LeftAlign()
	-- 		:LayoutBounds("left", "below", self.skill_title)
	-- 		:Offset(0, -10)
	end

	self:LayoutChildrenInAutoSizeGrid(1, 20)

	return self
end



function EquipmentDescriptionWidget:SetItem(item, preview_upgrade)
	self.item = item
	local usagelvl = item:GetUsageLevel()
	self.def = item:GetDef()

	if self.def.slot == "GEMS" then
		-- This is a gem!
		self.power_desc:SetText(self.def.pretty.slotted_desc) --changed so that the gem can have a longer description on the inventoryscreen but a straight-to-the-point desc on the gemscreen --Kris
		self.variable_root:RemoveAllChildren()

		local has_header = false
		if self.def.stat_mods then
			for stat_id, stat_levels in pairs(self.def.stat_mods) do
				if not has_header then
					has_header = true
					self.variable_root:AddChild(PowerVariableWidget:GenerateMultiLevelHeaderWidget(stat_levels, usagelvl))
				end

				self.variable_root:AddChild(PowerVariableWidget(self.width * self.powervariable_width_modifier, self.text_size))
					:SetGemStat(stat_id, stat_levels, usagelvl)
			end
		elseif self.def.usage_data and self.def.usage_data.power_on_equip then

			self.variable_root:RemoveAllChildren()

			local power_def = Power.FindPowerByName(self.def.usage_data.power_on_equip)
			local power = itemforge.CreatePower(power_def)

			self.variable_root:AddChild(PowerVariableWidget:GenerateMultiLevelHeaderWidget(power_def.stacks_per_usage_level, usagelvl))
			self.variable_root:AddChild(PowerVariableWidget(self.width * self.powervariable_width_modifier, self.text_size))
				:SetGemPower(power, self.def.usage_data.stacks, item)
		end

		if not self.variables_bg then
			self.variables_bg = self:AddChild(Image("images/ui_ftf_gems/gem_stats_bg.tex"))
				:SetHiddenBoundingBox(true)
				:SetMultColor(UICOLORS.BACKGROUND_LIGHT)
				:SetMultColorAlpha(0.1)
				:SendToBack()
		end

		-- Layout
		self.variable_root:LayoutChildrenInColumn(5, "right")
		local w, h = self.variable_root:GetSize()
		self.variables_bg:SetSize(w + 40, h + 20)
			:LayoutBounds("center", "center", self.variable_root)
		self.power_desc:LayoutBounds("left", "above", self.variable_root)
			:Offset(0, 20)

	elseif self.def.usage_data then
		self:SetItemDef(usagelvl, self.def, preview_upgrade)
	end

	return self
end

return EquipmentDescriptionWidget
