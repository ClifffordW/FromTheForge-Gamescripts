local Convo = require "questral.convo"
local Quest = require "questral.quest"
local quest_helper = require "questral.game.rotwoodquestutil"
local quest_strings = require ("strings.strings_npc_armorsmith").QUESTS.invite_to_town

------QUEST SETUP------

local Q = Quest.CreateJob()
    :TitleString(quest_strings.TITLE)
    :SetPriority(QUEST_PRIORITY.HIGHEST)
    :SetIsImportant()
    :SetWorldQuester()

function Q:Quest_EvaluateSpawn(quester)
    return true
end

------CAST DECLARATIONS------
local has_local_player_talked = false

Q:UpdateCast("giver")
    :FilterForPrefab("npc_armorsmith")
    :AddOnCastFn(function(node)
        node.inst.components.markablenpc:AddMarkCondition(Q:GetContentID(), function(player)
            return not has_local_player_talked and not TheWorld:HasTag("town")
        end)
    end)

------OBJECTIVE DECLARATIONS------

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

--------------- DUNGEON ROUTE ---------------


Q:OnDungeonChat("talk_in_dungeon", "giver", function(quest, node, sim, convo_target)
        local in_correct_room = Quest.Filters.InDungeon_QuestRoom(quest, node, sim, convo_target)
        return in_correct_room and not has_local_player_talked
    end)
    :SetPriority(Convo.PRIORITY.HIGHEST)
    :Strings(quest_strings)
    :Fn(function(cx)
        cx:Talk("TALK")
        cx:Opt("OPT_1")
            :Fn(function()
                cx:Talk("TALK2")

                cx:Opt("OPT_2A")
                cx:Opt("OPT_2B")

                cx:JoinAllOpt_Fn(function()
                    cx:Talk("TALK3")
                    cx:Opt("OPT_3")
                        :Fn(function()
                            cx:Talk("TALK4")
                            -- should only effect other players on the local machine
                            has_local_player_talked = true
                            -- force quest marks to be updated, making the marker disappear for local players
                            local giver = quest_helper.GetGiver(cx)
                            giver.inst.components.timer:StartTimer("talk_cd", 5)
                        end)
                end)
            end)
    end)

return Q