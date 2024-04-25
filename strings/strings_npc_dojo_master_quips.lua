local quips = {}
local AddQuips = function(tbl)
	table.insert( quips, tbl )
end

AddQuips{
	tags = { "chitchat", "in_town", "role_hunter", "can_claim_mastery" },
	[[
		!happy
		!point
		<#RED>{name.npc_scout}</> tells me you've completed another challenge!
		!gesture
		You can claim yer Mastery whenever you're ready.
	]],
	[[
		!happy
		!point
		I hear you finished off one of my challenges, Hunter.
		!gesture
		I've got a little <#KONJUR>Treat</> for you, when you're ready to claim it.
	]],
}

------------------------------------------------------------------------------------
--LOST LAST RUN--
------------------------------------------------------------------------------------
AddQuips{
	tags = { "chitchat", "role_hunter", "in_town", "lost_last_run" },
	[[
		!gesture
		<#RED>Healing's</> scarce on Hunts.
		!happy
		!gruffnod
		Best not to get hit if you can help it.
		!neutral
	]],
	[[
		!cough
		Listen up, Hunter.
		!gruffnod
		Failed Hunts is just learning experiences.
	]],
	[[
		!gruffnod
		Welcome back.
		!gesture
		I'm prouda you for getting out there.
	]],
	[[
		!dubious
		Get yer butt whupped?
		!disagree
		Ain't no shame in a loss. It's part of the process.
	]],
}

