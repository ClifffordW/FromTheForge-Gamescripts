local quips = {}
local AddQuips = function(tbl)
	table.insert( quips, tbl )
end

--jcheng: these should probably be removed, but adding this here as a fallback so it doesn't crash if we don't have default quips
AddQuips{
	tags = { "chitchat" },
	not_tags = { "role_hunter", "role_scout", "role_travelling_salesman", "role_armorsmith", "role_konjurist", "role_blacksmith", "role_market_merchant" },
	[[
		I shouldn't be saying this, please press F8 to report it!
	]],
}

AddQuips{
	tags = { "nothingtosay" },
	not_tags = { "role_hunter", "role_scout", "role_travelling_salesman", "role_armorsmith", "role_blacksmith", "role_konjurist", "role_market_merchant" },
	[[
		I shouldn't be saying this, please press F8 to report it.
	]],
}

AddQuips{
	tags = { "nothingtosay", "role_hunter" },
	[[
		!neutral
		!cough
		{name.dojo_cough}
	]],
}

AddQuips{
	tags = { "nothingtosay", "role_scout" },
	[[
		!neutral
		!think
		Sorry, can't talk. I'm working out a cartographical problem.
	]],
	[[
		!happy
		!think
		Sorry-- I'm trying to solve an engineering issue on the {name.damselfly} at the moment.
	]],
	[[
		!neutral
		!think
		Sorry, Hunter-- I'm a little busy figuring out my next scouting route.
	]],
	[[
		!neutral
		!think
		Sorry Hunter, I'm working out provisioning logistics for the camp right now.
	]],
	[[
		!happy
		!greet
		Hey, Hunter. Talk later?
	]],
}

-- Nothing to say in town, prioritize talking about using the damselfly
AddQuips{
	tags = { "nothingtosay", "role_scout", "in_town" },
	tag_scores = { in_town = 5 },
	[[
		!happy
		!gesture
		Hop in the <#RED>{name.damselfly}</> when you're ready to Hunt.
	]],
	[[
		!happy
		!gesture
		The <#RED>{name.damselfly}'s</> waiting when you're ready.
	]],
	[[
		!happy
		!gesture
		The <#RED>{name.damselfly}'s</> ready when you are.
	]],
	[[
		!happy
		!gesture
		Just click the <#RED>{name.damselfly}</> when you're ready for another {name.run}.
	]],
}

--comment out for quip-testing purposes - Chloe
AddQuips{
	tags = { "nothingtosay", "role_armorsmith" },
	[[
		!happy
		!closedeyes
		<i><z 0.8>(humming)</></i>
	]],
	[[
		!happy
		!dubious
		Shh! <#BLUE>{name.npc_lunn}'s</> telling me a story!
	]],
}

AddQuips{
	tags = { "nothingtosay", "role_blacksmith" },
	[[
		!neutral
		!gruffnod
		<i><z 0.8>(grunt)</></i>
	]],
	[[
		!neutral
		!gruffnod
		Hmff.
	]],
}

AddQuips{
	tags = { "nothingtosay", "role_travelling_salesman" },
	[[
		!happy
		!laugh
		If ma could sssee me now.
	]],
	[[
		!agree
		Trussst me, I'm a doctor.
	]],
}

AddQuips{
	tags = { "nothingtosay", "role_travelling_salesman", "has_refilled_potion" },
	[[
		!happy
		!gesture
		Thank-you for your patronage.
	]],
	[[
		!point
		You're my favourite cussstomer.
	]],
}

AddQuips{
	tags = { "nothingtosay", "role_travelling_salesman", "cant_craft_potion" },
	[[
		!happy
		!dubious
		Come back later, my friend friend.
	]],
}

AddQuips{
	tags = { "nothingtosay", "role_konjurist" },
	[[
		!neutral
		!dubious
		Hm? Oh, you're still here.
	]],
	[[
		!neutral
		!dubious
		Try not to step on anything on your way out. Thanks.
	]],
	[[
		!neutral
		!thinking
		Doing <#RED>Upgrades</> is a nice break from my research.
	]],
}

AddQuips{
	tags = { "nothingtosay", "role_market_merchant" },
	[[
		!happy
		!wink
		Take a picture, it'll last longer.
	]],
	[[
		!happy
		!dubious
		What're you looking at?
	]],
}

AddQuips{
	tags = { "nothingtosay", "role_magpie" },
	[[
		!happy
		!laugh
		Kwee?
	]],
}

return quips
