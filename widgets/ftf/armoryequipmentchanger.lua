local Widget = require"widgets.widget"
local Panel = require"widgets.panel"
local Text = require"widgets.text"
local Image = require"widgets.image"

local ItemCatalog = require"defs.itemcatalog"
local Equipment = require"defs.equipment"
local fmodtable = require "defs.sound.fmodtable"

local monsterutil = require"util.monsterutil"

local InventorySlot = require "widgets.ftf.inventoryslot"
local EquipmentTooltip = require "widgets/ftf/equipmenttooltip"

local ActionButton = require("widgets/actionbutton")

local INNER_PANEL_WIDTH = 760

local ArmoryEquipmentChanger = Class(Widget, function(self, player, height)
	Widget._ctor(self, "ArmoryEquipmentChanger")

	self.player = player

	self.bg = self:AddChild(Panel("images/ui_ftf/angled_panel.tex"))
		:SetName("Panel")
		:SetNineSliceCoords(34, 48, 199, 197)
		:SetSize(INNER_PANEL_WIDTH, height or 1200)
		:SetMultColor(UICOLORS.LIGHT_BACKGROUNDS_MID)

	self.title_container = self:AddChild(Widget())
	self.title = self.title_container:AddChild(Text(FONTFACE.DEFAULT, 80, "", UICOLORS.LIGHT_TEXT_DARKER))
		:SetAutoSize(self.contentWidth)
		:LeftAlign()
	self.title_decor_left = self.title_container:AddChild(Image("images/ui_ftf_inventory/InventoryTitleDecorLeft.tex"))
		:SetSize(80, 80)
		:SetMultColor(UICOLORS.LIGHT_TEXT_DARK)
		:SetMultColorAlpha(0.5)
	self.title_decor_right = self.title_container:AddChild(Image("images/ui_ftf_inventory/InventoryTitleDecorRight.tex"))
		:SetSize(80, 80)
		:SetMultColor(UICOLORS.LIGHT_TEXT_DARK)
		:SetMultColorAlpha(0.5)

	self.owned_items = self:AddChild(Widget())

	local btn_scale = 0.6
	self.back_btn = self:AddChild(ActionButton())
		:SetText(STRINGS.UI.ARMORYSCREEN.BACK)
		:LayoutBounds("center", "below", self)
		:SetSize(BUTTON_W, BUTTON_H)
		:SetNormalScale(btn_scale)
		:SetFocusScale(btn_scale)
		:SetScale(btn_scale)
		:Offset(0, -20)
		:SetOnClick(function()
			if self.on_select_equipment then
				self.on_select_equipment()
			end
		end)
		:Hide()

	self.enable_title = true
	self.enable_unequip = true

	self.forward_default_focus = function()
		return self.owned_items:GetFirstChild()
	end
end)

function ArmoryEquipmentChanger:SetEnableBackButton(enable)
	self.back_btn:SetShown(enable)
	return self
end

function ArmoryEquipmentChanger:SetEnableTitle(enable)
	self.enable_title = enable
	self.title_container:SetShown(enable)
	self.title:SetShown(enable)
	return self
end

function ArmoryEquipmentChanger:SetEnableUnequip(enable)
	self.enable_unequip = enable
	return self
end

function ArmoryEquipmentChanger:SetFilterFn(filter_fn)
	self.filter_fn = filter_fn
	return self
end

function ArmoryEquipmentChanger:Refresh(slot)
	local equipped_item = self.player.components.inventoryhoard:GetEquippedItem(slot)
	for _, inventory_slot in ipairs(self.owned_items:GetChildren()) do
		if inventory_slot:HasItem() then
			inventory_slot:SetEquipped(inventory_slot:GetItemInstance() == equipped_item)
		end
	end
end

