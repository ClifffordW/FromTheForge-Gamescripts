local Convo = require "questral.convo"
local Npc = require "components.npc"
local Quest = require "questral.quest"
local Quip = require "questral.quip"
local fmodtable = require "defs.sound.fmodtable"
local quest_helper = require "questral.game.rotwoodquestutil"
local Mastery = require"defs.masteries"

local quest_strings = require("strings.strings_npc_dojo_master").QUESTS.twn_shop_dojo

local Q = Quest.CreateRecurringChat()
	:AddStrings(quest_strings)

function Q:Quest_EvaluateSpawn(quester)
	return TheDungeon:IsFlagUnlocked("wf_town_has_dojo")
end

------CAST DECLARATIONS------

Q:UpdateCast("giver")
	:FilterForPrefab("npc_dojo_master")

------OBJECTIVE DECLARATIONS------

Q:AddObjective("resident")
	:SetIsUnimportant()
	:InitialState(QUEST_OBJECTIVE_STATE.s.ACTIVE)

------CONVERSATIONS AND QUESTS------

Q:OnHub("resident", "giver", function(quest)
	--has the player had the masterys intro explained
	return quest:GetPlayer():IsFlagUnlocked("pf_unlocked_masteries")
end)
	:Fn(function(cx)
		cx:Opt("OPT_OPEN_MASTERY")
			:MakeArmor()
			:Fn(function()
				quest_helper.OpenShop(cx, require("screens.town.masteryscreen"))
				cx:End()
			end)
	end)

return Q
