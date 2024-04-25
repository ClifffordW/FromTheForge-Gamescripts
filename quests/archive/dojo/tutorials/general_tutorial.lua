local Convo = require "questral.convo"
local Npc = require "components.npc"
local Quest = require "questral.quest"
local soundutil = require "util.soundutil"
local fmodtable = require "defs.sound.fmodtable"

local quest_strings = require("strings.strings_npc_dojo_master").QUESTS.twn_shop_dojo.LESSONS
local quest_helper = require "questral.game.rotwoodquestutil"

local unlock_tiers = {1, 3, 8} --number of unlocked flags required to trigger a reward tier. There are actually 4 tiers but the fourth is award for completing all tutorials, so the existing tutorials are counted programmatically
local unlockable_title_IDs = {"teacherspet", "hunterphd"}

local Q = Quest.CreateJob()
	:SetPriority(QUEST_PRIORITY.HIGHEST)
	:SetRateLimited(false)

function Q:Quest_EvaluateSpawn(quester)
	return TheDungeon:IsFlagUnlocked("wf_town_has_dojo")
end

Q:UpdateCast("giver")
	:FilterForPrefab("npc_dojo_master")

Q:AddObjective("general_tutorial")
	:InitialState(QUEST_OBJECTIVE_STATE.s.ACTIVE)
	-- :UnlockPlayerFlagsOnComplete{"pf_dodge_pop_quiz_complete"}
	:SetPriority(Convo.PRIORITY.HIGH)
	:OnComplete(function(quest)
		quest:Complete()
	end)

local unlock_tiers = {1, 3, 8} --number of unlocked flags required to trigger a reward tier. There are actually 4 tiers but the fourth is award for completing all tutorials, so the existing tutorials are counted programmatically
local unlockable_title_IDs = {"teacherspet", "hunterphd"}

