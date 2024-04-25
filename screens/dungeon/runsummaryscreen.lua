local Screen = require "widgets.screen"
local Widget = require "widgets.widget"
local PlayerDungeonSummary = require "widgets.ftf.newplayerdungeonsummary"
local HuntProgressWidget = require "widgets/ftf/accoladewidgets/huntprogresswidget"
local templates = require "widgets.ftf.templates"
local fmodtable = require "defs.sound.fmodtable"
local Equipment = require("defs.equipment")
local lume = require "util.lume"
local iterator = require "util.iterator"
local Consumable = require("defs.consumable")
local MetaProgress = require("defs.metaprogression")
local Mastery = require "defs.mastery.mastery"

local RunSummaryScreen =  Class(Screen, function(self, data)
	Screen._ctor(self, "RunSummaryScreen")

	-- Required to load the decoration icons for the reward tooltip
	TheSim:LoadPrefabs({ GroupPrefab("deps_ui_decor") })
	self.inst:ListenForEvent("onremove", function() TheSim:UnloadPrefabs({ GroupPrefab("deps_ui_decor") }) end)

	self:SetAudioCategory(Screen.AudioCategory.s.PartialOverlay)
	self:PushAudioParameterWhileOpen(fmodtable.GlobalParameter.g_isRunSummaryScreen)

	self.data = data
	self.is_defeat = data.defeat

	self.showing_summary = false

	-- STATES:
	-- "LOADING" : no data has been received yet, the page is not unfurled yet
	-- "REWARDS" : data has been received, first page is active
	-- "SUMMARY" : second page is active
	-- "DONE" 	 : player has pressed "done"

	self.current_panel_states = { nil, nil, nil, nil }
	self.requested_panel_states = { nil, nil, nil, nil }

    self.black = self:AddChild(templates.BackgroundTint())
		:SetMultColor(HexToRGB(0x211A1AFF))
		:SetMultColorAlpha(0.77)

    self.root = self:AddChild(Widget())

	self.progress_widget = self.root:AddChild(HuntProgressWidget())
		:LayoutBounds("center", "bottom", self)
		:Offset(0, -80)
		:Hide()

	self.continue_btn = self.root:AddChild(templates.Button(STRINGS.UI.HUD.CONTINUE))
		:SetSize(BUTTON_W * 1.1, BUTTON_H) -- fit "waiting for players"
		:SetOnClick(function() self:OnClickContinue() end)
		:SetScale(0.95)
		:SetNormalScale(0.95)
		:SetFocusScale(1)
		:Offset(0, 50 * HACK_FOR_4K)
		:Disable()

	self.player_panels_container = self.root:AddChild(Widget("Player Stats"))

	self.playerdungeonsummaries = {}

	self.players = TheNet:GetAllPlayers()
	for i, player in ipairs(self.players) do
		-- Grab all loot to show final resource stats instead of omitting ones
		-- on their way.
		player.components.lootvacuum:CollectAllLoot_Instant()
		local summary = self.player_panels_container:AddChild(PlayerDungeonSummary(player, self.data[player]))
			:SetMultColorAlpha(0)
		self.playerdungeonsummaries[player] = summary
		self.requested_panel_states[i] = "LOADING"
	end

	self._onplayerexited = function(_world, exitedplayer)
		for i,player in ipairs(self.players) do
			if player == exitedplayer then
				TheLog.ch.RunSummaryScreen:printf("Removing exited player %s GUID %d",
					self.players[i]:GetCustomUserName(), self.players[i].GUID)
				self:_ShowDone(i)
				table.remove(self.players, i)
				break
			end
		end
	end

	self.inst:ListenForEvent("playerexited", self._onplayerexited, TheWorld)


	self.player_panels_container:LayoutChildrenInGrid(4, 10)
	self.player_panels_container:LayoutBounds("center", "center", self)
		:Offset(-30, 60)
	self.continue_btn:LayoutBounds("center", "bottom", self):Offset(0, 25 * HACK_FOR_4K)

	-- HACK, this needs to be done this way because some UI elements begin animating (and making sound)
	-- before they are shown on screen. The below snapshot suppresses them
	--TheAudio:StartFMODSnapshot(fmodtable.Snapshot.Mute_EndOfRun_Meters)

	self.default_focus = self.continue_btn
end)

