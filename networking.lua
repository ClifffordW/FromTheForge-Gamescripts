local ConfirmDialog = require "screens.dialogs.confirmdialog"
local ConnectingToGamePopup = require "screens/redux/connectingtogamepopup"
local krandom = require "util.krandom"
local DebugDraw = require "util.debugdraw"
local SpawnCoordinator = require "components.spawncoordinator"
local Constructable = require "defs.constructable"

local LoadingInProgress = false

local VERBOSENETWORK <const> = 0x00000040 -- kiln::LoggingOptions::VerboseNetwork
local SUPERVERBOSENETWORK <const> = 0x00000080 -- kiln::LoggingOptions::SuperVerboseNetwork
VerboseNetworkLogging = TheSim and TheSim:IsLoggingOptionEnabled(VERBOSENETWORK) or false
SuperVerboseNetworkLogging = TheSim and TheSim:IsLoggingOptionEnabled(SUPERVERBOSENETWORK) or false
IsLocalGame = not TheNet:IsInGame() or TheNet:IsGameTypeLocal() -- TODO: nosimreset, do not cache this

-- These need to stay in sync with the game modes in networklib\NetworkHostStateImplementation.h
GAMEMODE_GAME = 0
GAMEMODE_GAMEOVER = 1
GAMEMODE_VICTORY = 2
GAMEMODE_ABANDON = 3
GAMEMODE_SKILLSELECT = 4
GAMEMODE_RELICSELECT = 5
GAMEMODE_POWERFABLEDSELECT = 6

STARTRUNMODE_DEFAULT = 0
STARTRUNMODE_ARENA = 1

-- These need to stay in sync with the power drop types in networklib\NetworkHostStateImplementation.h
POWERDROP_RELIC = 0
POWERDROP_SKILL = 1
POWERDROP_POWERFABLED = 2
POWERDROP_LOOTONLY = 3

-- These need to stay in sync with run player status in networklib\NetworkHostStateImplementation.h
RUNPLAYERSTATUS_ACTIVE = 0
RUNPLAYERSTATUS_CORPSE = 1


-- MessageType enum from NetworkHostNotifications.h
MESSAGETYPE_PLAYERJOINED = 0
MESSAGETYPE_PLAYERLEFT = 1
MESSAGETYPE_PLAYERKICKED = 2
MESSAGETYPE_FEEDBACKREQUEST = 3

-- Permanent Flags for NetworkEntities
SupportPFlags = true
PFLAG_ALL = 0xFF
PFLAG_JOURNALED_REMOVAL = 0x1 -- set when an entity begins removal; transferred owners should remove the entity if set
PFLAG_CHARMED = 0x2 -- set when an entity is charmed

-- Transform NetworkHistoryIgnoreFlags
NETHISTORYIGNOREFLAG_POSITION = 0x1
NETHISTORYIGNOREFLAG_ROTATION = 0x2
NETHISTORYIGNOREFLAG_SCALE = 0x4

function GetRunPlayerStatusDescription(status)
	if status == RUNPLAYERSTATUS_ACTIVE then
		return "ACTIVE"
	elseif status == RUNPLAYERSTATUS_CORPSE then
		return "CORPSE"
	end
	return "UNKNOWN"
end

local function NetworkInitThread(continuation)
	local startTime = GetTime()
	TheLog.ch.Networking:printf("  ... Waiting for network to initialize")

	-- bootstrap the network if it isn't running. (could happen when using various debug buttons to start the game.
	if not TheNet:IsInGame() then
		TheLog.ch.Networking:printf("  ... Starting new network game")
		local inputID = TheSaveSystem.cheats:GetValue("debug_inputID") or 0
		TheNet:StartGame(inputID, "local")
	end


	local yieldCount = 0
	while not TheNet:IsGameReady() do
		yieldCount = yieldCount + 1
		-- TheLog.ch.Networking:printf("  ... %d", yieldCount)
		Yield()
	end
	Yield()

	local elapsedTime = GetTime() - startTime
	TheLog.ch.Networking:printf("  ... Network initialized in %1.2f seconds", elapsedTime)

	LoadingInProgress = false
	TheLog.ch.Networking:printf("Starting network... complete")
	if continuation then
		continuation()
	end
end

-- Asynchronous initialization of network system
function TryStartNetwork(continuation)
	if LoadingInProgress then
		TheLog.ch.Networking:printf("Ignoring additional request to initialize network.")
		return
	end

	TheLog.ch.Networking:printf("Starting network...")
	LoadingInProgress = true -- reset in NetworkInitThread
	Scheduler:StartThread(function() NetworkInitThread(continuation) end)
end

function Networking_Announcement(message, colour, announce_type)
    if TheDungeon and TheDungeon.HUD and TheDungeon.HUD.eventannouncer.inst:IsValid() then
        TheDungeon.HUD.eventannouncer:ShowNewAnnouncement(message, colour, announce_type)
    end
end

function Networking_SystemMessage(message)
    if TheDungeon and TheDungeon.HUD then
        TheDungeon.HUD.controls.networkchatqueue:DisplaySystemMessage(message)
    end
end

function Networking_ModOutOfDateAnnouncement(mod)
    if Platform.IsRail() then
        Networking_Announcement(string.format(STRINGS.MODS.VERSIONING.OUT_OF_DATE_RAIL, mod), nil, "mod")
    else
        Networking_Announcement(string.format(STRINGS.MODS.VERSIONING.OUT_OF_DATE, mod), nil, "mod")
    end
end

--For ease of overriding in mods
function Networking_Announcement_GetDisplayName(name)
    return name
end

function Networking_Say(guid, userid, name, prefab, message, colour, whisper, isemote, user_vanity)
    if message ~= nil and message:utf8len() > MAX_CHAT_INPUT_LENGTH then
        return
    end
    local entity = Ents[guid]
    if not isemote and entity ~= nil and entity.components.talker ~= nil then
        entity.components.talker:Say(not entity:HasTag("mime") and message or "", nil, nil, nil, true, colour)
    end
    if message ~= nil then
        if not (whisper or isemote) then
            local screen = TheFrontEnd:GetActiveScreen()
            if screen ~= nil and screen.ReceiveChatMessage then
                screen:ReceiveChatMessage(name, prefab, message, colour, whisper)
            end
        end
        local hud = TheDungeon.HUD
        if hud ~= nil
            and (not whisper
                or (entity ~= nil
                    and (hud:HasTargetIndicator(entity) or
                        entity.entity:FrustumCheck()))) then
            if isemote then
                hud.controls.networkchatqueue:DisplayEmoteMessage(name, prefab, message, colour, whisper)
            else
                local profileflair = GetRemotePlayerVanityItem(user_vanity or {}, "profileflair")
                hud.controls.networkchatqueue:OnMessageReceived(name, prefab, message, colour, whisper, profileflair)
            end
        end
    end
end

function OnTwitchMessageReceived(username, message, colour)
    if TheWorld ~= nil then
        TheWorld:PushEvent("twitchmessage", {
            username = username,
            message = message,
            colour = colour,
        })
    end
end

function OnTwitchLoginAttempt(success, result)
    if TheWorld ~= nil then
        TheWorld:PushEvent("twitchloginresult", {
            success = success,
            result = result,
        })
    end
end

function OnTwitchChatStatusUpdate(status)
    if TheWorld ~= nil then
        TheWorld:PushEvent("twitchstatusupdate", {
            status = status,
        })
    end
end

function ValidateRecipeSkinRequest(user_id, prefab_name, skin)
    TheLog.ch.Networking:printf("ValidateRecipeSkinRequest called")
    local validated_skin = nil
    if skin ~= nil and skin ~= "" and TheInventory:CheckClientOwnership(user_id, skin) then
        if table.contains( PREFAB_SKINS[prefab_name], skin ) then
            validated_skin = skin
        end
    end
    return validated_skin
end


-- current critical path to player spawning
function SpawnLocalPlayerFromSim(player_guid, playerID)
    local player = Ents[player_guid]
    if player ~= nil then
        player:TrySpawnIntoWorld()

		print("Spawning Local Player From Sim. PlayerID=" .. (playerID or -1))
    else
		print("INVALID PLAYER ENTITY! Guid: " .. player_guid)
	end
end

