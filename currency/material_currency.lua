local Currency = require "currency.currency"
local Consumable = require "defs.consumable"
local KString = require "util.kstring"

local MaterialCurrency = Class(Currency, function(self, material, use_default_deposit_rates)
	Currency._ctor(self, use_default_deposit_rates)
	self.material = material
end)

function MaterialCurrency:_ManifestDef()
	if not self.def then
		self.def = Consumable.FindItem(self.material)
	end
	return self.def
end

function MaterialCurrency:_ManifestIcon()
	if not self.icon then
		self.icon = KString.subfmt("<p img='{icon}'>", {icon = self:_ManifestDef().icon})
	end
	return self.icon
end

function MaterialCurrency:_ClearCache()
	self.def = nil
	self.icon = nil
end

function Currency:GetName()
	return self:_ManifestDef().pretty.name
end

function MaterialCurrency:GetIcon()
	return self:_ManifestIcon()
end

function MaterialCurrency:GetRarity()
	return self:_ManifestDef().rarity
end

function MaterialCurrency:GetAvailableFunds(player)
	return player.components.inventoryhoard:GetStackableCount(self:_ManifestDef())
end

function MaterialCurrency:ReduceFunds(player, deposit)
	player.components.inventoryhoard:RemoveStackable(self:_ManifestDef(), deposit)
end

function MaterialCurrency:IncreaseFunds(player, amount)
	player.components.inventoryhoard:AddStackable(self:_ManifestDef(), amount, true)
end

function MaterialCurrency:NetSerialize(ser)
	Currency.NetSerialize(self, ser)
	ser:SerializeString(self.material)
end

function MaterialCurrency:NetDeserialize(de)
	Currency.NetDeserialize(self, de)
	local material = de:DeserializeString()
	if material ~= self.material then
		self:_ClearCache()
		self.material = material
	end
end

return MaterialCurrency
