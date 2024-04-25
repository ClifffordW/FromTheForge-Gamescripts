local ConfirmDialog = require "screens.dialogs.confirmdialog"
local ControlsWidget = require "widgets.ftf.controlswidget"
local DungeonHistoryMap = require "widgets.ftf.dungeonhistorymap"
local DungeonLayoutMap = require "widgets.ftf.dungeonlayoutmap"
local EditableEditor = require "debug.inspectors.editableeditor"
local Enum = require "util.enum"
local OptionsScreen = require "screens.optionsscreen"
local PlayersScreen = require "screens.playersscreen"
local RoomLoader = require "roomloader"
local Screen = require "widgets.screen"
local Text = require "widgets.text"
local easing = require "util.easing"
local fmodtable = require "defs.sound.fmodtable"
local templates = require "widgets.ftf.templates"
local DiscordSharingSetting = require ("widgets/ftf/discordsharingsetting")


local PauseScreen = Class(Screen, function(self, player)
	Screen._ctor(self, "PauseScreen")
	self:SetAudioEnterOverride(fmodtable.Event.ui_pauseScreen_enter)
		:SetAudioExitOverride(fmodtable.Event.ui_pauseScreen_exit)
		:SetAudioCategory(Screen.AudioCategory.s.Fullscreen)

	self.active = true
	SetGameplayPause(true, "PauseScreen")

	-- Get location data
	self.inTown = TheWorld:HasTag("town")
	self.worldmap = TheDungeon:GetDungeonMap()

	-- Add background
	self.bg = self:AddChild(templates.BackgroundImage("images/ui_ftf_pausescreen/background_gradient.tex"))

	if TheNet:IsGameTypeLocal() then
		self.bg.full_alpha = 1
	else
		-- Cannot pause in a non-local network game, so don't tint background
		-- so hard.
		self.bg.full_alpha = 0.4
	end

	-- Back button
	self.closeButton = self:AddChild(templates.BackButton())
		:SetPrimary()
		:SetOnClick(function() self:Unpause() end)
		:LayoutBounds("left", "bottom", self.bg)
		:Offset(30, 20)

	-- Manage Multiplayer button
	self.manageMPButton = self:AddChild(templates.Button(STRINGS.UI.PAUSEMENU.MANAGE_MP_BUTTON))
		:SetFlipped()
		:SetOnClick(function() self:OnClickManageMP() end)
		:LayoutBounds("after", "center", self.closeButton)
		:Offset(20, 0)



	if EditableEditor.HasUnsavedChanges() then
		self.debugSaveButton = self:AddChild(templates.Button("<p img='images/icons_ftf/inventory_wrap.tex' color=0> Save editor changes"))
			:SetDebug()
			:SetSize(BUTTON_W * 1.2, BUTTON_H)
			:SetOnClick(function()
				TheWorld.components.propmanager:SaveAllProps()
				self:Unpause()
			end)
			:LayoutBounds("right", "above", self.closeButton)
			:Offset(0, -10)
	end

	-- Options button
	self.optionsButton = self:AddChild(templates.Button(STRINGS.UI.PAUSEMENU.OPTIONS_BUTTON))
		:SetSecondary()
		:SetOnClick(function() self:OnClickOptions() end)
		:LayoutBounds("right", "bottom", self.bg)
		:Offset(-30, 20)

	-- TODO: Align with map?
	self.controls = self:AddChild(ControlsWidget(player))
		:LayoutBounds("right", "above", self.optionsButton)
		:Offset(-10, 140)

	self.quit_button = self:AddChild(templates.Button(STRINGS.UI.PAUSEMENU.SAVEQUIT_BUTTON))
		:SetSecondary()
		:SetFlipped()
		:SetOnClick(function() self:OnClickQuit() end)
		:LayoutBounds("before", "center", self.optionsButton)
		:Offset(-20, 0)
	if not self.inTown then
		self.quit_button:SetText(STRINGS.UI.PAUSEMENU.ABANDON_BUTTON)
	end

	self.imStuckButton = self:AddChild(templates.Button(STRINGS.UI.PAUSEMENU.IMSTUCK_BUTTON))
		:SetSecondary()
		:SetOnClick(function() self:OnClickImStuck() end)
		:LayoutBounds("before", "center", self.quit_button)
		:Offset(-20, 0)
		:SetPublicFacingDebug()

	if not TheNet:IsHost() then
		self.imStuckButton:SetEnabled(false)
			:SetToolTip(STRINGS.UI.PAUSEMENU.IMSTUCK.NON_HOST)
	end

	self:UpdateJoinCodeAndDiscordButtons()
			
	-- Map widget is only in dungeons
	if not self.inTown then
		self.map = self:AddChild(DungeonHistoryMap(self.worldmap.nav))
			:SetOnMapChangedFn(function() self:OnMapChanged() end)
			:DrawFullMap()
			:LayoutBounds("left", "above", self.closeButton)
			:Offset(0, 80)


		self.layout_btn = self.map.buttons:AddChild(templates.Button("Show Dungeon Layout"))
			:SetDebug()
			:SetOnClick(function()
				self.controls:Hide() -- more space for layout
				self.map:Hide()
				self.dungeon_layout = self:AddChild(DungeonLayoutMap(self.worldmap.nav))
					:Debug_SetupEditor(self)
					:SetOnMapChangedFn(function() self:OnMapChanged() end)
					:DrawFullMap()
				self:OnMapChanged()
			end)

		self.map.buttons:LayoutChildrenInGrid(1, 10)
		self.map.buttons:Reparent(self)
			:SetScale(0.6, 0.6)
			:LayoutBounds("right", "top", self.bg)
			:Offset(-30, -30)

		self:OnMapChanged()
	end

	self.default_focus = self.closeButton
	self:SetOwningPlayer(player)
end)

