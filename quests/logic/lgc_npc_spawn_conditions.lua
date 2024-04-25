local Quest = require "questral.quest"
local quest_helper = require "questral.game.rotwoodquestutil"
local biomes = require "defs.biomes"

-- Only contains logic! Do not add convos to these quests.
local Q = Quest.CreateLogic()
	:SetWorldQuester()

function Q:Quest_EvaluateSpawn(quester)
	return true -- every world needs this quest
end

function Q:Quest_Start()
	-- runs on every load.
	local objectives = self:GetAllObjectives()
	for _, objective_id in ipairs(objectives) do
		local state = self:GetObjectiveState(objective_id)
		if state == QUEST_OBJECTIVE_STATE.s.INACTIVE then
			self:ActivateObjective(objective_id)
		end
	end
end

Q:AddCast("npc_scout")
	:FilterForPrefab("npc_scout")

Q:AddCast("npc_armorsmith")
	:FilterForPrefab("npc_armorsmith")

Q:AddCast("npc_blacksmith")
	:FilterForPrefab("npc_blacksmith")

Q:AddCast("npc_cook")
	:FilterForPrefab("npc_cook")

Q:AddObjective("spawn_flitt_in_dungeon")
	:AppearInDungeon_Entrance(nil, "npc_scout")
	:InitialState(QUEST_OBJECTIVE_STATE.s.ACTIVE)

quest_helper.AddNPCToTown(Q, "npc_armorsmith", "wf_town_has_armorsmith")
    :AppearInDungeon_QuestRoom_Exclusive(function(quest, biome_location)
        local has_berna = TheWorld:IsFlagUnlocked("wf_town_has_armorsmith") -- the town already has berna
        local has_seen_alphonse = TheWorld:IsFlagUnlocked("wf_seen_npc_market_merchant") -- this world has been to the market room before
        local is_in_forest = biome_location.id == biomes.locations.treemon_forest.id
        return not has_berna and has_seen_alphonse and is_in_forest
    end, "npc_armorsmith")

quest_helper.AddNPCToTown(Q, "npc_blacksmith", "wf_town_has_blacksmith")
	:AppearInDungeon_Hype_Exclusive(function(quest, biome_location)
		local has_hamish = TheWorld:IsFlagUnlocked("wf_town_has_blacksmith") -- the town already has hamish
		local in_owl_forest = biome_location.id == biomes.locations.owlitzer_forest.id -- is in the owl forest
		return not has_hamish and in_owl_forest
	end, "npc_blacksmith")

quest_helper.AddNPCToTown(Q, "npc_cook", "wf_town_has_cook")
	:AppearInDungeon_QuestRoom_Exclusive(function(quest, biome_location)
		return false -- Glorabelle is disabled for now
		-- local has_glorabelle = TheWorld:IsFlagUnlocked("wf_town_has_cook") -- the town already has glorabelle
		-- local can_meet_glorabelle = quest:GetPlayer():IsFlagUnlocked("pf_can_meet_cook") -- the player can meet glorabelle
		-- local in_owl_forest = quest_helper.IsInDungeon("owlitzer_forest") -- is in the owl forest
		-- return not has_glorabelle and can_meet_glorabelle and in_owl_forest
	end, "npc_cook")

return Q