local DebugNodes = require "dbui.debug_nodes"
local Constructable = require "defs.constructable"
local Mastery = require "defs.masteries"
local MetaProgress = require "defs.metaprogression"
local lume = require"util.lume"
local monsterutil = require"util.monsterutil"
local Consumable = require "defs.consumable"
local ItemCatalog = require("defs.itemcatalog")
local DebugLister = require "debug.inspectors.debug_lister"

local unlocked_via = function(item)
	for _, mastery_group in pairs(Mastery.Items) do
		for _, mastery in pairs(mastery_group) do
			for _, reward in ipairs(mastery.rewards) do
				if (reward.slot == Constructable.Slots.DECOR or reward.slot == Constructable.Slots.STRUCTURES) and reward.def.name == item.name then
					return "Mastery: "..mastery.name
				end
			end
		end
	end

	for groupname, progress_group in pairs(MetaProgress.Items) do
		-- print("Progress Group:", groupname)
		for progressname, progress in pairs(progress_group) do
			-- print("		Progress:", progressname)
			for _, reward_data in ipairs(progress.rewards) do
				-- print("			Reward Data:", _)
				-- If this is a reward group, this will be a table. Otherwise, it will be a single def.

				if reward_data.rewards then
					for _, reward in ipairs(reward_data.rewards) do
						if (reward.slot == Constructable.Slots.DECOR or reward.slot == Constructable.Slots.STRUCTURES) and reward.def.name == item.name then
							return groupname.."."..progressname
						end
					end
				end
			end
		end
	end

	return ""
end


local ConstructablesLister = Class(DebugLister, function(self)
	DebugLister._ctor(self, "ConstructablesLister")

	self:SetColumns({
		{ key = "name", name = "Name" },
		{ key = "slot", name = "Slot" },
		{ key = "rarity", name = "Rarity" },
		{ key = "category", name = "Category",
			fn = function(item)
				for _, category in pairs(ItemCatalog.Constructable.Categories) do
					if item.tags and item.tags[category] ~= nil then
						return category
					end
				end
				return ""
			end
		},
		{ key = "ingredient", name = "Ingredient" },
		{ key = "ingredient_count", name = "Ingredient Count" },
		{ key = "icon", name = "Icon",
			fn = function(item)
				if item.icon == "images/icons_ftf/item_temp.tex" then
					return ""
				else
					return function(ui, panel) 
						panel:AppendImageViewer(ui, item.icon, "##"..item.name) 
					end
				end
			end
		},
		{ key = "unlocked", name = "Unlocked Via",
			fn = function(item)
				return unlocked_via(item)
			end
		},
		{ key = "drop_location", name = "Drop Location" },
		{ key = "ingredient_rarity", name = "Ingredient Rarity" },
	})

	self:Refresh()
	self:SetSource(ItemCatalog.Constructable)
end)

function ConstructablesLister:Refresh()	

	--jcheng: expand the rows by the ingredients so we can put this in a spreadsheet and pivot on the numbers
	local expanded_items = {}
	local used_items = {}
	for _, item_group in pairs(ItemCatalog.Constructable.Items) do
		for _, item in pairs(item_group) do
			if item.tags.playercraftable ~= nil then
				for ingredient, count in pairs(item.ingredients) do
					local item_copy = deepcopy(item)
					item_copy.ingredient = ingredient
					item_copy.ingredient_count = count
					item_copy.ingredient_rarity = Consumable.Items.MATERIALS[ingredient].rarity
					local locations = monsterutil.GetLocationsForItem(ingredient)
					item_copy.drop_location = #locations > 0 and locations[1].id or ""
					table.insert( expanded_items, item_copy )
					used_items[ingredient] = true
				end
			end
		end
	end

	local materials = Consumable.Items.MATERIALS
	local unused_items = {}
	for key, item in pairs(materials) do
		if used_items[item.name] == nil then
			unused_items[item.name] = true
		end
	end

	for item_name, _ in pairs(unused_items) do
		local locations = monsterutil.GetLocationsForItem(item_name)
		if #locations > 0 then
			table.insert(expanded_items, {
				drop_location = locations[1].id,
				name = "UNUSED",
				ingredient = item_name,
				ingredient_count = 0,
				ingredient_rarity = Consumable.Items.MATERIALS[item_name].rarity,
			})
		end
	end

	for _, item in ipairs(expanded_items) do
		local item_v = {}
		for _, v in ipairs(self:GetColumns()) do
			if v.fn then
				item_v[v.key] = v.fn(item)
			else
				item_v[v.key] = tostring(item[v.key])
			end
		end

		item_v["data"] = item

		self:AddValue(item_v)
	end
end

DebugNodes.ConstructablesLister = ConstructablesLister

return ConstructablesLister
