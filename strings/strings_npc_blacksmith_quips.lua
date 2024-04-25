local quips = {}
local AddQuips = function(tbl)
	table.insert( quips, tbl )
end

------------------------------------------------------------------------------------
--PLAYER HAS AN UPGRADABLE WEAPON EQUIPPED--
------------------------------------------------------------------------------------
AddQuips{
	tags = { "chitchat", "role_blacksmith", "can_upgrade_weapon", "has_killed_megatreemon" },
	[[
		!neutral
		!dubious
		You goin' ta <#RED>Upgrade</> that <#RED>Weapon</>, or naw?
		!gesture
		Ye can <#RED>Upgrade</> at the <#RED>Weapon Rack</> o'er yonder.
	]],
}
AddQuips{
	tags = { "chitchat", "role_blacksmith", "can_upgrade_weapon" },
	[[
		!neutral
		!dubious
		You goin' ta <#RED>Upgrade</> that <#RED>Weapon</>, or naw?
		!point
		Ye have all th'materials.
	]],
}
------------------------------------------------------------------------------------
--DUNGEON QUIPS--
------------------------------------------------------------------------------------
AddQuips{
	tags = { "chitchat", "role_blacksmith" },
	not_tags = { "in_town" },
	[[
		!neutral
		!gruffnod
		Hrm. Aye.
		!gesture
		I'll be seein' ye at camp then.
	]],
	[[
		!neutral
		!gruffnod
		Go on, then.
		!gesture
		I'll make me way to th' camp.
	]],
}
------------------------------------------------------------------------------------
--GENERAL TOWN QUIPS--
------------------------------------------------------------------------------------
AddQuips{
	tags = { "chitchat", "in_town", "role_blacksmith" },
	[[
		!neutral
		!point
		Yer wee {name.job_armorsmith}'s been snoopin' round me forge again.
		!dubious
		<z 0.7>(hmph)</>
	]],
	[[
		!neutral
		!disagree
		Hrm. Ye've got naught for me, I see.
		!dubious
		...
	]],
	[[
		!neutral
		!gruffnod
		'Tis a fine forge ye've got here.
		!closedeyes
		...
	]],
	[[
		!neutral
		!point
		Mind ye tell yer {name.job_armorsmith} she cannae name other people's tools.
		!dubious
		<z 0.7>(hmph)</>
	]],
}
------------------------------------------------------------------------------------
--WON LAST RUN--
------------------------------------------------------------------------------------

--general
AddQuips{
	tags = { "chitchat", "role_blacksmith", "in_town", "won_last_run" },
	[[
		!neutral
		!dubious
		Hrm.
		!gruffnod
		Yer showin' promise.
	]],
	[[
		!neutral
		!dubious
		Och, well done.
		!closedeyes
		I've not smiled like this in years.
	]],
	[[
		!neutral
		!gruffnod
		Ye almost gave <#BLUE>{name.npc_scout}</> a wee heart attack that time.
		!dubious
		...
	]],

}

