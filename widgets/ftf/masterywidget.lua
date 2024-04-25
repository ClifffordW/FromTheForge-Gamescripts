local Image = require("widgets/image")
local ImageButton = require("widgets/imagebutton")
local Text = require("widgets/text")
local Widget = require("widgets/widget")
local ActionButton = require("widgets/actionbutton")
local itemforge = require"defs.itemforge"
local Mastery = require"defs.masteries"
local PowerWidget = require("widgets/ftf/powerwidget")
local CosmeticIcon = require("widgets/ftf/cosmeticicon")
local LockedMetaRewardWidget = require("widgets/ftf/lockedmetarewardwidget")
local Power = require"defs.powers"
local Consumable = require"defs.consumable"
local Panel = require("widgets/panel")
local easing = require "util.easing"
local Cosmetic = require "defs.cosmetics.cosmetics"
local soundutil = require "util.soundutil"
local fmodtable = require "defs.sound.fmodtable"
local ui_ftf_mastery_icons = require "gen.atlas.ui_ftf_mastery_icons"

local TOOLTIP_TEXT_WIDTH = 780

local MasteryWidgetTooltip = Class(Widget, function(self)
	Widget._ctor(self, "MasteryWidgetTooltip")

	self.bg = self:AddChild(Image("images/ui_ftf_relic_selection/relic_bg_blank.tex"))
		:ApplyMultColor(0, 0, 0, TOOLTIP_BG_ALPHA)

	self.container = self:AddChild(Widget())

	self.item_name = self.container:AddChild(Text(FONTFACE.DEFAULT, FONTSIZE.SCREEN_SUBTITLE))
		:LeftAlign()
        :SetRegionSize(TOOLTIP_TEXT_WIDTH, 70)
        :EnableWordWrap(true)
        :ShrinkToFitRegion(true)
		:SetGlyphColor(UICOLORS.LIGHT_TEXT)

	self.item_desc = self.container:AddChild(Text(FONTFACE.DEFAULT, FONTSIZE.SCREEN_TEXT))
		:LeftAlign()
		:SetAutoSize(TOOLTIP_TEXT_WIDTH)
		:OverrideLineHeight(FONTSIZE.SCREEN_TEXT+10)
		:SetGlyphColor(UICOLORS.LIGHT_TEXT_DARK)

	self.dividing_line = self.container:AddChild(Image("images/ui_ftf_inventory/StatsUnderline3.tex"))
		:SetMultColor(UICOLORS.LIGHT_TEXT_DARKER)
		:SetSize(480, 2.5)

	self.progress_text = self.container:AddChild(Text(FONTFACE.DEFAULT, FONTSIZE.COMMON_OVERLAY, ""))
		:LeftAlign()
		:SetAutoSize(TOOLTIP_TEXT_WIDTH)
		:SetGlyphColor(UICOLORS.LIGHT_TEXT)

	self.rewards_text = self.container:AddChild(Text(FONTFACE.DEFAULT, FONTSIZE.COMMON_OVERLAY, STRINGS.UI.MASTERYSCREEN.REWARDS))
		:LeftAlign()
		:SetAutoSize(TOOLTIP_TEXT_WIDTH)
		:SetGlyphColor(UICOLORS.LIGHT_TEXT)

	self.rewards_group = self.container:AddChild(Widget())
	self.title_rewards_group = self.container:AddChild(Widget())
end)

