local GenericPlayerScreen = require"screens.town.genericplayerscreen"

local Widget = require"widgets.widget"
local Panel = require"widgets.panel"
local Text = require"widgets.text"
local ImageButton = require"widgets.imagebutton"
local Image = require"widgets.image"
local UIAnim = require"widgets.uianim"

local ItemCatalog = require"defs.itemcatalog"
local itemforge = require"defs.itemforge"
local playerutil = require "util.playerutil"
local Equipment = require"defs.equipment"
local fmodtable = require"defs.sound.fmodtable"
local Power = require"defs.powers"
local Recipes = require "defs.recipes"

local GenericPlayerPanel = require"widgets.ftf.genericplayerpanel"
local InventorySlot = require "widgets.ftf.inventoryslot"
local ItemWidget = require("widgets/ftf/itemwidget")
local DisplayStat = require "widgets.ftf.displaystat"
local EquipmentTooltip = require "widgets/ftf/equipmenttooltip"
local EquipmentDescriptionWidget = require"widgets.ftf.equipmentdescriptionwidget"
local PowerDescriptionWidget = require("widgets/ftf/powerdescriptionwidget")
local TotalWeightWidget = require "widgets.ftf.totalweightwidget"
local ArmoryEquipmentChanger = require "widgets.ftf.armoryequipmentchanger"
-- local SkillIconWidget = require "widgets.skilliconwidget"
local SkillWidget = require"widgets.ftf.skillwidget"
local EquipmentUpgradeTooltip = require"widgets.ftf.equipmentupgradetooltip"

local itemutil = require "util.itemutil"
local Enum = require "util.enum"
local color = require "math.modules.color"
local Weight = require "components.weight"

local INNER_PANEL_WIDTH = 760

local UPGRADE_TYPE = Enum
{
	"SKILL_UPGRADE",
	"ATTACK_UPGRADE"
}

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

-----------------------------------------------------
-- The text and level up button combo
-----------------------------------------------------
local WeaponLevelWidget = Class(Widget, function(self, player, item, upgrade_type, display_widget)
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

	--no hamish, no upgrade
	if TheWorld:IsFlagUnlocked("wf_town_has_blacksmith") then
		self.level_up
			:SetOnClick( function() self:OnClickUpgradeItem() end )
			:SetToolTipClass(EquipmentUpgradeTooltip)
			:SetControlUpSound(nil)
	else
		local tt = STRINGS.UI.WEAPONSELECTIONSCREEN.NO_BLACKSMITH_TT

		if self.player:IsLocationUnlocked("owlitzer_forest") then
			tt = STRINGS.UI.WEAPONSELECTIONSCREEN.NO_BLACKSMITH_HAS_LOCATION_TT
		end

		self.level_up
			:Disable()
			:SetMultColor(HexToRGB(0x999999ff))
			:SetSaturation(0.15)
			:SetToolTip(tt)
	end

	self.inst:ListenForEvent("inventory_changed", function() self:Refresh() end, self.player)
end)

function WeaponLevelWidget:_SetHoverFn(fn)
	self._hover_fn = fn
end

