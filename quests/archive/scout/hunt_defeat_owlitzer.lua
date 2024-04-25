local Quest = require "questral.quest"
local biomes = require "defs.biomes"
local quest_strings = require("strings.strings_npc_scout").QUESTS.defeat_owlitzer
local QuestTemplateFn = require"questral.game.templates.quest_template_hunt"

------------------------------------------------------------------

local Q = Quest.CreateJob()

QuestTemplateFn(Q, biomes.locations.owlitzer_forest,
{
	quest_strings = quest_strings,
	last_boss = "megatreemon",

	objectives =
	{
		quest_intro =
		{
			convo_fn =	function(cx)
				local function EndConvo()
					cx.quest:Complete("quest_intro")
					cx:End()
				end

				local function AskAboutBoss() --> must be complete to end the convo
					cx:Opt("OPT_1C")
					:Fn(function()
						cx:Talk("OPT1C_RESPONSE")
						cx:Opt("OPT_4A")
							:Fn(function()
								cx:Talk("OPT4A_RESPONSE")
								EndConvo()
							end)
						cx:Opt("OPT_4B")
							:Fn(function()
								cx:Talk("OPT4B_RESPONSE")
								EndConvo()
							end)
					end)
				end

				local function ChatAboutWind() --> optional chats about what the nocturne grove is like
					cx:Opt("OPT_2")
						:Fn(function()
							cx:Talk("OPT2_RESPONSE")
							cx:Opt("OPT_3")
								:Fn(function()
									cx:Talk("OPT3_RESPONSE")
									AskAboutBoss()
								end)
							AskAboutBoss()
						end)
					AskAboutBoss()
				end

				cx:Talk("TALK")
				cx:Opt("OPT_1A")
					:Fn(function()
						cx:Talk("OPT1A_RESPONSE")
						ChatAboutWind()
					end)
				cx:Opt("OPT_1B")
					:Fn(function()
						cx:Talk("OPT1B_RESPONSE")
						ChatAboutWind()
					end)
				AskAboutBoss()
			end,
		},

		celebrate_defeat_boss =
		{
			do_add_heart = true,

			convo_fn = function(cx)
				cx:Opt("HUB_OPT")
					:Fn(function(cx)
						cx:Talk("TALK")
						cx:AddEnd("OPT_1")
							:Fn(function()
								cx.quest:Complete("celebrate_defeat_boss")
							end)
					end)
			end,
		},

		talk_after_konjur_heart =
		{
			convo_fn = function(cx)
				cx:Opt("HUB_OPT")
					:Fn(function(cx)
						local asked_why = false --player asks why flitt wants to re-power the wellspring

						local function EndOpt()
							cx:AddEnd("OPT_7C")
								:Fn(function()
									cx:Talk("OPT7C_RESPONSE")
									cx.quest:Complete("talk_after_konjur_heart")
								end)
						end

						local clicked_opt4B = false
						local clicked_opt4C = false
						local function Opt4MenuLoop()
							if asked_why == false then
								cx:Opt("OPT_4A")
									:Fn(function()
										--flitt tells the player why the foxtails want to power the wellspring
										asked_why = true
										cx:Talk("OPT4A_RESPONSE")
										cx:Opt("OPT_5A")
											:Fn(function()
												cx:Talk("OPT5A_RESPONSE")
											end)
										cx:Opt("OPT_5B")
											:Fn(function()
												cx:Talk("OPT5B_RESPONSE")
											end)
										cx:JoinAllOpt_Fn(function()
											Opt4MenuLoop()
										end)
									end)
							end
							if clicked_opt4B == false then
								cx:Opt("OPT_4B")
									:Fn(function()
										cx:Talk("OPT4B_RESPONSE")
										clicked_opt4B = true
										Opt4MenuLoop()
									end)
							end
							if clicked_opt4C == false then
								cx:Opt("OPT_4C")
									:Fn(function()
										cx:Talk("OPT4C_RESPONSE")
										clicked_opt4C = true
										Opt4MenuLoop()
									end)
							end
							cx:Opt("OPT_4D")
								:Fn(function()
									cx:Talk("OPT4D_RESPONSE")
									cx:Opt("OPT_6B")
										:Fn(function()
											cx:Talk("OPT6B_RESPONSE")
											cx:Opt("OPT_7A")
												:Fn(function()
													cx:Talk("OPT7A_RESPONSE")
													EndOpt()
												end)

											--end convo
											EndOpt()
										end)
								end)
						end

						local function Opt2B()
							cx:Opt("OPT_2B")
								:Fn(function()
									cx:Talk("OPT2B_RESPONSE")
									if asked_why == false then
										cx:Opt("OPT_3A")
											:Fn(function()
												--flitt tells the player why the foxtails want to power the wellspring
												asked_why = true
												cx:Talk("OPT4A_RESPONSE")
												cx:Opt("OPT_5A")
													:Fn(function()
														cx:Talk("OPT5A_RESPONSE")
														Opt4MenuLoop()
													end)
												cx:Opt("OPT_5B")
													:Fn(function()
														cx:Talk("OPT5B_RESPONSE")
														Opt4MenuLoop()
													end)
											end)
										cx:Opt("OPT_3B")
											:Fn(function()
												cx:Talk("OPT3B_RESPONSE")
												Opt4MenuLoop()
											end)
									else
										cx:Opt("OPT_3B_ALT")
											:Fn(function()
												cx:Talk("OPT3B_RESPONSE")
												Opt4MenuLoop()
											end)
									end
								end)
						end

						cx:Talk("TALK")

						cx:Opt("OPT_1A")
							:Fn(function()
								cx:Talk("OPT1A_RESPONSE")
							end)
						cx:Opt("OPT_1B")
							:Fn(function()
								cx:Talk("OPT1B_RESPONSE")
							end)

						cx:JoinAllOpt_Fn(function()
							cx:Talk("TALK2")
							cx:Opt("OPT_2A")
								:Fn(function()
									cx:Talk("OPT2A_RESPONSE")
									Opt2B()
								end)
							Opt2B()

							--[[cx:Opt("OPT_2C")
								:Fn(function()
									--KRIS
								end)]]
						end)
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

-- quest_helper.AddCompleteObjectiveOnCast(Q,
-- {
-- 	objective_id = "find_target_miniboss",
-- 	cast_id = "miniboss",
-- 	on_complete_fn = function(quest)
-- 		quest:Complete("quest_intro") -- if this is still active somehow
-- 		quest:ActivateObjective("defeat_target_miniboss")
-- 		quest:ActivateObjective("die_to_miniboss_convo")
-- 		quest:Cancel("pre_miniboss_death_convo")
-- 	end,
-- }):LogString("The {miniboss} was last sighted in {target_dungeon}.")
-- :UnlockPlayerFlagsOnComplete{"pf_owlitzer_miniboss_seen"}

-- Q:AddObjective("die_to_miniboss_convo")

-- Q:AddObjective("defeat_target_miniboss")
-- 	:LogString("Defeat {miniboss}.")
-- 	:UnlockPlayerFlagsOnComplete{"pf_owltizer_miniboss_defeated"}
-- 	:OnComplete(function(quest)
-- 		quest:ActivateObjective("celebrate_defeat_miniboss")
-- 		quest:ActivateObjective("find_target_boss")
-- 		quest:Cancel("die_to_miniboss_convo")
-- 	end)

-- Q:AddObjective("celebrate_defeat_miniboss")
-- 	:LogString("{giver} won't believe what you encountered in the woods.")

-- Q:OnTownChat("die_to_miniboss_convo", "giver", CreateCondition_DiedFighting("miniboss"))
-- 	:NotReadyToTranslate()
-- 	:Strings(quest_strings.die_to_miniboss_convo)
-- 	:TalkAndCompleteQuestObjective("TALK_DEATH_TO_MINIBOSS")

return Q