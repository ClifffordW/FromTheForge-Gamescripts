local Convo = require "questral.convo"
local Npc = require "components.npc"
local Quest = require "questral.quest"
local Quip = require "questral.quip"
local rotwoodquestutil = require "questral.game.rotwoodquestutil"
local quest_strings = require("strings.strings_npc_blacksmith").QUESTS.twn_weapon_weight_explainer

------QUEST SETUP------

local Q = Quest.CreateJob()

-- ------CONVERSATIONS AND QUESTS------

local convo = function(cx)
	cx:CompleteQuest()
	cx:Question("1")
		:Fn(function()
			cx:Question("2A") :Fn(function()
				cx:Opt("END_OPT_A")
				cx:Opt("END_OPT_B")
				
				cx:JoinAllOpt_Fn(function()
					cx:Talk("END_TALK")
					cx:End()
				end)
			end)
			cx:AddEnd("QUESTION_2B") :Fn(function()
				cx:Talk("ANSWER_2B")
				cx:End()
			end)
		end)
end

local quip_convo = 
{
	tags = { "chitchat", "role_blacksmith", "in_town" },
	strings = quest_strings,
	quip = quest_strings.TALK,
	convo = convo,
	prefab = "npc_blacksmith"
}

rotwoodquestutil.AddQuipConvo(Q, quip_convo)

return Q
