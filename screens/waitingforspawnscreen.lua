local Screen = require "widgets.screen"
local fmodtable = require "defs.sound.fmodtable"
local kstring = require "util.kstring"


local MAX_WAIT_SECONDS = 5

-- Holds a FE fade to black until a local player is actually ready to play.
-- Hopefully their cine starts and that clears the fade.
local WaitingForSpawnScreen = Class(Screen, function(self)
	Screen._ctor(self, "WaitingForSpawnScreen")
	self:SetNonInteractive()
	self:SetAudioCategory(Screen.AudioCategory.s.None)
	-- self:SetAudioSnapshotOverride(fmodtable.Event.FullscreenOverlay_Instant_LP)
	-- self:SetAudioEnterOverride(nil)
	-- self:SetAudioExitOverride(nil)

	self:_Init()
end)

function WaitingForSpawnScreen:_Init()
	local old = TheFrontEnd:FindScreen(WaitingForSpawnScreen)
	if old then
		TheLog.ch.Boot:printf("Found another WaitingForSpawnScreen [%s] while creating [%s]. Closing to ignores its timer.", kstring.raw(old), kstring.raw(self))
		TheFrontEnd:PopScreen(old)
	end

	self.inst:DoTaskInTime(MAX_WAIT_SECONDS, function()
		TheLog.ch.Boot:printf("Closing WaitingForSpawnScreen from fallback timer. Fade=%f.", TheFrontEnd:GetFadeLevel())
		self:Close()
	end)


	-- This screen is invisible and relies on FE fade.
	local duration = 0
	TheFrontEnd:FadeToBlack(duration)

	self._onplayerconstructed = function(source, player)
		if self.close_handle then
			return
		end
		-- Before forcing fade out, delay for cine to start so it can handle fade out.
		local delay = 5
		TheLog.ch.Boot:printf("Closing WaitingForSpawnScreen in %d ticks. Fade=%f. Received on_player_set event for [%s]", delay, TheFrontEnd:GetFadeLevel(), player)
		self.close_handle = self.inst:DoTaskInTicks(delay, function()
			self:Close(player)
		end)
	end
	self.inst:ListenForEvent("on_player_set", self._onplayerconstructed, TheDungeon)
end

function WaitingForSpawnScreen:Close(spawned_player)
	TheFrontEnd:PopScreen(self)
	SetPause(false, "InitGame")

	-- Let the cine control the fade if possible.
	local in_cine = spawned_player and spawned_player.components.cineactor and spawned_player.components.cineactor:IsInCine()
	if not in_cine then
		TheFrontEnd:FadeInFromBlack()
	end
end

return WaitingForSpawnScreen
