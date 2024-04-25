local Widget = require("widgets/widget")
local Clickable = require("widgets/clickable")
local Text = require("widgets/text")
local Panel = require("widgets/panel")
local Image = require("widgets/image")
local ImageButton = require("widgets/imagebutton")
local PlayerPuppet = require("widgets/playerpuppet")
local CheckBox = require "widgets.checkbox"

local easing = require "util.easing"
local fmodtable = require "defs.sound.fmodtable"

------------------------------------------------------------------------------------
-- Displays a single player on the PlayersScreen.

local PlayersScreenRow = Class(Widget, function(self) self:init() end)

PlayersScreenRow.WIDTH = 1060
PlayersScreenRow.HEIGHT = 240

-- PlayersScreenRow.CONTROL_MAP =
-- {
-- 	{
-- 		control = Controls.Digital.Y,
-- 		fn = function(self)
-- 			if self.permissions:IsShown() then
-- 				self.permissions:Click()
-- 				return true
-- 			end
-- 		end
-- 	},
-- }

function PlayersScreenRow:init()
    Widget._ctor(self, "PlayersScreen Row")

    TheLog:enable_channel("PlayersScreenRow")

    self.client_id = nil
    self.player_id = nil
    self.empty = false
    self.host = false

    self.client_left_margin = 140
    self.text_width = 500
	self.padding_h = 20
    self.right_btn_width = 300
	self.was_device_connected = true -- we construct with connected setup

	self:SetGainFocusSound(nil)
	self:SetControlDownSound(nil)
	self:SetControlUpSound(nil)

    -- Add contents
    self.hitbox = self:AddChild(Image("images/global/square.tex"))
		:SetName("Hitbox")
		:SetSize(PlayersScreenRow.WIDTH, PlayersScreenRow.HEIGHT)
		:SetMultColor(UICOLORS.DEBUG)
		:SetMultColorAlpha(0)

	self.client_indicator = self:AddChild(Image("images/ui_ftf_online/player_client_2.tex"))
		:SetName("Client indicator")
		:SetHiddenBoundingBox(true)
		:Hide()

	self.disconnected_device = self:AddChild(Image("images/ui_ftf/error_large.tex"))
		:SetScale(0.2)
		:SetMultColor(UICOLORS.DARK_TEXT_ERROR)
		:Hide()

    self.bg = self:AddChild(Panel("images/ui_ftf_online/player_bg.tex"))
		:SetName("Background")
		:SetNineSliceCoords(90, 0, 970, 240)
		:SetSize(PlayersScreenRow.WIDTH, PlayersScreenRow.HEIGHT)

	self.portrait_container = self:AddChild(Widget())
		:SetName("Portrait container")
	self.portrait_bg = self.portrait_container:AddChild(Image("images/ui_ftf_online/portrait_bg.tex"))
		:SetName("Portrait background")
	self.portrait_mask = self.portrait_container:AddChild(Image("images/ui_ftf_online/portrait_mask.tex"))
		:SetName("Portrait mask")
		:SetMask()
	self.portrait_puppet = self.portrait_container:AddChild(PlayerPuppet())
		:SetName("Portrait puppet")
		:SetHiddenBoundingBox(true)
		:SetScale(0.7)
		:SetFacing(FACING_RIGHT)
		:SetMasked()
		:Pause()
	self.portrait_overlay = self.portrait_container:AddChild(Image("images/ui_ftf_online/portrait_overlay.tex"))
		:SetName("Portrait mask")

	self.text_container = self:AddChild(Widget())
		:SetName("Text container")
	self.title = self.text_container:AddChild(Text(FONTFACE.DEFAULT, FONTSIZE.SCREEN_TEXT*1.4))
		:SetName("Title")
		:SetGlyphColor(UICOLORS.SPEECH_BUTTON_TEXT)
		:OverrideLineHeight(FONTSIZE.SCREEN_TEXT * 1.2)
		:SetHAlign(ANCHOR_LEFT)
		:SetAutoSize(self.text_width)
	self.description = self.text_container:AddChild(Text(FONTFACE.DEFAULT, FONTSIZE.SCREEN_TEXT))
		:SetName("Description")
		:SetGlyphColor(UICOLORS.DARK_TEXT)
		:SetHAlign(ANCHOR_LEFT)
		:SetAutoSize(self.text_width)
	self.permissions = self.text_container:AddChild(CheckBox())
		:SetSize(50, 50)
		:SetTextSize(FONTSIZE.SCREEN_TEXT)
		:SetText(STRINGS.UI.PLAYERSSCREEN.ALLOW_TOWN_EDITING)
		:SetTextColour(UICOLORS.DARK_TEXT)
		:SetOnChangedFn(function(val)
			if self.client_id ~= nil then
				TheLog.ch.PlayersScreenRow:print("setting privileges", self.client_id, val and 2 or 0)
				TheNet:SetTownPropEditPrivilegeByClientID(self.client_id, val and 2 or 0)
			end
		end)
		:SetToolTip(STRINGS.UI.PLAYERSSCREEN.TT_ALLOW_TOWN_EDITING)
		:ShowToolTipOnFocus(true)
		:SetNavFocusable(true)

	self.empty_label = self:AddChild(Text(FONTFACE.DEFAULT, FONTSIZE.SCREEN_TEXT*1.4))
		:SetName("Empty label")
		:SetText(STRINGS.UI.PLAYERSSCREEN.PLAYER_AVAILABLE)
		:SetGlyphColor(UICOLORS.SPEECH_BUTTON_TEXT)
		:SetMultColorAlpha(0.3)
		:Hide()

	-- Ban and remove buttons
	self.row_ban_btn = self:AddChild(ImageButton("images/ui_ftf_online/player_btn_ban.tex"))
		:SetName("Ban button")
		:SetScaleOnFocus(false)
		:SetImageNormalColour(0xeeeeeeff)
		:SetImageFocusColour(0xffffffff)
		:SetSize(self.right_btn_width, PlayersScreenRow.HEIGHT)
		:LayoutBounds("right", "center", self.hitbox)
		:Hide()
	self.row_ban_text = self.row_ban_btn:GetImage():AddChild(Text(FONTFACE.DEFAULT, FONTSIZE.SCREEN_TEXT))
		:SetName("Ban text")
		:SetGlyphColor(UICOLORS.BACKGROUND_DARK)
		:OverrideLineHeight(FONTSIZE.SCREEN_TEXT * 0.8)
		:SetAutoSize(self.right_btn_width - self.padding_h*2)
		:SetText(STRINGS.UI.PLAYERSSCREEN.BAN_BTN)
		:LayoutBounds("center", "center")

	self.row_remove_btn = self:AddChild(ImageButton("images/ui_ftf_online/player_btn_remove.tex"))
		:SetName("Remove button")
		:SetScaleOnFocus(false)
		:SetImageNormalColour(0xeeeeeeff)
		:SetImageFocusColour(0xffffffff)
		:SetSize(self.right_btn_width, PlayersScreenRow.HEIGHT)
		:LayoutBounds("right", "center", self.hitbox)
		:Hide()
	self.row_remove_text = self.row_remove_btn:GetImage():AddChild(Text(FONTFACE.DEFAULT, FONTSIZE.SCREEN_TEXT))
		:SetName("Remove text")
		:SetGlyphColor(UICOLORS.BACKGROUND_DARK)
		:OverrideLineHeight(FONTSIZE.SCREEN_TEXT * 0.8)
		:SetAutoSize(self.right_btn_width - self.padding_h*2)
		:SetText(STRINGS.UI.PLAYERSSCREEN.REMOVE_BTN)
		:LayoutBounds("center", "center")
