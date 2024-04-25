local Quest = require "questral.quest"
local Convo = require "questral.convo"
local quest_strings = require("strings.strings_npc_scout").QUESTS.defeat_yammo
local biomes = require "defs.biomes"
------------------------------------------------------------------

local Q = Quest.CreateJob()

local yammo_prefab = "yammo_miniboss"

Q:SetRateLimited(false)
Q:SetIsImportant()
Q:SetPriority(QUEST_PRIORITY.HIGHEST)

function Q:Quest_EvaluateSpawn(quester)
	-- spawn the quest for the hunt if the player has the hunt unlocked
	return quester:IsLocationUnlocked(biomes.locations.treemon_forest.id)
end

Q:UpdateCast("giver")
	:FilterForPrefab("npc_scout")

Q:AddCast("target_dungeon")
	:CastFn(function(quest, root)
		return root:GetLocationActor(biomes.locations.treemon_forest.id)
	end)

Q:MarkLocation{"target_dungeon"}

Q:AddCast("miniboss")
	:CastFn(function(quest, root)
		return root:AllocateEnemy(yammo_prefab)
	end)

local function is_struggling_on_miniboss(runs, quest, node, sim)
	--player
	local player = quest:GetPlayer()

	-- player has done at least 3 runs, has seen yammo, but has not killed yammo.
	local num_runs = player.components.progresstracker:GetValue("total_num_runs") or 0
	local has_seen_miniboss = player.components.unlocktracker:IsEnemyUnlocked(yammo_prefab)
	local has_killed_miniboss = player.components.progresstracker:GetNumKills(yammo_prefab) > 0

	return num_runs >= runs and has_seen_miniboss and not has_killed_miniboss
end

Q:AddObjective("celebrate_defeat_miniboss")
	:InitialState(QUEST_OBJECTIVE_STATE.s.ACTIVE)
	:OnComplete(function(quest)
		quest:Complete()
	end)

Q:AddObjective("flitt_miniboss_tip")
	:InitialState(QUEST_OBJECTIVE_STATE.s.ACTIVE)

--miniboss tip hookups
Q:OnTownChat("flitt_miniboss_tip", "giver", function(...) return is_struggling_on_miniboss(5, ...) end)
	:SetPriority(Convo.PRIORITY.HIGH)
	:Strings(quest_strings.multiple_die_to_miniboss_convo)
	:Fn(function(cx)
		local function Opt1B_EndConvo()
			cx:AddEnd("OPT_1B")
				:Fn(function(cx)
					cx:Talk("OPT1B_RESPONSE")
				end)
				:CompleteObjective()
		end

		cx:Talk("TALK")
		cx:Opt("OPT_1A")
			:Fn(function(cx)
				cx:Talk("OPT1A_RESPONSE")
				Opt1B_EndConvo()
			end)
		Opt1B_EndConvo()
	end)

--KILL YAMMO
Q:OnTownChat("celebrate_defeat_miniboss", "giver", function(quest)
		return quest:GetPlayer().components.progresstracker:GetNumKills(yammo_prefab) > 0
	end)
	:SetPriority(Convo.PRIORITY.HIGHEST)
	:Strings(quest_strings.celebrate_defeat_miniboss)
	:Fn(function(cx)
		cx:Talk("TALK_FIRST_MINIBOSS_KILL")
		cx:Opt("OPT_1A")
			:Fn(function(cx)
				cx:Talk("OPT1A_RESPONSE")
				cx:Talk("TALK2")
			end)
			:CompleteObjective()
		cx:Opt("OPT_1B")
			:Fn(function(cx)
				cx:Talk("OPT1B_RESPONSE")
				cx:Talk("TALK2")
			end)
			:CompleteObjective()
	end)

return Q