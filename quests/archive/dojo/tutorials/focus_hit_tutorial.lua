local Convo = require "questral.convo"
local Npc = require "components.npc"
local Quest = require "questral.quest"

local quest_strings = require("strings.strings_npc_dojo_master").QUESTS.twn_shop_dojo.FOCUS_HIT_CONVERSATION
local questutil = require "questral.game.rotwoodquestutil"

local Q = Quest.CreateJob()
	:SetIsImportant()
	-- :SetRateLimited(false)

function Q:Quest_EvaluateSpawn(quester)
	local num_runs = quester.components.progresstracker:GetValue("total_num_runs") or 0
	return quester:HasEverCompletedQuest("dodge_tutorial") and num_runs >= 3
end

Q:UpdateCast("giver")
	:FilterForPrefab("npc_dojo_master")

Q:AddObjective("focus_hit_tutorial")
	:InitialState(QUEST_OBJECTIVE_STATE.s.ACTIVE)
	-- :UnlockPlayerFlagsOnComplete{"pf_dodge_pop_quiz_complete"}
	:OnComplete(function(quest)
		quest:Complete()
	end)

Q:OnHub("focus_hit_tutorial", "giver")
	:Strings(quest_strings)
	--:ForbiddenPlayerFlags{"pf_dodge_pop_quiz_complete"}
	:Fn(function(cx)
		local player = cx.GetPlayer(cx).inst

		cx:Opt("START"):Fn(function()
			local opt2B_clicked = false --"focus hit damage appears in blue"
			local opt2C_clicked = false --"focus hits are necessary to reach full damage potential"
			local opt2D_clicked = false --"focus hits are for nerds"

			local function EndConvo(treat)
				if treat == true then
					questutil.GiveItemReward(player, "konjur_soul_lesser", 1)
				end
				cx:End()
				cx.quest:Complete("focus_hit_tutorial")
			end

			cx:Talk("TALK")

			cx:Opt("OPT_1A")
			cx:Opt("OPT_1B")

			cx:JoinAllOpt_Fn(function()
				cx:Talk("TALK2")

				cx:Opt("OPT_2A")
					:Fn(function()
						cx:Talk("OPT2A_RESPONSE")
					end)
				cx:Opt("OPT_2B")
					:Fn(function()
						cx:Talk("OPT2B_RESPONSE")
						opt2B_clicked = true
					end)
				cx:Opt("OPT_2C")
					:Fn(function()
						cx:Talk("OPT2C_RESPONSE")
						opt2C_clicked = true
					end)
				cx:Opt("OPT_2D")
					:Fn(function()
						cx:Talk("OPT2D_RESPONSE")
						opt2D_clicked = true
					end)

				cx:JoinAllOpt_Fn(function()
					local function FinalOpt(button_str)
						cx:Opt(button_str)
						:Fn(function()
							cx:Talk("TALK3")
							EndConvo(true)
						end)
					end

					--regular options
					FinalOpt("OPT_3A")
					if opt2C_clicked == false then
						FinalOpt("OPT_3B")
					end
					if opt2B_clicked == false then
						FinalOpt("OPT_3C")
					end
					--jerk option
					if opt2D_clicked == true then
						cx:Opt("OPT_3D")
							:Fn(function()
								cx:Talk("OPT3D_RESPONSE")

								cx:Opt("OPT_4A")
									:Fn(function()
										cx:Talk("OPT4A_RESPONSE")
										EndConvo(true)
									end)
								cx:Opt("OPT_4B")
									:Fn(function()
										cx:Talk("OPT4B_RESPONSE")
										EndConvo(false)
									end)
							end)
					end
				end)
			end)
		end)
end)

return Q