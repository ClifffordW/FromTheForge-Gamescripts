local Widget = require("widgets/widget")
local Text = require("widgets/text")
local PlayerPuppet = require("widgets/playerpuppet")
local Image = require("widgets/image")
local ImageButton = require("widgets/imagebutton")
local LoadingIndicator = require("widgets/loadingindicator")
local UIAnim = require "widgets.uianim"
local DisplayStat = require("widgets/ftf/displaystat")
local SkillWidget = require("widgets/ftf/skillwidget")
local PowerWidget = require("widgets/ftf/powerwidget")
local DungeonLevelWidget = require("widgets/ftf/dungeonlevelwidget")
local InventorySlot = require "widgets.ftf.inventoryslot"
local ItemWidget = require("widgets/ftf/itemwidget")
local MasteryWidget = require("widgets/ftf/masterywidget")
local UnlockableRewardsContainer = require('widgets/ftf/newunlockablerewardscontainer')
local fmodtable = require "defs.sound.fmodtable"
local Equipment = require("defs.equipment")
local ItemCatalog = require("defs.itemcatalog")
local Consumable = require("defs.consumable")
local Power = require 'defs.powers'
local easing = require "util.easing"
local iterator = require "util.iterator"
local lume = require "util.lume"
local monster_pictures = require "gen.atlas.monster_pictures"
local PlayerTitleWidget = require("widgets/ftf/playertitlewidget")
local EquipmentTooltip = require"widgets/ftf/equipmenttooltip"
local itemforge = require "defs.itemforge"
local Mastery = require "defs.masteries"
local MetaProgress = require("defs.metaprogression")


