local Convo = require "questral.convo"
local Npc = require "components.npc"
local Quest = require "questral.quest"
local Quip = require "questral.quip"
local rotwoodquestutil = require "questral.game.rotwoodquestutil"
local quest_strings = require("strings.strings_npc_market_merchant").QUESTS.dgn_hub.new_biome_meeting

------QUEST SETUP------

local Q = Quest.CreateJob()

-- ------CONVERSATIONS AND QUESTS------

local convo = function(cx)
	local function EndBtn(btn_str, response_str)
		cx:AddEnd(btn_str)
				:Fn(function()
					cx:Talk(response_str)
				end)
	end

	cx:Question("1")
		:CompleteQuest()
		:Fn(function()
			cx:Question("2")
				:Fn(function()
					cx:Question("3")
						:Fn(function()
							cx:Question("4")
								:Fn(function()
									cx:Question("5")
										:Fn(function()
											EndBtn("QUESTION_ANNOYING_END", "ANSWER_ANNOYING_END")
										end)
									EndBtn("QUESTION_LATE_END", "ANSWER_LATE_END")
								end)
							EndBtn("QUESTION_LATE_END", "ANSWER_LATE_END")
						end)
					EndBtn("QUESTION_EARLY_END", "ANSWER_EARLY_END")
				end)
			EndBtn("QUESTION_EARLY_END", "ANSWER_EARLY_END")
		end)
end

local quip_convo = 
{
	tags = { "chitchat", "role_market_merchant", "qc_dgn_firstmeeting_market",},
	not_tags = { "location_treemon_forest", "seen_first_time" },
	tag_scores = { chitchat = 150 },
	strings = quest_strings,
	quip = quest_strings.TALK,
	convo = convo,
	prefab = "npc_market_merchant",
}

rotwoodquestutil.AddQuipConvo(Q, quip_convo)

return Q
