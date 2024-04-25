local Widget = require "widgets/widget"
local Image = require ("widgets/image")
local easing = require"util/easing"
local Text = require ("widgets/text")
local TabGroup = require "widgets.tabgroup"
local Panel = require "widgets.panel"


local DiscordSharingSetting = Class(Widget, function(self)
	Widget._ctor(self, "DiscordSharingSetting")

	self.groups_container_widget = self:AddChild(Widget())
		:SetName("Groups container")
		:SendToBack()
		:SetMultColorAlpha(0)
		:Hide()

--	self.background = self.groups_container_widget:AddChild(Panel("images/ui_ftf/ButtonBackground.tex"))
--		:SetNineSliceCoords(30, 20, 520, 120)
--		:SetNineSliceBorderScale(1)
--		:SetClickable(false)
--		:SetSize(700,400)
--		:MoveToBack()

	self.background = self.groups_container_widget:AddChild(Panel("images/ui_ftf/dialog_bg.tex"))
		:SetName("Panel")
		:SetNineSliceCoords(50, 28, 550, 239)
		:SetSize(700, 200)
		:MoveToBack()



	self.groups_title = self.groups_container_widget:AddChild(Text(FONTFACE.DEFAULT, FONTSIZE.CONFIRM_DIALOG_SUBTITLE))
		:SetName("Groups title")
		:SetGlyphColor(UICOLORS.LIGHT_TEXT_DARK)
		:SetText(STRINGS.UI.MAINSCREEN.HOST_DIALOG_DISCORD)
		:Offset(0, 50)

	local panelaroundtab = self.groups_container_widget:AddChild(Widget())
								:Offset(-240,-26)

	local icon_tab_group = panelaroundtab:AddChild(TabGroup())
		:SetName("DiscordStatus")
		:SetFontSize(FONTSIZE.ROOMBONUS_TEXT)
		:SetTabOnClick(function(active_tab) 
			TheNet:SetDiscordSharingType(active_tab.MyTag) 
			TheSaveSystem.network:SetValue("DiscordSharingType", TheNet:GetDiscordSharingType())
			TheSaveSystem.network:Save()
		end)
			
	icon_tab_group:AddIconTextTab("images/ui_ftf_icons/discord_off.tex",STRINGS.UI.MAINSCREEN.HOST_DIALOG_DISCORD_OFF)
					:SetSize(nil, 60)
					:SetToolTip(STRINGS.UI.MAINSCREEN.HOST_DIALOG_DISCORD_OFF_TOOLTIP)
					:ShowToolTipOnFocus()
					.MyTag = 0

	icon_tab_group:AddIconTextTab("images/ui_ftf_icons/discord_private.tex",STRINGS.UI.MAINSCREEN.HOST_DIALOG_DISCORD_PRIVATE)
					:SetSize(nil, 60)
					:SetToolTip(STRINGS.UI.MAINSCREEN.HOST_DIALOG_DISCORD_PRIVATE_TOOLTIP)
					:ShowToolTipOnFocus()
					.MyTag = 1

	icon_tab_group:AddIconTextTab("images/ui_ftf_icons/discord_public.tex",STRINGS.UI.MAINSCREEN.HOST_DIALOG_DISCORD_PUBLIC)
					:SetSize(nil, 60)
					:SetToolTip(STRINGS.UI.MAINSCREEN.HOST_DIALOG_DISCORD_PUBLIC_TOOLTIP)
					:ShowToolTipOnFocus()
					.MyTag = 2

	local sharingType = TheSaveSystem.network:GetValue("DiscordSharingType")
	if sharingType then
		TheNet:SetDiscordSharingType(sharingType)
	end


	icon_tab_group:LayoutChildrenInRow(40)
		:OpenTabAtIndex(TheNet:GetDiscordSharingType() + 1)

	local shouldshowdiscord = TheNet:IsDiscordEnabled() and (not TheNet:IsInGame() or (not TheNet:IsGameTypeLocal() and TheNet:IsHost()))

	if shouldshowdiscord then
		-- Only show the discord sharing widget if Discord is enabled
		self.groups_container_widget:Show()
		local x, y = self.groups_container_widget:GetPosition()
		self.groups_container_widget:SetPosition(x, y - 60)
			:MoveTo(x, y, 0.25, easing.outQuad)
			:SetMultColorAlpha(0)
			:AlphaTo(1, 0.1, easing.outQuad)
	end

end)

function DiscordSharingSetting:AnimateIn()
	if self:IsShown() then return end

	self:Show()
	self:SetMultColorAlpha(0)

	local x, y = self:GetPos()

	self:RunUpdater(Updater.Parallel{
		Updater.Ease(function(a) self:SetMultColorAlpha(a) end, 0, 1, 0.25, easing.outQuad),
		Updater.Ease(function(_y) self:SetPos(x, _y) end, y-40, y, 0.75, easing.outElasticUI),
	})
	return self
end

function DiscordSharingSetting:AnimateOut()
	self:Hide()
end

return DiscordSharingSetting
