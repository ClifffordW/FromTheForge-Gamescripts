local Convo = require "questral.convo"
local Npc = require "components.npc"
local Quest = require "questral.quest"
local quest_helper = require "questral.game.rotwoodquestutil"
local Mastery = require"defs.masteries"

local quest_strings = require("strings.strings_npc_dojo_master").QUESTS.twn_shop_dojo.HUB

local Q = Quest.CreateJob()
	:SetPriority(QUEST_PRIORITY.HIGHEST)
	:SetIsImportant()
	:SetRateLimited(false)

function Q:Quest_EvaluateSpawn(quester)
	return true
end

Q:UpdateCast("giver")
	:FilterForPrefab("npc_dojo_master")

Q:AddObjective("unlocked_masteries")
	:InitialState(QUEST_OBJECTIVE_STATE.s.ACTIVE)
	:UnlockPlayerFlagsOnComplete{"pf_unlocked_masteries"}
	:OnComplete(function(quest)
		quest:Complete()
	end)

Q:OnHub("unlocked_masteries", "giver", function(quest)
	--is this the players first time opening the masteries menu?
	local should_unlock = false
	local loop_all_default_masteries = function(fn)
		for _, mastery_group in pairs(Mastery.Items) do		
			for _, def in pairs(mastery_group) do
				if def.default_unlocked and quest:GetPlayer().components.masterymanager:GetMastery(def) == nil then
					fn(def)
				end
			end
		end	
	end

	loop_all_default_masteries(function() should_unlock = true end)
	return should_unlock
end)
	:SetPriority(Convo.PRIORITY.HIGHEST)
	:Strings(quest_strings.masteries)
	:Fn(function(cx)
		cx:Opt("OPT_START_MASTERIES")
			:Fn(function(cx)
				local player = cx.GetPlayer(cx).inst

				--check if I have the default masteries yet
				local loop_all_default_masteries = function(fn)
					for _, mastery_group in pairs(Mastery.Items) do		
						for _, def in pairs(mastery_group) do
							if def.default_unlocked and player.components.masterymanager:GetMastery(def) == nil then
								fn(def)
							end
						end
					end				
				end


				local clicked_1A = false
				local clicked_1B = false
				local function MenuLoop()
					if not clicked_1A then
						cx:Opt("OPT_1A")
							:Fn(function()
								cx:Talk("OPT1A_RESPONSE")
								clicked_1A = true
								MenuLoop()
							end)
					end
					if not clicked_1B then
						cx:Opt("OPT_1B")
							:Fn(function()
								cx:Talk("OPT1B_RESPONSE")
								clicked_1B = true
								MenuLoop()
							end)
					end
					cx:AddEnd("OPT_1C")
						:MakeArmor()
						:Fn(function()
							cx:Talk("OPT1C_RESPONSE")
							cx.quest:Complete("unlocked_masteries")
							
							loop_all_default_masteries(function(def) 
								player.components.masterymanager:AddMasteryByDef(def, true)
							end)

							quest_helper.OpenShop(cx, require("screens.town.masteryscreen"))
						end)
				end

				cx:Talk("INTRO")
				MenuLoop()
			end)
	end)

return Q