local quips = {}
local AddQuips = function(tbl)
	table.insert( quips, tbl )
end

------------------------------------------------------------------------------------
--EARLY ACCESS ONLY QUIPS--
------------------------------------------------------------------------------------
AddQuips{
	tags = { "chitchat", "role_scout" },
	[[
		!happy
		!clap
		Remember to press F8 to give feedback!
		!gesture
		I really appreciate it.
	]],
	[[
		!happy
		!shocked
		Oh! Don't forget you can press F8 to give <#RED>Early Access</> feedback!
		!bliss
		It's really a big help.
	]],
}

------------------------------------------------------------------------------------
--GENERAL TOWN QUIPS (UNIQUE)--
------------------------------------------------------------------------------------
AddQuips{
	tags = { "chitchat", "in_town", "role_scout" }, 
	unique = "smushed_rations",
	[[
		!neutral
		!think
		Hm... our food got pretty smushed in the {name.damselfly} crash.
		!happy
		!shrug
		I hope no one's picky.
	]],
}

AddQuips{
	tags = { "chitchat", "in_town", "role_scout" },
	unique = "playing_cards",
	[[
		!happy
		!bliss
		Oh hey! My pack of playing cards survived the crash!
		!gesture
		Well at least we have the essentials! Haha.
	]],
}

AddQuips{
	tags = { "chitchat", "in_town", "role_scout" },
	unique = "bonion_cry",
	[[
		!neutral
		!dejected
		Every time I see a <#RED>{name.cabbageroll}</> die I end up crying a little bit.
		!think
		But I'm not sure if that's because I feel bad for it, or because of the <#RED>{name.cabbageroll}</> stink.
	]],
}

AddQuips{
	tags = { "chitchat", "in_town", "role_scout" },
	unique = "gathering_data",
	[[
		!happy
		!gesture
		It's a lot easier to scout when you've got a fighter on the ground!
		!bliss
		I'm gathering so much info from your {name_multiple.run}!
	]],
}
------------------------------------------------------------------------------------
--GENERAL TOWN QUIPS (REPLAYABLE)--
------------------------------------------------------------------------------------

AddQuips{
	tags = { "chitchat", "in_town", "role_scout" },
	[[
		!neutral
		!point
		Remember to prioritize <#RED>Dodging</> over <#RED>{name.concept_damage}</> out there.
		!happy
		!nervous
		Sorry if I'm nagging... I just don't want anyone getting hurt.
	]],
	[[
		!happy
		!gesture
		Rest here as long as you need, Hunter.
		!shrug
		It's not like the <#RED>{name_multiple.rot}</> are going anywhere.
	]],
	[[
		!neutral
		!gesture
		Make sure to double check your gear before we head out.
		!happy
		!dubious
		I wouldn't want to have to fly back, y'know?
	]],
	[[
		!happy
		!gesture
		Don't forget, you can't change your <#RED>Armour</> once we leave!
		!neutral
		!shrug
		It'd be unwieldy to pack <i>all</i> the <#RED>Armour</> you own for every flight, y'know?
		!happy
	]],
	[[
		!happy
		!greet
		We can head out whenever you're ready.
		!gesture
		No rush.
	]],
	[[
		!happy
		!gesture
		Nice day, isn't it?
		!bliss
		My allergies are only moderately debilitating today!
	]],
	[[
		!happy
		!gesture
		Take a load off, Hunter, we're safe here in camp.
		!neutral
		!shrug
		At least I think we're safe.
		!happy
	]],
	[[
		!happy
		!gesture
		Make yourself at home.
		!neutral
		!shrug
		This <i>is</i> your home for the foreseeable future, after all.
		!happy
	]],
	[[
		!happy
		!gesture
		Ready to head out?
		!neutral
		!thinking
		I think I'm ready. Wait, did I pack my--
	]],
	[[
		!happy
		!gesture
		No pressure, but lemme know when you're ready.
		!agree
		I'm itching to get back in the air!
	]],
	[[
		!happy
		!gesture
		Ready for another {name.run}?
		!point
		Just hop in the ol'<#RED>{name.damselfly}</>.
	]],
	[[
		!happy
		!gesture
		Always glad to see you in one piece, Hunter.
		!point
		Stay that way, okay?
	]],
	[[
		!happy
		!gesture
		There's training dummies here in town if you'd like a chance to practice.
		!neutral
		!shrug
		If you can bring yourself to hit them, anyway. They're kinda cute.
		!happy
	]],
	[[
		!happy
		!gesture
		Don't forget, you can practice your moves on the training dummies around town.
		!shrug
		It's a good way to get the hang of a new weapon.
	]],
	[[
		!happy
		!gesture
		Ready to {name.run}?
		!point
		The <#RED>{name_multiple.rot}</> aren't ready for you, I'll tell you that for free.
	]],
}

