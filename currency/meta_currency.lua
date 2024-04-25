local MaterialCurrency = require "currency.material_currency"
local CurrencyType = require "currency.currency_type"
local Consumable = require "defs.consumable"

local MetaCurrency = Class(MaterialCurrency, function(self)
	MaterialCurrency._ctor(self, Consumable.Items.MATERIALS.konjur_soul_lesser.name, false)
end)

function MetaCurrency:GetType()
	return CurrencyType.id.Meta
end

return MetaCurrency