local NewPlayerDungeonSummary = Class(Widget, function(self, player, reward_data)
	Widget._ctor(self, "NewPlayerDungeonSummary")

	self:SetOwningPlayer(player)

	-- Show rolled paper anim over the contents
	self.roll_anim = self:AddChild(UIAnim())
		:SetName("Roll anim")
		:SetScale(0.52 * HACK_FOR_4K)
		:SetBank("ui_scroll")
		:PlayAnimation("downidle")
	self.roll_anim_w, self.roll_anim_h = self.roll_anim:GetScaledSize()

	-- Player portrait
	self.puppet_container = self:AddChild(Widget())
		:SetName("Puppet container")
	self.puppet_bg = self.puppet_container:AddChild(Image("images/ui_ftf_runsummary/CharacterMask.tex"))
		:SetName("Puppet bg")
		:SetMultColor(UICOLORS.WHITE)
	self.puppet_mask = self.puppet_container:AddChild(Image("images/ui_ftf_runsummary/CharacterMask.tex"))
		:SetName("Puppet mask")
		:SetMultColor(UICOLORS.WHITE)
		:SetMask()
	self.puppet = self.puppet_container:AddChild(PlayerPuppet())
		:SetName("Puppet")
		:SetScale(0.35 * HACK_FOR_4K)
		:SetFacing(FACING_RIGHT)
		:SetMasked()
	self.puppet_overlay = self.puppet_container:AddChild(Image("images/ui_ftf_runsummary/CharacterBg.tex"))
		:SetName("Overlay")
		:SetMultColor(HexToRGB(0x3D3029ff))

	-- Player username
	self.username = self:AddChild(Text(FONTFACE.DEFAULT, 25 * HACK_FOR_4K, "", UICOLORS.LIGHT_TEXT_TITLE))
		:SetName("Username")
		:LeftAlign()

	self.player_title = self:AddChild(PlayerTitleWidget(nil, FONTSIZE.SCREEN_TEXT))
		--:LeftAlign()

	-- Networking: some data on this screen will be static, filled out once and never updated.
	-- Other clients will be sending data every tick, so that the data is always available.
	-- So that we don't have to rebuild the screen every time, let's build the static data once and never rebuild it.
	-- Then, we'll only update the other clients' cursor positions.
	self.static_data_configured = false

	------------------------------------------------------------------------------
	-- Contains the background and all panel contents.
	-- Gets scissored during in/out animation
	-- The roll anim is shown over this
	self.panel_contents = self:AddChild(Widget())
		:SetName("Panel contents")
		:SendToBack()
		:SetShowDebugBoundingBox(true)

	-- Background for the panel
	self.bg = self.panel_contents:AddChild(Image("images/ui_ftf_runsummary/PanelBg.tex"))
		:SetName("Background")

	-- Show player equipment
	self.equipment_container = self.panel_contents:AddChild(Widget())
		:SetName("Equipment container")
	local weapon_slot_size = 95 * HACK_FOR_4K
	local slot_size = 70 * HACK_FOR_4K

	local function slot_tooltip_fn(focus_widget, tooltip_widget)
		tooltip_widget:LayoutBounds("center", nil, self.bg)
			:LayoutBounds(nil, "below", self.slot_weapon)
			:Offset(0, -15 * HACK_FOR_4K)
	end

	self.slot_weapon = self.equipment_container:AddChild(InventorySlot(weapon_slot_size, ItemCatalog.All.SlotDescriptor[Equipment.Slots.WEAPON].icon))
		:SetName("Slot weapon")
		:SetBackground("images/ui_ftf_runsummary/WeaponSlot.tex", "images/ui_ftf_inventory/WeaponSlotOverlay.tex", "images/ui_ftf_runsummary/WeaponSlot.tex")
		:ApplyTheme_DungeonSummary()
		:SetToolTipLayoutFn(slot_tooltip_fn)
		:ShowToolTipOnFocus(true)
		:SetMoveOnClick(false)
		:SetControlDownSound(nil)
		:SetControlUpSound(nil)
		:SetGainFocusSound(nil)
		:SetToolTipClass(EquipmentTooltip)

	self.slot_potion = self.equipment_container:AddChild(InventorySlot(slot_size*1.1, ItemCatalog.All.SlotDescriptor[Equipment.Slots.POTIONS].icon))
		:SetName("Slot potion")
		:ApplyTheme_DungeonSummaryPotion()
		:SetToolTipLayoutFn(slot_tooltip_fn)
		:ShowToolTipOnFocus(true)
		:SetMoveOnClick(false)
		:SetControlDownSound(nil)
		:SetControlUpSound(nil)
		:SetGainFocusSound(nil)
		:SetToolTipClass(EquipmentTooltip)

	self.slot_tonic = self.equipment_container:AddChild(InventorySlot(slot_size*0.6, ItemCatalog.All.SlotDescriptor[Equipment.Slots.TONICS].icon))
		:SetName("Slot tonic")
		:ApplyTheme_DungeonSummaryTonic()
		:SetToolTipLayoutFn(slot_tooltip_fn)
		:ShowToolTipOnFocus(true)
		:SetMoveOnClick(false)
		:SetControlDownSound(nil)
		:SetControlUpSound(nil)
		:SetGainFocusSound(nil)

	self.slot_food = self.equipment_container:AddChild(InventorySlot(slot_size, ItemCatalog.All.SlotDescriptor[Equipment.Slots.FOOD].icon))
		:SetName("Slot food")
		:ApplyTheme_DungeonSummary()
		:SetToolTipLayoutFn(slot_tooltip_fn)
		:ShowToolTipOnFocus(true)
		:SetMoveOnClick(false)
		:SetControlDownSound(nil)
		:SetControlUpSound(nil)
		:SetGainFocusSound(nil)

	self.slot_skill = self.equipment_container:AddChild(SkillWidget(slot_size * 0.9, player))
		:SetName("Slot skill")
		:SetToolTipLayoutFn(slot_tooltip_fn)
		:ShowToolTipOnFocus(true)
		:SetNavFocusable(true)
		:SetControlDownSound(nil)
		:SetControlUpSound(nil)
		:SetGainFocusSound(nil)

	------------------------------------------------------------------------------
	-- Only one of these is shown at a given time:
	------------------------------------------------------------------------------
	-- Contains the summary widgets
	self.summary_contents = self.panel_contents:AddChild(Widget())
		:SetName("Summary contents")
		:Hide()
	-- Contains the rewards widgets
	self.rewards_contents = self.panel_contents:AddChild(Widget())
		:SetName("Rewards contents")
		:Offset(0, 180)
		:Hide()
	------------------------------------------------------------------------------

	-- Calculate sizes
	self.width, self.height = self.bg:GetScaledSize()

	-- Calculate content size for animation
	self.content_width, self.content_height = self.panel_contents:GetSize()

	-- How much of the panel will be scissored in the animation, starting from the bottom
	-- Basically everything except the equipment icons at the top
	self.roll_scissored_height = self.content_height - 40

	-- Show kills
	-- self.kills_container = self.summary_contents:AddChild(Widget())
	-- 	:SetName("Kills container")
	-- self.kills_bg = self.kills_container:AddChild(Image("images/ui_ftf_runsummary/KillCountBg.tex"))
	-- 	:SetName("Background")
	-- self.kills_count = self.kills_container:AddChild(Text(FONTFACE.DEFAULT, FONTSIZE.SCREEN_SUBTITLE, "", UICOLORS.LIGHT_TEXT_TITLE))
	-- 	:SetName("Count")
	-- 	:SetGlyphColor(HexToRGB(0xDEC9B3FF))
	-- self.kills_label = self.kills_container:AddChild(Text(FONTFACE.DEFAULT, 20 * HACK_FOR_4K, STRINGS.UI.DUNGEONSUMMARYSCREEN.TOTAL_KILLS, UICOLORS.LIGHT_TEXT_TITLE))
	-- 	:SetName("Label")
	-- 	:SetGlyphColor(HexToRGB(0xDEC9B3FF))

	-- Show stats
	self.stats_title = self.summary_contents:AddChild(Text(FONTFACE.DEFAULT, FONTSIZE.ROOMBONUS_TEXT, STRINGS.UI.DUNGEONSUMMARYSCREEN.STATS_TITLE, UICOLORS.LIGHT_TEXT_DARK))
		:SetName("Stats Title")

	self.stats_container = self.summary_contents:AddChild(Widget())
		:SetName("Stats container")
	-- self.stats_bg = self.stats_container:AddChild(Image("images/ui_ftf_runsummary/StatsBg.tex"))
	-- 	:SetName("Background")
	local stats_w = 290 * HACK_FOR_4K
	self.stats_column = self.stats_container:AddChild(Widget())
		:SetName("Stats column")
	self.stat_damage_done = self.stats_column:AddChild(DisplayStat(stats_w))
		:SetLightBackgroundColors()
		:ShowUnderline(true, 4, HexToRGB(0xBCA493FF))
		:RightAlign()
	self.stat_damage_taken = self.stats_column:AddChild(DisplayStat(stats_w))
		:SetLightBackgroundColors()
		:ShowUnderline(true, 4, HexToRGB(0xBCA493FF))
		:RightAlign()
	self.stat_damage_deaths = self.stats_column:AddChild(DisplayStat(stats_w))
		:SetLightBackgroundColors()
		:ShowUnderline(true, 4, HexToRGB(0xBCA493FF))
		:RightAlign()
	self.stat_kills = self.stats_column:AddChild(DisplayStat(stats_w))
		:SetLightBackgroundColors()
		:ShowUnderline(true, 4, HexToRGB(0xBCA493FF))
		:RightAlign()
	self.stat_rooms = self.stats_column:AddChild(DisplayStat(stats_w))
		:SetLightBackgroundColors()
		:RightAlign()

	local empty_size = FONTSIZE.ROOMBONUS_TEXT * 0.8

	-- Show loot
	self.loot_container = self.summary_contents:AddChild(Widget())
		:SetName("Loot container")
	self.loot_bg = self.loot_container:AddChild(Image("images/ui_ftf_runsummary/LootBg.tex"))
		:SetName("Background")
	self.loot_title = self.loot_container:AddChild(Text(FONTFACE.DEFAULT, FONTSIZE.ROOMBONUS_TEXT, STRINGS.UI.DUNGEONSUMMARYSCREEN.LOOT_TITLE, UICOLORS.LIGHT_TEXT_DARK))
		:SetName("Title")
	self.loot_empty = self.loot_container:AddChild(Text(FONTFACE.DEFAULT, empty_size, STRINGS.UI.DUNGEONSUMMARYSCREEN.LOOT_EMPTY, UICOLORS.LIGHT_TEXT_DARK))
		:SetName("Empty Loot")
	self.loot_widgets = self.loot_container:AddChild(Widget())
		:SetName("Loot widgets")

	self.masteries_title = self.loot_container:AddChild(Text(FONTFACE.DEFAULT, FONTSIZE.ROOMBONUS_TEXT, STRINGS.UI.DUNGEONSUMMARYSCREEN.MASTERIES_TITLE, UICOLORS.LIGHT_TEXT_DARK))
		:SetName("Masteries Title")
	self.mastery_empty = self.loot_container:AddChild(Text(FONTFACE.DEFAULT, empty_size, STRINGS.UI.DUNGEONSUMMARYSCREEN.MASTERY_EMPTY, UICOLORS.LIGHT_TEXT_DARK))
		:SetName("mastery_empty")
	self.mastery_widgets = self.loot_container:AddChild(Widget())
		:SetName("Mastery widgets")

	-- Show powers used
	self.powers_title = self.summary_contents:AddChild(Text(FONTFACE.DEFAULT, FONTSIZE.ROOMBONUS_TEXT, STRINGS.UI.DUNGEONSUMMARYSCREEN.POWERS_TITLE, UICOLORS.LIGHT_TEXT_DARK))
		:SetName("Powers Title")

	self.powers_container = self.summary_contents:AddChild(Widget())
		:SetName("Powers container")
	self.empty_powers = self.summary_contents:AddChild(Text(FONTFACE.DEFAULT, empty_size, STRINGS.UI.DUNGEONSUMMARYSCREEN.POWER_EMPTY, UICOLORS.LIGHT_TEXT_DARK))
		:SetName("mastery_empty")

	-- Show level progression
	self.level_container = self.rewards_contents:AddChild(Widget())
		:SetName("level container")
	self.dungeon_level = self.level_container:AddChild(DungeonLevelWidget(player))
		:SetName("Dungeon level widget")
		:SetScale(1.2)
		:ShowLargePresentation(HexToRGB(0xA3897B77), UICOLORS.LIGHT_TEXT_DARKER)
		:SetTitleFontSize(30 * HACK_FOR_4K)
		:SetHiddenBoundingBox(true)
		:SetPos(0, 130)

	-- Show level reward
	self.reward_container = self.rewards_contents:AddChild(UnlockableRewardsContainer(self.width - 140, player))
		:SetName("Reward container")
		:SetNavFocusable(true)
		:Hide()
		:SetControlDownSound(nil)
		:SetControlUpSound(nil)
		:SetGainFocusSound(nil)

	-- Show loading spinner
	self.loading_indicator = self:AddChild(LoadingIndicator())
		:SetName("Loading indicator")
		:SetText(STRINGS.UI.DUNGEONSUMMARYSCREEN.LOADING_TEXT)
		:SendToBack()

	self.current_page = nil

	self.amount_to_unroll = 0.51 -- how far down the screen to unroll for reward portion (0 is all the way)

	self:SetPlayer(player, reward_data)
end)

