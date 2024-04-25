local GenericPlayerScreen = require"screens.town.genericplayerscreen"
local playerutil = require "util.playerutil"
local Widget = require"widgets.widget"
local Panel = require"widgets.panel"
local Text = require"widgets.text"
local ImageButton = require"widgets.imagebutton"
local Image = require"widgets.image"
local UIAnim = require"widgets.uianim"

local ItemCatalog = require"defs.itemcatalog"
local itemforge = require"defs.itemforge"
local Equipment = require"defs.equipment"
local Recipes = require "defs.recipes"
local fmodtable = require "defs.sound.fmodtable"

local GenericPlayerPanel = require"widgets.ftf.genericplayerpanel"
local InventorySlot = require "widgets.ftf.inventoryslot"
local ItemStats = require "widgets.ftf.itemstats"
local DisplayStat = require "widgets.ftf.displaystat"
local InventoryItemList = require "widgets.ftf.inventoryitemlist"
local EquipmentTooltip = require "widgets/ftf/equipmenttooltip"
local EquipmentDescriptionWidget = require"widgets.ftf.equipmentdescriptionwidget"
local TotalWeightWidget = require "widgets.ftf.totalweightwidget"
local ArmoryEquipmentChanger = require "widgets.ftf.armoryequipmentchanger"
local EquipmentUpgradeTooltip = require"widgets.ftf.equipmentupgradetooltip"

local Enum = require "util.enum"
local itemutil = require "util.itemutil"
local Weight = require "components.weight"

local INNER_PANEL_WIDTH = 760

-----------------------------------------------------
-- The stats for the piece of equipment you're wearing
-----------------------------------------------------
local ArmoryEquipmentStats = Class(Widget, function(self, player)
	Widget._ctor(self)

	self.player = player
	self.stats_container = self:AddChild(Widget())	
end)

function ArmoryEquipmentStats:SetItem(item)
	self.stats_container:RemoveAllChildren()

	if item == nil then
		return self
	end

	local stats_delta, stats = self.player.components.inventoryhoard:DiffStatsAgainstEquipped(item, item:GetDef().slot)	
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

function ArmoryEquipmentStats:AddStats(stats_data)
	local max_width = 290
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

	self.stats_container:LayoutChildrenInColumn(20, "left")

	return self
end

-------------------------------

local UPGRADE_TYPE = Enum
{
	"ITEM_UPGRADE",
	"DEFENSE_UPGRADE"
}

-----------------------------------------------------
-- The text and level up button combo
-----------------------------------------------------
local ArmoryLevelWidget = Class(Widget, function(self, player, item, upgrade_type, display_widget)
	Widget._ctor(self, "ArmoryLevelWidget")

	self.player = player
	self.item = item
	self.item_def = item:GetDef()
	self.upgrade_type = upgrade_type
	self.display_widget = display_widget

	self.level_text = self:AddChild(Text(FONTFACE.DEFAULT, FONTSIZE.SCREEN_TEXT * 1.1, "", UICOLORS.LIGHT_TEXT_DARK))
		:RightAlign()

	local size = 50
	self.level_up = self:AddChild(ImageButton("images/ui_ftf/ButtonPlus.tex"))
		:SetSize(size, size)
		:SetControlUpSound(nil)
		:ShowToolTipOnFocus(true)

	--no berna, no upgrade
	if TheWorld:IsFlagUnlocked("wf_town_has_armorsmith") then
		self.level_up
			:SetOnClick( function() self:OnClickUpgradeItem() end )
			:SetToolTipClass(EquipmentUpgradeTooltip)
			:SetControlUpSound(nil)
	else
		self.level_up
			:Disable()
			:SetMultColor(HexToRGB(0x999999ff))
			:SetSaturation(0.15)
			:SetToolTip(STRINGS.UI.ARMORYSCREEN.NO_ARMORSMITH_TT)
	end

	self.inst:ListenForEvent("inventory_changed", function() self:Refresh() end, self.player)
end)

function ArmoryLevelWidget:_SetHoverFn(fn)
	self._hover_fn = fn
end

