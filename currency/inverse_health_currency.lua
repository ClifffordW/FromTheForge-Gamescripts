local Currency = require "currency.currency"
local CurrencyType = require "currency.currency_type"
local KString = require "util.kstring"

local InverseHealthCurrency = Class(Currency, function(self)
	Currency._ctor(self, true)
	self.icon = KString.subfmt("<p img='{icon}' scale={scale}>", {
		icon = "images/ui_ftf_ingame/life_icon_healing.tex",
		scale = 0.7
	})
end)

function InverseHealthCurrency:GetType()
	return CurrencyType.id.Health
end

function InverseHealthCurrency:GetIcon()
	return self.icon
end

function InverseHealthCurrency:GetPriceFormat()
	return "{icon} {balance}/{cost}"
end

function InverseHealthCurrency:GetInsufficientFundsFormat()
	return STRINGS.UI.VENDING_MACHINE.INSUFFICIENT_FUNDS.HEALTH
end

function InverseHealthCurrency:GetAvailableFunds(player)
	return player.components.health:GetMissing()
end

function InverseHealthCurrency:ReduceFunds(player, deposit)
	player.components.health:DoDelta(deposit)
end

function InverseHealthCurrency:IncreaseFunds(player, amount)
	player.components.health:DoDelta(-amount)
end

return InverseHealthCurrency