function NewPlayerDungeonSummary:_TrySetDefaultFocus()
	if self.player and self.summary_contents:IsVisible() then
		self.powers_container:SetFocus(self.player:GetHunterId())
		return true
	end
end

function NewPlayerDungeonSummary:SetPlayer(player, reward_data)
	self.player = player
	self.player_colour = self.player.uicolor or HexToRGB(0x8CBF91ff)

	self.reward_data = reward_data

	self.username:SetText(player:GetCustomUserName())
	self.player_title:SetOwner(self.player)

	-- Update player color
	self.puppet_bg:SetMultColor(self.player_colour)
	self.puppet_overlay:SetMultColor(self.player_colour)
	self.username:SetGlyphColor(self.player_colour)

	-- used for sound
	self.player_id = self.player:GetHunterId()
	self.faction = self.player:IsLocal() and 1 or 2 -- sets faction parameter to 1 for local players, 2 for remote

	self:_TrySetDefaultFocus()

	self:Layout()
	return self
end

function NewPlayerDungeonSummary:ApplyDataToScreen(data)
	if not self.static_data_configured and data then
		TheLog.ch.RunSummary:print("Showing player ui data from player " .. self.player:GetCustomUserName())
		TheLog.ch.RunSummary:dumptable(data)

		self:RefreshEquipment(data)
		self:RefreshStats(data)
		self:RefreshBuild() -- PowerManager is already synced, other than 'mem' stuff -- so we don't need to send / receive this over the network.
		self:RefreshMetaProgress(data)
		self:RefreshLoot(data)
		self:RefreshMasteries(data)
		self:_TrySetDefaultFocus()
		self:Layout()

		self.static_data_configured = true
	end
