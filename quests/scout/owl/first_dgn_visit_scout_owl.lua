local Convo = require "questral.convo"
local Npc = require "components.npc"
local Quest = require "questral.quest"
local Quip = require "questral.quip"
local rotwoodquestutil = require "questral.game.rotwoodquestutil"
local quest_strings = require("strings.strings_npc_scout").QUESTS.owlitzer_forest.owl_first_dgn_visit

------QUEST SETUP------

local Q = Quest.CreateJob()

-- ------CONVERSATIONS AND QUESTS------

local convo = function(cx)
	local opt2A_clicked = false

	local function MenuLoop()
		cx:Loop(function()
			cx:Question("2A") :Fn(function() opt2A_clicked = true end)

			--flavour option only available if you clicked the flavour options above
			if opt2A_clicked then
				cx:Question("3")
			end

			if not TheWorld:IsFlagUnlocked("wf_town_has_blacksmith") then
				--ask about your missing crew member
				cx:Question("2B")
			end

			--ask about the boss in the area (owlitzer)
			--using Opt instead of Question so it doesnt have the "..." and it's a little clearer this is the end option
			cx:Opt("QUESTION_2C")
				:Fn(function()
					cx:Talk("ANSWER_2C")
					cx:Question("4A")
						:End()
					cx:Question("4B")
						:End()
				end)
		end)
	end

	--CONVO STARTS HERE
	cx:CompleteQuest()
	cx:Question("1A") :Fn(function() MenuLoop() end)
	cx:Question("1B") :Fn(function() MenuLoop() end)
end

local quip_convo =
{
	tags = {"chitchat", "role_scout", "location_owlitzer_forest"},
	not_tags = {"has_killed_owlitzer", "in_town"},
	tag_scores =
	{
		location_owlitzer_forest = 100
	},
	strings = quest_strings,
	quip = quest_strings.TALK,
	convo = convo,
	important = true,
	prefab = "npc_scout",
}

rotwoodquestutil.AddQuipConvo(Q, quip_convo)


return Q