function RemoveLocalPlayerFromSim(player_guid, playerID)

	print("Removing Player From Sim. PlayerID=" .. (playerID or -1))

	RemoveEntity(player_guid)

	-- save player data now in case a developer hot reloads
	TheSaveSystem:SaveAllExcludingRoom()
end

function LocalPlayerChangedInputID(player_guid)
    local player = Ents[player_guid]
    if player ~= nil then
		-- Don't clear because we want to *start* using inputid from native.
		local clear_input_id = false
		player.components.playercontroller:ReInitInputs(clear_input_id)
    else
		print("INVALID PLAYER ENTITY! Guid: " .. player_guid)
	end
end

function RequestedLobbyCharacter(userid, prefab_name, skin_base, clothing_body, clothing_hand, clothing_legs, clothing_feet)
	TheWorld:PushEvent("ms_requestedlobbycharacter", {userid=userid, prefab_name=prefab_name, skin_base=skin_base, clothing_body=clothing_body, clothing_hand=clothing_hand, clothing_legs=clothing_legs, clothing_feet=clothing_feet})
end

function DownloadMods( server_listing )
	assert(false, "Needs new implementation")
end

function ShowConnectingToGamePopup()
    local active_screen = TheFrontEnd:GetActiveScreen()
    if active_screen == nil or (active_screen._widgetname ~= "ConnectingToGamePopup" and active_screen._widgetname ~= "QuickJoinScreen") then
		print("ShowConnectingToGamePopup()");
        local popup = ConnectingToGamePopup()
        TheFrontEnd:PushScreen(popup)
        popup:AnimateIn()
        return popup
    end
end

function HideConnectingToGamePopup()
	repeat
		local popup = TheFrontEnd:FindScreen(ConnectingToGamePopup)
		if popup then
			print("Popping ConnectingToGamePopup in HideConnectingToGamePopup().")
			TheFrontEnd:PopScreen(popup)
		end
	until not popup
end

function GetAvailablePlayerColors()
    -- 2023-10-05: This function is called from cClientColorPicker in native,
    -- but that functionality is not used on Rotwood.

    -- -Return an ordered list of player colours, and a default colour.
    --
    -- -Default colour should not be in the list, and it is only used
    --  when data is not available yet or in case of errors.
    --
    -- -Colours are assigned in order as players join, so modders can
    --  prerandomize this list if they want random assignments.
    --
    -- -Players will be reassigned their previous colour on a server if
    --  it hasn't been used, and the server is in the same session.

    --TODO: forward to a mod function before returning?
    return UICOLORS.PLAYERS, UICOLORS.PLAYER_UNKNOWN
end

-- Used with c_reset, Ctrl+R reload, etc.
function WorldResetFromSim()
	TheLog.ch.Networking:printf("Received world reset request")
	if TheWorld then
		if TheWorld.IsInitialized then
			if TheDungeon:GetDungeonMap():IsDebugMap() then
				StartNextInstance({
					reset_action = RESET_ACTION.DEV_LOAD_ROOM,
					world_prefab = TheWorld.prefab,
					force_reset = true,
				})
			else
				StartNextInstance({
					reset_action = TheWorld:HasTag("town") and RESET_ACTION.LOAD_TOWN_ROOM or RESET_ACTION.LOAD_DUNGEON_ROOM,
					world_prefab = TheWorld.prefab,
					scenegen_prefab = TheSceneGen and TheSceneGen.prefab,
					room_id = TheDungeon:GetDungeonMap():GetCurrentRoomId(),
					force_reset = true,
				})
			end
		elseif InstanceParams and InstanceParams.settings then
			TheLog.ch.Networking:printf("Warning: TheWorld failed during initialization.  Restarting with previous settings...")
			StartNextInstance({
				reset_action = InstanceParams.settings.reset_action,
				world_prefab = InstanceParams.settings.world_prefab,
				scenegen_prefab = InstanceParams.settings.scenegen_prefab,
				room_id = InstanceParams.settings.room_id,
				force_reset = InstanceParams.settings.force_reset,
			})
		else
			TheLog.ch.Networking:printf("Warning: TheWorld failed during initialization with no restart settings.  Returning to main menu...")
			StartNextInstance({ reset_action = RESET_ACTION.LOAD_FRONTEND })
		end
	else
		TheLog.ch.Networking:printf("Warning: TheWorld does not exist.  Returning to main menu...")
		StartNextInstance({ reset_action = RESET_ACTION.LOAD_FRONTEND })
	end
end




--------------------------------------------------------------------------


-- example arena_world_prefab: "starting_forest_arena_nesw"
-- example region_id: "forest", "swamp", etc.
-- example location_id: "treemon_forest", "owlitzer_forest", "bandi_swamp", etc.
-- alt_mapgen_id is an optional index into alternate_mapgens for a biome (see biomes.lua)
function OnNetworkClientStartRun(mode, dungeon_run_params, quest_params)
	if TheNet:IsHost() then
		return
	end

	TheAudio:StopAllSounds()
	TheLog.ch.Networking:printf("OnNetworkClientStartRun: mode=%d dungeon_run_params=%s quest_params=%s",
		mode, tabletoordereddictstring(dungeon_run_params), tabletoordereddictstring(quest_params))

	if mode == STARTRUNMODE_DEFAULT then
		local RoomLoader = require "roomloader"
		RoomLoader.ClientStartRun(dungeon_run_params, quest_params)

	elseif mode == STARTRUNMODE_ARENA then
		-- like debugcommands.lua start_specific_room()
		local biomes = require "defs.biomes"
		local biome_location = biomes.locations[dungeon_run_params.location_id]

		TheAudio:StopAllSounds() -- Not normal flow, so clean up sounds.
		local WorldMap = require "components.worldmap"
		WorldMap.GetDungeonMap_Safe():Debug_StartArena(dungeon_run_params.arena_world_prefab,
			{
				roomtype = dungeon_run_params.roomtype,
				location = biome_location.id,
				is_terminal = false, -- terminal suppresses resource rooms
			})
	else
		assert(false, "Unhandled StartRun mode")
	end
end

-- this resets to zero every time there is a sim reset
-- the room complete seqnr resets to zero every room change
local lastRoomCompleteAckSeqNr = 0

function OnNetworkClientLoadRoom(roomdata)
	if TheNet:IsHost() then
		return
	elseif roomdata.actionID == 0 then
		return
	end

	lastRoomCompleteAckSeqNr = 0 -- explicit reset needed when per-room sim reset goes away

	TheLog.ch.Networking:printf("OnNetworkClientLoadRoom: actionID=%d worldPrefab=%s sceneGenPrefab=%s roomID=%d forceReset=%s",
		roomdata.actionID, roomdata.worldPrefab, roomdata.sceneGenPrefab, roomdata.roomID, roomdata.forceReset)

	local RoomLoader = require "roomloader"
	assert(RoomLoader.ClientLoadTownLevel ~= nil)

	if roomdata.forceReset then
		RoomLoader.ResetNextLoad()
	end

	-- similar to gamelogic.lua DoResetAction?
	if roomdata.actionID == RESET_ACTION.LOAD_DUNGEON_ROOM then
		-- TODO(roomtravel): test for TheWorld because it is eventually used in
		-- DungeonSave:SaveCurrentRoom, called via TravelCardinalDirection.  That likely needs to be "fixed"
		if TheWorld and TheDungeon and TheDungeon:GetDungeonMap() then
			local cardinal = TheDungeon:GetDungeonMap():GetCardinalDirectionForAdjacentRoomId(roomdata.roomID)
			if cardinal then
				TheLog.ch.Networking:printf("OnNetworkClientLoadRoom: TravelCardinalDirection %s at room id %d", cardinal, roomdata.roomID)
				TheDungeon:GetDungeonMap():TravelCardinalDirection(cardinal)
			end
		end
		RoomLoader.ClientLoadDungeonLevel(roomdata.worldPrefab, roomdata.sceneGenPrefab, roomdata.roomID)
	elseif roomdata.actionID == RESET_ACTION.LOAD_TOWN_ROOM then
		RoomLoader.ClientLoadTownLevel(roomdata.worldPrefab, roomdata.roomID)
	elseif roomdata.actionID == RESET_ACTION.DEV_LOAD_ROOM then
		RoomLoader.ClientDevLoadLevel(roomdata.worldPrefab)
	else
		TheLog.ch.Networking:printf("OnNetworkClientLoadRoom: Unhandled actionID")
		assert(false)
	end

	-- no entities for this simseqnr are available after this callback completes!