end

function NewPlayerDungeonSummary:OnInputModeChanged(old_device_type, new_device_type)
end

function NewPlayerDungeonSummary:RefreshEquipment(display_data)
	-- Update weapon
	local catalog = ItemCatalog.All.Items
	local weapon_def = catalog.WEAPON[display_data.equipment.equipped_weapon]
	local weapon

	if weapon_def then
		weapon = itemforge.CreateEquipment(weapon_def.slot, weapon_def)
	end

	self.slot_weapon:SetItem(weapon, self.player)
		:SetToolTip{ item = weapon, player = self.player }

	-- Update potion
	local potion_def = catalog.POTIONS[display_data.equipment.equipped_potion]
	local potion
	if potion_def then
		potion = itemforge.CreateEquipment(potion_def.slot, potion_def)
	end
	self.slot_potion:SetItem(potion, self.player)
		:SetToolTip{ item = potion, player = self.player }

	-- Update tonic
	local tonic_def = catalog.TONICS[display_data.equipment.equipped_tonic]
	local tonic
	if tonic_def then
		tonic = itemforge.CreateEquipment(tonic_def.slot, tonic_def)
		self.slot_tonic:SetGainFocusSound(fmodtable.Event.hover)
	end
	self.slot_tonic:SetItem(tonic, self.player)

	-- Update food
	local food_def = catalog.FOOD[display_data.equipment.equipped_food]
	local food
	if food_def then
		food = itemforge.CreateEquipment(food_def.slot, food_def)
		self.slot_food:Show()
		self.slot_food:SetHoverSound(fmodtable.Event.hover)
		self.slot_food:SetGainFocusSound(fmodtable.Event.hover)
	else
		self.slot_food:Hide()
	end
	self.slot_food:SetItem(food, self.player)

	-- Update skill
	local skill = self.player.components.powermanager:GetCurrentSkillPower()
	if skill then
		self.slot_skill:SetSkill(skill)
		self.slot_skill:Show()
		self.slot_skill:SetHoverSound(fmodtable.Event.hover)
		self.slot_skill:SetGainFocusSound(fmodtable.Event.hover)
	else
		self.slot_skill:Hide()
	end

	return self
end

function NewPlayerDungeonSummary:RefreshPuppet()
	self.puppet:CloneCharacterWithEquipment(self.player)
	-- TODO: re-layout this puppet, seems to be too far down now?
	return self
end

function NewPlayerDungeonSummary:RefreshStats(display_data)

	if display_data.stats.total_damage_done then
		self.stat_damage_done:SetValue(display_data.stats.total_damage_done, STRINGS.UI.DUNGEONSUMMARYSCREEN.DAMAGE_DONE)
	end

	if display_data.stats.total_damage_taken then
		self.stat_damage_taken:SetValue(display_data.stats.total_damage_taken, STRINGS.UI.DUNGEONSUMMARYSCREEN.DAMAGE_TAKEN)
	end

	self.stat_kills:SetValue(display_data.stats.total_kills or 0, STRINGS.UI.DUNGEONSUMMARYSCREEN.TOTAL_KILLS)
	self.stat_rooms:SetValue(display_data.stats.rooms_discovered or 0, STRINGS.UI.DUNGEONSUMMARYSCREEN.ROOMS_LABEL_STAT)
	self.stat_damage_deaths:SetValue(display_data.stats.total_deaths or 0, STRINGS.UI.DUNGEONSUMMARYSCREEN.DEATHS)

end

