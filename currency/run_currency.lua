local MaterialCurrency = require "currency.material_currency"
local CurrencyType = require "currency.currency_type"
local Consumable = require "defs.consumable"

local RunCurrency = Class(MaterialCurrency, function(self)
	MaterialCurrency._ctor(self, Consumable.Items.MATERIALS.konjur.name, true)
end)

function RunCurrency:GetType()
	return CurrencyType.id.Run
end

return RunCurrency
