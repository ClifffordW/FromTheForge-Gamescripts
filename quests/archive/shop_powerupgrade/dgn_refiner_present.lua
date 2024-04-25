--[[local Convo = require "questral.convo"
local Npc = require "components.npc"
local Quip = require "questral.quip"
local Quest = require "questral.quest"
local quest_helper = require "questral.game.rotwoodquestutil"
local Power = require "defs.powers.power"

local quest_strings = require("strings.strings_npc_konjurist").QUESTS.dgn_shop_powerupgrade

local Q = Quest.CreateJob()
	:SetPriority(QUEST_PRIORITY.HIGHEST)
	:SetIsImportant()
	:SetRateLimited(false)

------CAST DECLARATIONS------

Q:UpdateCast("giver")
	:FilterForRole(Npc.Role.s.konjurist)

Q:AddCast("refiner")
	:FilterForPrefab("npc_refiner")
	:SetOptional()

------OBJECTIVE DECLARATIONS------

Q:AddObjective("chat_only")
	:InitialState(QUEST_OBJECTIVE_STATE.s.ACTIVE)

Q:AddObjective("done")
	:InitialState(QUEST_OBJECTIVE_STATE.s.ACTIVE)

Q:AddObjective("shop")
	:InitialState(QUEST_OBJECTIVE_STATE.s.ACTIVE)
	:OnComplete(function(quest)
		quest:ActivateObjective("done")
	end)

-- Re-useable within multiple convos.
Q:AddStrings(quest_strings.lottie_desc)

------CONVERSATIONS AND QUESTS------
Q:AddQuips {
    Quip("konjurist", "quip_shop_upgrade")
        :PossibleStrings(quest_strings.shop.QUIP_UPGRADE),
    Quip("konjurist", "quip_shop_nomoney")
        :PossibleStrings(quest_strings.shop.QUIP_NOMONEY),
    Quip("konjurist", "quip_shop_noupgradable")
        :PossibleStrings(quest_strings.shop.QUIP_NOUPGRADABLE),
    Quip("konjurist", "quip_shop_done")
        :PossibleStrings(quest_strings.done.TALK_DONE),
}

Q:OnHub("dodge_tutorial", "giver")
	:Strings(quest_strings)
	:ForbiddenPlayerFlags{"wf_town_has_refiner"}
	:Fn(function(cx)
if quest_helper.IsCastPresent(cx.quest, "refiner") then
			cx:Opt("OPT_LOTTIE_PRESENT")
				:Fn(function()
					cx:Talk("TALK_LOTTIE_DESC")
					cx:AddEnd()
				end)
		end

return Q]]
