local Widget = require("widgets/widget")
local ActionButton = require("widgets/actionbutton")
local ImageButton = require("widgets/imagebutton")
local Text = require("widgets/text")
local UserGroupRow = require "widgets.usergrouprow"
local Image = require("widgets/image")
local PopupDialog = require("screens/dialogs/popupdialog")
local ScrollPanel = require ("widgets/scrollpanel")

local RoomLoader = require "roomloader"
local Controls = require "input.controls"
local easing = require "util.easing"
local DiscordSharingSetting = require ("widgets/ftf/discordsharingsetting")


----------------------------------------------------------------------
-- A dialog that allows the player to input a code
-- and join a friend's game

local OnlineHostDialog = Class(PopupDialog, function(self)
	PopupDialog._ctor(self, "OnlineHostDialog")

	self.max_text_width = 1300
	self.connecting_time_UI_delay = 0
	self.connecting_time_min_UI_delay = 1.5 -- Wait these seconds before moving on after connecting
	self.delay_after_showing_join_code = 1.1 -- Wait these seconds before starting the game

	self.groups_scroll_width = 560
	self.groups_scroll_height = 584

	self.dialog_container = self:AddChild(Widget())
		:SetName("Dialog container")

	self.glow = self.dialog_container:AddChild(Image("images/ui_ftf/gradient_circle.tex"))
		:SetName("Glow")
		:SetHiddenBoundingBox(true)
		:SetMultColor(UICOLORS.LIGHT_TEXT_DARKER)

	self.bg = self.dialog_container:AddChild(Image("images/ui_ftf_multiplayer/popup_host.tex"))
		:SetName("Background")

	self.close_button = self.dialog_container:AddChild(ImageButton("images/ui_ftf/HeaderClose.tex"))
		:SetNavFocusable(false) -- rely on CONTROL_MAP
		:SetOnClick(function() self:OnClickClose() end)
		:SetSize(BUTTON_SQUARE_SIZE, BUTTON_SQUARE_SIZE)
		:LayoutBounds("right", "top", self.bg)
		:Offset(-40, 0)

	self.text_container = self.dialog_container:AddChild(Widget())
	self.dialog_title = self.text_container:AddChild(Text(FONTFACE.DEFAULT, FONTSIZE.CONFIRM_DIALOG_TITLE))
		:SetGlyphColor(UICOLORS.BACKGROUND_DARK)
		:SetHAlign(ANCHOR_MIDDLE)
		:SetAutoSize(self.max_text_width)
		:SetText(STRINGS.UI.MAINSCREEN.HOST_DIALOG_TITLE)
	self.dialog_text = self.text_container:AddChild(Text(FONTFACE.DEFAULT, FONTSIZE.CONFIRM_DIALOG_SUBTITLE*0.9))
		:SetGlyphColor(UICOLORS.LIGHT_TEXT_DARK)
		:SetHAlign(ANCHOR_MIDDLE)
		:SetAutoSize(self.max_text_width)
		:SetText(STRINGS.UI.MAINSCREEN.HOST_DIALOG_TEXT)
	self.dialog_subtext = self.text_container:AddChild(Text(FONTFACE.DEFAULT, FONTSIZE.CONFIRM_DIALOG_SUBTITLE*0.75))
		:SetGlyphColor(UICOLORS.LIGHT_TEXT_DARKER)
		:SetHAlign(ANCHOR_MIDDLE)
		:SetAutoSize(self.max_text_width)
		:SetText(STRINGS.UI.MAINSCREEN.HOST_DIALOG_SUBTEXT)

	self.loading_text = self.text_container:AddChild(Text(FONTFACE.DEFAULT, FONTSIZE.CONFIRM_DIALOG_SUBTITLE))
		:SetGlyphColor(UICOLORS.LIGHT_TEXT_DARK)
		:SetHAlign(ANCHOR_MIDDLE)
		:SetText(STRINGS.UI.MAINSCREEN.HOST_DIALOG_LOADING_TEXT)
		:Hide()
	self.start_btn = self.text_container:AddChild(ActionButton())
		:SetSize(BUTTON_W, BUTTON_H)
		:SetPrimary()
		:SetScaleOnFocus(false)
		:SetTextAndResizeToFit(STRINGS.UI.MAINSCREEN.HOST_DIALOG_BTN, 190, 40)
		:SetOnClick(function(device_type, device_id) self:OnClickStart(device_type, device_id) end)


	-- Add a collapsible side panel to display a Steam Group listing the player can toggle
	self.groups_container_widget = self.dialog_container:AddChild(Widget())
		:SetName("Groups container")
		:SendToBack()
		:SetMultColorAlpha(0)
		:Hide()
	self.groups_bg = self.groups_container_widget:AddChild(Image("images/ui_ftf_gems/gems_panel_bg.tex"))
		:SetName("Groups background")
		:SetScale(0.5)
	self.groups_scroll = self.groups_container_widget:AddChild(ScrollPanel())
		:SetName("Groups scroll")
		:SetSize(self.groups_scroll_width, self.groups_scroll_height)
		:SetVirtualMargin(50)
	self.groups_scroll_contents = self.groups_scroll:AddScrollChild(Widget())
		:SetName("Groups scroll contents")
	self.groups_title_bg = self.groups_container_widget:AddChild(Image("images/ui_ftf/small_panel.tex"))
		:SetName("Groups title background")
		:SetMultColor(UICOLORS.LIGHT_BACKGROUNDS_MID)
		:SetSize(620, nil)
	self.groups_title = self.groups_container_widget:AddChild(Text(FONTFACE.DEFAULT, FONTSIZE.CONFIRM_DIALOG_SUBTITLE))
		:SetName("Groups title")
		:SetGlyphColor(UICOLORS.LIGHT_TEXT_DARK)
		:SetText(STRINGS.UI.MAINSCREEN.HOST_DIALOG_USERGROUP_JOIN)

	-- Check if there are Steam Groups this player's a part of
	local groups = TheNet:GetUserGroups()
	if groups and (table.count(groups) > 0) then

		-- Add a widget for each user group:
		for _i, usergroup_data in ipairs(groups) do
			local row_button = self.groups_scroll_contents:AddChild(UserGroupRow(490))
				:SetText(usergroup_data.name)
				:SetIcon(usergroup_data.avatarfilename)
				:SetValue(false)
				:SetToolTip(STRINGS.UI.MAINSCREEN.HOST_DIALOG_USERGROUP_JOIN_TOOLTIP)

			row_button.usergroupid = usergroup_data.id
		end


		-- Layout
		self.groups_scroll_contents:LayoutChildrenInColumn(25, "left")
			:LayoutBounds("left", "top", -self.groups_scroll_width/2 + 30, 0)
		self.groups_scroll:RefreshView()



		self:LoadStatus()


		-- Only show the groups button if the player is in any group
		self.groups_container_widget:Show()
		self:_LayoutDialog()
		local x, y = self.groups_container_widget:GetPosition()
		self.groups_container_widget:SetPosition(x - 60, y)
			:MoveTo(x, y, 0.25, easing.outQuad)
			:SetMultColorAlpha(0)
			:AlphaTo(1, 0.1, easing.outQuad)
	end


	-- Discord settings:
	self.discord_sharing_setting = self:AddChild(DiscordSharingSetting())
	self.discord_sharing_setting:LayoutBounds("left", "bottom", self.bg):Offset(400,-225)


	self:_LayoutDialog()
	self.default_focus = self.start_btn

end)