end

function PlayersScreenRow:SetPlayer(player)
	self.player = player

	self.empty = false
	self.bg:SetTexture("images/ui_ftf_online/player_bg.tex")
	self.empty_label:Hide()
	self.description:SetText("")
		:Hide()
	self.portrait_container:Show()
	self.text_container:Show()

	-- Update puppet
	if self.player then
		self.portrait_puppet:CloneCharacterWithEquipment(self.player)

		-- Update color
		self.title:SetGlyphColor(player.uicolor)
	end

	local is_device_connected = not self.player or not self.player:IsLocal() or self.player.components.playercontroller:HasInputDevice()
	if self.was_device_connected ~= is_device_connected then
		if is_device_connected then
			self.disconnected_device:Hide()
			self.portrait_bg
				:StopPulse()
				:SetMultColor(WEBCOLORS.WHITE)
		else
			self.disconnected_device:Show()
			self.portrait_bg:PulseColor(WEBCOLORS.WHITE, UICOLORS.DARK_TEXT_ERROR, 2, easing.inOutSine)
		end
	end
	self.was_device_connected = is_device_connected

	return self
end

function PlayersScreenRow:GetPlayer()
	return self.player
end

function PlayersScreenRow:SetPlayerId(player_id)
	self.player_id = player_id
	return self
end

function PlayersScreenRow:SetClientId(client_id)
	if client_id ~= self.client_id then
		self.client_id = client_id

		local privileges = TheNet:GetTownPropEditPrivileges()
		local can_edit = privileges[client_id] and privileges[client_id].privilege == 2
		self.permissions:SetValue(can_edit, true)
	end
	return self
