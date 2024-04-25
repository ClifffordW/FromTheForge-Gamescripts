local Widget = require("widgets/widget")
local Text = require("widgets/text")
local PowerVariableWidget = require("widgets/ftf/powervariablewidget")

local lume = require("util/lume")

local Power = require("defs/powers")

local PowerDescriptionWidget = Class(Widget, function(self, width, text_size, power, stacks_to_preview, show_variables)
	Widget._ctor(self)

	self.width = width
	self.powervariable_width_modifier = 1.3
	self.font_color = UICOLORS.LIGHT_TEXT
	self.text_size = text_size or 35

	self.root = self:AddChild(Widget("Root"))

	if power then
		self:SetPower(power, stacks_to_preview, show_variables)
	end
end)

function PowerDescriptionWidget:SetPower(power, stacks_to_preview, show_variables)
	-- it's ok if stacks_to_preview is nil, it just means no "next step" will be shown.
	self.root:RemoveAllChildren()

	self.power_desc = self.root:AddChild(Text(FONTFACE.DEFAULT, self.text_size, Power.GetDescForPower(power), self.font_color))
		:SetAutoSize(self.width)
		:LeftAlign()

	if show_variables then
		self.variable_root = self.root:AddChild(Widget("Variable Root"))
		local variables = lume.sort(lume.keys(power:GetTuning()))

		for _, var in ipairs(variables) do
			self.variable_root:AddChild(PowerVariableWidget(self.width * self.powervariable_width_modifier, self.text_size))
				:Refresh(power, var, stacks_to_preview)
		end

		-- Layout
		self.variable_root:LayoutChildrenInAutoSizeGrid(1, 0, 5)
		self.variable_root:LayoutBounds("left", "below", self.power_desc)
			:Offset(0, -10)
	end

	return self
end

function PowerDescriptionWidget:SetFontColor(color)
	self.font_color = color or UICOLORS.LIGHT_TEXT
	if self.power_desc then
		self.power_desc:SetGlyphColor(self.font_color)
	end
	return self
end


function PowerDescriptionWidget:SetVariableFontColor(color)
	if self.variable_root then
		for _, widget in ipairs(self.variable_root:GetChildren()) do
			widget:SetFontColor(color)
		end
	end
	return self
end

return PowerDescriptionWidget