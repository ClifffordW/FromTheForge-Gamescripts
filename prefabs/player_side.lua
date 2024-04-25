local Cosmetic = require "defs.cosmetics.cosmetics"
local EffectEvents = require "effectevents"
local Equipment = require "defs.equipment"
local LootEvents = require "lootevents"
local PlayerPlacer = require "components.playerplacer"
local PlayerStatsFXer = require "components.playerstatsfxer"
local Power = require "defs.powers"
local SGPlayerCommon = require "stategraphs.sg_player_common"
local Weight = require "components.weight"
local easing = require "util.easing"
local fmodtable = require "defs.sound.fmodtable"
local lume = require "util.lume"
local prefabutil = require "prefabs.prefabutil"
local playerutil = require "util.playerutil"

PER_PLAYER_SILHOUETTE_COLOR = false
PLAYER_SILHOUETTE_ALPHA = 0.2

--------------------------------------------------------------------------
--Construction/Destruction helpers
--------------------------------------------------------------------------

local function ActivatePlayer(inst)
	inst.activatetask = nil
	dbassert(inst:IsLocal(), "Isn't ActivatePlayer only for local players?")

	-- playeractivated: When a local player is ready for use. You probably want player_fully_constructed.
	inst:PushEvent("playeractivated")
	TheWorld:PushEvent("playeractivated", inst) -- listen on world if you only exist in the current room
	TheDungeon:PushEvent("playeractivated", inst) -- listen on dungeon if you SurviveRoomTravel.

	-- playerentered fires too early for local players (they don't have
	-- playercontroller or input devices yet). This later event is after
	-- they've responded to their activation events.
	TheDungeon:PushEvent("player_fully_constructed", inst) -- Also fired for remotes from networking.
end

local function DeactivatePlayer(inst)
	if inst.activatetask ~= nil then
		inst.activatetask:Cancel()
		inst.activatetask = nil
		return
	end

	inst:PushEvent("playerdeactivated")
	TheWorld:PushEvent("playerdeactivated", inst)
	TheDungeon:PushEvent("playerdeactivated", inst)
end

local function SetPlayerColor(inst, skin_rgb)
	skin_rgb = skin_rgb or inst.skincolor
	-- GetHunterId won't exist until after we're done creating because it
	-- relies on Network which isn't added until after prefab construction.
	local player_index = inst.GetHunterId and inst:GetHunterId() or 1
	inst.playercolor = UICOLORS.PLAYERS[player_index] or UICOLORS.PLAYER_UNKNOWN
	inst.uicolor = UICOLORS.PLAYERS[player_index] or UICOLORS.PLAYER_UNKNOWN
	inst.skincolor = skin_rgb or UICOLORS.PLAYER_UNKNOWN

	if inst.components.playerhighlight then
		inst.components.playerhighlight:SetPlayer(inst)
	end

	if inst.components.playerplacer then
		inst.components.playerplacer:SetPlayer(inst)
	end

	-- To make the player 'pop' a bit more in the environment, let's nudge them a bit brighter.
	-- They should 'pop' off the screen a bit more than the environment, other creatures, etc.
	if inst:IsLocal() then
		inst.AnimState:SetBrightness(1.2)
	--	inst.AnimState:SetSaturation(1.1)
	end

	assert(inst.uicolor)
end

local function GetColoredCustomUserName(inst, include_player_id)
	local name = inst:GetCustomUserName()
	local player_index = inst.GetHunterId and inst:GetHunterId()
	local player_id = ""
	if include_player_id then
		player_id = ("P%i "):format(player_index)
	end

	local color_key = player_index
	if not UICOLORS.PLAYERS[color_key] then -- this table matches the UICOLORS.PLAYER_X entries
		color_key = "UNKNOWN"
	end
	-- Color is UICOLORS.PLAYER_1, PLAYER_1, PLAYER_UNKNOWN...
	return ("<#PLAYER_%s>%s%s</>"):format(color_key, player_id, name)
end