function NewPlayerDungeonSummary:RefreshBuild()
	-- PowerManager is already synced, other than 'mem' stuff -- so we don't need to send / receive this over the network.
	local powers = self.player.components.powermanager:GetAllPowersInAcquiredOrder()

	for _, pow in ipairs(powers) do
		if pow.def.show_in_ui then
			if pow.def.power_type ~= Power.Types.SKILL then
				self.powers_container:AddChild(PowerWidget(self.width / 4.5, self.player, pow.persistdata))
					:SetNavFocusable(true)
					:ShowToolTipOnFocus(true)
					-- sound
					:SetControlDownSound(nil)
					:SetControlUpSound(nil)
					:SetGainFocusSound(fmodtable.Event.hover)
			end
			-- else: The skill is shown on the top bar, next to the equipment
		end
	end
	local child = self.powers_container:GetFirstChild()
	self.powers_container.focus_forward = child
	self.empty_powers:SetShown(not child)
end

function NewPlayerDungeonSummary:RefreshMetaProgress(display_data)
	if display_data.biome_exploration then

		local meta_progress_data = display_data.biome_exploration

		if not meta_progress_data.meta_reward and not TheDungeon:IsInTown() then
			local mrm = self.player.components.metaprogressmanager
			local def = MetaProgress.FindProgressByName(TheDungeon:GetCurrentLocationID())
			if not mrm:GetProgress(def) and def ~= nil then
				mrm:StartTrackingProgress(mrm:CreateProgress(def))
			end
			local progress = mrm:GetProgress(def)

			meta_progress_data.meta_reward_def = def
			meta_progress_data.meta_reward = progress
		end

		-- Update progress display
		self.dungeon_level:RefreshMetaProgress(meta_progress_data)

		-- Remove existing rewards
		self.reward_container:RemoveAllPowers()
	end
end

function NewPlayerDungeonSummary:RefreshLoot(display_data)

	-- Remove old loot
	self.loot_widgets:RemoveAllChildren()

	local total_loot_count = 0
	if display_data.loot then
		total_loot_count = total_loot_count + #display_data.loot
	end
	
	if display_data.bonus_loot then
		total_loot_count = total_loot_count + #display_data.bonus_loot
	end
	
	local icon_size = total_loot_count > 5 and 45 or 60

	-- Add new stuffs
	if display_data.loot then
		for _, loot_data in ipairs(display_data.loot) do
			if loot_data.name ~= "konjur" then
				local def = Consumable.FindItem(loot_data.name)
				self.loot_widgets:AddChild(ItemWidget(def, loot_data.count, icon_size * HACK_FOR_4K))
					:SetNavFocusable(true)
					:ShowToolTipOnFocus(true)
			end
		end
	end

	if display_data.bonus_loot then
		for _, loot_data in ipairs(display_data.bonus_loot) do
			local def = Consumable.FindItem(loot_data.name)
			self.loot_widgets:AddChild(ItemWidget(def, loot_data.count, icon_size * HACK_FOR_4K))
				:SetNavFocusable(true)
				:ShowToolTipOnFocus(true)
				:SetBonus()
		end
	end

	return self
end

function NewPlayerDungeonSummary:RefreshMasteries(display_data)
	-- Remove old loot
	self.mastery_widgets:RemoveAllChildren()

	if display_data.masteries then
		local icon_size = #display_data.masteries > 4 and 60 or 80
		for _, mastery_data in ipairs(display_data.masteries) do
			local def = Mastery.FindMasteryByName(mastery_data.name)
			self.mastery_widgets:AddChild(MasteryWidget(self.player, icon_size * HACK_FOR_4K))
				:DisableClaim()
				:SetMasteryData(def, mastery_data.starting_progress, mastery_data.current_progress)
		end
	end

	return self
end

function NewPlayerDungeonSummary:_SetPaperRollAmount(amount_rolled)
	self.panel_contents:SetScissor(-self.content_width/2, -self.content_height/2 + self.roll_scissored_height*amount_rolled, self.content_width, self.content_height)
	self.roll_anim:LayoutBounds(nil, "below", self.panel_contents)
		:Offset(0, self.roll_anim_h/2)
end

function NewPlayerDungeonSummary:PrepareToAnimate()
	-- Start hidden until we unroll. Don't hide until after layout is complete.
	self.panel_contents:Hide()

	-- Snap to fully rolled position.
	self:_SetPaperRollAmount(1)
end

function NewPlayerDungeonSummary:_StopAnimation()
	if self.anim_updater then
		self.anim_updater:Stop()
		self.anim_updater = nil
	end
end

function NewPlayerDungeonSummary:AnimateInSummary()

	-- Show summary
	self.panel_contents:Show()
	self.summary_contents:Hide()
	self.rewards_contents:Show()

	-- Animation duration
	local scissor_duration = 0.45

	self:_StopAnimation()
	self.anim_updater = self:RunUpdater(Updater.Series{
		-- Scissor up
		Updater.Parallel{
			Updater.Do(function()
				-- Roll up sound
				self:PlaySpatialSound(fmodtable.Event.endOfRun_rollUp, nil, true)

				self.roll_anim:PlayAnimation("rollup")
					:PushAnimation("upidle", true)
			end),
			Updater.Ease(function(v)
				self:_SetPaperRollAmount(v)
			end, self.amount_to_unroll, 1, scissor_duration, easing.outQuad)
		},
		-- Scissor down
		Updater.Series{
			Updater.Parallel{
				Updater.Do(function()
					-- Show summary
					self.summary_contents:Show()
					self.rewards_contents:Hide()

					-- Unroll sound
					self:PlaySpatialSound(fmodtable.Event.endOfRun_rollDown, nil, true)

					-- Animate rolling
					self.roll_anim:PlayAnimation("rolldown")
						:PushAnimation("downidle", true)

				end),
				Updater.Ease(function(v)
					self:_SetPaperRollAmount(v)
				end, 1, 0, scissor_duration, easing.outQuad)
			},
			self:_CreateLootAnimator(),
			self:_CreateMasteryAnimator(),
		}
	})
