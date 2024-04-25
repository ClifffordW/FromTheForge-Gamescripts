local quips = {}
local AddQuips = function(tbl)
	table.insert( quips, tbl )
end

AddQuips{
	tags = { "chitchat", "role_konjurist" },
	[[
		!happy
		!dubious
		The raw <#KONJUR>{name.i_konjur}</> is pretty potent here.
		!closedeyes
		It's great.
	]],
	[[
		!happy
		!bliss
		Don't you love the sting of <#KONJUR>{name.i_konjur}</> hitting your nostrils?
		!shrug
		I know I do.
	]],
	[[
		!neutral
		!thinking
		Now what if...?
		!notebook
		No, no, that won't work.
	]],
	[[
		!neutral
		!point
		Haha, I knew you were headed this way.
		!gesture
		My equipment's been going nuts.
	]],
	[[
		!neutral
		!gesture
		Watch your step.
		!shrug
		I've got a bunch of gadgets and crystals strewn about.
	]],
	[[
		!neutral
		!notebook
		Well, I didn't expect <i>that</i> result.
		!notebook
		That's research for you.
	]],
	[[
		!happy
		!notebook
		Hmm...
		!think
		How interesting.
	]],
	[[
		!neutral
		!notebook
		Making a note of that...
		!dubious
		Huh? Sorry, I was distracted.
	]],
	[[
		!neutral
		!shrug
		Kinda hard to work when you're making my equipment go haywire.
		!notebook
		Not that you can control it, I guess.
	]],
	[[
		!happy
		!notebook
		You're welcome to hang.
		!notebook
		The <#KONJUR>{name.i_konjur}</> fumes are wonderfully fragrant this time of day.
	]],
	[[
		!neutral
		!dubious
		How do I move from room to room?
		!shrug
		Very carefully.
	]],
	[[
		!neutral
		!think
		What's it like to be full of <#KONJUR>{name.i_konjur}</>?
		!closedeyes
		Bet its nice.
	]],
}

AddQuips{
	tags = { "chitchat", "role_konjurist", "upgradable_powers", "can_get_free_upgrade" },
	[[
		!happy
		!point
		Whewie, you're <i>ripe</i> with <#KONJUR>{name.i_konjur}</> stink-- need an <#RED>Upgrade</>?
	]],
	[[
		!neutral
		!greet
		Oh, hey. Want an <#RED>Upgrade</>? First one's free.
	]],
	[[
		!neutral
		!gesture
		First <#RED>Upgrade</>'s on the house. After that I'll need some <#KONJUR>{name.i_konjur}</>.
	]],
	[[
		!neutral
		!greet
		First <#RED>Upgrade's</> always free.
	]],
	[[
		!neutral
		!notebook
		Oh. Is it <#RED>Upgrade</> time?
	]],
	[[
		!neutral
		!greet
		Want an <#RED>Upgrade</>? First one's on me.
	]],
	[[
		!neutral
		!point
		First <#RED>Upgrade's</> on the house.
	]],
}

AddQuips{
	tags = { "chitchat", "role_konjurist", "upgradable_powers" },
	not_tag = { "free_upgrade_available" },
	[[
		!neutral
		!notebook
		Need anymore <#RED>Upgrades</>?
	]],
	[[
		!neutral
		!notebook
		Don't forget, only the <i>first</i> one's free.
	]],
	[[
		!neutral
		!gesture
		I can do more <#RED>Upgrades</> if you don't mind paying.
	]],
	[[
		!neutral
		!shrug
		I'm out spare <#KONJUR>{name.konjur}</>, so you'll have to pay if you want another <#RED>Upgrade</>.
	]],
	[[
		!neutral
		!notebook
		If you need any more <#RED>Upgrades</>, I'm your <#KONJUR>{name.job_konjurist}</>.
	]],
	[[
		!neutral
		!dubious
		I can do another <#RED>Upgrade</> if you've got the <#KONJUR>{name.konjur}</>.
	]],
	[[
		!neutral
		!gesture
		Thanks for letting me do a free <#RED>Upgrade</>. It's a nice break.
	]],
	[[
		!neutral
		!dubious
		So? How's the <#RED>Upgrade</> feel?
	]],
	[[
		!neutral
		!shrug
		Hope that free <#RED>Upgrade</> does you some good.
	]],
	[[
		!neutral
		!dubious
		Did you want to look at the <#RED>Upgrade</> options again?
	]],
	[[
		!neutral
		!point
		If you want some more <#RED>Upgrades</>, I'll need some <#KONJUR>{name.konjur}</>.
	]],
	[[
		!neutral
		!dubious
		Need something else?
	]],
}

AddQuips{
	tags = { "chitchat", "role_konjurist"},
	not_tags = { "upgradable_powers" },
	[[
		!neutral
		!dubious
		No <#RED>{name_multiple.concept_relic}</> to <#RED>Upgrade</> today?
		!notebook
		'Shame.
	]],
	[[
		!neutral
		!notebook
		Eh? Oh. You've got nothing for me to <#RED>Upgrade</> today.
		!dubious
		Well, I'll be here when you need me.
	]],
	[[
		!neutral
		!dejected
		Aw, you've got nothing to <#RED>Upgrade</>.
		!notebook
		I was looking forward to a break.
	]],
	[[
		!neutral
		!dubious
		Eh? You've got nothing to <#RED>Upgrade</>.
		!notebook
		What a bummer.
	]],
	[[
		!neutral
		!notebook
		Nothing to <#RED>Upgrade</> today, huh?
		!shrug
		Maybe you'll get a <#RED>{name.concept_relic}</> in the next room.
	]],
	[[
		!neutral
		!notebook
		Nothing to <#RED>Upgrade</>?
		!shrug
		Just as well, I'm behind on data entry.
	]],
}

return quips
