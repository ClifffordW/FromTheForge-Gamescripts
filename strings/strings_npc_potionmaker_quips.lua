local quips = {}
local AddQuips = function(tbl)
	table.insert( quips, tbl )
end

AddQuips{
	tags = { "chitchat", "role_travelling_salesman"},
	[[
		!neutral
		!dubious
		It'sss not easy to brew this stuff up, you know.
		!shrug
		I've only got so much oil.
	]],
	[[
		!happy
		!gesture
		Thanks for stopping by the finest little caravan this ssside of the volcano!
		!point
		Be sure to tell your friendsss... <z 0.7>(with money.)</z>
	]],
	[[
		!happy
		!greet
		{name.npc_doc_lastname}-brand <#RED>Health {name.potion}s</>!
		!shocked
		Restore your mojo on the go-go!
	]],
}

AddQuips{
	tags = { "chitchat", "role_travelling_salesman", "location_treemon_forest" },
	[[	
		!happy
		!gesture
		This here tonic is made from the finest, freshest ingredientsss east of the <#RED>{name.treemon}</>.
		!shocked
		Don't misss out!
	]],
}

AddQuips{
	tags = { "chitchat", "role_travelling_salesman", "location_bandi_swamp" },
	[[
		!happy
		!gesture
		Don't <i>muck</i> about with inferior products, my friend.
		!point
		For the discerning ssshopper, it's {name.npc_doc_lastname}-brand or bust!
	]],
	[[
		!happy
		!gesture
		Don't get <i>bogged down</i> with inferior products!
		!point
		Buy {name.npc_doc_lastname}-brand <#RED>Health {name.potion}s</>, for all your recovery needs!
	]],
}

--Stealing five finger brew
AddQuips{
	tags = { "chitchat", "role_travelling_salesman", "steal_five_finger_brew" },
	[[
		!neutral
		!angry
		Does that look like a trough??
	]],
	[[
		!neutral
		!shocked
		Hey!
	]],
	[[
		!neutral
		!dubious
		What are you doing over there, my fine friend?
	]],
	[[
		!neutral
		!angry
		Keep your paws out of that!
	]],
	[[
		!neutral
		!think
		Did I hear something?
	]],
	[[
		!neutral
		!think
		What was that?
	]],
	[[
		!neutral
		!dubious
		Hm?
	]],
	[[
		!neutral
		!eyeroll
		Like I need another health code violation.
	]],
	[[
		!dubious
		What's going on over there?
	]],
	[[
		!neutral
		!think
		My lost profit sense is tingling.
	]],
	[[
		!neutral
		!gesture
		Ahem.
	]],
	[[
		!neutral
		!dubious
		What's happening over there?
	]],
	[[
		!neutral
		!angry
		At least wear a hairnet!
	]],
	[[
		!neutral
		!think
		What's that?
	]],
	[[
		!neutral
		!dubious
		Must've been the wind.
	]],
	[[
		!neutral
		!shocked
		I say!
	]],
	[[
		!neutral
		!angry
		No free samples!
	]],
}

AddQuips{
	tags = { "chitchat", "role_travelling_salesman", "needs_potion" },
	not_tags = { "can_craft_potion" },
	[[
		agent:
			!happy
			!shocked
			Oh my, your pocketsss seem lighter than usual today.
			!neutral
			!dejected
			As the single father of four plucky eruption orphansss, I'm afraid I simply can't give my <#RED>Potions</> away for free.
			!scared
			A little <#KONJUR>{name.i_konjur}</> is all I ask. It's for their college fundsss.
			!happy
			!gesture
			I'm sure you understand.
	]],
		-- player:
		-- 	My apologies! Say hi to the kids!\n<i><#RED><z 0.7>(Need more {name.konjur})</></i></z>
	[[
		!neutral
		!dejected
		Good gravy, maybe Ma wasss right about this venture.
		!happy
		!dubious
		Hm? Oh my friend, I didn't realize you were lissstening!
	]],
}

AddQuips{
	tags = { "chitchat", "role_travelling_salesman", "can_craft_potion" },
	not_tags = { "needs_potion" },
	tag_scores = { can_craft_potion = 100 },
	[[
		agent:
			!shocked
			Why, my friend! Are you aware your flask is full of <i>inferior product</i>?!
			!think
			Golly, I just hate to see a salt of the earth <#BLUE>{player.species}</> like yourself get ssswindled.
			!dubious
			Tell you what, why don't you empty that swill out with <p bind='Controls.Digital.USE_POTION' color=BTNICON_DARK> and I'll top you up with some bonafide {name.npc_doc_lastname}-brand <#RED>Potion</> instead?
		player:
			Wow! You'd do that for me?
		agent:
			Undoubtedly!
	]],
}

return quips
