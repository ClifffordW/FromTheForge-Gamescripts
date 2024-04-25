local MaterialCurrency = require "currency.material_currency"
local CurrencyType = require "currency.currency_type"

local LootCurrency = Class(MaterialCurrency, function(self, currency)
	MaterialCurrency._ctor(self, currency and currency.material, true)
end)

function LootCurrency:GetType()
	return CurrencyType.id.Loot
end

function LootCurrency:GetPriceFormat()
	return "{icon} {cost}\n<#{rarity}>{name}</>"
end

function LootCurrency:MakePriceText(price)
	return self:GetPriceFormat():subfmt({
		icon = self:GetIcon(),
		name = self:GetName(),
		balance = price.balance,
		cost = price.cost,
		rarity = self:GetRarity(),
	})
end

return LootCurrency
