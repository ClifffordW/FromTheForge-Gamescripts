local Consumable = require "defs.consumable"
local Image = require("widgets/image")
local Text = require("widgets/text")
local Widget = require("widgets/widget")
local Panel = require("widgets/panel")
local monsterutil = require"util.monsterutil"

-------------------------------------------------------------------------------------------------
--- Displays an vertical listing of crafting/forging materials and where to find them
local CraftingMaterialsDesc = Class(Widget, function(self, icon_size, font_size)
	Widget._ctor(self, "CraftingMaterialsList")

	self.icon_size = icon_size or 100
	self.font_size = font_size or 40

	self.bg = self:AddChild(Image("images/ui_ftf_relic_selection/relic_bg_blank.tex"))
		:ApplyMultColor(0, 0, 0, TOOLTIP_BG_ALPHA)

	self.container = self:AddChild(Widget())
end)

function CraftingMaterialsDesc:SetRecipe(recipe)
	self.container:RemoveAllChildren()
	for id, _ in pairs(recipe.ingredients) do
		local mat_def = Consumable.Items.MATERIALS[id]
		assert(mat_def, id)

		-- Assemble our widget
		local material_root = self.container:AddChild(Widget())

		-- Add an icon
		material_root.icon = material_root:AddChild(Image(mat_def.icon))
			:SetSize(self.icon_size, self.icon_size)
			
		-- Add the name
		local name = string.format("<#%s>%s</>", mat_def.rarity, mat_def.pretty.name)
		local text = material_root:AddChild(Text(FONTFACE.BUTTON, self.font_size, name, UICOLORS.LIGHT_TEXT))
			:LayoutBounds("after", "top", material_root.icon)
			:Offset(10, -5)

		local locations = monsterutil.GetLocationsForItem(id)
		local location_strs = {}

		for i, location in ipairs(locations) do
			table.insert(location_strs, location.pretty.name)
		end

		local location_str = table.concat( location_strs, ", " )

		local location_text = material_root:AddChild(Text(FONTFACE.BUTTON, self.font_size, string.format(STRINGS.CRAFT_WIDGET.FOUND_IN, location_str), UICOLORS.LIGHT_TEXT_DARK))
			:LeftAlign()
			:SetAutoSize(400)
			:LayoutBounds("left", "below", text)

		if mat_def.tags[LOOT_TAGS.ELITE] ~= nil then
			material_root:AddChild(Text(FONTFACE.BUTTON, self.font_size*0.8, STRINGS.CRAFT_WIDGET.FOUND_IN_FRENZY, UICOLORS.LIGHT_TEXT_DARKER))
				:LeftAlign()
				:SetAutoSize(400)
				:LayoutBounds("left", "below", location_text)
				:Offset(0, -20)
		end
	end

	self.container:LayoutChildrenInGrid(1, 10)

	local w, h = self.container:GetSize()
	self.bg:SetSize(w+50, h+50)

	-- self.bg:SizeToWidgets(50, self.container)
	self.container:LayoutBounds("center", "center", self.bg)

	return self
end

return CraftingMaterialsDesc
