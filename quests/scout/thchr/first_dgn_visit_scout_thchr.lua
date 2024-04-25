local Convo = require "questral.convo"
local Npc = require "components.npc"
local Quest = require "questral.quest"
local Quip = require "questral.quip"
local rotwoodquestutil = require "questral.game.rotwoodquestutil"
local quest_strings = require("strings.strings_npc_scout").QUESTS.thatcher_swamp.thatcher_first_dgn_visit

------QUEST SETUP------

local Q = Quest.CreateJob()

-- ------CONVERSATIONS AND QUESTS------

local convo = function(cx)
	cx:CompleteQuest()

	local function SecondPartConvo()
		local function ThirdPartConvo()
			cx:Talk("TALK2")

			cx:Question("4A")
			cx:Question("4B")
			cx:Question("4C")

			cx:JoinAllOpt_Fn(function()
				cx:End()
			end)
		end

		cx:Question("2A")
			:Fn(function()
				cx:Question("3A")
				cx:Question("3B")
				cx:JoinAllOpt_Fn(function()
					ThirdPartConvo()
				end)
			end)
		cx:Question("2B") :Fn(function() ThirdPartConvo() end)
	end

	--convo starts here
	cx:Question("1A")
		:Fn(function()
			cx:Opt("QUESTION_1B_ALT") 
				:Fn(function()
					cx:Talk("ANSWER_1B") 
					SecondPartConvo() 
				end)
		end)
	cx:Question("1B") :Fn(function() SecondPartConvo() end)
end

local quip_convo =
{
	tags = {"chitchat", "role_scout", "location_thatcher_swamp"},
	not_tags = {"has_killed_thatcher", "in_town"},
	tag_scores = { location_thatcher_swamp = 100 },
	strings = quest_strings,
	quip = quest_strings.TALK,
	important = true,
	convo = convo,
	prefab = "npc_scout",
}

rotwoodquestutil.AddQuipConvo(Q, quip_convo)

return Q
