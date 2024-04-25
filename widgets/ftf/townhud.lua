local Button = require "widgets.button"
local HotkeyWidget = require "widgets.hotkeywidget"
local HudButton = require "widgets.ftf.hudbutton"
local ArmoryScreen = require "screens.town.armoryscreen"
local DecorScreen = require "screens.town.decorscreen"
local TownHudWidget = require("widgets/ftf/townhudwidget")
local Widget = require("widgets/widget")
local Image = require("widgets/image")
local playerutil = require "util.playerutil"
local Constructable = require "defs.constructable"

-- The whole hud widget for in town.
local TownHud = Class(Widget, function(self, debug_root)
	Widget._ctor(self, "TownHud")
	self.debug_root = debug_root
end)

function TownHud:OnBecomeActive()
	if self.townHudWidget then
		self.townHudWidget:Refresh()
	end

	self:StartUpdating()
end

function TownHud:_Init()
	local player = self:GetOwningPlayer()
	dbassert(player)
	self.root = self:AddChild(Widget("TownHud_root"))
		:LayoutBounds("left", "top", self.parent)

	self.townHudWidget = self.root:AddChild(TownHudWidget(self.debug_root))
		:LayoutBounds("center", "top", self.parent)

	self.testButton = self.root:AddChild(Button())
		 :LayoutBounds("right", "bottom", self.parent)
		 :Offset(-20, 20)
		 :SetTextSize(48)

	self.craftButton = self.root:AddChild(self:_CreateHudButton(
			"images/ui_ftf_shop/hud_button_build.tex", 
			Controls.Digital.OPEN_CRAFTING, 
			STRINGS.CRAFT_WIDGET.HUD_HOTKEY,
			function() self:OnCraftButtonClicked(player) end))
		:LayoutBounds("left", "bottom", self.parent)
		:Offset(20, 40)
end

local any_decor_unlocked = function(player)
	for _, items in pairs(Constructable.Items) do
		for _, item in pairs(items) do
			if player.components.unlocktracker:IsRecipeUnlocked(item.name) then
				return true
			end
		end	
	end

	return false
end

local any_decor_is_new = function(player)
	for _, items in pairs(Constructable.Items) do
		for _, item in pairs(items) do
			if player.components.unlocktracker:IsRecipeUnlocked(item.name) and
				not player.components.hasseen:HasSeenDecor(item.name) then
				return true
			end
		end	
	end

	return false
end

function TownHud:OnUpdate()
	local player = self:GetOwningPlayer()
	if player == nil then
		return
	end

	if self.craftButton ~= nil then
		self.craftButton:SetShown( any_decor_unlocked(player) )
		self.craftButton.new_icon:SetShown( any_decor_is_new(player) )
	end
end

function TownHud:AttachPlayerToHud(player)
	--~ TheLog.ch.FrontEnd:print("TownHud:AttachPlayerToHud", player)
	if not self:GetOwningPlayer() then
		-- Only take the first player as the primary owner.
		self:SetOwningPlayer(player)
	end
	if not self.root then
		self:_Init()
	end
	self.townHudWidget:AttachPlayerToHud(player)
	return self
end

function TownHud:DetachPlayerFromHud(player)
	self.townHudWidget:DetachPlayerFromHud(player)
	return self
end

function TownHud:GetControlMap()
	-- if self.craftButton and self.craftButton:IsBarOpen() then
	-- 	return self.craftButton:GetControlMap()
	-- end
end

function TownHud:AnimateIn()
	-- TODO: Could have nicer animation, but this works for now.
	self:Show()
	return self
end

function TownHud:AnimateOut()
	self:Hide()
	return self
end

function TownHud:_CreateHudButton(icon, hotkey, text, onclick)
	local fn = function(device_type, device_id)
		local input_device = TheInput:GetInputDevice(device_type, device_id)
		local player = TheInput:GetDeviceOwner(input_device)
		-- Our UI generally works with mouse, so find a player if there's no mouse user.
		player = player or (device_type == "mouse" and playerutil.GetFirstLocalPlayer())
		if player then
			onclick(player)
		end
	end
	local button = Widget("CraftButton")
	button.btn = button:AddChild(HudButton(300, icon, UICOLORS.ACTION, fn))
	button.new_icon = button:AddChild(Image("images/ui_ftf/star.tex"))
		:SetScale(1.2)
		:LayoutBounds("right", "top", button.btn)
		:SetHiddenBoundingBox(true)
		:SetToolTip(STRINGS.CRAFT_WIDGET.NEW)
	button.hotkeyWidget = button:AddChild(HotkeyWidget(hotkey, text):SetWidgetSize(32))
		:LayoutBounds("center", "below", button.btn)
		:Offset(0, -10)
	button.hotkeyWidget:SetOnLayoutFn(function()
		button.hotkeyWidget:LayoutBounds("center", "below", button.btn)
			:Offset(0, -10)
	end)
	return button
end

-- Also called by playerhud to handle Controls.Digital.OPEN_CRAFTING hotkey
function TownHud:OnCraftButtonClicked(player)
	if self.craftButton:IsShown() and self.craftButton:IsEnabled() then
		TheFrontEnd:PushScreen(DecorScreen(player))
	end
end

-- Also called by playerhud to handle Controls.Digital.OPEN_INVENTORY hotkey
function TownHud:OnInventoryButtonClicked(player)
	if self.inventoryButton:IsShown() and self.inventoryButton:IsEnabled() then
		TheFrontEnd:PushScreen(ArmoryScreen(player))
	end
end

return TownHud