function PauseScreen:UpdateJoinCodeAndDiscordButtons()
	print("PauseScreen:UpdateJoinCodeAndDiscordButtons()")
	if self.online_joincode_button then
		self.online_joincode_button:Remove()
		self.online_joincode_button = nil
	end


	local joincode = GetNetworkJoinCode()
	print("joincode = "..joincode)
	if joincode ~= "" then
		self.online_joincode_button = self:AddChild(templates.Button(STRINGS.UI.ONLINESCREEN.JOINCODE_LABEL:subfmt({ joincode = joincode })))
			:SetToolTip(STRINGS.UI.ONLINESCREEN.JOINCODE_LABEL_TOOLTIP)
			:SetUncolored()
			:SetFlipped()
			:SetTextSize(FONTSIZE.OVERLAY_TEXT)
			:OverrideLineHeight(FONTSIZE.OVERLAY_TEXT * 0.8)
			:SetOnClick(function() self:OnClickOnlineJoinCode() end)
			:LayoutBounds("left", "top", self.bg)
			:Offset(20,-20)


		self.online_joincode_button.on_streamer_mode_changed = function()
			local newstr = STRINGS.UI.ONLINESCREEN.JOINCODE_LABEL:subfmt({ joincode = GetNetworkJoinCode() })
			self.online_joincode_button:SetText(newstr);
		end

		self.online_joincode_button.inst:ListenForEvent("ui_streamer_mode_changed", self.online_joincode_button.on_streamer_mode_changed, TheGlobalInstance)
	end

	-- Discord settings:
	if self.discord_sharing_setting then
		self.discord_sharing_setting:Remove()
		self.discord_sharing_setting = nil
	end

	self.discord_sharing_setting = self:AddChild(DiscordSharingSetting())

	if self.online_joincode_button then 
		self.discord_sharing_setting:LayoutBounds("after", "top", self.online_joincode_button):Offset(20,-60)
	else 
		self.discord_sharing_setting:LayoutBounds("left", "top", self.bg):Offset(20,-70)
	end
end


function PauseScreen:SetOwningPlayer(player)
	PauseScreen._base.SetOwningPlayer(self, player)
	self.controls:SetOwningPlayer(player)
	return self
end

function PauseScreen:OnMapChanged()
	-- Layout map again
	local pad = 300
	if self.dungeon_layout then
		local scale_to_fit = true
		self.dungeon_layout:LayoutMap(self.bg, RES_X - pad, RES_Y - pad, scale_to_fit)
			:LayoutBounds("left", "center", self.bg)
			:Offset(pad, 0)
	end

	return self
end

-- Only really specific special cases should call this (player join, feedback).
function PauseScreen:ForceUnpauseTime()
	TheLog.ch.FrontEnd:printf("Called PauseScreen:ForceUnpauseTime")
	return self:_UnpauseTime()
end

function PauseScreen:_UnpauseTime()
	self.active = false
	SetGameplayPause(false, "PauseScreen")
end

function PauseScreen:Unpause()
	TheFrontEnd:PopScreen(self)
end

function PauseScreen:OnOpen()
	PauseScreen._base.OnOpen(self)

	self:UpdateJoinCodeAndDiscordButtons()
end


