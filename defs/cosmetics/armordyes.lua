local Cosmetic = require("defs.cosmetics.cosmetic")
local Equipment = require "defs.equipment"

Cosmetic.DyeSlots = { "HEAD", "BODY", "WAIST" }
Cosmetic.EquipmentDyes = {}


local function AddDyeSlot(slot)
	assert(Cosmetic.EquipmentDyes[slot] == nil)
	Cosmetic.EquipmentDyes[slot] = {}
end

function Cosmetic.AddEquipmentDye(name, data)
	local cosmetic_data = data.cosmetic_data

	local slots = { Equipment.Slots.HEAD, Equipment.Slots.BODY, Equipment.Slots.WAIST }

	for i,slot in ipairs(slots) do
		local full_name = name.."_"..slot
		local def = Cosmetic.AddCosmetic(full_name, data)

		def.short_name = name
		def.armour_set = cosmetic_data.armour_set -- "yammo", "cabbageroll", etc
		def.armour_slot = slot -- HEAD, BODY or WAIST
		def.dye_number = cosmetic_data.dye_number   -- for the slot + armour name combo, which colour is this?
		def.build_override = cosmetic_data.build_override -- when equipped, what build override should we apply for this slot?

		def.uitags = Cosmetic.MakeTagsDict(cosmetic_data.uitags) or {} -- always have ui tags

		if Cosmetic.EquipmentDyes[def.armour_slot][def.armour_set] == nil then
			Cosmetic.EquipmentDyes[def.armour_slot][def.armour_set] = {}
		end
		Cosmetic.EquipmentDyes[def.armour_slot][def.armour_set][name] = def
	end

end

function Cosmetic.CollectEquipmentDyeAssets(asset_pack, included_cosmetics)
	local dupe = {
		prod = {},
		dev = {},
	}
	for slot, armour_set in pairs(Cosmetic.EquipmentDyes) do
		for set_name, set_data in pairs(armour_set) do
			for dye_name,dye_def in pairs(set_data) do
				local build = dye_def.build_override
				local dest = included_cosmetics[dye_name] and "prod" or "dev"
				if build and not dupe[dest][build] then
					dupe[dest][build] = true
					table.insert(asset_pack[dest], Asset("ANIM", "anim/"..build..".zip"))
				end
			end
		end
	end
end

for _, slot in ipairs(Cosmetic.DyeSlots) do
	AddDyeSlot(slot)
end

return Cosmetic
