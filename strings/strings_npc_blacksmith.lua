-- NPC
return
{
	QUESTS =
	{
		invite_to_town =
		{
			-- Use narration (*) to indicate the player's inner monologue.
			TALK = [[
				agent:
					!neutral
					!dubious
					...
				player:
					<i>(Hey, that's <#BLUE>{name.npc_blacksmith}</>, the {name.job_blacksmith}!)</i>
				agent:
					!dubious
					...Who are ye?
			]],

			OPT_1A = "<z 0.9>I'm with the {name_multiple.foxtails}. I'm so glad you're okay!</>",
			OPT_1B = "<i>You</i> can call me \"Your Saviour\".",

			TALK2 = [[
				agent:
					!happy
					!think
					Ah. I remember ye now.
					!neutral
					!point
					Ye were the one that kept screamin' as our ship went down.
			]],

			OPT_2A = "I knew you'd remember me!",
			OPT_2B = "Uh no, you must be thinking of {name.npc_scout}.",
			OPT_2C = "Close enough.",

			TALK3 = [[
				agent:
					!point
					Wailin' like a wee bairn, ye were.
			]],

			OPT_3 = "Yeah, well-- {name.npc_scout}'s waiting to pull you up.",

			TALK4 = [[
				agent:
					[title:SPEAKER]
					[sound:Event.joinedTheParty] 0.5
					!neutral
					!gruffnod
					Hrm. Aye. I'll be seein' ye at camp then.
					[title:CLEAR]
			]],
		},

		twn_function_unlocked = 
		{
			TITLE = "Hammer Home",

			TALK = [[
				agent:
					!neutral
					...
			]],

			QUESTION_1 = "You made it home!",

			ANSWER_1 = [[
				agent:
					!neutral
					!gesture
					O'course I did.
					!dubious
					But enough o'the bletherin'. Th'forge is up and ready.
			]],

			QUESTION_2A = "Can I get new Weapon types from you?",
			QUESTION_2B = "What sort of Upgrades do you do?",

			ANSWER_2A = [[
				agent:
					!neutral
					!think
					I tell ye what.
					!gesture
					I need <#KONJUR>{name_multiple.konjur_soul_lesser}</> ta fuel th'forge.
					!point
					You bring some <#KONJUR>{name_multiple.konjur_soul_lesser}</> to the <#RED>Weapon Racks</> o'er there, and I'll set ye up right.
					!gruffnod
					Deal? Deal.
			]],
			ANSWER_2B = [[
				agent:
					!neutral
					!dubious
					...
					!point
					<#RED>Weapon Upgrades</> only.
					!think
					<#RED>Hammers</>, <#RED>Spears</>, <#RED>Cannons</>, <#RED>Strikers</>.
					!happy
					!agree
					Aye, yes. I hammer them all.
					!neutral
					!point
					Your job's solicitin' the materials.
					!gruffnod
					I'll be handlin' the rest.
			]],

			QUESTION_3 = "Neato. Anything else I should know?",

			ANSWER_3 = [[
				agent:
					!neutral
					!think
					It ain't my primary trade, but I can set <#RED>{name_multiple.gem}</> if ye like.
					!point
					Imbue yer <#RED>Weapons</> with <#RED>Bonuses</> fer some extra <i>oompf</i>.
				]],

				QUESTION_5A = "Ooo, Weapon inlaying!",
				QUESTION_5B = "I'll keep an eye out for {name_multiple.gem}.",
				
				ANSWER_5A = [[
					agent:
						!neutral
						!agree
						Yes, but it's up ta you to find the <#RED>{name_multiple.gem}</>.
				]],
				ANSWER_5B = [[
					agent:
						!neutral
						!agree
						Grand.
				]],

			END_OPT = "Great! See you around, {name.npc_blacksmith}!",
			END_OPT_ALT = "Nice talking, {name.npc_blacksmith}! See you around.",
			END_OPT_ALT2 = "<z 0.9>Well, nice talking {name.npc_blacksmith}! Glad you're back.</z>",
			END_TALK = [[
				agent:
					!neutral
					!gruffnod
					Aye.
			]],
		},

		twn_gem_intro =
		{
			TITLE = "Shine On",
			gem_tips =
			{
				GEM_INTRO = [[
					agent:
						!dubious
						Hunter.
						!giveitem
						Take these.
						!gruffnod
						Ye'd be wise to learn how ta use them.
				]],

				OPT_GEM = "Woah, Weapon {name_multiple.gem}!",
			}
		},

		twn_weapon_weight_explainer = {
			TALK = [[
				agent:
					!neutral
					!dubious
					...Hunter.
			]],

			QUESTION_1 = "What's up, {name.npc_blacksmith}?",

			ANSWER_1 = [[
				agent:
					!neutral
					!gesture
					Do ye know about <#RED>Weapon Weight</>?
			]],

			QUESTION_2A = "I wouldn't mind some tips.",
			QUESTION_2B = "<z 0.9>Yeah. It affects Attack Speed and Damage.</>",

			ANSWER_2A = [[
				agent:
					!neutral
					!gruffnod
					Aye, then. Ahem. <#RED>Heavy Weapons</>?
					!point
					Hefty. They do more <#RED>Damage</>.
					!dubious
					<#RED>Light Weapons</>? Less <#RED>Damage</>.
					!point
					Fast though. Less risky ta commit ta an <#RED>Attack</>.
					!shrug
					<#RED>Normal Weapon</>? Eh. Balanced.
			]],

			ANSWER_2B = [[
				agent:
					!neutral
					!dubious
					...Aye.
					!gruffnod
					As ye were.
			]],

			END_OPT_A = "Is that all?",
			END_OPT_B = "Thanks for explaining.",

			END_TALK = [[
				agent:
					!happy
					!dubious
					...
					!neutral
					!gruffnod
					Aye.
			]],
		},		
	}
}
