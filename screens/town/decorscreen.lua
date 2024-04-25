local GenericPlayerScreen = require"screens.town.genericplayerscreen"

local Widget = require("widgets/widget")
local Image = require("widgets/image")
local Panel = require("widgets/panel")
local Text = require("widgets/text")
local ActionButton = require("widgets/actionbutton")
local ExpandingTabGroup = require "widgets/expandingtabgroup"

local fmodtable = require "defs.sound.fmodtable"
local ItemCatalog = require("defs.itemcatalog")
local Consumable = require("defs.consumable")
local Constructable = require "defs.constructable"
local Recipes = require "defs.recipes"
local biomes = require"defs.biomes"

local GenericPlayerPanel = require"widgets.ftf.genericplayerpanel"
local DecorWidget = require("widgets/ftf/decorwidget")

local LockedMetaRewardWidget = require("widgets/ftf/lockedmetarewardwidget")

local lume = require"util.lume"
local monsterutil = require"util.monsterutil"
local playerutil = require "util.playerutil"
local itemforge = require"defs.itemforge"
local easing = require "util.easing"

local INNER_PANEL_WIDTH = 760

local DecorSelector = Class(Widget, function(self, player, panel)
	Widget._ctor(self, "DecorSelector")

	self.player = player
	self.panel = panel

	self.bg = self:AddChild(Panel("images/ui_ftf/angled_panel.tex"))
		:SetName("Panel")
		:SetNineSliceCoords(34, 48, 199, 197)
		:SetSize(INNER_PANEL_WIDTH, 1300)
		:SetMultColor(UICOLORS.LIGHT_BACKGROUNDS_MID)

	self.title_container = self:AddChild(Widget())
	self.title = self.title_container:AddChild(Text(FONTFACE.DEFAULT, 80, "testing", UICOLORS.LIGHT_TEXT_DARKER))
        :SetRegionSize(480, 70)
        :EnableWordWrap(true)
        :ShrinkToFitRegion(true)
	self.title_decor_left = self.title_container:AddChild(Image("images/ui_ftf_inventory/InventoryTitleDecorLeft.tex"))
		:SetSize(80, 80)
		:SetMultColor(UICOLORS.LIGHT_TEXT_DARK)
		:SetMultColorAlpha(0.5)
	self.title_decor_right = self.title_container:AddChild(Image("images/ui_ftf_inventory/InventoryTitleDecorRight.tex"))
		:SetSize(80, 80)
		:SetMultColor(UICOLORS.LIGHT_TEXT_DARK)
		:SetMultColorAlpha(0.5)

	self.decor_items = self:AddChild(Widget("Decor Items"))
end)

local get_displayed_items = function(player, category)
	local unlocked_locations = {}
	for _, location in pairs(biomes.locations) do
		if location.region_id ~= biomes.starting_region and player.components.unlocktracker:IsLocationUnlocked(location.id) then
			table.insert(unlocked_locations, location)
		end
	end

	--only show items where you have the dungeon unlocked for the ingredients
	local full_item_list = {}
	for _, location in ipairs(unlocked_locations) do
		local item_list = monsterutil.GetItemsInLocation(location)
		for _, item in ipairs(item_list) do
			table.insert(full_item_list, item.name)
		end
	end
	
	local ordered_slots = shallowcopy(Constructable.GetOrderedSlots())
	-- Buildings are only built by hiring npcs.
	lume.remove(ordered_slots, Constructable.Slots.BUILDINGS)
	lume.remove(ordered_slots, Constructable.Slots.FAVOURITES)

	local items = {}
	for _, slot in ipairs(ordered_slots) do
		table.appendarrays(items, Constructable.GetItemList(slot, {category}))
	end
	
	local decor_items = {}
	for _, item in pairs(items) do
		local ingredients_available = true
		--go through ingredients
		for ingredient_name, _ in pairs(item.ingredients) do
			if table.find(full_item_list, ingredient_name) == nil then
				ingredients_available = false
			end
		end
		
		-- check if you can possibly get the material, or if it's already unlocked
		if ingredients_available or player.components.unlocktracker:IsRecipeUnlocked(item.name) then
			table.insert(decor_items, item)
		end
	end

	return decor_items