------------------------------------------------------------------------------------
--GENERAL DUNGEON QUIPS--
------------------------------------------------------------------------------------
AddQuips{
	tags = { "chitchat", "role_scout" },
	not_tags = { "in_town" },
	[[
		agent:
			!greet
			Don't forget to keep <#BLUE>{name_multiple.concept_focus_hit}</> in mind out there!
			!gesture
			They do an increased amount of <#RED>Damage</>, which'll appear in <#BLUE>Blue</>!
	]],
	[[
		!happy
		!gesture
		Hey, Hunter... I just wanted to say I appreciate all the work you do for the {name_multiple.foxtails}' expedition.
		!nervous
		That's... that's all. Sorry if I embarrassed you.
	]],
}

--have hammer equipped in the dungeon
AddQuips{
	tags = { "chitchat", "weapon_type_hammer", "role_scout" },
	not_tags = { "in_town" },
	[[
		agent:
			!neutral
			!think
			Hey, do you know about <#BLUE>{name_multiple.concept_focus_hit}</>?
			!point
			For a <#RED>{name.weapon_hammer}</> like yours, one way to <#BLUE>{name.concept_focus_hit}</> is to hit <#RED>2+ Targets</> at once.
	]],
	[[
		agent:
			!neutral
			!think
			Hey Hunter, do you know how to do your <#BLUE>{name_multiple.concept_focus_hit}</>?
			!point
			For a <#RED>{name.weapon_hammer}</> like yours, one way to <#BLUE>{name.concept_focus_hit}</> is to fully charge your <#RED>Skill</> (<p bind='Controls.Digital.SKILL' color=BTNICON_DARK>).
	]],
	[[
		agent:
			!neutral
			!think
			Oh, Hunter, do you know your <#BLUE>{name.concept_focus_hit}</> conditions?
			!point
			For a <#RED>{name.weapon_hammer}</> like that, one way to <#BLUE>{name.concept_focus_hit}</> is to fully charge your <#RED>Heavy Attack</> (<p bind='Controls.Digital.ATTACK_HEAVY' color=BTNICON_DARK>).
	]],
}
--have polearm equipped in the dungeon
AddQuips{
	tags = { "chitchat", "weapon_type_polearm", "role_scout" },
	not_tags = { "in_town" },
	[[
		agent:
			!neutral
			!thinking
			<#RED>{name.weapon_polearm}</> today, huh?
			!point
			Don't forget to hit with the tip to do a <#BLUE>{name.concept_focus_hit}</>.
	]],
}
--dodge tips if you don't have a cannon equipped
AddQuips{
	tags = { "chitchat", "role_scout" },
	not_tags = {"weapon_type_cannon", "in_town" },
	[[
		!neutral
		!greet
		Be cautious against the <#RED>{name_multiple.rot}</> in there.
		!scared
		If one looks like it's about to <#RED>Attack</>, press <p bind='Controls.Digital.DODGE' color=BTNICON_DARK> to <#RED>Dodge</> out of the way.
	]],
	[[
		!neutral
		!gesture
		Don't forget, a <#RED>Dodge</> will always get you out of harm's way quicker than running.
		!point
		You can <#RED>Dodge</> with <p bind='Controls.Digital.DODGE' color=BTNICON_DARK>.
	]],
	[[
		!neutral
		!agree
		Do a well-timed <#RED>Dodge</> after starting an <#RED>Attack</> and you'll perform a <#RED>{name.concept_dodge} Cancel</>.
		!dubious
		Longer or heavier <#RED>Attacks</> usually have smaller <#RED>Cancel Windows</>, though.
	]],
	[[
		!neutral
		!gesture
		When you <#RED>{name.concept_dodge}</>, you'll roll a short distance and even be <#RED>Invincible</> for a little bit.
		!agree
		Heck, if you're stylish, you can even do a <#RED>Perfect Dodge</> by waiting until the last moment to roll away.
	]],
}
------------------------------------------------------------------------------------
--TREEMON FOREST DUNGEON QUIPS--
------------------------------------------------------------------------------------
AddQuips{
	tags = { "chitchat", "role_scout", "location_treemon_forest" },
	not_tags = { "in_town" },
	[[
		!happy
		!agree
		I'm glad we're doing another Hunt here.
		!closedeyes
		I love flying over the treetops.
	]],
	[[
		!happy
		!think
		Y'think there are any squirrels left in this forest?
		!point
		Squirrels are neat.
	]],
	[[
		!happy
		!closedeyes
		When I was a kid my granddad and I used to pick berries around here.
		!gesture
		Anyway. Be safe on your Hunt.
	]],
}

