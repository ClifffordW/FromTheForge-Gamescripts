local Convo = require "questral.convo"
local Npc = require "components.npc"
local Quip = require "questral.quip"
local Quest = require "questral.quest"
local rotwoodquestutil = require "questral.game.rotwoodquestutil"
local Power = require "defs.powers.power"
local soundutil = require "util.soundutil"
local fmodtable = require "defs.sound.fmodtable"
local audioid = require "defs.sound.audioid"

local quest_strings = require("strings.strings_npc_konjurist").QUESTS.shop_powerupgrade

local Q = Quest.CreateRecurringChat()
	:SetPriority(QUEST_PRIORITY.HIGH)

function Q:Quest_EvaluateSpawn(quester)
	return true
end

Q:SetIsUnimportant()

------CAST DECLARATIONS------

Q:UpdateCast("giver")
	:FilterForRole(Npc.Role.s.konjurist)

------FUNCTIONS------

local function OnDoUpgrade(inst, player)
	local upgrades = player:GetTempData('free_power_upgrades') or 0
	player:SetTempData('free_power_upgrades', upgrades + 1)
end

local function OpenUpgradeScreen(inst, player, cx)
	local PowerSelectionScreen = require "screens.dungeon.powerselectionscreen"
	if inst.components.conversation then
		inst.components.conversation:StopInteractableSnapshot()
	end

	local cb_fn = function()
		OnDoUpgrade(inst, player)
		rotwoodquestutil.ConvoCooldownGiver(cx, 145 * TICKS)
	end

	while rotwoodquestutil.GetUpgradeablePowerCount(player) > 0 do
		local powers = player.components.powermanager:GetUpgradeablePowers()

		local free = player:GetTempData('free_power_upgrades') == nil

		local screen = cx:PresentCallbackScreen(PowerSelectionScreen, player, powers, PowerSelectionScreen.SelectAction.s.Upgrade, cb_fn, free)
		-- screen has shown and exited at this point.
		local complete_state = screen.complete_state
		if complete_state == PowerSelectionScreen.CompleteState.s.ShowAgainAfterAnim then
			cx:DelaySeconds(0.1)  -- ensure animation started
			cx:WaitForAnimOver(player)
		else
			dbassert(complete_state == PowerSelectionScreen.CompleteState.s.Exit, "Update this quest if you add new states.")
			break
		end
	end
end

------OBJECTIVE DECLARATIONS------

Q:AddObjective("shop")
	:InitialState(QUEST_OBJECTIVE_STATE.s.ACTIVE)

------CONVERSATIONS AND QUESTS------
Q:OnHub("shop", "giver", function(quest, node, sim)
	return true
end)
	:SetPriority(Convo.PRIORITY.HIGH)
	:Strings(quest_strings)
	:Fn(function(cx)
		local player = cx.quest:GetPlayer()
		--[[NOTE on ReqCondition():
			This option requires a condition (player has at least 1 upgradeable power) in order to be a valid option,
			otherwise the button is greyed out and it displays a tooltip ("TT_NO_POWERS"),
			which is simply a string that can be found in the same place as the quest's other strings]]
		cx:Opt("OPT_UPGRADE")
			:ReqCondition(rotwoodquestutil.GetUpgradeablePowerCount(player) > 0, "TT_NO_POWERS")
			:Fn(function()
				local node = rotwoodquestutil.GetGiver(cx)
				OpenUpgradeScreen(node.inst, player, cx)
				cx:End()
			end)
	end)

return Q
