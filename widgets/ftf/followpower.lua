local FollowPrompt = require("widgets/ftf/followprompt")
local WorldPowerDescription = require "widgets.ftf.worldpowerdescription"
local Power = require "defs.powers.power"
local ItemForge = require "defs.itemforge"
local easing = require "util.easing"

local SCALE = 0.8

-- Text that follows a world-space entity around.
local FollowPower = Class(FollowPrompt, function(self, power)
	FollowPrompt._ctor(self)

	self.scale = SCALE
	self.offset_x = 0
	self.offset_y = 500

	self.fade_in_time = 0.1
	self.hold_time = 4
	self.fade_out_time = 1

	self.powerwidget = self:AddChild(WorldPowerDescription())

	self._on_hide_followpower = function()
		self.powerwidget:AlphaTo(0, 0.05, easing.inExpo) -- Don't remove it, because it will just handle itself invisibly below
		if self.target ~= nil and self.target:IsValid() then
			self.target:RemoveEventCallback("hide_followpower", self._on_hide_followpower)
		end
	end

	self:SetScale(self.scale)
end)

FollowPower.SCALE = SCALE

function FollowPower:Init(data)
	-- data =
	-- 		target: what world object to be placed on
	--		scale: how big should this widget be

	--		fade_in_time: how long it takes to fade in
	--		hold_time: how long to hold this up
	--		fade_out_time: how long it takes to fade out

	-- 		disable_tooltip: whether or not this should show a tooltip

	-- 		offset_x: x offset lol
	--		offset_y: y offset lol

	local power_def = Power.FindPowerByName(data.power)
	local power = ItemForge.CreatePower(power_def)

	self.powerwidget:SetPower(power, false, true)
		:SetStyle_IconOnly()
		:SetClickable(false)

	if data.target then
		self:SetTarget(data.target)
	end

	if data.offset_x then self.offset_x = data.offset_x end
	if data.offset_y then self.offset_y = data.offset_y end
	if data.scale then self.scale = data.scale end

	self.target = data.target
	self.target:ListenForEvent("hide_followpower", self._on_hide_followpower)

	self:Offset(self.offset_x, self.offset_y)
	self:SetScale(self.scale)
	self:SetTarget(self.target)

	self.powerwidget.icon:AssignToPlayer(self.target)

	if data.disable_tooltip then
		self.powerwidget:SetEnableTooltip(false)
	end	

	-- Fade it in, hold it for 'hold_time', then fade it out
	self.powerwidget:SetMultColorAlpha(0)
	self.powerwidget:AlphaTo(1, data.fade_in_time or self.fade_in_time, easing.inExpo, function()

		if self.powerwidget ~= nil and self.target ~= nil then
			self.target:DoTaskInTime(data.hold_time or self.hold_time, function()

				if self.powerwidget ~= nil then
					self.powerwidget:AlphaTo(0, data.fade_out_time or self.fade_out_time, easing.inExpo, function()
						if self.target ~= nil and self.target:IsValid() then
							self.target:RemoveEventCallback("hide_followpower", self._on_hide_followpower)
						end

						self:Remove()
					end)
				end
			end)
		end
	end)
end

return FollowPower
