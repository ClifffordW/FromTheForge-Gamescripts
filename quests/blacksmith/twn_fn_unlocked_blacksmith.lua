local Convo = require "questral.convo"
local Npc = require "components.npc"
local Quest = require "questral.quest"
local Quip = require "questral.quip"
local rotwoodquestutil = require "questral.game.rotwoodquestutil"
local quest_strings = require("strings.strings_npc_blacksmith").QUESTS.twn_function_unlocked

------QUEST SETUP------

local Q = Quest.CreateJob()

-- ------CONVERSATIONS AND QUESTS------

local convo = function(cx)
	cx:CompleteQuest()
	cx:Question("1")
		:Fn(function()
			local end_btn_title = "END_OPT"
			local clicked_2A = false
			local clicked_2B = false
			cx:Loop(function()

				cx:Question("2A") :Fn(function() clicked_2A = true end_btn_title = "END_OPT_ALT" end)

				cx:Question("2B") :Fn(function() clicked_2B = true end_btn_title = "END_OPT_ALT" end)
				--[[
				if clicked_2A and clicked_2B then
					cx:Question("3")
						:Fn(function()
							end_btn_title = "END_OPT_ALT2"
							cx:Question("5A")
							cx:Question("5B")
							cx:AddEnd(end_btn_title) :Fn(function() cx:Talk("END_TALK") end)
						end)
				end
				--]]
				cx:AddEnd(end_btn_title) :Fn(function() cx:Talk("END_TALK") end)
			end)	
		end)
end

local quip_convo = 
{
	tags = { "chitchat", "role_blacksmith", "in_town" },
	tag_scores = 
	{
		chitchat = 100
	},
	strings = quest_strings,
	quip = quest_strings.TALK,
	convo = convo,
	prefab = "npc_blacksmith"
}

rotwoodquestutil.AddQuipConvo(Q, quip_convo)

return Q
