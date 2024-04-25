local Convo = require "questral.convo"
local Npc = require "components.npc"
local Quest = require "questral.quest"
local Quip = require "questral.quip"
local rotwoodquestutil = require "questral.game.rotwoodquestutil"
local quest_strings = require("strings.strings_npc_scout").QUESTS.first_death

------QUEST SETUP------

local Q = Quest.CreateJob()

-- ------CONVERSATIONS AND QUESTS------

local convo = function(cx)
	cx:CompleteQuest()
	cx:Question("1")
		:Fn(function()
			cx:Question("2")
				:Fn(function()
					cx:Question("3A")
						:CompleteQuest()
						:End()
					cx:Question("3B")
						:CompleteQuest()
						:End()
				end)
		end)
end

local quip_convo =
{
	tags = {"chitchat", "role_scout", "lost_last_run", "in_town"},
	not_tags = {"has_killed_any_boss"},
	tag_scores = { lost_last_run = 50 },
	strings = quest_strings,
	quip = quest_strings.TALK,
	convo = convo,
	prefab = "npc_scout"
}

rotwoodquestutil.AddQuipConvo(Q, quip_convo)

return Q
