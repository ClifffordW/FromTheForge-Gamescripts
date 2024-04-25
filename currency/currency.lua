local Currency = Class(function(self, use_default_deposit_rates)
	self.use_default_deposit_rates = use_default_deposit_rates
end)

local function DeclarePureVirtual(method)
	dbassert(false, "Currency:"..method.."() is pure virtual. Sub-classes must provide this method.")
end

function Currency:GetType()
	DeclarePureVirtual("GetType")
end

function Currency:GetIcon()
	DeclarePureVirtual("GetIcon")
end

function Currency:GetName()
	DeclarePureVirtual("GetName")
end

function Currency:GetRarity()
	DeclarePureVirtual("GetRarity")
end

function Currency:GetPriceFormat()
	return "{icon} {balance}"
end

function Currency:GetInsufficientFundsFormat()
	return STRINGS.UI.VENDING_MACHINE.INSUFFICIENT_FUNDS.DEFAULT
end

function Currency:GetAvailableFunds(player)
	DeclarePureVirtual("GetAvailableFunds")
end

function Currency:ReduceFunds(player, deposit)
	DeclarePureVirtual("ReduceFunds")
end

function Currency:IncreaseFunds(player, amount)
	DeclarePureVirtual("IncreaseFunds")
end

function Currency:NetSerialize(ser)
	ser:SerializeBoolean(self.use_default_deposit_rates)
end

function Currency:NetDeserialize(de)
	self.use_default_deposit_rates = de:DeserializeBoolean()
end

function Currency:MakePriceText(price)
	return self:GetPriceFormat():subfmt({
		icon = self:GetIcon(),
		balance = price.balance,
		cost = price.cost,
	})
end

function Currency:MakeInsufficientFundsText()
	return self:GetInsufficientFundsFormat():subfmt({icon = self:GetIcon()})
end

return Currency
