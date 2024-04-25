local Convo = require "questral.convo"
local Npc = require "components.npc"
--local Quip = require "questral.quip"
local Quest = require "questral.quest"
local quest_helper = require "questral.game.rotwoodquestutil"

local quest_strings = require("strings.strings_npc_scout").QUESTS.twn_chat_scout
--local quip_strings = require("strings.strings_npc_scout").QUIPS

local Q = Quest.CreateJob()
	:SetPriority(QUEST_PRIORITY.NORMAL)
	--:SetIsUnimportant()

function Q:Quest_EvaluateSpawn(quester)
	return true
end

Q:SetRateLimited(true)

------CAST DECLARATIONS------

Q:UpdateCast("giver")
	:FilterForPrefab("npc_scout")

------OBJECTIVE DECLARATIONS------
Q:AddObjective("tutorial_feedback")
	:InitialState(QUEST_OBJECTIVE_STATE.s.ACTIVE)
	:SetIsUnimportant()

Q:AddObjective("bandages")
	:SetRateLimited(true)
	:InitialState(QUEST_OBJECTIVE_STATE.s.ACTIVE)

--[[Q:AddObjective("glitz_allergy")
	:SetRateLimited(true)
	:InitialState(QUEST_OBJECTIVE_STATE.s.ACTIVE)]]

Q:AddObjective("beautiful_future")
	:SetRateLimited(true)
	:InitialState(QUEST_OBJECTIVE_STATE.s.ACTIVE)

Q:AddObjective("foraging_part_one")
	:SetRateLimited(true)
	:InitialState(QUEST_OBJECTIVE_STATE.s.ACTIVE)
	:OnComplete(function(quest)
		--quest:ActivateObjective("foraging_part_two")
	end)

Q:AddObjective("foraging_part_two")
	:SetRateLimited(true)
	:SetIsImportant()
	:OnComplete(function(quest)
		quest:ActivateObjective("foraging_part_three")
	end)

Q:AddObjective("foraging_part_three")
	:SetRateLimited(true)
	:SetIsImportant()
	:OnComplete(function(quest)
		quest:ActivateObjective("upgrade_home_celebrate")
	end)

Q:AddObjective("gathering_data")
	:SetRateLimited(true)
	:InitialState(QUEST_OBJECTIVE_STATE.s.ACTIVE)

Q:AddObjective("bonion_cry")
	:SetRateLimited(true)
	:InitialState(QUEST_OBJECTIVE_STATE.s.ACTIVE)

------CONVERSATIONS AND QUESTS------
Q:OnTownChat("foraging_part_one", "giver")
	:SetPriority(Convo.PRIORITY.NORMAL)
	:Strings(quest_strings.foraging.part_one)
	:Fn(function(cx)
		cx:Talk("TALK")

		cx:Opt("OPT_1A")
		cx:Opt("OPT_1B")
		cx:Opt("OPT_1C")

		cx:JoinAllOpt_Fn(function()
			cx:Talk("TALK2")
			cx.quest:Complete("foraging_part_one")
			cx:End()
		end)
	end)
Q:OnTownChat("foraging_part_two", "giver")
	:SetPriority(Convo.PRIORITY.NORMAL)
	:Strings(quest_strings.foraging.part_two)
	:Fn(function(cx)
		cx:Talk("TALK")
		cx:Opt("OPT_1")
			:Fn(function()
				cx:Talk("TALK2")
				cx:End()
				cx.quest:Complete("foraging_part_two")
			end)
	end)
Q:OnTownChat("foraging_part_three", "giver")
	:SetPriority(Convo.PRIORITY.NORMAL)
	:Strings(quest_strings.foraging.part_three)
	:Fn(function(cx)
		local function AddEndBtn(btn_str)
			cx:AddEnd(btn_str)
				:Fn(function()
					cx.quest:Complete("foraging_part_three")
				end)
		end

		cx:Talk("TALK")
		cx:Opt("OPT_1A")
			:Fn(function()
				cx:Talk("OPT1A_RESPONSE")
				AddEndBtn("OPT_1B_ALT")
			end)
		AddEndBtn("OPT_1B")
	end)

Q:OnTownChat("bandages", "giver")
	:SetPriority(Convo.PRIORITY.NORMAL)
	:Strings(quest_strings.bandages)
	:Fn(function(cx)
		cx:Talk("TALK")
		cx:Opt("OPT_1A")
			:Fn(function()
				cx:Talk("OPT1A_RESPONSE")
				cx:End()
				cx.quest:Complete("bandages")
			end)
		cx:AddEnd("OPT_1B")
			:Fn(function()
				cx.quest:Complete("bandages")
			end)
	end)

Q:OnTownChat("gathering_data", "giver")
	:SetPriority(Convo.PRIORITY.NORMAL)
	:Strings(quest_strings.gathering_data)
	:Fn(function(cx)
		cx:Talk("TALK")
		cx.quest:Complete("gathering_data")
		cx:End()
	end)

Q:OnTownChat("bonion_cry", "giver")
	:SetPriority(Convo.PRIORITY.NORMAL)
	:Strings(quest_strings.bonion_cry)
	:Fn(function(cx)
		cx:Talk("TALK")
		cx.quest:Complete("bonion_cry")
		cx:End()
	end)

--[[Q:OnTownChat("glitz_allergy", "giver")
	:SetPriority(Convo.PRIORITY.NORMAL)
	:Strings(quest_strings.glitz_allergy)
	:Fn(function(cx)
		cx:Talk("TALK")
		cx:Opt("OPT_1A")
			:Fn(function()
				cx:Talk("TALK2")

				cx:Opt("OPT_2A")
				cx:Opt("OPT_2B")
				cx:Opt("OPT_2C")

				cx:JoinAllOpt_Fn(function()
					cx:Talk("TALK3")
					cx:End()
					cx.quest:Complete("glitz_allergy")
				end)
			end)
	end)]]

Q:OnTownChat("beautiful_future", "giver")
	:SetPriority(Convo.PRIORITY.NORMAL)
	:Strings(quest_strings.beautiful_future)
	:Fn(function(cx)
		local function OptBtn(btnStr, responseStr)
			cx:Opt(btnStr)
			:Fn(function()
				cx:Talk(responseStr)
				cx:End()
				cx.quest:Complete("beautiful_future")
			end)
		end

		cx:Talk("TALK")
		OptBtn("OPT_1A", "OPT1A_RESPONSE")
		OptBtn("OPT_1B", "OPT1B_RESPONSE")
		OptBtn("OPT_1C", "OPT1C_RESPONSE")
	end)

Q:OnTownChat("tutorial_feedback", "giver",
	function(quest, node, sim)
		local num_runs = quest:GetPlayer().components.progresstracker:GetValue("total_num_runs") or 0
		return num_runs >= 2
	end)
	:SetPriority(Convo.PRIORITY.LOWEST)
	:Strings(quest_strings.tutorial_feedback)
	:TalkAndCompleteQuestObjective("TALK_FEEDBACK_REMINDER")

return Q
