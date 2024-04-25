local Convo = require "questral.convo"
local Npc = require "components.npc"
local Quest = require "questral.quest"
local Quip = require "questral.quip"
local rotwoodquestutil = require "questral.game.rotwoodquestutil"
local quest_strings = require("strings.strings_npc_scout").QUESTS.megatreemon_forest.MT_celebrate_defeat_boss.MT_defeated_regular

------QUEST SETUP------

local Q = Quest.CreateJob()

-- ------CONVERSATIONS AND QUESTS------

local convo = function(cx)
	
	local opt_1C = "QUESTION_1C"
	local clicked_funny = false
	
	cx:CompleteQuest()
	if not clicked_funny then
		cx:Question("1A") :Fn(function() clicked_funny = true end)
		cx:Question("1B") :Fn(function() clicked_funny = true end)
		cx:JoinAllOpt_Fn(function()
			cx:Opt("QUESTION_1C_ALT")
				:CompleteQuest()
				:Fn(function()
					cx:Talk("ANSWER_1C")
						
					local opt_2B = "QUESTION_2B"

					cx:Loop(function()
						
						cx:Question("2A")
						cx:AddEnd(opt_2B)
						
						opt_2B = "QUESTION_2B_ALT"
					end)
				end)
		end)
	end

	cx:Opt("QUESTION_1C")
		:CompleteQuest()
		:Fn(function()
			cx:Talk("ANSWER_1C")
				
			local opt_2B = "QUESTION_2B"

			cx:Loop(function()
				
				cx:Question("2A")
				cx:AddEnd(opt_2B)
				
				opt_2B = "QUESTION_2B_ALT"
			end)
		end)
end

local quip_convo = 
{
	tags = {"chitchat", "role_scout", "has_killed_megatreemon", "has_megatreemon_heart", "megatreemon_heart_level_0", "in_town"},
	tag_scores = { has_megatreemon_heart = 100 },
	strings = quest_strings,
	quip = quest_strings.TALK,
	convo = convo,
	prefab = "npc_scout",
	important = true,
}

rotwoodquestutil.AddQuipConvo(Q, quip_convo)


return Q