------------------------------------------------------------------------------------
--OWLITZER FOREST DUNGEON QUIPS--
------------------------------------------------------------------------------------
AddQuips{
	tags = { "chitchat", "role_scout", "location_owlitzer_forest" },
	not_tags = { "in_town" },
	[[
		!happy
		!closedeyes
		It's so peaceful here.
		!gesture
		Almost makes you forget how crazy the rest of the world is.
		!closedeyes
		Almost...
		!neutral
	]],
	[[
		!happy
		!bliss
		I love when we Hunt here.
		!point
		The <#RED>Wind</> gives me a proper flying challenge!
	]],
	[[
		!neutral
		!think
		I wonder if the old fishing hole here still exists.
		!disgaree
		I always meant to go more, but something more important always came up.
		!shrug
		'Just thought it'd always be there, I guess.
	]],
}

------------------------------------------------------------------------------------
--BANDICOOT SWAMP DUNGEON QUIPS--
------------------------------------------------------------------------------------
AddQuips{
	tags = { "chitchat", "role_scout", "location_bandi_swamp" },
	not_tags = { "in_town" },
	[[
		!neutral
		!nervous
		Oooh. I stepped in something goopy.
		!dubious
		Gross.
	]],
	[[
		!neutral
		!think
		Hmmmm..... Yeah.
		!dejected
		I'll <i>definitely</i> need to hose down the {name.damselfly}'s floor mats when we get home.
	]],
	[[
		!neutral
		!think
		How d'you think the <#RED>{name.bandicoot}</> gets her fur so silky?
		!shocked
		I-I'm not jealous!
	]],
}
AddQuips{
	tags = { "chitchat", "role_scout", "location_bandi_swamp", "wf_town_has_armorsmith" },
	not_tags = { "in_town" },
	[[
		!happy
		!point
		<#BLUE>{name.npc_armorsmith}'s</> been teaching me all about skincare lately.
		!think
		I wonder if the goop here would make a good mask.
	]],
	[[
		!neutral
		!nervous
		Ah geez, I hope I don't get any <#RED>Poison</> on my watch.
		!dejected
		Why didn't I leave it at home?
	]],
}

------------------------------------------------------------------------------------
--THATCHER SWAMP DUNGEON QUIPS--
------------------------------------------------------------------------------------
AddQuips{
	tags = { "chitchat", "role_scout", "location_thatcher_swamp" },
	not_tags = { "in_town" },
	[[
		!neutral
		!think
		I didn't think to pack bug spray for this Hunt.
		!happy
		!dubious
		I regret that.
	]],
	[[
		!happy
		!think
		Y'know, I think <#BLUE>{name.npc_dojo_master}</> grew up around here actually.
		!shrug
		Maybe I'll find him a neat rock to bring back as a souvenir.
	]],
	[[
		!happy
		!point
		Oh hey, remember not to stand in the <#RED>Poison</>.
		!shrug
		You'd be surprised how many Hunters forget.
	]],
}

