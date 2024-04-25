local audioid = require "defs.sound.audioid"
local fmodtable = require "defs.sound.fmodtable"
local waves = require "encounter.waves"

-- Each entry corresponds to the # of players
local fight_waves =
{
	waves.Raw{ swarmy = 1, woworm = 2 },
	waves.Raw{ swarmy = 1, woworm = 3 },
	waves.Raw{ swarmy = 2, woworm = 3 },
	waves.Raw{ swarmy = 2, woworm = 3, slowpoke = 1 },
}

-- Non-permanent acid positions spawned by special Thatcher States
local GEYSER_ACID_POSITIONS =
{
	intro = -- Also used for phase 1 special move
	{
		{0.3, 0.4},
		{0.7, 0.4},
	},

	phase2 =
	{
		{0.5, 0.4},

		{0.3, 0.55},
		{0.7, 0.55},
		{0.3, 0.25},
		{0.7, 0.25},
	},

	phase3 =
	{
		{0.46, 0.55},
		{0.46, 0.25},
		{0.54, 0.55},
		{0.54, 0.25},

		{0.38, 0.55},
		{0.38, 0.25},
		{0.62, 0.55},
		{0.62, 0.25},

		{0.3, 0.55},
		{0.3, 0.25},
		{0.7, 0.55},
		{0.7, 0.25},

		{0.22, 0.55},
		{0.22, 0.25},
		{0.78, 0.55},
		{0.78, 0.25},
	},
}

local PERMANENT_ACID_POSITIONS =
{
	-- Phase 1 - Starting acid; top left/right corners.
	{
		{ 0.09, 0.89 },
		{ 0.16, 0.89 },

		{ 0.91, 0.89 },
		{ 0.84, 0.89 },
	},

	-- Phase 2 - Left/Right sides.
	{
		{ 0.09, 0.69 },
		{ 0.91, 0.69 },

		{ 0.09, 0.53 },
		{ 0.91, 0.53 },

		{ 0.09, 0.37 },
		{ 0.91, 0.37 },

		{ 0.09, 0.22 },
		{ 0.91, 0.22 },

		{ 0.18, 0.11 },
		{ 0.82, 0.11 },
	},

	-- Phase 3 - Bottom/Top Center.
	{
		{ 0.24, 0.68 },
		{ 0.84, 0.69 },

		{ 0.39, 0.64 },
		{ 0.69, 0.64 },
		{ 0.31, 0.11 },
		{ 0.69, 0.11 },

		{ 0.54, 0.64 },
		{ 0.44, 0.11 },
		{ 0.56, 0.11 },
	},
}

local PHASE_THRESHOLDS =
{
	0.8,	-- Phase 1 to 2
	0.4,	-- Phase 2 to 3
}

-- Use current phase to make these faster as phases increase
local TIME_BETWEEN_ATTACKS =
{
	{ 12, 15 },
	{ 8, 10 },
	{ 8, 10 },
}

local BossCoroThatcher = Class(BossCoroutine, function(self, inst)
	BossCoroutine._ctor(self, inst)

	-- Check for phase changes
	self:CheckHealthPhaseTransition(PHASE_THRESHOLDS)
end)

function BossCoroThatcher:OnNetSerialize()
	local e = self.inst.entity

	e:SerializeBoolean(self.music_phase ~= nil)
	if self.music_phase then
		e:SerializeUInt(self.music_phase, 3) -- 0 thru 4
	end
end

function BossCoroThatcher:OnNetDeserialize()	
	local e = self.inst.entity

	local has_music_phase = e:DeserializeBoolean()
	if has_music_phase then
		local new_music_phase = e:DeserializeUInt(3)
		if not self.music_started then
			TheLog.ch.Audio:print("***///***bc_thatcher.lua: Fight in progress, starting boss music.")
			if new_music_phase then
				TheLog.ch.Audio:print("***///***bc_thatcher.lua: Skipping to phase" .. new_music_phase .. " .")
				TheWorld.components.ambientaudio:StartBossMusic(new_music_phase)
			else
				TheWorld.components.ambientaudio:StartBossMusic()
			end
			self.music_started = true
		end
		if new_music_phase ~= self.music_phase then
			self:SetMusicPhase(new_music_phase)
		end
	end
