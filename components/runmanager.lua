local Consumable = require"defs.consumable"
local MetaProgress = require"defs.metaprogression"
local krandom = require "util.krandom"
local playerutil = require "util.playerutil"

local STATE_TO_SPAWNER_ID =
{
	[RunStates.s.ACTIVE] = "new_player", -- the only way this should be possible is if it's a completely fresh save
	[RunStates.s.VICTORY] = "victory",
	[RunStates.s.DEFEAT] = "defeat",
	[RunStates.s.ABANDON] = "defeat",
}

local function CalculateBiomeExplorationReward(progress, victory)
	local base_exp = math.floor(progress * TUNING.BIOME_EXPLORATION.BASE)

	local miniboss_progress = TheDungeon:GetDungeonMap().nav:GetProgressForFirstMinibossEncounter()

	if progress > miniboss_progress then
		base_exp = base_exp + TUNING.BIOME_EXPLORATION.MINIBOSS
	end

	if victory then
		base_exp = base_exp + TUNING.BIOME_EXPLORATION.BOSS
	end

	local frenzy = TheDungeon.progression.components.ascensionmanager:GetCurrentLevel()

	local frenzy_modifier = 1 + (frenzy * TUNING.BIOME_EXPLORATION.FRENZY_LEVEL_MODIFIER)
	base_exp = math.ceil(base_exp * frenzy_modifier)

	return base_exp
end

local function CalculateKonjurShardReward(progress)
	-- guaranteed shards at 33, 66 and 100% progress.

	-- any 'left over' chance is rolled against a math.random() as a chance to get a bonus shard

	local shard_chance = progress * 2.5

	local shards_to_drop = math.floor(shard_chance)

	local got_bonus = math.random() < (shard_chance - shards_to_drop)

	if got_bonus then
		shards_to_drop = shards_to_drop + 1
	end

	return shards_to_drop
end

------------------------------------------------

local RunManager = Class(function(self, inst)
	self.inst = inst

	self.can_abandon = true

	self.run_state = RunStates.s.ACTIVE -- this is town-wide right now. Could maybe be made to be player specific?
	self.run_time = 0
	self.rooms_discovered = 0
	self.met_npc = false

	self.deadplayers = {}

	self._onstartrun = function() self:ResetData() end
	self.inst:ListenForEvent("start_new_run", self._onstartrun, TheDungeon)

	self._ondungeoncleared = function()
		-- delay to pace out appearance of victory button but
		-- also need to wait for player done message from last client when receiving a soul drop
		self.inst:DoTaskInTime(2, function()
			self:Victory()
		end)
	end

	self.inst:ListenForEvent("dungeoncleared", self._ondungeoncleared, TheDungeon)
	self.inst:ListenForEvent("exit_room", function() self:OnExitRoom() end, TheDungeon)
end)

function RunManager:OnExitRoom()
	-- Get current time, add to run_time
	self.run_time = self.run_time + GetTime()
	self.rooms_discovered = self.rooms_discovered + 1
	self.can_abandon = true -- reset this variable, it is only supposed to last for a single room.
end


function RunManager:OnSave()
	local data =
	{
		run_state = self.run_state,
		run_time = self.run_time,
		rooms_discovered = self.rooms_discovered,
		met_npc = self.met_npc,
		is_practice = self.is_practice,
	}

	return data
end

function RunManager:OnLoad(data)
	if data ~= nil then
		-- If loaded back into a dungeon room, reset to ACTIVE to reset cases where we died and reloaded, etc.
		if not TheDungeon:IsInTown() then
			data.run_state = RunStates.s.ACTIVE
		end

		for k, v in pairs(data) do
			self[k] = v
		end
	end
end

function RunManager:ResetData()
	self.run_time = 0
	self.rooms_discovered = 0
	self.met_npc = false
	self.is_practice = false
	self:SetRunState(RunStates.s.ACTIVE)
end

----

function RunManager:HasMetTownNPCInDungeon()
	return self.met_npc
end

function RunManager:SetHasMetTownNPCInDungeon(bool)
	self.met_npc = bool
end

function RunManager:GetBestCommonBossProgress()
	-- For now, just use the host
	if not TheNet:IsHost() then return 1 end
	local boss_prefab = TheDungeon:GetCurrentBoss()
	local main_player = playerutil.GetFirstLocalPlayer()
	return main_player.components.progresstracker:GetBestBossAttempt(boss_prefab)
end

----

function RunManager:IsPracticeRun()
	return self.is_practice
end

function RunManager:SetIsPracticeRun(bool)
	self.is_practice = bool
end

----

function RunManager:CanAbandonRun()
	return self.can_abandon or DEV_MODE
end

function RunManager:SetCanAbandon(bool)
	self.can_abandon = bool
end

----