function ArmoryLevelWidget:Refresh()
	self.upgrade_recipe = nil
	local txt
	local hover_fn

	--depending what I'm upgrading, figure out the fns and text
	if self.upgrade_type == UPGRADE_TYPE.id.DEFENSE_UPGRADE then
		local level = self.item:GetUpgradeLevel()
		txt = string.format(STRINGS.UI.ARMORYSCREEN.DEFENSE_LVL, level)

		self.upgrade_recipe = Recipes.FindItemUpgradeRecipeForItem(self.item)

		if self.upgrade_recipe then
			dbassert(self.display_widget:is_a(ArmoryEquipmentStats))
			hover_fn = function()
				--store the upgraded version of this item for comparison
				local item_upgrade = itemforge.CreateEquipment(self.item_def.slot, self.item_def)
				item_upgrade:SetItemLevel(level + 1)

				self.display_widget:SetItem(item_upgrade)
			end
		end
	else
		txt = string.format(STRINGS.UI.ARMORYSCREEN.EFFECT_LVL, self.item:GetUsageLevel())
		self.upgrade_recipe = Recipes.FindUsageUpgradeRecipeForItem(self.item)

		if self.upgrade_recipe then
			dbassert(self.display_widget:is_a(EquipmentDescriptionWidget))
			hover_fn = function()
				self.display_widget:SetItem(self.item, true)
			end
		end
	end

	-- Check whether the player can upgrade this, and show the button accordingly
	if self.level_up:IsEnabled() then
		if self.upgrade_recipe and self.upgrade_recipe:CanPlayerCraft(self.player) then
			self.level_up:SetMultColor(UICOLORS.WHITE)
				:SetSaturation(1)
				:SetScale(1)
				:SetMoveOnClick(true)
		elseif self.upgrade_recipe then -- Can't afford the upgrade
			self.level_up:SetMultColor(HexToRGB(0x999999ff))
				:SetSaturation(0.15)
				:SetScale(1)
				:SetMoveOnClick(false)
		elseif not self.upgrade_recipe then -- Max level
			self.level_up:SetTextures("images/ui_ftf/ButtonUpgraded.tex")
				:SetMultColor(UICOLORS.WHITE)
				:SetSaturation(1)
				:SetScale(1)
				:SetMoveOnClick(false)
		end
	end

	--set up hover / unhover fns
	self:_SetHoverFn(hover_fn)

	local losehover_fn = function() self.display_widget:SetItem(self.item) end

	if self.level_up:IsEnabled() then
		if self.upgrade_recipe then
			self.level_up
				:SetOnGainHover(hover_fn)
				:SetOnGainFocusFn(hover_fn)
				:SetOnLoseHover(losehover_fn)
				:SetOnLoseFocusFn(losehover_fn)
		else
			self.level_up
				:SetOnGainHover(nil)
				:SetOnGainFocusFn(nil)
				:SetOnLoseHover(nil)
				:SetOnLoseFocusFn(nil)

		end

		self.level_up
			:SetToolTip({player = self.player, recipe = self.upgrade_recipe})
	end

	self.level_text:SetText(txt)
		:LayoutBounds("right", "center")
		:Offset(-40, 0)

	return self
end

function ArmoryLevelWidget:OnClickUpgradeItem()
	local player = self:GetOwningPlayer()

	if self.upgrade_recipe == nil or not self.upgrade_recipe:CanPlayerCraft(player) then
		TheFrontEnd:GetSound():PlaySound(fmodtable.Event.ui_action_blocked)		
		return
	end

	if self.upgrade_type == UPGRADE_TYPE.id.DEFENSE_UPGRADE then
		self.item:UpgradeItemLevel()
	else
		self.item:UpgradeUsageLevel()
	end

	--take the ingredients from the player
	self.upgrade_recipe:TakeIngredientsFromPlayer(player)

	--update the current display
	self.display_widget:SetItem(self.item)

	TheFrontEnd:GetSound():PlaySound(fmodtable.Event.inventory_upgrade)
	TheFrontEnd:GetSound():PlaySound(fmodtable.Event.upgrade_armour)
	player:PushEvent("inventory_changed", { item = self.item })
	player:PushEvent("equipment_upgrade", { item = self.item })

	self:Refresh()

	--still hovering, so call the fn
	if self._hover_fn ~= nil then
		self._hover_fn()
	end
end

