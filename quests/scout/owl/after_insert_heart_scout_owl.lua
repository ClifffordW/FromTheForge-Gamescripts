local Convo = require "questral.convo"
local Npc = require "components.npc"
local Quest = require "questral.quest"
local Quip = require "questral.quip"
local rotwoodquestutil = require "questral.game.rotwoodquestutil"
local quest_strings = require("strings.strings_npc_scout").QUESTS.owlitzer_forest.owl_talk_after_konjur_heart

------QUEST SETUP------

local Q = Quest.CreateJob()

--------CONVERSATIONS AND QUESTS------

local convo = function(cx)
	cx:CompleteQuest()
	cx:Question("1A")
		:Fn(function()
			local clicked_2A = false
			local clicked_3D = false

			local function EndOpt()
				cx:AddEnd("QUESTION_END") :Fn(function() cx:Talk("ANSWER_END") end)
			end

			local function LoopMenu()
				cx:Loop(function()
					--question 3A has the same answer as 2A
					if not clicked_2A then
						cx:Opt("QUESTION_3A")
							:Fn(function()
								clicked_2A = true
								cx:Talk("ANSWER_2A")
							end)
					end
					cx:Question("3B")
					cx:Question("3C")
					if not clicked_3D then
						cx:Question("3D") :Fn(function() clicked_3D = true end)
					else
						cx:Question("5")
							:Fn(function()
								cx:EndLoop()
								cx:Question("6A") :Fn(function() EndOpt() end)
								EndOpt()
						end)
					end
				end)
			end

			--CONVO STARTS HERE
			cx:Question("2A")
				:Fn(function()
					clicked_2A = true
					cx:Question("4A")
					cx:Question("4B")
					cx:JoinAllOpt_Fn(function() LoopMenu() end)
				end)

			cx:Question("2B") :Fn(function() LoopMenu() end)
	end)
end

local quip_convo =
{
	tags = {"chitchat", "role_scout", "in_town", "has_killed_owlitzer", "just_deposited_owlitzer_heart"},
	tag_scores = { just_deposited_owlitzer_heart = 190 },
	strings = quest_strings,
	quip = quest_strings.TALK,
	convo = convo,
	prefab = "npc_scout",
	important = true,
}

rotwoodquestutil.AddQuipConvo(Q, quip_convo)


return Q
