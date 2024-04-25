local Screen = require("widgets/screen")
local Widget = require("widgets/widget")
local Image = require("widgets/image")
local ActionButton = require("widgets/actionbutton")

local GenericPlayerScreen = Class(Screen, function(self, player, screen_name)
	Screen._ctor(self, screen_name or "GenericPlayerScreen")

	self.darken = self:AddChild(Image("images/ui_ftf_roombonus/background_gradient.tex"))
		:SetAnchors("fill", "fill")
		:SetMultColor(UICOLORS.BLACK)
		:SetMultColorAlpha(BACKGROUND_DARK_ALPHA)

	self.panels = self:AddChild(Widget())
		:SetName("panels")
	self.panel_list = {}

	self.close_button = self:AddChild(ActionButton())
		:SetName("Close button")
		:SetScale(0.8)
		:SetText(STRINGS.UI.BUTTONS.CLOSE)
		:SetOnClick(function() self:OnCloseButton() end)
end)

function GenericPlayerScreen:AddPanel(panel)
	self.panels:AddChild(panel)
	table.insert(self.panel_list, panel)
	
	self.panels
	:LayoutChildrenInRow(10)
	--if there are 4 panels, shrink them
	:SetScale(#self.panels:GetChildren() == 4 and 0.95 or 1)
	:LayoutBounds("center", "center")

	self:_LayoutButton()

	panel.screen = self
	return panel
end

function GenericPlayerScreen:_LayoutButton()
	self.close_button
		:LayoutBounds("center", "bottom", self)
		:Offset(0, 20)
		:SendToFront()
	return self
end

function GenericPlayerScreen:OnOpen()
	self:EnableFocusBracketsForGamepad()

	for _, panel in ipairs(self.panel_list) do
		panel:OnOpenPanel()
	end

	self:_LayoutButton()
end

function GenericPlayerScreen:GetPlayerPanel(player)
	for _, panel in ipairs(self.panel_list) do
		if panel:GetOwningPlayer() == player then
			return panel
		end
	end
end

function GenericPlayerScreen:GetPlayerPanelByHunterID(hunter_id)
	for _, panel in ipairs(self.panel_list) do
		local owning_player = panel:GetOwningPlayer()
		if owning_player and owning_player:GetHunterId() == hunter_id then
			return panel
		end
	end
end

function GenericPlayerScreen:OnCloseButton()
	TheFrontEnd:PopScreen(self)
end

function GenericPlayerScreen:FindDefaultFocus(hunter_id)
	local player_panel = self:GetPlayerPanelByHunterID(hunter_id)
	local focus = player_panel and player_panel:FindDefaultFocus()
	-- Fallback to close button if nothing to select.
	return focus or self.close_button
end

function GenericPlayerScreen:OnBecomeActive()
	GenericPlayerScreen._base.OnBecomeActive(self)

	for _, panel in ipairs(self.panels:GetChildren()) do
		panel:AnimateIn()
	end

	TheDungeon.HUD:Hide()
end

function GenericPlayerScreen:OnBecomeInactive()
	GenericPlayerScreen._base.OnBecomeInactive(self)

	for _, panel in ipairs(self.panels:GetChildren()) do
		panel:AnimateOut()
	end

	TheDungeon.HUD:Show()
end

GenericPlayerScreen.CONTROL_MAP =
{
	{
		control = Controls.Digital.CANCEL,
		hint = function(self, left, right)
			table.insert(right, loc.format(LOC"UI.CONTROLS.CANCEL", Controls.Digital.CANCEL))
		end,
		fn = function(self)
			self:OnCloseButton()
			return true
		end,
	},
}

return GenericPlayerScreen
