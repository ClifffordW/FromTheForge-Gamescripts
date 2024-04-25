local audioid = require "defs.sound.audioid"
local fmodtable = require "defs.sound.fmodtable"
--local mapgen = require "defs.mapgen"
require "class"

-- stop music on on activated if wanderer

local AmbientAudio = Class(function(self, inst)
	self.inst = inst
	local worldmap = TheDungeon:GetDungeonMap()
	local biomes_location = worldmap:GetBiomeLocation()
	local room = worldmap:GetRoomData(self.travel_room_id)
	if room and room.roomtype then 
		TheLog.ch.Audio:print("***///***ambientaudio.lua: Ambient audio has reloaded and the room type is", room.roomtype .. ".")
	end

	self.ambient_bed_id = audioid.persistent.world_ambient
	self.ambient_birds_id = audioid.persistent.world_birds

	self.threat_level = 0 -- network expecting just 0 or 1; change native serialization if precision increases
	self.noMusicRooms = {
		["boss"] = true,
		["hype"] = true,
		["miniboss"] = true,
	}

	self.noAmbRooms = {
	}

	-- Failsafe to ensure these tracks don't persist past a black screen / new clearing
	TheAudio:StopPersistentSound(audioid.persistent.ui_music)
	TheAudio:StopPersistentSound(audioid.persistent.death_music)
	TheAudio:StopPersistentSound(audioid.persistent.boss_music)
	TheAudio:StopPersistentSound(audioid.persistent.slideshow_music)

	self:SetTravelling(false)
	self:_ResetParamaters()
	self:_ResetSnapshots()
	self:SetThreatLevel(0)

	-- we are starting the music through here only to avoid playing music in the intro quest room really
	-- if we find a better way to circumvent that, we could move music starting to the top of this class
	self._on_player_activated = function()
		if self.checked then
			TheLog.ch.Audio:print("***///***ambientaudio.lua: Player activated, but we've already checked to play music / amb. Exiting.")
			return
		end

		TheLog.ch.Audio:print("***///***ambientaudio.lua: Player activated, determining if we should play music.")
		self:CheckShouldStartMusic()
		self:CheckShouldStartAmbient()

		self:SetThreatLevel(self.threat_level)
		self.checked = true
	end
	inst:ListenForEvent("playeractivated", self._on_player_activated, TheWorld)

	self._onspawnenemy = function(source, ent)
		self:SetThreatLevel(1)
	end
	inst:ListenForEvent("spawnenemy", self._onspawnenemy, TheWorld)

	self._onroomcomplete = function(world, data)
		self:SetThreatLevel(0)
		-- handle miniboss victory sequence
		if worldmap:GetCurrentRoomType() == "miniboss" and TheWorld.components.roomclear:IsRoomComplete() then
			TheFrontEnd:GetSound():PlaySound(biomes_location.miniboss_music_victory)
			self:StopBossMusic()
			self:StartMusic()
		end
	end
	inst:ListenForEvent("room_complete", self._onroomcomplete, TheWorld)

	-- listens for events triggered by runsummaryscreen appearing and going away to know if we're in the 'end of run' flow
	self._on_run_summary_flow = function(active)
		if active then
			local run_end_state = TheDungeon.progression.components.runmanager:GetRunState()
			if run_end_state == "ABANDON" then
				TheAudio:StartFMODSnapshot(fmodtable.Snapshot.DeathScreen)
			elseif run_end_state == "DEFEAT" then
				self:StopAllMusic()
				TheAudio:PlayPersistentSound(audioid.persistent.death_music, fmodtable.Event.mus_Death_LP)
				TheAudio:StartFMODSnapshot(fmodtable.Snapshot.DeathScreen)
			end
		else
			TheAudio:StopFMODSnapshot(fmodtable.Snapshot.DeathScreen)
		end
	end
	inst:ListenForEvent("run_summary_flow", function(_, active) self._on_run_summary_flow(active) end)

	inst:ListenForEvent("end_run_sequence", function(_, is_victory)
		TheAudio:StopFMODSnapshot(fmodtable.Snapshot.DeathScreen)
	end)

	-- self._on_exit_room = function(world, data) end
	-- inst:ListenForEvent("exit_room", self._on_exit_room, TheDungeon)

	-- there's probably a better way to do this, this won't start playing the music until they take damage
	-- but it's better than nothing for right now
	self._on_miniboss_activated = function()
		TheLog.ch.Audio:print(
		"***///***ambientaudio.lua: Miniboss activated, attempting to play music as fallback in case cinematic was missed.")
		self:StartMinibossMusic()
	end
	inst:ListenForEvent("minibossactivated", self._on_miniboss_activated, TheWorld)

	self._on_starting_intro_quest = function() end
	inst:ListenForEvent("starting_intro_quest", self._on_starting_intro_quest, TheWorld)

	self._on_new_game_started = function() end
	inst:ListenForEvent("new_game_started", self._on_new_game_started, TheDungeon)

	self._on_quit_to_menu = function() 
		self:StopEverything()
	end
	inst:ListenForEvent("quit_to_menu", self._on_quit_to_menu, TheWorld)

	-- inst:ListenForEvent("start_new_run", self._on_start_new_run, TheDungeon)

	-- inst:ListenForEvent("end_current_run", self._on_end_current_run, TheDungeon)
end)

