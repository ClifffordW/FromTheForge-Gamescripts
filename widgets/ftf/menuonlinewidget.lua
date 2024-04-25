local Widget = require("widgets/widget")
local Image = require ("widgets/image")
local Text = require ("widgets/text")
local ActionButton = require ("widgets/actionbutton")
local MenuButton = require ("widgets/ftf/menubutton")
local CheckBox = require ("widgets/checkbox")
local MenuSteamFriendsWidget = require ("widgets/ftf/menusteamfriendswidget")
local MenuSteamUserGroupsWidget = require ("widgets/ftf/menusteamusergroupswidget")
local fmodtable = require "defs.sound.fmodtable"

local OnlineJoinCodeDialog = require ("screens/dialogs/onlinejoincodedialog")
local OnlineHostDialog = require ("screens/dialogs/onlinehostdialog")

local easing = require "util.easing"

----------------------------------------------------------------------
-- After the player clicks MULTIPLAYER on the main menu,
-- this allows them to join or host a game, or see their Steam friends

-- ┌──────────────────────────────────────────────────────────────────────────────────────────────────────────┐
-- │ panels_container                                                                                         │
-- │  ┌──────────────────────┐                                                                                │
-- │  │ buttons_container    │  ┌───────────────────────────────────┐  ┌───────────────────────────────────┐  │
-- │  │                      │  │ steam_friends_widget              │  │ steam_usergroups_widget           │  │
-- │  │ ┌──────────────────┐ │  │  (MenuSteamFriendsWidget)         │  │  (MenuSteamUserGroupsWidget)      │  │
-- │  │ │ join_button      │ │  │                                   │  │                                   │  │
-- │  │ │                  │ │  │                                   │  │                                   │  │
-- │  │ │                  │ │  │                                   │  │                                   │  │
-- │  │ └──────────────────┘ │  │                                   │  │                                   │  │
-- │  │ ┌──────────────────┐ │  │                                   │  │                                   │  │
-- │  │ │ host_button      │ │  │                                   │  │                                   │  │
-- │  │ │                  │ │  │                                   │  │                                   │  │
-- │  │ │                  │ │  │                                   │  │                                   │  │
-- │  │ └──────────────────┘ │  │                                   │  │                                   │  │
-- │  │                      │  └───────────────────────────────────┘  └───────────────────────────────────┘  │
-- │  └──────────────────────┘                                                                                │
-- └──────────────────────────────────────────────────────────────────────────────────────────────────────────┘

local MenuOnlineWidget = Class(Widget, function(self, player)
	Widget._ctor(self, "MenuOnlineWidget")

	self.panels_container = self:AddChild(Widget())
		:SetName("Panels container")

	self.buttons_container = self.panels_container:AddChild(Widget())
		:SetName("Buttons container")

	self.join_button = self.buttons_container:AddChild(MenuButton(670, 470))
		:SetName("Join game button")
		:SetTexture("images/ui_ftf_multiplayer/multiplayer_btn_join.tex")
		:SetNineSliceCoords(0, 50, 670, 60)
		:SetText(STRINGS.UI.MAINSCREEN.BTN_JOIN_TITLE, STRINGS.UI.MAINSCREEN.BTN_JOIN_TEXT)
		:SetTextColor(nil, HexToRGB(0x97660Eff))
		:SetTextWidth(360)
		:SetOnClick(function(device_type, device_id) self:OnClickJoin(device_type, device_id) end)

	self.host_button = self.buttons_container:AddChild(MenuButton(670, 420))
		:SetName("Host game button")
		:SetTexture("images/ui_ftf_multiplayer/multiplayer_btn_host.tex")
		:SetNineSliceCoords(0, 50, 670, 60)
		:SetText(STRINGS.UI.MAINSCREEN.BTN_HOST_TITLE, STRINGS.UI.MAINSCREEN.BTN_HOST_TEXT)
		:SetTextColor(nil, HexToRGB(0x006D58ff))
		:SetTextWidth(360)
		:SetOnClick(function() self:OnClickHost() end)

	self.buttons_container:LayoutChildrenInColumn(40)
		:LayoutBounds("center", "center", 0, 0)

	self.steam_friends_widget = self.panels_container:AddChild(MenuSteamFriendsWidget(700, 860))
		:SetName("Steam friends widget")
		:LayoutBounds("after", "center", self.buttons_container)
		:Offset(40, 0)


	self.steam_usergroups_widget = self.panels_container:AddChild(MenuSteamUserGroupsWidget(700, 860))
		:SetName("Steam usergroups widget")
		:LayoutBounds("after", "center", self.steam_friends_widget)
		:Offset(40, 0)

	-- Save button positions for animation purposes
	self.join_button_x, self.join_button_y = self.join_button:GetPos()
	self.host_button_x, self.host_button_y = self.host_button:GetPos()
	self.steam_friends_widget_x, self.steam_friends_widget_y = self.steam_friends_widget:GetPos()
	self.steam_usergroups_widget_x, self.steam_usergroups_widget_y = self.steam_usergroups_widget:GetPos()

	local palette = {
		primary_active = UICOLORS.LIGHT_TEXT,
		primary_inactive = UICOLORS.LIGHT_TEXT_DARK,
	}
	self.streamer_mode = self:AddChild(CheckBox(palette))
		:SetSize(60, 60)
		:SetTextSize(FONTSIZE.SCREEN_SUBTITLE)
		:SetText(STRINGS.UI.OPTIONSSCREEN.SETTINGS.OTHER.STREAMER_MODE.TITLE)
		:SetToolTip(STRINGS.UI.OPTIONSSCREEN.SETTINGS.OTHER.STREAMER_MODE.TOOLTIP)
		:SetOnChangedFn(function(val)
			TheGameSettings:Set("network.streamer_mode", val)
			TheGameSettings:Save()
		end)
		:SetValue(TheGameSettings:Get("network.streamer_mode"), true)

	self.info_label = self:AddChild(Text(FONTFACE.DEFAULT, FONTSIZE.SCREEN_TEXT))
		:SetGlyphColor(UICOLORS.LIGHT_BACKGROUNDS_DARK)
		:SetHAlign(ANCHOR_MIDDLE)
		:SetAutoSize(900)
		:SetText(STRINGS.UI.MAINSCREEN.ONLINE_INFO)

	self:Layout()
	self.default_focus = self.join_button

end)

