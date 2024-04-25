local DebugNodes = require "dbui.debug_nodes"
local Mastery = require "defs.masteries"
local mastery_icons = require "gen.atlas.ui_ftf_mastery_icons"

local ItemCatalog = require("defs.itemcatalog")
local DebugLister = require "debug.inspectors.debug_lister"

local unlocked_via = function(item)
	if item.default_unlocked then
		return "default"
	end

	-- print("MasteryLister.unlocked_via")
	for _, mastery_group in pairs(Mastery.Items) do
		-- print("group: ", _, mastery_group)
		for mastery, mastery_data in pairs(mastery_group) do
			-- print("		mastery: ", mastery, mastery_data)
			if mastery_data.next_step then
				for _, next in ipairs(mastery_data.next_step) do
					-- print("			next: ", next, "item:", item.name)
					if next == item.name then
						return mastery
					end
				end
			end
		end
	end

	return ""
end

local MasteryLister = Class(DebugLister, function(self)
	DebugLister._ctor(self, "MasteryLister")

	self:SetColumns({
		{ key = "slot", name = "Slot" },
		{ key = "mastery_type", name = "Type" },
		{ key = "name", name = "Code Name" },
		{ key = "gamename", name = "Name",
			fn = function(item)
				local slot = item.slot
				local type = item.mastery_type
				local name = item.name

				if STRINGS.ITEMS[slot] and STRINGS.ITEMS[slot][type] and STRINGS.ITEMS[slot][type][name] then
					return tostring(STRINGS.ITEMS[slot][type][name].name)
				else
					return tostring("")
				end
			end
		},
		{ key = "desc", name = "Desc",
			fn = function(item)
				local slot = item.slot
				local type = item.mastery_type
				local name = item.name

				if STRINGS.ITEMS[slot] and STRINGS.ITEMS[slot][type] and STRINGS.ITEMS[slot][type][name] then
					return tostring(STRINGS.ITEMS[slot][type][name].desc)
				else
					return tostring("")
				end
			end
		},
		{ key = "icon", name = "Icon",
			fn = function(item)
				if item.icon == mastery_icons.tex.icon_mastery_temp then
					return ""
				else
					return function(ui, panel) 
						panel:AppendImageViewer(ui, item.icon, "##"..item.name) 
					end
				end
			end
		},
		{ key = "unlock", name = "Unlocked Via",
			fn = function(item)
				return unlocked_via(item)
			end
		},
		{ key = "hide", name = "Hide" },
		{ key = "corestones", name = "Corestones",
			fn = function(item)
				local corestones = 0
				for _, reward in ipairs( item.rewards ) do
					if reward.def.name == "konjur_soul_lesser" then
						corestones = corestones + reward.count
					end
				end

				return tostring(corestones)
			end
		},
	})

	for _, item_group in pairs(ItemCatalog.Mastery.Items) do
		for _, item in pairs(item_group) do
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

	self:SetSource(ItemCatalog.Mastery.Items)
end)

DebugNodes.MasteryLister = MasteryLister

return MasteryLister