end

local function UpdateClientLoadRoom()
	if TheNet:IsHost() then
		return
	end

	if LoadingInProgress then	-- don't handle room changes if we're currently loading into a room. If we handle them now, the OnNetworkClientLoadRoom will just silently fail
		return
	end

	-- this function will only invoke the callback if a room change is happening
	-- It assumes that the lua side will successfully change rooms after this call, as it internally updates the simseqnr
	TheNet:ClientDoRoomChange(OnNetworkClientLoadRoom)
end

local function UpdateClientRoomLockState()
	if TheNet:IsHost() or not TheWorld or not TheNet:IsInGame() then
		return
	end

	local isLocked = TheNet:GetRoomLockState()
	if isLocked ~= TheWorld.components.roomlockable:IsLocked() then
		TheLog.ch.Networking:printf("UpdateClientRoomLockState: isLocked=%s", isLocked)
		TheWorld.components.roomlockable:SetClientRoomLockState(isLocked)
	end
end

local function UpdateClientRoomCompleteState()
	if TheNet:IsHost() or not TheWorld then
		return
	end

	local seqNr, isComplete, enemyHighWater, lastEnemyID = TheNet:GetRoomCompleteState()
	if seqNr ~= nil and seqNr > lastRoomCompleteAckSeqNr then
		if isComplete then
			local lastEnemyGUID = TheNet:FindGUIDForEntityID(lastEnemyID)
			-- TODO: networking2022, last_enemy isn't even used by clients -- see powerdropmanager.lua (OnRoomComplete)
			-- The enemy ID may be invalid by the time this event reaches clients
			TheLog.ch.Networking:printf("UpdateClientRoomCompleteState: seqNr=%d isComplete=%s enemyHighWater=%d lastEnemyGUID=%s",
				seqNr, isComplete, enemyHighWater, tostring(lastEnemyGUID))
			local lastEnemy = lastEnemyGUID and Ents[lastEnemyGUID] or nil
			TheWorld:PushEvent("room_complete",
				{
					["enemy_highwater"] = enemyHighWater,
					["last_enemy"] = lastEnemy,
				}
			)
		else
			TheLog.ch.Networking:printf("UpdateClientRoomCompleteState: seqNr=%d isComplete=%s", seqNr, isComplete)
		end
		lastRoomCompleteAckSeqNr = seqNr
	end
end

local function UpdateClientAmbientAudio()
	if TheWorld and TheWorld.components.ambientaudio then
		local new_level = TheNet:GetThreatLevel()
		local current_level = TheWorld.components.ambientaudio:GetThreatLevel()
		if new_level and new_level ~= current_level then
			TheWorld.components.ambientaudio:SetThreatLevel(new_level)
		end
	end
end

local function UpdateClientFocalPoint()
	if TheFocalPoint then
		local ents = TheNet:GetFocalPointEntitiesForEdgeDetection()
		if ents then
		 	TheFocalPoint.components.focalpoint:ClientSetEntitiesForEdgeDetection(ents)
		end
	end
end

local function UpdateClientHostState()
	UpdateClientLoadRoom()
end

local function UpdateGameplayClientHostState()
	UpdateClientRoomLockState()
	UpdateClientRoomCompleteState()
	UpdateClientAmbientAudio()
	UpdateClientFocalPoint()
end

local RoomBonusScreen = require("screens.dungeon.roombonusscreen")
local WaitingForPlayersScreen = require("screens.waitingforplayersscreen")
local Power = require 'defs.powers'


-- This function needs to get called every frame.
-- This will kick a client into different game modes:
function OnNetworkUpdate()
	if not TheNet:IsHost() then
		UpdateClientHostState()
	end

	-- If the waiting for players screen is up, call the CheckReadyToProgress function from here. The reason being that the OnUpdate() doesn't get called if another 
	-- screen pops up over top of it. This logic can't wait as it's for networked games. So call it from there:

	local screen = TheFrontEnd:FindScreen(WaitingForPlayersScreen)
	if screen then
		screen:CheckReadyToProgress()
	end


	if InGamePlay() and TheNet:IsInGame() then
		if not TheNet:IsHost() then
			UpdateGameplayClientHostState()
		end

		local mode, modeseqnr = TheNet:GetCurrentGameMode()

		if mode == GAMEMODE_GAMEOVER then
			if not TheDungeon.progression.components.runmanager:IsRunDefeat() then
				TheLog.ch.Network:printf("Run: Defeated")
				TheDungeon.progression.components.runmanager:Defeated()
			end
		elseif mode == GAMEMODE_ABANDON then
			if not TheDungeon.progression.components.runmanager:IsRunAbandon() then
				TheLog.ch.Network:printf("Run: Abandon")
				TheDungeon.progression.components.runmanager:Abandon()
			end
		elseif mode == GAMEMODE_VICTORY then
			if not TheDungeon.progression.components.runmanager:IsRunVictory() then
				TheLog.ch.Network:printf("Run: Victory")
				TheDungeon.progression.components.runmanager:Victory()
			end
		elseif mode ~= GAMEMODE_GAME then
			-- If the RoomBonusScreen is already active, check if it's
			local screen = TheFrontEnd:FindScreen( RoomBonusScreen )

			if screen and screen.seqnr and screen.seqnr ~= modeseqnr then
				-- The room bonus screen is still up, but it was for a different game mode seqnr.
				-- Make sure to call exit, and wait for the screen to be removed from the front end before starting a new one:
				screen:Exit()
			elseif not screen then
				-- screen was already active..
				if mode == GAMEMODE_RELICSELECT then
					-- If relic select screen is not active, make it active
					print("Network: Relic Select")
					local screen = RoomBonusScreen(Power.Types.RELIC)
					screen.seqnr = modeseqnr
					TheFrontEnd:PushScreen(screen)

				elseif mode == GAMEMODE_SKILLSELECT then
					-- If skill select screen is not active, make it active
					print("Network: Skill Select")
					local screen = RoomBonusScreen(Power.Types.SKILL)
					screen.seqnr = modeseqnr
					TheFrontEnd:PushScreen(screen)

				elseif mode == GAMEMODE_POWERFABLEDSELECT then
					-- If power fabled select screen is not active, make it active
					print("Network: Fabled Select")
					local screen = RoomBonusScreen(Power.Types.FABLED_RELIC)
					screen.seqnr = modeseqnr
					TheFrontEnd:PushScreen(screen)
				else
					-- This relies on the game screens individually switching back to the game when done
				end
			end
		end
	end
end

------------------------------------------------------------------------------

-- Make pseudo-random RNG derived from the current room seed (or fixed seed) and a player/entity identifier
local function _CreateRNG(seed, id, name)
	assert(TheWorld)
	local room_seed = TheDungeon:GetDungeonMap():GetCurrentRoomSeed()
	seed = seed + 10 * (id or 0)
	if name then
		TheLog.ch.Random:printf("%s id %d Random Seeds: %d %d", name, id, room_seed, seed)
	end
	return krandom.CreateGenerator(room_seed, seed)
end

function CreatePlayerRNG(inst, seed, name)
	local player_id = inst.Network:GetPlayerID()
	assert(player_id)
	return _CreateRNG(seed, player_id, name)
end

function CreateEntityRNG(inst, seed, name)
	local entity_id = inst.Network:GetEntityID()
	assert(entity_id)
	return _CreateRNG(seed, entity_id, name)
end

------------------------------------------------------------------------------

local EffectEvents = require "effectevents"
local Enum = require "util.enum"
local ParticleSystemHelper = require "util.particlesystemhelper"
local SGCommon = require("stategraphs.sg_common")
local SGPlayerCommon = require("stategraphs.sg_player_common")
local soundutil = require("util.soundutil")
require("prefabs.fx_hits")
local monsterutil = require("util.monsterutil")

function HandleNetEventPlaySound(emitterGUID, eventName)
	local inst = Ents[emitterGUID]
	if inst and inst:IsValid() then
		inst.SoundEmitter:PlaySound(eventName)
	end
end