function PauseScreen:OnClose()
	PauseScreen._base.OnClose(self)

	-- TODO: someone, force player to travel if leaving screen and debug travel was used
	-- if self.map and (self.map:Debug_TravelUsed() or self.dungeon_layout:Debug_TravelUsed()) then
	-- end
	self:_UnpauseTime()
	TheDungeon.HUD:Show()
	TheWorld:PushEvent("continuefrompause")
end

--[[
function PauseScreen:goafk()
	self:Unpause()

	local player = self:GetOwningPlayer()
	if player and player.components.combat and player.components.combat:IsInDanger() then
		--it's too dangerous to afk
		player.components.talker:Say(GetString(player, "ANNOUNCE_NODANGERAFK"))
		return
	end
end
]]

function PauseScreen:OnClickReturnToTown()
	-- Allow load tasks can update.
	self:_UnpauseTime()

	if EditableEditor.HasUnsavedChanges() then
		self:OnClickDebugSave()
	else
		TheDungeon.progression.components.runmanager:Abandon()
	end
	return self
end

function PauseScreen:OnClickOptions()
	TheFrontEnd:PushScreen(OptionsScreen(self:GetOwningPlayer()))
	TheDungeon.HUD:Show()
	--Ensure last_focus is the options button since mouse can
	--unfocus this button during the screen change, resulting
	--in controllers having no focus when toggled on from the
	--options screen
	self.last_focus = self.optionsButton
	return self
end

function PauseScreen:OnClickImStuck()
	TheLog.ch.FrontEnd:printf("'I'm Stuck' clicked")

	local confirm_popup
	confirm_popup = ConfirmDialog(self:GetOwningPlayer(), nil, true)
		:SetTitle(STRINGS.UI.PAUSEMENU.IMSTUCK.TITLE)
		:SetText(STRINGS.UI.PAUSEMENU.IMSTUCK.BODY)
		:HideArrow()
		:SetYesButton(STRINGS.UI.PAUSEMENU.IMSTUCK.SEND_FEEDBACK, function()
			TheNet:HostRequestFeedbackForAllClients()
			-- Unpause to remove PauseScreen and hide confirm so it's not in
			-- the screenshot. Feedback messes with pause state regardless, so
			-- we won't stay properly paused.
			self:Unpause()
			confirm_popup:Hide()
			self.inst:DoTaskInTicks(2, function()
				confirm_popup:Show()
			end)
			-- hide the feedback button so it's clear that they should now reset.
			confirm_popup:HideYesButton()
		end)
		:SetNoButton(STRINGS.UI.PAUSEMENU.IMSTUCK.RESTART_ROOM, c_reset)
		:SetCancelButton(STRINGS.UI.PAUSEMENU.IMSTUCK.CANCEL, function()
			TheFrontEnd:PopScreen(confirm_popup)
		end)
		:CenterButtons()

	TheFrontEnd:PushScreen(confirm_popup)

	self.last_focus = self.imStuckButton
	return self
end

function PauseScreen:OnClickManageMP()
	TheFrontEnd:PushScreen(PlayersScreen())
	self.last_focus = self.manageMPButton
	return self
end


function PauseScreen:OnClickDebugSave()
	local town = "home_forest"
	local popup = ConfirmDialog(self:GetOwningPlayer())
		:SetTitle("Unsaved editor changes!")
		:SetText("You have unsaved changes to this level. Some props were modified.")
		:HideArrow()
		:SetYesButton("Save", function()
			TheWorld.components.propmanager:SaveAllProps()
			RoomLoader.LoadTownLevel(town)
			TheFrontEnd:PopScreen()
		end)
		:SetNoButton("Discard", function()
			RoomLoader.LoadTownLevel(town)
			TheFrontEnd:PopScreen()
		end)
		:SetCancelButton(STRINGS.UI.BUTTONS.CANCEL, function()
			TheFrontEnd:PopScreen()
		end)
	TheFrontEnd:PushScreen(popup)
	return self
end


