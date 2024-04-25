local Quest = require "questral.quest"
local biomes = require "defs.biomes"
-- local quest_helper = require "questral.game.rotwoodquestutil"
local quest_strings = require("strings.strings_npc_scout").QUESTS.defeat_bandicoot
local QuestTemplateFn = require"questral.game.templates.quest_template_hunt"

------------------------------------------------------------------

local Q = Quest.CreateJob()

QuestTemplateFn(Q, biomes.locations.bandi_swamp,
{
	quest_strings = quest_strings,
	last_boss = "owlitzer",

	objectives =
	{
		quest_intro =
		{
			convo_fn = function(cx)
				--used to keep track of if player has clicked the acid and/or the spore explainer yet
				local acidspore_btnstates = {}
				acidspore_btnstates = { false, false }

				--option that ends the conversation at the end of every dialogue branch
				local function Opt3B_EndConvo()
					cx:AddEnd("OPT_3B")
						:Fn(function()
							cx:Talk("TALK2")
							cx.quest:Complete("quest_intro")
						end)
				end

				--used in AcidSporeMenu() to discuss the bandicoot, then end the conversation
				local function DescribeRotBossAndExit(btn_txt)
					cx:Opt(btn_txt) --end convo
						:Fn(function()
							cx:Talk("OPT2C_RESPONSE")
							Opt3B_EndConvo()
						end)
				end

				--used to explain the concept of Acid and Spores
				local function AcidSporeMenu(opt2C_alt_text)
					if acidspore_btnstates[1] == false then --player hasn't done the acid explainer yet

						--player hasnt done either explainer, show all buttons with no alt text
						if acidspore_btnstates[2] == false then 
							cx:Opt("OPT_2A") --acid
							:Fn(function()
								cx:Talk("OPT2A_RESPONSE")
								acidspore_btnstates[1] = true
								AcidSporeMenu(opt2C_alt_text)
							end)
							cx:Opt("OPT_2B") --spores
								:Fn(function()
									cx:Talk("OPT2B_RESPONSE")
									acidspore_btnstates[2] = true
									AcidSporeMenu(opt2C_alt_text)
								end)
							DescribeRotBossAndExit("OPT_2C") --end convo

						--player's hasnt done the acid explainer but already did the spore explainer, give acid and exit convo button their alt text
						else
							cx:Opt("OPT_2A_ALT") --acid
							:Fn(function()
								cx:Talk("OPT2A_RESPONSE")
								acidspore_btnstates[1] = true
								AcidSporeMenu(opt2C_alt_text)
							end)
							DescribeRotBossAndExit(opt2C_alt_text) --end convo (alt text)
						end
					else --player's already done the acid explainer

						--player hasnt done the spore explainer but already did the acid explainer, give spore + end convo buttons their alt text
						if acidspore_btnstates[2] == false then
							cx:Opt("OPT_2B_ALT") --spore
							:Fn(function()
								cx:Talk("OPT2B_RESPONSE")
								acidspore_btnstates[2] = true
								AcidSporeMenu(opt2C_alt_text)
							end)
							DescribeRotBossAndExit(opt2C_alt_text) --end convo (alt text)
						--player's done both explainers, show end convo button with alt text
						else
							DescribeRotBossAndExit(opt2C_alt_text) --end convo (alt text)
						end
					end
				end

				cx:Talk("TALK")
				cx:Opt("OPT_1A") --player's never been to the swamp before
					:Fn(function()
						cx:Talk("OPT1A_RESPONSE")
						AcidSporeMenu("OPT_2C_ALT")
					end)
				cx:Opt("OPT_1B") --player says they've been to the swamp before and probably wants to skip chatting
					:Fn(function()
						cx:Talk("OPT1B_RESPONSE")

						AcidSporeMenu("OPT_3A")
						Opt3B_EndConvo()
					end)
			end,
		},

		celebrate_defeat_boss = {
			do_add_heart = true,

			convo_fn = function(cx)
				cx:Opt("HUB_OPT")
					:Fn(function(cx)
						cx:Talk("TALK_FIRST_BOSS_KILL")
						cx.quest:Complete("celebrate_defeat_boss")
					end)
			end,
		},

		talk_after_konjur_heart = {
			convo_fn = function(cx)
				cx:Opt("HUB_OPT")
					:Fn(function()
						cx:Talk("TALK_GAVE_KONJUR_HEART")
						cx.quest:Complete("talk_after_konjur_heart")
					end)
			end,
		},
	},
	--[[
	chat_functions =
	{
		has_not_seen_boss = function(cx)
			cx:Opt("HUB_OPT")
				:Fn(function(cx)
					cx:Talk("TALK_FIRST_PLAYER_DEATH")
					cx.quest:Complete("has_not_seen_boss")
				end)
		end,

		die_to_boss_convo = function(cx)
			cx:Opt("HUB_OPT")
				:Fn(function(cx)
					cx:Talk("TALK_DEATH_TO_BOSS")
					cx.quest:Complete("die_to_boss_convo")
				end)
		end,
	},
	--]]
})

-- just disabled miniboss related stuff for now, we can bring it back in later if need be.

-- Q:TitleString(quest_strings.TITLE) -- use String for all pretty text
-- Q:DescString(quest_strings.DESC)

-- Q:AddObjective("pre_miniboss_death_convo")
-- 	:OnComplete(function(quest)
-- 		quest:Complete("quest_intro") -- if this is still active somehow
-- 	end)

-- Q:AddObjective("defeat_target_miniboss")
-- 	:LogString("Defeat {miniboss}.")
-- 	:OnComplete(function(quest)
-- 		-- Unlock new weapons when defeating miniboss
-- 		local player = quest:GetPlayer()

-- 		quest:ActivateObjective("celebrate_defeat_miniboss")
-- 		quest:ActivateObjective("find_target_boss")
-- 		quest:Cancel("die_to_miniboss_convo")
-- 	end)

-- Q:AddObjective("celebrate_defeat_miniboss")
-- 	:LogString("{giver} won't believe what you encountered in the woods.")

------CONVERSATIONS AND QUESTS------

-- Q:OnTownChat("die_to_miniboss_convo", "giver", quest_helper.CreateCondition_DiedFighting("miniboss"))
-- 	:NotReadyToTranslate()
-- 	:Strings(quest_strings.die_to_miniboss_convo)
-- 	:TalkAndCompleteQuestObjective("TALK_DEATH_TO_MINIBOSS")

-- Q:OnTownChat("celebrate_defeat_miniboss", "giver")
-- 	:NotReadyToTranslate()
-- 	:Strings(quest_strings.celebrate_defeat_miniboss)
-- 	:TalkAndCompleteQuestObjective("TALK_FIRST_MINIBOSS_KILL")

return Q
