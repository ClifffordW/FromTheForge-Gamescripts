local Convo = require "questral.convo"
local Npc = require "components.npc"
local Quip = require "questral.quip"
local Quest = require "questral.quest"
local quest_helper = require "questral.game.rotwoodquestutil"
local Power = require "defs.powers.power"

local quest_strings = require("strings.strings_npc_konjurist").QUESTS.dgn_shop_powerupgrade
local quip_strings = require("strings.strings_npc_konjurist").QUIPS

local Q = Quest.CreateRecurringChat()
	:SetPriority(QUEST_PRIORITY.HIGH)

function Q:Quest_EvaluateSpawn(quester)
	return true
end

Q:SetIsUnimportant()

------CAST DECLARATIONS------

Q:UpdateCast("giver")
	:FilterForRole(Npc.Role.s.konjurist)

------QUIPS------
Q:AddQuips {
    Quip("konjurist", "quip_shop_upgrade")
        :PossibleStrings(quip_strings.SHOP_UPGRADE),
    Quip("konjurist", "quip_shop_nomoney")
        :PossibleStrings(quip_strings.SHOP_NOMONEY),
    Quip("konjurist", "quip_shop_noupgradable")
        :PossibleStrings(quip_strings.SHOP_NO_UPGRADABLE),
    Quip("konjurist", "quip_shop_done")
        :PossibleStrings(quip_strings.SHOP_HAS_UPGRADED),
    Quip("konjurist", "quip_chitchat")
    	:PossibleStrings(quip_strings.QUIP_CHITCHAT)
}

------FUNCTIONS------
local function GetUpgradeablePowerCount(player)
	local powers = player.components.powermanager:GetUpgradeablePowers()
	return #powers
end

--[[local function CanBuyUpgrade(player)
	local powers = player.components.powermanager:GetUpgradeablePowers()
	local cheapest_power = nil

	print("AYO !")
	for _,pow in ipairs(powers) do
		local pwr_price = Power.GetUpgradePrice(pow)
		player.components.powermanager:UpgradePower(pow.def)
		
		if cheapest_power == nil then
			cheapest_power = pwr_price
		elseif pwr_price < cheapest_power then
			cheapest_power = pwr_price
		end
	end

	if quest_helper.GetPlayerKonjur(player) >= cheapest_power then
		return true
	else
		return false
	end
end]]

-- TODO(quest): Handle upgrade tracking with an objective.
local function CountUpgradesCompletedThisMeeting(inst, player)
	return inst.components.conversation.temp.upgrades_done and inst.components.conversation.temp.upgrades_done[player] or 0
end

local function OpenUpgradeScreen(inst, player, cx)
	-- See quests/shop_powerupgrade/dgn_shop_powerupgrade.lua
end

------OBJECTIVE DECLARATIONS------

--other convos will get added here, including shop and done
Q:AddObjective("hub")
	:InitialState(QUEST_OBJECTIVE_STATE.s.ACTIVE)

--[[Q:AddObjective("chat_only")
	:InitialState(QUEST_OBJECTIVE_STATE.s.ACTIVE)]]

Q:AddObjective("done")
	:InitialState(QUEST_OBJECTIVE_STATE.s.ACTIVE)

Q:AddObjective("shop")
	:InitialState(QUEST_OBJECTIVE_STATE.s.ACTIVE)

-- Re-useable within multiple convos.
Q:AddStrings(quest_strings.lottie_desc)

------CONVERSATIONS AND QUESTS------
Q:OnAttract("hub", "giver")
	:SetPriority(Convo.PRIORITY.HIGH)
	:Strings(quest_strings.chat_only)
	:Fn(function(cx)
		local player = cx.quest:GetPlayer()
		local upg_pwr_count = GetUpgradeablePowerCount(player)
		
		--player has powers that can upgrade...
		if upg_pwr_count > 0 then
			--...and they've already bought at least 1 upgrade, do second shopping sesh quip
			if CountUpgradesCompletedThisMeeting(quest_helper.GetGiver(cx).inst, player) > 0 then
				cx:Quip("giver", { "konjurist", "quip_shop_done" })
			--...but they haven't bought anything yet, do regular shop quip
			else
				cx:Quip("giver", { "konjurist", "quip_shop_upgrade" })
			end
		--player has nothing to upgrade, do No Upgradeable chat
		else
			cx:Quip("giver", { "konjurist", "quip_shop_noupgradable" })
		end

		cx:PushAgentHub()
end)

Q:OnHub("shop", "giver", function(quest, node, sim)
	local player = quest:GetPlayer()
	return GetUpgradeablePowerCount(player) > 0
end)
	:SetPriority(Convo.PRIORITY.HIGH)
	:Strings(quest_strings.shop)
	:Fn(function(cx)
		--cx:Quip("giver", { "konjurist", "quip_shop_upgrade" })

		cx:Opt("OPT_UPGRADE")
			--~ :CompleteObjective() -- allow re-entering upgrade state
			:Fn(function()
				local node = quest_helper.GetGiver(cx)
				local player = cx.quest:GetPlayer()
				OpenUpgradeScreen(node.inst, player, cx)

				-- We aren't preventing re-entering the shop, so activate that
				-- objective but don't complete this one.
				cx.quest:ActivateObjective("done")
				cx:End()
			end)
	end)

return Q
