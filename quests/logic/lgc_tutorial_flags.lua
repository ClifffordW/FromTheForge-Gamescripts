local Quest = require "questral.quest"
local quest_helper = require "questral.game.rotwoodquestutil"

-- Only contains logic! Do not add convos to these quests.
local Q = Quest.CreateLogic()

function Q:Quest_EvaluateSpawn(quester)
	return true -- every player needs this quest
end

Q:AddCast("first_miniboss")
	:CastFn(function(quest, root)
		return root:AllocateEnemy("yammo_miniboss")
	end)

quest_helper.AddCompleteObjectiveOnCast(Q,
{
	objective_id = "find_first_miniboss",
	cast_id = "first_miniboss",
	default_active = true,
}):UnlockPlayerFlagsOnComplete{"pf_first_miniboss_seen"}

Q:AddObjective("defeat_first_miniboss")
	:InitialState(QUEST_OBJECTIVE_STATE.s.ACTIVE)
	:UnlockPlayerFlagsOnComplete{"pf_first_miniboss_defeated"}
	:OnEvent("player_kill", function(quest, victim)
		quest_helper.CompleteObjectiveIfCastMatches(quest, "defeat_first_miniboss", "first_miniboss", victim.prefab)
	end)
	:OnComplete(function(quest) quest:Complete() end)

return Q