end

function DecorSelector:SetCategory(category)
	self.items = {}

	self.title:SetText(category == "basic" and STRINGS.UI.DECORSCREEN.BASIC_CATEGORY or STRINGS.LOCATIONS[category].name)

	self.title:LayoutBounds("center", "top", self.bg)
		:Offset(0, -20)
	self.title_decor_left:LayoutBounds("before", "center", self.title)
		:Offset(-20, 0)
	self.title_decor_right:LayoutBounds("after", "center", self.title)
		:Offset(20, 0)

	self.decor_items:RemoveAllChildren()

	local items_to_add = get_displayed_items(self.player, category)
	table.sort(items_to_add, Consumable.CompareDef_ByRarityAndName)

	self.num_columns = 4
	--local icon_size = #items_to_add < 20 and 170 or 210

	for _, item in ipairs(items_to_add) do
		self.decor_items:AddChild(DecorWidget(self.player, item, 170))
			:SetOnGainHover( function() self.panel:RefreshNewStatus() end )
			--:SetNavFocusable(true)
	end

	self.decor_items
		:LayoutChildrenInGrid(self.num_columns, 10)
		:LayoutBounds("center", "below", self.pickup_btn)
		:MoveToFront()
		:Offset(0, -20)

	self:RenavControls()
end

function DecorSelector:RenavControls()
	-- Go through list and make items nav correctly to each other
	local widgets = self.decor_items:GetChildren()
	for i, v in ipairs(widgets) do
		if i > 1 then
			v:SetFocusDir("left", widgets[i-1], true)
		end
		if i > self.num_columns then
			v:SetFocusDir("up", widgets[i-self.num_columns], true)
		end
	end
end

function DecorSelector:GetItems()
	return self.decor_items
end

local DecorPanel = Class(GenericPlayerPanel, function(self, player)
	GenericPlayerPanel._ctor(self, player, STRINGS.UI.DECORSCREEN.TITLE)

	local contents = self:GetContents()
	
	self.categories_container = contents:AddChild(Widget())
	self.categories_bg = self.categories_container:AddChild(Panel("images/ui_ftf_research/research_tabs_bg.tex"))
		:SetName("Tabs background")
		:SetNineSliceCoords(26, 0, 195, 150)
		:SetMultColor(UICOLORS.LIGHT_BACKGROUNDS_DARK)

	self.categories = self.categories_container:AddChild(ExpandingTabGroup("Categories"))
		:SetTabOnClick(function(tab_btn)
			self.selected_category = tab_btn.category
			self:RefreshCategories()
		end)

	local unlocked_locations = {{id = "basic", icon = "images/icons_ftf/build_buildings.tex"}}
	for _, location_t in pairs(biomes.location_unlock_order) do -- Using the unlock order here to make sure decorations abide by it
		local location = location_t[1]
		if location.region_id ~= biomes.starting_region and player.components.unlocktracker:IsLocationUnlocked(location.id) then
			table.insert(unlocked_locations, location)
		end
	end

	self.category_btns = {}
	for i,location in pairs(unlocked_locations) do

		-- Add a button per category
		local category_btn = self.categories
			:AddTab(location.icon)--category.icon)
			:SetToolTip(location.id == "basic" and STRINGS.UI.DECORSCREEN.BASIC_CATEGORY or STRINGS.LOCATIONS[location.id].name)--category.pretty.name)
			:ShowToolTipOnFocus(true)
			:SetStarIcon()

		category_btn.category = location.id
		table.insert(self.category_btns, { button=category_btn, location=location.id })
	end

	self.categories:Layout()

	if self.categories:GetNumTabs() > 1 then
		self.categories:AddCycleIcons(60, 40, UICOLORS.LIGHT_TEXT_DARK)
	end

	local tabs_w, tabs_h = self.categories:GetSize()
	self.categories_bg
		:SetSize(tabs_w + 100, tabs_h + 60)
		:LayoutBounds("center", "center", self.categories_container)

	self.categories
		:LayoutBounds("center", "center", self.categories_bg)

	self.categories:SetNavFocusable(false)

	self.categories_container
		:LayoutBounds("center", "below", self.title_bg)
		:Offset(0, -30)

	self.decor_selector = contents:AddChild(DecorSelector(player, self))
		:LayoutBounds("center", "below", self.categories_container)
		:Offset(0, -40)

	local can_pickup_net = TheNet:GetLocalTownPropEditPrivilege() ~= 0

	local btn_scale = 0.6
	self.pickup_btn = contents:AddChild(ActionButton())
		:SetSize(BUTTON_W, BUTTON_H)
		:SetScale(btn_scale)
		:SetNormalScale(btn_scale)
		:SetFocusScale(btn_scale)
		:SetText(STRINGS.UI.DECORSCREEN.PICKUP)
		:LayoutBounds("center", "below", self.decor_selector)
		:Offset(0, -20)
		:SetOnClick(function()
			player.components.playercontroller:StartPropRemover()
			self.on_close_fn()
		end)
		:SetEnabled(can_pickup_net)

	if not can_pickup_net then
		self.pickup_btn:SetToolTip(STRINGS.UI.DECORSCREEN.NO_PERMISSION)
	end

	self.forward_default_focus = function()
		local children = self.decor_selector:GetItems():GetChildren()
		if #children > 0 then
			return children[1].icon
		end
		return self.pickup_btn
	end
