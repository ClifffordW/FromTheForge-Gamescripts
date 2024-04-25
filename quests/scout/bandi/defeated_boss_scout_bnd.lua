local Convo = require "questral.convo"
local Npc = require "components.npc"
local Quest = require "questral.quest"
local Quip = require "questral.quip"
local rotwoodquestutil = require "questral.game.rotwoodquestutil"
local quest_strings = require("strings.strings_npc_scout").QUESTS.bandicoot_swamp.bandi_celebrate_defeat_boss

------QUEST SETUP------

local Q = Quest.CreateJob()

-- ------CONVERSATIONS AND QUESTS------

local convo = function(cx)
	cx:CompleteQuest()
	cx:Question("1A")
end

local quip_convo =
{
	tags = {"chitchat", "role_scout", "in_town", "has_killed_bandicoot", "has_bandicoot_heart", "bandicoot_heart_level_0"},
	tag_scores = { has_bandicoot_heart = 90 },
	strings = quest_strings,
	quip = quest_strings.TALK,
	convo = convo,
	prefab = "npc_scout",
	important = true,
}

rotwoodquestutil.AddQuipConvo(Q, quip_convo)

return Q
