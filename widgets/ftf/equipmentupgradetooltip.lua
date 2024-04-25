local Widget = require"widgets.widget"
local Text = require"widgets.text"
local Image = require"widgets.image"

local CraftingMaterialsList = require"widgets.ftf.craftingmaterialslist"
local CraftingMaterialsDesc = require("widgets/ftf/craftingmaterialsdesc")

local Consumable = require "defs.consumable"
-----------------------------------------------------
-- Tooltip for hovering over the upgrade button
-----------------------------------------------------
local EquipmentUpgradeTooltip = Class(Widget, function(self)
	Widget._ctor(self, "ArmoryUpgradeTooltip")

	self.bg = self:AddChild(Image("images/ui_ftf_relic_selection/relic_bg_blank.tex"))
		:ApplyMultColor(0, 0, 0, TOOLTIP_BG_ALPHA)

	self.container = self:AddChild(Widget())
	self.required_materials = self.container:AddChild(CraftingMaterialsList())

	self.max_level = self.container:AddChild(Text(FONTFACE.DEFAULT, 44))
		:LeftAlign()
		:SetGlyphColor(UICOLORS.LIGHT_TEXT)
		:SetText(STRINGS.UI.ARMORYSCREEN.MAX_LEVEL)

	self.ingredient_desc = self:AddChild(CraftingMaterialsDesc())
end)

function EquipmentUpgradeTooltip:LayoutWithContent( data )

	if data.recipe ~= nil then
		self.required_materials:SetPlayer(data.player)
			:SetRecipe(data.recipe)
			:Show()
		self.max_level:Hide()
		self.ingredient_desc
			:SetRecipe(data.recipe)
			:Show()

	else
		self.required_materials:Hide()
		self.ingredient_desc:Hide()
		self.max_level:Show()
	end

	self.required_materials:LayoutBounds("center", "center")

	local w, h = self.container:GetSize()
	self.bg:SetSize(w+50, h+50)

	self.max_level:LayoutBounds("center", "center", self.bg)
	self.container:LayoutBounds("center", "center", self.bg)

	self.ingredient_desc
		:LayoutBounds("after", "top", self.bg)
		:Offset(10,0)

	return true
end

return EquipmentUpgradeTooltip