-------------------------------------------------------------
-- Each panel for each piece of equipment you're wearing
-------------------------------------------------------------
local ArmoryEquipmentPanel = Class(Widget, function(self, player, slot)
	Widget._ctor(self, "ArmoryEquipmentPanel")

	self.player = player
	self.slot = slot

	local angled_panel = self:AddChild(Panel("images/ui_ftf/angled_panel.tex"))
		:SetName("Panel")
		:SetNineSliceCoords(34, 48, 199, 197)
		:SetSize(INNER_PANEL_WIDTH, 490)
		:SetMultColor(UICOLORS.BACKGROUND_MID)

	local common = ItemCatalog.All.SlotDescriptor[slot]
	self.equipped_item = player.components.inventoryhoard:GetEquippedItem(slot)

	self.slot_widget =	self:AddChild(InventorySlot(200, common.icon))
		:SetItem(self.equipped_item, player)
		:LayoutBounds("left", "top", angled_panel)
		:SetOnClick(function() self.on_change_equipment_fn() end)
		:SetOnClickAlt(nil)
		:SetToolTipClass(nil)
		:SetToolTip(STRINGS.UI.ARMORYSCREEN.EQUIP_TT)
		:ShowToolTipOnFocus(true)
		:Offset(20, -20)

	self.no_equipment_slot_name = self:AddChild(Text(FONTFACE.DEFAULT, FONTSIZE.SCREEN_SUBTITLE, STRINGS.ITEM_CATEGORIES[self.slot], UICOLORS.LIGHT_TEXT_DARK))
		:SetName("Equipment Slot Name")
		:Hide()

	self.no_equipment_text = self:AddChild(Text(FONTFACE.DEFAULT, FONTSIZE.SCREEN_TEXT, STRINGS.UI.ARMORYSCREEN.NO_EQUIPMENT, UICOLORS.LIGHT_TEXT_DARK))
		:SetName("No")
		:Hide()

	local item_name = ""
	if self.equipped_item ~= nil then
		local def = self.equipped_item:GetDef()
		local rarity = def.rarity or "COMMON"
		item_name = string.format("<#%s>%s</>", rarity, self.equipped_item:GetLocalizedName())
	end

	self.title = self:AddChild(Text(FONTFACE.DEFAULT, FONTSIZE.SCREEN_SUBTITLE, item_name))
		:LeftAlign()
        :SetRegionSize(480, 70)
        :EnableWordWrap(true)
        :ShrinkToFitRegion(true)
		:LayoutBounds("after", "top", self.slot_widget)
		:Offset(20, -10)
	self.equipment_desc = self:AddChild(EquipmentDescriptionWidget(500, FONTSIZE.SCREEN_TEXT))

	self.stats_desc = self:AddChild(ArmoryEquipmentStats(player))
		:SetItem(self.equipped_item)

	if self.equipped_item ~= nil then
		self.equipment_desc:SetItem(self.equipped_item)

		self.def_level = self:AddChild(ArmoryLevelWidget(player, self.equipped_item, UPGRADE_TYPE.id.DEFENSE_UPGRADE, self.stats_desc))
			:Refresh()
			:LayoutBounds("right", "bottom", angled_panel)
			:Offset(-20, 20)

		local def = self.equipped_item:GetDef()

		if def.usage_data and def.usage_data.power_on_equip then
			self.usage_level = self:AddChild(ArmoryLevelWidget(player, self.equipped_item, UPGRADE_TYPE.id.ITEM_UPGRADE, self.equipment_desc))
				:Refresh()
				:LayoutBounds("right", "above", self.def_level)
				:Offset(0, 10)
		end
	else
		self.equipment_desc:Hide()
		self.no_equipment_text:Show()
		self.no_equipment_slot_name:Show()
	end

	self.no_equipment_slot_name:LayoutBounds("left", "below", self.title)
		:LayoutBounds("after", "top", self.slot_widget)
		:Offset(20, -10)
	self.no_equipment_text:LayoutBounds("left", "below", self.no_equipment_slot_name)

	self.equipment_desc:LayoutBounds("left", "below", self.title)
		:Offset(0, -5)
	self.stats_desc
		:LayoutBounds("left", nil, self.slot_widget)
		:SetScale(0.6)
		:Offset(-45, 0)

	self.stats_desc:LayoutBounds(nil, "bottom", angled_panel)
		:Offset(0, 20)
end)

function ArmoryEquipmentPanel:SetOnClickChangeEquipment(fn)
	self.on_change_equipment_fn = fn
	return self
end

