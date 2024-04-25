local Convo = require "questral.convo"
local Quest = require "questral.quest"
local quest_helper = require "questral.game.rotwoodquestutil"

local primary_quest_strings = require ("strings.strings_npc_cook").QUESTS.primary_dgn_meeting_cook

------QUEST SETUP------

local Q = Quest.CreateJob()
	:SetPriority(QUEST_PRIORITY.HIGHEST)
	:SetIsImportant()
	:TitleString(primary_quest_strings.TITLE)
	:SetWorldQuester()

function Q:Quest_EvaluateSpawn(quester)
	return true
end

------CAST DECLARATIONS------

Q:UpdateCast("giver")
	:FilterForPrefab("npc_cook")

--------------- DUNGEON ROUTE ---------------

Q:AddObjective("talk_in_dungeon")
	:InitialState(QUEST_OBJECTIVE_STATE.s.ACTIVE)
    :OnEvent("exit_room", function(quest)
		quest_helper.CompleteObjectiveIfCastPresent(quest, "giver", "talk_in_dungeon")
    end)
    :OnEvent("end_current_run", function(quest)
		quest_helper.CompleteObjectiveIfCastPresent(quest, "giver", "talk_in_dungeon")
    end)
    :OnComplete(function(quest)
        quest:Complete()
    end)

local has_local_player_talked = false

local function _finish_chat(cx)
    -- should only effect other players on the local machine
    has_local_player_talked = true
    -- force quest marks to be updated, making the marker disappear for local players

    local giver = quest_helper.GetGiver(cx)
    giver.inst.components.timer:StartTimer("talk_cd", 5)
end

Q:OnDungeonChat("talk_in_dungeon", "giver", function(quest, node, sim, convo_target)
        local in_correct_room = Quest.Filters.InDungeon_QuestRoom(quest, node, sim, convo_target)
        return in_correct_room and not has_local_player_talked
    end)
	:SetPriority(Convo.PRIORITY.HIGHEST)
	:Strings(primary_quest_strings.invite_to_town)
	:Fn(function(cx)
		cx:Talk("TALK_INTRODUCE_SELF")
		cx:Opt("OPT_1A")
		cx:Opt("OPT_1B")
		cx:JoinAllOpt_Fn(function()
			-- both options go here

			cx:Talk("TALK_INTRODUCE_SELF2")
			cx:Opt("OPT_2A")
			cx:Opt("OPT_2B")
			cx:JoinAllOpt_Fn(function()
				-- then both options go here

				cx:Talk("TALK_INTRODUCE_SELF3")
				cx:Opt("OPT_3B")
					:Fn(function()
						cx:Talk("OPT3B_RESPONSE")
						cx:AddEnd("OPT_4")
							:Fn(function()
								cx:Talk("OPT4_RESPONSE")
								_finish_chat(cx)
							end)
					end)
				cx:AddEnd("OPT_3A")
					:Fn(function()
						cx:Talk("OPT3A_RESPONSE")
						_finish_chat(cx)
					end)
			end)
		end)
	end)

return Q