local templist = {}
function RunSummaryScreen:_ValidatePlayerList()
	table.clear(templist)

	for i,player in ipairs(self.players) do
		if not player:IsValid() then
			table.insert(templist, i)
			self:_ShowDone(i)
		end
	end

	for _i,playerindex in ipairs(templist) do
		TheLog.ch.RunSummaryScreen:printf("Removing stale player GUID %d", self.players[playerindex].GUID)
		table.remove(self.players, playerindex)
	end
end

function RunSummaryScreen:OnClickContinue()
	if not self.showing_summary then
		TheFrontEnd:GetSound():KillAutoStopSounds() -- kill lingering meter sounds from hunt progress or XP or masteries
		-- Advance to summary
		self.progress_widget:Hide()
		self.showing_summary = true
		self.continue_btn:Disable()
		self.continue_btn:SetText(STRINGS.UI.HUD.TO_TOWN)

		-- TODO: each panel should have a "continue" button ---- iterate through all local players, for now
		for i,player in ipairs(self.players) do
			if player:IsLocal() then
				self.requested_panel_states[i] = "SUMMARY"
			end
			
			if player:IsPickingCharacter() then
				self.requested_panel_states[i] = "DONE"
			end
		end
	else
		-- Summary was shown. Wait until all players are ready to continue
		if #AllPlayers > 1 then
			self.continue_btn:SetText(STRINGS.UI.HUD.WAITING_FOR_ALL_PLAYERS_NO_COUNT)
		end
		self.continue_btn:Disable()

		for i, player in ipairs(TheNet:GetLocalPlayerList()) do
			self.requested_panel_states[player+1] = "DONE" -- Player is the Player ID, which starts at 0
		end

		-- Use an updater that calls CloseScreen when all players are done
		self:RunUpdater(
			Updater.Series({
				Updater.Do(function() TheFrontEnd:GetSound():KillAutoStopSounds() end), -- kill remaining mastery meter sounds
				Updater.Wait(0.85),  -- Wait a bit to let the panels furl fully back up.
				Updater.Do(function() self:SendLocalPlayersDone() end),
				Updater.While(function() return not TheNet:AreAllPlayersDone() end),
				Updater.Do(function() self:CloseScreen() end)
			}))
	end
end

function RunSummaryScreen:SendLocalPlayersDone()
	-- Currently there is just one continue button for all local players.
	-- If this ever changes, each player can be individually marked as 'complete'
	for _, player in ipairs(TheNet:GetLocalPlayerList()) do
		TheNet:SetPlayerDone(player, 1)	-- 1 is just a value. Ignored.
	end
end

function RunSummaryScreen:CloseScreen()
	TheFrontEnd:PopScreen(self)
	TheWorld:PushEvent("run_summary_flow", false)
	TheWorld:PushEvent("end_run_sequence", not self.is_defeat)
end

function RunSummaryScreen:_ShowRequestedPage(playernumber)
	local requested_page = self.requested_panel_states[playernumber]

	if requested_page == "SUMMARY" then
		self:_ShowSummary(playernumber)
	elseif requested_page == "PROGRESS" then
		self:_ShowProgress(playernumber)
	elseif requested_page == "REWARDS" then
		self:_ShowRewards(playernumber)
	elseif requested_page == "LOADING" then
		self:_ShowLoading(playernumber)
	elseif requested_page == "DONE" then
		self:_ShowDone(playernumber)
	end
end

function RunSummaryScreen:_ShowLoading(playernumber)
	self.current_panel_states[playernumber] = "LOADING"

	local panel = self.player_panels_container.children[playernumber]
	panel:SetMultColorAlpha(1)
	panel:PrepareToAnimate()
end

