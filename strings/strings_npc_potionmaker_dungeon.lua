return
{
	QUESTS =
	{
		first_meeting = {
			TALK = [[
				agent:
					!shocked
					Goodness <i>graciousss!</i> Is that a cussstomer I see?
					!greet
					Greetings and sssalutations, my fine <#BLUE>{player.species}</> friend! Welcome to the <#RED>{name.rotwood}</>!
					!point
					<i>Boy howdy</i>, have I ever got a business proposition for YOU!
			]],

			-- NO RESOURCES (MOST LIKELY PATH)
			QUESTION_NO_RESOURCES_1 = "Woah, hold on a sec. Who are--",
			ANSWER_NO_RESOURCES_1 = [[
				agent:
					!dubious
					--Now, you seem like a savvy <#BLUE>{player.species}</> who could use a bit of a pick-me-up. A refreshing <i>punch</i> of vim and vigour... a bit of, err...
					!shocked
					Now wait just a moment!
					!angry
					<i>I barely sssmell any <#KONJUR>{name.i_konjur}</> on you</i>.
			]],

			QUESTION_NO_RESOURCES_2A = "Oh, yeah. I'm a bit broke right now.",
			QUESTION_NO_RESOURCES_2B = "Yeah? So?",

			ANSWER_NO_RESOURCES_2 = [[
					!think
					My, what an awkward predicament we find ourselvesss in!
					!dejected
					I can't show you the wonder of my {name.npc_doc_lastname}-brand <#RED>Health {name.potion}s</> without appropriate compensssation!
					!shrug
					Sssuch is the fickle nature of the market, I suppose.
					!point
					Do come back for a <#RED>{name.potion}</> when you have <#KONJUR><p img='images/ui_ftf_icons/konjur.tex'> 75 {name.konjur}</>, won't you?
			]],

			QUESTION_NO_RESOURCES_3A = "Okay, sorry about that. See ya!",
			ANSWER_NO_RESOURCES_3A = [[
				agent:
					!greet
					Ta-ta!
			]],

			QUESTION_NO_RESOURCES_3B = "Well that was a waste of time.",
			ANSWER_NO_RESOURCES_3B = [[
				agent:
					!greet
					Agreed!
			]],

			-- HAS RESOURCES (RARE, AND THIS CHAT ONLY HAS ONE CHANCE TO EVER HAPPEN!)
			QUESTION_HAS_RESOURCES_1 = "Woah, hold on a sec. Who are--",
			ANSWER_HAS_RESOURCES_1 = [[
				agent:
					!dubious
					--Now, you seem like someone who could use a bit of a pick-me-up. A refreshing <i>punch</i> of vim and vigour! A bit of insurance, you might say, in an unsssure w--
			]],

			QUESTION_HAS_RESOURCES_2A = "--SORRY! To interrupt. Who <i>are</i> you?",
			QUESTION_HAS_RESOURCES_2B = "--Skip the pitch. Are those {name_multiple.potion}?",

			ANSWER_HAS_RESOURCES_2 = [[
				agent:
					!shocked
					Why, forgive my manners!
					!clap
					The name's <#BLUE>{name.npc_potionmaker_dungeon}</>, illussstrious post-apocalypse entrepreneur, ssscholar of medicine and beloved young heir to the {name.npc_doc_lastname} family fortune!
					!gesture
					At your mid-hunt convenience.
			]],
		},

		second_meeting = {
			TALK = [[
			agent:
				!shocked
				Ah, my friend! You've returned!
			]],

			QUESTION_HAS_RESOURCES_1 = "Yeah! And I have funds this time.",
			QUESTION_NO_SPACE_1 = "Err, yeah, but I have a {name.potion} already.",
			QUESTION_NO_RESOURCES_1 = "Err, yeah, but I'm still a bit low on {name.i_konjur}.",

			--REGULAR BRANCH--
			ANSWER_HAS_RESOURCES_1 = [[
				agent:
					!clap
					Sssplendid, sssplendid!
					!gesture
					Then without further ado, allow me to introduce you to my patented {name.npc_doc_lastname}-brand <#RED>Health {name.potion}</>!
					!agree
					One sip with <p bind='Controls.Digital.USE_POTION' color=BTNICON_DARK>'s guaranteed to <#RED>Heal</> your woundsss, clear your skin, and leave your breath minty fresh for that <i>ssspecial someone</i> back home.
					!shocked
					[recipe:admission_recipe] This veritable panacea <#RED>Health {name.potion}</> can be <i>yours</i> for only a modessst sum of <#KONJUR>{name.i_konjur}</>!
			]],

			QUESTION_HAS_RESOURCES_2A = "Why should I buy your {name_multiple.potion}? I don't even know you.",
			QUESTION_HAS_RESOURCES_2B = "I think I'll pass, thanks.",

				--2A branch--
					ANSWER_HAS_RESOURCES_2A = [[
						agent:
							!shocked
							Why, forgive my manners!
							!clap
							The name's <#BLUE>{name.npc_potionmaker_dungeon}</>, illussstrious post-apocalypse entrepreneur, ssscholar of medicine and beloved young heir to the {name.npc_doc_lastname} family fortune!
							!gesture
							[recipe:admission_recipe] At your mid-hunt convenience.
					]],

				--2C branch--
					ANSWER_HAS_RESOURCES_2B = [[
						agent:
							!angry
							Now hold on just a sssecond there!
							!dubious
							I'll let you in on a little secret. These woods are <i>danger</i>-ous. 
							!think
							I'd hate to see fine folks like yourself in a pinch... so what sssay you buy one of these <#RED>Potions</> for the road, hm?
					]],

					QUESTION_HAS_RESOURCES_3A = "Fine, you talked me into it.",
					QUESTION_HAS_RESOURCES_3B = "No, I'm really okay.",

					ANSWER_HAS_RESOURCES_3A = [[
						agent:
							!laugh
							Ha-ha! You had me on the ropes, but I knew from the start you were a smart <#BLUE>{player.species}</>!
							!agree
							Enjoy your {name.npc_doc_lastname}-brand <#RED>Health {name.potion}</>, and may we deal again soon!
					]],
					ANSWER_HAS_RESOURCES_3B = [[
						agent:
							!point
							A tough customer. I <i>do</i> love a challenge.
							!greet
							Well, fair play, my friend. I'll get you next time!
					]],
				--2C branch end--
			--END REGULAR BRANCH--

			--POTION FULL BRANCH--
			ANSWER_NO_SPACE_1 = [[
				agent:
				!dubious
				--Now, as I was sssaying last time, you seem like a savvy <#BLUE>{player.species}</> who could--
				!shocked
				WAIT! You already have a <#RED>{name.potion}</>?
				!disagree
				Bouncing <#RED>{name_multiple.cabbageroll}</> on a pogo stick, this just won't do!
				!dejected
				I can't sell you my <#RED>{name_multiple.potion}</> if you have nothing to carry them in.
			]],
				--mid branch--
				QUESTION_NO_SPACE_2_FULL_HEALTH = "Err, sorry. Catch ya next time?\n<i><#RED><z 0.7>(Potion already full)</></i></z>",

				ANSWER_NO_SPACE_2_FULL_HEALTH = [[
					agent:
						!greet
						I'm counting on it!
				]],
				--end mid branch--

				--mid branch--
				ANSWER_NO_SPACE_1_MISSING_HEALTH = [[
					!dubious
					Tell you what, why don't you take a moment to empty that flask of yours out with <p bind='Controls.Digital.USE_POTION' color=BTNICON_DARK>?
					!clap
					Then I can top you up with some bonafide {name.npc_doc_lastname}-brand <#RED>Health Potion</> instead!
				]],

				QUESTION_NO_SPACE_2A = "Wowee! Thanks!\n<i><#RED><z 0.7>(Potion already full)</></i></z>",
				QUESTION_NO_SPACE_2B = "Lemme think it over.\n<i><#RED><z 0.7>(Potion already full)</></i></z>",

				ANSWER_NO_SPACE_2A = "Most certainly!",
				ANSWER_NO_SPACE_2B = "Don't think <i>too</i> long now!",
				--end mid branch--
			--END POTION FULL BRANCH--

			--NO FUNDS BRANCH--
			ANSWER_NO_RESOURCES_1 = [[
				agent:
					!dubious
					<i>--Now,</i> as I was sssaying last time, you seem like one savvy <#BLUE>{player.species}</> who could--
					!shocked
					<i>Hold your horses!</i> Did you just say you're ssstill broke? 
					!angry
					How'sss that even possible?
					!dubious
					Err, I mean, no hard feelings. Why don't you go give some monsters the what-for, then come back in a flash with some cold hard cash!
					!agree
					My gen-u-ine <#RED>{name_multiple.potion}</> will be waiting!
			]],

			QUESTION_NO_RESOURCES_2A = "Okay! I'll go bash some {name_multiple.rot}!",
			QUESTION_NO_RESOURCES_2B = "Eh, we'll see how I do.",

			ANSWER_NO_RESOURCES_2 = [[
				agent:
					!greet
					Ta-ta!
					!angry
					<z 0.7>(Good grief.)</z>
			]],
			--END NO FUNDS BRANCH--
		},

		third_meeting = {
			TALK = [[
				agent:
					!dubious
					(sniff sniff)...
					!dejected
					Kid. We gotta stop meeting like this.
			]],
		},

		dgn_shop_potion =
		{
			OPT_CONFIRM = "<#RED>[<p img='images/ui_ftf_icons/konjur.tex'> 75 {name.konjur}]</> Take my {name.konjur}! <i><#RED><z 0.7>(Refill Potion)</></i></z>",
			TT_CANT_AFFORD = "Not enough <p img='images/ui_ftf_icons/konjur.tex'>",
			TT_FULL_POTION = "Full potion",
			TT_ALREADY_REFILLED = "Already refilled",
			TALK_DONE_GAME = [[
				agent:
					!greet
					Pleasssure doing business with you.
			]],
		}
	}
}