------------------------------------------------------------------------------------
--WON LAST RUN--
------------------------------------------------------------------------------------
AddQuips{
	tags = { "chitchat", "role_scout", "in_town", "won_last_run" },
	[[
		!closedeyes
		Ahh. I love a victory flight home, don't you?
		!agree
		The air just <i>feels</i> headier. 
	]],
	[[
		!clap
		Another hunt well done, Hunter.
		!gesture
		Not that I had any doubts.
	]],
	[[
		!gesture
		There are few things more refreshing than the wind rushing through my fur.
		!think
		I have to brush it kinda thoroughly afterwards to prevent matting, though.
	]],
	[[
		!laugh
		I bet you enjoy the flight home more when you're conscious, huh?
		!shrug
		Or, remember more of the scenery at least.
	]],
}

------------------------------------------------------------------------------------
--LOST LAST RUN--
------------------------------------------------------------------------------------
AddQuips{
	tags = { "chitchat", "role_scout", "in_town", "lost_last_run" },
	[[
		!shrug
		You win some, you lose some, right Hunter?
		!gesture
		No one said it'd be easy.
	]],
	[[
		!gesture
		Glad to see you up.
		!point
		Ready to get back to it?
	]],
	[[
		!greet
		Hey, Hunter.
		!agree
		No lasting damage from that last Hunt, I hope.
	]],
}

------------------------------------------------------------------------------------
--ABANDONED LAST RUN--
------------------------------------------------------------------------------------
AddQuips{
	tags = { "chitchat", "role_scout", "in_town", "abandoned_last_run" },
	[[
		!gesture
		Better to tuck tail on a bad Hunt than get chomped.
		!agree
		The important thing is we made it back.
	]],
	[[
		!gesture
		I respect your tactical decision to retreat.
		!agree
		Very smart.
	]],
}

------------------------------------------------------------------------------------
--ARMOURSMITH QUIPS (BERNA)--
------------------------------------------------------------------------------------
--town has berna
AddQuips{
	tags = { "chitchat", "role_scout", "in_town", "wf_town_has_armorsmith" },
	[[
		!happy
		!gesture
		It's nice to have <#BLUE>{name.npc_armorsmith}</> around.
		!closedeyes
		I think she brightens up the camp.
	]],
	[[
		!happy
		!gesture
		Feel free to chat with folks around town.
		!agree
		It's good for morale.
	]],
	[[
		!happy
		!gesture
		Take some time to socialize with the other {name_multiple.foxtails}.
		!neutral
		!point
		It's good for team cohesion.
	]],
}
--berna hasn't been rescued yet
AddQuips{
	tags = { "chitchat", "role_scout", "location_treemon_forest" },
	tag_scores = { chitchat = 5  },
	not_tags = { "wf_town_has_armorsmith", "in_town" },
	[[
		!neutral
		!dejected
		I hope <#BLUE>{name.npc_armorsmith}'s</> alright.
		!scared
		She could be halfway through a <#RED>{name.yammo}'s</> digestive tract by now!
	]],
	[[
		!neutral
		!nervous
		I keep flying over the woods but I haven't seen <#BLUE>{name.npc_armorsmith}</> anywhere.
		!shocked
		There's no way she got <i>that</i> far!
	]],
	[[
		!neutral
		!nervous
		Let's get back out there and search for <#BLUE>{name.npc_armorsmith}</>.
		!gesture
		The sooner we find her, the sooner I can sleep again.
	]],
	[[
		!neutral
		!sigh
		Things to do, people to save.
		!gesture
		We should get back to the search.
	]],
	[[
		!neutral
		!nervous
		I hired <#BLUE>{name.npc_armorsmith}</> to do upkeep and modifications for the whole camp.
		!dejected
		Our Hunters won't stand a chance against some of the stuff out there without her.
	]],
	[[
		!neutral
		!scared
		I hope <#BLUE>{name.npc_armorsmith}'s</> confidence doesn't get her into any trouble out there.
		!gesture
		She's, uh, not the best at risk assessment.
	]],
}

AddQuips{
	tags = { "chitchat", "in_town", "role_scout"},
	not_tags = { "wf_town_has_armorsmith" },
	unique = "armoursmith_itch_cream",
	[[
		!neutral
		!dubious
		I found <#BLUE>{name.npc_armorsmith}'s</> anti-itch cream in some debris.
		!scared
		She's probably missing that by now.
	]],
}