function WeaponLevelWidget:Refresh()
	self.upgrade_recipe = nil
	local txt
	local hover_fn

	--depending what I'm upgrading, figure out the fns and text
	if self.upgrade_type == UPGRADE_TYPE.id.ATTACK_UPGRADE then
		local level = self.item:GetUpgradeLevel()
		txt = string.format(STRINGS.UI.WEAPONSELECTIONSCREEN.ATTACK_LVL, level)

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
		txt = string.format(STRINGS.UI.WEAPONSELECTIONSCREEN.SKILL_LVL, self.item:GetUsageLevel())
		self.upgrade_recipe = Recipes.FindUsageUpgradeRecipeForItem(self.item)

		if self.upgrade_recipe then
			dbassert(self.display_widget:is_a(PowerDescriptionWidget))
			hover_fn = function()
				local def = self.item:GetDef()
				local usagelvl = self.item:GetUsageLevel()
				local power_def = Power.FindPowerByName(def.usage_data.power_on_equip)
				local power = itemforge.CreatePower(power_def)
				local current_stacks = power_def.stacks_per_usage_level and power_def.stacks_per_usage_level[usagelvl]
				local next_stacks = power_def.stacks_per_usage_level and power_def.stacks_per_usage_level[usagelvl + 1]
				power.stacks = current_stacks

				self.display_widget:SetPower(power, next_stacks, true)
			end
		end
	end 

	--set up hover / unhover fns
	self:_SetHoverFn(hover_fn)

	local losehover_fn = function() 
		if self.display_widget:is_a(PowerDescriptionWidget) then
			local def = self.item:GetDef()
			local usagelvl = self.item:GetUsageLevel()
			local power_def = Power.FindPowerByName(def.usage_data.power_on_equip)
			local power = itemforge.CreatePower(power_def)
			local current_stacks = power_def.stacks_per_usage_level and power_def.stacks_per_usage_level[usagelvl]
			power.stacks = current_stacks
			self.display_widget:SetPower(power, nil, true)
		else
			self.display_widget:SetItem(self.item)
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