end)

function DecorPanel:OnOpenPanel()
	self.categories:OpenTabAtIndex(1)
end

DecorPanel.CONTROL_MAP =
{
	{
		control = Controls.Digital.MENU_TAB_PREV,
		hint = function(self, left, right)
			table.insert(right, loc.format(LOC"UI.CONTROLS.PREV_TAB", Controls.Digital.MENU_TAB_PREV))
		end,
		fn = function(self)
			self.categories:NextTab(-1)
			TheFrontEnd:GetSound():PlaySound(fmodtable.Event.input_down)
			return true
		end,
	},
	{
		control = Controls.Digital.MENU_TAB_NEXT,
		hint = function(self, left, right)
			table.insert(right, loc.format(LOC"UI.CONTROLS.NEXT_TAB", Controls.Digital.MENU_TAB_NEXT))
		end,
		fn = function(self)
			self.categories:NextTab(1)
			TheFrontEnd:GetSound():PlaySound(fmodtable.Event.input_down)
			return true
		end,
	},
}

function DecorPanel:SetOnCloseFn(on_close_fn)
	self.on_close_fn = on_close_fn
end

function DecorPanel:RefreshCategories()
	self.decor_selector:SetCategory(self.selected_category)
	self:Refresh()

	self:FindDefaultFocus():SetFocus(self:GetOwningPlayer():GetHunterId())
end

function DecorPanel:RefreshNewStatus()
	local player = self:GetOwningPlayer()
	for _, category_btn in ipairs(self.category_btns) do
		category_btn.button:ShowAvailableActionIcon(false)
		local items = get_displayed_items(player, category_btn.location)
		for _, item in pairs(items) do
			if not player.components.hasseen:HasSeenDecor(item.name) and player.components.unlocktracker:IsRecipeUnlocked(item.name) then
				category_btn.button:ShowAvailableActionIcon(true)
			end
		end
	end
end

function DecorPanel:Refresh()

	for _, v in ipairs(self.decor_selector:GetItems():GetChildren()) do
		v:Refresh()
			:SetOnClick( function() self:OnClickItem(v:GetDef()) end )
			:SetOnRightClick( function() self:OnRightClickItem(v:GetDef(), v) end )
	end

	self:RefreshNewStatus()