--singleplayer OR multiplayer
AddQuips{
	tags = { "chitchat", "in_town", "role_hunter" },
	[[
		!point
		It's easy to regret a swing, but you'll never regret a <#RED>{name.concept_dodge}</>.
		!shrug
		So, y'know. <#RED>{name.concept_dodge}</>.
	]],
	[[
		!gesture
		You can check yer <#RED>Weight Class</> over at the <#RED>Armoury</>.
		!cough
		{name.dojo_cough}
	]],
	[[
		!gesture
		You can check yer <#RED>Weight Class</> over at any <#RED>Weapon Rack</>.
		!cough
		{name.dojo_cough}
	]],
	[[
		!point
		Be thoughtful when yer trying new <#RED>Armour</>.
		!gesture
		Changing your gear might change your <#RED>Weight Class</>.
	]],
	[[
		!happy
		!shrug
		It's easier to fight when you're comfy.
		!neutral
		!gesture
		Try mixin' and matchin' <#RED>Armour</> sets to get your favourite <#RED>Weight Class</>.
	]],
	[[
		!eyeroll
		Kids these days can't get enough of them "<#RED>Emote Wheels</>" <p bind='Controls.Digital.SHOW_EMOTE_RING' color=BTNICON_DARK>.
		!disagree
		I prefer to never express myself.
	]],
	[[
		!point
		Some <#RED>{name_multiple.concept_relic}</> is more powerful than others, y'know.
		!gruffnod
		You can tell <#RED>Fabled {name_multiple.concept_relic}</> apart by the fancier frames around their icons.
	]],
	[[
		!point
		Listen up.
		!gruffnod
		You can do <#RED>Dodge Cancels</> to keep up your <#RED>Hit Streak</>.
	]],
	[[
		!point
		How's yer gear treatin' you?
		!shrug
		Gettin' new equipment's just as important as upgrading your old stuff. Maybe even more.
	]],
	[[
		!point
		Didja know smacking objects in the environment keeps yer <#RED>Hit Streak</> going?
		!gesture
		'Thought it was a good tip.
	]],
	[[
		!dubious
		A <#RED>{name.beets}</> is dazed after a head slam.
		!point
		Bait and <#RED>{name.concept_dodge}</> before going in for the kill.
	]],
	[[
		!cough
		{name.dojo_cough}
		!point
		You can swap your equipped gear at the <#RED>Armoury</> here in town.
	]],
	[[
		!gesture
		You can't change your gear once you set out on a Hunt.
		!cough
		{name.dojo_cough} Dress wisely before you leave.
	]],
	[[
		!point
		Don't forget, it's more important to stay alive than it is to strike.
		!happy
		!gruffnod
		This is yer daily reminder to <#RED>{name.concept_dodge}</>.
	]],
	[[
		!gruffnod
		Remember, all <#RED>Weight</> builds are viable.
		!point
		You just gotta find what build works for you.
	]],
	[[
		!cough
		{name.dojo_cough}
		!gruffnod
		All great Hunters started off as newbies trying stuff out.
	]],
	[[
		!agree
		If you ever feel stuck, try changing up your gear.
		!happy
		!shrug
		If nothing else, you'll feel snazzy.
	]],
	[[
		!agree
		Gettin' stuck's just an opportunity to try new things.
		!gesture
		Try experimenting with your tactics.
	]],
	[[
		!dubious
		<#RED>{name_multiple.rot}</> have melons for brains.
		!disagree
		<#RED>{name_multiple.yammo}'ll</> hit their own pals if you bait a swing right.
	]],
	[[
		!cough
		{name.dojo_cough} Hey.
		!dubious
		Be wary of the folks in the woods.
	]],
	[[
		!cough
		You done any training lately?
		!point
		You can practice <#BLUE>Focus Hits</> on the dummies here in town.
	]],
	[[
		!gesture
		<#RED>{name_multiple.concept_relic}</> only last for one Hunt.
		!point
		Experiment with yer combinations.
	]],
	[[
		!cough
		Listen up, Hunter.
		!gesture
		You'll know yer <#RED>Luck</> stat swayed a sitchy-ation if you see a <#RED>Lucky Clover Icon</>.
	]],
	[[
		!gesture
		Gusts of <#RED>Wind</> aren't so bad if you're a <#RED>{name.heavy_weight} Class</> build.
		!dubious
		<#RED>{name.light_weight} Class</> build? Different story.
	]],
	[[
		!cough
		Listen up, Hunter.
		!point
		Every <#RED>Enemy</> is predictable, if you learn to read them.
	]],
	[[
		!point
		Study your foes. Watch their moves.
		!gruffnod
		Soon you'll see the openings.
	]],
	[[
		!gesture
		Didja know you can get a <#RED>Critical</> <#BLUE>Focus Hit</>?
		!gruff
		Powerful stuff.
	]],
	[[
		!cough
		{name.dojo_cough}
		!greet
		Need a lesson?
	]],
	[[
		!cough
		{name.dojo_cough}
		!greet
		How're yer studies going?
	]],
	[[
		!gruffnod
		Need anything explained?
		!cough
		Ask away.
	]],
	[[
		!gruffnod
		Hmph.
		!agree
		I'm in a teachin' mood today.
	]],
	[[
		!cough
		{name.dojo_cough}
		!gesture
		Don't forget to review the fundamentals.
	]],
	[[
		!cough
		{name.dojo_cough}
		!greet
		Need me to explain anythin'?
	]],
}

--player has either a keyboard OR a gamepad and is playing with someone
AddQuips{
	tags = { "chitchat", "role_hunter", "in_town", "multiplayer"},
	[[
		!cough
		{name.dojo_cough}
		!gesture
		Remember that you and other Hunters are working together.
	]],
	[[
		!gesture
		By the way, if yer fighting with allies and get knocked out try hitting the <#RED>Attack</> and <#RED>{name.concept_dodge}</> buttons.
		!cough
		Ghe-he-he.
	]],
}

--player has a keyboard and is playing with someone
AddQuips{
	tags = { "chitchat", "role_hunter", "in_town", "multiplayer"},
	not_tags = { "using_gamepad" },
	[[
		!cough
		{name.dojo_cough}
		!gruffnod
		If you learn something useful out there, share the tip with your fellow Hunters.
	]],
	[[
		!cough
		{name.dojo_cough}
		!gruffnod
		By the way, you can communicate with other Hunters by pressing <p bind='Controls.Digital.TOGGLE_SAY' color=BTNICON_DARK> to chat.
	]],
}

return quips