Q:OnHub("general_tutorial", "giver")
	:Strings(quest_strings)
	--:ForbiddenPlayerFlags{"pf_dodge_pop_quiz_complete"}
	:Fn(function(cx)
		local general_cat = { "POWER_DROPS", "REVIVE_MECHANICS", "FRENZIED_HUNTS"}
		local combat_cat = { "FOCUS_HITS", "CRITICAL_HITS", "HIT_STREAKS"}
		local defense_cat = { "DODGE", "PERFECT_DODGE", "DODGE_CANCEL"}
		--local weapons_cat = { "HAMMER", "SPEAR", "SHOTPUT", "CANNON"}
		local equipment_cat = { "POTIONS", "WEIGHT_SYSTEM", "LUCK_STAT"}

		local player = cx.GetPlayer(cx).inst
		--DECLARE FUNCTIONS--
		--count how many of the tutorials the player has read
		local function NumTutorialCompletions(current_tutorial) --current tutorial is the tutorial the player just read

			local flag_string = ("pf_%s"):format(current_tutorial)

			if not player:IsFlagUnlocked(flag_string) then
				--unlock flag for this tutorial
				player:UnlockFlag(flag_string)

				--check how many flags are unlocked total
				--flags are based on the string name of the tutorial only, so lessons can be shuffled around the different lesson categories without affecting existing unlocks
				local total_num_tutorials = 0
				local unlock_count = 0
				for _,list in pairs({general_cat, combat_cat, defense_cat, equipment_cat}) do
					for _,tutorial in pairs(list) do
						total_num_tutorials = total_num_tutorials + 1
						if player:IsFlagUnlocked(flag_string) then
							unlock_count = unlock_count + 1
						end
					end
				end
				
				--REWARDS--
				if unlock_count == unlock_tiers[1] and not player:IsFlagUnlocked("pf_tier_one_tutorial_reward") then
					cx:Talk("TUTORIALS.REWARD_TIER_ONE.TALK")

					quest_helper.GiveItemReward(player, "konjur_soul_lesser", 1)
					
					--prevent re-giving the tutorial reward if more tutorials are added at a later date
					player:UnlockFlag("pf_tier_one_tutorial_reward")
				--unlocking the number of flags needed for the second tier gives the "Teacher's Pet" title
				elseif unlock_count == unlock_tiers[2] and not player:IsFlagUnlocked("pf_tier_two_tutorial_reward") then
					cx:Talk("TUTORIALS.REWARD_TIER_TWO.TALK")
					
					--quest_helper.UnlockCosmeticTitle(player, unlockable_title_IDs[1])
					quest_helper.GiveItemReward(player, "konjur_soul_lesser", 1)
					
					--prevent re-giving the tutorial reward if more tutorials are added at a later date
					player:UnlockFlag("pf_tier_two_tutorial_reward")
				--unlocking the number of flags needed for the third tier gives a corestone
				elseif unlock_count == unlock_tiers[3] and not player:IsFlagUnlocked("pf_tier_three_tutorial_reward") then
					cx:Talk("TUTORIALS.REWARD_TIER_THREE.TALK")

					quest_helper.GiveItemReward(player, "konjur_soul_lesser", 1)

					--prevent re-giving the tutorial reward if more tutorials are added at a later date
					player:UnlockFlag("pf_tier_three_tutorial_reward")
				--unlocking the number of flags needed for the second tier gives the "Hunter, PhD" title
				elseif unlock_count == total_num_tutorials and not player:IsFlagUnlocked("pf_tier_four_tutorial_reward")then
					cx:Talk("TUTORIALS.REWARD_TIER_FOUR.TALK")

					--quest_helper.UnlockCosmeticTitle(player, unlockable_title_IDs[2])
					quest_helper.GiveItemReward(player, "konjur_soul_lesser", 2)

					--prevent re-giving the tutorial reward if more tutorials are added at a later date
					player:UnlockFlag("pf_tier_four_tutorial_reward")
					--[[cx:Opt("TUTORIALS.REWARD_TIER_FOUR.OPT_1A")
						:Fn(function()
							cx:Talk("TUTORIALS.REWARD_TIER_FOUR.OPT1A_RESPONSE")
							cx:End()
						end)
					cx:Opt("TUTORIALS.REWARD_TIER_FOUR.OPT_1B")
						:Fn(function()
							cx:Talk("TUTORIALS.REWARD_TIER_FOUR.OPT1B_RESPONSE")
							cx:End()
						end)
					cx:Opt("TUTORIALS.REWARD_TIER_FOUR.OPT_1C")
						:Fn(function()
							cx:Talk("TUTORIALS.REWARD_TIER_FOUR.OPT1C_RESPONSE")
							cx:End()
						end)
					]]
				end

			end
		end

		--Home menu where player can select from the lesson categories (General, Combat, Weapons, Equipment)
		local function LessonMenu()
			--see whether or not the player has completed all the lessons under a category heading so the button string can change
			local function EvalueCatCompletion(category)
				for k,tutorial in pairs(category) do
					--PLAYER HASN'T READ THIS TUTORIAL YET
					local flag_string = ("pf_%s"):format(tutorial)
					if not player:IsFlagUnlocked(flag_string) then
						return false
					end
				end
				return true
			end

			local function SubMenu(category, lessons_table) --category is the category (General/Combat/Defense/etc) and lessons_table is a table of all the individual tutorials in that category
				cx:Opt("BACK_BTN")
					:Fn(function()
						cx:Talk("BACK_BTN_RESPONSE")
						LessonMenu()
					end)

				for k,tutorial in pairs(lessons_table) do
					--PLAYER HASN'T READ THIS TUTORIAL YET
					local flag_string = ("pf_%s"):format(tutorial)
					if not player:IsFlagUnlocked(flag_string) then
						cx:Opt("TUTORIALS." .. category .. "." .. tostring(tutorial) .. "_BTN")
							:Fn(function()
								--play lesson message
								cx:Talk("TUTORIALS." .. category .. "." .. tostring(tutorial))
								
								--see how many tutorials the player has completed, give a reward if needed
								NumTutorialCompletions(tostring(tutorial))
								
								--go back to the lesson menu
								SubMenu(category, lessons_table)
							end)
					--PLAYERS ALREADY READ THIS TUTORIAL BUT IS REPEATING IT
					else
						cx:Opt("TUTORIALS." .. category .. "." .. tostring(tutorial) .. "_BTN_ALT")
							:Fn(function()
								cx:Talk("REPEAT_LESSON_FIRST_LINE")
								--play lesson message
								cx:Talk("TUTORIALS." .. category .. "." .. tostring(tutorial))
								
								--see how many tutorials the player has completed, give a reward if needed
								NumTutorialCompletions(tostring(tutorial))
								
								--go back to the lesson menu
								SubMenu(category, lessons_table)
							end)
					end
				end

				cx:AddEnd("END_BTN_SUBMENU")
					:Fn(function()
						cx:Talk("END_BTN_SUBMENU_RESPONSE")
					end)
			end
			
			cx:Talk("TALK_SELECT_CATEGORY")

			--CATEGORY MENU--
			--General Concepts SubMenu
			if EvalueCatCompletion(general_cat) then
				cx:Opt("TUTORIALS.GENERAL_BTN_ALT")
					:Fn(function()
						cx:Talk("TALK_SELECT_GENERAL")
						SubMenu("GENERAL", general_cat)
					end)
			else
				cx:Opt("TUTORIALS.GENERAL_BTN")
					:Fn(function()
						cx:Talk("TALK_SELECT_GENERAL")
						SubMenu("GENERAL", general_cat)
					end)
			end

			--Combat Concepts SubMenu
			if EvalueCatCompletion(combat_cat) then
				cx:Opt("TUTORIALS.COMBAT_BTN_ALT")
					:Fn(function()
						cx:Talk("TALK_SELECT_COMBAT")
						SubMenu("COMBAT", combat_cat)
					end)
			else
				cx:Opt("TUTORIALS.COMBAT_BTN")
					:Fn(function()
						cx:Talk("TALK_SELECT_COMBAT")
						SubMenu("COMBAT", combat_cat)
					end)
			end

			--Defense Concepts SubMenu
			if EvalueCatCompletion(defense_cat) then
				cx:Opt("TUTORIALS.DEFENSE_BTN_ALT")
					:Fn(function()
						cx:Talk("TALK_SELECT_DEFENSE")
						SubMenu("DEFENSE", defense_cat)
					end)
			else
				cx:Opt("TUTORIALS.DEFENSE_BTN")
					:Fn(function()
						cx:Talk("TALK_SELECT_DEFENSE")
						SubMenu("DEFENSE", defense_cat)
					end)
			end

			--Weapons SubMenu (WIP)
		--[[
			if EvalueCatCompletion(weapons_cat) then
				cx:Opt("TUTORIALS.WEAPONS_BTN_ALT")
					:Fn(function()
						cx:Talk("TALK_SELECT_WEAPONS")
						SubMenu("WEAPONS", weapons_cat)
					end)
			else
				cx:Opt("TUTORIALS.WEAPONS_BTN")
					:Fn(function()
						cx:Talk("TALK_SELECT_WEAPONS")
						SubMenu("WEAPONS", weapons_cat)
					end)
			end
		]]

			--Equipment SubMenu
			if EvalueCatCompletion(equipment_cat) then
				cx:Opt("TUTORIALS.EQUIPMENT_BTN_ALT")
					:Fn(function()
						cx:Talk("TALK_SELECT_EQUIPMENT")
						SubMenu("EQUIPMENT", equipment_cat)
					end)
			else
				cx:Opt("TUTORIALS.EQUIPMENT_BTN")
					:Fn(function()
						cx:Talk("TALK_SELECT_EQUIPMENT")
						SubMenu("EQUIPMENT", equipment_cat)
					end)
			end

			cx:AddEnd("END_BTN_MAINMENU")
					:Fn(function()
						cx:Talk("END_BTN_MAINMENU_RESPONSE")
					end)
		end

		cx:Opt("Quest.twn_shop_dojo.OPT_TEACH")
			:Fn(function()
				LessonMenu()
			end)
end)

return Q
