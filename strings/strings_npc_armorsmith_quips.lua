local quips = {}
local AddQuips = function(tbl)
	table.insert( quips, tbl )
end


------------------------------------------------------------------------------------
--GENERAL DUNGEON QUIPS--
------------------------------------------------------------------------------------
AddQuips {
	tags = {"chitchat", "role_armorsmith" },
	not_tags = { "in_town" },
	[[
		!happy
		!wavelunn
		<#BLUE>{name.npc_lunn}</> and I are gonna take a big nap the second we get home.
		!closedeyes
		Can't wait.
	]],
	[[
		!happy
		!gesture
		Don't let any monsters bite your butt while you're out here.
		!shrug
		Or do. Who am I to give orders.
	]],
	[[
		!happy
		!bliss
		It'll be nice to get to camp and take a load off.
		!closedeyes
		Maybe a warm foot bath.
	]],
	[[
		!happy
		!laugh
		So tell me more about how <#BLUE>{name.npc_scout}</> was worried about me.
		!wavelunn
		Heehee.
	]],
	[[
		!happy
		!clap
		I can't wait to see who else joins our camp!
		!shrug
		What can I say? I'm a people person.
	]],
	[[
		!happy
		!clap
		I'll be at the camp if you need me!
		!gesture
		See you there!
	]],
	[[
		!happy
		!clap
		Come say hi after your Hunt!
		!gesture
		We have so much to chat about.
	]],
	[[
		!happy
		!clap
		See you at home... <i>neighbour!</i>
		!wavelunn
		Heehee.
	]],
}

------------------------------------------------------------------------------------
--GENERAL TOWN QUIPS--
------------------------------------------------------------------------------------
AddQuips{
	tags = { "chitchat", "in_town", "role_armorsmith" },
	[[
		!happy
		!dubious
		Find you're dying a bunch out there?
		!point
		The right kind of <#RED>Armour</> could change that...
	]],
	[[
		!happy
		!dubious
		Skin too soft?
		!shocked
		Protect it with <#RED>Armour</>!
	]],
	[[
		!happy
		!dubious
		Been feeling unlucky on the Hunt?
		!shocked
		With the right <#RED>Armour</>, you don't <i>need</i> luck!
	]],
	[[
		!happy
		!shocked
		People's voices really carry in this camp. 
		!bliss
		I love it!
	]],
	[[
		!happy
		!think
		I wonder if <#BLUE>{name.npc_dojo_master}</> would take <#BLUE>{name.npc_lunn}</> as an apprentice.
		!agree
		<#BLUE>{name.npc_lunn}'s</> very studious.
	]],
	[[
		!happy
		!point
		Information is the best <#RED>Armour</>.
		!shocked
		That's why I'm <i>always</i> listening!
	]],
	[[
		!greet
		!point
		You're looking sharp!
		!wavelunn
		Almost as sharp as <#BLUE>{name.npc_lunn}</>.
	]],
	[[
		!shocked
		D'you ever think about singing your feelings?
		!point
		I think you'd be good at it.
	]],
	[[
		!gesture
		Folks say I talk too much.
		!shrug
		But then when I listen, they call it eavesdropping.
	]],
	[[
		!happy
		!gesture
		You know what makes me a good friend? I'm a great secret-keeper.
		!point
		For example, I've never told anyone that <#BLUE>{name.npc_scout}'s</> self-conscious about his snout.
	]],
	[[
		!notebook
		Says here you've been voted "Most Likely To Sleep Through A Natural Disaster."
		!shrug
		Honestly, same.
	]],
	[[
		!wavelunn
		<#BLUE>{name.npc_lunn}</> once carved my initials into a <#RED>{name.gourdo}'s</> leg.
		!laugh
		He got almost halfway through the "B" before it woke up.
	]],
	[[
		!happy
		!think
		D'you think <#BLUE>{name.npc_scout}</> would let me borrow the <#RED>{name.damselfly}</>?
	]],
	[[
		!happy
		!shocked
		You'll never guess who came by my workshop today!
		!eyeroll
		Oh wait, I promised not to say.
	]],

}

------------------------------------------------------------------------------------
--have polearm equipped in town--
------------------------------------------------------------------------------------
AddQuips{
	tags = { "chitchat", "weapon_type_polearm", "in_town", "role_armorsmith" },
	[[
		!happy
		!clap
		I knew it was a <#RED>{name.rot}</> kebab kind of day!
		!point
		Just watch where you point that thing.
	]],
}

