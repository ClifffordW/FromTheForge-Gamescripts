local Convo = require "questral.convo"
local Npc = require "components.npc"
local Quest = require "questral.quest"
local Quip = require "questral.quip"
local rotwoodquestutil = require "questral.game.rotwoodquestutil"
local quest_strings = require("strings.strings_npc_scout").QUESTS.thatcher_swamp.thatcher_celebrate_defeat_boss

------QUEST SETUP------

local Q = Quest.CreateJob()

-- ------CONVERSATIONS AND QUESTS------

local convo = function(cx)
	cx:CompleteQuest()
	cx:Opt("QUESTION_1A")
	cx:Opt("QUESTION_1B")
	cx:JoinAllOpt_Fn(function()
		cx:Talk("ANSWER_1")
		cx:End()
	end)
end

local quip_convo =
{
	tags = {"chitchat", "role_scout", "in_town", "has_killed_thatcher", "has_thatcher_heart", "thatcher_heart_level_0"},
	tag_scores = { has_thatcher_heart = 90 },
	strings = quest_strings,
	quip = quest_strings.TALK,
	important = true,
	convo = convo,
	prefab = "npc_scout",
}

rotwoodquestutil.AddQuipConvo(Q, quip_convo)

return Q