end

function BossCoroThatcher:SpawnSetDressing(data)
	BossCoroThatcher._base.SpawnSetDressing(self, data)
	--TheWorld.components.spawncoordinator:SpawnPropDestructibles(10, true)
end

function BossCoroThatcher:GetAttackCooldown()
	local current_phase = self.inst.boss_coro:CurrentPhase() or 1
	local min, max = TIME_BETWEEN_ATTACKS[current_phase][1], TIME_BETWEEN_ATTACKS[current_phase][2]
	return math.random(min, max)
end

function BossCoroThatcher:SetMusicPhase(phase)
	TheAudio:SetPersistentSoundParameter(audioid.persistent.boss_music, "Music_BossPhase", phase)
	self.music_phase = phase
end

function BossCoroThatcher:SetUpFight()
	for id, data in pairs(self.inst.components.attacktracker.attack_data) do
		if data.timer_id then
			self.inst.components.timer:ResumeTimer(data.timer_id)
		end
	end
end

local SPAWN_WAVE_POST_WAIT_TIME = 3

function BossCoroThatcher:SummonWave(wave)
	-- print("BossCoroThatcher:SummonWave(wave)")
	local enemy_list = TheWorld.components.roomclear:GetEnemies()
	if #enemy_list > 1 then
		return
	end

	local sc = TheWorld.components.spawncoordinator
	local custom_encounter = function(spawner)
		spawner:StartSpawningFromHidingPlaces()
		spawner:SpawnWave(wave, 0, 0)
	end
	sc:StartCustomEncounter(custom_encounter)
	self:SetMusicPhase(4)
	-- need to wait for a bit to ensure the enemies have spawned before the next command
	self:WaitForSeconds(SPAWN_WAVE_POST_WAIT_TIME)
end

function BossCoroThatcher:GetGeyserAcidPattern(key)
	return GEYSER_ACID_POSITIONS[key]
end

function BossCoroThatcher:GetPermanentAcidPattern(phase)
	return PERMANENT_ACID_POSITIONS[phase or self:CurrentPhase()]
end

-----------------------------------------------------------

function BossCoroThatcher:DoIdleBehavior()
	self:WaitForNotBusy()
	self.inst.boss_coro:SendEvent("idlebehavior")
	self:WaitForSeconds(self:GetAttackCooldown(), true)
end

--[[function BossCoroThatcher:DoFullSwing()
	self:WaitForNotBusy()
	self.inst.boss_coro:SendEvent("fullswing")
	self:WaitForEvent("fullswing_over")
end]]

function BossCoroThatcher:DoFullSwingMobile()
	self:WaitForNotBusy()
	self.inst.boss_coro:SendEvent("fullswing_mobile")
	self:WaitForEvent("fullswing_mobile_over")
end

--[[function BossCoroThatcher:DoHook()
	self:WaitForNotBusy()
	self.inst.boss_coro:SendEvent("hook")
	self:WaitForEvent("hook_over")
end]]

function BossCoroThatcher:DoDashUppercut()
	self:WaitForNotBusy()
	self.inst.boss_coro:SendEvent("dash_uppercut")
	self:WaitForEvent("dash_uppercut_over")
end

function BossCoroThatcher:DoSwingSmash()
	self:WaitForNotBusy()
	self.inst.boss_coro:SendEvent("swing_smash")
	self:WaitForEvent("swing_smash_over")
end

function BossCoroThatcher:DoAcidSplash()
	self:WaitForNotBusy()
	self.inst.boss_coro:SendEvent("acid_splash")
	self:WaitForEvent("acid_splash_over")
end

function BossCoroThatcher:DoAcidCoating()
	self:WaitForNotBusy()
	self.inst.boss_coro:SendEvent("acid_coating")
	self:WaitForEvent("acid_coating_over")
end

