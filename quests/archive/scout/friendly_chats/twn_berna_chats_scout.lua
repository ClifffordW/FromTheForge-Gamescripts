local Convo = require "questral.convo"
local Npc = require "components.npc"
local Quip = require "questral.quip"
local Quest = require "questral.quest"
local quest_helper = require "questral.game.rotwoodquestutil"

local quest_strings = require("strings.strings_npc_scout").QUESTS.twn_friendlychat.armorsmith
local quip_strings = require("strings.strings_npc_scout").QUIPS.twn_friendlychat

local Q = Quest.CreateJob()
	:SetPriority(QUEST_PRIORITY.NORMAL)

function Q:Quest_EvaluateSpawn(quester)
	return TheDungeon:IsFlagUnlocked("wf_town_has_armorsmith")
end

Q:SetRateLimited(false)

Q:AddQuips {
    Quip("scout", "end_chat")
        :PossibleStrings(quip_strings.QUIP_END_RESPONSE),
}

------CAST DECLARATIONS------

Q:UpdateCast("giver")
	:FilterForPrefab("npc_scout")

Q:AddCast("berna")
	:FilterForPrefab("npc_armorsmith")

------OBJECTIVE DECLARATIONS------

Q:AddObjective("berna_recruited")
	:SetIsUnimportant()
	:InitialState(QUEST_OBJECTIVE_STATE.s.ACTIVE)

------CONVERSATIONS AND QUESTS------

Q:OnHub("berna_recruited", "giver")
	:Strings(quest_strings.armorsmith_recruited)
	:Fn(function(cx)
		cx:Opt("ARMORSMITH_QUESTION")
			:Fn(function(cx)
				cx:Talk("ARMORSMITH_TALK")
				cx:AddEnd()
					:Fn(function()
						cx:Quip("giver", { "scout", "end_chat" })
						cx.quest:Complete("berna_recruited")
					end)
		end)
	end)


return Q