function HandleNetEventPlaySoundData(emitterGUID, params, instanceName, instigatorGUID)
	local inst = Ents[emitterGUID]
	local name = instanceName ~= "" and instanceName or nil
	local instigator = instigatorGUID ~= 0 and Ents[instigatorGUID] or nil
	if inst and inst:IsValid() then
		soundutil.HandlePlaySoundData(inst, params, name, instigator)
	end
	-- the return for this is normally the name of the event or generated name (see soundtracker.lua:13)
	-- since it is known data, save the effort of a return value and do it on the caller side
end

function HandleNetEventPlaySoundWithParams(emitterGUID, eventName, params, volume, autostop)
	local inst = Ents[emitterGUID]
	if inst and inst:IsValid() then
		soundutil.HandlePlaySoundWithParams(inst, eventName, params, volume, autostop)
	end
end

function HandleNetEventPlayCountedSound(emitterGUID, param)
	local inst = Ents[emitterGUID]
	if inst and inst:IsValid() then
		soundutil.HandlePlayCountedSound(inst, param)
	end
end

function HandleNetEventPlayWindowedSound(emitterGUID, instigatorGUID, eventName, volume, windowFrames)
	local inst = Ents[emitterGUID]
	local instigator = Ents[instigatorGUID]
	if inst and inst:IsValid() and instigator and instigator:IsValid() then
		local soundtracker = soundutil.FindSoundTracker(instigator)
		soundtracker:PlayWindowedSound(eventName, volume, inst, windowFrames)
	end
end

function HandleNetEventKillSound(emitterGUID, instanceName)
	local inst = Ents[emitterGUID]
	if inst and inst:IsValid() then
		inst.SoundEmitter:KillSound(instanceName)
	end
end

function HandleNetEventSetSoundInstanceParam(emitterGUID, instanceName, paramName, value)
	local inst = Ents[emitterGUID]
	if inst and inst:IsValid() then
		soundutil.HandleSetInstanceParameter(inst, instanceName, paramName, value)
	end
end

NetFXSlot = Enum{"DEFAULT", "POWER", "EXTRA", "PROJECTILE"}

function HandleNetEventFXAttach(parentGUID, prefab, background, slot, stopOnInterruptState)
	local inst = Ents[parentGUID]
	if not inst or not inst:IsValid() then
		return 0
	end
	local fx
	if slot == NetFXSlot.id.DEFAULT then
		-- TheLog.ch.NetworkEventManager:printf("Network HandleAttachSwipeFx parent GUID=%d fx_name=%s", parentGUID, prefab)
		fx = SGPlayerCommon.Fns.HandleAttachSwipeFx(inst, prefab, background, stopOnInterruptState)
	elseif slot == NetFXSlot.id.POWER then
		fx = SGPlayerCommon.Fns.HandleAttachPowerSwipeFx(inst, prefab, background, stopOnInterruptState)
	elseif slot == NetFXSlot.id.EXTRA then
		fx = SGPlayerCommon.Fns.HandleAttachExtraSwipeFx(inst, prefab)
	elseif slot == NetFXSlot.id.PROJECTILE then
		fx = SGPlayerCommon.Fns.HandleAttachPowerFxToProjectile(inst, prefab)
	else
		assert(false, "Unhandled NetFXSlot id: " .. slot)
	end
	return fx and fx.GUID or 0
end

function HandleNetEventFXDetach(parentGUID, background, slot, removeOnDetach)
	local inst = Ents[parentGUID]
	if not inst or not inst:IsValid() then
		return
	end
	if slot == NetFXSlot.id.DEFAULT then
		SGPlayerCommon.Fns.HandleDetachSwipeFx(inst, background, removeOnDetach)
	elseif slot == NetFXSlot.id.POWER then
		SGPlayerCommon.Fns.HandleDetachPowerSwipeFx(inst, background, removeOnDetach)
	elseif slot == NetFXSlot.id.EXTRA then
		SGPlayerCommon.Fns.HandleDetachExtraSwipeFx(inst, removeOnDetach)
	elseif slot == NetFXSlot.id.PROJECTILE then
		-- do nothing; projectiles should auto-remove themselves and child entities
	else
		assert(false, "Unhandled NetFXSlot id: " .. slot)
	end
end

function HandleNetEventFXDeath(parentGUID, isFocusAttack, attackTargetGUID, fxName, offsets)
	local inst = Ents[parentGUID]
	if not inst or not inst:IsValid() then
		return
	end
	local attackTarget = attackTargetGUID ~= 0 and Ents[attackTargetGUID] or nil
	if attackTarget and not attackTarget:IsValid() then
		return
	end
	EffectEvents.HandleEventFXDeath(inst, isFocusAttack, attackTarget, fxName, offsets)
end

function HandleNetEventFXHit(prefab, attackerGUID, targetGUID, xOffset, yOffset, dir, hitstopLevel, isPowerHit)
	local attacker = Ents[attackerGUID]
	local target = Ents[targetGUID]
	if attacker and attacker:IsValid() and target and target:IsValid() then
		if isPowerHit then
			local fx = HandleSpawnPowerHitFx(prefab, attacker, target, xOffset, yOffset, hitstopLevel)
			return fx and fx.GUID or 0
		else
			local fx = HandleSpawnHitFx(prefab, attacker, target, xOffset, yOffset, dir, hitstopLevel)
			return fx and fx.GUID or 0
		end
	end
	return 0
end

function HandleNetEventFXScorchMark(instGUID, focus, explo_scale, scorch_scale, scorch_rot, scorch_fade_scale)
	local inst = Ents[instGUID]
	if inst and inst:IsValid() then
		EffectEvents.HandleNetEventScorchMark(inst, focus, explo_scale, scorch_scale, scorch_rot, scorch_fade_scale)
	end
end

function HandleNetEventHitShudderStart(entityGUID, shudderAmount, animFrames)
	-- TheLog.ch.Networking:printf("HandleNetEventHitShudderStart ent=%s shudderAmount=%d animFrames=%d", entityGUID, shudderAmount, animFrames)
	local inst = Ents[entityGUID]
	if inst and inst:IsValid() and inst.components.hitshudder then
		inst.components.hitshudder:HandleDoShudder(shudderAmount, animFrames)
	end
end

function HandleNetEventHitShudderStop(entityGUID)
	-- TheLog.ch.Networking:printf("HandleNetEventHitShudderStop ent=%s", entityGUID)
	local inst = Ents[entityGUID]
	if inst and inst:IsValid() and inst.components.hitshudder then
		inst.components.hitshudder:HandleStop()
	end
end

function HandleNetEventParticlesStart(parentGUID, param)
	local inst = Ents[parentGUID]
	-- TheLog.ch.NetworkEventManager:printf("guid=%d fxName=%s instanceName=%s followSymbol=%s offset=(%1.2f,%1.2f,%1.2f) isChild=%s duration=%1.2f useEntityFacing=%s renderInFront=%s",
	-- 	parentGUID, fxName, instanceName, followSymbol,
	-- 	offset[1], offset[2], offset[3],
	-- 	tostring(isChild), duration, tostring(useEntityFacing), tostring(renderInFront))

	if inst and inst:IsValid() then
		local particles = ParticleSystemHelper.HandleEventSpawnParticles(inst, param)
		return particles and particles.GUID or 0
	end
	return 0
end

function HandleNetEventParticlesStop(parentGUID, instanceName)
	local inst = Ents[parentGUID]
	if inst and inst:IsValid() then
		if instanceName then
			local param = { name = instanceName }
			ParticleSystemHelper.HandleEventStopParticles(inst, param)
		else
			ParticleSystemHelper.HandleEventStopAllParticles(inst)
		end
	end
end

function HandleNetEventParticlesOneShotAtPosition(instigatorGUID, position, fxName, lifetime, param)
	local inst = Ents[instigatorGUID]
	if inst and inst:IsValid() then
		local pfx = ParticleSystemHelper.HandleMakeOneShotAtPosition(Vector3(position), fxName, lifetime, inst, param)
		if pfx then
			return pfx.GUID
		end
	end
	return 0
end

function HandleNetEventEffectStart(parentGUID, param)
	local inst = Ents[parentGUID]
	if inst and inst:IsValid() then
		local fx = EffectEvents.HandleEventSpawnEffect(inst, param)
		return fx and fx.GUID or 0
	end
	return 0
end

