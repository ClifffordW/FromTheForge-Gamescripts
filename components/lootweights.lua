local Recipes = require"defs/recipes"
local Consumable = require"defs/consumable"
local Equipment = require"defs/equipment"

local LootWeights = Class(function(self, inst)
	self.inst = inst

    self._update_loot = function() self:UpdateLootWeights() end
    self.inst:ListenForEvent("exit_room", self._update_loot)
    self.loot_weight = {}
end)

function LootWeights:UpdateLootWeights()
	self.loot_weight = {}

	local slots = 
	{
		Equipment.Slots.HEAD,
		Equipment.Slots.BODY,
		Equipment.Slots.WAIST,
		Equipment.Slots.WEAPON,
	}

	local players = TheNet:GetPlayersOnRoomChange()

	for _i, player in ipairs(players) do
		--update all the loot from all players, putting more weight on things I need to upgrade

		local total_needed = {}

		-- go over all my equipment and check their upgrade status
		for _, slot in ipairs(slots) do	

			local equipped_item = player.components.inventoryhoard:GetEquippedItem(slot)

			local items = player.components.inventoryhoard:GetSlotItems(slot)

			for _, item in pairs(items) do

				local base_ilvl = math.max(item:GetBaseItemLevel(), 1) -- we don't want to mult by 0

				local level = item:GetUpgradeLevel()

				local recipe = Recipes.FindItemUpgradeRecipeForItem(item)

				-- extra priority for equipped items
				local item_ingredient_weight = (item == equipped_item) and TUNING.LOOT_WEIGHTS.EQUIPPED_GEAR or TUNING.LOOT_WEIGHTS.HELD_GEAR

				-- Higher (base) ilvl items get higher loot priority. This is so your best gear is more likely to get loot.
				item_ingredient_weight = item_ingredient_weight * (1 + (TUNING.LOOT_WEIGHTS.BASE_ILVL_MULT * base_ilvl))

				if recipe then
					for ing, count in pairs(recipe.ingredients) do
						-- printf("[%s] Delta weight of %s", item:GetLocalizedName(), ing)
						-- priority for gear is additive so that the more things you have that need it, the higher chance you have to get it.
						self.loot_weight[ing] = (self.loot_weight[ing] or 0) + item_ingredient_weight
						total_needed[ing] = (total_needed[ing] or 0) + count
					end
				end

				recipe = Recipes.FindUsageUpgradeRecipeForItem(item)

				if recipe then
					for ing, count in pairs(recipe.ingredients) do
						-- printf("[%s] Delta weight of %s", item:GetLocalizedName(), ing)
						self.loot_weight[ing] = (self.loot_weight[ing] or 0) + item_ingredient_weight
						total_needed[ing] = (total_needed[ing] or 0) + count
					end
				end
			end

		end

		-- reduce weight if you have many of this ingredient
		for ing, weight in pairs(self.loot_weight) do
			local held_amount = player.components.inventoryhoard:GetStackableCount(Consumable.FindItem(ing)) or 0

			-- printf("[%s] %s -> %s", ing, held_amount, total_needed[ing])

			if held_amount >= (total_needed[ing] or 15) then
				local new_weight = math.max((weight * TUNING.LOOT_WEIGHTS.EXCESS_LOOT_MULT), TUNING.LOOT_WEIGHTS.DECOR)
				-- printf("[%s] Reduce Weight from %s to %s", ing, weight, new_weight)
				self.loot_weight[ing] = new_weight
			end
		end

		--lower weight on my decor items
		local DECOR_RECIPES = Recipes.FindRecipesForSlots({"DECOR"})
		for slot, slot_recipes in pairs(DECOR_RECIPES) do
			for id, recipe_def in pairs(slot_recipes) do
				if player.components.unlocktracker:IsRecipeUnlocked(id) then
					for ing, count in pairs(recipe_def.ingredients) do
						if not self.loot_weight[ing] then
							-- decor weights are NOT additive, and do not overwrite the weights calculated by equipped items
							-- printf("[Decor: %s] Delta weight of %s", id, ing)
							self.loot_weight[ing] = TUNING.LOOT_WEIGHTS.DECOR
						end
					end
				end
			end
		end
	end

	-- d_view(self.loot_weight)
end

function LootWeights:GetLootWeight(loot_name)
	return self.loot_weight[loot_name] or 0
end


return LootWeights
