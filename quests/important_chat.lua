local Convo = require "questral.convo"
local Npc = require "components.npc"
local Quest = require "questral.quest"

local Q = Quest.CreateLogic()
	:SetWorldQuester()

function Q:Quest_EvaluateSpawn(quester)
	return true -- every world needs this quest
end

------CAST DECLARATIONS------

local current_npcs = 
{
    --"npc_apothecary",
    "npc_armorsmith",
    "npc_blacksmith",
    "npc_cook",
    "npc_dojo_master",
    "npc_konjurist",
    "npc_market_merchant",
    "npc_potionmaker_dungeon",
    -- "npc_refiner",
    "npc_scout",
    "npc_specialeventhost",	
}

for _, id in ipairs(current_npcs) do
	Q:AddCast(id)
		:FilterForPrefab(id)
		:AddOnCastFn(function(node)
			node.inst.components.markablenpc:AddMarkCondition("has_important_convo", function(player)
			    local matcher = player.components.questcentral:GetQuipMatcher()
			    local tags = {"chitchat"}
			    tags = matcher:CollectRelevantTags(tags, node, player)
			    local _, match = matcher:LookupQuip(tags, nil, player)
		    	if match and match.quip:IsImportant() then
		    		return true
		    	end
			    return false
			end)
		end)
end

------OBJECTIVE DECLARATIONS------

Q:AddObjective("resident")
	:SetIsUnimportant()

return Q