function PauseScreen:OnClickQuit()
	self.active = false

	local function actualquit()
		self.parent:Disable()
		RestartToMainMenu("save")
	end

	local function doquit()
		-- You can listen to quit_to_menu to write to TheSaveSystem and we'll
		-- save it all before we quit.
		TheWorld:PushEvent("quit_to_menu")
		c_save(actualquit)
	end


	local dialog = nil

	local Actions = Enum{
		"Yes_Abandon",
		"No_QuitToMenu",
		"Cancel",
	}

	if TheNet:IsHost() and not TheNet:IsGameTypeLocal() then
		dialog = ConfirmDialog(self:GetOwningPlayer(), self.quit_button, true,
			STRINGS.UI.PAUSEMENU.HOSTQUITTITLE,
			STRINGS.UI.PAUSEMENU.HOSTQUITSUBTITLE)
		dialog:SetYesTooltip(STRINGS.UI.PAUSEMENU.HOSTQUIT_TOOLTIP)
	else
		-- Only if there are actually multiple players.
		local subtitle = #AllPlayers > 1 and STRINGS.UI.PAUSEMENU.CLIENTQUITBODY_MP or nil
		if TheWorld:HasTag("town") then
			dialog = ConfirmDialog(self:GetOwningPlayer(), self.quit_button, true,
				STRINGS.UI.PAUSEMENU.CLIENTQUITTITLE_TOWN,
				subtitle,
				STRINGS.UI.PAUSEMENU.CLIENTQUITSUBTITLE_TOWN)
		else
			dialog = ConfirmDialog(self:GetOwningPlayer(), self.quit_button, true,
				STRINGS.UI.PAUSEMENU.CLIENTQUITTITLE_DUNGEON,
				subtitle,
				STRINGS.UI.PAUSEMENU.CLIENTQUITSUBTITLE_DUNGEON)
		end
	end

	dialog
		:SetWideButtons()

	if TheWorld:HasTag("town") then
		dialog
			:SetYesButtonText(STRINGS.UI.PAUSEMENU.QUIT_BUTTON)
			:SetNoButton(STRINGS.UI.PAUSEMENU.CANCEL_QUIT)
			:SetCallbackActionLabels(Actions.s.No_QuitToMenu, Actions.s.Cancel)
	else
		dialog
			:SetText(STRINGS.UI.PAUSEMENU.CLIENTQUITSUBTITLE_DUNGEON)
			:SetYesTooltip(STRINGS.UI.PAUSEMENU.HOSTRETURNTOTOWN_TOOLTIP)
			:SetYesButtonText(STRINGS.UI.PAUSEMENU.RETURN_TO_TOWN_BUTTON)
			:SetNoButton(STRINGS.UI.PAUSEMENU.QUIT_BUTTON)
			-- :SetCancelButtonText(STRINGS.UI.PAUSEMENU.CANCEL_QUIT)
			:SetCloseButton(function() dialog:Close() end)
			:SetCallbackActionLabels(Actions.s.Yes_Abandon, Actions.s.No_QuitToMenu, Actions.s.Cancel)

			local can_abandon = TheDungeon.progression.components.runmanager:CanAbandonRun()
			if not can_abandon then
				dialog.yesButton:SetEnabled(false)
					:SetToolTip(STRINGS.UI.PAUSEMENU.NO_ABANDON_QUEST)
			end

		if not TheNet:IsHost() then
			dialog.yesButton:SetEnabled(false)
				:SetToolTip(STRINGS.UI.PAUSEMENU.NO_ABANDON_CLIENT)
		end
	end

	-- Set the dialog's callback
	dialog:SetOnDoneFn(
		function(action)
			assert(Actions:Contains(action))
			if action == Actions.s.Yes_Abandon then
				self:OnClickReturnToTown()
			elseif action == Actions.s.No_QuitToMenu then
				--TheLog.ch.Audio:print("***///***pausescreen.lua: Stopping all music.")
				TheWorld.components.ambientaudio:StopAllMusic()
				TheWorld.components.ambientaudio:StopAmbient()
				--TheFrontEnd:GetSound():PlaySound(fmodtable.Event.ui_input_up_confirm_save)
				doquit()
			else
				TheFrontEnd:PopScreen(dialog)
			end
		end)
	dialog:SetOwningPlayer(self:GetOwningPlayer())

	-- Show the popup
	TheFrontEnd:PushScreen(dialog)

	-- And animate it in!
	dialog:AnimateIn()
end

function PauseScreen:OnClickOnlineJoinCode()
	local success = TheNet:CopyJoinCodeToClipboard()
	if success then
		if self.online_joincode_button and not self.online_joincode_copied then
			self.online_joincode_button:Disable()
			local offx, offy = self.online_joincode_button:GetSize()
			self.online_joincode_copied = self:AddChild(Text(FONTFACE.BODYTEXT, FONTSIZE.OVERLAY_TEXT))
				:SetText(STRINGS.UI.PAUSEMENU.JOINCODE_COPIED)
				:LayoutBounds("center", "below", self.online_joincode_button)

			local fadeStatus = Updater.Series({
				Updater.Wait(2.0),
				Updater.Ease(function(v) self.online_joincode_copied:SetMultColorAlpha(v) end, 1, 0, 0.5, easing.inOutQuad),
				Updater.Do(function()
					self.online_joincode_copied:Remove()
					self.online_joincode_copied = nil
					self.online_joincode_button:Enable()
				end)
			})

			self:RunUpdater(fadeStatus)
		end
	end