end

function NewPlayerDungeonSummary:HideLoading()
	self.loading_indicator:Hide()
end

function NewPlayerDungeonSummary:AnimateInRewards()

	-- Show rewards
	self.panel_contents:Show()
	self.summary_contents:Hide()
	self.rewards_contents:Show()

	-- Animation duration
	local scissor_duration = 0.45

	self:_StopAnimation()
	self.anim_updater = self:RunUpdater(Updater.Series{
		-- Scissor down
		Updater.Parallel{
			Updater.Do(function()
				-- Unroll sound
				self:PlaySpatialSound(fmodtable.Event.endOfRun_rollDown, nil, true)

				-- Animate rolling
				self.roll_anim:PlayAnimation("rolldown")
					:PushAnimation("downidle", true)
			end),
			Updater.Ease(function(v)
				self:_SetPaperRollAmount(v)
			end, 1, self.amount_to_unroll, scissor_duration, easing.outQuad)
		},
		Updater.Do(function()
			-- Show progress
			self.dungeon_level:ShowMetaProgression(function(data)
				-- Called first, to move the widget up
				-- if data.move_up then
				-- 	self.dungeon_level:MoveTo(nil, self.level_container_end_y, 0.45, easing.outQuad)
				-- 	self.dungeon_level:SetBiomeTitle("")
				-- end

				-- -- Called next, for each reward earned
				-- if data.reward_earned then
				-- 	self.reward_container:Show():AddReward(data.reward_earned, data.level_num, true)
				-- end
			end)
		end),

	})
end

function NewPlayerDungeonSummary:AnimateOutDone()

	-- Show rewards
	self.loading_indicator:Hide()
	-- Animation duration
	local scissor_duration = 0.45

	self:_StopAnimation()
	self.anim_updater = self:RunUpdater(Updater.Series{
		-- Scissor up
		Updater.Parallel{
			Updater.Do(function()
				-- Roll up sound
				self:PlaySpatialSound(fmodtable.Event.endOfRun_rollUp, nil, true)

				self.roll_anim:PlayAnimation("rollup")
					:PushAnimation("upidle", true)
			end),
			Updater.Ease(function(v)
				self:_SetPaperRollAmount(v)
			end, 0, 1, scissor_duration, easing.outQuad),
		},
		Updater.Do(function()
			-- Ensure widgets are not interactable.
			self.panel_contents:Hide()
		end),
	})
end