OnlineHostDialog.CONTROL_MAP =
{
	{
		control = Controls.Digital.CANCEL,
		hint = function(self, left, right)
			table.insert(right, loc.format(LOC"UI.CONTROLS.CANCEL", Controls.Digital.CANCEL))
		end,
		fn = function(self)
			if self.close_button:IsShown() then
				self.close_button:Click()
			end
			return true
		end,
	}
}

function OnlineHostDialog:_LayoutDialog()

	local w, h = self.bg:GetSize()
	self.glow:SetSize(w + 500, h + 500)

	self.dialog_text:LayoutBounds("center", "below", self.dialog_title)
		:Offset(0, -20)
	self.dialog_subtext:LayoutBounds("center", "below", self.dialog_text)
		:Offset(0, -20)


	self.start_btn:LayoutBounds("center", "below")
		:Offset(0, -100)
	self.loading_text:LayoutBounds("center", "center", self.start_btn)
		:Offset(0, 50)


	self.text_container:LayoutBounds("center", "center", self.bg)


	-- Layout groups container widget
	self.groups_container_widget:LayoutBounds("after", "center", self.bg):Offset(-40, 0)
	self.groups_title_bg:LayoutBounds("center", "top", self.groups_bg):Offset(10, -20)
	self.groups_title:LayoutBounds("center", "center", self.groups_title_bg):Offset(0, 0)
	self.groups_scroll:LayoutBounds("left", "top", self.groups_bg):Offset(60, -130)


	return self
end

function OnlineHostDialog:OnOpen()
	OnlineHostDialog._base.OnOpen(self)
	self:AnimateIn()

	----------------------------------------------------------------------
	-- Focus selection brackets
	self:EnableFocusBracketsForGamepad()
	-- self:EnableFocusBracketsForGamepadAndMouse()
	----------------------------------------------------------------------
end

function OnlineHostDialog:OnBecomeActive()
	OnlineHostDialog._base.OnBecomeActive(self)
	self:StartUpdating()
end

function OnlineHostDialog:OnClickClose()
	self:SaveStatus()
	TheFrontEnd:PopScreen(self)
	self:StopUpdating()
	return self
end

function OnlineHostDialog:OnClickStart(device_type, device_id)

	-- Disable the start button for the moment
	self.start_btn:Disable()

	-- Show a "Connecting..." popup
	self.connect_popup = ShowConnectingToGamePopup()

	-- Wait at least this amount of time before actually going into the game
	self.connecting_time_UI_delay = self.connecting_time_min_UI_delay

	-- Trigger the actual game start
	-- Player wants a code + friends game!
	local inputID = TheInput:ConvertToInputID(device_type, device_id)

	local openToGroups = {} -- add steamids of groups you want to open the game to here (you need to be a part of this group to open it up to that group)
	if self.groups_scroll_contents then
		for i,v in ipairs(self.groups_scroll_contents.children) do
			if v.usergroupid and v:IsChecked() then
				table.insert(openToGroups, v.usergroupid)
			end
		end
	end

	TheNet:StartGame(inputID, "joincode", openToGroups)

	return self
