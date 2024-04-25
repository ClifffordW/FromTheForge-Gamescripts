local quips = {}
local AddQuips = function(tbl)
	table.insert( quips, tbl )
end

AddQuips{
	tags = { "chitchat", "role_market_merchant" },
	[[
		!happy
		!bliss
		What a privilege for you, browsing my wares.
		!wink
		You're welcome.
	]],
	[[
		!happy
		!wink
		Peruse at your leisure, culver.
		!gesture
		I'm not going anywhere.
	]],
	[[
		!neutral
		!agree
		Handcrafted, artisanal pieces at reasonable prices.
		!happy
		!gesture
		Made from local materials.
	]],
	[[
		!neutral
		!point
		All pieces are guaranteed to be one-size-fits-all.
		!gesture
		The material is <i>deceptively</i> elastic.
	]],
	[[
		!happy
		!smirk
		Hand-hammered, hand-forged.
		!gesture
		And, if you desire, hand-delivered.
	]],
	[[
		!happy
		!agree
		Oh yeah. I hath what the Hunters crave.
		!wink
		Enjoy.
	]],
}

return quips
