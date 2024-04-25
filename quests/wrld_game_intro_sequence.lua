local Quest = require "questral.quest"
local Convo = require "questral.convo"
local playerutil = require "util.playerutil"
local biomes = require "defs.biomes"
local RoomLoader = require "roomloader"

local quest_helper = require "questral.game.rotwoodquestutil"
local quest_strings = require("strings.strings_npc_scout").QUESTS.game_start

------QUEST SETUP------

local Q = Quest.CreateJob()
	:SetWorldQuester()

function Q:Quest_EvaluateSpawn(quester)
	return TheNet:IsHost()
end

------CAST DECLARATIONS------

Q:UpdateCast("giver")
	:FilterForPrefab("npc_scout")

------OBJECTIVE DECLARATIONS------

local function _TryStartIntroRun(quest)
	-- This should trigger on first loading the game to look like a seamless
	-- load into the dungeon (instead of town). We can't be seamless if there
	-- were other players around.

	if not TheWorld:HasTag("town") then return end

	if not TheSaveSystem.cheats:GetValue("skip_new_game_flow") and TheNet:IsHost() and playerutil.CountLocalPlayers() == 1 then
		-- Allow HasRemotePlayers so host sees new game flow: otherwise if
		-- remote p2 joins before host p1 finishes creating character, everyone
		-- spawns in town. We should prevent joining until your player spawns.
		local intro_location_id <const> = "treemon_forest"
		assert(biomes.locations[intro_location_id])
		local intro_dungeon_run_params =
		{
			location_id = intro_location_id,
			region_id = biomes.locations[intro_location_id].region_id,
			alt_mapgen_id = 2, -- treemon_forest_tutorial1
			ascension = 0,
		}

		RoomLoader.StartRun(intro_dungeon_run_params)
	else
		quest:Complete("game_intro")
	end
end

local has_started_intro = false -- this will be reset if the player quits to menu

local function _force_spawn_giver()
	TheDungeon.progression.components.meetingmanager:EvaluateSpawnNPC_Dungeon(TheDungeon:GetDungeonMap():GetBiomeLocation())
	TheDungeon.progression.components.meetingmanager:OnStartRoom()
end

local function _TrySetupScoutIntro(quest, player)
	if not has_started_intro and not TheWorld:HasTag("town") then
		-- TheWorld.components.ambientaudio.is_new_game = true
		local giver = quest_helper.GetGiver(quest)

		if not giver.inst then
			_force_spawn_giver()
		end

		if not giver.inst then
			TheLog.ch.Quest:printf("_force_spawn_giver failed to find a spawner_npc_dungeon to trigger. InGamePlay[%s] room[%s]", InGamePlay(), TheDungeon.room)
			return
		end

		giver.inst.components.markablenpc:AddMarkCondition("quest_active", function(player) return true end)
		TheWorld:PushEvent("refresh_markers", { npc = giver.inst })

		TheDungeon.progression.components.runmanager:SetCanAbandon(false)

		local allow_cine = player.components.questcentral:IsCinematicDirector()
		if allow_cine then
			giver.inst.components.cineactor:QueueIntro("cine_main_defeat_megatreemon_intro")
			TheWorld.components.ambientaudio:StopAllMusic()
		end

		has_started_intro = true
		TheWorld:PushEvent("starting_intro_quest")
	end
end

local function _DEBUG_COMPLETE_QUEST(quest)
	quest:Complete()
end

Q:AddObjective("game_intro")
	:UnlockWorldFlagsOnComplete{ "wf_did_intro_sequence" }	-- UnlockFlag("wf_did_intro_sequence")	Leave this comment here, so that this flag gets picked up by the exportflags.lua tool
	:SetIsImportant()
	:OnEvent("on_player_set", _TryStartIntroRun)
	:OnEvent("playerentered", _TrySetupScoutIntro)
	:OnEvent("end_current_run", _DEBUG_COMPLETE_QUEST)
	:InitialState(QUEST_OBJECTIVE_STATE.s.ACTIVE)
	:AppearInDungeon_Entrance()
	:OnComplete(function(quest)
		quest:Complete()
		local giver = quest_helper.GetGiver(quest)
		if giver and giver.inst then
			giver.inst.components.markablenpc:RemoveMarkCondition("quest_active")
			TheWorld:PushEvent("refresh_markers", { npc = giver.inst })
		end
	end)

local has_local_player_talked = false

Q:OnDungeonChat("game_intro", "giver", function(quest, node, sim, convo_target)
		local in_correct_room = Quest.Filters.InDungeon_Entrance(quest, node, sim, convo_target)
		return in_correct_room and not has_local_player_talked
	end)
	-- :ForbiddenWorldFlags{ "wf_did_intro_sequence" }
	:SetPriority(Convo.PRIORITY.HIGHEST)
	:Strings(quest_strings)
	-- We define a function that takes cx: a ConvoPlayer. When this convo
	-- activates, it'll call this function. Most steps in the function yield so
	-- they don't all happen immediately.
	:Fn(function(cx)
		local Opt3AClicked = false

		local function ReusedSequence(cx)
			if Opt3AClicked == false then
				cx:Opt("OPT_3A")
					:Fn(function()
						cx:Talk("OPT3A_RESPONSE")
						Opt3AClicked = true
						ReusedSequence(cx)
					end)
			end

			local function EndConvo(opt_str, response_str)
				cx:AddEnd(opt_str)
					:Fn(function()
						cx:Talk(response_str)
	                    -- should only effect other players on the local machine
	                    has_local_player_talked = true
	                    -- force quest marks to be updated, making the marker disappear for local players
	                    local giver = quest_helper.GetGiver(cx)
						quest_helper.GetGiver(cx).inst.components.timer:StartTimer("talk_cd", 7.5)
						cx.quest:Complete("game_intro")
						TheWorld:DoTaskInTime(1, function()
							TheLog.ch.Audio:print(
							"***///***wrld_game_intro_sequence.lua: Intro quest complete! Starting music.")
							TheWorld.components.ambientaudio:StartMusic()
							-- prob don't need to do this because it will get reset to nil when we finish run or go to town anyways
							-- but makes me feel clean inside
							TheWorld.components.ambientaudio.is_new_game = nil
						end)
					end)
			end

			cx:Opt("OPT_3B")
				:Fn(function()
					cx:Talk("OPT3B_RESPONSE")
					cx:Opt("OPT_4A")
						:Fn(function()
							cx:Talk("OPT4A_RESPONSE")
							EndConvo("OPT_5", "OPT5_RESPONSE")
						end)
					EndConvo("OPT_4B", "OPT4B_RESPONSE")
				end)
			EndConvo("OPT_3C", "OPT3C_RESPONSE")
		end

		cx:Talk("TALK_INTRO")
		cx:Opt("OPT_1")
			:Fn(function()
				cx:Talk("TALK_INTRO2")
				cx:Opt("OPT_2C")
					:Fn(function(cx)
						cx:Talk("OPT2C_RESPONSE")
						ReusedSequence(cx)
					end)
				cx:Opt("OPT_2B")
					:Fn(function(cx)
						cx:Talk("OPT2B_RESPONSE")
						cx:Talk("TALK_INTRO3")
						ReusedSequence(cx)
					end)
				cx:Opt("OPT_2A")
					:Fn(function(cx)
						cx:Talk("OPT2A_RESPONSE")
						cx:Talk("TALK_INTRO3")
						ReusedSequence(cx)
					end)
			end)
	end)

return Q
