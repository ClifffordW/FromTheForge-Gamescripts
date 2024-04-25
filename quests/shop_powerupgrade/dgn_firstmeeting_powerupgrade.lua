local Quest = require "questral.quest"
local rotwoodquestutil = require "questral.game.rotwoodquestutil"
local quest_strings = require("strings.strings_npc_konjurist").QUESTS.first_meeting

------QUEST SETUP------

local Q = Quest.CreateJob()

------CONVERSATIONS AND QUESTS------

local convo = function(cx)
	cx:Question("1A")
	cx:Question("1B")

	cx:JoinAllOpt_Fn(function()
		cx:Talk("TALK2")
		cx:CompleteQuest() --after talking, complete the quest, not before
		cx:Question("2A")
			:Fn(function()
				cx:InjectHubOptions()
				cx:AddEnd()
			end)

		cx:InjectHubOptions()
		cx:AddEnd()
	end)
end

local quip_convo =
{
	tags = {"chitchat", "role_konjurist"},
	tag_scores = { seen_first_time = 100 },
	strings = quest_strings,
	quip = quest_strings.TALK,
	convo = convo,
	prefab = "npc_konjurist"
}

rotwoodquestutil.AddQuipConvo(Q, quip_convo)

return Q
