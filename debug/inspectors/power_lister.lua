local DebugDraw = require "util.debugdraw"
local DebugNodes = require "dbui.debug_nodes"
local iterator = require "util.iterator"
local lume = require "util.lume"
local csvutil = require "util.csvutil"

local Power = require("defs.powers")
local DebugLister = require "debug.inspectors.debug_lister"

local PowerLister = Class(DebugLister, function(self)
	DebugLister._ctor(self, "PowerLister")

	self:SetColumns({
		{ key = "power_category", name = "Category" },
		{ key = "power_type", name = "Power Type" },
		{ key = "name", name = "Name" },
		{ key = "can_drop", name = "Can Drop" },
		{ key = "slot", name = "Slot" },
		{ key = "tuning", name = "Rarity", 
			fn = function(power) 
				return tostring(Power.GetBaseRarity(power))
			end
		},
		{ key = "pretty", name = "Pretty Name",
			fn = function(power)
				local slot = power.slot
				local name = power.name

				if STRINGS.ITEMS[slot] ~= nil and STRINGS.ITEMS[slot][name] ~= nil then
					return tostring(STRINGS.ITEMS[slot][name].name)
				else
					return tostring("N/A")
				end
			end
		},
		{ key = "desc", name = "Description",
			fn = function(power)
				local slot = power.slot
				local name = power.name

				if STRINGS.ITEMS[slot] ~= nil and STRINGS.ITEMS[slot][name] ~= nil then
					return tostring(STRINGS.ITEMS[slot][name].desc)
				else
					return tostring("N/A")
				end
			end
		},
	})

	local items = Power.Items
	for power_group, powers in pairs(Power.Items) do

		for power_name, power in pairs(powers) do
			local item_v = {}
			for _, v in ipairs(self:GetColumns()) do
				if v.fn then
					item_v[v.key] = v.fn(power)
				else
					item_v[v.key] = tostring(power[v.key])
				end
			end

			item_v["data"] = power
			
			self:AddValue(item_v)
		end
	end

	self:SetSource(Power)
end)

DebugNodes.PowerLister = PowerLister

return PowerLister