-------------------------------------------------------------
-- The tall panel for each player that holds the equipment panels
-------------------------------------------------------------
local ArmoryPanel = Class(GenericPlayerPanel, function(self, player)
	GenericPlayerPanel._ctor(self, player, STRINGS.UI.ARMORYSCREEN.TITLE)

	self.player = player

	local contents = self:GetContents()
	local offset_y = -50

	self.equipment = contents:AddChild(Widget())
		:SetRegistration("center", "top")
		:Offset(0, offset_y)

	self.change_equipment = contents:AddChild(ArmoryEquipmentChanger(player))
		:SetRegistration("center", "top")
		:Offset(0, offset_y)
		:SetOnSelectEquipment( function() self:OnSelectEquipment() end )
		:SetOnHoverEquipment(function(item, slot) self:OnHoverEquipment(item, slot) end)
		:SetEnableBackButton(true)
		:Hide()

	self:Refresh()

	self.weight_angled_panel = contents:AddChild(Panel("images/ui_ftf/angled_panel.tex"))
		:SetName("Panel")
		:SetNineSliceCoords(34, 48, 199, 197)
		:SetSize(INNER_PANEL_WIDTH, 220)
		:SetMultColor(UICOLORS.LIGHT_BACKGROUNDS_MID)
		:LayoutBounds("center", "below", self.equipment)
		:Offset(0, -20)

	self.weight_title = contents:AddChild(Text(FONTFACE.DEFAULT, 70, STRINGS.UI.ARMORYSCREEN.WEIGHT, UICOLORS.LIGHT_TEXT_DARKER))
		:SetAutoSize(self.contentWidth)
		:LeftAlign()
		:LayoutBounds("center", "top", self.weight_angled_panel)
		:Offset(0, -10)

	self.title_decor_left = self.weight_title:AddChild(Image("images/ui_ftf_inventory/InventoryTitleDecorLeft.tex"))
		:SetSize(80, 80)
		:SetMultColor(UICOLORS.LIGHT_TEXT_DARK)
		:SetMultColorAlpha(0.5)
		:LayoutBounds("before", "center", self.weight_title)
		:Offset(-20, 0)

	self.title_decor_right = self.weight_title:AddChild(Image("images/ui_ftf_inventory/InventoryTitleDecorRight.tex"))
		:SetSize(80, 80)
		:SetMultColor(UICOLORS.LIGHT_TEXT_DARK)
		:SetMultColorAlpha(0.5)
		:LayoutBounds("after", "center", self.weight_title)
		:Offset(20, 0)

	self.weight = contents:AddChild(TotalWeightWidget(player, 0.7))
		:LayoutBounds("center", "below", self.weight_title)
		:SetRotation(90)
		:Offset(0, 220)
		:SetNavFocusable(true)
		:ShowToolTipOnFocus(true)
		:SetBracketSizeOverride(INNER_PANEL_WIDTH, 220)
		:SetFocusBracketsOffset(0, 40)

	self.equipment_panels = {}

	self.forward_default_focus = function()
		if self.change_equipment:IsShown() then
			return self.change_equipment
		else
			return self.weight
		end
	end
end)

ArmoryPanel.CONTROL_MAP =
{
	{
		control = Controls.Digital.CANCEL,
		fn = function(self)
			if self.change_equipment:IsShown() then
				self:OnSelectEquipment()
			else
				self.screen:OnCloseButton()
			end
			return true
		end,
	},
}

function ArmoryPanel:Refresh()
	ArmoryPanel._base.Refresh(self)
	self.equipment:RemoveAllChildren()
	self.equipment_panels = {}

	self:CreateEquipmentPanel(Equipment.Slots.HEAD)
	self:CreateEquipmentPanel(Equipment.Slots.BODY)
	self:CreateEquipmentPanel(Equipment.Slots.WAIST)

	self.equipment:Show()
end

local get_weights = function(player)
	local weights = {}
	local relevant_slots = { Equipment.Slots.WEAPON, Equipment.Slots.HEAD, Equipment.Slots.BODY, Equipment.Slots.WAIST }
	for _, slot in ipairs(relevant_slots) do
		local item = player.components.inventoryhoard:GetEquippedItem(slot)

		local def = item and item:GetDef()
		weights[slot] = def and def.weight or Weight.EquipmentWeight.s.None
	end

	return weights
end

function ArmoryPanel:OnClickChangeEquipment(slot)
	self.equipment:Hide()
	local focus = self.change_equipment:DisplayEquipment(slot)
	focus:SetFocus(self:GetOwningPlayer():GetHunterId())
end

function ArmoryPanel:OnHoverEquipment(item, slot)
	--update weight and puppet
	local player = self:GetOwningPlayer()
	local weights = get_weights(player)

	if slot ~= nil then
		weights[slot] = item and item:GetDef().weight or Weight.EquipmentWeight.s.None
	end

	self.weight:PreviewByListOfWeights(weights)
end

function ArmoryPanel:OnSelectEquipment()
	self:Refresh()
	self.change_equipment:Hide()

	local player = self:GetOwningPlayer()
	self.weight:UpdateByListOfWeights(get_weights(player))

	-- Check what this screen should focus on next, since the list is now gone
	local target_focus = nil
	if self.change_equipment.slot ~= nil then
		target_focus = self.equipment_panels[self.change_equipment.slot].slot_widget
		self.change_equipment.slot = nil
	else
		target_focus = self:FindDefaultFocus()
	end

	self:SetPanelFocus(target_focus)
end

function ArmoryPanel:CreateEquipmentPanel(slot)
	local player = self:GetOwningPlayer()

	local panel = ArmoryEquipmentPanel(player, slot)
	panel:SetOnClickChangeEquipment(function()
		self:OnClickChangeEquipment(slot)
	end)

	self.equipment_panels[slot] = panel

	self.equipment:AddChild(panel)

	self.equipment:LayoutChildrenInColumn(20)
end

local ArmoryScreen = Class(GenericPlayerScreen, function(self, player)
	GenericPlayerScreen._ctor(self, player, "ArmoryScreen")

	local use_large = playerutil.CountLocalPlayers() <= 1
	for h_id, player in playerutil.LocalPlayers() do
		local p = self:AddPanel(ArmoryPanel(player))
		if use_large then
			p:UseLargePuppet()
		end
	end
end)

return ArmoryScreen