function RunSummaryScreen:_ShowProgress(playernumber)
	self.current_panel_states[playernumber] = "PROGRESS"

	self:RunUpdater(Updater.Series{
		Updater.Do( function() 
			--no longer loading, but waiting for the progress to finish
			for i, player in ipairs(self.players) do
				local panel = self.player_panels_container.children[i]
				panel:HideLoading()
			end
			self.progress_widget:Show()
		end),
		Updater.While( function() 
			return self.progress_widget:IsAnimationComplete() == false 
		end ),
		Updater.Do( function() 
			for i,player in ipairs(self.players) do
				if player:IsLocal() then
					self.requested_panel_states[i] = "REWARDS"
				end
			end
		end)
	})
end

-- Sequentially show the panels switching to rewards
function RunSummaryScreen:_ShowRewards(playernumber)
	local sequence = Updater.Parallel()
	local delay_per_panel = 0.15
	local current_delay = 0

	self.current_panel_states[playernumber] = "REWARDS"

	local panel = self.player_panels_container.children[playernumber]
	sequence:Add(Updater.Series{
		Updater.Wait(current_delay),
		Updater.Do(function()
			panel:SetMultColorAlpha(1)
			panel:AnimateInRewards()
		end)
	})

	self:RunUpdater(Updater.Series{
		sequence,
		Updater.Wait(.5),
		Updater.Do(function()
			self.continue_btn:Enable()
		end)
	})
end

-- Sequentially show the panels's summaries
function RunSummaryScreen:_ShowSummary(playernumber)
	local sequence = Updater.Parallel()
	local delay_per_panel = 0.15
	local current_delay = 0

	self.current_panel_states[playernumber] = "SUMMARY"
	self.progress_widget:Hide()

	local panel = self.player_panels_container.children[playernumber]
	sequence:Add(Updater.Series{
		Updater.Wait(current_delay),
		Updater.Do(function()
			panel:AnimateInSummary()
		end)
	})

	-- TODO OLD: sequence them in with a delay. Getting working for networking now, bring back later if can
	-- for k,v in ipairs(self.player_panels_container.children) do
	-- 	sequence:Add(Updater.Series{
	-- 		Updater.Wait(current_delay),
	-- 		Updater.Do(function()
	-- 			v:AnimateInSummary()
	-- 		end)
	-- 	})
	-- 	current_delay = current_delay + delay_per_panel
	-- end

	self:RunUpdater(Updater.Series{
		sequence,
		Updater.Wait(.5),
		Updater.Do(function()
			self.continue_btn:Enable()
		end)
	})
end

function RunSummaryScreen:_ShowDone(playernumber)
	self.current_panel_states[playernumber] = "DONE"

	local panel = self.player_panels_container.children[playernumber]
	panel:AnimateOutDone()
end