--multiplayer
AddQuips{
	tags = { "chitchat", "role_blacksmith", "in_town", "won_last_run", "multiplayer" },
	[[
		!neutral
		!dubious
		...
		!gruffnod
		Doin' us all proud.
	]],
	[[
		!neutral
		!dubious
		...
		!point
		'Tis an honour to fight alongside yer pals.
	]],
}
--has a hammer
AddQuips{
	tags = { "chitchat", "role_blacksmith", "in_town", "won_last_run", "weapon_type_hammer" },
	[[
		!neutral
		!gruffnod
		Th' <#RED>{name.weapon_hammer}</>'s a good, honest weapon.
		!dubious
		...
	]],
}
------------------------------------------------------------------------------------
--LOST LAST RUN--
------------------------------------------------------------------------------------
AddQuips{
	tags = { "chitchat", "role_blacksmith", "in_town", "lost_last_run" },
	[[
		!neutral
		!gesture
		Hm... Listen, Hunter.
		!closedeyes
		Yer not the first to get knocked down a bit.
	]],
	[[
		!neutral
		!dubious
		Hunter.
		!closedeyes
		Those boggin' <#RED>{name_multiple.rot}'ll</> get theirs.
	]],
	[[
		!neutral
		!closedeyes
		{name.job_dojo}'s been askin' after ye.
		!dubious
		...
	]],
	[[
		!neutral
		!closedeyes
		I've got th' forge fired up if ye need.
		!dubious
		It ain't gettin' any hotter.
	]],
	[[
		!neutral
		!dubious
		...
		!gruffnod
		Failin' means yer playin'.
	]],
}
--struggling with a miniboss
AddQuips{
	tags = { "chitchat", "role_blacksmith", "in_town", "struggling_on_miniboss" },
	[[
		!neutral
		!gesture
		Hm... Listen, Hunter.
		!gruffnod
		Yer mind is yer best weapon.
	]],
}

--town has Kuma
AddQuips{
	tags = { "chitchat", "role_blacksmith", "in_town", "lost_last_run", "wf_town_has_apothecary" },
	[[
		!neutral
		!dubious
		Y'alright?
		!closedeyes
		Ye look like somethin' th' {name.job_apothecary} dragged in.
	]],
}
------------------------------------------------------------------------------------
--ABANDONED LAST RUN--
------------------------------------------------------------------------------------
AddQuips{
	tags = { "chitchat", "role_blacksmith", "in_town", "abandoned_last_run" },
	[[
		!neutral
		!closedeyes
		Still alive, I see.
		!gruffnod
		Good.
	]],
	[[
		!neutral
		!closedeyes
		Back for better weapons, are ye?
		!dubious
		Wise.
	]],
}
------------------------------------------------------------------------------------
--GLORABELLE QUIPS--
------------------------------------------------------------------------------------
AddQuips{
	tags = { "chitchat", "role_blacksmith", "in_town", "wf_town_has_cook" },
	[[
		!neutral
		!closedeyes
		Och, th' scullery reeks o' burnt porridge again.
		!dubious
		<z 0.7>(hmph)</>
	]],
	[[
		!neutral
		!closedeyes
		Th' {name.job_cook}'s been after me biscuit recipe.
		!dubious
		G'luck. I'm a steel trap.
	]],
	[[
		!neutral
		!closedeyes
		Th' dinner around here's like a Guild initiation rite.
		!dubious
		<z 0.7>(hmph)</>
	]],
	[[
		!neutral
		!gruffnod
		Yer {name.job_cook}'s fried tatties'd kill a {name.groak} faster'n a <#RED>{name.weapon_cannon}</>.
		!closedeyes
		<i>Och.</i>
	]],
}
------------------------------------------------------------------------------------
--DOJO MASTER QUIPS (TOOT)--
------------------------------------------------------------------------------------
AddQuips{
	tags = { "chitchat", "role_blacksmith", "in_town", "wf_town_has_dojo" },
	[[
		!neutral
		!closedeyes
		That {name.job_dojo}'s got a few marks on 'im.
		!dubious
		<z 0.7>(grumble)</>
	]],
	[[
		!neutral
		!gruffnod
		I had a square go wit' yer {name.job_dojo}.
		!point
		Fierce fella.
	]],
}

------------------------------------------------------------------------------------
--POTIONMAKER QUIPS (KUMA)--
------------------------------------------------------------------------------------
AddQuips{
	tags = { "chitchat", "role_blacksmith", "in_town", "wf_town_has_apothecary" },

	[[
		!neutral
		!closedeyes
		Yer {name.job_apothecary}'s not one for bletherin'.
		!gruffnod
		Makes a nice change.
	]],
	[[
		!neutral
		!closedeyes
		Th' town's gettin' crowded.
		!gruffnod
		<z 0.7>(hmph)</>
	]],

}
return quips