local function OnPlayerEntered(inst)
	-- Only add to player list when ready to spawn to prevent accessing
	-- partially created players.
	-- AllPlayers index may not correspond to player/hunter id! (otherwise
	-- it could have holes)
	if not table.contains(AllPlayers, inst) then
		AllPlayers[#AllPlayers + 1] = inst
	else
		dbassert(false, "How were we already in AllPlayers? count: ".. #AllPlayers)
	end

	SetPlayerColor(inst)

	if inst.components.questcentral:IsCinematicDirector() then
		TheCamera:Snap()
	end
end

--------------------------------------------------------------------------

local function IsOnlyLocalPlayer(inst)
	return #TheNet:GetLocalPlayerList() == 1
end


local function OnSetOwner(inst)
	inst.name = inst.Network:GetClientName()
	inst.userid = inst.Network:GetUserID()
	inst.picking_character = true
	-- if not TheSaveSystem.cheats:GetValue("skip_new_game_flow") and TheNet:IsHost() and playerutil.CountLocalPlayers() == 1 then
	-- 	TheLog.ch.Audio:print ("***///***player_side.lua: We think this is a new game and heading to the intro quest. No delayed start of town music.")
	-- 	TheWorld.components.ambientaudio.is_new_game = true
	-- end

	local playerID = inst.Network:GetPlayerID()
	TheLog.ch.Player:printf("OnSetOwner for <%s> playerID=%s", inst, playerID);
	if not inst:IsSpectating() then
		TheNet:SetRunPlayerStatus(playerID, RUNPLAYERSTATUS_ACTIVE)
	end

	local on_player_set = function()

		inst.picking_character = nil
		-- give these every time, it's possible that they will change.

		-- Seems these are not using OnPostSpawn so they don't fire until we
		-- have a fully created and owned player?
		inst.components.huntunlocker:OnPostSetOwner() -- do this before questcentral so quests can respond.
		inst.components.questcentral:OnPostSetOwner()
		inst.components.powermanager:OnPostSetPlayerOwner()

		if TheWorld:HasTag("town") then
			inst.components.health:SetPercent(1)
			inst:PushEvent("enter_town")
		end

		if inst.components.progresstracker:GetValue("total_num_runs") == 0 then
			TheDungeon:PushEvent("new_game_started")
		end

		if not inst:IsInLimbo() then
			inst:Show()

			-- Show notifications telling the host about their sharecode and the players-screen
			if TheWorld
			and TheNet:IsHost()
			and TheNet:HasJoinCode()
			and TheNet:HasShownJoinCodePopup() == false then
				TheNet:CopyJoinCodeToClipboard()
				TheFrontEnd:ShowTextNotification("images/ui_ftf_notifications/sharecode.tex", STRINGS.UI.PLAYERSSCREEN.NOTIFICATION_CODE_COPIED_TITLE, string.format(STRINGS.UI.PLAYERSSCREEN.NOTIFICATION_CODE_COPIED_TEXT, GetNetworkJoinCode()), 8)
				local text = STRINGS.UI.PLAYERSSCREEN.NOTIFICATION_PLAYERS_SCREEN_TEXT
				if not TheInput:GetKeyboard():GetPlayer() then
					text = STRINGS.UI.PLAYERSSCREEN.NOTIFICATION_PLAYERS_SCREEN_TEXT_PAUSE
				end
				TheFrontEnd:ShowTextNotification("images/ui_ftf_notifications/playerscreen.tex", STRINGS.UI.PLAYERSSCREEN.NOTIFICATION_PLAYERS_SCREEN_TITLE, text, 12)
				TheNet:SetShownJoinCodePopup()
			end
		end

		inst:PushEvent("on_player_set")
		TheDungeon:PushEvent("on_player_set", inst)
	end

	if TheSaveSystem.cheats:GetValue("skip_new_game_flow") then
		TheSaveSystem.active_players:SetValue("quick_start", true)
	end

	if TheSaveSystem.active_players:GetValue("quick_start") then
		-- If there is only one local player, that player must be the "main" local player.
		if inst:IsOnlyLocalPlayer() then
			TheSaveSystem:LoadCharacterAsPlayerID(TheSaveSystem:GetLastSelectedCharacterSlot(), playerID)
			TheSaveSystem.active_players:SetValue("quick_start", false)
		end
	end

	inst.components.unlocktracker:GiveDefaultUnlocks()

	local slot = TheSaveSystem:GetCharacterForPlayerID(playerID)
	if slot ~= nil then
		local character_save = TheSaveSystem:LoadCharacterAsPlayerID(slot, playerID)
		local player_entity_data =  character_save ~= nil and character_save:GetValue("player")
		if player_entity_data ~= nil then
			inst:SetPersistData(player_entity_data)
		else
			inst.components.inventoryhoard:GiveDefaultEquipment()
		end
		inst:PostLoadWorld(player_entity_data)

		on_player_set()
	else
		-- the player character needs to have a weapon while the save slot is selected
		inst.components.inventoryhoard:GiveDefaultEquipment()

		inst:Hide()

		-- pick your character
		local CharacterSelectionScreen = require "screens.character.characterselectionscreen"
		local WaitingForSpawnScreen = require "screens.waitingforspawnscreen"
		local function on_close_screen()
			if inst:IsLocal() then
				TheFrontEnd:PushScreen(WaitingForSpawnScreen())
			end
			on_player_set()
		end
		local screen = CharacterSelectionScreen(inst, on_close_screen)
		screen:SetOnClickCloseFn(function()
			if TheNet:GetNrLocalPlayers() == 1 then
				-- This player just started a game, and they're cancelling picking a character
				-- Go to main menu
				TheFrontEnd:PopScreen(screen)
				TheWorld:PushEvent("quit_to_menu")
				RestartToMainMenu("save")
			else
				-- This game was already started, and a new player cancelled picking a character
				-- Remove that player and close the screen
				net_removeplayer(playerID)
				TheFrontEnd:PopScreen(screen)
			end
		end)
		TheFrontEnd:PushScreen(screen)
	end

	inst.activatetask = inst:DoTaskInTicks(0, ActivatePlayer)
end

local function OnRemoveEntity(inst)
	table.removearrayvalue(AllPlayers, inst)

	-- "playerexited" is available on both server and client.
	-- - On clients, this is pushed whenever a player entity is removed
	--   locally because it has gone out of range of your network view.
	-- - On servers, this message is identical to "ms_playerleft", since
	--   players are always in network view range until they disconnect.
	if TheWorld then -- can be invalid with dev reload and nosimreset
		TheWorld:PushEvent("playerexited", inst)
	end

	if inst.low_health and inst.low_health:IsValid() then
		inst.low_health:Remove()
	end
	inst.low_health = nil

	DeactivatePlayer(inst)
end

--------------------------------------------------------------------------
--Save/Load stuff
--------------------------------------------------------------------------
local function OnSave(inst, data)
	-- This is for saving in a world save, but we save our data through
	-- TheSaveSystem instead. See PlayerSave:Save().

	-- TEMP: Until players can name their own characters, give them a username
	-- nw TODO: move this to the c++ side
	if inst ~= GetDebugPlayer() then
		data._customusername = inst._customusername
	end

	data.mother_seed = TheDungeon:GetDungeonMap():GetMotherSeed()
end

local function OnPreLoad(inst, data)
end

local function OnLoad(inst, data)
	-- We generally don't save/load data for the player through the normal
	-- flow. Instead, we pull it out of TheSaveSystem once the player is
	-- assigned an owner (so we know which data to load). See OnSetOwner.

	if inst.components.timer:HasTimer("potion_cd") then
		inst:PushEvent("refreshpotiondata")
	end

	if data then
		-- TEMP: Until players can name their own characters, give them a username
		-- nw TODO: move this to the c++ side
		if data._customusername and inst ~= GetDebugPlayer() then
			inst:SetCustomUserName(data._customusername)
		end

		local current_run_mother_seed = TheDungeon:GetDungeonMap():GetMotherSeed()
		if not data.mother_seed or data.mother_seed ~= current_run_mother_seed then
			TheLog.ch.Player:printf("Player data mother seed (%s) doesn't match current run (%s).  Pushing start new run event.",
				tostring(data.mother_seed), tostring(current_run_mother_seed))
			inst:PushEvent("start_new_run")
		end
	end
end

local function OnPostLoadWorld(inst, data)
	-- force another refresh of player portrait after everything has been init'd
	inst:PushEvent("player_post_load")
end

--------------------------------------------------------------------------
--Spawing stuff
--------------------------------------------------------------------------

--Player cleanup usually called just before save/delete
--just before the the player entity is actually removed
local function OnDespawn(inst)
	inst.components.playercontroller:SetEnabled(false)
	inst.components.locomotor:Stop()
end

-- display relevant player info around the character, like a health bar
local function PeekFollowStatus(inst, options, auto_fade)
	options = options or {}

	local follow_status = inst.follow_status
	if follow_status and inst:GetHunterId() then

		if options.show_potion then
			follow_status:TryShowPotion(auto_fade)
		end

		if options.show_id then
			follow_status:TryShowID(auto_fade)
		end

		if options.show_radial then
			follow_status:TryShowRadial(auto_fade)
		end

		if options.do_input_identifier then
			follow_status:TryShowID(auto_fade)
			follow_status:DoShake()
		end

		-- local data =
		-- {
		-- 	shake = options.doInputIdentifier,
		-- 	force_show_potion = options.show_potion,
		-- 	show_id = options.show_id,
		-- 	show_radial = options.show_radial,
		-- }

		-- follow_status:Reveal(data, auto_fade)
	end
end

-- show emotes in a ring around the player
local function PeekEmoteRing(inst, options)
	options = options or {}

	if inst.emote_ring and inst:GetHunterId() then
		inst.emote_ring:OnEmoteKey(options.toggleMode)
	end
end

local function PeekPlayerLoadout(inst, options)
	options = options or {}

	if inst.loadout_ui and inst:GetHunterId() then
		inst.loadout_ui:OnLoadoutKey(options.toggleMode)
	end
end

local function OnRoomComplete(inst, world, data)
	-- revive players that were knocked out during a room battle to 1hp
	-- however, don't allow weird post-defeat room completions to trigger this
	-- if TheDungeon.HUD and not TheDungeon.HUD.is_showing_defeat then
	-- 	if inst:IsLocal() and not inst:IsAlive() then
	-- 		inst.components.health:SetRevivable()
	-- 		inst.components.health:SetRevived()
	-- 	end
	-- end
end

--------------------------------------------------------------------------
-- Roll Speed/Distance modification
local function UpdateTotalRollSpeedMult(inst)
	local total = 1
	for id, bonus in pairs(inst.roll_speed_mults) do
		total = total + bonus
	end
	local old_total = inst.total_roll_speed_mult
	inst.total_roll_speed_mult = math.max(total, 0)

	if old_total ~= inst.total_roll_speed_mult then
		self.inst:PushEvent("speed_mult_changed", { new = inst.total_roll_speed_mult, old = old_total })
	end
end

local function AddRollSpeedMult(inst, source_id, bonus)
	inst.roll_speed_mults[source_id] = bonus
	self:UpdateTotalRollSpeedMult()
end

local function RemoveRollSpeedMult(inst, source_id)
	self.roll_speed_mults[source_id] = nil
	self:UpdateTotalRollSpeedMult()
end

local function GetTotalRollSpeedMult(inst)
	return inst.total_roll_speed_mult
end


--------------------------------------------------------------------------


--------------------------------------------------------------------------
--HUD/Camera/FE interface
--------------------------------------------------------------------------

local function ShakeCamera(inst, mode, duration, speed, scale, source_or_pt, maxdist)
	if source_or_pt ~= nil and maxdist ~= nil then
		local distsq = source_or_pt.entity ~= nil and inst:GetDistanceSqTo(source_or_pt) or inst:GetDistanceSqToXZ(source_or_pt:GetXZ())
		local k = math.max(0, math.min(1, distsq / (maxdist * maxdist)))
		scale = easing.outQuad(k, scale, -scale, 1)
	end

	--normalize for net_byte
	duration = math.floor((duration >= 16 and 16 or duration) * 16 + .5) - 1
	speed = math.floor((speed >= 1 and 1 or speed) * 256 + .5) - 1
	scale = math.floor((scale >= 8 and 8 or scale) * 32 + .5) - 1

	if scale > 0 and speed > 0 and duration > 0 then
		if TheCamera ~= nil then
			local playerId = inst:GetHunterId()
			local deviceId
			local playercontroller = inst.components.playercontroller
			-- TODO: input - maybe the camera shouldn't interface directly with input and instead go
			-- through playercontroller for rummble requests; that way hardware isn't exposed
			if playerId and playerId > 0
				and playercontroller:GetLastInputDeviceType() == "gamepad" and playercontroller.gamepad_id then
				deviceId = 1 << inst.components.playercontroller.gamepad_id
			end

			TheCamera:Shake(
				mode,
				(duration + 1) / 16,
				(speed + 1) / 256,
				(scale + 1) / 32,
				deviceId
			)
		end
	end
end

-- A numeric id that persists through a whole gameplay session. Won't change if
-- remote players drop. Generally, you should use this to display a numeric id,
-- but don't pass this to any network functions expecting a PlayerID (they are
-- different values).
--
-- Guaranteed to be greater than 0.
local function GetHunterId(inst)
	-- Currently based on network id, but that may change if we want this value
	-- bounded.
	return TheNet:IsInGame()
		and inst:IsValid() and inst.Network:GetPlayerID() + 1 -- playerIDs are zero-based
		or table.arrayfind(AllPlayers, inst)
end

local function GetDisplayName(inst)
	-- Player names aren't in STRINGS. We set name when the owner is set.
	return inst.name
end

local function SetCustomUserName(inst, username)
	TheLog.ch.Player:printf("SetCustomUserName = %s", username)
	inst._customusername = username
	inst:PushEvent("username_changed")
end

local function HasCustomUserName(inst)
	return inst._customusername ~= nil
end

local function GetCustomUserName(inst)
	if (inst._customusername ~= nil) then
		return inst._customusername
	end

	local playerID = TheNet:IsInGame() and inst.Network:GetPlayerID() or -1
	local player_name = TheNet:GetPlayerName(playerID) or ""
	return player_name:sanitize_user_text()
end

--------------------------------------------------------------------------

local function CanMouseThrough(inst)
	return true, true
end

--------------------------------------------------------------------------

local function OnInventoryTagsChanged(inst, data)
	if inst:IsLocal() and inst.sg == nil or data.slot == Equipment.Slots.WEAPON then
		local tag = inst.components.inventory:GetEquippedWeaponTag()
		if tag then
			local sgname = "sg_player_"..tag
			if inst.sg == nil or inst.sg.sg.name ~= sgname then
				if inst.sg ~= nil and not inst.sg:HasStateTag("idle") then
					inst.sg:GoToState("idle")
				end
				inst:SetStateGraph(sgname)
			end
		else
			TheLog.ch.Player:printf("Inventory didn't have a valid weapon tag (%s). Not setting stategraph.", tag)
		end

--		if inst.CanSpawnIntoWorld and not inst:CanSpawnIntoWorld() then
--			inst:SetSpectating(true)
--		end
	end
end

--------------------------------------------------------------------------

local function OnConversation(inst, data)
	if data ~= nil then
		if data.action == "start" and data.npc ~= nil then
			-- We've started a modal conversation.
			inst.components.locomotor:TurnToDirection(inst:GetAngleTo(data.npc))

			-- TODO remove these until I fix the issues around conversations and callbacks
			--inst:PushEvent("sheathe_and_wait")
		    -- elseif data.action == "end" then
			-- 	inst:PushEvent("unsheathe_stop_waiting")
		end
	end
end

--------------------------------------------------------------------------
-- NOTE: On event handlers below that GoToState, we must check for death first to handle wanderer cases where the below are done but HP is reduced.

local function OnPotionRefill(inst, data)
	inst:DoTaskInTime(0.25, function()
		if not inst.sg:HasStateTag("death") then
			inst.sg:GoToState("potion_refill_pre")
		end
	end)
end

--------------------------------------------------------------------------

local function OnUpgradePower(inst, data)
	inst:DoTaskInTime(0.25, function()
		if not inst.sg:HasStateTag("death") then
			inst.sg:GoToState("powerup_upgrade")
		end
	end)
end

--------------------------------------------------------------------------
local weight_to_dodge_fx = {
		[Weight.Status.s.Light] = "fx_iframe_dodge_light",
		[Weight.Status.s.Normal] = "fx_iframe_dodge_med",
		[Weight.Status.s.Heavy] = "fx_iframe_dodge_heavy",
}

local function OniFrameDodge(inst, _hitbox)
	if inst.iframefx == nil and inst.sg:HasStateTag("dodge") then
		local weight = inst.components.weight:GetStatus()
		local fx_name = weight_to_dodge_fx[weight] or weight_to_dodge_fx.Normal

		local flip = inst.Transform:GetFacingRotation() == 0
		local params =
		{
			fxname = fx_name,
			scalex = flip and -1.0 or 1.0,
			-- offx = 0 -- setting to 0, but leaving this here in case we want to adjust offsets
		}
		inst.iframefx = EffectEvents.MakeEventSpawnEffect(inst, params)
		if inst.iframefx ~= nil then -- In case MakeEventSpawnEffect returns no prefab for any reason.
			inst.iframefx:ListenForEvent("onremove", function()
				if inst ~= nil and inst:IsValid() then
					inst.iframefx = nil
				end
			end)
		else
			printf("WARNING: inst.iframefx is nil for some reason. MakeEventSpawnEffect returned no prefab. Tried spawning [%s] with weight [%s]", fx_name, weight)
		end
	end
end

-- Post Hit iFrames

local function OnBasicAttackedIframes(inst, data)
	-- This function is intended to apply iframes while being with a BasicAttack while in the middle of an attack.
	-- Knockback and Knockdown hits will cancel the player out of their attack states, and kick in their own iframes.

	-- "Hit" state, "Knockback" state, and "Knockdown" state all handle their own invincibility in their states themselves, if the player is not attacking.

	local attack = data.attack

	if not attack:BypassesPosthitInvincibility() and inst.sg:HasStateTag("attack") then
		inst.HitBox:SetInvincible(true)
		inst:DoTaskInAnimFrames(TUNING.PLAYER_POSTHIT_IFRAMES, function(inst)
			if inst ~= nil and inst:IsValid() then
				inst.HitBox:SetInvincible(false)
			end
		end)
	end


end
--------------------------------------------------------------------------


local RUN_STATE_TO_CINEMATIC =
{
	ENTER_TOWN = {
		ACTIVE = nil,
		VICTORY = "cine_town_spawn_victory",
		ABANDON = "cine_town_spawn_abandon",
		DEFEAT = "cine_town_spawn_defeat",
	},

	END_RUN = {
		ACTIVE = nil,
		VICTORY = "cine_dgn_pickup_abandon",
		ABANDON = "cine_dgn_pickup_abandon",
		DEFEAT = "cine_dgn_pickup_defeat",
	},
}

local function OnEnterTown(inst)
	if TheSaveSystem.cheats:GetValue("skip_town_spawn") then
		return
	end

	local state = inst.components.progresstracker:GetLastRunResult()
	local cine = RUN_STATE_TO_CINEMATIC.ENTER_TOWN[state]

	-- Only plays the cine for initial local host player
	if cine and inst.components.cineactor:CanPlayerStartCine() then
		inst.components.cineactor:PlayAsLeadActor(cine)
	end
end

local function _end_run(is_victory)
	TheDungeon:GetDungeonMap():ReturnToTown()
end

local function OnEndRun(inst, is_victory)
	-- Make the player invincible so they don't get hit out for whatever reason
	inst.HitBox:SetInvincible(true)

	local state = inst.components.progresstracker:GetLastRunResult()
	local cine = RUN_STATE_TO_CINEMATIC.END_RUN[state]

	if cine then
		inst:ListenForEvent("cine_end", function() _end_run(is_victory) end)

		-- Only plays the cine for initial local host player
		if inst.components.cineactor:CanPlayerStartCine() then
			inst.components.cineactor:PlayAsLeadActor(cine)
		end
	else
		_end_run(is_victory)
	end
end

--------------------------------------------------------------------------

local function CanSpawnIntoWorld(inst)
	if TheWorld then
		if TheWorld:HasTag("town") or TheDungeon:GetDungeonMap():IsDebugMap() then
			return true
		elseif inst.created_by_debugspawn or inst.in_embellisher then -- dev tools, embellisher, etc.
			return true
		end
		local player_id = inst.Network:GetPlayerID()
		if TheNet:WasPlayerInLastRoomChange(player_id) then
			return true
		end
	end

	return false
end

local function TrySpawnIntoWorld(inst)
	if inst:CanSpawnIntoWorld() then
		TheLog.ch.Player:printf("TrySpawnIntoWorld: SpawnAtEntrance")
		TheWorld.components.playerspawner:SpawnAtEntrance(inst)
	else
		TheLog.ch.Player:printf("TrySpawnIntoWorld: Spectating")
		inst:SetSpectating(true)
	end
end

local function SetSpectating(inst, enabled)
	if enabled and not inst.is_spectating then
		inst.is_spectating = true

		local player_id = inst.Network:GetPlayerID()
		TheLog.ch.Player:printf("Player %d GUID %d entering spectating state...", player_id, inst.GUID)
		inst:Hide()
		inst:RemoveFromScene()

		assert(inst.sg)
		if inst.sg:GetCurrentState() ~= "spectating" then
			inst.sg:GoToState("spectating")
		end
		inst:PushEvent("spectatingstart")

		inst.components.playercontroller:FlushControlQueue()
		TheNet:SetRunPlayerStatus(player_id, RUNPLAYERSTATUS_CORPSE)
	elseif not enabled and inst.is_spectating then
		inst.is_spectating = nil

		local player_id = inst.Network:GetPlayerID()
		TheLog.ch.Player:printf("Player %d GUID %d exiting spectating state...", player_id, inst.GUID)

		assert(inst.sg)
		if inst.sg:GetCurrentState() ~= "spectating" then
			inst.sg:GoToState("spectating")
		end
		inst:ReturnToScene()
		inst:Show()
		inst:PushEvent("spectatingstop")

		inst.components.playercontroller:FlushControlQueue()
		TheNet:SetRunPlayerStatus(player_id, RUNPLAYERSTATUS_ACTIVE)
	end
end

local function IsSpectating(inst)
	return inst.is_spectating
end

local function IsPickingCharacter(inst)
	return inst.picking_character
end

--------------------------------------------------------------------------

local function RefreshMouth(inst)
	local mouth = inst.components.charactercreator:GetBodyPart(Cosmetic.BodyPartGroups.MOUTH)
	local mouth_def = Cosmetic.BodyParts.MOUTH[mouth]
	inst.mouth.AnimState:SetBuild(mouth_def.build)

	local colour_id = inst.components.charactercreator:GetColor(Cosmetic.ColorGroups.SKIN_TONE)
	local colour = Cosmetic.Colors.SKIN_TONE[colour_id]

	local h, s, b = table.unpack(colour.hsb)
	inst.mouth.AnimState:SetSymbolColorShift("mouth01", h, s, b)
	inst.mouth.AnimState:SetSymbolColorShift("mouth_inner01", h, s, b)
end

local function CreateMouth(prefabname, bank, build)
	local inst = CreateEntity()
	-- TODO(roomtravel): Don't keep players between rooms yet. Same as below in fn.
	--~ :MakeSurviveRoomTravel()
	inst:SetPrefabName(prefabname)

	inst.entity:AddTransform()
	inst.entity:AddAnimState()
	inst.entity:AddFollower()

	inst:AddTag("FX")
	inst.persists = false

	inst.Transform:SetTwoFaced()

	inst.AnimState:SetBank(bank)
	inst.AnimState:SetBuild(build)
	inst.AnimState:PlayAnimation("neutral_mouth_talk", true)

	return inst
end

function MakePlayerMouth(name)
	local mouth_bank_file = "player_bank_emote_mouths"
	local mouth_build_file = "player_mouth_canine_flat_cat"

	local assets =
	{
		Asset("ANIM", "anim/"..mouth_bank_file..".zip"),
		Asset("ANIM", "anim/"..mouth_build_file..".zip"),
	}

	local mouth_bank = "player_emote_mouth"
	local mouth_build = mouth_build_file
	local function fn(prefabname)
		local inst = CreateMouth(prefabname, mouth_bank, mouth_build)
		return inst
	end

	return Prefab(name, fn, assets, nil, nil, NetworkType_None)
end

local function RefreshEmotes(inst)
	if not inst:IsLocal() then
		return
	end
	-- network multiplayer playtest sept 2023
	-- #MAKING_COSMETICS #MAKING_EMOTES
	-- Here I'm detecting what their species is, and then putting their species-specific emote into the RIGHT slot.
	-- Later we can do this in a more elegant way.
	-- I'm just giving the ogre a "emote_pump" for now, since there's no specific ogre one yet! Feel free to change

	-- Species Specific:
	local emote_slot = 3
	local species = inst.components.charactercreator:GetSpecies()
	if species == "ogre" then
		inst.components.playeremoter:EquipEmote(emote_slot, "emote_ogre_charged_jump")
	elseif species == "canine" then
		inst.components.playeremoter:EquipEmote(emote_slot, "emote_mammimal_howl")
	elseif species == "mer" then
		inst.components.playeremoter:EquipEmote(emote_slot, "emote_amphibee_bubble_kiss")
	end

	-- Weapon Specific:
	emote_slot = 5
	local weapon = inst.components.inventory:GetEquippedWeaponType()
	if weapon then
		if weapon == WEAPON_TYPES.HAMMER then
			inst.components.playeremoter:EquipEmote(emote_slot, "emote_hammer_twirl")
		elseif weapon == WEAPON_TYPES.POLEARM then
			inst.components.playeremoter:EquipEmote(emote_slot, "emote_polearm_twirl")
		elseif weapon == WEAPON_TYPES.CANNON then
			inst.components.playeremoter:EquipEmote(emote_slot, "emote_cannon_twirl")
		elseif weapon == WEAPON_TYPES.SHOTPUT then
			inst.components.playeremoter:EquipEmote(emote_slot, "emote_shotput_twirl")
		end
	end
end

local function SetTempData(inst, key, value)
	-- Data that does not save or network sync, used for logic that only needs to persist within the room.
	-- Typically used for conversation context.
	if not inst.temp_data then
		inst.temp_data = {}
	end
	inst.temp_data[key] = value or true
end

local function GetTempData(inst, key)
	return inst.temp_data and inst.temp_data[key]
end

-- UnlockTracker easy access functions

local function UnlockFlag(inst, flag)
	inst.components.unlocktracker:UnlockFlag(flag)
end

local function LockFlag(inst, flag)
	inst.components.unlocktracker:LockFlag(flag)
end

local function IsFlagUnlocked(inst, flag)
	return inst.components.unlocktracker:IsFlagUnlocked(flag)
end

local function UnlockWeaponType(inst, weapon_type)
	inst.components.unlocktracker:UnlockWeaponType(weapon_type)
end

local function IsWeaponTypeUnlocked(inst, weapon_type)
	return inst.components.unlocktracker:IsWeaponTypeUnlocked(weapon_type)
end

local function UnlockRecipe(inst, recipe)
	inst.components.unlocktracker:UnlockRecipe(recipe)
end

local function UnlockRegion(inst, region)
	inst.components.unlocktracker:UnlockRegion(region)
end

local function UnlockLocation(inst, location_id)
	inst.components.unlocktracker:UnlockLocation(location_id)
end

local function IsLocationUnlocked(inst, location_id)
	return inst.components.unlocktracker:IsLocationUnlocked(location_id)
end

local function HasEverCompletedQuest(inst, ...)
	return inst.components.questcentral:GetQuestManager():HasEverCompletedQuest(...)
end

local function HasEverCompletedQuestObjective(inst, ...)
	return inst.components.questcentral:GetQuestManager():HasEverCompletedQuestObjective(...)
end

local function HasDoneMastery(inst, ...)
	local mastery = inst.components.masterymanager:GetMasteryByName(...)
	return mastery and mastery:IsClaimed()
end

local function HasUnlockedMasteries(inst, ...)
	local should_unlock = false
	print(inst)
	for _, mastery_group in pairs(Mastery.Items) do		
		for _, def in pairs(mastery_group) do
			if def.default_unlocked and inst.components.masterymanager:GetMastery(def) == nil then
				fn(def)
			end
		end
	end	

	loop_all_default_masteries(function() should_unlock = true end)
	return should_unlock
end

local function MakePlayerCharacter(name, customprefabs, customassets, common_postinit, master_postinit)
	local assets =
	{
		Asset("ANIM", "anim/player_bank_basic.zip"),
		Asset("ANIM", "anim/player_bank_basic_2.zip"),
		Asset("ANIM", "anim/player_bank_ui.zip"),
		Asset("ANIM", "anim/player_bank_skills.zip"),
		Asset("ANIM", "anim/player_bank_skills_miniboss.zip"),
		Asset("ANIM", "anim/player_bank_emotes.zip"),
		Asset("ANIM", "anim/player_bank_flying_machine.zip"),

		Asset("ANIM", "anim/player_bank_hammer_emotes.zip"),
		Asset("ANIM", "anim/player_bank_polearm_emotes.zip"),
		Asset("ANIM", "anim/player_bank_cannon_emotes.zip"),
		Asset("ANIM", "anim/player_bank_shotput_emotes.zip"),

		Asset("ANIM", "anim/fx_player_weapon_smear.zip"),
		Asset("ANIM", "anim/fx_player_smear.zip"),
	}

	if not IS_BUILD_STRIPPED and DEV_MODE then
		assets[#assets + 1] = Asset("ANIM", "anim/1_player_master_template.zip")
	end

	local prefabs =
	{
		"player_side_mouth",

		"aim_pointer",
		"aim_pointer_p1",
		"aim_pointer_p2",
		"aim_pointer_p3",
		"aim_pointer_p4",
		"ground_indicator_p1",
		"ground_indicator_p2",
		"ground_indicator_p3",
		"ground_indicator_p4",
		"ground_indicator_ring_p1",
		"ground_indicator_ring_p2",
		"ground_indicator_ring_p3",
		"ground_indicator_ring_p4",
		"indicator_player_health",

		"cine_boss_death_hit_hold",  -- shared by all bosses
		"cine_main_defeat_megatreemon_intro",  -- queued from a quest
		"cine_play_miniboss_intro",  -- shared by all minibosses
		"cine_town_newgame",  -- more cine added below with RUN_STATE_TO_CINEMATIC

		GroupPrefab("fx_for_player"),
		GroupPrefab("fx_player"),
		GroupPrefab("player_skills"),
		"fx_heal_burst",
		"fx_hit_player_round",
		"fx_hurt_sweat",
		"fx_player_flask_smash_glass",
		"fx_player_flask_smash_impact",
		"fx_player_ground_smash_dust",
		"fx_player_ground_smash_ring",
		GroupPrefab("impacts"),
		"impact_dirt_small", -- default from SGCommon

		"fx_player_quickrise",
		"fx_stunned_headstars",
		GroupPrefab("fx_warning"),  -- I think we need this?
		GroupPrefab("healing"),

		"player_cannon_projectile",
		"player_cannon_mortar_projectile",
		"player_shotput_projectile",
		"fx_projectile_trail_shotput_air_very_fast",
		"fx_projectile_trail_shotput_air_fast",
		"fx_projectile_trail_shotput_air",
		"fx_projectile_trail_shotput_caught",

		"gem_crafting_table", -- DEMO HACK: this should ideally be loaded with Blacksmith, but no easy way to load with just them right now.

		GroupPrefab("hits_fx"),

		GroupPrefab("drops_generic"),
		GroupPrefab("drops_startingforest"),
		GroupPrefab("drops_swamp"),

		-- TODO: Aren't these already added by Equipment?
		GroupPrefab("fx_cannon"),
		GroupPrefab("fx_cannon_basic"),
		GroupPrefab("fx_cannon_electric"),

		-- for player powers
		GroupPrefab("player_power_prefabs"),
		GroupPrefab("deps_player_cosmetics"),

		"generic_projectile",
		"ground_target",

		"soul_drop_lesser",
		"soul_drop_greater",
		"soul_drop_heart",
	}

	-- TODO(memory): Player could load only basic build and equipment could
	-- load its builds.
	Equipment.CollectAssets(assets, prefabs)
	LootEvents.CollectAssets(assets, prefabs)
	PlayerPlacer.CollectAssets(assets, prefabs)
	PlayerStatsFXer.CollectAssets(assets, prefabs)
	prefabs = table.appendarrays(
		prefabs,
		lume.values(weight_to_dodge_fx),
		lume.values(RUN_STATE_TO_CINEMATIC.ENTER_TOWN),
		lume.values(RUN_STATE_TO_CINEMATIC.END_RUN))


	if customprefabs ~= nil then
		local prefabs_cache = {}
		for i, v in ipairs(prefabs) do
			prefabs_cache[v] = true
		end

		if customprefabs ~= nil then
			for i, v in ipairs(customprefabs) do
				if not prefabs_cache[v] then
					table.insert(prefabs, v)
					prefabs_cache[v] = true
				end
			end
		end
	end

	if customassets ~= nil then
		for i, v in ipairs(customassets) do
			table.insert(assets, v)
		end
	end

	local function SetInstanceFunctions(inst)
		-- we're bumping against the limit of upvalues in a lua function so work around by breaking this assignment out into its own function
		inst.OnRemoveEntity = OnRemoveEntity
		inst.ShakeCamera = ShakeCamera
	end

	local function TryStopSpectating(inst)
		local isLocked = TheNet:GetRoomLockState()
		local isPicking = inst.picking_character
		if not isLocked and not isPicking and inst:IsSpectating() then
			inst:SetSpectating(false)
		end
	end

	local function fn(prefabname)
		local inst = CreateEntity()
        -- TODO(roomtravel): Don't keep players between rooms yet. There's lots
        -- that we'd need to fix to support that (make their fx and quests
        -- survive, reconnect any world event handlers, resolve knockons) and
        -- it makes it less visible when we break c_reset.
		--~ :MakeSurviveRoomTravel()
		inst:SetPrefabName(prefabname)

		inst.entity:AddTransform()
		inst.entity:AddAnimState()
		inst.entity:AddSoundEmitter()
		inst.entity:AddHitBox()
		inst.HitBox:SetNonPhysicsRect(TUNING.PLAYER_HITBOX_SIZE)
		inst:ListenForEvent("hitboxcollided_invincible", OniFrameDodge)

		inst.Transform:SetTwoFaced()

		prefabutil.RegisterHitbox(inst, "main")

		inst.AnimState:SetBank("player")
		inst.AnimState:SetBuild("player_bank_basic")

		inst.serializeHistory = true	-- Tell it to precisely sync animations

		-- These are disabled to get rid of "could not find anim build FROMNUM"
		-- errors, but I'm not sure what they're for in the first place. These
		-- weapons work without them.
		--inst.AnimState:AddOverrideBuild("player_bank_hammer")
		--inst.AnimState:AddOverrideBuild("player_bank_polearm")
		--inst.AnimState:AddOverrideBuild("player_bank_cleaver")
		inst.AnimState:SetShadowEnabled(true)

		inst.AnimState:SetRimEnabled(true)
		inst.AnimState:SetRimSize(1.5)
		inst.AnimState:SetRimSteps(2)

		inst.AnimState:SetSilhouetteColor(0/255, 0/255, 0/255, PLAYER_SILHOUETTE_ALPHA)
		inst.AnimState:SetSilhouetteMode(SilhouetteMode.Have)

		MakeCharacterPhysics(inst, .3) --Character physics small so that walking through groups of enemies is easy

		inst:AddTag("player")
		inst:AddTag("character")

		SetInstanceFunctions(inst)

		inst:ListenForEvent("setowner", OnSetOwner)

		inst:ListenForEvent("playerentered", OnPlayerEntered)

		if common_postinit ~= nil then
			common_postinit(inst)
		end

		inst.userid = ""

		inst.CanMouseThrough = CanMouseThrough

		inst.persists = false --handled in a special way

		inst:AddComponent("locomotor")
		inst:AddComponent("forcedlocomote")
		inst:AddComponent("playercontroller")
		inst:AddComponent("interactor")

		inst:AddComponent("pushforce")
		--inst.components.pushforce:AddPushForceModifier("weight", 1)

		if not TheDungeon:GetDungeonMap():IsDebugMap() then
			inst:AddComponent("fadeforeground")
		end
		inst:AddComponent("bloomer")
		inst:AddComponent("colormultiplier")
		inst:AddComponent("coloradder")
		inst:AddComponent("hitstopper")
		inst:AddComponent("hitshudder")

		inst:AddComponent("health")
		inst.components.health:SetMax(TUNING.PLAYER_HEALTH, true)
		inst.components.health:SetLowHealthPercent(0.2)

		inst:AddComponent("weight")

		inst:AddComponent("revive")

		inst:AddComponent("lowhealthindicator")

		inst:AddComponent("hitbox")
		inst.components.hitbox:SetHitGroup(HitGroup.PLAYER)
		inst.components.hitbox:SetHitFlags(HitGroup.CREATURES | HitGroup.RESOURCE)

		inst:AddComponent("combat")
		inst:AddComponent("combatplayersync")	-- component to sync specific parts of the combat component
		inst.components.combat:SetHurtFx("fx_hurt_sweat")
		inst.components.combat:SetHasKnockback(true)
		inst.components.combat:SetHasKnockdown(true)
		inst.components.combat:SetBlockKnockback(true)
		inst.components.combat:SetHasBlockDir(true)
		inst.components.combat:AddTargetTags(TargetTagGroups.Enemies)
		inst.components.combat:AddTargetTags(TargetTagGroups.Neutral)
		inst.components.combat:AddFriendlyTargetTags(TargetTagGroups.Players)
		inst.components.combat:AddFriendlyTargetTags(TargetTagGroups.Neutral)

		inst:AddComponent("hittracker")
		inst:AddComponent("hitflagmanager")

		inst:AddComponent("playerstatsfxer")
		inst:AddComponent("playerroller")

		-- Player identifiers:
		inst:AddComponent("playerhighlight")
		inst:AddComponent("playerplacer")
		inst:AddComponent("propremover")
		inst:AddComponent("aimindicator")

		inst:AddComponent("timer")
		inst:AddComponent("damagebonus")
		inst:AddComponent("potiondrinker")
		inst:ListenForEvent("potion_refilled",OnPotionRefill)

		inst:AddComponent("foodeater")

		inst:AddComponent("usetracker")

		inst.uicolor = UICOLORS.PLAYER_UNKNOWN
		inst.skincolor = UICOLORS.PLAYER_UNKNOWN

		-- charactercreator may invoke this in its constructor, so we need to listen before then.
		inst:ListenForEvent("update_skin_color", function(inst, rgb)
			SetPlayerColor(inst, rgb)
			-- Once we have the color configured, send another event for ui to listen to.
			inst:PushEvent("update_ui_color", inst.uicolor)
		end)
		inst:AddComponent("charactercreator", true)

		inst:AddComponent("equipmentdyer")

		inst:AddComponent("lucky")
		inst:AddComponent("lootdropmanager")
		inst:AddComponent("inventory")
		inst:AddComponent("inventoryhoard")
		-- inst:AddComponent("lifetimewatcher")
		inst:AddComponent("playercrafter")
		inst:AddComponent("lootvacuum")

		inst:AddComponent("powermanager")

		inst:ListenForEvent("power_upgraded",OnUpgradePower)
		inst:ListenForEvent("enter_room", function(inst) inst.components.powermanager:RefreshPowerAttackFX() end)

		inst:AddComponent("gemmanager")
		inst:AddComponent("heartmanager")

		inst:AddComponent("masterymanager")

		inst:AddComponent("dungeontracker")
		inst:AddComponent("progresstracker")

		inst:AddComponent("ghosttrail")

		inst:AddComponent("metaprogressmanager")

		inst:AddComponent("unlocktracker")

		inst:AddComponent("hasseen")
		inst:AddComponent("hasmade")

		inst.SetTempData = SetTempData
		inst.GetTempData = GetTempData

		-- unlocktracker easy access functions --
		inst.UnlockFlag = UnlockFlag
		inst.LockFlag = LockFlag
		inst.IsFlagUnlocked = IsFlagUnlocked
		inst.UnlockWeaponType = UnlockWeaponType
		inst.IsWeaponTypeUnlocked = IsWeaponTypeUnlocked
		inst.UnlockRecipe = UnlockRecipe
		inst.UnlockRegion = UnlockRegion
		inst.UnlockLocation = UnlockLocation
		inst.IsLocationUnlocked = IsLocationUnlocked

		inst.HasEverCompletedQuest = HasEverCompletedQuest
		inst.HasEverCompletedQuestObjective = HasEverCompletedQuestObjective

		inst.HasDoneMastery = HasDoneMastery

		inst:AddComponent("cineactor")

		--~ inst:AddComponent("talkaudio")
		inst:AddComponent("foleysounder")
		inst.components.foleysounder:SetFootstepSound(fmodtable.Event.base_layer)
		inst.components.foleysounder:SetFootstepStopSound(fmodtable.Event.Dirt_run_stop)
		inst.components.foleysounder:SetHandSound(fmodtable.Event.Dirt_hand)
		inst.components.foleysounder:SetJumpSound(fmodtable.Event.Dirt_jump)
		inst.components.foleysounder:SetLandSound(fmodtable.Event.Dirt_land)
		inst.components.foleysounder:SetBodyfallSound(fmodtable.Event.Dirt_bodyfall)
		inst.components.foleysounder:SetSize("medium")

		inst:AddComponent("soundtracker")

		inst:AddComponent("entityocclusion")
		inst.components.entityocclusion:SetOccluderTags({"large", "giant"})
		inst:ListenForEvent("occluded", function(me, data) me:PeekFollowStatus({ show_id = true }, true) end)

		inst.low_health = SpawnPrefab("indicator_player_health", inst)
		inst.low_health:WatchHealth(inst)

		inst:AddComponent("scalable")

		if HITSTUN_VISUALIZER_ENABLED then
			inst:AddComponent("hitstunvisualizer")
		end

		inst:AddComponent("playeremoter")
		inst.components.playeremoter:EquipEmote(1, "emote_pump")
		--inst.components.playeremoter:EquipEmote(2, "emote_wave")
		--inst.components.playeremoter:EquipEmote(3, "emote_whistle")
		--inst.components.playeremoter:EquipEmote(5, "emote_no_thx")
		--inst.components.playeremoter:EquipEmote(8, "emote_dejected")
		inst.components.playeremoter:EquipEmote(7, "emote_over_here")

		inst:ListenForEvent("enter_town", OnEnterTown)
		inst:ListenForEvent("end_run_sequence", function(_, is_victory) OnEndRun(inst, is_victory) end, TheWorld)

		inst:ListenForEvent("attacked", OnBasicAttackedIframes) -- ONLY applies iframes from BasicAttacks while the player is mid-attack. iframes for other attack types are applied in the state themselves, i.e. knockback or knockdown

		inst:AddComponent("playerbusyindicator")
		inst:AddComponent("worldbounded")

		-- Roll Speed Modification
		inst.AddRollSpeedMult = AddRollSpeedMult
		inst.RemoveRollSpeedMult = RemoveRollSpeedMult
		inst.UpdateTotalRollSpeedMult = UpdateTotalRollSpeedMult
		inst.GetTotalRollSpeedMult = GetTotalRollSpeedMult
		inst.roll_speed_mults = {}

		inst:DoTaskInTime(0, function()
			inst.mouth = SpawnPrefab("player_side_mouth")
			inst.mouth.entity:SetParent(inst.entity)
			inst.mouth.Follower:FollowSymbol(inst.GUID, "snapTo_mouth")
			inst.mouth:ListenForEvent("sfx-speech_blah", function() inst:PushEvent("speech_blah") end)
			inst.mouth:Hide()
			inst:ListenForEvent("update_skin_color", RefreshMouth)

			inst:ListenForEvent("charactercreator_load", RefreshMouth)

			RefreshMouth(inst)
			inst:PushEvent("mouthacquired")
		end)

		inst:ListenForEvent("charactercreator_load", RefreshEmotes)
		inst:ListenForEvent("loadout_changed", RefreshEmotes)

		inst:AddComponent("interactable")
		inst:AddComponent("playertitleholder")

		inst:AddComponent("questcentral")

		inst:AddComponent("tilehazard")
		inst.components.powermanager:EnsureRequiredComponents()

		inst:AddComponent("huntunlocker")
		inst:AddComponent("grabbag")

		if master_postinit ~= nil then
			master_postinit(inst)
		end

		assert(not inst.OnLoad)
		assert(not inst.OnSave)
		assert(not inst.OnPreLoad)
		assert(not inst.OnLoad)
		assert(not inst.OnDespawn)
		inst.OnSave = OnSave
		inst.OnPreLoad = OnPreLoad
		inst.OnLoad = OnLoad
		inst.OnPostLoadWorld = OnPostLoadWorld
		inst.OnDespawn = OnDespawn
		inst.GetDisplayName = GetDisplayName
		inst.GetHunterId = GetHunterId -- can't actually call until construction completes!
		inst.PeekFollowStatus = PeekFollowStatus
		inst.PeekEmoteRing = PeekEmoteRing
		inst.PeekPlayerLoadout = PeekPlayerLoadout

		inst.GetColoredCustomUserName = GetColoredCustomUserName
		inst.GetCustomUserName = GetCustomUserName
		inst.HasCustomUserName = HasCustomUserName
		inst.SetCustomUserName = SetCustomUserName

		inst.CanSpawnIntoWorld = CanSpawnIntoWorld
		inst.TrySpawnIntoWorld = TrySpawnIntoWorld
		inst.SetSpectating = SetSpectating
		inst.IsSpectating = IsSpectating
		inst.TryStopSpectating = TryStopSpectating
		inst.IsPickingCharacter = IsPickingCharacter

		inst.IsOnlyLocalPlayer = IsOnlyLocalPlayer

		inst.DebugNodeName = "DebugPlayer"

		inst:ListenForEvent("on_player_set", function()
			inst:TryStopSpectating()
		end)

		inst:ListenForEvent("room_unlocked", function()
			inst:TryStopSpectating()
		end, TheWorld)

		inst:ListenForEvent("created_by_debugspawn", function()
			-- When debug spawned, we shouldn't behave like a real player.
			if AllPlayers[#AllPlayers] == inst then
				AllPlayers[#AllPlayers] = nil
			end
			inst.OnRemoveEntity = nil -- prevent "playerexited"
			inst.created_by_debugspawn = true
		end)

		inst.offscreen = { urgent = false, silent = true, puppetPlayer = inst, puppetScale = 0.35 }

		return inst
	end

	return Prefab(name, fn, assets, prefabs, nil, NetworkType_ClientAuth)
end

--------------------------------------------------------------------------

local function common_postinit(inst)
end

local function master_postinit(inst)
	inst.tuning = TUNING.player
	inst.components.locomotor:SetRunSpeed(inst.tuning.run_speed)

	OnInventoryTagsChanged(inst)
	inst:ListenForEvent("inventorytagschanged", OnInventoryTagsChanged)

	inst:ListenForEvent("conversation", OnConversation)

	-- HACK(worldgen): https://quire.io/w/Sprint_Tracker/969/Split_player_save_data_into_dungeon_and_town
	-- local hack_is_new_run = TheDungeon:GetDungeonMap():IsCurrentRoomDungeonEntrance()
	-- if hack_is_new_run then
	-- 	inst:DoTaskInTicks(2, function(inst_)
	-- 		if inst.components.powermanager ~= nil and next(inst.components.powermanager.powers) then
	-- 			TheLog.ch.Player:print("HACK! Looks like debug start run was used and we have left over powers. Firing start_new_run.")
	-- 			inst:PushEvent("start_new_run")
	-- 		end
	-- 	end)
	-- end

	inst:ListenForEvent("room_complete", function(world, data) OnRoomComplete(inst, world, data) end, TheWorld)

	inst._onhealthchanged_corpse = function()
		local playerID = inst.Network:GetPlayerID()
		TheNet:SetRunPlayerStatus(playerID, RUNPLAYERSTATUS_ACTIVE)
		inst:RemoveEventCallback("revived", inst._onhealthchanged_corpse)
	end

	inst:ListenForEvent("start_new_run", function()
		-- TODO: someone -- this may be handled in a non-deterministic order with powermanager's event handler for this event
		-- All players have the lucky revive power
		local pm = inst.components.powermanager
		local def = Power.FindPowerByName("lucky_revive")
		local power = pm:CreatePower(def)
		pm:AddPower(power)
	end)

	inst:ListenForEvent("becomecorpse", function()
		local playerID = inst.Network:GetPlayerID()
		TheNet:SetRunPlayerStatus(playerID, RUNPLAYERSTATUS_CORPSE)
		inst:ListenForEvent("revived", inst._onhealthchanged_corpse)
	end)

	inst:ListenForEvent("revivable", function()
		local playerID = inst.Network:GetPlayerID()
		TheNet:SetRunPlayerStatus(playerID, RUNPLAYERSTATUS_CORPSE)
		inst:ListenForEvent("revived", inst._onhealthchanged_corpse)
	end)

	-- Handler for when a player disconnects while reviving another player.
	TheWorld:ListenForEvent("playerexited", function(TheWorld, reviver)
		if inst.components.revive and inst.components.revive.reviver == reviver then
			inst.components.revive:_ReviveeCancelReviving()
		end
	end)

	SGPlayerCommon.Fns.SetupReviveInteractable(inst)
end

return MakePlayerCharacter("player_side", nil, nil, common_postinit, master_postinit),
	MakePlayerMouth("player_side_mouth")
