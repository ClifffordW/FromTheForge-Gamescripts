local Convo = require "questral.convo"
local Npc = require "components.npc"
local Quest = require "questral.quest"
local Quip = require "questral.quip"
local rotwoodquestutil = require "questral.game.rotwoodquestutil"
local quest_strings = require("strings.strings_npc_potionmaker_dungeon").QUESTS.first_meeting
local recipes = require "defs.recipes"

------QUEST SETUP------

local Q = Quest.CreateJob()

-- ------CONVERSATIONS AND QUESTS------

local convo = function(cx)
	local player = cx:GetPlayer().inst
    local admission_recipe = recipes.ForSlot.PRICE.potion_refill
    if not admission_recipe:CanPlayerCraft(player) then
    	--no money
		cx:Question("NO_RESOURCES_1"):Fn(function()
			cx:CompleteQuest()
			cx:Opt("QUESTION_NO_RESOURCES_2A")
			cx:Opt("QUESTION_NO_RESOURCES_2B")
			cx:JoinAllOpt_Fn(function()
				cx:Talk("ANSWER_NO_RESOURCES_2")
				cx:Question("NO_RESOURCES_3A")
				cx:Question("NO_RESOURCES_3B")
			end)
		end)
	else
		--yes money
		cx:Question("HAS_RESOURCES_1"):Fn(function()
			cx:Opt("QUESTION_HAS_RESOURCES_2A")
			cx:Opt("QUESTION_HAS_RESOURCES_2B")
			cx:JoinAllOpt_Fn(function()
				cx:Talk("ANSWER_HAS_RESOURCES_2")
				cx:CompleteQuest()

				cx:InjectHubOptions()
				cx:AddEnd()
			end)
		end)
	end
end

local quip_convo = 
{
	tags = {"chitchat", "role_travelling_salesman", "seen_first_time"},
	tag_scores = { never_bought_potion = 100 },
	strings = quest_strings,
	quip = quest_strings.TALK,
	convo = convo,
	prefab = "npc_potionmaker_dungeon"
}

rotwoodquestutil.AddQuipConvo(Q, quip_convo)

return Q
