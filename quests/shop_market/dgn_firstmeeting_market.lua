local Convo = require "questral.convo"
local Npc = require "components.npc"
local Quest = require "questral.quest"
local Quip = require "questral.quip"
local rotwoodquestutil = require "questral.game.rotwoodquestutil"
local quest_strings = require("strings.strings_npc_market_merchant").QUESTS.first_meeting

------QUEST SETUP------

local Q = Quest.CreateJob()

-- ------CONVERSATIONS AND QUESTS------

local convo = function(cx)
	cx:CompleteQuest()
	cx:GetPlayer().inst:UnlockFlag("qc_dgn_firstmeeting_market")
	cx:Question("1A")
	cx:Question("1B")
	cx:JoinAllOpt_Fn(function()
		cx:Talk("TALK2")
		local clicked_any = false
		local clicked_2A = false
		cx:Loop(function()
			if not clicked_any then
				if not clicked_2A then
					cx:Question("2A")
						:Fn(function()
							clicked_2A = true
						end)
				else
					cx:Question("2B")
				end
				cx:Question("2C")
				cx:AddEnd("OPT_END")
					:Fn(function()
						cx:Talk("TALK_END")
					end)
				clicked_any = true
			else
				if not clicked_2A then
					cx:Opt("QUESTION_2A_ALT")
						:Fn(function()
							clicked_2A = true
							cx:Talk("ANSWER_2A")
						end)
				else
					cx:Question("2B")
				end
				cx:Question("2C")
				cx:Question("2D")
				cx:AddEnd("OPT_END_ALT")
					:Fn(function()
						cx:Talk("TALK_END")
					end)
			end
		end)
	end)
end

local quip_convo = 
{
	tags = {"chitchat", "role_market_merchant"},
	tag_scores = { seen_first_time = 100 },
	strings = quest_strings,
	quip = quest_strings.TALK,
	convo = convo,
	prefab = "npc_market_merchant",
	important = true,
}

rotwoodquestutil.AddQuipConvo(Q, quip_convo)

return Q
