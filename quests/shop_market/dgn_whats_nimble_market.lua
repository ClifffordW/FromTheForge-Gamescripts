local Convo = require "questral.convo"
local Npc = require "components.npc"
local Quest = require "questral.quest"
local Quip = require "questral.quip"
local rotwoodquestutil = require "questral.game.rotwoodquestutil"
local quest_strings = require("strings.strings_npc_market_merchant").QUESTS.dgn_hub.what_is_nimble

------QUEST SETUP------

local Q = Quest.CreateJob()

-- ------CONVERSATIONS AND QUESTS------

local convo = function(cx)
	cx:Question("1")
		:CompleteQuest()
		:Fn(function()
			cx:Question("2A")
			cx:Opt("QUESTION_2B")
				:Fn(function()
					cx:Talk("ANSWER_2A") --2B and 2A have the same answer
				end)
			cx:Question("2C")
			cx:JoinAllOpt_Fn(function()
				cx:Talk("TALK2")
				cx:Question("3")
					:Fn(function()
						cx:AddEnd("QUESTION_REGULAR_EXIT")
							:Fn(function()
								cx:Talk("ANSWER_EXIT")
							end)
					end)
				cx:AddEnd("QUESTION_EARLY_EXIT")
					:Fn(function()
						cx:Talk("ANSWER_EXIT")
					end)
			end)
			cx:AddEnd("QUESTION_EARLY_EXIT")
				:Fn(function()
					cx:Talk("ANSWER_EXIT")
				end)
		end)
	--cx:InjectHubOptions()
end

local quip_convo = 
{
	tags = {"chitchat", "role_market_merchant", "qc_dgn_firstmeeting_market", },
	tag_scores = { chitchat = 100 },
	strings = quest_strings,
	quip = quest_strings.TALK,
	convo = convo,
	prefab = "npc_market_merchant",
}

rotwoodquestutil.AddQuipConvo(Q, quip_convo)

return Q