--~ function AmbientAudio:OnSave()
--~ 	local data = {}
--~ 	return next(data) ~= nil and data or nil
--~ end

--~ function AmbientAudio:OnLoad(data)
--~ end

-- == ==

function AmbientAudio:_ResetParamaters()
	-- This section is dedicated to resetting parameters and snapshots to their default values.
	-- Use it to clean up and initialize variables before or after certain actions
	-- to ensure the system starts from a known state.
	local audioParametersToReset = {
		"g_fadeOutMusicAndSendToReverb",
		"isLocalPlayerInTotem",
		"thump_pitch",
		"critHitCounter",
		"hitHammerCounter",
		"hitSpearCounter",
		"hitShotputCounter",
	}

	for _, paramName in ipairs(audioParametersToReset) do
		if fmodtable.GlobalParameter[paramName] == nil then
			TheLog.ch.Audio:print("Parameter", paramName, "not found in fmodtable.GlobalParameter")
			return
		end
		TheAudio:SetGlobalParameter(fmodtable.GlobalParameter[paramName], 0)
	end

	TheAudio:SetGlobalParameter(fmodtable.GlobalParameter.thump_quiet_pitch, 7)
end

function AmbientAudio:_ResetSnapshots()
	local audioSnapshotsToStop = {
		"Boss_Intro",
		"Interacting",
		"DuckMusicBass",
		"FadeOutMusicBeforeBossRoom",
		"HitstopCutToBlack",
		"Mute_Music_NonMenuMusic",
		"Mute_Ambience_Bed",
		"Mute_Ambience_Birds",
		"Mute_Music_Dungeon",
		"Mute_Music", -- this could get stuck on from the wellspring lp
		"DeathScreen"
	}

	-- Stopping all snapshots to ensure they don't get stuck
	for _, snapshotName in ipairs(audioSnapshotsToStop) do
		TheAudio:StopFMODSnapshot(fmodtable.Snapshot[snapshotName])
	end
end

function AmbientAudio:CheckShouldStartMusic()
	local currentRoomType = TheDungeon:GetDungeonMap():GetCurrentRoomType()

	if self.noMusicRooms[currentRoomType] then
		TheLog.ch.Audio:print(
		"***///***ambientaudio.lua: No music for this room type. Not starting music automatically.")
		return
	end

	self:StartMusic()
end

function AmbientAudio:CheckShouldStartAmbient()
	local currentRoomType = TheDungeon:GetDungeonMap():GetCurrentRoomType()
	if self.noAmbRooms[currentRoomType] then
		return
	end
	
	self:StartAmbient()
end

function AmbientAudio:StartMusic()
	local worldmap = TheDungeon:GetDungeonMap()
	local biomes_location = TheDungeon:GetDungeonMap():GetBiomeLocation()
	local world_music = biomes_location.ambient_music
	local room_music = worldmap:GetCurrentRoomAudio()

    if room_music then
        self:StartRoomMusic(room_music)
	else
		self:StopRoomMusic()
	end

	if world_music then
		self:StartWorldMusic()
	else
		TheLog.ch.Audio:print("No world music found for this biome. Stopping existing world music.")
		self:StopWorldMusic()
	end
end

function AmbientAudio:StartAmbient()
	local worldmap = TheDungeon:GetDungeonMap()

	self.ambient_bed_sound, self.ambient_birds_sound = self:_GetAmbientSound()
	TheAudio:PlayPersistentSound(self.ambient_bed_id, self.ambient_bed_sound)

	if self.ambient_birds_sound then
		TheAudio:PlayPersistentSound(self.ambient_birds_id, self.ambient_birds_sound)
	end

	self:SetDungeonProgressParameter({ self.ambient_bed_id, self.ambient_birds_id })
	self:SetIsInBossFlowParameter(worldmap:IsInBossArea())
end

function AmbientAudio:StartRoomMusic(room_music)
	TheAudio:PlayPersistentSound(audioid.persistent.room_music, room_music)
	self:SetDungeonProgressParameter({ audioid.persistent.room_music, room_music })
end

function AmbientAudio:StartMinibossMusic()
	local biomes_location = TheDungeon:GetDungeonMap():GetBiomeLocation()
	local music = biomes_location.miniboss_music_LP or biomes_location.ambient_music
	TheAudio:PlayPersistentSound(audioid.persistent.boss_music, music)