function MenuOnlineWidget:Layout()
	self.streamer_mode:LayoutBounds("center", "below", self.panels_container)
		:Offset(0, -60)
		:SetValue(TheGameSettings:Get("network.streamer_mode"), true)		
	self.info_label:LayoutBounds("center", "below", self.streamer_mode)
		:Offset(0, -10)
end

function MenuOnlineWidget:ShowSteamFriends(show)
	self.steam_friends_widget:SetShown(show)
	self:Layout()
	return self
end

function MenuOnlineWidget:ShowUserGroupsFriends(show)
	self.steam_usergroups_widget:SetShown(show)
	self:Layout()
	return self
end

function MenuOnlineWidget:AnimateIn(on_done_fn)
	TheFrontEnd:GetSound():PlaySound(fmodtable.Event.ui_networking_coop_show)
	self.streamer_mode:SetValue(TheGameSettings:Get("network.streamer_mode"), true)		

	self.join_button:SetMultColorAlpha(0)
	self.host_button:SetMultColorAlpha(0)

	self.steam_friends_widget:SetMultColorAlpha(0)
		:StartUpdating()
	self.steam_usergroups_widget:SetMultColorAlpha(0)
		:StartUpdating()

	self:RunUpdater(Updater.Parallel{
		Updater.Ease(function(a) self.join_button:SetMultColorAlpha(a) end, 0, 1, 0.25, easing.outQuad),
		Updater.Ease(function(y) self.join_button:SetPos(self.join_button_x, y) end, self.join_button_y-40, self.join_button_y, 0.75, easing.outElasticUI),

		Updater.Series{
			Updater.Wait(0.1),
			Updater.Parallel{
				Updater.Ease(function(a) self.host_button:SetMultColorAlpha(a) end, 0, 1, 0.25, easing.outQuad),
				Updater.Ease(function(y) self.host_button:SetPos(self.host_button_x, y) end, self.host_button_y-40, self.host_button_y, 0.75, easing.outElasticUI),
			}
		},

		Updater.Series{
			Updater.Wait(0.2),
			Updater.Parallel{
				Updater.Ease(function(a) self.steam_friends_widget:SetMultColorAlpha(a) end, 0, 1, 0.25, easing.outQuad),
				Updater.Ease(function(y) self.steam_friends_widget:SetPos(self.steam_friends_widget_x, y) end, self.steam_friends_widget_y-40, self.steam_friends_widget_y, 0.75, easing.outElasticUI),
			}
		},

		Updater.Series{
			Updater.Wait(0.3),
			Updater.Parallel{
				Updater.Ease(function(a) self.steam_usergroups_widget:SetMultColorAlpha(a) end, 0, 1, 0.25, easing.outQuad),
				Updater.Ease(function(y) self.steam_usergroups_widget:SetPos(self.steam_usergroups_widget_x, y) end, self.steam_usergroups_widget_y-40, self.steam_usergroups_widget_y, 0.75, easing.outElasticUI),
			}
		},

		Updater.Series{
			Updater.Wait(0.35),
			Updater.Do(function()
				if on_done_fn then on_done_fn() end
			end)
		}

	})
	return self
end

function MenuOnlineWidget:AnimateOut(on_done_fn)
	self.steam_friends_widget:StopUpdating()
	self.steam_usergroups_widget:StopUpdating()
	if on_done_fn then on_done_fn() end
	return self
end

function MenuOnlineWidget:OnClickJoin(device_type, device_id)
	TheFrontEnd:PushScreen(OnlineJoinCodeDialog(device_type, device_id))
	return self
end

function MenuOnlineWidget:OnClickHost()
	TheFrontEnd:PushScreen(OnlineHostDialog())
	return self
end

return MenuOnlineWidget