end

function PlayersScreenRow:GetPlayerId()
	return self.player_id
end

function PlayersScreenRow:SetHost(is_host)
	self.host = is_host
	local input_device_icon = ""
	if self.player and self.player:IsLocal() then
		if self.player.components.playercontroller:HasInputDevice() then
			input_device_icon = self.player.components.playercontroller:GetLabelForDevice()
		else
			input_device_icon = STRINGS.UI.PLAYERSSCREEN.PLAYER_NO_DEVICE
		end
		dbassert(input_device_icon)
	end

	if self.host then
		self.description:SetText(input_device_icon .." ".. STRINGS.UI.PLAYERSSCREEN.PLAYER_HOST)
			:Show()
	else
		self.description:SetText(input_device_icon)
			:Show()
	end
	self:Layout()

	return self
end

function PlayersScreenRow:IsHost()
	return self.host
end

function PlayersScreenRow:SetPlayerIndex(idx)
	if idx == 1 then
		-- This is the main player, don't indent
		self.client_indicator:Hide()
		self.bg:SetSize(PlayersScreenRow.WIDTH, PlayersScreenRow.HEIGHT)
		self.disconnected_device:LayoutBounds("before", "center", self.bg)

		self.permissions:SetShown(not self.host)
	else
		-- This is indented under the main player
		self.permissions:Hide()
		if idx == 2 then
			self.client_indicator:SetTexture("images/ui_ftf_online/player_client_2.tex")
		elseif idx > 2 then
			self.client_indicator:SetTexture("images/ui_ftf_online/player_client_3.tex")
		end

		self.client_indicator:Show()
			:LayoutBounds("left", "bottom", self.hitbox)

		self.disconnected_device:LayoutBounds("center", "bottom", self.client_indicator)
			:Offset(27, 62)

		self.bg:SetSize(PlayersScreenRow.WIDTH - self.client_left_margin, PlayersScreenRow.HEIGHT)
	end

	self:Layout()
	return self
end

function PlayersScreenRow:ShowBanButton(fn)
	self.row_ban_btn:Show()
		:SetOnClick(fn)
	self:Layout()
	return self
end

function PlayersScreenRow:HideBanButton()
	self.row_ban_btn:Hide()
	return self
end

function PlayersScreenRow:ShowRemoveButton(fn)
	self.row_remove_btn:Show()
		:SetOnClick(fn)
	self:Layout()
	return self
end

function PlayersScreenRow:HideRemoveButton()
	self.row_remove_btn:Hide()
	return self
end

function PlayersScreenRow:SetEmpty()
	self.player = nil
	self.player_id = nil

	self.empty = true
	self.bg:SetTexture("images/ui_ftf_online/player_bg_empty.tex")
		:SetSize(PlayersScreenRow.WIDTH, PlayersScreenRow.HEIGHT)
	self.empty_label:Show()
	self.portrait_container:Hide()
	self.text_container:Hide()
	self.client_indicator:Hide()
	self.disconnected_device:Hide()
	self:HideBanButton()
	self:HideRemoveButton()

	self:Layout()
	return self
end

function PlayersScreenRow:SetUsername(username)
	self.title:SetText(username)
	self:Layout()
	return self
end

function PlayersScreenRow:SetLoading()
	self.title:SetText(STRINGS.UI.PLAYERSSCREEN.PLAYER_LOADING)
	self.description:SetText(STRINGS.UI.PLAYERSSCREEN.PLAYER_LOADING_DESC)
		:Show()
	self:Layout()
	return self
end

function PlayersScreenRow:Layout()

	-- Position bg
	self.bg:LayoutBounds("right", "center", self.hitbox)

	-- Position portrait
	self.portrait_container:LayoutBounds("left", nil, self.bg)
	self.portrait_puppet:SetPos(0, -210)

	-- Check if there are buttons shown
	-- and adjust the text width accordingly
	self.text_width = PlayersScreenRow.WIDTH - self.portrait_container:GetSize() - 70
	if self.client_indicator:IsShown() then -- Is the client indicator shown on the left?
		self.text_width = self.text_width - self.client_left_margin
	end
	if self.row_ban_btn:IsShown() or self.row_remove_btn:IsShown() then -- Are buttons shown?
		self.text_width = self.text_width - self.right_btn_width
	end
	self.title:SetAutoSize(self.text_width)
	self.description:SetAutoSize(self.text_width)

	-- Position text widgets
	self.text_container:LayoutChildrenInColumn(0, "left")
		:LayoutBounds("after", "center", self.portrait_container)
		:Offset(40, 3)

	return self
end

return PlayersScreenRow