end

function AmbientAudio:StartBossMusic(skip_to_phase)
	local biomes_location = TheDungeon:GetDungeonMap():GetBiomeLocation()
	local music = biomes_location.boss_music_LP or biomes_location.ambient_music
	TheAudio:PlayPersistentSound(audioid.persistent.boss_music, music)
	if skip_to_phase then
		TheAudio:SetPersistentSoundParameter(audioid.persistent.boss_music, "Music_BossPhase_Skip", skip_to_phase)
		TheLog.ch.Audio:print("***///***ambientaudio.lua: Setting boss music phase to" .. skip_to_phase)
	end
end

function AmbientAudio:StopRoomMusic()
	TheAudio:StopPersistentSound(audioid.persistent.room_music)
end

function AmbientAudio:StartWorldMusic()
	local biomes_location = TheDungeon:GetDungeonMap():GetBiomeLocation()
	local world_music = biomes_location.ambient_music
	TheAudio:PlayPersistentSound(audioid.persistent.world_music, world_music)
	self:SetDungeonProgressParameter({ audioid.persistent.world_music, world_music })
end

function AmbientAudio:StopWorldMusic()
	TheAudio:StopPersistentSound(audioid.persistent.world_music)
end

function AmbientAudio:StopBossMusic()
	TheAudio:StopPersistentSound(audioid.persistent.boss_music)
end

function AmbientAudio:StopAllMusic()
	self:StopWorldMusic()
	self:StopRoomMusic()
	self:StopBossMusic()
end

function AmbientAudio:StopAmbient()
	TheAudio:StopPersistentSound(self.ambient_bed_id)
	TheAudio:StopPersistentSound(self.ambient_birds_id)
end

function AmbientAudio:StopEverything()
	AmbientAudio:StopAmbient()
	AmbientAudio:StopAllMusic()
end

function AmbientAudio:GetDungeonProgress()
	local worldmap = TheDungeon:GetDungeonMap()
	local dungeon_progress = worldmap.nav:GetProgressThroughDungeon()
	return dungeon_progress
end

function AmbientAudio:SetDungeonProgressParameter(id)
	local dungeon_progress = self:GetDungeonProgress()
	for k, v in pairs(id) do
		TheAudio:SetPersistentSoundParameter(v, "Music_Dungeon_Progress", dungeon_progress)
	end
end

function AmbientAudio:SetIsInBossFlowParameter(is_boss) -- reset to 0 after the boss death animation plays as well
	TheAudio:SetPersistentSoundParameter(self.ambient_bed_id, "isInBossFlow", is_boss and 1 or 0)
	TheAudio:SetPersistentSoundParameter(self.ambient_birds_id, "isInBossFlow", is_boss and 1 or 0)
	TheAudio:SetPersistentSoundParameter(audioid.persistent.world_music, "isInBossFlow", is_boss and 1 or 0)
end

function AmbientAudio:StartMuteSnapshot()
	TheAudio:PlayPersistentSound(audioid.persistent.mute_world_music_snapshot, fmodtable.Event.Snapshot_MuteWorldMusic_LP)
end

function AmbientAudio:StopMuteSnapshot()
	TheAudio:StopPersistentSound(audioid.persistent.mute_world_music_snapshot)
end

function AmbientAudio:StartWandererSnapshot()
	TheAudio:PlayPersistentSound(audioid.persistent.wanderer_snapshot, fmodtable.Event.Snapshot_Wanderer_LP)
end

function AmbientAudio:StopWandererSnapshot()
	TheAudio:StopPersistentSound(audioid.persistent.wanderer_snapshot)
end

function AmbientAudio:_GetAmbientSound()
	local biomes_location = TheDungeon:GetDungeonMap():GetBiomeLocation()
	if biomes_location.ambient_birds_sound then
		return biomes_location.ambient_bed_sound or nil, biomes_location.ambient_birds_sound or nil
	else
		return biomes_location.ambient_bed_sound or nil, nil
	end
end

function AmbientAudio:GetMinibossMusic()
	local biomes_location = TheDungeon:GetDungeonMap():GetBiomeLocation()
	return biomes_location.miniboss_music_LP or biomes_location.ambient_music
end

function AmbientAudio:GetBossMusic()
	local biomes_location = TheDungeon:GetDungeonMap():GetBiomeLocation()
	return biomes_location.boss_music_LP or biomes_location.ambient_music
end

function AmbientAudio:_GetWorldMusic()
	local biomes_location = TheDungeon:GetDungeonMap():GetBiomeLocation()
	return biomes_location.ambient_music
end

function AmbientAudio:PlayMusicStinger(stinger)
	TheAudio:PlayPersistentSound(audioid.oneshot.stinger, stinger)
end

