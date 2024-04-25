local Convo = require "questral.convo"
local Npc = require "components.npc"
local Quest = require "questral.quest"
local Quip = require "questral.quip"
local rotwoodquestutil = require "questral.game.rotwoodquestutil"
local quest_strings = require("strings.strings_npc_scout").QUESTS.bandicoot_swamp.bandi_first_dgn_visit

------QUEST SETUP------

local Q = Quest.CreateJob()

-- ------CONVERSATIONS AND QUESTS------

local convo = function(cx)
	cx:CompleteQuest()
	cx:Question("1A")
		:Fn(function()
			local opt_2A = false
			local opt_2B = false
			cx:Loop(function()
				if not opt_2A and not opt_2B then
					cx:Question("2A") :Fn(function() opt_2A = true end)
					cx:Question("2B") :Fn(function() opt_2B = true end)
					cx:AddEnd()
				else
					--explain spores
					if not opt_2A then
						cx:Opt("QUESTION_2A_ALT")
							:Fn(function() 
								opt_2A = true
								cx:Talk("ANSWER_2A")
							end)
					end
					--talk about boss
					if not opt_2B then
						cx:Opt("QUESTION_2B_ALT")
							:Fn(function()
								opt_2B = true
								cx:Talk("ANSWER_2B") 
							end)
							cx:AddEnd()
					else
						cx:AddEnd("END_3B")
							:Fn(function()
								cx:Talk("TALK2")
						end)
					end
				end
		end)
	end)
	cx:Question("1B")
		:Fn(function()
			cx:Opt("OPT_3A")
				:Fn(function()
					cx:Talk("ANSWER_2B")
					cx:AddEnd("END_3B_ALT")
						:Fn(function()
							cx:Talk("TALK2")
					end)
				end)
			cx:AddEnd("END_3B")
				:Fn(function()
					cx:Talk("TALK2")
			end)
	end)
end

local quip_convo = 
{
	tags = {"chitchat", "role_scout", "location_bandi_swamp"},
	not_tags = {"has_killed_bandicoot", "in_town"},
	tag_scores = { location_bandi_swamp = 100 },
	strings = quest_strings,
	quip = quest_strings.TALK,
	convo = convo,
	prefab = "npc_scout",
	important = true,
}

rotwoodquestutil.AddQuipConvo(Q, quip_convo)

return Q
