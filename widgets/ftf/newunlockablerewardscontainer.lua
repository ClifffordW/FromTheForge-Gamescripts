local Widget = require("widgets/widget")
local Panel = require('widgets/panel')
local Image = require('widgets/image')
local ImageButton = require('widgets/imagebutton')
local Text = require('widgets/text')
local HotkeyWidget = require('widgets/hotkeywidget')
local PowerWidget = require("widgets/ftf/powerwidget")
local LockedMetaRewardWidget = require("widgets/ftf/lockedmetarewardwidget")

local itemforge = require"defs.itemforge"
local Power = require"defs.powers"
local Consumable = require"defs.consumable"
local MetaProgress = require("defs.metaprogression")

local easing = require "util.easing"
local fmodtable = require "defs.sound.fmodtable"

local UnlockableRewardWidget = Class(Widget, function(self, width, owner, reward)
	Widget._ctor(self, "UnlockableRewardWidget")

	self.owner = owner
	self.width = width or 107 * HACK_FOR_4K
	self.icon_width = 100 * HACK_FOR_4K

	self.icon_root = self:AddChild(Widget("Icon Root"))
	self.icon = nil -- created when SetUnlockableData is called

	if reward then
		self:AddReward(reward)
	end
end)

function UnlockableRewardWidget:AddReward(reward)

	if reward:is_a(MetaProgress.RewardGroup) then

		for _, reward_instance in ipairs(reward:GetRewards()) do
			self:AddReward(reward_instance)
		end

	elseif reward:is_a(MetaProgress.Reward) then

		local def = reward.def
		if def.slot == Consumable.Slots.KEY_ITEMS or def.slot == Consumable.Slots.MATERIALS then
			self.fake_item = itemforge.CreateKeyItem(def)
			self.icon = self.icon_root:AddChild(LockedMetaRewardWidget(self.icon_width, self.owner, self.fake_item, reward.count))
		else
			self.fake_item = self.owner.components.powermanager:CreatePower(def)
			self.icon = self.icon_root:AddChild(PowerWidget(self.icon_width, self.owner, self.fake_item))
		end

	end

	self:Layout()
end

function UnlockableRewardWidget:SetUnlocked(optional_text_above)
	local lock_label_x, lock_label_y = self.instructions_label:GetPos()
	local text_x, text_y = self.text_container:GetPos()

	-- Setup animation
	local animation = Updater.Series{
		Updater.Ease(function(v) self.instructions_label:SetScale(v) end, 1, 1.1, 0.5, easing.outQuad),
		Updater.Parallel{
			Updater.Ease(function(v) self.instructions_label:SetMultColorAlpha(v) end, 1, 0, 0.1, easing.outQuad),
			Updater.Ease(function(v) self.instructions_label:SetPos(lock_label_x, v) end, lock_label_y, lock_label_y+10 * HACK_FOR_4K, 0.1, easing.outQuad),
		},
		Updater.Wait(0.1),
		Updater.Parallel{
			Updater.Ease(function(v) self.text_container:SetMultColorAlpha(v) end, 0, 1, 0.2, easing.outQuad),
			Updater.Ease(function(v) self.text_container:SetPos(text_x, v) end, text_y-5, text_y, 0.2, easing.outQuad),
		}
	}

	-- If there's a label to show above the widget at the end, add it here
	if optional_text_above then
		animation:Add(Updater.Wait(0.1))
		animation:Add(Updater.Parallel{
			Updater.Do(function()
				self.instructions_label:SetText(optional_text_above)
					:LayoutBounds("center", nil, self)
					:LayoutBounds(nil, "above", self.details_bg)
					:Offset(0, 4)
			end),
			Updater.Ease(function(v) self.instructions_label:SetMultColorAlpha(v) end, 0, 1, 0.1, easing.outQuad),
		})
	end

	self:RunUpdater(animation)
end

function UnlockableRewardWidget:Layout()
	local MAX_COLUMNS = 4
	local children = self.icon_root:GetChildren()
	
	local scale = #children < MAX_COLUMNS and 1.5 or 0.9
	for _, child in ipairs(children) do
		child:SetScale(scale)
	end

	self.icon_root:LayoutInDiagonal(4, 20, 10)

	local animation = Updater.Series()

	for _, child in ipairs(children) do
		child:SetMultColorAlpha(0)
		animation:Add(Updater.Wait(0.25))
		
		local end_pos_x, end_pos_y = child:GetPos()

		animation:Add(
			Updater.Parallel{
				Updater.Do( function() 
					
					if child:is_a(PowerWidget) then
						self:PlaySpatialSound(fmodtable.Event.ui_endOfRun_unlock_power)
					else
						self:PlaySpatialSound(fmodtable.Event.corestone_accept)
					end

					child:SetMultColorAlpha(1) 
				end),
				Updater.Ease(function(v) child:SetPos(end_pos_x, v) end, end_pos_y-10 * HACK_FOR_4K, end_pos_y, 0.1, easing.outQuad)
			})
	end

	self:RunUpdater(animation)

	return self
end

local UnlockableRewardsContainer = Class(Widget, function(self, width, owner)
	Widget._ctor(self, "UnlockableRewardsContainer")

	self.owner = owner
	self.width = width or 300
	self.reward_width = self.width - 30

	self.current_idx = 1

	self.hitbox = self:AddChild(Image("images/global/square.tex"))
		:SetName("Hitbox")
		:SetSize(self.width, 340)
		:SetMultColor(UICOLORS.DEBUG)
		:SetMultColorAlpha(0.0)

	self.info_label = self:AddChild(Text(FONTFACE.DEFAULT, FONTSIZE.ROOMBONUS_TEXT * 0.8))
		:SetName("Info label")
		:SetGlyphColor(UICOLORS.LIGHT_TEXT_DARK)
		:SetHiddenBoundingBox(true)
		:SetMultColorAlpha(0)

	self.rewards_container = self:AddChild(Widget())
		:SetName("Rewards container")
		:SetHiddenBoundingBox(true)

	self:Layout()
end)

function UnlockableRewardsContainer:RemoveAllPowers()
	self.rewards_container:RemoveAllChildren()
	self:Layout()
end

function UnlockableRewardsContainer:AddReward(reward, level_num, has_earned_reward)

	-- Create reward widget
	local reward_widget = self.rewards_container:AddChild(UnlockableRewardWidget(self.reward_width, self.owner, reward))
		-- :SetTitleColor(UICOLORS.LIGHT_TEXT_DARKER)
		-- :SetMultColorAlpha(0)

	-- Save important info on it
	reward_widget.reward_idx = #self.rewards_container.children
	reward_widget.info_text = STRINGS.UI.DUNGEONLEVELWIDGET.REWARD_UNLOCKED

	-- Layout everything again
	self:Layout()

	-- Save its position, for animation purposes
	reward_widget.center_x, reward_widget.center_y = reward_widget:GetPos()

	-- And now animate it!
	--self:AnimateToIdx(#self.rewards_container.children)
	return reward_widget
end

function UnlockableRewardsContainer:Layout()
	self.rewards_container
		:LayoutBounds("center", "center")
		:Offset(0, 20)

	return self
end

return UnlockableRewardsContainer
