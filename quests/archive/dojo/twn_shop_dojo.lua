local Convo = require "questral.convo"
local Npc = require "components.npc"
local Quest = require "questral.quest"
local Quip = require "questral.quip"
local fmodtable = require "defs.sound.fmodtable"
local quest_helper = require "questral.game.rotwoodquestutil"
local Mastery = require"defs.masteries"

local quest_strings = require("strings.strings_npc_dojo_master").QUESTS.twn_shop_dojo.HUB
local quip_strings = require("strings.strings_npc_dojo_master").QUESTS.twn_shop_dojo.QUIPS

local Q = Quest.CreateRecurringChat()
	:AddStrings(quest_strings)

function Q:Quest_EvaluateSpawn(quester)
	return TheDungeon:IsFlagUnlocked("wf_town_has_dojo")
end

Q:SetRateLimited(false)

------CAST DECLARATIONS------

Q:UpdateCast("giver")
	:FilterForPrefab("npc_dojo_master")

------OBJECTIVE DECLARATIONS------

Q:AddObjective("resident")
	:SetIsUnimportant()
	:InitialState(QUEST_OBJECTIVE_STATE.s.ACTIVE)

Q:AddQuips {
    Quip("dojo_master", "tip_quip")
        :PossibleStrings(quip_strings.GOODBYE_QUIPS),
    Quip("dojo_master", "tip_quip_mp")
        :PossibleStrings(quip_strings.GOODBYE_QUIPS_MP)
}

------CONVERSATIONS AND QUESTS------

Q:OnHub("resident", "giver", function(quest)
	--has the player had the masterys intro explained
	return quest:GetPlayer():IsFlagUnlocked("pf_unlocked_masteries")
end)
	:SetPriority(QUEST_PRIORITY.HIGHEST)
	:Fn(function(cx)
		cx:Opt("OPT_OPEN_MASTERY")
			:MakeArmor()
			:Fn(function()
				quest_helper.OpenShop(cx, require("screens.town.masteryscreen"))
				cx:End()
			end)
	end)

Q:OnTownShopChat("resident", "giver")
	:Fn(function(cx)
		--CONVO LOGIC--
		local agent = cx.quest:GetCastMember("giver")

		if not agent.skip_talk then
			cx:Quip("giver", { "dojo_master", "tip_quip" })
			--[[if AllPlayers[2] == nil then
				cx:Quip("giver", { "dojo_master", "tip_quip" })
			else
				cx:Quip("giver", { "dojo_master", "tip_quip_mp, tip_quip" })
			end]]
		else
			agent.skip_talk = nil -- HACK
		end

		cx:PushAgentHub()
	end)

return Q
