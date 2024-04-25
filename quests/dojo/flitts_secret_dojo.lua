local Quest = require "questral.quest"
local rotwoodquestutil = require "questral.game.rotwoodquestutil"
local quest_strings = require("strings.strings_npc_dojo_master").QUESTS.flitts_secret

local Q = Quest.CreateJob()

local convo = function(cx)
	cx:Question("1") :CompleteQuest()
		:Fn(function()
			cx:Question("2A")
			cx:Question("2B")
			--cx:Question("2C")
			cx:JoinAllOpt_Fn(function()
				cx:Question("3A")
				--cx:Question("3B")
				cx:JoinAllOpt_Fn(function()
					cx:Question("4A")
					cx:Question("4B")
					cx:JoinAllOpt_Fn(function()
						cx:AddEnd("END_QUESTION")
							:Fn(function()
								cx:Talk("END_ANSWER")
								cx:InjectHubOptions()
							end)
					end)
				end)
			end)
		end)
end

local quip_convo =
{
	tags = {"chitchat", "role_hunter", "in_town", "pf_after_bandi_flitt", "pf_unlocked_masteries"},
	tag_scores ={ pf_after_bandi_flitt = 90 },
	strings = quest_strings,
	quip = quest_strings.TALK,
	convo = convo,
	important = true,
	prefab = "npc_dojo_master"
}

rotwoodquestutil.AddQuipConvo(Q, quip_convo)

return Q