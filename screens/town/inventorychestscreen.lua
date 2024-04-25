local GenericPlayerScreen = require"screens.town.genericplayerscreen"
local GenericPlayerPanel = require"widgets.ftf.genericplayerpanel"

local Widget = require"widgets.widget"
local Text = require"widgets.text"
local Panel = require"widgets.panel"
local Image = require"widgets.image"
local ExpandingTabGroup = require "widgets/expandingtabgroup"

local ItemWidget = require"widgets.ftf.itemwidget"

local ItemCatalog = require"defs.itemcatalog"
local Consumable = require"defs.consumable"
local monsterutil = require"util.monsterutil"

local biomes = require"defs.biomes"
local playerutil = require "util.playerutil"
local fmodtable = require "defs.sound.fmodtable"

local INNER_PANEL_WIDTH = 760

local InventorySelector = Class(Widget, function(self, player)
	Widget._ctor(self, "InventorySelector")

	self.player = player

	self.bg = self:AddChild(Panel("images/ui_ftf/angled_panel.tex"))
		:SetName("Panel")
		:SetNineSliceCoords(34, 48, 199, 197)
		:SetSize(INNER_PANEL_WIDTH, 1300)
		:SetMultColor(UICOLORS.LIGHT_BACKGROUNDS_MID)

	self.title_container = self:AddChild(Widget())
	self.title = self.title_container:AddChild(Text(FONTFACE.DEFAULT, 80, "testing", UICOLORS.LIGHT_TEXT_DARKER))
		:SetRegionSize(500, 70)
		:ShrinkToFitRegion()
		--:LeftAlign()
	self.title_decor_left = self.title_container:AddChild(Image("images/ui_ftf_inventory/InventoryTitleDecorLeft.tex"))
		:SetSize(80, 80)
		:SetMultColor(UICOLORS.LIGHT_TEXT_DARK)
		:SetMultColorAlpha(0.5)
	self.title_decor_right = self.title_container:AddChild(Image("images/ui_ftf_inventory/InventoryTitleDecorRight.tex"))
		:SetSize(80, 80)
		:SetMultColor(UICOLORS.LIGHT_TEXT_DARK)
		:SetMultColorAlpha(0.5)

	self.owned_items = self:AddChild(Widget("Owned Items"))
end)

function InventorySelector:SetLocation(location)
	self.title:SetText(location.pretty.name)

	self.title:LayoutBounds("center", "top", self.bg)
		:Offset(0, -20)
	self.title_decor_left:LayoutBounds("before", "center", self.title)
		:Offset(-20, 0)
	self.title_decor_right:LayoutBounds("after", "center", self.title)
		:Offset(20, 0)

	self.owned_items:RemoveAllChildren()

	--get the list of items that are in this location
	local full_item_list = monsterutil.GetItemsInLocation(location)
	table.sort(full_item_list, Consumable.CompareDef_ByRarityAndName)
	for _, item in ipairs(full_item_list) do
		local count = self.player.components.inventoryhoard:GetStackableCount(item)
		local item_widget = self.owned_items:AddChild(ItemWidget(item, count, 170))
											:SetNavFocusable(true)
											:ShowToolTipOnFocus(true)

		if count == 0 then
			item_widget:SetMultColor(HexToRGB(0x777777ff))
		end
	end


	self.num_columns = 4
	self.owned_items:LayoutChildrenInGrid(self.num_columns, 10)
		:LayoutBounds("center", "below", self.title)
		:Offset(0, -20)	

	self:RenavControls()

	self.focus_forward = self.owned_items.children[1]
	return self
end

function InventorySelector:RenavControls()
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

local InventoryChestPanel = Class(GenericPlayerPanel, function(self, player)
	GenericPlayerPanel._ctor(self, player, STRINGS.UI.INVENTORYCHESTSCREEN.TITLE)

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

	--get sorted locations
	local locations = {}
	for _, location_group in ipairs( biomes.location_unlock_order ) do
		for _, location in ipairs(location_group) do 
			table.insert(locations, location)
		end
	end

	for _, location in pairs(locations) do
		if location.region_id ~= biomes.starting_region and player.components.unlocktracker:IsLocationUnlocked(location.id) then
			local tab_btn = self.categories
				:AddTab(location.icon)
				:SetToolTip(location.pretty.name)
				:ShowToolTipOnFocus(true)

			tab_btn.category = location
		end
	end

	self.categories:Layout()

	local tabs_w, tabs_h = self.categories:GetSize()
	self.categories_bg
		:SetSize(tabs_w + 100, tabs_h + 60)
		:LayoutBounds("center", "center", self.categories_container)

	self.categories
		:LayoutBounds("center", "center", self.categories_bg)

	if self.categories:GetNumTabs() > 1 then
		self.categories:AddCycleIcons(60, 40, UICOLORS.LIGHT_TEXT_DARK)
	end

	self.categories_container
		:LayoutBounds("center", "below", self.title_bg)
		:Offset(0, -30)

	self.selector = self.contents:AddChild(InventorySelector(player))
		:LayoutBounds("center", "below", self.categories_container)
		:Offset(0, -40)

	self.categories:SetNavFocusable(false) -- rely on CONTROL_MAP

	self.forward_default_focus = function()
		return self.selector.owned_items:GetFirstChild()
	end
end)

function InventoryChestPanel:OnOpenPanel()
	self.categories:OpenTabAtIndex(1)
end

function InventoryChestPanel:RefreshCategories()
	self.selector:SetLocation(self.selected_category)
	if #self.selector.owned_items.children > 0 then
		self.selector.owned_items.children[1]:SetFocus()
	end
end

InventoryChestPanel.CONTROL_MAP =
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

local InventoryChestScreen = Class(GenericPlayerScreen, function(self, player)
	GenericPlayerScreen._ctor(self, player, "InventoryChestScreen")
	playerutil.DoForAllLocalPlayers(function(player)
		self:AddPanel(InventoryChestPanel(player))
	end)

	--self:AddPanel(InventoryChestPanel(player))
end)

return InventoryChestScreen
