local Convo = require "questral.convo"
local Quest = require "questral.quest"
local recipes = require "defs.recipes"
local rotwoodquestutil = require "questral.game.rotwoodquestutil"

local quest_strings = require ("strings.strings_npc_potionmaker_dungeon").QUESTS.dgn_shop_potion

local admission_recipe = recipes.ForSlot.PRICE.potion_refill

local Q = Quest.CreateRecurringChat()
	:AddStrings(quest_strings)

function Q:Quest_EvaluateSpawn(quester)
	return true
end

local function OnStartCooking(inst, player)
	-- Don't CraftItemForPlayer because the recipe is the entry cost.
	admission_recipe:TakeIngredientsFromPlayer(player)

	player.components.potiondrinker:RefillPotion()
	player.components.progresstracker:IncrementValue("total_potion_refills_hoggins")
	TheDungeon:GetDungeonMap():RecordActionInCurrentRoom("travelling_salesman")
end

------CAST DECLARATIONS------

Q:UpdateCast("giver")
	:FilterForRole("travelling_salesman")

function Q:Quest_Start()
	-- Set param here to use as "{primary_ingredient_name}" in strings.
	self:SetParam("primary_ingredient_name", rotwoodquestutil.GetPrettyRecipeIngredient(admission_recipe))
	self:SetParam("admission_recipe", admission_recipe)
end

------OBJECTIVE DECLARATIONS------

Q:AddObjective("shop")
	:InitialState(QUEST_OBJECTIVE_STATE.s.ACTIVE)

------CONVERSATIONS AND QUESTS------

Q:OnHub("shop", "giver", function(quest)		
		return true
	end)
	:Fn(function(cx)
		local player = cx.quest:GetPlayer()
		cx:Opt("OPT_CONFIRM")
			:CompleteObjective()
			:ReqCondition(not rotwoodquestutil.PlayerHasRefilledPotion(player), "TT_ALREADY_REFILLED")
			:ReqCondition(rotwoodquestutil.PlayerNeedsPotion(player), "TT_FULL_POTION")
			:ReqCondition(admission_recipe:CanPlayerCraft(player), "TT_CANT_AFFORD")
			:Fn(function(cx)
				local giver = rotwoodquestutil.GetGiver(cx)
				OnStartCooking(giver.inst, cx.quest:GetPlayer())
				cx:End()
			end)
			:Talk("TALK_DONE_GAME")
	end)

return Q