function ArmoryEquipmentChanger:DisplayEquipment(slot)
	self.owned_items:RemoveAllChildren()

	self.slot = slot
	local items = self.player.components.inventoryhoard:GetSlotItems(slot)
	local common = ItemCatalog.All.SlotDescriptor[slot]

	local items_to_add = {}

	local has_shown_own_equipment = false
	local equipped_item = self.player.components.inventoryhoard:GetEquippedItem(slot)

	for k, item in pairs(items) do
		--all the equipment you own, if it passes the filter
		if self.filter_fn == nil or self.filter_fn(item) then
			table.insert(items_to_add, { item=item, equipped=equipped_item == item })

			if item == equipped_item then
				has_shown_own_equipment = true
			end
		end
	end

	--see how many children I have and size appropriately
	self.num_columns = #items_to_add < 12 and 3 or 4
	local icon_size = #items_to_add < 12 and 220 or 170

	--sort the equipment by dungeon, then by rarity
	local sort = function(a, b)
		local item_a = Equipment.Items[slot][a.item.id]
		local item_b = Equipment.Items[slot][b.item.id]

		local loc_a = item_a.crafting_data and item_a.crafting_data.craftable_location and item_a.crafting_data.craftable_location[1] or "default"
		local loc_b = item_b.crafting_data and item_b.crafting_data.craftable_location and item_b.crafting_data.craftable_location[1] or "default"

		if loc_a ~= loc_b then
			return monsterutil.GetLocationsUnlockIdx(loc_a) < monsterutil.GetLocationsUnlockIdx(loc_b)
		else
			return Equipment.CompareDef_ByRarityAndName(item_a, item_b)
		end
	end
	table.sort( items_to_add, sort )

	--empty icon
	if self.enable_unequip then
		table.insert(items_to_add, { equipped=false })
	end

	--always add the equipment you're already wearing, for example in the case of holding a spear and going to the hammer rack
	if not has_shown_own_equipment and equipped_item ~= nil then
		table.insert(items_to_add, { item=equipped_item, equipped=true })
	end

	--actually add the items
	for _, item_to_add in ipairs(items_to_add) do
		local item = item_to_add.item
		self.owned_items:AddChild(InventorySlot(icon_size, common.icon))
			:SetItem(item, self.player)
			:SetToolTipClass(EquipmentTooltip)
			:ShowToolTipOnFocus(true)
			:SetOnClick(function() self:OnSelectEquipment(item, slot) end)
			:SetOnGainHover(function()
				self.on_hover_equipment_fn(item, slot)
			end)
			:SetOnLoseHover(function()
				self.on_hover_equipment_fn()
			end)
			:SetOnGainFocus(function() self.on_hover_equipment_fn(item, slot) end)
			:SetOnLoseFocus(function() self.on_hover_equipment_fn() end)
			:SetEquipped(item_to_add.equipped)
	end

	self.title:SetText(STRINGS.ITEM_CATEGORIES[slot])

	self.title:LayoutBounds("center", "top", self.bg)
		:Offset(0, 0)
	self.title_decor_left:LayoutBounds("before", "center", self.title)
		:Offset(-20, 0)
	self.title_decor_right:LayoutBounds("after", "center", self.title)
		:Offset(20, 0)

	self.owned_items:LayoutChildrenInGrid(self.num_columns, 10)

	if self.enable_title then
		self.owned_items:LayoutBounds("center", "below", self.title)
			:Offset(0, -20)
	else
		self.owned_items:LayoutBounds("center", "top", self.bg)
			:Offset(0, -30)
	end

	self:Show()

	self:RenavControls()

	-- Don't set focus here since we may not be fully constructed. Instead,
	-- return focus for caller to handle.
	return self.owned_items:GetFirstChild()
end

function ArmoryEquipmentChanger:RenavControls()
	-- Go through list and make items nav correctly to each other
	local widgets = self.owned_items:GetChildren()
	for i, v in ipairs(widgets) do
		if i > 1 then
			v:SetFocusDir("left", widgets[i-1], true)
		end
		if i > self.num_columns then
			v:SetFocusDir("up", widgets[i-self.num_columns], true)
		end
	end
end

function ArmoryEquipmentChanger:SetOnSelectEquipment(fn)
	self.on_select_equipment = fn
	return self
end

function ArmoryEquipmentChanger:SetOnHoverEquipment(fn)
	self.on_hover_equipment_fn = fn
	return self
end


function ArmoryEquipmentChanger:OnSelectEquipment(item, slot)
	local hoard = self.player.components.inventoryhoard
	local index = self.player.components.inventoryhoard.data.selectedLoadoutIndex
	hoard:SetLoadoutItem(index, slot, item)
	hoard:EquipSavedEquipment()

	local item_def = item and item:GetDef()
	if item_def and item_def.sound_events and item_def.sound_events.equip then
		TheFrontEnd:GetSound():PlaySound(fmodtable.Event[item_def.sound_events.equip])
	end

	self:Refresh(slot)
	self.on_select_equipment()
end

return ArmoryEquipmentChanger
