local MasteryWidget = require("widgets/ftf/masterywidget")
local Mastery = require "defs.mastery.mastery"
local Widget = require "widgets.widget"
local Text = require "widgets.text"
local Image = require "widgets.image"
local PopPrompt = require "widgets.ftf.popprompt"
local fmodtable = require "defs.sound.fmodtable"

local easing = require "util.easing"

local PopMasteryProgress = Class(PopPrompt, function(self, target, button)
	Widget._ctor(self, "PopMasteryProgress")

	self.text_root = self:AddChild(Widget())

	self.number = self.text_root:AddChild(Text(FONTFACE.BUTTON, 75, "", UICOLORS.GOLD_FOCUS))
		:SetShadowColor(UICOLORS.BLACK)
		:SetShadowOffset(1, -1)
		:SetOutlineColor(UICOLORS.BLACK)
		:EnableShadow()
		:EnableOutline()

	self.desc = self.text_root:AddChild(Text(FONTFACE.BUTTON, 50, "", UICOLORS.WHITE))
		:SetShadowColor(UICOLORS.BLACK)
		:SetShadowOffset(1, -1)
		:SetOutlineColor(UICOLORS.BLACK)
		:EnableShadow()
		:EnableOutline()
		:LeftAlign()
end)

function PopMasteryProgress:PlayProgressSound(data)
	local progress = data.mastery:GetProgress() / data.mastery:GetMaxProgress()
	-- d_view(self.mastery_inst.persist_data.progress)
	self:PlaySpatialSound(fmodtable.Event.ui_mastery_progress, { masteryProgress = progress })
end

function PopMasteryProgress:PlayCompleteSound(data)
	if data.mastery.def.slot == Mastery.Slots.MONSTER_MASTERY then
		self:PlaySpatialSound(fmodtable.Event.ui_mastery_monster_complete)
	else
		self:PlaySpatialSound(fmodtable.Event.ui_mastery_weapon_complete)
	end
end

local function _get_main_string(mst, is_past_threshold)
	local pretty_name = mst:GetDef().pretty.name
	local main_str

	if is_past_threshold then
		main_str = ("%s/%s %s"):format(mst:GetProgress(), mst:GetMaxProgress(), pretty_name)
	else
		main_str = ("%s/%s"):format(mst:GetProgress(), mst:GetMaxProgress())
	end

	if mst:IsNew() then
		main_str = STRINGS.UI.MASTERYSCREEN.POPUP.MASTERY_ACTIVATED:subfmt({mastery_name = pretty_name})
	end

	if mst:IsComplete() then
		main_str = STRINGS.UI.MASTERYSCREEN.POPUP.MASTERY_COMPLETED:subfmt({mastery_name = pretty_name})
	end

	return main_str
end

function PopMasteryProgress:Init(data)
	self:Refresh(data)
end

function PopMasteryProgress:Refresh(data)
	local started = self:Start(data)

	if not started then
		return
	end

	if self.icon then
		self.icon:Remove()
	end

	-- Layout everything relative to icon to get consistent visual appearance
	-- if we step through consecutive levels in quick succession.
	-- TODO: Even better would be to move the x/x text to the icon instead of in number.
	self.icon = self:AddChild(MasteryWidget(data.target, 180))
		:ShowPlayerColor()
		:HideQuantity()
		:DisableHover()
		:DisableClaim()
		:SetMasteryData(data.mastery.def)
		:Offset(-100, 0)  -- to balance text on right

	if data.color then
		self.number:SetGlyphColor(data.color)
	end

	if data.outline_color then
		self.number:SetOutlineColor(data.outline_color)
	end

	if data.size then
		self.number:SetFontSize(data.size)
		self.desc:SetFontSize(math.floor(data.size * 0.66))
	end

	local main_str = _get_main_string(data.mastery, data.is_past_threshold)
	local desc_str = Mastery.GetDesc(data.mastery)

	self.number:SetText(main_str)

	local w, h = self.number:GetSize()

	self.number
		:LayoutBounds("after", "top", self.icon)
		:Offset(20,0)

	self.desc:SetText(desc_str)
		:SetAutoSize(w)
		:LayoutBounds("left", "below", self.number)
		:Show()

	--if I've seen this mastery hide the desc
	if not data.mastery:IsComplete() and not data.is_past_threshold then
		self.desc:Hide()
	end

	self:Extend(data)

	if data.mastery:IsComplete() then
		self:PlayCompleteSound(data)
	else
		self:PlayProgressSound(data)
	end
end

return PopMasteryProgress
