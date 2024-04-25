local Convo = require "questral.convo"
local Npc = require "components.npc"
local Quest = require "questral.quest"
local Quip = require "questral.quip"
local rotwoodquestutil = require "questral.game.rotwoodquestutil"
local quest_strings = require("strings.strings_npc_market_merchant").QUESTS.dgn_hub.explain_shipping2

------QUEST SETUP------

local Q = Quest.CreateJob()

-- ------CONVERSATIONS AND QUESTS------

local convo = function(cx)
	cx:Question("1")
		:CompleteQuest()
		:End()
end

local quip_convo = 
{
	tags = {"chitchat", "role_market_merchant", "qc_dgn_firstmeeting_market", "pf_shipping_explained"},
	tag_scores = { chitchat = 100 },
	strings = quest_strings,
	quip = quest_strings.TALK,
	convo = convo,
	prefab = "npc_market_merchant",
}

rotwoodquestutil.AddQuipConvo(Q, quip_convo)

return Q
