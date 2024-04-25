local MetaCurrency = require "currency.meta_currency"
local RunCurrency = require "currency.run_currency"
local InverseHealthCurrency = require "currency.inverse_health_currency"
local LootCurrency = require "currency.loot_currency"
local CurrencyType = require "currency.currency_type"

local CurrencyFactory = {}

-- Construct a Currency sub-class from the 'currency' table.
function CurrencyFactory.Build(currency)
	if currency.currency_type == CurrencyType.id.Meta then
		return MetaCurrency(currency)
	elseif currency.currency_type == CurrencyType.id.Run then
		return RunCurrency(currency)
	elseif currency.currency_type == CurrencyType.id.Health then
		return InverseHealthCurrency(currency)
	elseif currency.currency_type == CurrencyType.id.Loot then
		return LootCurrency(currency)
	end
end

function CurrencyFactory.NetSerializeCurrency(ser, currency)
	local currency_type = currency and currency:GetType() or 0
	ser:SerializeUInt(currency_type, CurrencyType.BIT_COUNT)
	if currency_type ~= 0 then
		currency:NetSerialize(ser)
	end
end

function CurrencyFactory.NetDeserializeCurrency(de)
	local currency_type = de:DeserializeUInt(CurrencyType.BIT_COUNT)
	if currency_type == 0 then
		return nil
	end
	local currency = CurrencyFactory.Build({
		currency_type = currency_type
	})
	currency:NetDeserialize(de)
	return currency
end

return CurrencyFactory
 