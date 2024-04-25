local Convo = require "questral.convo"
local Npc = require "components.npc"
local Quest = require "questral.quest"
local Quip = require "questral.quip"
local rotwoodquestutil = require "questral.game.rotwoodquestutil"
local quest_strings = require("strings.strings_npc_scout").QUESTS.thatcher_swamp.thatcher_talk_after_konjur_heart

------QUEST SETUP------

local Q = Quest.CreateJob()

-- ------CONVERSATIONS AND QUESTS------

local convo = function(cx)
	cx:CompleteQuest()
	cx:Question("1") :Fn(function() cx:End() end)
end

local quip_convo =
{
	tags = {"chitchat", "role_scout", "in_town", "has_killed_thatcher", "just_deposited_thatcher_heart"},
	tag_scores = { just_deposited_thatcher_heart = 170 },
	strings = quest_strings,
	quip = quest_strings.TALK,
	important = true,
	convo = convo,
	prefab = "npc_scout",
}

rotwoodquestutil.AddQuipConvo(Q, quip_convo)

return Q