function RunSummaryScreen:_CollectUIData(player, num)
	local display_data = {}
	local dungeon_data = player.components.dungeontracker
	local reward_data = self.data[player]

	---------- RefreshEquipment()  ----------
	display_data.equipment = {}
	self.selectedLoadoutIndex = player.components.inventoryhoard.data.selectedLoadoutIndex
	local equipped_weapon = player.components.inventoryhoard:GetLoadoutItem(self.selectedLoadoutIndex, Equipment.Slots.WEAPON)
	local equipped_potion = player.components.inventoryhoard:GetLoadoutItem(self.selectedLoadoutIndex, Equipment.Slots.POTIONS)
	local equipped_tonic = player.components.inventoryhoard:GetLoadoutItem(self.selectedLoadoutIndex, Equipment.Slots.TONICS)
	local equipped_food = player.components.inventoryhoard:GetLoadoutItem(self.selectedLoadoutIndex, Equipment.Slots.FOOD)

	if equipped_weapon then
		display_data.equipment.equipped_weapon = equipped_weapon.id
	end

	if equipped_potion then
		display_data.equipment.equipped_potion = equipped_potion.id
	end

	if equipped_tonic then
		display_data.equipment.equipped_tonic = equipped_tonic.id
	end

	if equipped_food then
		display_data.equipment.equipped_food = equipped_food.id
	end

	---------- RefreshPuppet() ----------
	-- Already synced, so we don't need to display over the network.
	-- display_data.puppet = {}
	-- display_data.puppet.character_data = player.components.charactercreator:SaveToTable()
	-- display_data.puppet.inventory_data = player.components.inventory:OnSave()

	---------- RefreshStats() ----------
	display_data.stats = {}

	-- Total Kills
	display_data.stats.total_kills = dungeon_data:GetValue("total_kills") or 0

	-- TODO: Kills by Mob

	-- Total Damage Dealt
	local total_damage_done = dungeon_data:GetValue("total_damage_done") or 0
	display_data.stats.total_damage_done = lume.round(total_damage_done)

	-- TODO: Damage dealt by Mob

	-- Damage Taken and Nemesis
	local nemesis = nil
	local best = 0

	for prefab, damage in pairs(dungeon_data:GetValue("damage_taken")) do
		if damage < best then -- damage amounts are negative
			nemesis = prefab
			best = damage
		end
	end

	display_data.stats.nemesis_damage = best
	display_data.stats.nemesis = nemesis
	display_data.stats.total_damage_taken = lume.round(math.abs(dungeon_data:GetValue("total_damage_taken") or 0))

	-- Deaths
	display_data.stats.total_deaths = dungeon_data:GetValue("total_deaths") or 0

	-- Run time
	local duration_millis = reward_data and reward_data.run_time or 0
	local show_hours = false
	display_data.stats.duration_millis = duration_millis
	display_data.stats.duration_show_hours = show_hours

	-- Run completion amount
	local rooms_discovered = reward_data and reward_data.rooms_discovered or 0
	display_data.stats.rooms_discovered = rooms_discovered


	---------- RefreshBuild() ----------
	-- PowerManager is already synched, other than 'mem' stuff - we don't need to prepare this separately.
	-- display_data.powers = player.components.powermanager:GetAllPowersInAcquiredOrder()

	---------- RefreshMetaProgress() ----------

	if reward_data then
		local def = MetaProgress.FindProgressByName(TheDungeon:GetDungeonMap().data.location_id)
		display_data.biome_exploration = {}

		local meta_reward = reward_data.biome_exploration.meta_reward
		display_data.biome_exploration.meta_level = meta_reward:GetLevel()
		display_data.biome_exploration.meta_exp = meta_reward:GetEXP()
		display_data.biome_exploration.meta_exp_max = MetaProgress.GetEXPForLevel(def, display_data.biome_exploration.meta_level)

		-- We no longer pass the reward over the network.
		-- Instead, we can tell if you leveled & what level you were, then get the reward from that.

		display_data.biome_exploration.meta_reward_log = reward_data.biome_exploration.meta_reward_log
	end

	---------- RefreshMasteries() ----------
	display_data.masteries = {}
	for name, tbl in pairs(dungeon_data:GetValue("mastery_progressed")) do
		table.insert(display_data.masteries, { name = name, starting_progress = tbl.starting_progress, current_progress = tbl.current_progress} )
	end

	---------- RefreshLoot() ----------
	display_data.loot = {}
	for name, count in iterator.sorted_pairs(dungeon_data:GetValue("loot"), Consumable.CompareId_ByRarityAndName) do
		if name ~= "konjur" then
			table.insert(display_data.loot, { name = name, count = count} )
		end
	end

	if reward_data and reward_data.bonus_loot then
		display_data.bonus_loot = {}
		for name, count in iterator.sorted_pairs(reward_data.bonus_loot, Consumable.CompareId_ByRarityAndName) do
			table.insert(display_data.bonus_loot, {name = name, count = count } )
		end
	end

	-- DYNAMIC DATA:
	-- Things that we expect to change, like the player's focused widget, mouse position, or what page they are viewing
	display_data.dynamic = {}

	-- What page are we viewing?
	local page = self.requested_panel_states[num]

	if page == "LOADING" then
		display_data.dynamic.requested_page = "PROGRESS"
	else
		display_data.dynamic.requested_page = page
	end

	return display_data
