local Convo = require "questral.convo"
local Npc = require "components.npc"
local Quest = require "questral.quest"
local Quip = require "questral.quip"
local rotwoodquestutil = require "questral.game.rotwoodquestutil"
local quest_strings = require("strings.strings_npc_scout").QUESTS.megatreemon_forest.MT_celebrate_defeat_miniboss

------QUEST SETUP------

local Q = Quest.CreateJob()

-- ------CONVERSATIONS AND QUESTS------

local convo = function(cx)
	cx:CompleteQuest()
	cx:Question("1"):Fn(function()
		cx:Question("2A")
			:End()
		cx:Question("2B")
			:End()
	end)
end

local quip_convo =
{
	tags = {"chitchat", "role_scout", "has_killed_yammo_miniboss", "in_town"},
	not_tags = { "has_seen_megatreemon" },
	tag_scores = { has_killed_yammo_miniboss = 100 },
	strings = quest_strings,
	quip = quest_strings.TALK,
	convo = convo,
	prefab = "npc_scout",
}

rotwoodquestutil.AddQuipConvo(Q, quip_convo)


return Q
