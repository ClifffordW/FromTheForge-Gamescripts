local Image = require("widgets/image")
local ImageButton = require("widgets/imagebutton")
local Text = require("widgets/text")
local Widget = require("widgets/widget")

local itemcatalog = require "defs.itemcatalog"
local fmodtable = require "defs.sound.fmodtable"
local Recipes = require "defs.recipes"
local Consumable = require "defs.consumable"
local Constructable = require "defs.constructable"

local CraftingMaterialsList = require("widgets/ftf/craftingmaterialslist")
local CraftingMaterialsDesc = require("widgets/ftf/craftingmaterialsdesc")

local DecorWidgetTooltip = Class(Widget, function(self)
	Widget._ctor(self, "DecorWidgetTooltip")
end)

function DecorWidgetTooltip:ResizeBG()
	local w, h = self.container:GetSize()
	self.bg:SetSize(w+50, h+50)
	self.container:LayoutBounds("center", "center", self.bg)
end

function DecorWidgetTooltip:LayoutWithContent( data )
	self:RemoveAllChildren()

	self.bg = self:AddChild(Image("images/ui_ftf_relic_selection/relic_bg_blank.tex"))
		:ApplyMultColor(0, 0, 0, TOOLTIP_BG_ALPHA)

	self.container = self:AddChild(Widget())

	if data.locked then
		self.item_name = self.container:AddChild(Text(FONTFACE.DEFAULT, FONTSIZE.SCREEN_SUBTITLE, STRINGS.UI.DECORSCREEN.LOCKED_TT))
			:SetGlyphColor(UICOLORS.LIGHT_TEXT)

		self:ResizeBG()
	else
		local recipe = Recipes.ForSlot[data.def.slot][data.def.name]

		-------

		self.text_root = self.container:AddChild(Widget("Text Root"))

		self.item_name = self.text_root:AddChild(Text(FONTFACE.DEFAULT, FONTSIZE.SCREEN_SUBTITLE, data.def.pretty.name))
			:LeftAlign()
	        :SetRegionSize(480, 70)
	        :EnableWordWrap(true)
	        :ShrinkToFitRegion(true)
			:SetGlyphColor(UICOLORS.LIGHT_TEXT)

		self.item_desc = self.text_root:AddChild(Text(FONTFACE.DEFAULT, FONTSIZE.SCREEN_TEXT, string.format("<i>%s</>", data.def.pretty.desc)))
			:LeftAlign()
			:SetAutoSize(480)
			:SetGlyphColor(UICOLORS.LIGHT_TEXT_DARK)
			:LayoutBounds("left", "below")

		-------

		self.ingredients_root = self.container:AddChild(Widget("Ingredients Root"))

		self.ingredients_text = self.ingredients_root:AddChild(Text(FONTFACE.DEFAULT, FONTSIZE.SCREEN_TEXT, STRINGS.CRAFT_WIDGET.INGREDIENTS))
			:LeftAlign()
			:SetAutoSize(480)
			:SetGlyphColor(UICOLORS.LIGHT_TEXT)
			:LayoutBounds("left", "below")
			:Offset(0, -20)

		self.ingredients_list = self.ingredients_root:AddChild(CraftingMaterialsList())
			:SetPlayer(data.player)
			:SetRecipe(recipe)
			:LayoutBounds("left", "below")

		-------

		self.dividing_line = self.container:AddChild(Image("images/ui_ftf_inventory/StatsUnderline3.tex"))
			:SetMultColor(UICOLORS.LIGHT_TEXT_DARKER)
			:SetSize(480, 2.5)

		-------

		self.controls_root = self.container:AddChild(Widget("Controls Root"))

		self.left_mouse_label = self.controls_root:AddChild(Text(FONTFACE.BUTTON, 20 * HACK_FOR_4K, STRINGS.CRAFT_WIDGET.PLACE, UICOLORS.WHITE))
		self.right_mouse_label = self.controls_root:AddChild(Text(FONTFACE.BUTTON, 20 * HACK_FOR_4K, STRINGS.CRAFT_WIDGET.CRAFT_STORE, UICOLORS.WHITE))
		self.no_placement_permission = self.controls_root:AddChild(Text(FONTFACE.BUTTON, 20 * HACK_FOR_4K, STRINGS.CRAFT_WIDGET.NO_PERMISSION)):Hide()

		local can_place_net = TheNet:CanPlaceTownProp()
		if data.count > 0 and can_place_net then
			self.left_mouse_label:SetText(string.format("%s", STRINGS.CRAFT_WIDGET.PLACE))
		else
			self.left_mouse_label:SetText(string.format("<#PENALTY>%s</>", STRINGS.CRAFT_WIDGET.PLACE))
		end

		self.no_placement_permission:SetShown(not can_place_net)

		if recipe:CanPlayerCraft(data.player) then
			self.right_mouse_label:SetText(string.format("%s", STRINGS.CRAFT_WIDGET.CRAFT_STORE))
		else
			self.right_mouse_label:SetText(string.format("<#PENALTY>%s</>", STRINGS.CRAFT_WIDGET.CRAFT_STORE))
		end

		self.controls_root:LayoutChildrenInGrid(2, 10)

		-------
		local has_made = data.player.components.hasmade:HasMadeDecor(data.def.name)
		if not has_made then

			self.dividing_line_2 = self.container:AddChild(Image("images/ui_ftf_inventory/StatsUnderline3.tex"))
				:SetMultColor(UICOLORS.LIGHT_TEXT_DARKER)
				:SetSize(480, 2.5)

			self.bonus_reward_root = self.container:AddChild(Widget("Bonus Reward Root"))

			local text = self.bonus_reward_root:AddChild(Widget("Bonus Reward Root Text"))

			self.bonus_title = text:AddChild(Text(FONTFACE.DEFAULT, FONTSIZE.SCREEN_TEXT, STRINGS.CRAFT_WIDGET.FIRST_TIME_CRAFT_REWARD_TITLE))
				:LeftAlign()
				:SetGlyphColor(UICOLORS.LIGHT_TEXT)

			self.bonus_desc = text:AddChild(Text(FONTFACE.DEFAULT, FONTSIZE.SCREEN_TEXT * 0.8, string.format("<i>%s</>", STRINGS.CRAFT_WIDGET.NEW_CRAFT_DESC)))
				:LeftAlign()
				:SetAutoSize(480)
				:SetGlyphColor(UICOLORS.LIGHT_TEXT_DARK)
				:LayoutBounds("left", "below", self.bonus_title)
				:Offset(0, -20)

			local reward_id, reward_count = Constructable.GetFirstCraftBounty(data.def)
			local reward_def = Consumable.FindItem(reward_id)

			local widget = self.bonus_reward_root:AddChild(Widget())

			local size = 100
			local image = widget:AddChild(Image(reward_def.icon))
				:SetSize(size, size)

			widget:AddChild(Text(FONTFACE.DEFAULT, 40, string.format("x %d", reward_count), UICOLORS.LIGHT_TEXT))
				:LayoutBounds("after", "center", image)

			widget:LayoutBounds("after", "center", text)
				:Offset(20, 0)
		end

		-------

		self.ingredients_root:LayoutBounds("left", "below", self.text_root):Offset(0, -20)
		self.dividing_line:LayoutBounds("left", "below", self.ingredients_root):Offset(0, -20)
		self.controls_root:LayoutBounds("left", "below", self.dividing_line):Offset(0, -20)

		if not has_made then
			self.dividing_line_2:LayoutBounds("left", "below", self.controls_root):Offset(0, -20)
			self.bonus_reward_root:LayoutBounds("left", "below", self.dividing_line_2):Offset(0, -20)
		end

		self:ResizeBG()

		self.ingredient_desc = self:AddChild(CraftingMaterialsDesc())
			:SetRecipe(recipe)
			:LayoutBounds("after", "top", self.bg)
			:Offset(10,0)
	end

	return true