function HandleNetEventSGRunStopAutogen(entityGUID)
	local inst = Ents[entityGUID]
	if inst and inst:IsValid() and inst.sg then
		inst.sg:HandleSGRunStopAutogen()
	end
end

function HandleNetEventPlayGroundImpact(parentGUID, param)
	local inst = Ents[parentGUID]
	if inst and inst:IsValid() then
		local impact = SGCommon.Fns.HandlePlayGroundImpact(inst, param)
		return impact and impact.GUID or 0
	end
	return 0
end


NetworkShowHitboxDebug = false

local function DrawDebugHitboxShape(inst, hitbox_data, did_hit)
	local hitboxcomp = hitbox_data.params[1]

	local col = WEBCOLORS.RED
	if did_hit then
		col = WEBCOLORS.LIME
	end

	if hitbox_data.triggerfnname == "TriggerCircle" then
		local dist = hitbox_data.params[2]
		-- local rotation = hitbox_data.params[3]
		local radius = hitbox_data.params[4]
		local zoffset = hitbox_data.params[5] or 0.0

		local scale = inst.Transform:GetScale()

		dist = dist * scale
		radius = radius * scale
		zoffset = zoffset * scale

		local x, z = inst.Transform:GetWorldXZ()
		if dist ~= 0 then
			rot = math.rad(rot + hitboxcomp:CalculateRotation())
			x = x + dist * math.cos(rot)
			z = z - dist * math.sin(rot)
		end
		DebugDraw.GroundCircle(x, zoffset + z, radius, col, 1, 5.0)

	elseif hitbox_data.triggerfnname == "TriggerBeam" then
		local startdist = hitbox_data.params[2]
		local enddist = hitbox_data.params[3]
		local thickness = hitbox_data.params[4]
		local zoffset = hitbox_data.params[5] or 0.0

		local scale = inst.Transform:GetScale()

		startdist = startdist * scale
		enddist = enddist * scale
		thickness = thickness * scale
		zoffset = zoffset * scale

		local facing = inst.Transform:GetFacing()
		-- Now supports up to four-faced entities

		if facing == FACING_LEFT then
			startdist = -startdist
			enddist = -enddist
		elseif facing == FACING_UP or facing == FACING_DOWN then
			local startdist_new = -thickness
			local enddist_new = thickness
			local thickness_new = enddist
			local zoffset_new = startdist + enddist * (facing == FACING_DOWN and -1 or 1)

			startdist = startdist_new
			enddist = enddist_new
			thickness = thickness_new
			zoffset = zoffset_new
		end

		local x, z = inst.Transform:GetWorldXZ()
		DebugDraw.GroundRect(x + startdist, zoffset + z - thickness, x + enddist, zoffset + z + thickness, col, 1, 5.0)
--		local ents = self.inst.HitBox:FindHitBoxesInRect(x + startdist, zoffset + z - thickness, x + enddist, zoffset + z + thickness, self.padsize)
	end
end

function HandleNetEventApplyDamage(attackerGUID, targetGUID, attackTable, event)
	local attacker = Ents[attackerGUID]
	local target = Ents[targetGUID]

	if NetworkShowHitboxDebug then
		TheLog.ch.Networking:print("[HitboxDebug] HandleNetEventApplyDamage. attacker = " .. attackerGUID .. " target = " .. targetGUID)
	end

	if not attacker or not attacker:IsValid() or not target or not target:IsValid() then
		return
	elseif not attacker:IsLocalOrMinimal() and not target:IsLocalOrMinimal() then
		-- early exit if this client is an observer to this combat interaction (3P+ games)
		return
	elseif target:IsInLimbo() then
		TheLog.ch.Networking:printf("Warning: Attempted to apply damage to a target in limbo GUID %d EntityID %d (%s)",
			targetGUID, target.Network:GetEntityID(), target.prefab)
		return
	end

	local atk = Attack(attacker, target)

	for k, v in pairs(attackTable) do
		if k ~= "_attacker" and k ~= "_target" then
			atk[k] = v
		end
	end

	-- Client-authoritative hit-confirm for remote, non-player attackers:
	-- 1. test remote attacker hitbox triggers with target at its current location
	-- 2. test that current target hitflags match remote attack hitflags

	-- local hits are already confirmed and added to the ignore list of the hitbox; no point in
	-- checking again except perhaps for debugging purposes
	-- let players attacking non-players auto-hit confirm as well so they always seem fair
	-- non-players as targets occurs with cannon mortar shots
	local is_hit_confirmed = attacker:IsLocal() or (attacker:HasTag("player") and not target:HasTag("player")) or atk:IsForceRemoteHitConfirm()
	local hitbox_data = atk:GetHitBoxData()
	if not is_hit_confirmed and hitbox_data then
		-- restore component 'self' to params
		local hitbox_ent = atk:GetProjectile() or attacker
		hitbox_data.params[1] = hitbox_ent.components.hitbox
		local triggerfn = HitBoxManager:LookupFunction(hitbox_data.triggerfnname)

		hitbox_ent.components.hitbox.temp_allow_entity = target
		local ents = triggerfn(table.unpack(hitbox_data.params))
		hitbox_ent.components.hitbox.temp_allow_entity = nil

		if NetworkShowHitboxDebug then
			TheLog.ch.Networking:printf("[HitboxDebug] Hit box check.")
			dumptable(hitbox_data.params)

			DrawDebugHitboxShape(hitbox_ent, hitbox_data, ents ~= nil)
		end


		if ents then
			if NetworkShowHitboxDebug then
				TheLog.ch.Networking:print("[HitboxDebug] Detected hits with entities:")
				dumptable(ents)
			end

			for _i,ent in ipairs(ents) do
				if ent and ent == target then
					if NetworkShowHitboxDebug then
						TheLog.ch.Networking:print("[HitboxDebug] Hitting the target!")
					end

					if target.HitBox:IsInvincible() then -- TODO: handle utility hitboxes like HitBoxQueue:PostUpdate?
						-- Leaving this so we can still follow the thread in the future
						--ent:PushEvent("hitboxcollided_invincible", hitbox_ent.components.hitbox)
						EffectEvents.MakeNetEventPushHitBoxInvincibleEventOnEntity(attacker, target)
						is_hit_confirmed = false

						if NetworkShowHitboxDebug then
							TheLog.ch.Networking:print("[HitboxDebug] Invincible!")
						end
					else
						is_hit_confirmed = not target.components.hitflagmanager or target.components.hitflagmanager:CanAttackHit(atk)
					end
					break
				end
			end -- for
		end
	end

	if is_hit_confirmed then
		if NetworkShowHitboxDebug then
			TheLog.ch.Networking:print("[HitboxDebug] Hit Confirmed")
		end

		DoNetEventApplyDamage(atk, event)	-- in combat.lua
		if atk:IsRemoteAttack() and attacker:IsLocal() then
			-- TheLog.ch.Networking:printf("NetEventApplyDamage remote attack for %s", attacker)
			attacker.components.combat:PostApplyDamage(atk)
		end

		-- local attacking_entity = atk:GetProjectile() or attacker
		-- TheLog.ch.Combat:printf("Do network hit confirm: attacking_entity %s EntityID %d target %s EntityID %d",
		-- 	attacking_entity, attacking_entity.Network:GetEntityID(), target, target.Network:GetEntityID())
		SGCommon.Fns.ApplyHitConfirmEffects(atk)
	else
		if NetworkShowHitboxDebug then
			TheLog.ch.Networking:print("[HitboxDebug] NO HIT")
		end
	end
end

function HandleNetEventApplyHeal(attackerGUID, targetGUID, heal)
	local attacker = Ents[attackerGUID]
	local target = Ents[targetGUID]

	if not attacker or not attacker:IsValid() or not target or not target:IsValid() then
		return
	elseif not attacker:IsLocalOrMinimal() and not target:IsLocalOrMinimal() then
		-- early exit if this client is an observer to this combat interaction (3P+ games)
		return
	elseif target:IsInLimbo() then
		TheLog.ch.Networking:printf("Warning: Attempted to apply heal to a target in limbo GUID %d EntityID %d (%s)",
			targetGUID, target.Network:GetEntityID(), target.prefab)
		return
	end

	local hl = Attack(attacker, target)
	for k, v in pairs(heal) do
		if k ~= "_attacker" and k ~= "_target" then
			hl[k] = v
		end
	end

	if target and target.components.combat then
		target.components.combat:GetHealed(hl)
	end
	--	DoNetEventApplyHeal(hl, event)	-- in combat.lua