function MasteryWidgetTooltip:LayoutWithContent( data )

	-- ricardo: there's some circumstance where the data comes in without an instance, making this crash
	-- This check prevents the crash, but there should be data instead
	if not (data and data.mastery_inst) then return end

	self.mastery_inst = data.mastery_inst

	local def = self.mastery_inst:GetDef()
	local current = self.mastery_inst:GetProgress()
	local max = self.mastery_inst:GetMaxProgress()

	self.item_name:SetText(self.mastery_inst.persistdata:GetLocalizedName())
	self.item_desc:SetText(string.format("<i>%s</>", Mastery.GetDesc(self.mastery_inst)))

	if self.mastery_inst:IsClaimed() then
		self.progress_text:SetText(STRINGS.UI.MASTERYSCREEN.PROGRESS_COMPLETE)
	else
		self.progress_text:SetText(string.format(STRINGS.UI.MASTERYSCREEN.PROGRESS, current, max))
	end

	self.rewards_group:RemoveAllChildren()
	local title_rewards = {}
	for _, reward in ipairs( def.rewards ) do

		local widget = self.rewards_group:AddChild(Widget())

		if reward.def.build then
			widget:AddChild( CosmeticIcon(reward.def, 90) )

			widget:AddChild(Text(FONTFACE.DEFAULT, 40, string.format("x %d", reward.count), UICOLORS.LIGHT_TEXT))
				:LayoutBounds("after", "center", widget)
				:Offset(10, 0)
		elseif reward.def.slot == Cosmetic.Slots.PLAYER_TITLE then
			table.insert(title_rewards, reward)
		else
			local size = 100
			local image = widget:AddChild(Image("images/global/square.tex"))

			image:SetTexture(reward.icon)
				:SetSize(size, size)

			widget:AddChild(Text(FONTFACE.DEFAULT, 40, string.format("x %d", reward.count), UICOLORS.LIGHT_TEXT))
				:LayoutBounds("after", "center", image)
		end
	end

	self.rewards_group:LayoutChildrenInGrid(5, 20)

	self.title_rewards_group:RemoveAllChildren()
	for _, reward in ipairs( title_rewards ) do
		local widget = self.title_rewards_group:AddChild(Widget())

		local title_str = string.format(STRINGS.UI.MASTERYSCREEN.UNLOCK_NEW_TITLE, string.upper(STRINGS.COSMETICS.TITLES[string.upper(reward.def.title_key)]))
		widget:AddChild(Text(FONTFACE.DEFAULT, 40, title_str, UICOLORS.LIGHT_TEXT))
					:LayoutBounds("center", "below", widget)
					:Offset(10, 0)
	end

	self.title_rewards_group:LayoutChildrenInColumn(20)

	local x1, y1, x2, y2 = self.rewards_group:GetBoundingBox()
	self.item_desc:SetAutoSize(math.max(x2-x1, TOOLTIP_TEXT_WIDTH))
		:LayoutBounds("left", "below", self.item_name):Offset(0,-5)

	self.progress_text:LayoutBounds("left", "below", self.item_desc):Offset(0,-20)
	self.dividing_line:LayoutBounds("left", "below", self.progress_text):Offset(0,-20)
	self.rewards_text:LayoutBounds("left", "below", self.dividing_line):Offset(0,-20)
	self.rewards_group:LayoutBounds("left", "below", self.rewards_text)
	self.title_rewards_group:LayoutBounds("left", "below", self.rewards_group):Offset(0, -10)

	local w, h = self.container:GetSize()
	self.bg:SetSize(w+50, h+50)

	self.container:LayoutBounds("center", "center", self.bg)

	return true
end


local MasteryWidget = Class(Widget, function(self, player, size)
	Widget._ctor(self, "MasteryWidget")

	self:SetOwningPlayer(player)

	-- sound
	self:SetControlDownSound(nil)
	self:SetControlUpSound(nil)
	self:SetHoverSound(fmodtable.Event.hover)
	self:SetGainFocusSound(fmodtable.Event.hover)

	self.size = size or 300

	self.background = self:AddChild(Image(ui_ftf_mastery_icons.tex.mask_mastery_icons))
		:SetSize(self.size, self.size)
		:SetMask()

	self.button = self:AddChild(ImageButton("images/global/square.tex"))
		:SetSize(self.size * 0.65, self.size * 0.65)
		:SetEnabled(false)
		:SetMultColorAlpha(0)


	self.icon = self:AddChild(Image())
		:SetSize(self.size * 0.8, self.size * 0.8)
		:SetMasked()

	self.border = self:AddChild(Image(ui_ftf_mastery_icons.tex.frame_mastery_icons))
		:SetSize(self.size, self.size)

	-- Add quantity
	self.quantity = self:AddChild(Text(FONTFACE.DEFAULT, 30 * HACK_FOR_4K, "", UICOLORS.LIGHT_TEXT_TITLE))
		:SetOutlineColor(UICOLORS.BACKGROUND_LIGHT)
		:EnableOutline(0.00001)
		:EnableShadow()
		:LayoutBounds("center", "center", self.background)

	local btn_scale = 0.55
	self.claim_button = self:AddChild(ActionButton())
		:SetSize(BUTTON_W * 0.5, BUTTON_H)
		:SetScale(btn_scale)
		:SetNormalScale(btn_scale)
		:SetFocusScale(btn_scale)
		:SetText(STRINGS.UI.MASTERYSCREEN.CLAIM)
		:SetHiddenBoundingBox(true)
		:LayoutBounds("center", "center", self.background)
		:Offset(0, 0)
		:SetToolTipClass(MasteryWidgetTooltip)
		:ShowToolTipOnFocus(true)
		:Hide()
		:SetOnClick(function()
			self:Claim()
		end)

	self.lock_badge = self:AddChild(Image("images/ui_ftf_character/LockBadge.tex"))
		:SetName("Lock badge")
		:SetHiddenBoundingBox(true)
		:LayoutBounds("center", "center", self.background)
		:SetScale(0.75)


	self.new_icon = self:AddChild(Image("images/ui_ftf/star.tex"))
		:SetScale(0.8)
		:LayoutBounds("center", "top", self.background)
		:SetHiddenBoundingBox(true)
		:SetToolTip(STRINGS.UI.MASTERYSCREEN.NEW_MASTERY)
		:Hide()

	self:SetBracketSizeOverride(self.size * 0.8, self.size * 0.8)
	self:SetNavFocusable(true)
	self:ShowToolTipOnFocus(true)
	self.rewards = self:AddChild(Widget())
	self.reward_icon_width = 80 * HACK_FOR_4K
	
	self.title_rewards = self:AddChild(Widget())

	self.can_claim = true
	self.on_claim_fn = nil
end)