end


local DecorWidget = Class(Widget, function(self, player, def, size)
	Widget._ctor(self, "DecorWidget")
	
	self:SetOwningPlayer(player)

	-- sound
	self:SetControlDownSound(nil)
	self:SetControlUpSound(nil)
	self:SetHoverSound(fmodtable.Event.hover)
	self:SetGainFocusSound(fmodtable.Event.hover)

	self.def = def

	self.size = size or 130 * HACK_FOR_4K

	self.mask = self:AddChild(Image("images/global/square.tex"))
		:SetSize(self.size, self.size)
		:SetMultColorAlpha(0)
		:SetMask()

	self.background = self:AddChild(Image("images/ui_ftf_shop/inventory_slot_rare.tex"))
		:SetSize(self.size, self.size)
		--:SetMask()

	local function MarkAsSeen()
		player.components.hasseen:MarkDecorAsSeen(def.name)
		self:Refresh()
		self.onlosehover()
	end

	local icon_tex = def.icon
	self.icon = self:AddChild(ImageButton(icon_tex))
		:SetOnClick(function()
			self:OnClick()
		end)
		:SetOnClickAlt(function()
			self:OnRightClick()
		end)
		:SetSize(self.size, self.size)
		:SetOnGainHover(function()
			MarkAsSeen()
		end)
		:SetOnGainFocus(function()
			MarkAsSeen()
		end)
		:SetMasked()
		:ShowToolTipOnFocus(true)
		:SetToolTipClass(DecorWidgetTooltip)

	-- locked?
	self.lock_badge = self:AddChild(Image("images/ui_ftf_character/LockBadge.tex"))
		:SetName("Lock badge")
		:SetHiddenBoundingBox(true)
		:LayoutBounds("center", "center", self.background)
		:SetScale(0.75)

	-- self.quantity_bg = self:AddChild(Image("images/ui_ftf_character/ItemPriceBg.tex"))
	-- 	:LayoutBounds("right", "bottom", self.background)
	-- 	:Offset(-24, 30)

	-- Add quantity
	self.quantity = self:AddChild(Text(FONTFACE.DEFAULT, 30 * HACK_FOR_4K, "", UICOLORS.LIGHT_TEXT_TITLE))
		:SetOutlineColor(UICOLORS.BLACK)
		:EnableOutline()
		:LayoutBounds("right", "bottom", self.background)
		:Offset(-24, 30)

	self.new_icon = self:AddChild(Image("images/ui_ftf/star.tex"))
		:SetScale(0.7)
		:LayoutBounds("right", "top", self.background)
		:SetHiddenBoundingBox(true)
		:Offset(8, 8)
		:Hide()

	self.craft_bounty_banner = self:AddChild(Image("images/ui_ftf/craft_bounty_banner.tex"))
		:SetSize(self.size * 0.5, self.size * 0.5)
		:LayoutBounds("left", "top", self.background)
		:SetHiddenBoundingBox(true)
		:SetMultColor(UICOLORS.KONJUR)
		:Hide()

	self.onclick = nil
	self.onrightclick = nil

	self:Refresh()
end)