------------------------------------------------------------------------------------
--WON LAST RUN--
------------------------------------------------------------------------------------
AddQuips{
	tags = { "chitchat", "role_armorsmith", "in_town", "won_last_run" },
	[[
		!greet
		I've been hearing a <i>lot</i> of chatter about you...
		!point
		...folks are saying you're a natural!
	]],
	[[
		!neutral
		!gesture
		Even if you <i>do</i> wipe out all the <#RED>{name_multiple.rot}</>...
		!happy
		!bliss
		...you'll need <#RED>Armour</> to stay safe from all your fans.
	]],
	[[
		!clap
		Way to slay, Hunter!
		!point
		Get it? 'Cause you slayed all those <#RED>{name_multiple.rot}</>.
	]],
	[[
		!gesture
		If you ever run outta <#RED>{name_multiple.rot}</> to hunt...
		!laugh
		...<#BLUE>{name.npc_lunn}</> could teach you to be an {name.job_armorsmith}!
	]],
	[[
		!greet
		That last run was <i>killer!</i>
		!laugh
		Hooyah!
	]],
	[[
		!point
		All your training is really paying off.
		!think
		D'you think I could train myself to be taller?
	]],
	[[
		!dubious
		!disagree
		You're not a Hunter.
		!point
		!clap
		You're a DECIMATOR! Hooyah!
	]],
	[[
		!notebook
		<i>Dear Diary, many <#RED>{name.rot}</> butts were kicked today.</i>
		!think
		Do you think <#BLUE>{name.npc_dojo_master}</> minds that I borrowed his diary?
	]],
}
------------------------------------------------------------------------------------
--LOST LAST RUN--
------------------------------------------------------------------------------------
AddQuips{
	tags = { "chitchat", "role_armorsmith", "in_town", "lost_last_run" },
	[[
		!gesture
		Welcome home!
		!point
		I hear you gave almost as good as you got.
	]],
	[[
		!happy
		!gesture
		I really admire your grit.
		!neutral
		!point
		...and your ears.
	]],
	[[
		!neutral
		!gesture
		When I've had a rough run, I like to go scream into a tree.
		!happy
		!point
		The trees don't mind. I asked.
	]],
	[[
		!gesture
		Heya, welcome back.
		!point
		Glad you made it out with all your limbs!
	]],
	[[
		!wave
		Hey Hunter!
		!point
		Those <#RED>{name_multiple.rot}</> are in for a <i>big</i> surprise next time.
	]],
	[[
		!greet
		Hey Hunter!
		!point
		You really gave those <#RED>{name_multiple.rot}</> a run for their... rottenness.
	]],
	[[
		!greet
		!wavelunn
		<#BLUE>{name.npc_lunn}</> says he's got a good feeling about your next run!
		!point
		!agree
		You're scrappy, like us.
	]],
	[[
		!gesture
		It's not just about winning.
		!point
		It's about putting up a fight.
	]],
	[[
		!gesture
		Yowza...those <#RED>{name_multiple.rot}</> are tough!
		!point
		And so are you.
	]],
	[[
		!gesture
		I know what it's like to get my butt kicked.
		!shrug
		I had a family once.
	]],
	[[
		!wavelunn
		Folks think I won <#BLUE>{name.npc_lunn}</> in a leg-wrestling match against three {name_multiple.cabbageroll}.
		!shrug
		Truth is, I stole him off the jerk who laughed at me for losing.
	]],
	[[
		!point
		It's not a loss as long as you learn something.
		!shrug
		Even if all you learn is that you need better <#RED>Armour</>.
	]],
}
------------------------------------------------------------------------------------
--ABANDONED LAST RUN--
------------------------------------------------------------------------------------
AddQuips{
	tags = { "chitchat", "role_armorsmith", "in_town", "abandoned_last_run" },
	[[
		!greet
		I've been looking for you!
		!point
		Can you tell <#BLUE>{name.npc_scout}</> the {name.damselfly} should be a community vehicle?
	]],
	[[
		!greet
		Welcome home!
		!think
		"Home." Huh. It's got a nice mouthfeel.
	]],
}
------------------------------------------------------------------------------------
--BLACKSMITH QUIPS (HAMISH)--
------------------------------------------------------------------------------------
--town has hamish
AddQuips{
	tags = { "chitchat", "role_armorsmith", "in_town", "wf_town_has_blacksmith" },
	[[
		!bliss
		<#BLUE>{name.npc_blacksmith}</>'s sonnets are so lyrical.
		!point
		You didn't hear it from me.
	]],
	[[
		!think
		You know some folks call <#BLUE>{name.npc_blacksmith}</> "HAM-ish" instead of "HAY-mish"?
		!shrug
		He's really not much of a ham.
	]],
	[[
		!point
		!shocked
		They say that <#BLUE>{name.npc_blacksmith}</> gave <i>himself</i> that tattoo.
		!laugh
		!shrug
		Okay, nobody says that. But it could be true!
	]],
	[[
		!shocked
		!wavelunn
		<#BLUE>{name.npc_blacksmith}'s</> hammer just called <#BLUE>{name.npc_lunn}</> <i>dull</i>.
		!eyeroll
		!disagree
		What a tool.
	]],
	[[
		!eyeroll
		<#BLUE>{name.npc_blacksmith}</> is <i>so weird</i> about accepting help.
		!shocked
		!laugh
		I spent all morning suggesting names for his hammer, and he told me to go <i>boil my head!</i>
	]],
	[[
		!point
		Does <#BLUE>{name.npc_blacksmith}</> seem okay to you?
		!think
		He seems gruntier than usual.
	]],
}
--hamish hasnt been rescued yet
AddQuips{
	tags = { "chitchat", "role_armorsmith", "in_town"},
	not_tags = { "wf_town_has_blacksmith" },
	[[
		!nervous
		Do you think <#BLUE>{name.npc_blacksmith}</> has made new friends elsewhere?
		!neutral
		!shrug
		Not that I'd care.
		!wavelunn
		But <#BLUE>{name.npc_lunn}</> misses him.
	]],
	[[
		!nervous
		You're still looking for <#BLUE>{name.npc_blacksmith}</>, right?
		!dejected
		He's not as tough as he thinks.
	]],
	[[
		!nervous
		It's not that I miss <#BLUE>{name.npc_blacksmith}</>, it's just...
		!dubious
		...no one's grunted angrily at me in ages.
	]],
}
------------------------------------------------------------------------------------
--DOJO MASTER QUIPS (TOOT)--
------------------------------------------------------------------------------------
AddQuips{
	tags = { "chitchat", "role_armorsmith", "in_town", "wf_town_has_dojo" },
	[[
		!neutral
		!gesture
		<#BLUE>{name.npc_dojo_master}</> once killed a <#RED>{name.rot}</> by slapping it in the face with a sandwich.
		!shocked
		And then ate the sandwich!
	]],
	[[
		!gesture
		<#BLUE>{name.npc_dojo_master}</> mutters in his sleep.
		!think
		It'd be nice if he spoke up a little.
	]],
	[[
		!shocked
		<#BLUE>{name.npc_dojo_master}</> told <#BLUE>{name.npc_scout}</> you were a gut biter!
		!think
		!shrug
		Or maybe it was "good fighter." Lip-reading is hard.
	]],
	[[
		!greet
		<#BLUE>{name.npc_dojo_master}</> has never stayed in one place this long.
		!shrug
		He must <i>really</i> like my work.
	]],
	[[
		!wavelunn
		<#BLUE>{name.npc_lunn}</> and I would be great {name.job_dojo}s!
		!shrug
		We just don't wanna step on <#BLUE>{name.npc_dojo_master}</>'s toes. He's already missing a few.
	]],
}
------------------------------------------------------------------------------------
--COOK QUIPS (GLORABELLE)--
------------------------------------------------------------------------------------
AddQuips{
	tags = { "chitchat", "role_armorsmith", "in_town", "wf_town_has_cook" },
	[[
		!happy
		!gesture
		<#BLUE>{name.npc_cook}</> says superheating food releases the nutrients.
		!point
		That's why she makes sure to burn everything.
	]],
	[[
		!neutral
		!shocked
		Some <#RED>{name.rot}</>-tainted jerk called <#BLUE>{name.npc_cook}'s</> food "slop"!
		!dubious
		!angry
		They're not <i>wrong</i>. But still.
	]],
	[[
		!happy
		!shocked
		Smell that?
		!bliss
		It's mystery mash casserole night!
	]],
	[[
		!happy
		!gesture
		You know what's worse than food poisoning?
		!point
		!agree
		Eating raw <#RED>{name.gnarlic}</> out of a shoe. Trust me.
	]],
	[[
		!happy
		!shocked
		A few more weeks with <#BLUE>{name.npc_cook}</>, and you'll have a cast-iron gut!
		!point
		That's like <#RED>Armour</> for your insides.
	]],
	[[
		!happy
		!gesture
		I added flame-retardant lining to <#BLUE>{name.npc_cook}'s</> apron.
		!clap
		She said she's already getting lots of use out of it!
	]],

}
------------------------------------------------------------------------------------
--POTIONMAKER QUIPS (DOC HOGGINS)--
------------------------------------------------------------------------------------
AddQuips{
	tags = { "chitchat", "role_armorsmith", "in_town", "wf_seen_npc_potionmaker_dungeon" },
	[[
		!neutral
		!gesture
		I got a free mouthwash sample from a slippery salesman out there once...
		!shocked
		...turned out to be a <i>very</i> powerful burping potion.
	]],
	[[
		!neutral
		!dubious
		You're not talking to <i>strange</i> strangers out there, are you?
		!clap
		You could be home talking to strange friends instead!
	]],
}
return quips