function RunManager:Debug_PushProgress(dungeon, progress, victory)
	local experience = CalculateBiomeExplorationReward(progress, victory)

	for _, player in ipairs(AllPlayers) do
		local player_log = {}
		local mrm = player.components.metaprogressmanager
		local def = MetaProgress.FindProgressByName(dungeon)
		if not mrm:GetProgress(def) and def ~= nil then
			mrm:StartTrackingProgress(mrm:CreateProgress(def))
		end
		local log = mrm:GrantExperience(def, experience)
	end
end

function RunManager:ApplyRunData(progress_override)
	local progress = progress_override or TheDungeon:GetDungeonMap().nav:GetProgressThroughDungeon()
	local ascension_level = TheDungeon.progression.components.ascensionmanager:GetCurrentLevel()

	local killed_boss = self:IsRunVictory()
	local experience = CalculateBiomeExplorationReward(progress, killed_boss)

	local run_data = {}

	for _, player in ipairs(AllPlayers) do
		local player_log = {}
		local mrm = player.components.metaprogressmanager
		local def = MetaProgress.FindProgressByName(TheDungeon:GetDungeonMap().data.location_id)
		if not mrm:GetProgress(def) and def ~= nil then
			mrm:StartTrackingProgress(mrm:CreateProgress(def))
		end
		local log = mrm:GrantExperience(def, experience)

		player_log.biome_exploration = { meta_reward = mrm:GetProgress(def), meta_reward_log = log }

		player_log.run_time = self.run_time
		player_log.rooms_discovered = self.rooms_discovered

		run_data[player] = player_log
	end

	run_data.run_time = self.run_time
	run_data.rooms_discovered = self.rooms_discovered

	return run_data
end

function RunManager:SetRunState(state)
	self.run_state = state
end

function RunManager:GetRunState()
	return self.run_state
end

function RunManager:IsRunAbandon()
	return self:GetRunState() == RunStates.s.ABANDON
end

function RunManager:IsRunDefeat()
	return self:GetRunState() == RunStates.s.DEFEAT
end

function RunManager:IsRunVictory()
	return self:GetRunState() == RunStates.s.VICTORY
end

function RunManager:IsRunActive()
	return self:GetRunState() == RunStates.s.ACTIVE
end

local function PlayWhistleForHelp(player)
	if player:IsAlive() and not player.sg:HasStateTag("busy") then
		player.sg:GoToState("emote_whistle")
	end
end

function RunManager:Abandon()
	if self:IsRunActive() then
		self:OnExitRoom()
		self:SetRunState(RunStates.s.ABANDON)
		print("RunManager: Switching to " .. self:GetRunState());
		local run_data = self:ApplyRunData()
		run_data.defeat = true
		TheDungeon.HUD:DoDefeatedFlow(run_data)

		if TheNet:IsHost() then
			TheNet:HostEndRun(GAMEMODE_ABANDON)
		end

		for _i,player in ipairs(AllPlayers) do
			if player and player:IsLocal() then
				player:AddTag("nokill")
				local delay = krandom.Float(0, 0.5)
				player:DoTaskInTime(delay, PlayWhistleForHelp)
			end
		end

		TheDungeon:GetDungeonMap():EndRun(self:GetRunState())
	else
		print("RunManager: can't switch to Abandon, because current state is " .. self:GetRunState());
	end
end

function RunManager:Defeated()
	if self:IsRunActive() then
		self:OnExitRoom()
		self:SetRunState(RunStates.s.DEFEAT)
		print("RunManager: Switching to " .. self:GetRunState());
		local run_data = self:ApplyRunData()
		run_data.defeat = true
		TheDungeon.HUD:DoDefeatedFlow(run_data)

		-- network defeat is currently auto-calculated when all players have died
		TheWorld:PushEvent("lastplayerdead")

		TheDungeon:GetDungeonMap():EndRun(self:GetRunState())
	else
		print("RunManager: can't switch to Defeated, because current state is " .. self:GetRunState());
	end
end

function RunManager:Victory()
	if self:IsRunActive() then
		TheDungeon.progression.components.ascensionmanager:CompleteCurrentAscension()

		self:OnExitRoom()
		self:SetRunState(RunStates.s.VICTORY)
		print("RunManager: Switching to " .. self:GetRunState());
		local run_data = self:ApplyRunData()
		TheDungeon.HUD:ShowVictoryButton(run_data)

		if TheNet:IsHost() then
			TheNet:HostEndRun(GAMEMODE_VICTORY)
		end

		for _i,player in ipairs(AllPlayers) do
			if player and player:IsLocal() then
				player:AddTag("nokill")
			end
		end

		TheDungeon:GetDungeonMap():EndRun(self:GetRunState())
	else
		print("RunManager: can't switch to Victory, because current state is " .. self:GetRunState());
	end
end

function RunManager:GetTownSpawnerID()
	return STATE_TO_SPAWNER_ID[self:GetRunState()]
end

return RunManager