end

function HandleNetEventApplyPowerChargedDamage(attackerGUID, targetGUID, attackTable)
	local attacker = Ents[attackerGUID]
	local target = Ents[targetGUID]

	if not attacker or not attacker:IsValid() or not target or not target:IsValid() then
		return
	elseif not target:IsLocalOrMinimal() then
		-- early exit if this client is an observer to this combat interaction (3P+ games)
		return
	elseif target:IsInLimbo() then
		TheLog.ch.Networking:printf("Warning: Attempted to apply power charged damage to a target in limbo GUID %d EntityID %d (%s)",
			targetGUID, target.Network:GetEntityID(), target.prefab)
		return
	end

	local atk = Attack(attacker, target)

	for k, v in pairs(attackTable) do
		if k ~= "_attacker" and k ~= "_target" then
			atk[k] = v
		end
	end

	-- TheLog.ch.Networking:printf("HandleNetEventApplyPowerChargedDamage attacker %s target %s", attacker, target)
	target:PushEvent("power_charged_damage", atk)
end

function HandleNetEventApplyPower(attackerGUID, targetGUID, powerDefName, powerStacks)
	local attacker = Ents[attackerGUID]
	local target = Ents[targetGUID]

	if not attacker or not attacker:IsValid() or not target or not target:IsValid() then
		return
	elseif not attacker:IsLocalOrMinimal() and not target:IsLocalOrMinimal() then
		-- early exit if this client is an observer to this combat interaction (3P+ games)
		return
	elseif target:IsInLimbo() then
		TheLog.ch.Networking:printf("Warning: Attempted to apply power to a target in limbo GUID %d EntityID %d (%s)",
			targetGUID, target.Network:GetEntityID(), target.prefab)
		return
	end

	local power_def = Power.FindPowerByName(powerDefName) --slow?
	if power_def then
		target.components.powermanager:AddPower(target.components.powermanager:CreatePower(power_def), powerStacks)
		-- target.components.powermanager:AddPowerByName(powerDefName, powerStacks)
	end
end

function HandleNetEventApplyPowerChargedDamage(attackerGUID, targetGUID, attackTable)
	local attacker = Ents[attackerGUID]
	local target = Ents[targetGUID]

	if not attacker or not attacker:IsValid() or not target or not target:IsValid() then
		return
	elseif not target:IsLocalOrMinimal() then
		return
	elseif target:IsInLimbo() then
		TheLog.ch.Networking:printf("Warning: Attempted to apply power charged damage to a target in limbo GUID %d EntityID %d (%s)",
			targetGUID, target.Network:GetEntityID(), target.prefab)
		return
	end

	local atk = Attack(attacker, target)

	for k, v in pairs(attackTable) do
		if k ~= "_attacker" and k ~= "_target" then
			atk[k] = v
		end
	end

	target:PushEvent("power_charged_damage", atk)
end

function HandleNetEventSetupProjectile(projectileGUID, ownerGUID, targetGUID)
	local projectile = Ents[projectileGUID]
	local owner = Ents[ownerGUID]
	local target = targetGUID and Ents[targetGUID] or nil
	if target and not target:IsValid() then
		target = nil
	end

	if projectile and projectile:IsValid() and projectile.Setup and owner and owner:IsValid() then
		monsterutil.HandleBasicProjectileSetup(projectile, owner, target)
	end
end

function HandleNetEventEntityTeardownFunction(entGUID, otherGUID, params)
	local ent = Ents[entGUID]
	local other = otherGUID and Ents[otherGUID] or nil

	if other and not other:IsValid() then
		other = nil
	end

	if ent:IsValid() then
		-- TheLog.ch.Networking:printf("Entity Lifetime Function: Teardown attacker = %s", other)
		ent:HandleTeardown(other, params) -- other is 'attacker', optional
	end
end


function HandleEntitySetup(entGUID, otherGUID, params)
	local ent = Ents[entGUID]
	local other = otherGUID and Ents[otherGUID] or nil

	if other and not other:IsValid() then
		other = nil
	end

	if ent and ent:IsValid() and ent.HandleSetup then
		ent:HandleSetup(other, params) -- other is 'owner', required?
	end
end

-- this is only called for loot drops with only remote players
-- local loot is handled through the typical generate, drop flow via various
-- state changes to time with enemy death effects, etc.
-- see NetworkEventImplementations.cpp for details
function HandleNetEventGenerateLoot(spawningEntityGUID, lootToDrop, luckyLoot, ignore_post_death)
	local inst = Ents[spawningEntityGUID]
	-- TheLog.ch.Networking:printf("HandleNetEventGenerateLoot from %s", tostring(spawningEntityGUID))
	-- dumptable(lootToDrop, nil, 3)
	-- dumptable(luckyLoot, nil, 3)
	if inst and inst:IsValid() then
		LootEvents.HandleEventGenerateLoot(inst, lootToDrop, luckyLoot, ignore_post_death)
	end
end

function HandleNetEventSpawnLocalEntity(parentGUID, prefabname, initialstate)
	local inst = Ents[parentGUID]
	if inst and inst:IsValid() then
		EffectEvents.HandleEventSpawnLocalEntity(inst, prefabname, initialstate)
	end
end

function HandleNetEventRequestSpawnCurrency(deadEntityGUID)
	-- TheLog.ch.Networking:printf("HandleNetEventRequestSpawnCurrency guid=%s", tostring(deadEntityGUID))
	local deadEntity = Ents[deadEntityGUID]
	if deadEntity and deadEntity:IsValid() then
		LootEvents.HandleEventRequestSpawnCurrency(deadEntity)
	end
end

function HandleNetEventSpawnCurrency(amount, pos, ownerGUID, isLucky, showAmount)
	-- TheLog.ch.Networking:printf("HandleNetEventSpawnCurrency: %d pos=%1.2f,%1.2f,%1.2f GUID=%s isLucky=%s showAmount=%s",
	-- 	amount, pos[1], pos[2], pos[3], tostring(ownerGUID), tostring(isLucky), tostring(showAmount))
	local owner = ownerGUID and Ents[ownerGUID] or nil
	LootEvents.HandleEventSpawnCurrency(amount, Vector3(pos), owner, isLucky, showAmount)
end


function HandleNetEventPushEventOnMinimalEntity(parentGUID, eventname, parameters)
	local inst = Ents[parentGUID]
	if inst and inst:IsValid() and inst:IsMinimal() then
		EffectEvents.HandleNetEventPushEventOnMinimalEntity(inst, eventname, parameters)
	end
end

function HandleNetEventPushEventOnOwnerEntity(ownerGUID, projectileGUID, eventname, parameters)
	local owner = Ents[ownerGUID]
	local projectile = Ents[projectileGUID]
	if owner and owner:IsValid() and owner:IsLocal() and projectile and projectile:IsValid() then
		parameters.projectile = projectile
		owner:PushEvent(eventname, parameters)
	end
end

function HandleNetEventPushHitBoxInvincibleEventOnEntity(attackerGUID, targetGUID)
	local attacker = Ents[attackerGUID]
	local target = Ents[targetGUID]

	if attacker and attacker:IsValid() and target and target:IsValid() then
		EffectEvents.HandleNetEventPushHitBoxInvincibleEventOnEntity(attacker, target)
	end
end

function HandleNetEventPlayCinematic(parentGUID, actors_table)
	local inst = Ents[parentGUID]

	if inst and inst:IsValid() and inst:IsMinimal() then
		EffectEvents.HandleNetEventPlayCinematic(inst, actors_table)
	end
end



function HandleNetEventKill(attackerGUID, targetGUID, attackTable)
	local attacker = Ents[attackerGUID]
	local target = Ents[targetGUID]

	if not attacker or not attacker:IsValid() or not target or not target:IsValid() then
		return
	end

	if not attacker:IsLocal() then	-- Needs to be a local attacker
		return
	end

	local atk = Attack(attacker, target)

	for k, v in pairs(attackTable) do
		if k ~= "_attacker" and k ~= "_target" then
			atk[k] = v
		end
	end

	DoNetEventKill(atk)	-- in combat.lua
end

