local MetaProgress = require "defs.metaprogression.metaprogress"

local Consumable = require"defs.consumable"

-- This Progress is for converting Konjur directly into Corestones.
-- A vendingmachine in the hyperoom will access this progression and give 1xp per teffra, and give a corestone in exchange.
function MetaProgress.AddKonjurConversion(id, data)
	data.base_exp = {
		200,
	}
	data.exp_growth = 0.0

	MetaProgress.AddProgression(MetaProgress.Slots.KONJUR_CONVERSION, id, data)
end

MetaProgress.AddProgressionType("KONJUR_CONVERSION")

MetaProgress.AddKonjurConversion("basic",
{
	-- NOTE: Players will be unlocking these through either Dungeon 1 or Dungeon 2
	endless_reward = MetaProgress.Reward(Consumable, Consumable.Slots.MATERIALS, "konjur_soul_lesser", 1),
	rewards =
	{
	},
})