local Convo = require "questral.convo"
local Npc = require "components.npc"
local Quest = require "questral.quest"
local Quip = require "questral.quip"
local rotwoodquestutil = require "questral.game.rotwoodquestutil"
local quest_strings = require("strings.strings_npc_scout").QUESTS.megatreemon_forest.MT_celebrate_defeat_boss.MT_talk_after_konjur_heart

------QUEST SETUP------

local Q = Quest.CreateJob()

-- ------CONVERSATIONS AND QUESTS------

local convo = function(cx)
	cx:CompleteQuest()
	cx:Question("1")
		:Fn(function()
			cx:Question("2A") :Fn(function() cx:Talk("ANSWER_2B") end) --the 2A opt has an extra flavour chat line and then plays the mainline 2B response
			cx:Question("2B")
			cx:JoinAllOpt_Fn(function()
				local clicked_3C = false
				cx:Loop(function()
					if not clicked_3C then
						cx:Question("3A")
						cx:Question("3B")
						cx:Opt("QUESTION_3C") :Fn(function()
							clicked_3C = true
							if TheWorld:IsFlagUnlocked("wf_town_has_armorsmith") then
								cx:Talk("ANSWER_3C_HAVEBERNA")
							else
								cx:Talk("ANSWER_3C_NOBERNA")
								cx:Question("4_NOBERNA")
								cx:AddEnd("END")
							end
						end)
					else
						cx:AddEnd("END")
					end
				end)
			end)
	end)
end

local quip_convo =
{
	tags = {"chitchat", "role_scout", "has_killed_megatreemon", "just_deposited_megatreemon_heart", "in_town"},
	tag_scores = { just_deposited_megatreemon_heart = 200 },
	strings = quest_strings,
	quip = quest_strings.TALK,
	convo = convo,
	prefab = "npc_scout",
	important = true,
}

rotwoodquestutil.AddQuipConvo(Q, quip_convo)


return Q
