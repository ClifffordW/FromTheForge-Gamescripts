-- local Convo = require "questral.convo"
-- local Npc = require "components.npc"
-- local Quest = require "questral.quest"
-- local Quip = require "questral.quip"
-- local quest_strings = require("strings.strings_npc_dojo_master").QUESTS.twn_meeting_dojo
-- local flitt_strings = require("strings.strings_npc_scout").QUESTS
-- local flitt_quips = require("strings.strings_npc_scout").QUIPS

-- ------QUEST SETUP------

-- local Q = Quest.CreateJob()
-- 	:SetPriority(QUEST_PRIORITY.HIGH)
-- 	:TitleString(quest_strings.TITLE)
-- 	:SetWorldQuester()

-- function Q:Quest_EvaluateSpawn(quester)
-- 	return false
-- end

-- ------CAST DECLARATIONS------

-- Q:UpdateCast("giver")
-- 	:FilterForPrefab("npc_dojo_master")

-- Q:AddCast("flitt")
-- 	:FilterForPrefab("npc_scout")

-- ------OBJECTIVE DECLARATIONS------
-- Q:AddObjective("add_to_town")
-- 	:InitialState(QUEST_OBJECTIVE_STATE.s.ACTIVE)
-- 	:OnEvent("end_current_run", function(quest) quest:Complete("add_to_town") end)
-- 	:OnComplete(function(quest) 
-- 		quest:Complete() -- just complete the quest because the rest of this convo doesn't flow well right now
-- 		-- quest:ActivateObjective("talk_in_town")	
-- 	end)
-- 	:UnlockWorldFlagsOnComplete{"wf_town_has_dojo"}

-- Q:AddObjective("recharge_inhaler")
-- 	:SetPriority(QUEST_PRIORITY.HIGH)

-- Q:AddObjective("talk_in_town")
-- 	:SetIsImportant()
-- 	:OnComplete(function(quest)
-- 		-- quest:ActivateObjective("recharge_inhaler")
-- 	end)
	

-- Q:AddQuips {
--     Quip("scout", "pre_toot_quips")
--         :PossibleStrings(flitt_quips.quip_scout_no_dojo),
--     Quip("scout", "mid_quest_quips")
--         :PossibleStrings(flitt_quips.dojo_inhalerquest_one.mid_quest_quips)
-- }

-- Q:AddObjective("toot_returned")
-- 	:InitialState(QUEST_OBJECTIVE_STATE.s.ACTIVE)

-- ------CONVERSATIONS AND QUESTS------

-- --TEMP CONVO FOR PLAYTEST
-- Q:OnTownChat("talk_in_town", "giver")
-- 	:SetPriority(Convo.PRIORITY.HIGHEST)
-- 	:Strings(quest_strings.talk_in_town)
-- 	:Fn(function(cx)
-- 		cx:Talk("TEMP_INTRO")

-- 		cx:AddEnd("TEMP_OPT")
-- 			:Fn(function()
-- 				cx:Talk("TEMP_INTRO2")
-- 				cx.quest:Complete()
-- 			end)
-- end)

-- --flitt worrying about toot while hes still lost in the woods
-- Q:OnTownChat("talk_in_town", "flitt", function(quest, node, sim) return not TheWorld:IsFlagUnlocked("wf_town_has_dojo") end)
-- 	:Fn(function(cx)
-- 	cx:Quip("giver", { "scout", "pre_toot_quips" })
-- end)

-- --flitt comments on wanting to get back out in the field bc we need to charge the inhaler while rechard_inhaler is active
-- Q:OnTownChat("recharge_inhaler", "flitt")
-- 	:Fn(function(cx)
-- 	cx:Quip("giver", { "scout", "mid_quest_quips" })
-- end)

-- Q:OnTownChat("toot_returned", "flitt", function(quest, node, sim) return quest:IsActive("recharge_inhaler") end)
-- 	:SetPriority(Convo.PRIORITY.HIGHEST)
-- 	:Strings(flitt_strings.twn_chat_scout.TOOT_RETURNED)
-- 	:Fn(function(cx)
-- 		cx:Talk("TALK1")

-- 		local function MenuLoop(click1A, click1B)
-- 			if not click1A then
-- 				cx:Opt("OPT_1A")
-- 					:Fn(function()
-- 						click1A = true
-- 						cx:Talk("OPT1A_RESPONSE")
-- 						MenuLoop(click1A, click1B)
-- 					end)
-- 			end

-- 			if not click1B then
-- 				cx:Opt("OPT_1B")
-- 					:Fn(function()
-- 						click1B = true
-- 						cx:Talk("OPT1B_RESPONSE")
-- 						MenuLoop(click1A, click1B)
-- 					end)
-- 			end

-- 			cx:AddEnd("OPT_1C")
-- 				:Fn(function()
-- 					cx:Talk("OPT1C_RESPONSE")
-- 					cx.quest:Complete("toot_returned")
-- 				end)
-- 		end

-- 		MenuLoop(false, false)
-- 	end)

-- --[[Q:OnTownChat("talk_in_town", "giver")
-- 	:SetPriority(Convo.PRIORITY.HIGHEST)
-- 	:Strings(quest_strings.talk_in_town)
-- 	:Fn(function(cx)
-- 		cx:Talk("TALK")
-- 		cx:Opt("OPT_1A")
-- 			:Talk("OPT1A_RESPONSE")
-- 		cx:Opt("OPT_1B")
-- 			:Talk("OPT1B_RESPONSE")

-- 		cx:JoinAllOpt_Fn(function()
-- 			cx:Talk("TALK2")
-- 			cx:Opt("OPT_2A")
-- 				:Fn(function(cx)
-- 					cx:Talk("TALK3")
-- 					cx:Talk("OPT2A_RESPONSE")
-- 				end)
-- 			cx:Opt("OPT_2B")
-- 				:Fn(function(cx)
-- 					cx:Talk("TALK3")
-- 					cx:Talk("OPT2B_RESPONSE")
-- 				end)

-- 			cx:JoinAllOpt_Fn(function(cx)
-- 				cx:AddEnd("OPT_3")
-- 					:Fn(function(cx)
-- 						cx.quest:Complete("talk_in_town")
-- 					end)
-- 			end)
-- 		end)
-- 	end)]]

-- return Q
