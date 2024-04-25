local Widget = require("widgets/widget")
local Image = require ("widgets/image")
local ImageButton = require ("widgets/imagebutton")
local Panel = require ("widgets/panel")
local ScrollPanel = require ("widgets/scrollpanel")
local Text = require ("widgets/text")

local easing = require "util.easing"

----------------------------------------------------------------------
-- A single Steam user group row for a list

-- groupinfo = {
-- {
--		id = "steam id"
--		name = "name"
--		avatar = "avatar image"
--		games = [
--			lobbyID,
--			lobbyID
--		]
-- }

local MenuSteamUserGroupRow = Class(ImageButton, function(self, width, groupinfo)
	ImageButton._ctor(self, "images/ui_ftf_multiplayer/friend_row.tex")

	-- Store data
	self.groupinfo = groupinfo

	-- Prepare sizes
	self.width = width or 600
	self.height = 90
	self.padding_h = 12
	self.padding_v = 12
	self.avatar_size = self.height - self.padding_v*2
	self.join_btn_width = 190

	-- Set ImageButton defaults
	self:SetScaleOnFocus(false)
		:SetSize(self.width, self.height)

	-- Add widgets
	self.row_avatar = self:AddChild(Image(groupinfo.avatarfilename or "images/global/square.tex"))
		:SetName("Avatar")
		:SetSize(self.avatar_size, self.avatar_size)
		:LayoutBounds("left", "center", self:GetImage())
		:Offset(self.padding_h)

	if not groupinfo.avatarfilename then 
		self.row_avatar:SetMultColor(UICOLORS.LIGHT_BACKGROUNDS_MID)
						:SetMultColorAlpha(0.35)
	end

	self.row_text = self:AddChild(Widget())
		:SetName("Row text")
	self.row_username = self.row_text:AddChild(Text(FONTFACE.DEFAULT, FONTSIZE.SCREEN_TEXT))
		:SetName("Username")
		:SetGlyphColor(UICOLORS.SPEECH_BUTTON_TEXT)
		:SetTruncatedStringRaw(self.groupinfo.name:sanitize_user_text(), self.width - self.padding_h*2 - self.avatar_size - self.join_btn_width)
	self.row_freespots = self.row_text:AddChild(Text(FONTFACE.DEFAULT, FONTSIZE.SCREEN_TEXT*0.8))
		:SetName("FreeSpots")
		:SetGlyphColor(UICOLORS.LIGHT_TEXT_DARK)
		:Hide()

	local nrgamesingroup = 0
	if self.groupinfo.games then 
		nrgamesingroup = table.count(self.groupinfo.games)
	end

	local maxnr = 10

	if nrgamesingroup == 0 then
		self.row_freespots:Show():SetText(STRINGS.UI.STEAMUSERGROUPSWIDGET.NO_GAMES_TO_JOIN)
	elseif nrgamesingroup == 1 then
		self.row_freespots:Show():SetText(STRINGS.UI.STEAMUSERGROUPSWIDGET.ONE_GAME_TO_JOIN)
	elseif nrgamesingroup >= maxnr then
		self.row_freespots:Show():SetText(string.format(STRINGS.UI.STEAMUSERGROUPSWIDGET.MORE_NR_GAMES_TO_JOIN, maxnr))
	else
		self.row_freespots:Show():SetText(string.format(STRINGS.UI.STEAMUSERGROUPSWIDGET.NR_GAMES_TO_JOIN, nrgamesingroup))
	end

	if nrgamesingroup > 0 then
		-- You can join. Show button
		self.row_join_btn = self:AddChild(Image("images/ui_ftf_multiplayer/friend_row_btn.tex"))
			:SetName("Join button")
			:SetSize(self.join_btn_width, self.height)
			:LayoutBounds("right", "center", self:GetImage())
		self.row_join_text = self:AddChild(Text(FONTFACE.DEFAULT, FONTSIZE.SCREEN_TEXT))
			:SetName("Join text")
			:SetGlyphColor(UICOLORS.BACKGROUND_DARK)
			:SetAutoSize(self.join_btn_width - self.padding_h*2)
			:SetText(STRINGS.UI.STEAMUSERGROUPSWIDGET.JOIN_USERGROUP_BTN)
			:LayoutBounds("center", "center", self.row_join_btn)

		self:Enable()
	else
		-- No lobby. The person is in the menu
		self.no_lobby_text = self:AddChild(Text(FONTFACE.DEFAULT, FONTSIZE.SCREEN_TEXT))
			:SetName("No-lobby text")
			:SetGlyphColor(UICOLORS.LIGHT_BACKGROUNDS_DARK)
			:SetAutoSize(self.join_btn_width - self.padding_h*2)
			:SetText(STRINGS.UI.STEAMUSERGROUPSWIDGET.USERGROUP_NOT_IN_LOBBY)
			:LayoutBounds("after", "center", self:GetImage())
		self.no_lobby_text:Offset(-self.join_btn_width/2 - self.no_lobby_text:GetSize()/2, 0)
		self:Disable()

--		self.no_lobby_text = self:AddChild(Text(FONTFACE.DEFAULT, FONTSIZE.SCREEN_TEXT))
--			:SetName("No free spots text")
--			:SetGlyphColor(UICOLORS.RED)
--			:OverrideLineHeight(FONTSIZE.SCREEN_TEXT * 0.85)
--			:SetAutoSize(self.join_btn_width - self.padding_h*2)
--			:SetText(STRINGS.UI.STEAMUSERGROUPSWIDGET.NO_GAME_TO_JOIN)
--			:LayoutBounds("after", "center", self:GetImage())
--		self.no_lobby_text:Offset(-self.join_btn_width/2 - self.no_lobby_text:GetSize()/2, 0)

		self:Disable()
	end


	-- Show a tooltip with the groups this lobby accepts
--	if nrgamesingroup > 0 then
--		self:SetToolTip(STRINGS.UI.STEAMUSERGROUPSWIDGET.JOIN_RANDOM)
--			:SetToolTipLayoutFn(function(w, tooltip) tooltip:LayoutBounds("after", nil, w):Offset(70, 0) end)
--			:ShowToolTipOnFocus( true )
--	end

	-- TODO: Show categories

	self:SetOnGainFocus(function() self:OnFocusChanged(true) end)
	self:SetOnLoseFocus(function() self:OnFocusChanged(false) end)

	self:_Layout()
end)

function MenuSteamUserGroupRow:OnFocusChanged(has_focus)
	if has_focus then
		-- self:GetImage():ColorAddTo(nil, UICOLORS.LIGHT_BACKGROUNDS_LIGHT, 0.1, easing.outQuad)
		if self.row_join_btn then self.row_join_btn:ColorAddTo(nil, HexToRGB(0x101010FF), 0.1, easing.outQuad) end
	else
		-- self:GetImage():ColorAddTo(nil, UICOLORS.BLACK, 0.2, easing.outQuad)
		if self.row_join_btn then self.row_join_btn:ColorAddTo(nil, UICOLORS.BLACK, 0.2, easing.outQuad) end
	end
	return self
end

function MenuSteamUserGroupRow:_Layout()
	self.row_freespots:LayoutBounds("left", "below", self.row_username):Offset(0, 0)
	self.row_text:LayoutBounds("after", "center", self.row_avatar):Offset(self.padding_h, 0)
	return self
end

return MenuSteamUserGroupRow
