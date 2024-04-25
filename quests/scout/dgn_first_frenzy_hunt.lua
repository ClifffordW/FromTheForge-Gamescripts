local Convo = require "questral.convo"
local Npc = require "components.npc"
local Quest = require "questral.quest"
local Quip = require "questral.quip"
local rotwoodquestutil = require "questral.game.rotwoodquestutil"
local quest_strings = require("strings.strings_npc_scout").QUESTS.first_frenzy_hunt

------QUEST SETUP------

local Q = Quest.CreateJob()

-- ------CONVERSATIONS AND QUESTS------

local convo = function(cx)

	--flitts final line changes depending if youre in single player or multiplayer
	local function ChooseEndResponse()
		if (#TheNet:GetPlayerList() == 1) then
			cx:Talk("END_TALK_SINGLEPLAYER")
		else
			cx:Talk("END_TALK_MULTIPLAYER")
		end
	end

	--just making it so i can edit all the end buttons in one place
	local function EndOpt()
		cx:AddEnd("END_OPT")
			:Fn(function()
				ChooseEndResponse()
			end)
	end

	cx:CompleteQuest()
	cx:Question("1A")
		:CompleteQuest()
		:Fn(function()
			cx:Question("2")
				:Fn(function()
					EndOpt()
				end)
			EndOpt()
		end)

	cx:Question("1B")
		:CompleteQuest()
		:Fn(function()
			cx:Question("2")
				:Fn(function()
					EndOpt()
				end)
			EndOpt()
		end)

	cx:AddEnd("QUESTION_1C")
		:CompleteQuest()
		:Fn(function()
			cx:Talk("ANSWER_1C")
			ChooseEndResponse()
		end)

end

local quip_convo =
{
	tags = {"chitchat", "role_scout", "frenzy_1"},
	not_tags = { "in_town" },
	strings = quest_strings,
	quip = quest_strings.TALK,
	convo = convo,
	prefab = "npc_scout"
}

rotwoodquestutil.AddQuipConvo(Q, quip_convo)

return Q