function WeaponLevelWidget:OnClickUpgradeItem()
	local player = self:GetOwningPlayer()

	if self.upgrade_recipe == nil or not self.upgrade_recipe:CanPlayerCraft(player) then
		TheFrontEnd:GetSound():PlaySound(fmodtable.Event.ui_action_blocked)
		return
	end

	if self.upgrade_type == UPGRADE_TYPE.id.ATTACK_UPGRADE then
		self.item:UpgradeItemLevel()
	else
		self.item:UpgradeUsageLevel()
	end

	--take the ingredients from the player
	self.upgrade_recipe:TakeIngredientsFromPlayer(player)
	

	if self.display_widget:is_a(PowerDescriptionWidget) then
		local def = self.item:GetDef()
		local usagelvl = self.item:GetUsageLevel()
		local power_def = Power.FindPowerByName(def.usage_data.power_on_equip)
		local power = itemforge.CreatePower(power_def)
		local current_stacks = power_def.stacks_per_usage_level and power_def.stacks_per_usage_level[usagelvl]
		power.stacks = current_stacks
		self.display_widget:SetPower(power, nil, true)
	else
		self.display_widget:SetItem(self.item)
	end

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
local WeaponPanel = Class(Widget, function(self, player, slot)
	Widget._ctor(self, "WeaponPanel")

	self.player = player
	self.slot = slot

	local angled_panel = self:AddChild(Panel("images/ui_ftf/angled_panel.tex"))
		:SetName("Panel")
		:SetNineSliceCoords(34, 48, 199, 197)
		:SetSize(INNER_PANEL_WIDTH, 820)
		:SetMultColor(UICOLORS.BACKGROUND_MID)

	local common = ItemCatalog.All.SlotDescriptor[slot]
	self.equipped_item = player.components.inventoryhoard:GetEquippedItem(slot)

	self.slot_widget =	self:AddChild( ItemWidget(nil, nil, 175) ) -- InventorySlot(200, common.icon))
		:SetNavFocusable(true)
		:SetToolTipClass(EquipmentTooltip)
		:ShowToolTipOnFocus(true)
		:SetItem(self.equipped_item:GetDef())--, player)
		:LayoutBounds("left", "top", angled_panel)
		:Offset(25, -20)
		:HideQuantity()
		:SetToolTip{ item = self.equipped_item, player = self.player }

	local def = self.equipped_item:GetDef()
	local rarity = def.rarity or "COMMON"
	local item_name = string.format("<#%s>%s</>", rarity, self.equipped_item:GetLocalizedName())

	local desc_width = 500

	self.title = self:AddChild(Text(FONTFACE.DEFAULT, FONTSIZE.SCREEN_SUBTITLE, item_name))
		:LeftAlign()
        :SetRegionSize(desc_width, 70)
        :EnableWordWrap(true)
        :ShrinkToFitRegion(true)
		:LayoutBounds("after", "top", self.slot_widget)
		:Offset(20, -10)

	self.flavor = self:AddChild(Text(FONTFACE.DEFAULT, FONTSIZE.SCREEN_TEXT, string.format("<i>%s</>", def.pretty.desc), UICOLORS.LIGHT_TEXT_DARKER))
		:LeftAlign()
		:SetAutoSize(desc_width)
		:LayoutBounds("left", "below", self.title)
		:Offset(0, -5)

	local padding = 5

	local showing_power = false

	if def.usage_data.power_on_equip then
		local usagelvl = self.equipped_item:GetUsageLevel()
		local power_def = Power.FindPowerByName(def.usage_data.power_on_equip)
		local power = itemforge.CreatePower(power_def)
		local current_stacks = power_def.stacks_per_usage_level and power_def.stacks_per_usage_level[usagelvl]
		power.stacks = current_stacks

		self.power_desc = self:AddChild(PowerDescriptionWidget(desc_width, FONTSIZE.SCREEN_TEXT, power, false, true))
			:LayoutBounds("left", "below", self.flavor)
			:Offset(0, -padding * 2)
			:SetVariableFontColor(UICOLORS.LIGHT_TEXT_DARK)

		showing_power = true
	end

	if def.usage_data.skill_on_equip then
		local icon_size = 133
		local skill_def = Power.FindPowerByName(def.usage_data.skill_on_equip)
		local skill = itemforge.CreatePower(skill_def)

		self.skill_icon = self:AddChild(SkillWidget(icon_size, self.player, skill))
		self.skill_text = self:AddChild(Widget("Skill Text"))
		self.skill_title = self.skill_text:AddChild(Text(FONTFACE.DEFAULT, FONTSIZE.TOOLTIP, skill_def.pretty.name, UICOLORS.LIGHT_TEXT))
			:SetRegionSize(desc_width, 70)
	        :ShrinkToFitRegion(true)
	        :LeftAlign()

		self.skill_desc = self.skill_text:AddChild(PowerDescriptionWidget(desc_width, FONTSIZE.SCREEN_TEXT, skill, false, false))
			:LayoutBounds("left", "below", self.skill_title)
			:Offset(0, -padding)

		if showing_power then
			self.skill_text:LayoutBounds("left", "below", self.power_desc)
				:Offset(0, -padding * 2)
		else
			self.skill_text:LayoutBounds(nil, "below", self.slot_widget)
				:LayoutBounds("left", nil, self.flavor)
				:Offset(0, -padding * 2)
		end

		self.skill_icon:LayoutBounds("center", nil, self.slot_widget)
		self.skill_icon:LayoutBounds(nil, "top", self.skill_title)
			:Offset(0, -30)
	end

	self.stats_desc = self:AddChild(ArmoryEquipmentStats(player))
		:SetItem(self.equipped_item)

	self.stats_desc
		:LayoutBounds("left", "below", self.slot_widget)
		:SetScale(0.6)
		:Offset(-45,0)

	self.stats_desc:LayoutBounds(nil, "bottom", angled_panel)
		:Offset(0, 20)

	self.def_level = self:AddChild(WeaponLevelWidget(player, self.equipped_item, UPGRADE_TYPE.id.ATTACK_UPGRADE, self.stats_desc))
		:Refresh()
		:LayoutBounds("right", "bottom", angled_panel)
		:Offset(-20, 20)

	if def.usage_data.power_on_equip ~= nil then
		self.usage_level = self:AddChild(WeaponLevelWidget(player, self.equipped_item, UPGRADE_TYPE.id.SKILL_UPGRADE, self.power_desc))
			:Refresh()
			:LayoutBounds("right", "above", self.def_level)
			:Offset(0, 10)
	end
