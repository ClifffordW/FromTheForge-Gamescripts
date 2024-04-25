local Power = require "defs.powers"
local Text = require "widgets.text"
local Widget = require "widgets.widget"
local PowerIconWidget = require "widgets.powericonwidget"
local PowerTooltip = require"widgets.ftf.powertooltip"
local easing = require "util.easing"
local fmodtable = require "defs.sound.fmodtable"

-- Displays a power widget (frame, icon, and stacks)

local PowerWidget = Class(Widget, function(self, width, owner, power)
	Widget._ctor(self, "PowerWidget")
	self:SetHoverSound(fmodtable.Event.hover)
	-- TODO(demo): Enable asserts after demo
	--~ assert(owner)
	--~ assert(power)

	self.width = width or 107

	self.owner = owner
	self.power = power
	self.power_def = power:GetDef()

	self:SetToolTipClass(PowerTooltip)

	self.power_widget_root = self:AddChild(Widget())

	self.power_widget = self.power_widget_root:AddChild(PowerIconWidget())
		:SetScaleToMatchWidth(self.width)
		:SetPower(power)

	self.power_widget_status = self.power_widget_root:AddChild(PowerIconWidget())
		:SetScaleToMatchWidth(self.width)
		:SetSaturation(0)
		:SetMultColor(0, 0, 0, 0.5)
		:SetPower(power)
		:Hide()

	self:UpdateUI()

	self.text_root = self.power_widget:AddChild(Widget())
		:LayoutBounds("right", "top", self.power_widget)
		:Offset(-48 * HACK_FOR_4K, -52 * HACK_FOR_4K)
		:SetScale(4)

	self.counter_text = self.text_root:AddChild(Text(FONTFACE.DEFAULT, 23 * HACK_FOR_4K, nil, UICOLORS.LIGHT_TEXT_TITLE))
		:SetShadowColor(UICOLORS.BLACK)
		:SetShadowOffset(1, -1)
		:SetOutlineColor(UICOLORS.BLACK)
		:EnableShadow()
		:EnableOutline()

	self.text_root:Hide()

	self.inst:ListenForEvent("update_power", function(owner_, def)
		assert(owner_ == self.owner)
		if def.name == self.power_def.name then
			self:UpdateStacks()
			self:UpdateUI()
		end
	end, owner)

	self.inst:ListenForEvent("used_power", function(owner_, def)
		assert(owner_ == self.owner)
		if def.name == self.power_def.name then
			self:UpdateStacks()
			self:UpdateUI()
		end
	end, owner)

	self.inst:ListenForEvent("power_upgraded", function(owner_, pow)
		assert(owner_ == self.owner)
		if pow.def.name == self.power_def.name then
			self:AnimateFocusGrab(2.3)
		end
	end, owner)

	self:UpdateStacks()
end)

function PowerWidget:RefreshCounterLayoutBounds()
	print ("############ REFRESHING")
	-- self.text_root:LayoutBounds("right", "top", self.power_widget)
	-- 	:Offset(13 * HACK_FOR_4K, 12 * HACK_FOR_4K)
		--:Offset(0,0)
		--:Offset(-24 * HACK_FOR_4K, -26 * HACK_FOR_4K)
end

function PowerWidget:GetSizeVar()
	return self.width
end

function PowerWidget:SetSize(size)
	self.width = size
	self.power_widget:SetScaleToMatchWidth(self.width)
	self.power_widget_status:SetScaleToMatchWidth(self.width)
end

function PowerWidget:UpdateUI()
	self:SetToolTip({ power = self.power })
	self.power_widget:UpdatePower()
end

function PowerWidget:UpdateStacks()
	local text
	local power = self.power
	if power then
		if self.power_def.get_counter_text then
			text = self.power_def.get_counter_text(power, self.owner)
		elseif power.counter
			and ((type(power.counter) == "number" and power.counter > 0)
				or (type(power.counter) == "string" and power.counter ~= "")) then
			text = power.counter
		end
	end

	if text then
		self.text_root:Show()
		self.counter_text:SetText(text)
			-- HACK: For some reason, the text doesn't display from
			-- PlayerFollowStatus unless we change the colour after it becomes
			-- visible.
			:SetGlyphColor(UICOLORS.LIGHT_TEXT_TITLE)
	else
		self.text_root:Hide()
	end
end

function PowerWidget:AnimateFocusGrab(duration)
	if self.is_animating then
		return
	end
	self.is_animating = true

	self:ScaleTo(1, 1.75, duration * 0.6, easing.inOutQuad, function()
		self:ScaleTo(1.75, 1, duration * 0.4, easing.outElastic)
	end)
end

return PowerWidget
