-- NPC
return
{
	-- QUESTS
	QUESTS =
	{
		megatreemon = 
		{
			armor_hint = {
				TALK = [[
					agent:
						!greet
						Heyyy Hunter!
						!gesture
						Not to be <Ei>nosy</i>, but word on the street is that <#RED>{miniboss}</> is kicking your butt.
						!dubious
						Why don't you gather up some materials so I can make you a <#RED>Bonion Longcoat</>?
						!gesture
						I'd just need a <#KONJUR>Corestone</> and some <#RED>Bonion Skin</>.
						!dubious
						Hmm, what's that? Oh!
						!wavelunn
						{name.npc_lunn} says it would also bring out your eyes.
				]],
			},
		},
		-- QUEST IDd
		twn_shop_armor =
		{
			-- Objective
			resident =
			{
				-- Strings
				TALK_RESIDENT = [[
					agent:
						!point
						With the right armour, you don't <i>need</i> luck!
				]],

				TALK_HOME = [[
					agent:
						Is it... too messy?
				]],

				DISCUSS_UPGRADE = [[
					agent:
						Oh. My. God! I can't wait to show everyone!
						I'll <i>definitely</i> be able to do better upgrades with this gear.
						You're gonna be so well-protected out there!
					player:
						Glad you like it.
					agent:
						Like it? I love it!
						!wavelunn
						And so does {name.npc_lunn}!
				]],

				TALK_MOVED_HOME = [[
					agent:
						Ooh, I bet I can overhear more conversations from here.
					player:
						What?
					agent:
						Hm? I didn't say anything.
				]],

				OPT_SHOP = "Whatcha got for me?",
				OPT_LEAVE = "See ya, {name.npc_armorsmith}. <i><#RED><z 0.7>(Leave conversation)</></i></z>",
				OPT_HOME = "About your workshop...",
				OPT_UPGRADE = "Let's upgrade it",
				OPT_MOVE_IT = "Let's move it",
			}
		},

		--vanilla quest route
		primary_dgn_meeting_armorsmith =
		{
			TITLE = "Dressing for Battle",

			invite_to_town =
			{
				TALK = [[
					agent:
						!dubious
						...
					player:
						<i>(That's <#RED>{name.npc_armorsmith}</> the {name.job_armorsmith}!)</i>
					agent:
						!greet
						Omigod, Hunter, you made it out alive! Is {name.npc_scout} okay?
				]],

				OPT_1 = "Yeah! They were worried about you.",
					
				TALK2 = [[
					agent:
						!gesture
						Aw, they're so sweet-- but a lil aerial freefall's nothing to a big tough {name.job_armorsmith}!
						!point
						I arm-wrestled a <#RED>{name.zucco}</> once, you know.
				]],

				OPT_2A = "Whoa! Really?",
				OPT_2B = "That sounds questionably survivable.",

				TALK3 = [[
					agent:
						!think
						Or maybe I read that in a diary I found.
						!shrug
						Anyway, it was a great story!
					player:
						Oookay. Well, it's good to have our {name.job_armorsmith} back on the team.
					agent:
						[title:SPEAKER]
						[sound:Event.joinedTheParty] 0.5
						!clap
						Can't wait to get back and start upgrading your armour!
						[title:CLEAR]
				]],
			},
		},

		--this is a multiplayer alternate start to the quest if the player was present when the armorsmith was recruited in the dungeon but they werent the one to do it
		secondary_twn_meeting_armorsmith = 
		{
			TITLE = "Dressing for Battle",

			TALK = [[
				agent:
					!think
					Hey, I know you!
				player:
					Haha yeah, {name.npc_armorsmith}, right?
					I was there when--
				agent:
					!point
					--You're that Hunter who rubs earwax on their knuckles before every fight!
			]],

			OPT_1 = "What? Ew! No.",

			TALK2 = [[
				agent:
					!shrug
					Oh, that's too bad. I had a <i>lot</i> of questions.
				player:
					I was there when you were rescued, remember?
				agent:
					!greet
					Ohhh right! Nice to officially meet you! I'm {name.npc_armorsmith}.
					!point
					I do the best armour upgrades in town!
			]],

			OPT_2 = "How many other {name.job_armorsmith}s are in town?",

			TALK3 = [[
				agent:
					!shocked
					None!
					!gesture
					Let me know if you ever need upgraded gear, or even just a friendly ear...
					!bliss
					I'm a <i>very</i> good listener.
			]],
		},

		--this is a multiplayer alternate start to the quest if the player wasn't around when the armorsmith was recruited to town (they therefore need to meet her)
		tertiary_twn_meeting_armorsmith = 
		{
			TITLE = "Dressing for Battle",

			TALK = [[
				agent:
					...
				player:
					<i>(Hmm...)</i>
				agent:
					!dubious
					You know you're staring, right?
			]],

			OPT_1 = "Sorry! I can't remember your name.",

			TALK2 = [[
				agent:
					!laugh
					Hard to remember someone's name if you've never been introduced!
					!greet
					You must be a new Hunter. I'm {name.npc_armorsmith}, the {name.job_armorsmith}.
				player:
					{name.npc_armorsmith}? I heard you were in {name.npc_scout}'s {name.damselfly} when it went down!
				agent:
					!laugh
					I've survived worse.
					!think
					One time, I escaped a <#RED>{name.yammo}</> by rappelling down a cliff, using my own hair as a rope.
			]],

			OPT_2A = "Wow! That's incredible.",
			OPT_2B = "There's no way that's true.",

			TALK3 = [[
				agent:
					!agree
					Oh, it is. Although my hairline's never been quite the same.
					!shrug
					Point being, I don't die easy. And neither will anyone who wears my armour!
			]],

			OPT_3 = "Can you make me some armour?",

			TALK4 = [[
				agent:
					!wavelunn
					We actually specialize in <i>upgrading</i> armour. We aren't doing custom work right now.
					!laugh
					All you have to do is source the <#RED>{name.rot} {name_multiple.material}</> for me and {name.npc_lunn}.
			]],

			OPT_4A = "Wait, sorry, who's {name.npc_lunn}?",
			OPT_4B = "So let me get this straight--",
			OPT_4C = "I'm off to fight some {name_multiple.rot}!",

			--BRANCH START--
			--BRANCH 1--
			OPT4A_RESPONSE = [[
				agent:
					!wavelunn
					My leather cutter! He's my best pal.
				player:
					Your best pal is your leatherworking tool? That's--
				agent:
					!angry
					--That's <i>what</i>?
			]],

			OPT_5A = "Cool. Wish <i>my</i> friends were that \"sharp\".",
			OPT_5B = "Honestly? A little weird.",

			OPT5A_RESPONSE = [[
				agent:
					!clap
					Ha ha! "Sharp"! I love it.
					!point
					By the way, I've just decided we're friends.
			]],

			OPT5B_RESPONSE = [[
				agent:
					!shocked
					Gasp! {name.npc_lunn}'s fragile after everything we've been through!
					!wavelunn
					Don't listen to the mean Hunter, {name.npc_lunn}.
			]],
			--1--

			--BRANCH 2--
			OPT4B_RESPONSE = [[
				player:
					--You want me to fight <#RED>{name_multiple.rot}</> unprotected, so you can upgrade my armour to protect me while fighting <#RED>{name_multiple.rot}</>?
				agent:
					!shrug
					Yeah!
					!gesture
					We need the <#RED>{name.rot} {name_multiple.material}</> to upgrade the armour, silly.
					!laugh
					And as {name.job_armorsmith}s say back home... no cuts, no glory!
					!gesture
					You'll be fine! Probably.
			]],
			--2--

			--BRANCH 3--
			OPT4C_RESPONSE = [[
				agent:
					!greet
					Go get 'em, Hunter!
			]],
			--3--
			--BRANCH END--
		},

		--the player came in during multiplayer and missing the intro flitt dialogue about the crashed damselfly
		--as a result they dont have the quest to recruit the armorsmith but can still meet him in the forest to recruit him anyway
		--ie "Oh, you're with the Foxtails! Can you help me back to camp"
		tertiary_alt_dgn_meeting_armorsmith =
		{
			TALK = [[
				agent:
					!greet
					Ooo, oo oo oo!
					!shocked
					Hey! Are you with the {name_multiple.foxtails}?
				player:
					Uh... Yes?
				agent:
					!wavelunn
					You hear that, {name.npc_lunn}? You're saved!
			]],

			OPT_1B = "Who are you?",
			--BRANCH START--

			--BRANCH 1--
			OPT1A_RESPONSE = [[
				agent:
					!wavelunn
					My leather cutter! He's my best pal.
				player:
					Your best pal is your leatherworking tool? That's--
				agent:
					!angry
					--That's <i>what</i>?
			]],

			OPT_2A = "Cool. Wish <i>my</i> friends were that \"sharp\".",
			OPT_2B = "Honestly? A little weird.",

			OPT2A_RESPONSE = [[
				agent:
					!clap
					Ha ha! "Sharp"! I love it.
					!point
					By the way, I've just decided we're friends.
			]],

			OPT2B_RESPONSE = [[
				agent:
					!shocked
					Gasp! I can't believe you'd bully {name.npc_lunn} when he's already so clearly traumatized!
					!wavelunn
					Don't listen to the mean Hunter, {name.npc_lunn}. We'll be home soon.
			]],
			--1--

			--TODO KRIS: ask if its possible to have flitt talk offscreen from the sky in the dungeon

			OPT1B_RESPONSE = [[
				agent:
					!greet
					I'm {name.npc_armorsmith}, the {name_multiple.foxtails}' {name.job_armorsmith}! Or at least, I was supposed to be before that crash flung me into the woods.
					!gesture
					I've gotta get back to town, otherwise you poor little Hunters will be totally defenseless against the <#RED>{name_multiple.rot}</>!
					!gesture
					Would you mind letting {name.npc_scout} know I'm here?
			]],

			OPT_3 = "Of course!",
			OPT_3_ALT = "I'll let {name.npc_scout} know their {name.job_armorsmith}'s here.",

			TALK2 = [[
				agent:
					[title:SPEAKER]
					[sound:Event.joinedTheParty] 0.5
					!clap
					Thanks so much!
					[title:CLEAR]
			]], 

			--TODO(KRIS): variations on "See ya back at camp"
			QUIP_RENDEZVOUS_IN_TOWN = {
				
			},
		},

		
	}
}
