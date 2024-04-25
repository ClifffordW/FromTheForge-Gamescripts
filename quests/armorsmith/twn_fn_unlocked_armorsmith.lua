local Convo = require "questral.convo"
local Npc = require "components.npc"
local Quest = require "questral.quest"
local Quip = require "questral.quip"
local rotwoodquestutil = require "questral.game.rotwoodquestutil"
local quest_strings = require("strings.strings_npc_armorsmith").QUESTS.twn_function_unlocked

------QUEST SETUP------

local Q = Quest.CreateJob()

-- ------CONVERSATIONS AND QUESTS------

local convo = function(cx)
	cx:CompleteQuest()
	cx:Question("1")
		:Fn(function()
			local clicked_2A = false
			local clicked_2B = false
			cx:Loop(function()
				--button titles change if the *other* button has already been clicked
				local btn_2A_title = (clicked_2B == false and "QUESTION_2A" or "QUESTION_2A_ALT")
				local btn_2B_title = (clicked_2A == false and "QUESTION_2B" or "QUESTION_2B_ALT")

				--ask who Lunn is
				if not clicked_2A then
				cx:Opt(btn_2A_title)
					:Fn(function()
						clicked_2A = true
						cx:Talk("ANSWER_2A")
						cx:Question("3")
							:Fn(function()
								cx:Question("4A") :Fn(function() cx:Talk("TALK2") end)
								cx:Question("4B") :Fn(function() cx:Talk("TALK2") end)
							end)
					end)
				end

				--ask about bernas town function
				if not clicked_2B then
				cx:Opt(btn_2B_title)
					:Fn(function()
						clicked_2B = true
						cx:Talk("ANSWER_2B")
						cx:Question("5A")
						cx:Question("5B")
					end)
				end

				--end convo
				cx:AddEnd("END_OPT") :Fn(function() cx:Talk("END_TALK") end)
			end)
		end)	
end

local quip_convo = 
{
	tags = { "chitchat", "role_armorsmith", "in_town" },
	tag_scores = 
	{
		chitchat = 100
	},
	strings = quest_strings,
	quip = quest_strings.TALK,
	convo = convo,
	prefab = "npc_armorsmith"
}

rotwoodquestutil.AddQuipConvo(Q, quip_convo)

return Q
