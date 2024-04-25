local DebugDraw = require "util.debugdraw"
local DebugNodes = require "dbui.debug_nodes"
local iterator = require "util.iterator"
local lume = require "util.lume"
local csvutil = require "util.csvutil"

local Equipment = require("defs.equipment")
local DebugLister = require "debug.inspectors.debug_lister"

local EquipmentLister = Class(DebugLister, function(self)
	DebugLister._ctor(self, "EquipmentLister")

	self:SetColumns({
		{ key = "name", name = "Name" },
		{ key = "rarity", name = "Rarity" },
		{ key = "weight", name = "Weight" },
		{ key = "slot", name = "Slot" },
		{ key = "armour_type", name = "Armour Type" },
		-- 	fn = function(power) 
		-- 		return tostring(Power.GetBaseRarity(power))
		-- 	end
		-- },
	})

	for _, item_group in pairs(Equipment.Items) do
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

	self:SetSource(Equipment)
end)

DebugNodes.EquipmentLister = EquipmentLister

return EquipmentLister
