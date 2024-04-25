local Convo = require "questral.convo"
local Npc = require "components.npc"
local Quest = require "questral.quest"
local Quip = require "questral.quip"
local rotwoodquestutil = require "questral.game.rotwoodquestutil"
local quest_strings = require("strings.strings_npc_scout").QUESTS.dgn_weapons_explainers.POLEARM_FULL_CONVO

------QUEST SETUP------

local Q = Quest.CreateJob()

-- ------CONVERSATIONS AND QUESTS------

local convo = function(cx)
	local function EndOpt(str_end)
		cx:AddEnd(str_end)
			:Fn(function()
				cx:Talk("END_RESPONSE")
			end)
	end

	cx:Question("1A")
		:CompleteQuest()
		:Fn(function()
			cx:Question("2")
				:Fn(function()
					EndOpt("QUESTION_END")
				end)
			EndOpt("QUESTION_END")
		end)
	EndOpt("QUESTION_1B")
end

local quip_convo = 
{
	tags = {"chitchat", "role_scout", "weapon_type_polearm"},
	not_tags = { "in_town" },
	strings = quest_strings,
	quip = quest_strings.TALK,
	convo = convo,
	prefab = "npc_scout"
}

rotwoodquestutil.AddQuipConvo(Q, quip_convo)

return Q
