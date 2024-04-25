local Power = require("defs.powers.power")
local slotutil = require("defs.slotutil")
local power_icons = require "gen.atlas.ui_ftf_power_icons"

local function GetIcon(name)
	local icon_name = ("icon_equipment_%s"):format(name)

	local atlas = power_icons
	local icon = atlas.tex[icon_name]

	if not icon then
		printf("Failed to find icon: %s", icon_name)
		icon = "images/icons_ftf/item_temp.tex"
	end

	return icon
end

function Power.AddHeartPower(name, data)
	if data.toolips == nil then
		data.tooltips = {}
	end

	data.icon = GetIcon(name)
	data.pretty = slotutil.GetPrettyStrings(Power.Slots.HEART, name)

	data.power_type = Power.Types.HEART
	data.can_drop = false
	data.selectable = false
	data.show_in_ui = false

	data.stackable = true
	if not data.max_stacks then
		data.max_stacks = 4
	end

	name = ("heart_%s"):format(name):lower()
	Power.AddPower(Power.Slots.HEART, name, "heartpowers", data)
end

Power.AddPowerFamily("HEART")

Power.AddHeartPower("megatreemon",
{
	power_category = Power.Categories.SUSTAIN,
	permanent = true,
	max_stacks = 400, -- max 400 extra health

	tuning =
	{
		[Power.Rarity.COMMON] = {
			health = StackingVariable(1):SetFlat(), -- # stacks = # max health increase
		},
	},

	on_add_fn = function(pow, inst)
		if not pow.persistdata.did_init then
			local health_mod = pow.persistdata:GetVar("health")
			inst.components.health:AddHealthAddModifier(pow.def.name, health_mod)
			inst.components.health:DoDelta(health_mod, true)
			pow.persistdata.did_init = true
		end
	end,

	on_stacks_changed_fn = function(pow, inst)
		local health_mod = pow.persistdata:GetVar("health")
		inst.components.health:AddHealthAddModifier(pow.def.name, health_mod)
		inst.components.health:DoDelta(health_mod, true)
	end,

	on_remove_fn = function(pow, inst)
		inst.components.health:RemoveHealthAddModifier(pow.def.name)
		pow.persistdata.did_init = false
	end,
})

Power.AddHeartPower("owlitzer",
{
	power_category = Power.Categories.SUPPORT,

	tags = { POWER_TAGS.PROVIDES_HEALING },

	max_stacks = 40, -- max heal of 20/ room

	tuning = {
		[Power.Rarity.COMMON] = { 
			heal_on_enter = StackingVariable(1):SetFlat() 
		},
	},

	event_triggers =
	{
		["start_gameplay"] = function(pow, inst, data)
			local power_heal = Attack(inst, inst)
			power_heal:SetHeal(pow.persistdata:GetVar("heal_on_enter"))
			power_heal:SetSource(pow.def.name)
			inst.components.combat:ApplyHeal(power_heal)

			inst:PushEvent("used_power", pow.def)
		end,
	}
})

Power.AddHeartPower("bandicoot",
{
	power_category = Power.Categories.SUPPORT,
	permanent = true,
	max_stacks = 40,

	tuning =
	{
		[Power.Rarity.COMMON] = {
			roll_speed_bonus = StackingVariable(1):SetPercentage(),
		},
	},

	on_stacks_changed_fn = function(pow, inst)
		if pow.persistdata.init then
			inst.components.playerroller:RemoveTicksMultModifier(pow.def.name)
		end

		pow.persistdata.init = true
		local percent = pow.persistdata:GetVar("roll_speed_bonus")
		inst.components.playerroller:AddTicksMultModifier(pow.def.name, -percent)
	end,

	on_remove_fn = function(pow, inst)
		if pow.persistdata.init then
			pow.persistdata.init = false
			inst.components.playerroller:RemoveTicksMultModifier(pow.def.name)
		end
	end,
})

local function thatcher_GetBonusIFrames(pow, inst)
	local percent = pow.persistdata:GetVar("percent_extra_iframes")
	local normal_frames = inst.components.playerroller:GetIframes()
	local bonus_frames = math.ceil(normal_frames * percent) -- ceil makes it so that each level gives at least 1f even for Light Dodge

	return bonus_frames
end

Power.AddHeartPower("thatcher",
{
	power_category = Power.Categories.SUPPORT,
	permanent = true,
	max_stacks = 40,

	tuning =
	{
		[Power.Rarity.COMMON] = {
			percent_distance_bonus = StackingVariable(1):SetPercentage(), -- % multiplier of iframes
		},
	},

	on_stacks_changed_fn = function(pow, inst)
		if pow.persistdata.init then
			inst.components.playerroller:RemoveDistanceMultModifier(pow.def.name)
		end

		pow.persistdata.init = true
		local percent = pow.persistdata:GetVar("percent_distance_bonus")
		inst.components.playerroller:AddDistanceMultModifier(pow.def.name, percent)
	end,

	on_remove_fn = function(pow, inst)
		if pow.persistdata.init then
			pow.persistdata.init = false
			inst.components.playerroller:RemoveDistanceMultModifier(pow.def.name)
		end
	end,
})
-- heart features should generally be powers that allow the player to fine-tune how their character controls
-- an armour power 