-----------------------------------------------------------

-- Starting phase. Melee/Wind Flap/Dive Bomb
function BossCoroThatcher:PhaseOne()
	--print("BossCoroThatcher:PhaseOne()")
	if self.inst.components.combat:GetTarget() == nil then
		self:DoIdleBehavior()
		return
	end

	self:DoConditionalFunction(self.WaitForSeconds, self:GetAttackCooldown(), true)
	self:DoConditionalFunction(self.DoFullSwingMobile)
	self:DoConditionalFunction(self.WaitForNotBusy) -- If owlitzer gets stunned, wait until it recovers to resume
end

-- Melee/Dive/Summon Mobs/Flap/Dive Bomb
function BossCoroThatcher:PhaseTwo()
	--print("BossCoroThatcher:PhaseTwo()")
	if self.inst.components.combat:GetTarget() == nil then
		self:DoIdleBehavior()
		return
	end

	self:DoConditionalFunction(self.WaitForSeconds, self:GetAttackCooldown(), true)
	self:DoConditionalFunction(self.DoAcidSplash)
	self:DoConditionalFunction(self.WaitForSeconds, self:GetAttackCooldown(), true)
	--self:DoConditionalFunction(self.DoHook)
	self:DoConditionalFunction(self.DoDashUppercut)
	self:DoConditionalFunction(self.WaitForNotBusy)
end

-- Melee/Dive/Barf/Dive Bomb/Summon Mobs/Super Flapping/Fly By.
function BossCoroThatcher:PhaseThree()
	--print("BossCoroThatcher:PhaseThree()")
	if self.inst.components.combat:GetTarget() == nil then
		self:DoIdleBehavior()
		return
	end

	self:DoConditionalFunction(self.WaitForSeconds, self:GetAttackCooldown(), true)
	self:DoConditionalFunction(self.DoAcidSplash)
	self:DoConditionalFunction(self.WaitForSeconds, self:GetAttackCooldown(), true)
	self:DoConditionalFunction(self.DoSwingSmash)
	self:DoConditionalFunction(self.WaitForNotBusy)

	-- Summon mobs
	--self:DoConditionalFunction(self.SummonWave, fight_waves[#AllPlayers])
	--self:DoConditionalFunction(self.WaitForSeconds, 10)

	self:DoConditionalFunction(self.WaitForSeconds, self:GetAttackCooldown(), true)
end

-----------------------------------------------------------

function BossCoroThatcher:Main()
	-- Will start after cine completes.
	self:SetUpFight()

	-- FOR DEBUG USE
	--self.inst.boss_coro:SetPhase(2)
	--self.inst.sg:GoToState("phase_transition")
	--self:DoUntilHealthPercent(0, self.DoFullSwingMobile)
	--self:DoUntilHealthPercent(0, self.DoDashUppercut)
	--self:DoUntilHealthPercent(0, self.DoSwingSmash)
	--self:DoUntilHealthPercent(0, self.DoAcidSplash)
	--self:DoUntilHealthPercent(0, self.DoAcidCoating)

	-- Phase 1:
	self:SetMusicPhase(1)
	self:SetConditionalFunction(function() return self:HealthAbovePercent(PHASE_THRESHOLDS[1]) end)
	self:DoUntilHealthPercent(PHASE_THRESHOLDS[1], self.PhaseOne)

	self.inst.components.attacktracker:SetMinimumCooldown(1.5) -- Make more aggressive at each phase transition

	-- Phase 2:
	self:SetConditionalFunction(function() return self:HealthAbovePercent(PHASE_THRESHOLDS[2]) end)
	self:DoUntilHealthPercent(PHASE_THRESHOLDS[2], self.PhaseTwo)

	self.inst.components.attacktracker:SetMinimumCooldown(1)

	--self:WaitForNotBusy()
	--self:DoAcidCoating()

	-- Phase 3:
	self:SetConditionalFunction(function() return self:HealthAbovePercent(0) end)
	self:DoUntilHealthPercent(0, self.PhaseThree)
end

return BossCoroThatcher
