local Quest = require "questral.quest"
local rotwoodquestutil = require "questral.game.rotwoodquestutil"
local quest_strings = require("strings.strings_npc_dojo_master").QUESTS.masteries
local Mastery = require"defs.masteries"

local Q = Quest.CreateJob()

local convo = function(cx)
	cx:Opt("OPT_1")
		:CompleteQuest()
		:Fn(function()
			cx:Talk("TALK2")
			--ask questions about toot
			local clicked_2A = false
			local clicked_2B = false
			local btn_titles = {"QUESTION_2A", "QUESTION_2B", "QUESTION_2C"}

			cx:Loop(function()
				if clicked_2A or clicked_2B then
					btn_titles = {"QUESTION_2A_ALT", "QUESTION_2B_ALT", "QUESTION_2C_ALT"}
				end

				if not clicked_2A then
					cx:Opt(btn_titles[1])
						:Fn(function() clicked_2A = true cx:Talk("ANSWER_2A") end)
				end
				if not clicked_2B then
					cx:Opt(btn_titles[2])
						:Fn(function() clicked_2B = true cx:Talk("ANSWER_2B") end)
				end
				cx:Opt(btn_titles[3])
					:EndLoop()
					:Fn(function()
						cx:Talk("ANSWER_2C")
						--ask questions about masteries
						cx:Loop(function()
							cx:Question("3A")
							cx:Question("3B")
							cx:Opt("OPT_3C")
								:MakeArmor()
								:Fn(function()
									cx:Talk("OPT3C_RESPONSE")
									rotwoodquestutil.OpenShop(cx, require("screens.town.masteryscreen"))
									cx:End()
								end)
						end)
				end)
			end)
		end)
end

local quip_convo = 
{
	tags = {"chitchat", "role_hunter"},
	not_tags = {"pf_unlocked_masteries"},
	tag_scores = 
	{
		chitchat = 100
	},
	strings = quest_strings,
	quip = quest_strings.TALK,
	convo = convo,
	repeatable = true,
	important = true,
	prefab = "npc_dojo_master"
}

rotwoodquestutil.AddQuipConvo(Q, quip_convo)

return Q