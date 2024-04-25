local Equipment = require("defs.equipment")
local Power = require "defs.powers"
local lume = require"util.lume"
local krandom = require"util.krandom"

--component for UI to see if you've seen an item before, and mark it as new
local GrabBag = Class(function(self, inst)
	self.inst = inst
	self.bags = {}
	self.init_values = {}
end)

function GrabBag:OnSave()
	--jcheng: NOTE: do NOT save init values here. You should always add it at runtime, so we can change init values dynamically
	return self.bags
end

function GrabBag:OnLoad(data)
	self.bags = deepcopy(data) or {}
end

function GrabBag:VerifyBag(name)
	dbassert(self.init_values[name] ~= nil, "Trying to verify a bag that doesn't exist")
	if self.bags[name] == nil then
		self.bags[name] = {}
		return
	end

	--verify that the values in the bags are valid, and remove any that are not
	self.bags[name] = lume.reject(self.bags[name], function(value) return table.find(self.init_values[name], value) == nil end)
end

function GrabBag:_SetBag( name, values )
	self.init_values[name] = deepcopy(values)
	self:VerifyBag(name)
end

function GrabBag:PickFromBag( name, possible_values, rng )
	self:_SetBag(name, possible_values)

	if self.bags[name] == nil or #self.bags[name] == 0 then
		--nothing in the bag, reset it
		self.bags[name] = deepcopy(self.init_values[name])
	end

	--pick a value, remove the value
	local choice = rng:Integer(#self.bags[name])
	local val = self.bags[name][choice]

	table.remove(self.bags[name], choice)

	return val
end

return GrabBag
