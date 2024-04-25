local DebugDraw = require "util.debugdraw"
local DebugNodes = require "dbui.debug_nodes"
local iterator = require "util.iterator"
local csvutil = require "util.csvutil"
local Mastery = require "defs.masteries"
local biomes = require"defs.biomes"
local monsterutil = require"util.monsterutil"
local Consumable = require "defs.consumable"

local DebugLister = require "debug.inspectors.debug_lister"

local MaterialLister = Class(DebugLister, function(self)
	DebugLister._ctor(self, "Material Lister")

	local locations = {}
	for _, location_group in ipairs( biomes.location_unlock_order ) do
		for _, location in ipairs(location_group) do 
			table.insert(locations, location)
		end
	end

	self:SetColumns({
		{ key = "source", name = "Source" },
		{ key = "name", name = "Name" },
		{ key = "rarity", name = "Rarity" },
		{ key = "location", name = "Location", 
			fn = function(item)
				for _, location in pairs(locations) do
					local full_item_list = monsterutil.GetItemsInLocation(location)
					for _, location_item in ipairs(full_item_list) do
						if location_item.name == item.name then
							return location.id
						end
					end
				end			

				return ""	
			end
		},
	})	

	self:Refresh()
	self:SetSource(Consumable)
end)

function MaterialLister:Refresh()	
	self:ResetValues()

	local materials = Consumable.Items.MATERIALS
	for key, item in pairs(materials) do

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

MaterialLister.PANEL_WIDTH = 800
MaterialLister.PANEL_HEIGHT = 1000

DebugNodes.MaterialLister = MaterialLister

return MaterialLister