end

local ticks_til_receive_data = 0

function RunSummaryScreen:OnUpdate(dt)
	if not TheNet:IsInGame() then
		return
	end

	if self.waitingtostart then
		return
	end

	if self.exiting then
		return
	end

	if not self.waitingtostart and not self.exiting then
		self:_ValidatePlayerList()

		for i, player in ipairs(self.players) do

			local playerID = player.Network:GetPlayerID()

			-- If this is a remote player, get the UI data from the network.
			-- If it is a local player, gather the UI data from the player and UI state, and send it out to the network

			local display_data = {} -- Send an empty table in case of error, and make sure that the summarywidget can handle nil data
			local islocal = player:IsLocal()
			local is_picking_character = player:IsPickingCharacter()
			if player:IsLocal() then
				display_data = self:_CollectUIData(player, i)
				TheNet:SetPlayerUIData(playerID, display_data)
			else
				display_data = TheNet:GetPlayerUIData(playerID)
			end

			ticks_til_receive_data = ticks_til_receive_data - 1
			if ticks_til_receive_data > 0 then
				display_data = nil
			end

			-- If we haven't yet received valid display data, stay in the loading phase.
			if display_data then
				self.requested_panel_states[i] = display_data.dynamic.requested_page
			else
				self.requested_panel_states[i] = "LOADING"
			end

			if is_picking_character and self.requested_panel_states[i] ~= "DONE" then
				self.requested_panel_states[i] = "DONE"
				--self.continue_btn:Hide()
				TheNet:SetPlayerDone(playerID, 1)
			end
			
			local showing_correct_page = self.requested_panel_states[i] == self.current_panel_states[i]
			if not showing_correct_page then
				self:_ShowRequestedPage(i)
			end

			local summarywidget = self.playerdungeonsummaries[player]
			summarywidget:RefreshPuppet()
			summarywidget:ApplyDataToScreen(display_data)
		end

		-- If the game mode changes back to game, exit this screen
		-- local mode = TheNet:GetCurrentGameMode()
		-- if mode ~= GAMEMODE_GAMEOVER or mode ~= GAMEMODE_VICTORY or mode ~= GAMEMODE_ABANDON then	-- If the game mode was changed by the host, exit this screen immediately:
		-- 	self:Exit()
		-- end
	end
end

function RunSummaryScreen:Exit()
	if not self.exiting then	-- self:StopUpdating() somehow doesn't stops OnUpdate from being called (?!)
		self.exiting = true
		self:StopUpdating()
	end
end

function RunSummaryScreen:OnOpen()
	self._base.OnOpen(self)
	TheWorld:PushEvent("run_summary_flow", true)

	self:AnimateIn()
	TheDungeon.HUD:AnimateOut()
end

function RunSummaryScreen:OnClose()
	self._base.OnClose(self)
	if TheDungeon.HUD then
		-- Debug Flow: If you cheat health on this screen, restore previous state.
		TheDungeon.HUD:AnimateIn()
	end
end

function RunSummaryScreen:AnimateIn()
	self.player_panels_container:Hide()
	self.waitingtostart = true

	for i, player in ipairs(self.players) do
		local panel = self.player_panels_container.children[i]
		panel:SetMultColorAlpha(1)
		panel:PrepareToAnimate()
	end

	-- Delay a second so players can see their death.
	self:RunUpdater(Updater.Series{
		Updater.Wait(0.66),
		Updater.Do(function()
			self.player_panels_container:Show()

			self.waitingtostart = false

			-- Restore focus we lost from hiding.
			self:SetDefaultFocus()
			self:EnableFocusBracketsForGamepad()

			self:StartUpdating()
		end)
	})
	return self
end

