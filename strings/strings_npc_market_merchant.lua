return
{
	QUESTS = {

		first_meeting = {
			TALK = [[
				agent:
					!happy
					!dubious
					Welllll now, what hath we here?
					!neutral
					!eyeroll
					<#BLUE>{name.shop_magpie}</>, wake up!
					!happy
					!dubious
					Our new <#RED>Armour</> patron hath <i>deigned</i> to arrive.
			]],
			--[[nimble:
					Squawk!]]

			QUESTION_1A = "<z 0.97>Oh, hi! Nice to see a friendly face out here.</z>",
			QUESTION_1B = "Uhh, did you know I was coming? How?",
			

			ANSWER_1A = [[
				agent:
					!happy
					!eyeroll
					Yes, yes, everyone likes my face.
			]],
			ANSWER_1B = [[
				agent:
					!happy
					!eyeroll
					You could say a little birdie told me.
			]],
			--Bwe-heu-heu.

			TALK2 = [[
				agent:
					!neutral
					!wink
					The name's <#BLUE>{name.shop_armorsmith}</>.
					!happy
					!point
					My feathered friend over yonder is <#BLUE>{name.shop_magpie}</>.
					!neutral
					!agree
					Now that you've arrived, I'm quite pleased to inform you:
					!happy
					!gesture
					<i>You may purchase my <#RED>Armour</></i>.
					!closedeyes
					You're welcome.
			]],

			-->open loop menu
			QUESTION_2A = "What makes you think I'm in the market?",
			QUESTION_2A_ALT = "<z 0.9>Why do you think I'm in the market for gear?</z>",
			ANSWER_2A = [[
				agent:
					!happy
					!dubious
					Um... I hath eyes.
			]],
			
			QUESTION_2B = "<z 0.93>But the {name_multiple.foxtails} already have an {name.job_armorsmith}.</z>",
			ANSWER_2B = [[
				agent:
					!neutral
					!dubious
					And?
			]],

			QUESTION_2C = "What sort of armour do you sell?",
			ANSWER_2C = [[
				agent:
					!neutral
					!gesture
					I offer artisanal, hand-forged pieces of <#RED>Weapons</> and <#RED>Armour</>, both.
					!closedeyes
					My materials are locally sourced, semi-ethically, from the region's native monsters.
					!agree
					So expect my stock to change should we ever meet in another land.
			]],

			QUESTION_2D = "What's the bird sell?",
			ANSWER_2D = [[
				agent:
					!happy
					!dubious
					<#BLUE>{name.shop_magpie}</>? Ohh, odds and ends.
					!neutral
					!eyeroll
					<#RED>Potions</>, <#RED>{name_multiple.concept_relic}</>, anything she finds lying about, verily.
					!happy
					!think
					She's quite proud of her collection.
					!neutral
			]],
			
			OPT_END = "I'll look around.",
			OPT_END_ALT = "Okay, thanks. I'll take a look around.",
			TALK_END = [[
				agent:
					!wink
					Enjoyyy, culver.
					!happy
			]],
		},
			
		dgn_hub = {
			--chat when you meet alphonse in a different biome for the first time, where hell have different stock
			new_biome_meeting = {
				TALK = [[
					agent:
						!neutral
						!smirk
						Welcome back, culver.
				]],

				QUESTION_1 = "Hey! Your stock's totally different!",

				ANSWER_1 = [[
					agent:
						!neutral
						!dubious
						Um, yes.
						!gesture
						I maketh my pieces from locally sourced <#RED>{name.rot}</> materials.
						!happy
						!point
						Different locale? Different pieces.
				]],

				QUESTION_2 = "But I wanted something you had at the other location.",

				ANSWER_2 = [[
					agent:
						!neutral
						!shrug
						Then I guess you'll have to come find me again over there.
				]],

				QUESTION_3 = "Can't you look in the back to see if you have it?",

				ANSWER_3 = [[
					agent:
						!point
						No.
				]],

				QUESTION_4 = "Pleeeeease?",
				ANSWER_4 = [[
					agent:
						!angry
						<i>No!</i>
				]],

				QUESTION_5 = "C'moonnn...",
				ANSWER_5 = [[
					agent:
						!neutral
						!eyeroll
						Fine.
						!happy
						!closedeyes
						Hmmm... Yep, I art <i>definitely</i> looking. This is me, "looking in the back". I art looking in the back, and...
						!neutral
						!point
						Nope, we don't have it. Begone now.
				]],

				QUESTION_EARLY_END = "Okay. Good to know.", --available after alongside question 2 and 3
				ANSWER_EARLY_END = [[
					agent:
						!happy
						!wink
						Make sure to tell your Hunter friends about me once thou returnst home.
				]],

				QUESTION_LATE_END = "Fine.", --available alongside question 4 and 5
				ANSWER_LATE_END = [[
					agent:
						!neutral
						!dubious
						Glad that is settled.
						!wink
						Thou art free to continue browsing now, little culver.
				]],

				QUESTION_ANNOYING_END = "See? That wasn't so hard.", --used as the only followup option after clicking question 5
				ANSWER_ANNOYING_END = [[
					agent:
						!neutral
						!dejected
						<z 0.7>I hate interacting with the clientele.</z>
				]],
			},

			--let the player know they can only buy whatever alphonse has available
			no_custom_orders = {
				TALK = [[
					agent:
						!neutral
						!dubious
						Something on your mind, culver?
				]],
				QUESTION_1 = "Hey, can I put in orders for specific items?",
				ANSWER_1 = [[
					agent:
						!neutral
						!shocked
						Ugh! I don't take <i>commissions</i>.
						!angry
						I am an independent artist.
						!gesture
						You hath the <i>opportunity</i> to purchase my original work.
						!happy
						!closedeyes
						But lucky for you I'm quite magnamious, so I won't let this ruin our professional relationship.
				]],
			},

			--how shipping objects back to camp works
			explain_shipping1 = {
				TALK = [[
					agent:
						!neutral
						!gesture
						Welcome back, little culver.
				]],
				QUESTION_1 = "I saw something I liked. Do I have to wear it right now if I buy it?",
				ANSWER_1 = [[
					agent:
						!happy
						!think
						How funny you should ask.
						!wink
						My associate <#BLUE>{name.shop_magpie}</> doth provide a delivery service, free of charge.
						!neutral
						!gesture
						Just choose <#RED>Ship</> when you purchase your piece, and we'll ensure it's waiting on your <#RED>Armour Rack</> by the time you returnst home.
				]],
			},
			explain_shipping2 = {
				TALK = [[
					agent:
						!happy
						!dubious
						Back again, culver?
				]],
				QUESTION_1 = "Can you remind me how shipping works?",
				ANSWER_1 = [[
					agent:
						!eyeroll
						...It's <i>simple</>.
						!point
						Just choose <#RED>Ship</> when you buy a piece.
						!dubious
						<#BLUE>{name.shop_magpie}'ll</> ensure it's waiting on your <#RED>Armour Rack</> once you returnst home.
				]],
			},

			--ask nimbles origin
			what_is_nimble = {
				TALK = [[
					agent:
						!neutral
						!gesture
						Welcome back, culver.
				]],
				QUESTION_1 = "So... what <i>is</i> {name.shop_magpie} exactly?",
				ANSWER_1 = [[
					agent:
						!happy
						!dejected
						Woe, but it's a tragic tale!
						!neutral
						!gesture
						She used to be a beautiful <#BLUE>{name.species_mer}</> maiden, 'til one day she was cursed by the prick of a poison <#KONJUR>{name.konjur}</> thorn.
				]],

				QUESTION_2A = "I knew it!",
				QUESTION_2B = "{name.konjur} can do that to people?", --uses the same answer as 2A
				QUESTION_2C = "Pfft, no way.",

				ANSWER_2A = [[
					agent:
						!happy
						!laugh
						<i>Bwe-heu-heu</i>! You're so gullible!
				]],

				ANSWER_2C = [[
					agent:
						!happy
						!shrug
						Bwe-heu-heu, yeah, I cut that tale of whole cloth.
				]],

				TALK2 = [[
					agent:
						!neutral
						!dubious
						<#BLUE>{name.shop_magpie}</> was just normal wild magpie. But <#KONJUR>{name.konjur}</> <i>did</i> turn her into whatever she is now.
				]],

				QUESTION_3 = "Why didn't she become a {name.rot}?",
				ANSWER_3 = [[
					agent:
						!think
						I hath no clue.
						!happy
						!shrug
						But I'm thankful nonetheless. She is the most stalwart of squires an <#BLUE>{name.species_ogre}</> could ask for.
				]],

				QUESTION_EARLY_EXIT = "Sorry, I've actually gotta run.",
				QUESTION_REGULAR_EXIT = "Well. Good for you guys.",
				ANSWER_EXIT = [[
					agent:
						!happy
						!shrug
						All's well that ends well.
						!wink
						'Til next time, little culver.
				]],
			},

			--ask if alphonse ever encounters rots
			encounter_rots = {
				TALK = [[
					agent:
						!neutral
						!gesture
						Welcome back, little culver.
				]],

				QUESTION_1 = "So... do you ever run into {name_multiple.rot} out here?",
				ANSWER_1 = [[
					agent:
						!happy
						!shrug
						Verily.
				]],

				QUESTION_2 = "How're you and {name.shop_magpie} not mincemeat?",
				ANSWER_2 = [[
					agent:
						!point
						She can throw her voice, and do some <i>very</i> good vocal impressions.
						!eyeroll
						<#RED>{name_multiple.rot}</> art so easy to fool. Bwe-heu-heu.
				]],
			},

			corestones = {
				TALK = [[
					agent:
						!neutral
						!gesture
						Welcome back, little culver.
				]],

				QUESTION_1 = "What d'you do with all the {name_multiple.i_konjur_soul_lesser} I give you anyway?",

				QUESTION_1 = [[
					agent:
						!happy
						!gesture
						I use them to fuel mine forge and maketh more pieces.
						!closedeyes
						My craft is my life, you see.
				]],
			},

			OPT_END = "Okay. Back to browsing.",
			OPT_END_RESPONSE = [[
				agent:
					!smirk
					Enjoy, culver.
			]],
		},
		seen_missing_friends = 
		{
			
		},
	},
}