------------------------------------------------------------------------------------
--BLACKSMITH QUIPS (HAMISH)--
------------------------------------------------------------------------------------
--town has hamish
AddQuips{
	tags = { "chitchat", "role_scout", "in_town", "wf_town_has_blacksmith" },
	[[
		!happy
		!gesture
		I'm glad I hired <#BLUE>{name.npc_blacksmith}</>.
		!agree
		I can trust him to be honest with me.
	]],
}
--hamish hasnt been rescued yet
AddQuips{
	tags = { "chitchat", "role_scout", "location_owlitzer_forest" },
	tag_scores = { chitchat = 5 },
	not_tags = { "wf_town_has_blacksmith", "in_town" },
	[[
		!dejected
		I hope <#BLUE>{name.npc_blacksmith}'s</> alright.
		!nervous
		He's not a fighter, y'know.
	]],
	[[
		!nervous
		I keep flying over the woods but I haven't seen <#BLUE>{name.npc_blacksmith}</> anywhere.
		!dejected
		Where on earth could he be?
	]],
	[[
		!nervous
		I think I spotted some of <#BLUE>{name.npc_blacksmith}'s</> tools from up in the {name.damselfly}...
		!dejected
		But... no <#BLUE>{name.npc_blacksmith}</>.
	]],
	[[
		!nervous
		Let's get back out there and look for <#BLUE>{name.npc_blacksmith}</>.
		!dejected
		Next time I lead an expedition, I'm giving everyone flare guns.
	]],
	[[
		!gesture
		Don't forget, we've got people to go rescue.
		!nervous
		We should get back to it.
	]],
}

-- Players have not killed the boss rot in each dungeon
AddQuips{ -- Megatreemon
	tags = { "chitchat", "role_scout", "location_treemon_forest" },
	tag_scores = { chitchat = 3  },
	not_tags = { "has_killed_megatreemon", "in_town" },
	[[
		!neutral
		!dejected
		If you see <#RED>{name.megatreemon}</>, keep an eye out for her roots.
		!scared
		Who knew trees could be so mean?
	]],
	[[
		!happy
		!nervous
		I'm trusting you to avenge my {name.damselfly}, Hunter.
		!neutral
		!angry
		<#RED>{name.megatreemon}</> can't get away with this.
	]],
}
AddQuips{ -- Owlitzer
	tags = { "chitchat", "role_scout", "location_owlitzer_forest" },
	tag_scores = { chitchat = 3  },
	not_tags = { "has_killed_owlitzer", "in_town" },
	[[
		!neutral
		!nervous
		You promise to take down that <#RED>{name.owlitzer}</>, Hunter?
		!scared
		I hate birds...
	]],
	[[
		!neutral
		!greet
		Good luck out there, Hunter.
		!point
		Don't let the <#RED>Wind</> push you around.
	]],
}
AddQuips{ -- Bandicoot
	tags = { "chitchat", "role_scout", "location_bandi_swamp" },
	tag_scores = { chitchat = 3  },
	not_tags = { "has_killed_bandicoot", "in_town" },

	[[
		!neutral
		!dejected
		Just wait 'til that <#RED>{name.bandicoot}</> takes you on head-to-head!
		!laugh
		We'll see who gets the last laugh.
	]],
	[[
		!happy
		!bliss
		<z 0.7>(sniff sniff)</z> Don't you just love the smell of <#KONJUR>{name_multiple.i_konjur_heart}</> in the morning?
		!scared
		<i>ha</i>-CHOO.
	]],
	[[
		!happy
		!dubious
		Ready, Hunter?
		!neutral
		!point
		I think that <#RED>{name.bandicoot}</> has something that belongs to you. Haha.
	]],
}
AddQuips{ -- Thatcher
	tags = { "chitchat", "role_scout", "location_thatcher_swamp" },
	tag_scores = { chitchat = 3  },
	not_tags = { "has_killed_thatcher", "in_town" },
	[[
		!neutral
		!shocked
		I swear I hear music!
		!nervous
		Hey! I'm not crazy!
	]],
	[[
		!happy
		!greet
		Let's get goin', Hunter!
		!agree
		There's <#KONJUR>{name_multiple.i_konjur_heart}</> to be had.
	]],
	[[
		!agree
		Time to face the music.
		!gesture
		By which I mean a <#RED>{name.rot_boss}</>.
	]],
}

