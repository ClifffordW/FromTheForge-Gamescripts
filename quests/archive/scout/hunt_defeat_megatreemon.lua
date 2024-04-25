local Quest = require "questral.quest"
local QuestTemplateFn = require"questral.game.templates.quest_template_hunt"
local biomes = require "defs.biomes"
local quest_strings = require("strings.strings_npc_scout").QUESTS.defeat_megatreemon
local quest_helper = require "questral.game.rotwoodquestutil"

------------------------------------------------------------------

local Q = Quest.CreateJob()

QuestTemplateFn(Q, biomes.locations.treemon_forest,
{
	quest_strings = quest_strings,

	objectives =
	{
		celebrate_defeat_boss =
		{
			strings_override = quest_strings.celebrate_defeat_boss.defeated_regular,
			convo_fn = function(cx)
				cx:Opt("HUB_OPT")
					:Fn(function()
						local function EndConvo()
							cx.quest:Complete("celebrate_defeat_boss")
							quest_helper.ConvoCooldownGiver(cx, 5)
						end

						--find out how many crew members the player has recruited - if it's 2 or more they've rescued all the foxtails
						local function PickAltLine()
							if TheWorld:IsFlagUnlocked("wf_town_has_armorsmith") then
								cx:Talk("TALK2_ALT1")
							else
								cx:Talk("TALK2_ALT2")
							end
						end

						local function OPT_1C(btnText)
							cx:Opt(btnText)
								:Fn(function()
									cx:Talk("OPT1C_RESPONSE")
									cx:Opt("OPT_2A")
										:Fn(function()
											cx:Talk("OPT2A_RESPONSE")
											cx:AddEnd("OPT_2B_ALT")
												:Fn(function()
													EndConvo()
												end)
										end)
									cx:AddEnd("OPT_2B")
										:Fn(function()
											EndConvo()
										end)
								end)
						end

						cx:Talk("TALK")

						--chooses an alt line based on how many villagers the player has recruited
						PickAltLine()

						cx:Talk("TALK3")
						cx:Opt("OPT_1A")
							:Fn(function(cx)
								cx:Talk("OPT1A_RESPONSE")
								OPT_1C("OPT_1C_ALT")
							end)
						cx:Opt("OPT_1B")
							:Fn(function(cx)
								cx:Talk("OPT1B_RESPONSE")
								OPT_1C("OPT_1C_ALT")
							end)
						OPT_1C("OPT_1C")
					end)
			end,

			do_add_heart = true,
		},

		talk_after_konjur_heart =
		{
			convo_fn = function(cx)
				cx:Opt("HUB_OPT")
					:Fn(function()
						local function AddEndFn()
							cx:AddEnd("OPT_AGREE")
								:Fn(function()
									cx.quest:Complete("talk_after_konjur_heart")
								end)
						end

						--MENU LOGIC--
						local function MenuLoop(optAClicked, optBClicked)
							--ask if all hearts do the same thing
							if not optAClicked then
								cx:Opt("OPT_2A")
									:Fn(function()
										cx:Talk("OPT2A_RESPONSE")
										optAClicked = true
										MenuLoop(optAClicked, optBClicked)
									end)
							end

							--ask how long heart effects last
							if not optBClicked then
								cx:Opt("OPT_2B")
									:Fn(function()
										cx:Talk("OPT2B_RESPONSE")
										optBClicked = true
										MenuLoop(optAClicked, optBClicked)
									end)
							end

							--direction where to go next (changes whether or not you have berna already)
							if TheWorld:IsFlagUnlocked("wf_town_has_armorsmith") then
								cx:Opt("OPT_2C")
									:Fn(function()
										cx:Talk("OPT2C_RESPONSE_HAVEBERNA")
										AddEndFn()
									end)
							else
								cx:Opt("OPT_2C")
									:Fn(function()
										cx:Talk("OPT2C_RESPONSE_NOBERNA")
										cx:Opt("OPT_3_NOBERNA")
											:Fn(function()
												cx:Talk("OPT3_NOBERNA_RESPONSE")
												AddEndFn()
											end)
										AddEndFn()
									end)
							end
						end
						--END MENU LOGIC--

						--CONVO LOGIC START--
						cx:Talk("TALK")

						cx:Opt("OPT_1A")
							:Fn(function()
								cx:Talk("OPT1A_RESPONSE")
							end)
						cx:Opt("OPT_1B")

						cx:JoinAllOpt_Fn(function()
							cx:Talk("TALK2")

							MenuLoop(false, false)
						end)
					end)
			end,
		}
	},
})

return Q