end

PauseScreen.CONTROL_MAP =
{
	{
		control = Controls.Digital.SHOW_PLAYERS_LIST,
		fn = function(self)
			self:OnClickManageMP()
			return true
		end,
	},
}

function PauseScreen:OnControl(controls, down, ...)
	if PauseScreen._base.OnControl(self,controls, down, ...) then
		return true
	elseif not down and (controls:Has(Controls.Digital.PAUSE, Controls.Digital.CANCEL)) then
		self:Unpause()
		return true
	end
end

function PauseScreen:OnUpdate(dt)
	if self.active then
		SetGameplayPause(true, "PauseScreen")
	end
end

function PauseScreen:OnBecomeActive()
	PauseScreen._base.OnBecomeActive(self)

	-- Hide the topfade, it'll obscure the pause menu if paused during fade. Fade-out will re-enable it
	TheFrontEnd:HideTopFade()

	-- User may have been in options to rebind.
	self.controls:RefreshIcons()

	if not self.animatedIn then
		self:AnimateIn()
		self.animatedIn = true
	end
end

function PauseScreen:AnimateIn()

	-- Hide elements
	self.bg:SetMultColorAlpha(0)

	-- Get default positions
	local bgX, bgY = self.bg:GetPosition()

	local map_updater
	if self.map then
		local mapX, mapY = self.map:GetPosition()
		self.map:SetMultColorAlpha(0)
		-- And the map
		map_updater = Updater.Series({
				Updater.Wait(0.1),
				Updater.Parallel({
						Updater.Ease(function(v) self.map:SetMultColorAlpha(v) end, 0, 1, 0.1, easing.outQuad),
						Updater.Ease(function(v) self.map:SetPosition(mapX, v) end, mapY + 10, mapY, 0.4, easing.outQuad),
					}),
			})
	end

	local function AnimateButtonFromLeft_Sequence(btn)
		local btn_x, btn_y = btn:GetPosition()
		btn:SetMultColorAlpha(0)
		return {
			Updater.Wait(0.4),
			Updater.Parallel({
					Updater.Ease(function(v) btn:SetMultColorAlpha(v) end, 0, 1, 0.1, easing.inOutQuad),
					Updater.Ease(function(v) btn:SetPosition(v, btn_y) end, btn_x - 40, btn_x, 0.2, easing.inOutQuad),
				})
		}
	end

	-- Start animating
	local animateSequence = Updater.Parallel({

		Updater.Do(function()
			TheDungeon.HUD:Hide()
		end),

		-- Animate map background
		Updater.Series({
			-- Updater.Wait(0.15),
			Updater.Parallel({
				Updater.Ease(function(v) self.bg:SetMultColorAlpha(v) end, 0, self.bg.full_alpha, 0.5, easing.outQuad),
				Updater.Ease(function(v) self.bg:SetScale(v) end, 1.1, 1, 0.3, easing.outQuad),
				Updater.Ease(function(v) self.bg:SetPosition(bgX, v) end, bgY + 10, bgY, 0.3, easing.outQuad),
			}),
		}),

		Updater.Series({
			Updater.Series(AnimateButtonFromLeft_Sequence(self.closeButton)),
			Updater.Do(function()
				self:EnableFocusBracketsForGamepad()
			end),
		}),
		Updater.Series(AnimateButtonFromLeft_Sequence(self.manageMPButton)),

		map_updater, -- these are parallel and this might be nil, so keep it last.
	})

	-- Animate the other buttons too
	local function AnimateButtonFromRight(btn)
		btn:SetMultColorAlpha(0)
		local btn_x, btn_y = btn:GetPosition()
		animateSequence:Add(Updater.Series({
					Updater.Wait(0.4),
					Updater.Parallel({
							Updater.Ease(function(v) btn:SetMultColorAlpha(v) end, 0, 1, 0.1, easing.inOutQuad),
							Updater.Ease(function(v) btn:SetPosition(v, btn_y) end, btn_x + 40, btn_x, 0.2, easing.inOutQuad),
						}),
			}))
	end

	AnimateButtonFromRight(self.optionsButton)
	AnimateButtonFromRight(self.quit_button)
	AnimateButtonFromRight(self.imStuckButton)

	self:RunUpdater(animateSequence)
end

return PauseScreen
