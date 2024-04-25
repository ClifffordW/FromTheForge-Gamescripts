local Image = require("widgets/image")
local Screen = require "widgets.screen"
local Text = require "widgets.text"
local lume = require "util.lume"
local fmodtable = require "defs.sound.fmodtable"

local STATUS_REVEAL_WAIT_TIME = 1.0
local STATUS_MIN_VISIBLE_TIME = 1.0

-- Wait for other network players to be ready to start playing. Their player
-- entities are not yet spawned.
local WaitingForPlayersScreen = Class(Screen, function(self, finishedcallback, savedata, profile)
	Screen._ctor(self, "WaitingForPlayersScreen")
	self.callback = finishedcallback
	self.savedata = savedata
	self.profile = profile
	self.close_started = false
	self:DoInit()
	self:SetAudioCategory(Screen.AudioCategory.s.None)
	-- self:SetAudioSnapshotOverride(fmodtable.Event.FullscreenOverlay_Instant_LP)
	-- self:SetAudioEnterOverride(fmodtable.Event.ui_waitingForPlayersScreen_show)
	-- self:SetAudioExitOverride(nil)
end)

function WaitingForPlayersScreen:DoInit()
	self:SetAnchors("center","center")

	TheGameSettings:GetGraphicsOptions():DisableStencil()
	TheGameSettings:GetGraphicsOptions():DisableLightMapComponent()

	-- Super ugly background image:
	self.bg = self:AddChild(Image("images/bg_loading/loading.tex"))
	self.bg:SetAnchors("fill","fill")
	self.bg:SetMultColor(0, 0, 0, 1.0)

	self.fixed_root = self:AddChild(Screen("WaitingForPlayersScreen_fixed_root"))
		:SetAnchors("center","center")
		:SetScaleMode(SCALEMODE_PROPORTIONAL)

	self.status_text = self.fixed_root:AddChild(Text(FONTFACE.DEFAULT, 90, STRINGS.UI.WAITINGFORPLAYERSSCREEN.WAITING_TEXT, UICOLORS.WHITE))
		:LayoutBounds("center", "center", self)
		:Hide()

	self:SetNonInteractive()
end

function WaitingForPlayersScreen:Close()
	self:StopUpdating() -- this doesn't guarantee a stop update

	if not self.close_started then
		TheLog.ch.Networking:printf("All players are ready. Starting game.")
		self.close_started = true
		TheFrontEnd:PopScreen(self)
		self.callback(self.savedata, self.profile)
	end
end

function WaitingForPlayersScreen:OnOpen()
	self.end_time = TheSim:GetRealTime() + STATUS_REVEAL_WAIT_TIME
end

function WaitingForPlayersScreen:CheckReadyToProgress()
	if not self.close_started then
		if TheNet:GetNrRemotePlayers() > 0 and not self.status_text:IsVisible() and (TheSim:GetRealTime() > STATUS_REVEAL_WAIT_TIME) then
			TheLog.ch.Networking:printf("WaitingForPlayersScreen: Showing waiting for players")
			TheFrontEnd:SetFadeLevel(0)
			self.status_text:Show()

			self.end_time = self.end_time + STATUS_MIN_VISIBLE_TIME	-- extend the time by a bit so the text doesn't flicker on screen and then immediately disappear
		end
	
		if TheNet:IsReadyToStartRoom() and (TheSim:GetRealTime() > self.end_time) then 
			self:Close()
		end
	end
end

return WaitingForPlayersScreen
