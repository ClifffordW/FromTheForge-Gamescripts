return
{
	QUESTS =
	{	
		game_start =
		{
			TALK_INTRO = [[
				agent:
					!neutral
					!greet
					Hunter! Thank goodness, you're on your feet.
			]],
	
			OPT_1 = "<i>Oof</i>, what hit us?",
	
			TALK_INTRO2 = [[
				agent:
					!neutral
					!shocked
					That was a real life <#RED>{name.rot_boss}</> that smacked us down-- a <#RED>{name.megatreemon}</>, to be exact!
					!nervous
					Ohh, Hunter! What a terrible start to our expedition!
					!dejected
					Now half our crew are lost in the forest, and it's all my fault!
			]],
	
			--BRANCH START--
			OPT_2D = "What's a \"{name.rot}\"?",
			OPT_2A = "Just don't send <i>me</i> after them.",
			OPT_2B = "How'd you not see a {name.rot} that big anyway?",
			OPT_2C = "It's gonna be okay, {name.npc_scout}. Who's missing?",

			--not implemented kris
			OPT2D_RESPONSE = [[
				agent:
					!neutral
					!shocked
					<i>Uhh,</i> the giant monsters you're here to fight??
					!nervous
					Did you smack your head?
					!greet
					How many paws am I holding up?
			]],

			--BRANCH 1--
			OPT2A_RESPONSE = [[
				agent:
					!neutral
					!point
					Hey, don't back out on me now! I need you if we're gonna rescue <#RED>{name.npc_blacksmith}</> the {name.job_blacksmith} and <#RED>{name.npc_armorsmith}</> the {name.job_armorsmith}!
					!think
					Let's focus up, okay? We can fix this.
					!point
					You spearhead the search. I'll handle the rescue.
					!agree
					Finding <#RED>{name.npc_armorsmith}</> and <#RED>{name.npc_blacksmith}</> is our top priority. There are hostile <#RED>{name_multiple.rot}</> about, and those two aren't fighters.
			]],
			--1--

			--BRANCH 2--
			OPT2B_RESPONSE = [[
				agent:
					!neutral
					!shocked
					I-It was a <#RED>{name.treemon}</>! In a forest full of trees!
					!nervous
					Being a scout doesn't make me omniscient, you know...
					!angry
					But we can't dwell on it!
					!point
					Our top priority is rescuing our {name.job_armorsmith}, <#RED>{name.npc_armorsmith}</>, and <#RED>{name.npc_blacksmith}</> the {name.job_blacksmith}. There are dangerous <#RED>{name_multiple.rot}</> in these woods, and those two aren't fighters like you are.
			]],
			--3--

			--BRANCH 3--
			OPT2C_RESPONSE = [[
				agent:
					!neutral
					!nervous
					...<#RED>{name.npc_armorsmith}</> the {name.job_armorsmith}, and <#RED>{name.npc_blacksmith}</> the {name.job_blacksmith}.
					!think
					<#BLUE>{name.npc_dojo_master}'s</> out there too, but I trust him to hold his own.
					!shocked
					The other two wouldn't stand a chance against the <#RED>{name_multiple.rot}</> in these woods!
					!point
					I need you to comb the forest and search for them. Just make it as far in as you can.
			]],
			--3--

			--plays after branches 1 and 2
			TALK_INTRO3 = 
			[[
				agent:
					!neutral
					!shrug
					<#BLUE>{name.npc_dojo_master}'s</> out there too, but he can hold his own.
					!point
					Let's comb the woods as far as we can. And if you see that nasty <#RED>{name.megatreemon}</>, pop her one for me won't you?
			]],
			--BRANCH END--

			OPT_3A = "What are you gonna do?",
			OPT_3B = "But I've never been in a real fight before!\n<i><#RED><z 0.7>(Explain controls)</></i></z>",
			OPT_3C = "Welp, no sense wasting time.\n<i><#RED><z 0.7>(Skip controls explainer)</></i></z>",

			OPT3A_RESPONSE = [[
				agent:
					!neutral
					!think
					The <#RED>{name.damselfly}</> is still operational, so I'm headed back up.
					!agree
					I'll watch from the air to make sure you stay safe, and scoop up anyone you find along the way.
			]],

			--BRANCH 4--
			OPT3B_RESPONSE = [[
				agent:
					!neutral
					!think
					Oh, um. I know the basics of fighting, I could give you refresher if you'd like?
			]],

			OPT_4A = "Yes, please!",
			OPT_4B = "Actually, I've had a burst of bravery.",

			OPT4A_RESPONSE = [[
					agent:
						!neutral
						!agree
						Sure, if it'll help.
						!think
						Okay, so to start-- you can perform <#RED>Light Attacks</> with <p bind='Controls.Digital.ATTACK_LIGHT' color=BTNICON_DARK>, and <#RED>Heavy Attacks</> with <p bind='Controls.Digital.ATTACK_HEAVY' color=BTNICON_DARK>.
						!point
						You start a Hunt with a basic <#RED>Skill</> (<p bind='Controls.Digital.SKILL' color=BTNICON_DARK>), but if you find a cooler one along the way you can swap it.
						!gesture
						<p bind='Controls.Digital.DODGE' color=BTNICON_DARK> lets you <#RED>Dodge</>.
						!point
						Always keep your eyes peeled for when a <#RED>{name.rot}'s</> about to <#RED>Attack</>, so you can <#RED>Dodge</> (<p bind='Controls.Digital.DODGE' color=BTNICON_DARK>) out the way.
						!gesture
						I know that sounds obvious, but it's crucial to survival.
						!agree
						A good Hunter always prioritizes <#RED>Dodging Attacks</> over <#RED>Attacking</>.
			]],

			OPT_5 = "Thanks. I'm feeling a bit better now.",

			OPT5_RESPONSE = [[
				agent:
					!happy
					!agree
					Glad to hear it.
					!shocked
					Oh! And if your <#RED>Health</> gets low, you have a <#RED>Potion</> you can drink with <p bind='Controls.Digital.USE_POTION' color=BTNICON_DARK>. 
					!neutral
					!gesture
					You only have one, though, so use it wisely.
					!shocked
					Now let's get out there and save some people!
			]],

			--opt 4B ends the conversation, doesnt go on to opt 5
			OPT4B_RESPONSE = [[
				agent:
					!happy
					!gesture
					Don't worry Hunter, I'll be right behind you the whole way.
					!neutral
					!point
					Now let's go.
			]],				
			--4--

			OPT3C_RESPONSE = [[
				agent:
					!neutral
					!shocked
					Hold on everyone, we're coming!
			]],
		},

		first_death = {
			TALK = [[
				agent:
					!happy
					!nervous
					Whew! I grabbed you in the nick of time.
			]],

			QUESTION_1 = "Did... did I die?",

			ANSWER_1 = [[
				agent:
					!neutral
					!angry
					Of course not! I'm better at rescues than that.
					!shrug
					...You did get a teensy bit knocked out though.
			]],

			QUESTION_2 = "How did I end up in camp?",

			ANSWER_2 = [[
				agent:
					!happy
					!point
					I snagged you with the {name.damselfly}'s rope claw.
					!neutral
					!gesture
					I always follow you from the air during Hunts so I can pull you out if things get dicey.
					!happy
					!point
					It'll never be "safe" out there, but I can at least make sure it's not deadly.
			]],

			QUESTION_3A = "I'm glad to know you have my back.",
			QUESTION_3B = "Could you grab me earlier next time? Maybe before I get knocked out?",

			ANSWER_3A = [[
				agent:
					!happy
					!agree
					That's my job.
			]],

			ANSWER_3B = [[
				agent:
					!neutral
					!shrug
					Hey, pobody's nerfect.
			]],
		},

		dgn_weapons_explainers = {
			POLEARM_FULL_CONVO = {
				
				TALK = [[
					agent:
						!happy
						!clap
						Ah, you're using the <#RED>{name.weapon_polearm}</>! I'm so glad.
						!neutral
						!dubious
						Did <#BLUE>{name.npc_dojo_master}</> explain how to use it?
				]],

				QUESTION_1A = "I wouldn't mind some tips.",
				QUESTION_1B = "Yep! No need to explain.",

				ANSWER_1A = [[
					agent:
						!agree
						Try to jab <#RED>Enemies</> with the tip of the <#RED>{name.weapon_polearm}</> if you want to perform a <#BLUE>{name.concept_focus_hit}</>.
						!dubious
						Hitting them when they're too close just won't do.
						!point
						Oh, and you can also hit multiple <#RED>Targets</> at once with your <#RED>Rolling Drill</>!
				]],

				QUESTION_2 = "How do I Rolling Drill?",
				QUESTION_END = "Thanks, {name.npc_scout}!",

				ANSWER_2 =
				[[
					agent:
						!point
						The <#RED>Rolling Drill</> is <#RED>Dodge</> (<p bind='Controls.Digital.DODGE' color=BTNICON_DARK>), then <#RED>Light Attack</> (<p bind='Controls.Digital.ATTACK_LIGHT' color=BTNICON_DARK>).
				]],

				END_RESPONSE = [[
					agent:
						!happy
						!agree
						Good Hunting!
				]],
			},
		},

		--this conversation happens the first time the player does a frenzied hunt, and can take place in any biome
		first_frenzy_hunt = {
			TALK = [[
				agent:
					!neutral
					!wave
					Heya! Ready for your first <#RED>Frenzied Hunt</>?
			]],

			QUESTION_1A = "No! I'm terrified!",
			QUESTION_1B = "Uh, I think I'm ready. Why do you ask?",
			QUESTION_1C = "I'm ready! Lemme at them!", --> exit convo button

			---
			ANSWER_1A = [[
				agent:
					!shocked
					There's no need to be scared! You're a certified <#RED>{name.rot_boss}-killer</>!
					!gesture
					I just wanted to make sure you knew ahead of time that the <#RED>{name_multiple.rot}</> up ahead have... changed.
			]],

			ANSWER_1B = [[
				agent:
					!gesture
					Well, the <#RED>{name_multiple.rot}</> aren't <i>just</i> more powerful in a <#RED>Frenzy Hunt</>.
					!point
					Some of them have soaked up enough <#KONJUR>{name.konjur}</> that they've... changed.
			]],

			QUESTION_2 = "Changed how?", --both 1A and 1B funnel here

			ANSWER_2 = [[
				agent:
					!gesture
					They've developed new moves and abilities, so stay on your toes.
					!point
					Don't assume you know all their tricks just because you've fought a weaker version before.
					!agree
					On the brightside the new <#RED>{name_multiple.rot}</> look quite different, so you won't be caught off guard.
			]],

			ANSWER_1C = [[
				agent:
					!happy
					!laugh
					Alright, best of luck!
			]],

			--becomes available after clicking any of the 1 questions
			END_OPT = "Thanks for the heads up.",

			END_TALK_SINGLEPLAYER = [[
				agent:
					!agree
					Any time.
			]],

			END_TALK_MULTIPLAYER = [[
				agent:
					!shocked
					Oh, one last thing!
					!point
					Since you're hunting together, keep in mind that <#RED>Revives</> cost a small amount of <#RED>Health</> in <#RED>Frenzy Level 2</> and above.
					!wave
					So watch each others' backs out there!
			]],

		},

		megatreemon_forest = {
			--died to yammo
			MT_die_to_miniboss_convo =
			{
				TALK = [[
					agent:
						!happy
						!clap
						You did great out there!
				]],

				QUESTION_1 = "I just got my butt kicked.",
				ANSWER_1 = [[
					agent:
						!neutral
						!point
						Uh yeah, you got your butt kicked <i>by a <#RED>{name.yammo_miniboss}</>!</i>
						!think
						Bigger <#RED>{name_multiple.rot}</> tend to hang out around <#RED>{name_multiple.rot_boss}</>, y'know.
						!happy
						!point
						If you faced off against a <#RED>{name.yammo_miniboss}</>, that must mean you're getting closer to the <#RED>{name.megatreemon}</>!
				]],

				QUESTION_2 = "That's... reassuring?",

				ANSWER_2 = [[
					agent:
						!clap
						I'm sure <#RED>{name.megatreemon}'s</> just around the corner.
				]],
			},

			--died at megatreemon
			MT_died_to_boss_convo =
			{
				TALK = [[
					agent:
						!happy
						!greet
						I can't believe you've made it so deep into the forest so fast.
						!shocked
						Imagine that! A rookie {name.foxtails} Hunter, taking on a <#RED>{name.rot_boss}</> head to head!
						!point
						That <#RED>{name.megatreemon}</> is lumber waiting to happen.
				]],

				QUESTION_1 = "Ugh. <#RED>{name.megatreemon}</> whupped my behind.",

				ANSWER_1 = [[
					agent:
						!neutral
						!agree
						Failure is an unavoidable part of the process.
						!gesture
						We're up against some pretty major forces and are learning as we go.
						!happy
						!point
						If it was easy, someone would have already done it, y'know?
				]],

				QUESTION_2A = "You're right. I'm learning.",
				QUESTION_2B = "I just wish it didn't hurt so bad.",
				QUESTION_2C = "I <i>GUESS</i>.",

				ANSWER_2A = [[
					agent:
						!happy
						!angry
						That's right!
						!point
						Keeping going the way you are and that <#RED>{name.megatreemon}</> is lumber waiting to happen.
				]],
				ANSWER_2B = [[
					agent:
						!happy
						!nervous
						Yeahhh, she packs a wallop, huh?
						!point
						But it'll be that much more satisfying when you finally wallop her back!
				]],
				ANSWER_2C = [[
					agent:
						!happy
						!laugh
						Haha.
						!gesture
						I know you're feeling frustrated, but it's quite incredible to see a rookie Hunter taking on a <#RED>{name.rot_boss}</> head to head.
				]],
			},

			--killed an elite yammo
			MT_celebrate_defeat_miniboss =
			{
				TALK = [[
					agent:
						!happy
						!clap
						That <#RED>{name.yammo}</> didn't stand a chance!
				]],

				QUESTION_1 = "I can't believe I downed a {name.yammo_elite}.",

				ANSWER_1 = [[
					agent:
						!happy
						!agree
						You've really found your footing since we got here.
				]],

				QUESTION_2A = "A lot of that is owing to you.",
				QUESTION_2B = "Thanks. I'm feeling pretty confident.",

				ANSWER_2A = [[
					agent:
						!happy
						!agree
						We make a good team, huh?
						!gesture
						Anyway. Congrats on your win, Hunter.
				]],

				ANSWER_2B = [[
					agent:
						!happy
						!gesture
						You should, you're an asset to the {name_multiple.foxtails}.
						!gesture
						Anyway. Congrats on your win, Hunter.
				]],
			},

			--struggling on elite yammo
			MT_multiple_die_to_miniboss_convo = 
			{
				TALK = [[
					agent:
						!neutral
						!angry
						Yeesh, that <#RED>{name.rot_miniboss}'</> a real jerk!
				]],

				QUESTION_1 = "You, uh, got any {name.yammo_elite} tips?",

				ANSWER_1 = [[
					agent:
						!neutral
						!think
						Hmm, well... <#RED>{name.yammo_elite}</> hits pretty hard, but it's also slow winding up.
						!point
						If you keep an eye out for that wind up, it'll be easier to <#RED>Dodge</> (<p bind='Controls.Digital.DODGE' color=BTNICON_DARK>) when it finally swings.
						!gesture
						<#RED>Dodging</> is better than running away, because you'll stay in range to land a few <#RED>Attacks</> before the <#RED>{name.yammo}</> comes at you again.
						!happy
						!point
						Plus you'll be <#RED>Invincible</> for a split second during the <#RED>Dodge</> (<p bind='Controls.Digital.DODGE' color=BTNICON_DARK>), so even if you're up close and personal, you won't take any <#RED>Damage</>.
						!shrug
						As long as you time your roll right, anyway.
				]],

				QUESTION_2A = "Makes sense! Time to go whup some butt!",
				QUESTION_2B = "...That's all you've got for me?",

				ANSWER_2A = [[
					agent:
						!happy
						!clap
						Haha. I believe in you!
				]],

				ANSWER_2B = [[
					agent:
						!neutral
						!shrug
						Yep.
				]],
			},

			MT_celebrate_defeat_boss =
			{
				MT_defeated_first_run = {
					TALK = [[
						agent:
							!shocked
							Holy moly, that was incredible to watch!
							!point
							I can't believe you downed a <#RED>{name.megatreemon}</> on your very first {name.run}!
					]],

					QUESTION_1A = "Thanks! I'm feeling good about it.",
					QUESTION_1B = "I was screaming inside the entire time!",
					QUESTION_1C = "It was literally so easy.",

					ANSWER_1A = [[
						agent:
							!bliss
							As you should!
					]],

					ANSWER_1B = [[
						agent:
							!shocked
							I would never have guessed!
					]],

					ANSWER_1C = [[
						agent:
							!shocked
							You're so confident!
					]],

					TALK2 =[[
						agent:
							!thinking
							I think you might become a Hunter to rival <#BLUE>{name.npc_dojo_master}</> in his heyday.
							!clap
							Oh! Speaking of which, <#BLUE>{name.npc_dojo_master}</> made it back to camp while we were out!
							!gesture
							You should go introduce yourself if you haven't had a chance yet.
					]],

					QUESTION_2A = "We still haven't found {name.npc_armorsmith} or {name.npc_blacksmith}.",
					QUESTION_2B = "D'you think our {name.job_armorsmith} and {name.job_blacksmith} are goners yet?",

					ANSWER_2A = [[
						agent:
							!nervous
							Yes, I know. I'm very worried.
					]],

					ANSWER_2B = [[
						agent:
							!shocked
							Hunter!
							!angry
							Don't speak like that.
					]],

					TALK3 = [[
						agent:
							!gesture
							While you were hunting I spotted a section of the forest where the treeline had been disturbed, though.
							!agree
							It's possible one of our people landed there.
							!dubious
							I think we should keep searching the <#RED>{name.treemon_forest}</>, too.
							!gesture
							Both locations available on your map. I'll leave it up to you where we go next.
					]],

					QUESTION_3 = "Do you know anything about this rock the {name.megatreemon} dropped?",

					ANSWER_3 = [[
						agent:
							!shocked
							Woah! In all the commotion I totally forgot!
							!point
							That right there is a <#KONJUR>{name.i_konjur_heart}</>, my friend.
							!agree
							It's <i>very</i> important.
					]],

					QUESTION_4A = "Can I eat it?",
					QUESTION_4A = "What's it do?",

					ANSWER_4A = [[
						agent:
							!angry
							No!
							!think
							Well, sort of.
							!angry
							But no!
							!shrug
							I'll just show you.
					]],

					ANSWER_4B = [[
						agent:
							!agree
							That's precisely what I want to show you.
					]],

					TALK4 = [[
						agent:
							!gesture
							I'd prefer not to touch it. Do me a favour, won't you?
							!point
							Place <#RED>{name.megatreemon}'s</> <#KONJUR>{name.i_konjur_heart}</> in the <#RED>{name.town_grid_cryst}</>.
					]],

					QUESTION_5A = "{name.town_grid_cryst}? What's that?",
					OPT_5B = "Sure thing, {name.npc_scout}.",
					OPT_5B_ALT = "Ohhh, the {name.town_grid_cryst}. Sure thing, {name.npc_scout}.",

					ANSWER_5A = [[
						agent:
							!think
							Oh, sorry.
							!point
							The <#KONJUR>{name.town_grid_cryst}</> is that big clunky machine here in town.
							!shrug
							Y'know, near where I dropped you off.
					]],
				},

				MT_defeated_regular = {
					TALK = [[
						agent:
							!neutral
							!shocked
							Holy moly, you really did it!
							!happy
							!point
							You took down the <#RED>{name.megatreemon}</> that attacked us!
							!think
							Ah, but--
							!dubious
							You didn't happen to find a <#KONJUR>purple</> glowy rock when you felled her, did you?
					]],
					
					QUESTION_1A = "Why, is it edible?",
					QUESTION_1B = "Why, is it valuable?",
					QUESTION_1C = "You mean this? <i><#RED><z 0.7>(Show {name.npc_scout} the {name.konjur_heart})</z></></i>", --progresses conversation
					QUESTION_1C_ALT = "Oh, this thing! <i><#RED><z 0.7>(Show {name.npc_scout} the {name.konjur_heart})</z></></i>", --progresses conversation

					ANSWER_1A = [[
						agent:
							!neutral
							!angry
							No! It's much too important to eat.
							!think
							Although I guess you do kind of consume it in a way?
					]],

					ANSWER_1B = [[
						agent:
							!neutral
							!gesture
							Not monetarily, but they're <i>extremely</i> important to our expedition.
					]],

					ANSWER_1C = [[
						agent:
							!happy
							!clap
							Yes!
							!neutral
							!gesture
							Hunter... Have you noticed how powerful <#RED>{name_multiple.rot}</> tend to drop a bit more <#KONJUR>{name.i_konjur}</> than weaker ones?
							!point
							Well, <#RED>{name_multiple.rot_boss}</> have an absurd amount of <#KONJUR>{name.i_konjur}</> in their system.
							!gesture
							So much, in fact, that it crystallizes into what we call a <#KONJUR>{name.i_konjur_heart}</>.
							!shocked
							What you're holding there is <#RED>{name.megatreemon}'s</> <#KONJUR>{name.i_konjur_heart}</>!
							!gesture
							Can you do me a favour? I want to show you something, but I'd rather not touch the crystal if I can avoid it.
							!happy
							!point
							Go place <#RED>{name.megatreemon}'s</> <#KONJUR>{name.i_konjur_heart}</> in the <#KONJUR>{name.town_grid_cryst}</>.
					]],

					QUESTION_2A = "{name.town_grid_cryst}? What's that?",
					QUESTION_2B = "Sure thing, {name.npc_scout}.",
					QUESTION_2B_ALT = "Ohhh, the {name.town_grid_cryst}. Sure thing, {name.npc_scout}.",

					ANSWER_2A = [[
						agent:
							!neutral
							!think
							Oh, sorry.
							!happy
							!point
							The <#KONJUR>{name.town_grid_cryst}</> is that big clunky machine here in town.
							!shrug
							Y'know, near where I dropped you off.
					]],

					END = "Thanks.",
				},

				MT_talk_after_konjur_heart =
				{
					TALK = [[
						agent:
							!gesture
							Don't forget to put that <#KONJUR>{name.i_konjur_heart}</> in the <#KONJUR>{name.town_grid_cryst}</>!
							!point
							It's right where I always drop you off.
					]],

					QUESTION_1 = "I put the Heart in.",

					ANSWER_1 = [[
						agent:
							!happy
							!clap
							Now that's a thing of beauty!
					]],

					QUESTION_2A = "I feel kinda tingly.",
					QUESTION_2B = "What did we just do?",

					ANSWER_2A = [[
						agent:
							!happy
							!think
							Haha, I always wondered what it'd feel like.
					]],

					ANSWER_2B = [[
						agent:
							!neutral
							!point
							When you put a <#KONJUR>{name.i_konjur_heart}</> in the <#KONJUR>{name.town_grid_cryst}</> it works kinda like a prism, amplifying one aspect of your Hunter abilities.
							!happy
							!gesture
							It looks like <#RED>{name.megatreemon}'s</> <#KONJUR>{name.i_konjur_heart}</> gave you some extra <#RED>Health</>. Can't complain about that!
					]],

					QUESTION_3A = "Will all <#KONJUR>{name_multiple.konjur_heart}</> give me Health?",
					QUESTION_3B = "How long does the effect last?",
					QUESTION_3C = "Where can I get more <#KONJUR>{name_multiple.konjur_heart}</>?",

					ANSWER_3A = [[
						agent:
							!happy
							!think
							Well, to be honest, I'm sort of learning as we go. No one's really done this before.
							!neutral
							!disagree
							But no, I think each one will probably do something different.
							!dubious
							I mean, you can feel it, can't you? That heart wasn't <i>just</i> concentrated <#KONJUR>{name.i_konjur}</>.
							!nervous
							There's like... <#RED>{name.megatreemon}</> <i>essence</i> in there. 
					]],

					ANSWER_3B = [[
						agent:
							!neutral
							!shrug
							Indefinitely.
							!point
							The <#KONJUR>{name.town_grid_cryst}</> also has a pretty gigantic radius. You should get its benefits no matter where on the map we go to hunt.
							!shocked
							Oh! But you can only have one <#KONJUR>{name.i_konjur_heart}</> effect active per slot.
					]],

					ANSWER_3C_HAVEBERNA = [[
						agent:
							!happy
							!gesture
							I'm glad you asked!
							!neutral
							!point
							During our flight I spotted part of the forest where the treeline had been disturbed.
							!gesture
							It's possible <#BLUE>{name.npc_blacksmith}</> landed there in the crash.
							!point
							Finding him is priority number one... but there's also a huge <#RED>{name.rot_boss}</> called an <#RED>{name.owlitzer}</> prowling the area.
							!happy
							!dubious
							We could find {name.npc_blacksmith}, then secure another heart and kill two birds with one stone...
							!neutral
							!nervous
							Err, poor choice of words.
							!point
							Anyway, I've marked the area on your map as <#RED>{name.owlitzer_forest}</>.
					]],

					ANSWER_3C_NOBERNA = [[
						agent:
							!happy
							!point
							I'm glad you asked!
							!neutral
							!gesture
							During our flight I spotted part of the forest where the treeline had been disturbed.
							!nervous
							I think one of our missing people might have landed there-- and they probably woke up the <#RED>{name.owlitzer}</> that prowls the area!
							!point
							We should clear the <#RED>{name_multiple.rot}</> in those woods and see if we can find anyone. I've marked the area on your map as <#RED>{name.owlitzer_forest}</>.
					]],

					QUESTION_4_NOBERNA = "Anything else?", --only if you dont have berna

					ANSWER_4_NOBERNA = [[
						agent:
							!neutral
							!think
							Hmm... Well, I also think we should keep searching the <#RED>{name.treemon_forest}</>.
							!point
							I just have a feeling we missed someone out there.
							!gesture
							Anyway, both locations are available on your map. I'll leave it up to you where we go next.
					]],

					END = "On it, {name.npc_scout}!",
				},
			},
		},

		owlitzer_forest = {
			--visit the dungeon the first time
			owl_first_dgn_visit = {
				TALK = [[
					agent:
						!happy
						!shocked
						Can you believe this little grove was tucked away in the forest?
						!bliss
						I bet it'll make a great camping spot one day, once we've saved the <#RED>{name.rotwood}</>!
				]],

				QUESTION_1A = "I can actually see the stars!",
				QUESTION_1B = "<i>Brr</i>. Feels a little breezy.",

				--BRANCH (both 1A and 1B lead into this branch. 1C is a shortcut through the conversation)--
				ANSWER_1A = [[
					agent:
						!neutral
						!think
						Yeah, I think the <#RED>Wind</> here blows away some of the <#KONJUR>{name.konjur}</> smog.
						!happy
						!agree
						Isn't it nice? I can actually take full breaths!
				]],
				ANSWER_1B = [[
					agent:
						!neutral
						!agree
						Yeah, I hope you're warm enough in that.
						!dubious
						It gets <#RED>Windy</> in there.
				]],

				QUESTION_2A = "Uh, what was that about wind?",
				QUESTION_2B = "Any leads on our missing crew?",
				QUESTION_2C = "What can you tell me about the {name.rot_boss}?",

				ANSWER_2A = [[
					agent:
						!neutral
						!nervous
						Oh, did I forget to mention?
						!agree
						<#RED>{name.owlitzer_forest}'s</> full of <#RED>{name_multiple.rot}</> with <#RED>Wind</> abilities.
						!point
						If you've got <#RED>{name.heavy_weight} Class</> gear it won't bother you much, but anything lighter and you might find it hard to keep your footing.
				]],

				QUESTION_3 = "Can you still fly overhead if it's so windy?",

				ANSWER_3 = [[
					agent:
						!happy
						!laugh
						Oh, yeah. The {name.damselfly} and I withstood a direct hit from <#RED>{name.megatreemon}</>, we can handle a stiff breeze.
				]],
				--END BRANCH--

				--BRANCH
				ANSWER_2B = [[
					agent:
						!neutral
						!think
						Based on the disturbed trees and the trail of debris I saw, I'm pretty sure <#BLUE>{name.npc_blacksmith}</> is in these woods.
						!dejected
						I haven't been able to spot him yet, though.
						!dubious
						Maybe the forest denizens around here will have seen something.
				]],

				ANSWER_2C = [[
					agent:
						!neutral
						!think
						Well, it's called an <#RED>{name.owlitzer}</>.
						!point
						I've only spotted it outside its nest a few times, but I saw enough to know it's a <i>massive</i> bird with crazy sharp talons!
						!scared
						A single flap of its wings creates huge blasts of air!!
				]],

				QUESTION_4A = "<i>Perfect!</i> I love a challenge.",
				QUESTION_4B = "You're not inspiring a lot of confidence.",

				ANSWER_4A = [[
					agent:
						!neutral
						!gesture
						I dunno where you get your bravery, Hunter.
						!happy
						!clap
						But I like it!
						!point
						Let's head out!
				]],
				ANSWER_4B = [[
					agent:
						!neutral
						!nervous
						Oops. Sorry! Um--
						!happy
						!clap
						You can do whatever you put your mind to, Hunter!
						!neutral
						!dubious
						How was that?
				]],
				--END BRANCH--
			},

			owl_celebrate_defeat_boss =
			{
				TALK = [[
					agent:
						!happy
						!clap
						You did it!
				]],

				QUESTION_1 = "I got {name.owlitzer}'s {name.konjur_heart}!",

				ANSWER_1 = [[
					agent:
						!happy
						!point
						Don't leave me in suspense-- pop it into the <#KONJUR>{name.town_grid_cryst}</> and let's see what sort of ability you get!
				]],

				END_OPT = "Okay, okay!",
			},

			owl_talk_after_konjur_heart =
			{
				TALK = [[
					agent:
						!happy
						!clap
						I can feel the <#BLUE>{name.town_grid_cryst}</> buzzing from here!
						!point
						With every new <#KONJUR>{name.i_konjur_heart}</> you get, we get closer to our goal.
				]],

				QUESTION_1A = "How come we're putting {name_multiple.konjur_heart} in the {name.town_grid_cryst}?",

				--1A BRANCH--
				ANSWER_1A = [[
					agent:
						!neutral
						!think
						Welllll--
						!gesture
						You know the <#KONJUR>{name.i_konjur}</> grid that ran through the city, back before the disaster?
						!point
						Our <#BLUE>{name.town_grid_cryst}'s</> one of the last working nodes that fed that system. 
						!gesture
						I want to bring it back online.
				]],

				QUESTION_2A = "Why?", --> ANSWER_3A
				QUESTION_2B = "How do we do that?",
				QUESTION_2B_ALT = "How would we restore the grid?",

				--BRANCH 2B--
				ANSWER_2B = [[
					!neutral
					!dubious
					The <#RED>{name_multiple.town_grid_cryst}</> need an absurdly concentrated form of <#KONJUR>{name.i_konjur}</> to use as fuel.
					!point
					For example, the watered-down stuff you manifest abilities with wouldn't cut it.
					!gesture
					I've noticed a <#RED>{name.rot}'s</> strength is a good indicator of how potent the <#KONJUR>{name.i_konjur}</> in their system is.
					!point
					<#RED>{name_multiple.rot_boss}</> are practically guaranteed to have a <#KONJUR>{name.i_konjur_heart}</>, which is just what the <#BLUE>{name_multiple.town_grid_cryst}</> ordered.
				]],

				QUESTION_3A = "Why would restoring the grid help us?", --uses ANSWER_2A
				QUESTION_3B = "How many {name_multiple.konjur_heart} do we need?",
				QUESTION_3C = "We didn't use {name_multiple.konjur_heart} as fuel back in the day.",
				QUESTION_3D = "So I need to kill more {name_multiple.rot_boss}.",

				--BRANCH 2A--
					--ALSO USED AS QUESTION_3A RESPONSE!
					ANSWER_2A = [[ 
						agent:
							!neutral
							!point
							The grid powered multiple utilities, but the one I'm after is the <#KONJUR>Bubble Shield</>.
							!gesture
							If we could raise a <#KONJUR>Bubble Shield</>, even just around the campsite--
							!happy
							!closedeyes
							We could make things safe enough for normal people to return to the <#RED>{name.rotwood}</>.
							!agree
							After that, who knows. Maybe there'd even be a chance to restore normal life.
					]],
					QUESTION_4A = "You're a good person, {name.npc_scout}.",
					QUESTION_4B = "Sounds like a lofty goal.",

					ANSWER_4A = [[
						agent:
							!happy
							!gesture
							Thanks, Hunter... but none of this would be possible without every person who was crazy enough to come with me.
					]],

					ANSWER_4B = [[
						agent:
							!neutral
							!angry
							I know the odds are against us, but we'll never take back our home if no one's brave enough to try.
					]],
				--END BRANCH 4A--
				ANSWER_3B = [[
					agent:
						!neutral
						!think
						We don't know enough to calculate exactly how many <#KONJUR>{name_multiple.i_konjur_heart}</> it'd take to bring this node back online.
						!point
						But <#KONJUR>{name_multiple.i_konjur_heart}</> could also be useful for improving your powers.
						!gesture
						There's no shortage of big nasty <#RED>{name_multiple.rot_boss}</> out there, so keep feeding those <#KONJUR>{name_multiple.i_konjur_heart}</> into the <#BLUE>{name.town_grid_cryst}</>!
						!happy
						!laugh
						The stronger you are, the more <#KONJUR>{name_multiple.i_konjur_heart}</> you'll be able to procure for the {name_multiple.foxtails} in the future.
						!nervous
						Plus I'd be less worried about you.
				]],
				ANSWER_3C = [[
					agent:
						!neutral
						!shrug
						No, but unfortunately there are no more <#KONJUR>{name.konjur}</> mines left that could manufacture fuel rods.
						!point
						The <#KONJUR>{name_multiple.i_konjur_heart}</> are super potent though, and they work the same in a pinch.
						!gesture
						Plus we clean up the <#RED>{name.rot}</> infestation <i>and</i> enhance your abilities at the same time when we collect them.
						!happy
						!agree
						It's a win-win-<i>win</i>.                  
				]],

				ANSWER_3D = [[
					agent:
						!neutral
						!point
						Exactly. New <#RED>{name_multiple.rot_boss}</> always possess a <#KONJUR>{name.i_konjur_heart}</>.
						!shrug
						It's what turned them into <#RED>{name_multiple.rot_boss}</> in the first place.
				]],

				QUESTION_5 = "Do you have any leads on new {name_multiple.rot_boss}?",

				ANSWER_5 = [[
					agent:
						!neutral
						!gesture
						While you were working on taking down the <#RED>{name.owlitzer}</>, I was busy scouting another area called <#BLUE>{name.bandi_swamp}</>.
				]],

				QUESTION_6A = "Hey! I thought you were spotting me!",
				--[[OPT_6B = "Tell me about this new area.",
				OPT_6B_ALT = "Sigh. Tell me about the area you scouted.",]]
				QUESTION_END = "Well then. To <#RED>{name.bandi_swamp}</>!",

				ANSWER_6A = [[
					agent:
						!happy
						!nervous
						Haha... Hey, you didn't notice my absence, did you?
				]],
				--[[OPT6B_RESPONSE = [[
					agent:
						!neutral
						!thinking
						It's uh, very fungus-y.
						!scared
						And at the heart of the <#BLUE>Bog</> I swear I saw <i>two</i> <#RED>{name_multiple.rot_boss}</>...
						!shocked
						But when I rubbed my eyes, they were gone!
				]]--,
				ANSWER_END = [[
					agent:
						!happy
						!agree
						Let's go get that <#KONJUR>{name.i_konjur_heart}</>.
				]],

				--FUTURE KRIS
				--[[OPT_4D = "Tell me about {name.thatcher_swamp}",
				OPT4D_RESPONSE = [[
					agent:
						!neutral
						!point
						Well, for starters, just flying over it made my nose sting.
						!gesture
						There's a massive pre-eruption insect at the center being guarded by a <#RED>{name.rot_boss}</>.
						!think
						But... something seems wrong about it.
				]]--,
			},
		},

		bandicoot_swamp = {
			bandi_first_dgn_visit = {
				TALK = [[
					agent:
						!neutral
						!shocked
						Whew! It's been awhile since I touched down in <#RED>{name.bandi_swamp}</>.
						!angry
						I forgot how much it stinks!
						!happy
						!dubious
						Have you ever been here before?
				]],

				QUESTION_1A = "This is my first visit.",
				QUESTION_1B = "A couple times, pre-eruption.",

				--BRANCH 1--
				ANSWER_1A = [[
					agent:
						!happy
						!agree
						So this will be your first experience with <#RED>Spores</> then, huh.
				]],
				QUESTION_2A = "Spores?",
				QUESTION_2A_ALT = "Did you say something about Spores?",
				QUESTION_2B = "I'm more worried about the {name.rot_boss}.",
				QUESTION_2B_ALT = "What about the {name.rot_boss} here?",

				ANSWER_2A = [[
					agent:
						!neutral
						!nervous
						Yeah, this whole place is caked top to bottom with fungus.
						!gesture
						<#RED>Spores</> are mostly benign, but they <i>can</i> cause some weird and inconvenient effects.
						!think
						To be honest, there's too many <#RED>Spore</> types to explain individually.
						!point
						I'd suggest learning to identify them by sight.
						!happy
						!shrug
						You'll be fine. You're a fast learner, right?
				]],

				ANSWER_2B = [[
					agent:
						!happy
						!bliss
						Got your eye on the <#KONJUR>{name.i_konjur_heart}</>, do you? I'm glad.
						!neutral
						!gesture
						The <#RED>{name.rot_boss}</> in this area is something called an <#RED>{name.bandicoot}</>.
						!scared
						It's huge, and seems to delight in tormenting people with its tricks.
						!dubious
						This'll be a very different fight from the last <#RED>{name.rot_boss}</>. Steel yourself.
				]],

				-->include end_3B at end of branch
				--1--

				--BRANCH 2--
				ANSWER_1B = [[
					agent:
						!neutral
						!agree
						Ah. It's probably changed a bit since you last saw it.
						!gesture
						Ten years of <#KONJUR>{name.i_konjur}</> contamination's made the <#RED>Spores</> waaay more plentiful.
				]],

				OPT_3A = "Can you tell me about the {name.rot_boss}?", --> go to OPT2C_RESPONSE
				END_3B = "Let's go take down a {name.rot_boss}!", -->go to TALK2
				END_3B_ALT = "Let's go take down that {name.bandicoot}!",
				--2--

				TALK2 = [[
					agent:
						!happy
						!clap
						And get that <#KONJUR>{name.i_konjur_heart}</>!
				]],
			},
			bandi_celebrate_defeat_boss = {
				TALK = [[
					agent:
						!neutral
						That one looked tough!
				]],

				QUESTION_1A = "That was one slippery beast.",
				ANSWER_1A = [[
					agent:
						!neutral
						Good job on that one, it was causing quite the mess.
						!gesture
						Remember to put the <#KONJUR>{name.i_konjur_heart}</> in the machine.
				]]
			},
			bandi_talk_after_konjur_heart = {
				TALK = [[
					agent:
						!neutral
						!closedeyes
						...
				]],

				QUESTION_1A = "Hello? {name.npc_scout}? I put the Heart in.",
				ANSWER_1A = [[
					agent:
						!neutral
						!dubious
						Hm?
						!shocked
						Oh! Yes, great!
						!happy
						!nervous
						T-that heart gave you the ability to <#RED>Heal</> a bit when entering a new clearing!
						!agree
						How interesting!
						!neutral
				]],

				QUESTION_2 = "Is everything okay?",
				QUESTION_END = "Hey, I've been meaning to ask-- how do you know so much about all this stuff?", --shows at the same time as 2, and is still available after clicking 2

				ANSWER_2 = [[
					agent:
						!happy
						!disagree
						Ah, it's nothing.
						!neutral
						!gesture
						Sorry I got distracted, that wasn't very professional.
				]],
				ANSWER_END = [[
					agent:
						!happy
						!nervous
						Haha, I wouldn't say I know <i>that</i> much.
						!dubious
						!neutral
						But I know enough.
						!neutral
						!gesture
						And if I can't become a Hunter myself, then sharing that knowledge with those who can is my duty.
						!happy
						!dubious
						Sorry, would you excuse me?
						!gesture
						I'll talk to you later. Great job on the kill.
				]],
			},
		},
		thatcher_swamp ={
			thatcher_first_dgn_visit = {
				TALK = [[
					agent:
						!happy
						!wave
						Hey hey! Welcome to <#BLUE>{name.thatcher_swamp}</>-- enjoy the lush scenery, and watch your step!
						!shrug
						Unless you like <#RED>Poison</> between your toes.
				]],

				QUESTION_1A = "Poison?",
				--QUESTION_1A_ALT = "You said something about Poison?",
				QUESTION_1B = "Any intel on the {name.rot_boss}?",
				QUESTION_1B_ALT = "Can you tell me anything about the {name.rot_boss} here?",

				ANSWER_1A = [[
					agent:
						!neutral
						!think
						Yeah. There were always a ton of toxic creatures in the bog, even before the volcano erupted.
						!dubious
						And the introduction of <#KONJUR>{name.i_konjur}</> certainly didn't help matters.
						!gesture
						But <#RED>Poison's</> easy enough to understand. There's only one rule--
						!shrug
						Don't touch it.
						!point
						If something spits at you or leaves a <#RED>Poison</> trail, don't stand around in it.
						!happy
						!shrug
						Unless you're looking to do some industrial-strength exfoliation.
				]],
				--BRANCH 1B--
				ANSWER_1B = [[
					agent:
						!neutral
						!think
						It's interesting, Hunter.
						!gesture
						This area's heavily <#KONJUR>{name.konjur}</>-contaminated, but I haven't seen the <#RED>{name.rot_boss}</>.
						!think
						There should definitely be one, but all I've seen is a--
						!shocked
						...!
				]],

				QUESTION_2A = "Everything okay? Your ears twitched.",
				QUESTION_2B = "Hey, pay attention! I need to know about the Boss.",

				--BRANCH 2A--
				ANSWER_2A = [[
					agent:
						!dubious
						Did you... hear music just now?
				]],

				QUESTION_3A = "Yeah, now that you mention it.",
				QUESTION_3B = "No?",

				ANSWER_3A = [[
					agent:
						!dubious
						That's so strange.
				]],
				ANSWER_3B = [[
					agent:
						!shrug
						Welp, perhaps I'm finally losing it.
				]],
				--END BRANCH 2A--
				ANSWER_2B = [[
					agent:
						!happy
						!nervous
						Ah! Sorry! I swear I heard some sort of... music?
						!neutral
						!disagree
						Nevermind, it doesn't matter.
				]],
				--END BRANCH 1B--

				TALK2 = [[
					agent:
						!neutral
						!agree
						Err, anyway, like I was saying.
						!think
						I haven't seen a <#RED>{name.rot_boss}</> here, just a gigantic bug carcass.
						!happy
						!point
						Maybe that carcass <i>was</i> the <#RED>{name.rot_boss}</>, and nature's already done your job for you?
						!gesture
						!neutral
						We should go pick it over and see if there's a <#KONJUR>{name.i_konjur_heart}</> ripe for the picking. 
				]],

				QUESTION_4A = "Wooo! Freebies!",
				QUESTION_4B = "Sounds disgusting.",
				QUESTION_4C = "Booo, I wanted a fight!",

				ANSWER_4A = [[
					agent:
						!happy
						!clap
						Let's go!
				]],

				ANSWER_4B = [[
					agent:
						!happy
						!shrug
						Yep!
				]],

				ANSWER_4C = [[
					agent:
						!happy
						!laugh
						Haha, don't worry. There are plenty more <#RED>{name.rot}</> fights in your future.
				]],
			},

			thatcher_celebrate_defeat_boss = {
				TALK = [[
					agent:
						!neutral
						!think
						Man, it's kinda nuts how good you are at killing <#RED>{name_multiple.rot_boss}</>.
						!gesture
						By the way, I've been tinkering with the <#KONJUR>{name.town_grid_cryst}.
						!happy
						!clap
						I think this'll	 be the last <#KONJUR>{name.i_konjur_heart}</> we need to power the <#KONJUR>Bubble Shield</>!
				]],

				QUESTION_1A = "How exciting!",
				QUESTION_1B = "Hm. I'll believe it when I see it.",

				ANSWER_1 = [[
					agent:
						!gesture
						Yes, well, take a moment to rest if you need it.
						!neutral
						!shocked
						But... don't make me wait too long! Haha.
						!happy
						!nervous
						P-please.
				]],
			},
			thatcher_talk_after_konjur_heart = {
				TALK = [[
					agent:
						!neutral
						Hm... I don't understand.
				]],

				QUESTION_1 = "Hey, I put the Heart in. Where's our Shield?",

				ANSWER_1 = [[
					agent:
						!neutral
						!nervous
						Ah. Haha. I'm... not sure.
						!notebook
						The <#KONJUR>{name.town_grid_cryst}'s</> new power output matches the requirements for the <#KONJUR>Bubble Shield</>.
						!think
						It... should be working.
						!shrug
						It's almost like something is siphoning off the added energy, but that doesn't make any sense.
						!gesture
						I'm gonna need some more time to think about this. I hope you don't mind.
						!happy
						!point
						But congratulations on your win, I know it was no easy feat.
				]],
			},
		},
	}
}