function HandleNetEventSpawnCharmedCreature(spawnerGUID, deadEntityToCharmGUID)
	local spawner = Ents[spawnerGUID]
	local deadEntity = Ents[deadEntityToCharmGUID]

	if not spawner or not spawner:IsValid() or not deadEntity or not deadEntity:IsValid() then
		return
	end

	DoSpawnCharmedCreature(spawner, deadEntity)	-- in summonpowers.lua
end

function HandleNetEventDamageNumber(targetGUID, value, numSources, activeNumbers, isFocus, isCrit, isHeal, isPlayer, isSecondaryAttack, playerID)
	local target = Ents[targetGUID]
	if not target or not target:IsValid() then
		return nil
	end

	local num_widget = TheDungeon.HUD:HandleDamageNumber(target, value, numSources, activeNumbers, isFocus, isCrit, isHeal, isPlayer, isSecondaryAttack, playerID)
	return num_widget.inst.GUID
end

function HandleNetEventFlickerColor(targetGUID, color, numticks, fade, addTweens, symbol)
	local target = Ents[targetGUID]
	if not target or not target:IsValid() then
		return
	end

	if symbol then
		SGCommon.Fns.HandleFlickerSymbolBloom(target, symbol, color, numticks, fade, addTweens)
	else
		SGCommon.Fns.HandleFlickerColor(target, color, numticks, fade, addTweens)
	end
end

function HandleNetEventDeathStat(targetGUID)
	local target = Ents[targetGUID]
	if not target or not target:IsValid() or not target.components.health then
		return
	end

	target.components.health:UpdateDeathStats()

	-- this helps speed up wave and room clear notifications in a network game
	if TheNet:IsHost() and TheWorld.components.roomclear then
		TheWorld.components.roomclear:AfterDespawn(target)
	end
end

function HandleNetEventHealthBarReveal(targetGUID)
    local target = Ents[targetGUID]
    if not target or not target:IsValid() or not target.follow_health_bar then
        return
    end

    target.follow_health_bar:ShowHealthBar()
end

function HandleNetEventHitStreakUpdate(targetGUID, hitstreak, damagetotal)
	local target = Ents[targetGUID]
	if not target or not target:IsValid() then
		return
	end

	-- TheLog.ch.Networking:printf("[Combat] HitStreakUpdate: target=%s hitstreak=%s damagetotal=%s", target, hitstreak, damagetotal)
	target:PushEvent("hitstreak", { hitstreak = hitstreak, damagetotal = damagetotal })
end

local DUMMY_ATTACKIDS <const> = {}
local DUMMY_TARGETS <const> = {}
function HandleNetEventHitStreakKilled(targetGUID, hitstreak, damagetotal)
	local target = Ents[targetGUID]
	if not target or not target:IsValid() then
		return
	end

	target:PushEvent("hitstreak_killed",
		{
			hitstreak = hitstreak,
			damage_total = damagetotal,
			-- attack ids are not synced and only used for player progression things like masteries
			attacks = target:IsLocalOrMinimal() and target.components.combat:GetHitStreakAttackIDs() or DUMMY_ATTACKIDS,

			-- attack targets are not synced and only used for player progression things like masteries
			targets = target:IsLocalOrMinimal() and target.components.combat:GetHitStreakTargets() or DUMMY_TARGETS,
		})
end

function HandleNetEventHitStreakDecay(targetGUID, decaytime)
	local target = Ents[targetGUID]
	if not target or not target:IsValid() then
		return
	end

	target:PushEvent("hitstreakdecay", { hitstreakdecaytime = decaytime })
end

function HandleNetEventDeposit(vendingMachineGUID, playerID, amount)
--	print("HandleNetEventDeposit called. PlayerID="..playerID.." Amount="..amount)
	local vendingMachine = Ents[vendingMachineGUID]
	if not vendingMachine or not vendingMachine:IsValid() then
		return
	end

	vendingMachine.components.vendingmachine:OnNetDepositCurrency(playerID, amount)
end

function HandleNetEventRequestSinglePickup(pickupGUID, playerID)
--	print("HandleNetEventDeposit called. PlayerID="..playerID.." Amount="..amount)
	local pickup = Ents[pickupGUID]
	if not pickup or not pickup :IsValid() or not pickup.components.singlepickup then
		return
	end

	local player = Ents[TheNet:FindGUIDForPlayerID(playerID)]
	pickup.components.singlepickup:OnNetPickup(player)
end


function HandleNetEventSpawnPowerPopup(targetGUID, powername, hide_description, disable_tooltip, scale, offset_y)
	local target = Ents[targetGUID]

	if target then 
		--inst.sg.mem.power_popup = 
		TheDungeon.HUD:MakePowerPopup({ target = target, power = powername, hide_description = hide_description, scale = scale, offset_y = offset_y, disable_tooltip = disable_tooltip })
	end
end



-- Called for local and remote players.
function OnPlayerEntered(playerGUID)
    local inst = Ents[playerGUID]
	TheLog.ch.Player:printf("OnPlayerEntered for guid %s. Player <%s>", playerGUID, inst)

	-- Players don't spawn through SpawnPrefab, so they don't get instigator set.
	inst:_SetSpawnInstigator(inst)

	-- playerentered: When a local or remote player actually exists in the level.
	TheWorld:PushEvent("playerentered", inst) -- listen on world if you only exist in the current room.
	TheDungeon:PushEvent("playerentered", inst) -- listen on dungeon if you SurviveRoomTravel.
	inst:PushEvent("playerentered")
	-- TODO: reorder above events to fire on the player first to follow playeractivated and fire on broadest scope last.
	if not inst:IsLocal() then
		TheDungeon:PushEvent("player_fully_constructed", inst) -- Also fired for locals after additional setup.
	end
end


function OnValidateQuestCompleted(playerID, contentID, objectiveID, state)
    -- The intent of this is anti-cheat.
    -- It is only run on the host's machine.
    -- In an ideal world, we would check if the player who completed the quest could have possibly done so.
    -- However, we do not actually know the state of that player's quest central if they are remote, so we cannot check this.
    -- For now, return true.
    return true
end

function OnHostQuestCompleted(playerID, contentID, objectiveID, state)
    local playerutil = require"util.playerutil"
    playerutil.DoForAllLocalPlayers(function(player)
        player.components.questcentral:OnHostQuestCompleted(playerID, contentID, objectiveID, state)
    end)
end

function OnHostNotification(messageType, playerName)
	if messageType == MESSAGETYPE_FEEDBACKREQUEST then
		print("Host requested everybody send feedback")
		local feedback = require "feedback"
		if TheNet:IsHost() then
			feedback.StartFeedback(STRINGS.UI.FEEDBACK_SCREEN.ABOUT_HOSTREQUEST)
		else
			-- Since the host won't wait for us to finish writing and may boot
			-- us out before we send feedback, only send automatically from
			-- clients.
			feedback.AutoSendFeedback(STRINGS.UI.FEEDBACK_SCREEN.ABOUT_HOSTREQUEST)
		end

	else
		if playerName then
			if messageType == MESSAGETYPE_PLAYERJOINED then
				print("Player joined")
				TheFrontEnd:ShowTextNotification("images/ui_ftf_notifications/playerjoined.tex", nil, STRINGS.UI.NETWORK.PLAYER_JOINED_TEXT:subfmt({ player = playerName, }), 5)
			elseif messageType == MESSAGETYPE_PLAYERLEFT then
				print("Player Left")
				TheFrontEnd:ShowTextNotification("images/ui_ftf_notifications/playerleft.tex", nil, STRINGS.UI.NETWORK.PLAYER_LEFT_TEXT:subfmt({ player = playerName, }), 5)
			elseif messageType == MESSAGETYPE_PLAYERKICKED then
				print("Player Kicked")
				TheFrontEnd:ShowTextNotification("images/ui_ftf_notifications/playerleft.tex", nil, STRINGS.UI.NETWORK.PLAYER_KICKED_TEXT:subfmt({ player = playerName, }), 5)
			end
		end
	end
end


