local Quest = require "questral.quest"
local rotwoodquestutil = require "questral.game.rotwoodquestutil"
local quest_strings = require("strings.strings_npc_dojo_master").QUESTS.explain_frenzy

local Q = Quest.CreateJob()

local convo = function(cx)
	local function EndOpt(btn_str, response_str)
		cx:AddEnd(btn_str) --say thanks for the explainer
			:CompleteQuest()
			:Talk(response_str)
	end

	cx:Opt("OPT_1A")
		:Fn(function(cx)
			cx:Talk("OPT1A_RESPONSE")
			cx:Opt("OPT_2A") --player confirms they want the whole, lore-heavy spiel
				:Fn(function(cx)
					cx:Talk("OPT2A_RESPONSE") --full explainer
					cx:Opt("OPT_3A") --player notices its odd that were making rots more powerful by fighting them
						:Fn(function(cx)
							cx:Talk("OPT3A_RESPONSE") --end the convo
							EndOpt("OPT_3B", "TALK_END") --say thanks for the explainer
						end)
					EndOpt("OPT_3B", "TALK_END") --say thanks for the explainer
				end)
			cx:Opt("OPT_2B") --player asks for a condensed version of the explainer
				:Fn(function(cx)
					cx:Talk("OPT2B_RESPONSE")
					EndOpt("OPT_3B", "TALK_END") --end the convo
				end)
		end)
end

local quip_convo =
{
	tags = {"chitchat", "role_hunter", "has_killed_any_boss" },
	tag_scores = { has_killed_any_boss = 50 },
	strings = quest_strings,
	quip = quest_strings.TALK,
	convo = convo,
	prefab = "npc_dojo_master"
}

rotwoodquestutil.AddQuipConvo(Q, quip_convo)

return Q