function NewPlayerDungeonSummary:Layout()

	-- Position puppet
	self.puppet:LayoutBounds("left", "bottom", self.puppet_container)
		:Offset(65 * HACK_FOR_4K, -15 * HACK_FOR_4K)
	self.puppet_container:LayoutBounds("left", "top", self.bg)
		:Offset(-30 * HACK_FOR_4K, 40 * HACK_FOR_4K)
		:SendToFront()

	-- And username
	self.username:LayoutBounds("after", nil, self.puppet_container)
		:LayoutBounds(nil, "above", self.bg)
		:Offset(0, 21 * HACK_FOR_4K)

	self.player_title:LayoutBounds("left", "below", self.username)

	-- Layout equipment slots
	self.slot_weapon:LayoutBounds("left", "top", self.bg)
		:Offset(88 * HACK_FOR_4K, 1)
	if self.slot_tonic:HasItem() then
		-- If there's a tonic, nudge the potion a bit to make room
		self.slot_potion:LayoutBounds("after", "center", self.slot_weapon)
			:Offset(-20, 5)
		self.slot_tonic:Show()
			:LayoutBounds("right", "bottom", self.slot_potion)
			:Offset(5, -10)
	else
		self.slot_potion:LayoutBounds("after", "center", self.slot_weapon)
			:Offset(0, 0)
		self.slot_tonic:Hide()
	end
	self.slot_skill:LayoutBounds("after", "center", self.slot_weapon)
		:Offset(150, -10)
	self.slot_food:LayoutBounds("after", "center", self.slot_weapon)
		:Offset(280, -10)

	-- Layout powers grid
	local POWERS_HEIGHT = 300
	self.powers_title:LayoutBounds("center", "top", self.bg)
		:Offset(0, -100 * HACK_FOR_4K)

	--how much to scale powers based on how many rows there are
	local count_to_scale = 
	{
		[2] = 1.5,
		[3] = 1.1,
		[6] = 0.8,
		[14] = 0.55
	}

	--select the maximum scale you can
	local scale = 0.3
	for count, val in pairs(count_to_scale) do
		if count >= #self.powers_container.children then
			scale = math.max(val, scale)
		end
	end

	--force only one line of powers if 3 or less powers
	if #self.powers_container.children > 3 then
		self.powers_container:LayoutInDiagonal(5, 20, 10)
	else
		self.powers_container:LayoutChildrenInGrid(5, 20)
	end
	
	local power_bracket_size = (self.width / 4.5) * scale
	for _, power_icon in ipairs(self.powers_container.children) do
		power_icon:SetBracketSizeOverride(power_bracket_size, power_bracket_size)
	end

	self.powers_container
		:SetScale(scale)
		:LayoutBounds("center", "below", self.powers_title)
		:Offset(0, -20 * HACK_FOR_4K)

	self.empty_powers
		:LayoutBounds("center", "center", self.powers_container)
		:Offset(0, -100)

	-- Layout stats
	self.stats_title:LayoutBounds("center", "top", self.bg)
		:Offset(0 * HACK_FOR_4K, -POWERS_HEIGHT * HACK_FOR_4K)

	self.stats_column:LayoutChildrenInColumn(10 * HACK_FOR_4K, "left", 0, 0)
		:LayoutBounds("left", "center")
		:Offset(30 * HACK_FOR_4K, -5)

	self.stats_container:LayoutBounds("center", "below", self.stats_title)
		:Offset(0 * HACK_FOR_4K, -10 * HACK_FOR_4K)

	-- Layout reward
	self.reward_container
		:LayoutBounds("center", "below", self.level_container)
		:Offset(0, 150)
		:MoveToFront()


	-- Layout loot
	self.loot_title:LayoutBounds("center", "top", self.loot_container)
		:Offset(0, -60)


	local loot_count = #self.loot_widgets.children

	local num_columns = loot_count > 5 and 7 or 5
	local y_offset = loot_count > 5 and 0 or -15
	self.loot_widgets:LayoutChildrenInGrid(num_columns, 5 * HACK_FOR_4K)
		--:SetScale(Remap(#self.powers_container.children, 1, 11, 1.3, 0.85))
		:LayoutBounds("center", "below", self.loot_title)
		:Offset(0, y_offset * HACK_FOR_4K)


	self.loot_empty:SetMultColorAlpha(0)
		:LayoutBounds("center", "below", self.loot_title)
		:Offset(0, -60)

	self.masteries_title:LayoutBounds("center", "top", self.loot_container)
		:Offset(0, -160 * HACK_FOR_4K)

	local mastery_count = #self.mastery_widgets.children
	num_columns = mastery_count > 4 and 6 or 4
	y_offset = mastery_count > 4 and 0 or -15

	self.mastery_empty:SetMultColorAlpha(0)
		:LayoutBounds("center", "below", self.masteries_title)
		:Offset(0, -60)

	self.mastery_widgets:LayoutChildrenInGrid(num_columns, 5 * HACK_FOR_4K)
		--:SetScale(Remap(#self.powers_container.children, 1, 11, 1.3, 0.85))
		:LayoutBounds("center", "below", self.masteries_title)
		:Offset(0, y_offset * HACK_FOR_4K)

	self.loot_container:LayoutBounds("center", "bottom", self.bg)

	-- Position animated roll
	self.roll_anim:LayoutBounds(nil, "below", self.panel_contents)
		:Offset(-1 * HACK_FOR_4K, self.roll_anim_h/2)

	self.loading_indicator:SetScale(0.7)
		:LayoutBounds("center", "top", self.roll_anim)
		:Offset(0, -80)

	return self
end

function NewPlayerDungeonSummary:_CreateLootAnimator()
	local animation = Updater.Series()
	local children = self.loot_widgets:GetChildren()
	local TOTAL_LOOT_TIME = 1
	local ease_time = 0.1
	local widget_counts_per_rarity = {}

	if #children > 0 then
		local time_per_child = TOTAL_LOOT_TIME / #children

		for i, child in ipairs(children) do

			-- count # of items of a given rarity acquired in a session
			local rarity = child.itemdef.rarity
			if not widget_counts_per_rarity[rarity] then
				widget_counts_per_rarity[rarity] = 0
			end
			widget_counts_per_rarity[rarity] = widget_counts_per_rarity[rarity] + 1
			local current_count_of_given_rarity = widget_counts_per_rarity[rarity]

			child:SetMultColorAlpha(0)
			
			local end_pos_x, end_pos_y = child:GetPos()

			animation:Add(
				Updater.Series {
					Updater.Parallel{
						Updater.Do( function() 	
							child:PlaySpatialSound(fmodtable.Event.endOfRun_loot_widget_show, 
							{
								count_continuous = i
							}, true)
							child:PlaySpatialSound(child.itemdef:GetLootSound(),
								{
									count_continuous = current_count_of_given_rarity
								}, true)
							child:SetMultColorAlpha(1) 
						end),
						Updater.Ease(function(v) child:SetPos(end_pos_x, v) end, end_pos_y-10 * HACK_FOR_4K, end_pos_y, ease_time, easing.outQuad)
					},
					-- Updater.Wait(ease_time/2),
					-- Updater.Do((function(v)
					-- 	child:PlaySpatialSound(child.itemdef:GetLootSound(),
					-- 		{
					-- 			count_continuous = current_count_of_given_rarity
					-- 		}, true)
					-- end))
				})

			animation:Add(Updater.Wait(time_per_child-ease_time))
		end

		--then wait a little bit more
		animation:Add(Updater.Wait(0.5))

	else
		animation:Add(Updater.Wait(TOTAL_LOOT_TIME/2))
		local end_pos_x, end_pos_y = self.loot_empty:GetPos()

		animation:Add(
			Updater.Parallel{
				Updater.Do( function() 				
					self.loot_empty:SetMultColorAlpha(1)
				end),
				Updater.Ease(function(v) self.loot_empty:SetPos(end_pos_x, v) end, end_pos_y-10 * HACK_FOR_4K, end_pos_y, ease_time, easing.outQuad)
			})

		--always wait at least the total loot time
		animation:Add(Updater.Wait(TOTAL_LOOT_TIME/2-ease_time))
	end

	return animation
end


function NewPlayerDungeonSummary:_CreateMasteryAnimator()
	local animation = Updater.Series()

	for i, child in ipairs(self.mastery_widgets:GetChildren()) do
		child:SetMultColorAlpha(0)
		animation:Add(Updater.Wait(0.25))
		
		local end_pos_x, end_pos_y = child:GetPos()
		local def = child:GetDef()
		local delay_time = 0.1 -- to provide a 'beat' between meter showing and starting animation
		local ease_time = 0.35
		local progress_min = child:GetStartingProgress() / child:GetMaxProgress()
		local progress_max = child:GetCurrentProgress() / child:GetMaxProgress()
		local progress_delta = progress_max - progress_min
		local scatterer_spawn_rate = progress_delta

		if progress_min >= progress_max then
			delay_time = 0
			ease_time = 0
		end

		animation:Add(
			Updater.Series {
				Updater.Parallel {
					--draw widget
					Updater.Do(function()
						child:SetMultColorAlpha(1)
						-- play meter show sound
						child:PlaySpatialSound(fmodtable.Event.endOfRun_mastery_meter_show,
							{
								count_continuous = i
							}, true)
					end),
					Updater.Ease(function(v) child:SetPos(end_pos_x, v) end, end_pos_y - 10 * HACK_FOR_4K, end_pos_y, 0.1, easing.linear)
				},
				Updater.Wait(delay_time),
				Updater.Do(function()
					if progress_min < progress_max then
						--create looping XP sound
						child.meter_sound_LP = child:PlaySpatialSound(fmodtable.Event.endOfRun_mastery_XP_LP,
							{
								faction_player_id = self.player_id,
								faction = self.faction,
								progress = progress_min,
								spawnRate = scatterer_spawn_rate,
							}, true)
					end
				end),
				-- animate widget and update sound
				Updater.Ease(function(v)
					child:SetPercent(v)
					if child.meter_sound_LP then
						if v < progress_max then
							TheFrontEnd:GetSound():SetParameter(child.meter_sound_LP, "progress", v)
						else
							TheFrontEnd:GetSound():KillSound(child.meter_sound_LP)
							child.meter_sound_LP = nil
						end
					end
				end, progress_min, progress_max, ease_time, easing.linear),
				Updater.Do(function()
					if child.meter_sound_LP then
						TheFrontEnd:GetSound():KillSound(child.meter_sound_LP)
						child.meter_sound_LP = nil
					end
				end),
			})

		local is_completed = child:GetCurrentProgress() == child:GetMaxProgress() and child:GetStartingProgress() < child:GetMaxProgress()

		if is_completed then
			animation:Add(
				Updater.Parallel{
					Updater.Do( function() 		
						child:PlaySpatialSound(fmodtable.Event.endOfRun_mastery_levelUp,
							{
								faction_player_id = self.player_id,
								faction = self.faction,
							})
					end),
					Updater.Ease(function(v) child:SetPos(end_pos_x, v) end, end_pos_y+20 * HACK_FOR_4K, end_pos_y, 0.1, easing.outQuad)
				}
			)
		end
	end

	if self.mastery_widgets:IsEmpty() then
		local ease_time = 0.1
		local end_pos_x, end_pos_y = self.mastery_empty:GetPos()

		animation:Add(
			Updater.Parallel{
				Updater.Do( function() 				
					self.mastery_empty:SetMultColorAlpha(1)
				end),
				Updater.Ease(function(v) self.mastery_empty:SetPos(end_pos_x, v) end, end_pos_y-10 * HACK_FOR_4K, end_pos_y, ease_time, easing.outQuad)
			})

		-- Should we alsy wait at least the total mastery time?
	end
	return animation
end

function NewPlayerDungeonSummary:DebugDraw_AddSection(ui, panel)
	NewPlayerDungeonSummary._base.DebugDraw_AddSection(self, ui, panel)

	ui:Spacing()
	ui:Text("PlayerDungeonSummary")
	ui:Indent() do
		if ui:Button("AnimateInSummary") then
			self:AnimateInSummary()
		end
		if ui:Button("Unroll") then
			self:_SetPaperRollAmount(self.amount_to_unroll)
		end
	end
	ui:Unindent()
end

return NewPlayerDungeonSummary