MasteryWidget.CONTROL_MAP =
{
	{
		control = Controls.Digital.ACCEPT,
		fn = function(self)
			if self:IsRelativeNavigation() then
				if self.claim_button:IsShown() then
					self.claim_button:Click()
					return true
				end
			end
		end,
	},
}

function MasteryWidget:IsRelativeNavigation()
	return self:GetOwningPlayer().components.playercontroller:IsRelativeNavigation()
end

function MasteryWidget:ShowPlayerColor()
	dbassert(not self.solid_bg)
	local player = self:GetOwningPlayer()
	dbassert(player)
	local border_size = self.size + 30
	self.solid_bg = self:AddChild(Image(ui_ftf_mastery_icons.tex.fill_mastery_icons))
		:SetSize(border_size, border_size)
		:SetMultColor(player.uicolor)
		:SendToBack()
	return self
end

function MasteryWidget:OnGainFocus()
	if self.mastery_inst and self.can_claim and not self:GetOwningPlayer().components.hasseen:HasSeenMastery(self.def.name) then
		self:GetOwningPlayer().components.hasseen:MarkMasteryAsSeen(self.def.name)
		self:Refresh()
	end

	if self.on_gain_focus_fn then
		self.on_gain_focus_fn()
	end
end

function MasteryWidget:SetOnGainFocusFn(on_gain_focus_fn)
	self.on_gain_focus_fn = on_gain_focus_fn
	return self
end

function MasteryWidget:SetMasteryData(mastery_def, starting_progress, current_progress)
	self.starting_progress = starting_progress
	self.current_progress = current_progress
	self.def = mastery_def
	self.mastery_inst = self:GetOwningPlayer().components.masterymanager:GetMastery(mastery_def)
	local icon_tex = mastery_def.icon
	self.icon:SetTexture(icon_tex)
	self:Refresh()
	return self
end

function MasteryWidget:SetClaimFn(claim_fn)
	self.on_claim_fn = claim_fn
	return self
end

