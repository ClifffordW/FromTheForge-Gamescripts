local Convo = require "questral.convo"
local Npc = require "components.npc"
local Quest = require "questral.quest"
local Quip = require "questral.quip"
local rotwoodquestutil = require "questral.game.rotwoodquestutil"
local quest_strings = require("strings.strings_npc_scout").QUESTS.megatreemon_forest.MT_die_to_miniboss_convo

------QUEST SETUP------

local Q = Quest.CreateJob()

-- ------CONVERSATIONS AND QUESTS------

local convo = function(cx)
	cx:CompleteQuest()
	cx:Question("1") :Fn(function()
		cx:Question("2")
			:End()
	end)
end

local quip_convo =
{
	tags = {"chitchat", "role_scout", "in_town", "last_killed_by_yammo_miniboss"},
	not_tags = { "has_seen_megatreemon" },
	tag_scores = { last_killed_by_yammo_miniboss = 110 },
	strings = quest_strings,
	quip = quest_strings.TALK,
	convo = convo,
	prefab = "npc_scout",
}

rotwoodquestutil.AddQuipConvo(Q, quip_convo)


return Q
