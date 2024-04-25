local playerutil = require "util.playerutil"
local easing = require "util.easing"
local Enum = require "util.enum"

local HIGHLIGHT_STATE = Enum{
	"STARTING",
	"LOOPING",
	"STOPPING",
	"STOPPED"
}

local MIN_GLOW = 0.45 --minimum glow when looping
local DURATION = 0.6 --duration for initial glow
local LOOPING_DURATION = 0.9 --duration for glow

local TownHighlighter = Class(function(self, inst)
	self.inst = inst
	self.inst:StartUpdatingComponent(self)
	self.state = HIGHLIGHT_STATE.s.STOPPED

	self.current_time = 0
	self.delta = TICKS
	self.duration = DURATION
end)

function TownHighlighter:DoPulse(should_show)
	local color = {25/255, 20/255, 60/255}

	local pre_time = self.current_time
	self.current_time = self.current_time + self.delta
	if self.current_time >= self.duration then
		self.delta = -TICKS
	elseif self.current_time <= 0 then
		self.delta = TICKS
	end

	if should_show and self.state == HIGHLIGHT_STATE.s.STOPPED then
		self.state = HIGHLIGHT_STATE.s.STARTING
		self.current_time = 0
		self.inst:PushEvent("interactable_pulse", 1)
	end

	local should_update = self.state ~= HIGHLIGHT_STATE.s.STOPPED

	if self.inst:IsValid() and should_update then
		local r, g, b = table.unpack(color)
		local intensity

		if self.state == HIGHLIGHT_STATE.s.LOOPING then
			intensity = easing.inOutQuad(self.current_time, MIN_GLOW, 1-MIN_GLOW, self.duration)
		else
			intensity = easing.inOutQuad(self.current_time, 0, 1, self.duration)
		end

		if math.abs(self.duration - self.current_time) < 0.01 then
			if should_show then
				self.state = HIGHLIGHT_STATE.s.LOOPING
				self.duration = LOOPING_DURATION
				self.current_time = LOOPING_DURATION
			else
				self.state = HIGHLIGHT_STATE.s.STOPPING
				self.duration = DURATION
				self.current_time = DURATION
				self.inst:PushEvent("interactable_pulse", 0)
			end
		end

		--we want to stop, and the glow has completed, so mark myself as stopped
		if intensity < 0.05 and not should_show then
			self.state = HIGHLIGHT_STATE.s.STOPPED
		end

		self.inst.components.coloradder:PushColor("LowHealthPulse", (r)*intensity, (g)*intensity, (b)*intensity, (1)*intensity)
	end
end

function TownHighlighter:OnUpdate(dt)

	--check local players
	local should_show = false
	playerutil.DoForAllLocalPlayers(function(player)
		if self.inst:GetDistanceSqTo(player) < 100 then
			should_show = true
		end
	end)	

	local coloradder = self.inst.components.coloradder
	if coloradder == nil then
		self.inst:AddComponent("coloradder")
	end

	self:DoPulse(should_show)
end

return TownHighlighter