local fake_data = {
	{
		loot_prefabs = {
			"drop_cabbageroll_skin",
			"drop_cabbageroll_skin",
			"drop_blarmadillo_hide",
			"drop_blarmadillo_hide",
			"drop_treemon_arm",
			"drop_zucco_skin",
		},		

		masteries = 
		{
			{ "hammer_air_spin", 2 },
			{ "hammer_counterattack", 10 },
			{ "hammer_heavy_slam", 5 },
		}
	},
	{
		loot_prefabs = {
			"drop_treemon_arm",
			"drop_zucco_skin",
		},		
		masteries = 
		{
			{ "hammer_air_spin", 20 },
			{ "hammer_counterattack", 2 },
			{ "hammer_heavy_slam", 5 }
		}
	},
	{
		loot_prefabs = {
			"drop_cabbageroll_skin",
			"drop_cabbageroll_skin",
			"drop_blarmadillo_hide",
			"drop_blarmadillo_hide",
			"drop_treemon_arm",
			"drop_zucco_skin",
		},		
	},
	{
		masteries = 
		{
			{ "hammer_air_spin", 20 },
			{ "hammer_heavy_slam", 5 }
		}
	}
}

local function _FakeRunData(player, player_num)
	local data = fake_data[player_num]

	for i, loot in ipairs(data.loot_prefabs or {}) do
		local ent = c_spawn(loot)
		player.components.lootvacuum:CollectLoot(ent)
	end

	for i, v in ipairs(data.masteries or {}) do 
		local mastery_inst = player.components.masterymanager:GetMastery(Mastery.Items.WEAPON_MASTERY[v[1]])
		if mastery_inst == nil then
			player.components.masterymanager:AddMasteryByDef(Mastery.Items.WEAPON_MASTERY[v[1]])
			mastery_inst = player.components.masterymanager:GetMastery(Mastery.Items.WEAPON_MASTERY[v[1]])
		end
		mastery_inst:DeltaProgress(v[2])
	end

	local powers = {
		"pwr_sting_like_a_bee",
		"pwr_advantage",
		"pwr_salted_wounds",
		"pwr_heal_on_crit",
		"pwr_crit_knockdown",
		"pwr_konjur_on_crit",
		"pwr_sanguine_power",
		"pwr_feedback_loop",
		"pwr_lasting_power",
		"pwr_optimism",
		"pwr_streaking",
	}

	for i, power in ipairs(powers) do
		c_power(power)
	end
end

local function _FakeRunDataForAudio(player, player_num)
	player.components.masterymanager:DEBUG_ResetMasteries()
	local data = fake_data[player_num]

	for i, loot in ipairs(data.loot_prefabs or {}) do
		local ent = c_spawn(loot)
		player.components.lootvacuum:CollectLoot(ent)
	end

	for i, v in ipairs(data.masteries or {}) do
		local mastery_inst = player.components.masterymanager:GetMastery(Mastery.Items.WEAPON_MASTERY[v[1]])
		if mastery_inst == nil then
			player.components.masterymanager:AddMasteryByDef(Mastery.Items.WEAPON_MASTERY[v[1]])
			mastery_inst = player.components.masterymanager:GetMastery(Mastery.Items.WEAPON_MASTERY[v[1]])
		end
		mastery_inst:DeltaProgress(math.random(1, 100))
	end

	local powers = {
		"pwr_sting_like_a_bee",
		"pwr_advantage",
		"pwr_salted_wounds",
		"pwr_heal_on_crit",
		"pwr_crit_knockdown",
		"pwr_konjur_on_crit",
		"pwr_sanguine_power",
		"pwr_feedback_loop",
		"pwr_lasting_power",
		"pwr_optimism",
		"pwr_streaking",
	}

	for i, power in ipairs(powers) do
		c_power(power)
	end
end

function RunSummaryScreen.DebugConstructScreen(cls, player)
	local i = 1
	for _,player in ipairs(TheNet:GetAllPlayers()) do
		if player:IsLocal() then
			_FakeRunData(player, i)
			i = i + 1
		end
	end
	local run_data = TheDungeon.progression.components.runmanager:ApplyRunData(1)
	return RunSummaryScreen(run_data)
end

return RunSummaryScreen