end)

function WeaponPanel:SetOnClickChangeEquipment(fn)
	self.on_change_equipment_fn = fn
	return self
end

-------------------------------------------------------------
-- The tall panel for each player that holds the equipment panels
-------------------------------------------------------------
local WeaponSelectPanel = Class(GenericPlayerPanel, function(self, player, weapon_type)
	GenericPlayerPanel._ctor(self, player)

	self.weapon_type = weapon_type or WEAPON_TYPES.HAMMER

	self:SetTitle( string.format(STRINGS.UI.WEAPONSELECTIONSCREEN.TITLE, STRINGS.ITEM_CATEGORIES[self.weapon_type]) )

	local contents = self:GetContents()
	local offset_y = -20

	self.change_equipment = contents:AddChild(ArmoryEquipmentChanger(player, 730))
		:SetEnableTitle(false)
		:SetEnableUnequip(false)
		:SetRegistration("center", "top")
		:SetFilterFn( function(item)
			return item:GetDef().weapon_type == self.weapon_type
		end)
		:Offset(0, offset_y)
		:SetOnSelectEquipment( function() self:OnSelectEquipment() end )
		:SetOnHoverEquipment(function(item, slot) self:OnHoverEquipment(item, slot) end)

	self.equipment = contents:AddChild(Widget())
		:SetRegistration("center", "top")
		:LayoutBounds("center", "below", self.change_equipment)
		:Offset(0, offset_y)

	self.change_equipment:DisplayEquipment(Equipment.Slots.WEAPON)

	self:Refresh()

	self.weight_angled_panel = contents:AddChild(Panel("images/ui_ftf/angled_panel.tex"))
		:SetName("Panel")
		:SetNineSliceCoords(34, 48, 199, 197)
		:SetSize(INNER_PANEL_WIDTH, 220)
		:SetMultColor(UICOLORS.LIGHT_BACKGROUNDS_MID)
		:LayoutBounds("center", "bottom", self)
		:Offset(0, 350)

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

	self.forward_default_focus = self.change_equipment
end)

function WeaponSelectPanel:Refresh()
	WeaponSelectPanel._base.Refresh(self)
	self.equipment:RemoveAllChildren()

	self:CreateEquipmentPanel(Equipment.Slots.WEAPON)

	self.equipment:Show()
end

function WeaponSelectPanel:OnClickChangeEquipment(slot)
	local focus = self.change_equipment:DisplayEquipment(slot)
	focus:SetFocus(self:GetOwningPlayer():GetHunterId())
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

function WeaponSelectPanel:OnHoverEquipment(item, slot)
	--update attack value
	local player = self:GetOwningPlayer()	
	local weights = get_weights(player)

	if slot ~= nil then
		weights[slot] = item and item:GetDef().weight or Weight.EquipmentWeight.s.None
	end

	self.weight:PreviewByListOfWeights(weights)
end

function WeaponSelectPanel:OnSelectEquipment()
	self:Refresh()

	local player = self:GetOwningPlayer()
	self.weight:UpdateByListOfWeights(get_weights(player))
end

function WeaponSelectPanel:CreateEquipmentPanel(slot)
	local player = self:GetOwningPlayer()

	self.equipment:AddChild(WeaponPanel(player, slot))
		:SetOnClickChangeEquipment(function()
			self:OnClickChangeEquipment(slot)
		end)
end

local WeaponSelectionScreen = Class(GenericPlayerScreen, function(self, player, weapon_type)
	GenericPlayerScreen._ctor(self, player, "WeaponSelectionScreen")

	local use_large = playerutil.CountLocalPlayers() <= 1
	for h_id,hunter in playerutil.LocalPlayers() do
		local p = self:AddPanel(WeaponSelectPanel(hunter, weapon_type))
		if use_large then
			p:UseLargePuppet()
		end
	end
end)

return WeaponSelectionScreen