function AmbientAudio:GetThreatLevel()
	return self.threat_level
end

function AmbientAudio:SetThreatLevel(level)
	self.threat_level = level
	if TheNet:IsHost() then
		TheNet:HostSetThreatLevel(level)
	end

	TheAudio:SetPersistentSoundParameter(audioid.persistent.world_music, "Music_InCombat", level) -- this value gets lerped in FMOD Studio, but we also need to know the immediate value
	TheAudio:SetPersistentSoundParameter(audioid.persistent.world_music, "Music_InCombat_Destination", level) -- so we send a second parameter that represents the destination of the parameter
	TheAudio:SetGlobalParameter(fmodtable.GlobalParameter.inCombat, level)
	-- TheLog.ch.AudioSpam:print("THREAT LEVEL", level)
end

function AmbientAudio:SetTravelling(is_travelling)
	if is_travelling then
		TheAudio:StartFMODSnapshot(fmodtable.Snapshot.TravelScreen)
	else
		TheAudio:StopFMODSnapshot(fmodtable.Snapshot.TravelScreen)
	end
end

--~ function AmbientAudio:GetDebugString()
--~ 	return table.inspect{
--~ 		sound = self.sound_event,
--~ 		music = self.music_event,
--~ 		current_music = TheAudio:GetPersistentSound(audioid.persistent.world_music),
--~ 		current_sound = TheAudio:GetPersistentSound(self.amb_bed),
--~ 	}
--~ end

function AmbientAudio:SetLocalParameterForAllPersistentMusicTracks(parameter, value)
	TheAudio:SetPersistentSoundParameter(audioid.persistent.world_music, parameter, value)
	TheAudio:SetPersistentSoundParameter(audioid.persistent.room_music, parameter, value)
	TheAudio:SetPersistentSoundParameter(audioid.persistent.boss_music, parameter, value)
end

-- function AmbientAudio:GetRandomMusicOffset(floor)
-- 	-- Set a random seed based on the current time
-- 	math.randomseed(os.time())
-- 	local offset = math.random() + floor

-- 	-- Adjust the offset based on the floor value
-- 	if offset >= 1 then
-- 		offset = math.abs(1 - offset)
-- 	end

-- 	return offset
-- end

-- -- set a random start time for the level music to create illusion of continued play
-- local music_play_offset = self:GetRandomMusicOffset(self:GetDungeonProgress())
-- TheAudio:SetPersistentSoundParameter(audioid.persistent.world_music, "Music_PlayOffset", music_play_offset)
-- TheLog.ch.Audio:print("***///***ambientaudio.lua: Setting a random music offset:", music_play_offset)
	
-- self._on_boss_activated = function()
-- 	TheLog.ch.Audio:print(
-- 	"***///***ambientaudio.lua: Boss activated, attempting to play music as fallback in case cinematic was missed.")
-- 	self:StartBossMusic()
-- end
-- inst:ListenForEvent("bossactivated", self._on_boss_activated, TheWorld)

-- function AmbientAudio:CheckDelayedMusicStart(roomtype)
-- 	-- don't want to check this more than once. If there's a boss or miniboss, it would have been there on initial sweep
-- 	if self.checked_spawn then return end

-- 	local is_active_boss
-- 	self.checked_spawn = true
-- 	-- check if there are any minibosses in the room
-- 	local ents = FindEnemiesInRange(0, 0, 1000)
-- 	for i, ent in ipairs(ents) do
-- 		if ent:HasTag(roomtype)then
-- 			if ent.components.boss and ent.components.boss.has_activated then
-- 				is_active_boss = true
-- 				TheLog.ch.Audio:print("Active boss in here.")
-- 			end
-- 		end
-- 	end

-- 	-- no active bosses, exit and don't check again
-- 	if not is_active_boss then return end

-- 	if roomtype == "miniboss" then
-- 		TheLog.ch.Audio:print("***///***ambientaudio.lua: Delayed miniboss music start for spectator failsafe.")
-- 		self:StartMinibossMusic()
-- 	elseif roomtype == "boss" then
-- 		TheLog.ch.Audio:print("***///***ambientaudio.lua: Delayed miniboss music start for spectator failsafe.")
-- 		self:StartBossMusic()
-- 	end
-- end


	-- if TheWorld:HasTag("town") then
	-- 	local delay
	-- 	local returning_from_run = TheDungeon.progression.components.runmanager:GetRunState() ~= "ACTIVE"
	-- 	if returning_from_run then delay = 5 else delay = 0 end
	-- 	TheWorld:DoTaskInTime(delay, function()
	-- 		TheLog.ch.Audio:print("***///***ambientaudio.lua: Failsafe delayed start of town music.")
	-- 		self:StartMusic()
	-- 	end)
	-- else
	-- 	self:StartMusic()
	-- end

return AmbientAudio
