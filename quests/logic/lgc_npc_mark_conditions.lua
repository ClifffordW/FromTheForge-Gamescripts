local Quest = require "questral.quest"
local quest_helper = require "questral.game.rotwoodquestutil"
local biomes = require "defs.biomes"

-- Only contains logic! Do not add convos to these quests.
local Q = Quest.CreateLogic()
	:SetWorldQuester()

function Q:Quest_EvaluateSpawn(quester)
	return true -- every world needs this quest
end

Q:AddCast("npc_dojo_master")
	:FilterForPrefab("npc_dojo_master")
	:AddOnCastFn(function(node)
		node.inst.components.markablenpc:AddMarkCondition("has_masteries", function(player)
	        for name, mastery in pairs(player.components.masterymanager.masteries) do
	            if mastery:IsComplete() and not mastery:IsClaimed() then
	                return true
	            end
	        end
		end)
	end)

return Q