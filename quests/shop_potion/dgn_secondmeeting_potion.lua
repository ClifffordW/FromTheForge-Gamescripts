local Convo = require "questral.convo"
local Npc = require "components.npc"
local Quest = require "questral.quest"
local Quip = require "questral.quip"
local rotwoodquestutil = require "questral.game.rotwoodquestutil"
local quest_strings = require("strings.strings_npc_potionmaker_dungeon").QUESTS.second_meeting
local recipes = require "defs.recipes"

------QUEST SETUP------

local Q = Quest.CreateJob()

-- ------CONVERSATIONS AND QUESTS------

local convo = function(cx)
	local player = cx:GetPlayer().inst
    local admission_recipe = recipes.ForSlot.PRICE.potion_refill

	cx.quest:SetParam("primary_ingredient_name", rotwoodquestutil.GetPrettyRecipeIngredient(admission_recipe))
	cx.quest:SetParam("admission_recipe", admission_recipe)

    local can_craft = admission_recipe:CanPlayerCraft(player)
    local needs_potion = rotwoodquestutil.PlayerNeedsPotion(player)

    if not can_craft then
    	--no money
		cx:Question("NO_RESOURCES_1"):Fn(function()
			cx:Opt("QUESTION_NO_RESOURCES_2A")
			cx:Opt("QUESTION_NO_RESOURCES_2B")
			cx:JoinAllOpt_Fn(function()
				cx:Talk("ANSWER_NO_RESOURCES_2")
				cx:CompleteQuest()
			end)
		end)
	elseif can_craft and not needs_potion then
		--yes money... but no space
		cx:Question("NO_SPACE_1"):Fn(function()
			if not player.components.potiondrinker:CanDrinkPotion() then
				-- if player is full health...
				cx:Question("NO_SPACE_2_FULL_HEALTH"):Fn(function()
					cx:CompleteQuest()
				end)
			else
				local function TalkAndEnd(line)
					cx:Talk(line)
					cx:CompleteQuest()
				end
				-- Otherwise, continue pitch. Ask player to dump potion out.
				cx:Talk("ANSWER_NO_SPACE_1_MISSING_HEALTH")

				cx:Opt("QUESTION_NO_SPACE_2A")
					:Fn(function() TalkAndEnd("ANSWER_NO_SPACE_2A") end)
				cx:Opt("QUESTION_NO_SPACE_2B")
					:Fn(function() TalkAndEnd("ANSWER_NO_SPACE_2B") end)
			end
		end)
	elseif can_craft and needs_potion then
		-- yes money, yes space!
		cx:Question("HAS_RESOURCES_1"):Fn(function()

			local function AgreeToBuy()
				cx:CompleteQuest()
				cx:InjectHubOptions()
				cx:AddEnd()
			end

			local function DontWantPotion()
				-- ok I'll buy it
				cx:Question("HAS_RESOURCES_3A"):Fn(AgreeToBuy)
				-- no I really don't want it
				cx:Question("HAS_RESOURCES_3B"):Fn(function()
					cx:CompleteQuest()
				end)
			end

			-- why should I buy?
			cx:Question("HAS_RESOURCES_2A"):Fn(function()
				-- ok I'll buy it
				cx:Question("HAS_RESOURCES_3A"):Fn(AgreeToBuy)
				-- I don't want it
				cx:Question("HAS_RESOURCES_2B"):Fn(DontWantPotion)
			end)

			-- I don't want it
			cx:Question("HAS_RESOURCES_2B"):Fn(DontWantPotion)
		end)
	end
end

local quip_convo = 
{
	tags = {"chitchat", "role_travelling_salesman", "seen_second_time"},
	tag_scores = { never_bought_potion = 100 },
	strings = quest_strings,
	quip = quest_strings.TALK,
	convo = convo,
	prefab = "npc_potionmaker_dungeon"
}

rotwoodquestutil.AddQuipConvo(Q, quip_convo)

return Q