-- Called for both remote messages and our own messages.
function OnChatMessage(senderClientID, senderName, message, isWhisper)
	if not TheDungeon then
		TheLog.ch.Networking:print("Received chat message before we even have TheDungeon! Ignoring it.")
		return false
	end

	--find the first player on this client and use their color
	local color = UICOLORS.WHITE
	local clients = TheNet:GetPlayerListForClient(senderClientID)
	local playerGUID = TheNet:FindGUIDForPlayerID(clients[1])
	local sender
	if playerGUID then
		sender = Ents[playerGUID]
		color = sender.uicolor
	end

	message = message:sanitize_user_text()
	senderName = senderName:sanitize_user_text()

	if message:len() > 0 then
		local pretty_msg = string.format("<#%s>%s</>: %s", HexToStr(RGBToHex(color)), senderName, message)
		TheDungeon.components.chathistory:ReceiveChatMessage(pretty_msg, sender)
	end

	return true
end

function OnSoleOccupantsReceivedOnClient(sole_occupants)
	SpawnCoordinator.EnforceSoleOccupancy(sole_occupants)
end

---- Helper Functions ----

function GetPlayerEntityFromPlayerID(playerID)
    local playerGUID = TheNet:FindGUIDForPlayerID(playerID)
    return playerGUID and Ents[playerGUID] or nil
end

-- See also playerutil.GetFirstLocalPlayer()
function GetFirstLocalPlayer()
	local local_players = TheNet:GetLocalPlayerList()
	local player = #local_players > 0 and GetPlayerEntityFromPlayerID(local_players[1])
	return player
end

-- Return the difference between a local & remote network sequence number
function CompareNetworkSequenceNumber(local_num, remote_num, num_bits)
	local max_number = 2 ^ num_bits - 1

	-- Sequence number not initialized; return minimum of 1
	if not local_num then
		return math.min(remote_num + 1, max_number)
	end

	if remote_num < local_num then
		return max_number + 1 + remote_num - local_num
	else
		return remote_num - local_num
	end
end


function IsReadyForInvite()
	local active_screen = TheFrontEnd:GetActiveScreen()
	if active_screen and active_screen.is_a and active_screen:is_a(ConfirmDialog) then
		return false	-- A confirmation dialog is up, so wait with handling the invite 
	end

	if PerformingRestart or SimTearingDown or SimShuttingDown then
		return false	-- If the game is resetting itself, don't handle the invite yet
	end

	return true
end


function JoiningInvite()
	ShowConnectingToGamePopup()
end


-- there is a native version of this that needs to stay updated
PlayerDataChangedFlags =
{
	Unlocks = 0x1,
	Ascension = 0x2,
	Cosmetics = 0x4,
	HeartLevels = 0x8,
	CharacterCreator = 0x10,

	All = 0xFF,
}

function OnNetworkPlayerDataChanged(playerID, isRemoteData, dataChangedFlags)
	TheLog.ch.Networking:printf("Player data changed for player %s.  RemoteData=%s  Flags=0x%X",
		playerID, tostring(isRemoteData), dataChangedFlags)

	local ent = GetPlayerEntityFromPlayerID(playerID)
	if ent and ent:IsValid() then
		ent:PushEvent("playerdatachanged", dataChangedFlags)
	end
end

function OnNetworkWorldDataChanged(isRemoteData)
	TheLog.ch.Networking:print("World data changed. RemoteData = " .. tostring(isRemoteData))
end


function GetNetworkJoinCode()
	local joincode = TheNet:GetJoinCode()

	if joincode and joincode ~= "" and TheGameSettings:Get("network.streamer_mode") then
		joincode = "*****"	-- Redacted
	end
	return joincode
end



-- Need to return the entityID of the spawned prop, or 0 if not valid
function OnTownPropPlaceRequest(playerID, propname, x, z, flipped, variation)	-- Only called on host
	print("OnTownPropPlaceRequest playerID=" .. playerID .. " Prop=" .. propname .. " X=" .. tostring(x) .. " Z=" .. tostring(z) .. " Flipped=" .. tostring(flipped) .. " Variation=" .. tostring(variation))

	if TheWorld ~= nil and TheWorld:HasTag("town") then
		local def = Constructable.FindItem(propname)
		if def ~= nil then
			-- Right now we have no way of retrieving the grid size of a prop without spawning it
			-- so we're spawning a temp placer as a workaround
			local placer = SpawnPrefab(propname .. "_placer")
			placer.Transform:SetPosition(x, 0, z)
			if placer.components.placer:CanPlace() then
				local spawned = SpawnPrefab(propname)
				spawned.Transform:SetPosition(x,0,z)
				spawned:AddTag(placer.components.placer:GetDecorTag())
				if flipped then
					spawned.components.prop:FlipProp()
				end
				if variation then
					spawned.components.prop:SetVariationOverride(variation)
				end

				placer:Remove()
				return spawned.Network:GetEntityID()
			end
		end
	end

	return 0;
end

-- If resultEntityID == 0, the prop was NOT placed
-- if resultEntityID != 0, the prop was placed using the given entityID. (Entity might not be spawned yet because of unreliable network packets, though)
function OnTownPropPlaceResult(playerID, propname, resultEntityID)
	print("OnTownPropPlaceResult playerID=" .. playerID .. " Prop=" .. propname .. " ID=" .. tostring(resultEntityID))
	local player = Ents[TheNet:FindGUIDForPlayerID(playerID)]
	if player then
		if resultEntityID == 0 then
			player:PushEvent("placement_failed")
		else
			player:PushEvent("placement_sucessful", { entityID = resultEntityID, propname = propname })
		end
	end
end


-- Need to return true if removed, false if not
function OnTownPropRemoveRequest(playerID, propEntityID) -- Only called on host
	print("OnTownPropRemoveRequest playerID=" .. playerID .. " PropEntityID=" .. tostring(propEntityID))
	if TheWorld ~= nil and TheWorld:HasTag("town") then
		-- TODO: Copied from revive component. Consider making this a common function.
		local guid = TheNet:FindGUIDForEntityID(propEntityID)
		if guid and guid ~= 0 and Ents[guid] and Ents[guid]:IsValid() then
			local prop = Ents[guid]
			prop:Remove()
			return true
		end
	end

	return false;
end


function OnTownPropRemoveResult(playerID, propEntityID, successBool)
	print("OnTownPropRemoveResult playerID=" .. playerID .. " PropEntityID=" .. tostring(propEntityID) .. " Result=" .. tostring(successBool))
	local player = Ents[TheNet:FindGUIDForPlayerID(playerID)]
	if player then
		if successBool then
			player:PushEvent("onremovesuccessful", {entityID = propEntityID})
		else
			player:PushEvent("onremovefailed", {entityID = propEntityID})
		end
	end

end





-- Possible locations for rich presence:
-- (if you want more, they will need to be added on the native side for security reasons)
Location_None = 0
Location_GreatRotwoodForest = 1
Location_NocturneGrove = 2
Location_BlisterbaneBog = 3
Location_TheMoldedGrave = 4

-- Possible roomtype for rich presence:
RoomType_Normal = 0
RoomType_Market = 1
RoomType_Potion = 2

-- Possible frenzy types for rich presence:
-- (if you want more, they will need to be added on the native side for security reasons)
FrenzyType_Frenzy0 = 0
FrenzyType_Frenzy1 = 1
FrenzyType_Frenzy2 = 2
FrenzyType_Frenzy3 = 3
		

function GetRichPresenceDetails()
	local loc = Location_None
	local roomtype = RoomType_Normal
	local frenzy = FrenzyType_Frenzy0
	local progress = 0.0
	local valid = TheWorld ~= nil

	if TheDungeon and TheWorld then
		if not TheDungeon:IsInTown() then
			frenzy = TheDungeon.progression.components.ascensionmanager:GetCurrentLevel()	-- Should map to 0-3
			
			local locid = TheDungeon:GetCurrentLocationID()
			if locid == "treemon_forest" then
				loc = Location_GreatRotwoodForest
			elseif locid == "owlitzer_forest" then
				loc = Location_NocturneGrove
			elseif locid == "bandi_swamp" then
				loc = Location_BlisterbaneBog
			elseif locid == "thatcher_swamp" then
				loc = Location_TheMoldedGrave
			end

			local room_type = TheWorld:GetCurrentRoomType()
			if room_type == "potion" then 
				roomtype = RoomType_Potion
			elseif room_type == "market" then 
				roomtype = RoomType_Market
			end
		end
	
		if TheWorld then
			progress = TheWorld:GetDungeonProgress()
		end
	end

	return valid, loc, roomtype, frenzy, progress
end
