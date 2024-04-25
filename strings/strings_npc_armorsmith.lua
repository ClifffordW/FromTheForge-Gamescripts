-- NPC
return
{
	QUESTS =
	{
		invite_to_town =
		{
			TALK = [[
				agent:
					!happy
					!greet
					Omigod, Hunter, you made it out alive!
				player:
					<i>(That's <#RED>{name.npc_armorsmith}</> the {name.job_armorsmith}!)</i>
				agent:
					!neutral
					!dubious
					How's <#BLUE>{name.npc_scout}</>? Are they okay??
			]],

			OPT_1 = "Yeah! They were worried about you.",
				
			TALK2 = [[
				agent:
					!happy
					!gesture
					Aw, they're so sweet-- but a lil aerial freefall's nothing to a big tough {name.job_armorsmith}!
					!point
					I arm-wrestled a <#RED>{name.zucco}</> once, you know.
			]],

			OPT_2A = "Whoa! Really?",
			OPT_2B = "That sounds questionably survivable.",

			TALK3 = [[
				agent:
					!neutral
					!think
					Or maybe I read that in a diary I found.
					!happy
					!shrug
					Anyway, it was a great story!
			]],

			OPT_3 = "<z 0.89>Oookay. Well, good to have our {name.job_armorsmith} back!</z>",

			TALK4 = [[
				agent:
					[title:SPEAKER]
					[sound:Event.joinedTheParty] 0.5
					!happy
					!clap
					Can't wait to get back and start upgrading your armour!
					[title:CLEAR]
			]],
		},

		twn_function_unlocked = 
		{
			TITLE = "Dressing for Battle",

			TALK = [[
				agent:
					!happy
					!greet
					Heya, Hunter. Thanks for the ride home.
			]],

			QUESTION_1 = "Glad to see you back!",

			ANSWER_1 = [[
				agent:
					!neutral
					!dubious
					And I'm glad to see you're in one piece.
					!happy
					!gesture
					<#BLUE>{name.npc_lunn}'d</> love to help you stay that way.
			]],

			QUESTION_2A = "Wait, who's {name.npc_lunn}?",
			QUESTION_2A_ALT = "Who's this {name.npc_lunn} you keep mentioning?", --opt changes if you pressed 2B before 2A
			QUESTION_2B = "So what do ya do around here?",
			QUESTION_2B_ALT = "So what can you... and {name.npc_lunn}... <i>do?</i>", --opt changes if you pressed 2A before 2B
			
			--BRANCH 2A START--
			ANSWER_2A = [[
				agent:
					!happy
					!wavelunn
					My leather cutter, obviously. He's my best buddy.
			]],

			QUESTION_3 = "Your best friend is a leatherworking tool? That's--",
                
            ANSWER_3 = [[
            	agent:
            		!neutral
                    !angry
					--it's <i>what</i>?
			]],

			QUESTION_4A = "That's great. Friends are important.",
			QUESTION_4B = "Um... that's a little weird.",

			ANSWER_4A = [[
				agent:
					!happy
					!agree
					Agreed! You'd be surprised how many people are rude about it.
			]],

			ANSWER_4B = [[
				agent:
					!neutral
					!shrug
					Maybe. But I'd rather be weird with my best buddy than normal without him!
			]],
			--plays after both 4A and 4B answers
			TALK2 = [[
				agent:
					!neutral
					!think
					Although he does take a "cut" of all my earnings...
			]],
			--BRANCH 2A END--

			--BRANCH 2B START--
			ANSWER_2B = [[
				agent:
					!happy
					!gesture
					<#BLUE>{name.npc_lunn}</> and I are expert {name.job_armorsmith}s!
					!point
					And now that we're back, you can interact with the <#RED>Armoury Dummy</> over there to do some <#RED>Upgrades</>.
					!gesture
					You give us <#RED>{name.rot} {name_multiple.material}</>, and we'll give you the best <#RED>Armour Upgrades</> in town!
			]],

			QUESTION_5A = "I can do that!",
			QUESTION_5B = "You mean I have to fight unprotected first?",

			ANSWER_5A = [[
				agent:
					!happy
					!clap
					I thought you could! Either way, <#BLUE>{name.npc_lunn}</> and I'll be here!
			]],

			ANSWER_5B = [[
				agent:
					!neutral
					!shrug
					Well yeah, we need the <#RED>{name.rot} {name_multiple.material}</> to upgrade the armour, silly.
					!happy
					!laugh
					And as {name.job_armorsmith}s say back home... no cuts, no glory!
					!gesture
					You'll be fine! Probably.
			]],
			--BRANCH 2B END--

			END_OPT = "It was nice to meet you properly!",
			END_TALK = [[
				agent:
					!happy
					!greet
					You too!
					!think
					...I hope I didn't miss anything juicy while I was away.
			]],
		},
	}
}