function DecorWidget:SetOnClick(onclick)
	self.onclick = onclick
	return self
end

function DecorWidget:SetOnGainHover(onlosehover)
	self.onlosehover = onlosehover
	return self
end

function DecorWidget:SetOnRightClick(onclick)
	self.onrightclick = onclick
	return self
end

function DecorWidget:OnClick()
	self.onclick()
end

function DecorWidget:OnRightClick()
	self.onrightclick()
end

function DecorWidget:Refresh()
	local player = self:GetOwningPlayer()
	local locked = not player.components.unlocktracker:IsRecipeUnlocked(self.def.name)
	local count = player.components.inventoryhoard:GetStackableCount(self.def)
	local recipe = Recipes.ForSlot[self.def.slot][self.def.name]
	self.quantity:SetText(tostring(count))

	local tex = itemcatalog.GetRarityIcon(self.def.rarity)
	self.background:SetTexture(tex)

	self.icon:SetToolTipClass(DecorWidgetTooltip)
	self.icon:SetToolTip({player = player, def = self.def, count = count, locked = locked})
	self.new_icon:SetShown(not player.components.hasseen:HasSeenDecor(self.def.name))

	self.craft_bounty_banner:SetShown(not locked and not player.components.hasmade:HasMadeDecor(self.def.name))

	if locked then
		-- self.icon:SetToolTipClass(nil)
		-- self.icon:SetToolTip(STRINGS.UI.DECORSCREEN.LOCKED_TT)
		self.icon
			:SetMultColor(0,0,0,1)
			:SetSaturation(0)
		self.background:SetMultColor(HexToRGB(0x777777ff))
		self.new_icon:Hide()
			--:SetAddColor(HexToRGB(0xBCA693ff))

		self.quantity:Hide()
	elseif not recipe:CanPlayerCraft(player) and count == 0 then
		self.icon
			:SetMultColor(HexToRGB(0x888888ff))
			:SetSaturation(0.7)
		self.background:SetMultColor(HexToRGB(0x777777ff))
	end

	self.lock_badge:SetShown(locked)

	return self
end

function DecorWidget:GetDef()
	return self.def
end

return DecorWidget