--berna AND hamish are still missing
AddQuips{
	tags = { "chitchat", "role_scout", "in_town"},
	not_tags = { "wf_town_has_armorsmith", "wf_town_has_blacksmith" },
	unique = "bath",
	[[
		!neutral
		!dubious
		Hmm... It occurs to me <#BLUE>{name.npc_blacksmith}</> and <#BLUE>{name.npc_armorsmith}</> haven't bathed since we last saw them...
		!think
		<z 0.7>Maybe I'll add an air freshener to the {name.damselfly}'s dash.</z>
		!nervous
		Oh! I didn't mean to say that out loud!
	]],
}
AddQuips{
	tags = { "chitchat", "role_scout", "in_town"},
	tag_scores = { chitchat = 2 },
	not_tags = { "wf_town_has_armorsmith", "wf_town_has_blacksmith" },
	unique = "tea",
	[[
		!neutral
		!think
		I wonder if <#BLUE>{name.npc_armorsmith}</> and <#BLUE>{name.npc_blacksmith}</> are getting hungry about now.
		!agree
		I'll see if I can scrounge up some tea before they get back.
	]],
}

--Fallbacks when player has a heartstone to hand in
AddQuips{
	tags = { "chitchat", "role_scout", "in_town", "holding_any_heart"},
	tag_scores = { holding_any_heart = 10 },
	[[
		!neutral
		!scared
		<i>ha</i>-CHOO!
		!happy
		!nervous
		Whew. My allergies are acting up all of the sudden.
	]],
	[[
		!happy
		!dubious
		Oh hey, don't forget about that <#KONJUR>{name.i_konjur_heart}</> in your bag.
		!point
		Go pop it in the <#KONJUR>{name.town_grid_cryst}</> when you get a chance, okay?
	]],
	[[
		!neutral
		!scared
		<i>ha</i>-CHOOoo!
		!nervous
		Whewie. Do you have a <#KONJUR>{name.i_konjur_heart}</> on you or something?
	]],
	[[
		!greet
		Heya Hunter, how's it--
		!neutral
		!scared
		--HA-CHOO
		!happy
		!nervous
		Ah. Have a <#KONJUR>{name.i_konjur_heart}</> on you, do ya?
	]],
	[[
		!neutral
		!dubious
		Hey. You planning to put that <#KONJUR>{name.i_konjur_heart}</> in the <#KONJUR>{name.town_grid_cryst}</> or--
		!shrug
		We could use the power, y'know.
	]]
}

------------------------------------------------------------------------------------
--DOJO MASTER QUIPS (TOOT)--
------------------------------------------------------------------------------------
AddQuips{
	tags = { "chitchat", "role_scout", "in_town", "wf_town_has_dojo" },
	unique = "dojo_toe_nails",
	[[
		!neutral
		!gesture
		I wish <#BLUE>{name.npc_dojo_master}</> wouldn't clip his toenails in the common area.
		!eyeroll
		Sigh.
	]],
}
------------------------------------------------------------------------------------
--COOK QUIPS (GLORABELLE)--
------------------------------------------------------------------------------------
AddQuips{
	tags = { "chitchat", "role_scout", "in_town", "wf_town_has_cook" },
	[[
		!happy
		!gesture
		<#BLUE>{name.npc_cook}</> is an interesting character, isn't she?
		!neutral
		!gesture
		I have no further comment on that.
	]],
	[[
		!happy
		!gesture
		If you're taking a <#RED>{name.lunchbox}</>, make sure it's packed before we leave.
		!shrug
		I don't wanna have to fly all the back for a sandwich.
	]],
	[[
		!happy
		!gesture
		You'll get some good <#RED>Buffs</> from <#BLUE>{name.npc_cook}'s</> cooking.
		!shrug
		I guess that's just my way of saying "Don't forget to eat".
	]],
}

return quips
