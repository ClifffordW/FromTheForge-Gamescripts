local Convo = require "questral.convo"
local Npc = require "components.npc"
local Quest = require "questral.quest"
local Quip = require "questral.quip"
local rotwoodquestutil = require "questral.game.rotwoodquestutil"
local quest_strings = require("strings.strings_npc_potionmaker_dungeon").QUESTS.third_meeting
local recipes = require "defs.recipes"

------QUEST SETUP------

local Q = Quest.CreateJob()

-- ------CONVERSATIONS AND QUESTS------

local convo = function(cx) 
	cx:CompleteQuest()
end

local quip_convo = 
{
	tags = {"chitchat", "role_travelling_salesman", "seen_third_time", "cant_craft_potion"},
	tag_scores = { never_bought_potion = 100 },
	strings = quest_strings,
	quip = quest_strings.TALK,
	convo = convo,
	prefab = "npc_potionmaker_dungeon"
}

rotwoodquestutil.AddQuipConvo(Q, quip_convo)

return Q
