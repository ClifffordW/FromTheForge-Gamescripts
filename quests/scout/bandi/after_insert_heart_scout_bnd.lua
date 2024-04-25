local Convo = require "questral.convo"
local Npc = require "components.npc"
local Quest = require "questral.quest"
local Quip = require "questral.quip"
local rotwoodquestutil = require "questral.game.rotwoodquestutil"
local quest_strings = require("strings.strings_npc_scout").QUESTS.bandicoot_swamp.bandi_talk_after_konjur_heart

------QUEST SETUP------

local Q = Quest.CreateJob()

-- ------CONVERSATIONS AND QUESTS------

local convo = function(cx)
	cx:CompleteQuest()
	cx:GetPlayer().inst:UnlockFlag("pf_after_bandi_flitt")
	cx:Question("1A")
		:Fn(function()
			local function EndOpt()
				cx:AddEnd("QUESTION_END")
					:Fn(function() cx:Talk("ANSWER_END") end)
			end

			cx:Question("2")
				:Fn(function() EndOpt() end)
			EndOpt()
		end)
end

local quip_convo =
{
	tags = {"chitchat", "role_scout", "in_town", "has_killed_bandicoot", "just_deposited_bandicoot_heart"},
	tag_scores = { just_deposited_bandicoot_heart = 180 },
	strings = quest_strings,
	quip = quest_strings.TALK,
	convo = convo,
	prefab = "npc_scout",
	important = true,
}

rotwoodquestutil.AddQuipConvo(Q, quip_convo)

return Q
