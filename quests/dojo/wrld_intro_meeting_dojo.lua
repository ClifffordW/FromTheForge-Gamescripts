local Convo = require "questral.convo"
local Npc = require "components.npc"
local Quest = require "questral.quest"
local Quip = require "questral.quip"

------QUEST SETUP------

local Q = Quest.CreateJob()
	:SetPriority(QUEST_PRIORITY.HIGH)
	:SetWorldQuester()

function Q:Quest_EvaluateSpawn(quester)
	return true
end

------CAST DECLARATIONS------

Q:UpdateCast("giver")
	:FilterForPrefab("npc_dojo_master")

Q:AddCast("flitt")
	:FilterForPrefab("npc_scout")

------OBJECTIVE DECLARATIONS------
Q:AddObjective("add_to_town")
	:InitialState(QUEST_OBJECTIVE_STATE.s.ACTIVE)
	:OnEvent("end_current_run", function(quest) quest:Complete("add_to_town") end)
	:OnComplete(function(quest) 
		quest:Complete() -- just complete the quest because the rest of this convo doesn't flow well right now
		-- quest:ActivateObjective("talk_in_town")	
	end)
	:UnlockWorldFlagsOnComplete{"wf_town_has_dojo"}

return Q