function MasteryWidget:Claim()
	local player = self:GetOwningPlayer()

	local rewards = self.mastery_inst:ClaimRewards()
	local title_reward_defs = {}

	self.claim_button:Hide()

	for _, reward in ipairs(rewards) do
		reward:UnlockRewardForPlayer(player, true)

		local def = reward.def
		if def.slot == Consumable.Slots.KEY_ITEMS or def.slot == Consumable.Slots.MATERIALS then
			self.fake_item = itemforge.CreateKeyItem(def)
			self.rewards:AddChild(LockedMetaRewardWidget(self.reward_icon_width, player, self.fake_item, reward.count))
		elseif Power.IsSlot(def.slot) then
			self.fake_item = player.components.powermanager:CreatePower(def)
			self.rewards:AddChild(PowerWidget(self.reward_icon_width, player, self.fake_item))
		elseif Cosmetic.IsSlot(def.slot) then
			if def.slot == Cosmetic.Slots.PLAYER_TITLE then
				table.insert(title_reward_defs, def)
			else
				self.rewards:AddChild(CosmeticIcon(def, self.reward_icon_width))
			end
		end
	end

	self.rewards
		:LayoutInDiagonal(3, 10, 10)
		:LayoutBounds("center", "center", self.background)
		:Offset(0, 150)
		:MoveToFront()

	for _, def in ipairs(title_reward_defs) do
		local title_str = string.format(STRINGS.UI.MASTERYSCREEN.UNLOCK_NEW_TITLE, string.upper(STRINGS.COSMETICS.TITLES[string.upper(def.title_key)]))
		self.title_rewards:AddChild(Text(FONTFACE.DEFAULT, 80, title_str, UICOLORS.BLUE))
					:EnableOutline(true)
					:EnableShadow(true)
	end

	self.title_rewards
		:LayoutChildrenInColumn(30, "left")
		:LayoutBounds("center", "below", self.rewards)
		:Offset(0, 150)
		:MoveToFront()

	local end_pos_x, end_pos_y = self.rewards:GetPos()
	local move_y = 60 * HACK_FOR_4K
	self:RunUpdater(
		Updater.Series{
			Updater.Ease(function(v) self.rewards:SetPos(end_pos_x, v) end, end_pos_y, end_pos_y + move_y, 0.5, easing.outElastic),
			Updater.Wait(0.75),
			Updater.Ease(function(v) self.rewards:SetPos(end_pos_x, v) end, end_pos_y + move_y, end_pos_y + 40, 0.1, easing.outQuad),
			Updater.Do(function()
				self.rewards:RemoveAllChildren()
				self.on_claim_fn()
			end),
		}
	)

	self:PlaySpatialSound(fmodtable.Event.ui_mastery_claim)
end

function MasteryWidget:Refresh()
	-- Show quantity if available
	self.mastery_inst = self:GetOwningPlayer().components.masterymanager:GetMastery(self.def)

	if self.mastery_inst or self.starting_progress then
		if not self.hide_quantity then
			self.quantity:Show()
			self:SetPercent(self.starting_progress or self.mastery_inst:GetProgressPercent())
		end

		self.icon:SetMultColor(UICOLORS.WHITE)
			:SetAddColor(UICOLORS.BLACK)

		self:SetToolTipClass(MasteryWidgetTooltip)
			:SetToolTip({
				mastery_inst = self.mastery_inst,
			})

		self.lock_badge:Hide()

		if not self:GetOwningPlayer().components.hasseen:HasSeenMastery(self.def.name) and self.can_claim then
			self.new_icon:Show()
		else
			self.new_icon:Hide()
		end
	else
		--not yet unlocked
		self.quantity:Hide()

		self.icon:SetMultColor(HexToRGB(0x090909ff))
			:SetAddColor(HexToRGB(0xBCA693ff))

		self.lock_badge:Show()

		self.button:SetOnGainHover(nil)
			:SetOnLoseHover(nil)


		self:SetToolTipClass(nil)
			:SetToolTip(STRINGS.UI.MASTERYSCREEN.LOCKED)
	end

	if self.mastery_inst and self:CanClaim() then
		if self.mastery_inst:IsComplete() then
			self.quantity:Hide()

			self.claim_button:SetShown(not self.mastery_inst:IsClaimed())
				:SetToolTip({
					mastery_inst = self.mastery_inst,
				})
		else
			local tint = HexToRGB(0x999999ff)
			-- self.background:SetMultColor(tint)
			self.icon:SetMultColor(tint)
		end
	end
end

function MasteryWidget:CanClaim()
	return self.can_claim
end

function MasteryWidget:DisableClaim()
	self.can_claim = false
	return self
end

function MasteryWidget:HideQuantity()
	self.quantity:Hide()
	self.hide_quantity = true
	return self
end

function MasteryWidget:DisableHover()
	self:SetOnGainHover(nil)
		:SetOnLoseHover(nil)
		:IgnoreInput(true)

	return self
end

function MasteryWidget:GetDef()
	return self.def
end

function MasteryWidget:GetMaxProgress()
	return self.def.max_progress
end

function MasteryWidget:GetStartingProgress()
	return self.starting_progress
end

function MasteryWidget:GetCurrentProgress()
	return self.current_progress
end

function MasteryWidget:SetPercent(percent)
	self.quantity:SetText(string.format("%.0f%%", percent*100))
end

function MasteryWidget:OnVizChange(is_visible)
	if self.meter_sound_LP then
		if not is_visible then
			TheFrontEnd:GetSound():KillSound(self.meter_sound_LP)
			self.meter_sound_LP = nil
		end
	end
end

function MasteryWidget:OnRemoved()
	if self.meter_sound_LP then
		TheFrontEnd:GetSound():KillSound(self.meter_sound_LP)
		self.meter_sound_LP = nil
	end
end

return MasteryWidget
