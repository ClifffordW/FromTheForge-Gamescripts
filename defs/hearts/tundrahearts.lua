local Heart = require("defs.hearts.heart")

function Heart.AddTundraHeart(id, data)
	Heart.AddHeart(Heart.Slots.TUNDRA, id, "tundra_hearts", data)
end

Heart.AddHeartFamily("TUNDRA", nil, 2)

Heart.AddTundraHeart("boss1_todo",
{
	idx = 1,
	tooltips =
	{
	},
	-- power = "???",
})

Heart.AddTundraHeart("boss2_todo",
{
	idx = 2,
	tooltips =
	{
	},

	-- power = "???",
})