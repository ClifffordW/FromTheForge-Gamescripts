local Convo = require "questral.convo"
local Npc = require "components.npc"
local Quip = require "questral.quip"
local Quest = require "questral.quest"
local quest_helper = require "questral.game.rotwoodquestutil"

local quest_strings = require("strings.strings_npc_scout").QUESTS.twn_friendlychat.dojo_master
local quip_strings = require("strings.strings_npc_scout").QUIPS.twn_friendlychat

local Q = Quest.CreateJob()
	:SetPriority(QUEST_PRIORITY.NORMAL)

function Q:Quest_EvaluateSpawn(quester)
	return TheDungeon:IsFlagUnlocked("wf_town_has_dojo")
end

Q:SetRateLimited(false)

Q:AddQuips {
    Quip("dojo_master", "end_chat")
        :PossibleStrings(quip_strings.QUIP_END_RESPONSE),
}

------CAST DECLARATIONS------

Q:UpdateCast("giver")
	:FilterForPrefab("npc_scout")

------OBJECTIVE DECLARATIONS------

Q:AddObjective("toot_recruited")
	:SetIsUnimportant()
	:InitialState(QUEST_OBJECTIVE_STATE.s.ACTIVE)
	:OnComplete(function(quest)
		quest:ActivateObjective("toot_and_flitt_origin")
    end)

Q:AddObjective("toot_and_flitt_origin")
	:SetIsUnimportant()
	:OnComplete(function(quest)
		quest:ActivateObjective("konjur_allergy")
    end)

Q:AddObjective("konjur_allergy")
	:SetIsUnimportant()

------CONVERSATIONS AND QUESTS------
Q:OnHub("toot_recruited", "giver", function(quest, node, sim) return TheWorld:IsFlagUnlocked("wf_town_has_dojo") end)
	:Strings(quest_strings.recruit_chat)
	:Fn(function(cx)
		cx:Opt("QUESTION")
			:Fn(function(cx)
				cx:Talk("TALK")
				cx:AddEnd()
					:Fn(function()
						cx:Quip("giver", { "scout", "end_chat" })
						cx.quest:Complete("toot_recruited")
					end)
		end)
	end)

Q:OnHub("toot_and_flitt_origin", "giver", function(quest, node, sim) return TheWorld:IsFlagUnlocked("wf_town_has_dojo") end)
	:Strings(quest_strings.toot_and_flitt_origin)
	:Fn(function(cx)
		cx:Opt("QUESTION")
			:Fn(function(cx)
				local function EarlyEnd()
					cx:AddEnd("PREEMPTIVE_END")
						:Fn(function()
							cx:Talk("PREEMPTIVE_END_RESPONSE")
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
						end)
					cx:Opt("OPT_2B")
						:Fn(function()
							cx:Talk("OPT2B_RESPONSE")
						end)
					EarlyEnd()
					cx:JoinAllOpt_Fn(function()
						cx:Talk("TALK3")
						cx:Opt("OPT_3A")
						cx:Opt("OPT_3B")
						cx:JoinAllOpt_Fn(function()
							cx:Talk("TALK4")
							cx:Opt("OPT_4")
								:Fn(function()
									cx:Talk("OPT4_RESPONSE")
									cx:Opt("OPT_5A")
										:Fn(function()
											cx:Talk("OPT5A_RESPONSE")
										end)
									cx:Opt("OPT_5B")
										:Fn(function()
											cx:Talk("OPT5B_RESPONSE")
										end)
									cx:JoinAllOpt_Fn(function()
									cx:AddEnd("OPT_END")
										:Fn(function()
											cx:Talk("END_RESPONSE")
											cx.quest:Complete("toot_and_flitt_origin")
										end)
								end)
							end)
							EarlyEnd()
						end)
					end)
				end)
			end)
	end)


Q:OnHub("konjur_allergy", "giver", function(quest, node, sim) return TheWorld:IsFlagUnlocked("wf_town_has_dojo") end)
	:Strings(quest_strings.konjur_allergy)
	:Fn(function(cx)
		cx:Opt("QUESTION")
			:Fn(function(cx)
				local function EarlyEnd()
					cx:AddEnd("PREEMPTIVE_END")
						:Fn(function()
							cx:Talk("PREEMPTIVE_END_RESPONSE")
						end)
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
						end)
					EarlyEnd()
					cx:JoinAllOpt_Fn(function()
						cx:Talk("TALK3")
						cx:Opt("OPT_3")
							:Fn(function()
								cx:Talk("OPT3_RESPONSE")
								cx:Opt("OPT_4A")
									:Fn(function()
										cx:Talk("OPT4A_RESPONSE")
									end)
								cx:Opt("OPT_4B")
									:Fn(function()
										cx:Talk("OPT4B_RESPONSE")
										cx:Talk("OPT4A_RESPONSE")
									end)
								cx:JoinAllOpt_Fn(function()
									cx:AddEnd()
										:Fn(function()
											cx:Quip("giver", { "scout", "end_chat" })
											cx.quest:Complete("konjur_allergy")
										end)
								end)
							end)
					end)
				end)
		end)
	end)


return Q
