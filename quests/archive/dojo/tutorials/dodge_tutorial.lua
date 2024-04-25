local Convo = require "questral.convo"
local Npc = require "components.npc"
local Quest = require "questral.quest"

local quest_strings = require("strings.strings_npc_dojo_master").QUESTS.twn_shop_dojo.DODGE_CONVERSATION
local questutil = require "questral.game.rotwoodquestutil"

local Q = Quest.CreateJob()
	:SetIsImportant()
	-- :SetRateLimited(false)

function Q:Quest_EvaluateSpawn(quester)
	return TheDungeon:IsFlagUnlocked("wf_town_has_dojo")
end

Q:UpdateCast("giver")
	:FilterForPrefab("npc_dojo_master")

Q:AddObjective("dodge_tutorial")
	:InitialState(QUEST_OBJECTIVE_STATE.s.ACTIVE)
	:UnlockPlayerFlagsOnComplete{"pf_dodge_pop_quiz_complete"}
	:OnComplete(function(quest)
		quest:Complete()
	end)

Q:OnHub("dodge_tutorial", "giver")
	:Strings(quest_strings)
	--:ForbiddenPlayerFlags{"pf_dodge_pop_quiz_complete"}
	:Fn(function(cx)
		cx:Opt("START")
			:Fn(function()
				local opt1B_clicked = false --"its more important than attacking"
				local opt1C_clicked = false --"you dodge with SPACE"
				local opt1D_clicked = false --"dodgings for wimps"
				local player = cx.GetPlayer(cx).inst

				local function EndConvo(treat)
					if treat == true then
						questutil.GiveItemReward(player, "konjur_soul_lesser", 1)
					end
					cx.quest:Complete("dodge_tutorial")
					cx:End()
				end
				cx:Talk("TALK")
				cx:Opt("OPT_1A")
					:Fn(function()
						cx:Talk("OPT1A_RESPONSE")
				end)
				cx:Opt("OPT_1B")
					:Fn(function()
						cx:Talk("OPT1B_RESPONSE")
						opt1B_clicked = true
				end)
				cx:Opt("OPT_1C")
					:Fn(function()
						cx:Talk("OPT1C_RESPONSE")
						opt1C_clicked = true
				end)
				cx:Opt("OPT_1D")
					:Fn(function()
						cx:Talk("OPT1D_RESPONSE")
						opt1D_clicked = true
				end)

				cx:JoinAllOpt_Fn(function()
					cx:Talk("TALK2")
					if opt1C_clicked == false then
						cx:Opt("OPT_2A")
							:Fn(function()
								cx:Talk("OPT2A_RESPONSE")
								cx:Talk("TALK3")
								EndConvo(true)
						end)
					end
					if opt1B_clicked == false then
						cx:Opt("OPT_2B")
							:Fn(function()
								cx:Talk("OPT2B_RESPONSE")
								cx:Talk("TALK3")
								EndConvo(true)
						end)
					end
					cx:Opt("OPT_2C")
							:Fn(function()
								cx:Talk("OPT2C_RESPONSE")
								cx:Talk("TALK3")
								EndConvo(true)
						end)
					if opt1D_clicked == true then
						cx:Opt("OPT_2D")
							:Fn(function()
								cx:Talk("OPT2D_RESPONSE")
								cx:Opt("OPT_3A")
									:Fn(function()
										cx:Talk("OPT3A_RESPONSE")
										EndConvo(true)
									end)
								cx:Opt("OPT_3B")
									:Fn(function()
										cx:Talk("OPT3B_RESPONSE")
										EndConvo(false)
									end)
						end)
					end
				end)
			end)
end)

return Q