end

function OnlineHostDialog:OnClickGroupsBtn()
	self:AnimateGroupsIn()
	return self
end

function OnlineHostDialog:OnUpdate(dt)

	-- Decrease the delay, if it's ongoing
	self.connecting_time_UI_delay = math.max(0, self.connecting_time_UI_delay - dt)

	-- If we're not attempting to start a game (showing the loading popup), bail
	if not self.connect_popup then return end

	-- Wait until delay is done before proceeding
	if self.connecting_time_UI_delay > 0 then return end

	if TheNet:IsGameReady() and TheNet:IsHost() then
		-- Player started a code + friends game!
		self:HandleCodeGameStart()
	else
		-- Check if there was an error connecting. If the popup is up, we should be in game
		if not TheNet:IsInGame() then
			self:HandleGameStartFailed()
		end
	end

end

function OnlineHostDialog:HandleFriendsGameStart()

	-- Close the "Connecting..." popup
	if self.connect_popup then self.connect_popup:Close() end
	self.connect_popup = nil

	-- Hide button and show loading message
	self.start_btn:Hide()
	self.close_button:Hide()
	self.loading_text:Show()

	-- Start the game after a beat
	self:RunUpdater(Updater.Series{
		Updater.Wait(self.delay_after_showing_join_code),
		Updater.Do(function()
			self:StartGame()
		end)
	})
end

function OnlineHostDialog:HandleCodeGameStart()

	-- Close the "Connecting..." popup
	if self.connect_popup then self.connect_popup:Close() end
	self.connect_popup = nil

	-- Copy it to the clipboard
	TheNet:CopyJoinCodeToClipboard()

	-- Hide button and show loading message
	self.start_btn:Hide()
	self.close_button:Hide()
	self.loading_text:Show()

	-- Start the game 
	self:StartGame()
end

function OnlineHostDialog:HandleGameStartFailed()

	-- Close the "Connecting..." popup
	if self.connect_popup then self.connect_popup:Close() end
	self.connect_popup = nil

	-- Re-enable the start and close buttons
	self.start_btn:Show()
		:Enable()
	self.close_button:Show()

	-- Hide loading
	self.loading_text:Hide()

end

function OnlineHostDialog:StartGame()
	self:SaveStatus()
	RoomLoader.LoadTownLevel(TOWN_LEVEL)
	self:StopUpdating()
	TheFrontEnd:PopScreen(self)
end

function OnlineHostDialog:AnimateIn()
	local x, y = self.dialog_container:GetPosition()
	self:ScaleTo(0.8, 1, 0.15, easing.outQuad)
		:SetPosition(x, y - 60)
		:MoveTo(x, y, 0.25, easing.outQuad)
	self.glow:SetMultColorAlpha(0)
		:AlphaTo(0.25, 0.4, easing.outQuad)
	return self
end


function OnlineHostDialog:LoadStatus()
	if self.groups_scroll_contents then
		--local favgroups = TheSaveSystem.network:GetValue("FavouritedGroups")
		-- TODO: Filter favourited groups from the other Groups, and show those first

		-- Load checked status:
		local checkedgroups = TheSaveSystem.network:GetValue("CheckedGroups")

		if checkedgroups then
			for i,v in ipairs(self.groups_scroll_contents.children) do
				if v.usergroupid then
					v:SetValue(table.contains(checkedgroups, v.usergroupid))
				end
			end
		end

		self.groups_scroll_contents:SortChildren(function(a, b)
			-- TODO: Sort by favourite status

			-- Sort by checked status:
			return (a:IsChecked() ~= b:IsChecked()) and a:IsChecked()
		end)

		self.groups_scroll_contents:LayoutChildrenInColumn(25, "left")
			:LayoutBounds("left", "top", -self.groups_scroll_width/2 + 30, 0)
		self.groups_scroll:RefreshView()
	end
end


function OnlineHostDialog:SaveStatus()
	if self.groups_scroll_contents and self.groups_scroll_contents:HasChildren() then
		-- TheSaveSystem.network:SetValue("FavouritedGroups", ..)
		-- TheSaveSystem.network:SetValue("CheckedGroups", ..)

		local checkedGroups = {}
		local favouritedGroups = {}
		for i,v in ipairs(self.groups_scroll_contents.children) do
			if v.usergroupid then
				if v:IsChecked() then
					table.insert(checkedGroups, v.usergroupid)
				end

				-- TODO: something with favouritedGroups
			end
		end

		TheSaveSystem.network:SetValue("FavouritedGroups", favouritedGroups)
		TheSaveSystem.network:SetValue("CheckedGroups", checkedGroups)
		TheSaveSystem.network:Save()
	end
end


return OnlineHostDialog