end

function DecorPanel:GiveCraftBounty(item_def, widget)

	self:GetOwningPlayer().components.hasmade:MarkDecorAsMade(item_def.name)

	local reward_id, reward_count = Constructable.GetFirstCraftBounty(item_def)
	local reward_def = Consumable.FindItem(reward_id)
	local fake_item = itemforge.CreateKeyItem(reward_def)
	local bounty = self:AddChild(LockedMetaRewardWidget(160, self:GetOwningPlayer(), fake_item, reward_count, true))

	bounty:LayoutBounds("center", "center", widget)--(widget:GetPos())

	self:GetOwningPlayer().components.inventoryhoard:AddStackable(reward_def, reward_count)

	local end_pos_x, end_pos_y = bounty:GetPos()

	local move_y = 120
	self:RunUpdater(
		Updater.Series{
			Updater.Ease(function(v) bounty:SetPos(end_pos_x, v) end, end_pos_y, end_pos_y + move_y, 0.5, easing.outElastic),
			Updater.Wait(0.5),
			Updater.Ease(function(v) bounty:SetPos(end_pos_x, v) end, end_pos_y + move_y, end_pos_y + 40, 0.1, easing.outQuad),
			Updater.Do(function()
				bounty:Remove()
			end),
		}
	)

end

function DecorPanel:OnRightClickItem(item_def, widget)
	local player = self:GetOwningPlayer()
	local recipe = Recipes.ForSlot[item_def.slot][item_def.name]

	if recipe:CanPlayerCraft(player) then
		recipe:TakeIngredientsFromPlayer(player)
		player.components.inventoryhoard:AddStackable(item_def, 1)
		TheFrontEnd:GetSound():PlaySound(fmodtable.Event.inventory_craft_hide)

		if not player.components.hasmade:HasMadeDecor(item_def.name) then
			self:GiveCraftBounty(item_def, widget)
		end

		self:Refresh()
	end
end

function DecorPanel:OnClickItem(item_def)

	if not TheNet:CanPlaceTownProp() then
		return
	end

	local player = self:GetOwningPlayer()

	if player.components.inventoryhoard:GetStackableCount(item_def) == 0 then
		return
	end

	local function validate_fn()
		-- do you still have existing items or still have materials
		local can_place = player.components.inventoryhoard:GetStackableCount(item_def) > 0

		if not can_place then
			return false
		end

		return can_place
	end	

	local function on_cancel(placer, placed_ent)
		player:DoTaskInTime(0.65, function() 
			TheDungeon.HUD.townHud:OnCraftButtonClicked(player)
		end)
	end

	local function on_success(placer, placed_ent)
		dbassert(player.components.inventoryhoard:GetStackableCount(item_def) > 0)
		player.components.inventoryhoard:RemoveStackable(item_def, 1)

		if player.components.inventoryhoard:GetStackableCount(item_def) < 1 then
			player.components.playercontroller:StopPlacer()
		end

		TheFrontEnd:GetSound():PlaySound(fmodtable.Event.place_building)
	end

	self.on_close_fn()
	local prefab = item_def.name
	player.components.playercontroller:StartPlacer(prefab.."_placer", validate_fn, on_success)--, on_cancel)

	TheFrontEnd:GetSound():PlaySound(fmodtable.Event.input_down)
end

local DecorScreen = Class(GenericPlayerScreen, function(self, player)
	GenericPlayerScreen._ctor(self, player, "DecorScreen")
	
	playerutil.DoForAllLocalPlayers(function(local_player)
		self:AddPanel(DecorPanel(local_player))
			:SetOnCloseFn( function() self:OnCloseButton() end )

			local controller = local_player.components.playercontroller
			if controller:IsPlacing() then
				controller:OnCancelPlacer()
			elseif controller:IsRemovingProp() then
				controller:StopPropRemover()
			end
	end)
end)

return DecorScreen
