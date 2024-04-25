return
{
	QUESTS =
	{
		talk_in_town = {
			TALK = [[
				agent:
					!neutral
					!gesture
					{name.dojo_cough}
					!happy
					!greet
					'Ey, how d'you do, Hunter? I'm glad <#RED>Early Access'</> gave me a chance to meetcha.
					!gesture
					I'm <#BLUE>{name.npc_dojo_master}</>, the <#RED>{name.job_dojo}</>.
					!dubious
					I've got plans to give you some challenges and toughen you up.
					!laugh
					In the meantime, come by and chat if you want some combat tips! {name.dojo_cough}
			]],

			TEMP_OPT = "Cool. Nice to meet you, {name.npc_dojo_master}!",

			TEMP_INTRO2 = [[
				agent:
					[title:SPEAKER]
					[sound:Event.joinedTheParty] 0.5
					!dubious
					Phew. It was quite the fight gettin' home, y'know.
					[title:CLEAR]
			]],

			--[[TALK = [[
				agent:
					!gesture
					{name.dojo_cough} I'm ho-oome!
				flitt:
					!clap
					{name.npc_dojo_master}! Geez, you took long enough.
				agent:
					!angry
					'Ey. I'm <i>old</i>, fox.
					!point
					Who's yer friend?
				flitt:
					!greet
					Hunter! Good timing. I don't think you've formerly met <#BLUE>{name.npc_dojo_master}</>.
					!gesture
					<#BLUE>{name.npc_dojo_master}</>, this is one of our new Hunters.
			]]--,

			OPT_1A = "Nice to finally meet. I look forward to learning from you.",
			OPT_1B = "How'd you make it back to camp?",
			OPT_1C = "Are you feeling okay?",

			OPT1A_RESPONSE = [[
				agent:
					!agree
					I look forward to putting you through your paces.
			]],
			OPT1B_RESPONSE = [[
				agent:
					!shrug
					{name.dojo_cough} --Fought my way.
			]],
			OPT1C_RESPONSE = [[
				agent:
					!shrug
					Why do you ask?
			]],

			TALK2 = [[
				agent:
					!dejected
					<#KONJUR><i><z 0.8>(cough cough <i>cough</i> HACK)</>
				flitt:
					!point
					<#BLUE>{name.npc_dojo_master}</>? Where's your inhaler?
				agent:
					!angry
					I'm fine, fox! {name.dojo_cough} Quit yer worrying.
				flitt:
					!takeitem
					Huh? There's nothing in here. Did you drop your refill charges during the crash?
					!gesture
					'Ey Hunter, sorry, but <#BLUE>{name.npc_dojo_master}</> won't be up to tutoring you until I can get this refilled.
			]],

			OPT_2A = "Is he okay?",
			OPT_2B = "Can I help?",

			OPT2A_RESPONSE = [[
				agent:
					!angry
					I'm <i>fine</i>! 
			]],
			OPT2B_RESPONSE = [[
				flitt:
					!think
					Hmm...
			]],

			TALK3 = [[
				flitt:
					!agree
					Actually Hunter, there's an errand you could run for me if you're up for it.
					!giveitem
					Could you take this inhaler with you on our next {name.run}?
					!shrug
					If you kill about <#RED>{num_to_kill} {name_multiple.rot}</>, the <#KONJUR>{name.i_konjur}</> should work as a makeshift recharge.
			]],

			OPT_3A = "You got it, {name.npc_scout}.",

			TALK4 = [[
				flitt:
					!happy
					!clap
					Thanks! You're a huge help.
				agent:
					!eyeroll
					{name.dojo_cough} Bah.
			]],

			OPT_2A = "I'd love to learn more Hunter techniques.",
			OPT_2B = "I never turn down a challenge!",
			OPT_2C = "Nice to meet you, {name.npc_dojo_master}.",

			TALK3 = [[
				agent:
					[title:SPEAKER]
					[sound:Event.joinedTheParty] 0.5
					!agree
					Good.
					[title:CLEAR]
			]],

			OPT2A_RESPONSE = [[
				agent:
					!point
					Just know I'm not the type to go around handing out gold stars.
				flitt:
					!happy
					!laugh
					Don't worry, he's tough but fair.
			]],

			OPT2B_RESPONSE = [[
				flitt:
					!nervous
					Please try to keep our Hunters' safety in mind during training, {name.npc_dojo_master}.
				agent:
					!laugh
					You worry too much, fox.
			]],

			OPT_3C = [[

			]],

			OPT_3 = "Make yourself at home.",

			TALK_FIRST_HIRED = [[
				agent:
					!happy
					!laugh
					Ghe-he-he.
					!dubious
					This is gonna be fun.
			]],
		},

		twn_shop_dojo = {
			OPT_TEACH = "Teach me somethin', <#BLUE>{name.npc_dojo_master}</>.", --> go to LESSONS
			OPT_OPEN_MASTERY = "Lemme see my Masteries.", --> go to MASTERIES
		},

		--HELLOWRITER
		masteries = {
			TALK = [[
				agent:
					!neutral
					!happy
					!greet
					'Eyy, is that a new Hunter I see?
					!neutral
			]],

			OPT_1 = "Oh hey. {name.npc_dojo_master}, right?",

			TALK2 = [[
				agent:
					[title:SPEAKER]
					[sound:Event.joinedTheParty] 0.5
					!gruffnod
					!happy
					That's me. Yer very own <#RED>{name.job_dojo}</>.
					[title:CLEAR]
					!neutral
					!cough
					Sorry for the hold up gettin' here.
					!very_sick
					{name.dojo_cough}
					!happy
					!point
					What d'ya say we make up for lost time and getcha started on <#RED>Masteries</>?
			]],

			QUESTION_2A = "Woah, hold up. Are you feeling okay?",
			QUESTION_2A_ALT = "Are you... feeling okay?",
			QUESTION_2B = "Wait, how'd you make it home by yourself?",
			QUESTION_2B_ALT = "How'd you even make it home by yourself?",
			QUESTION_2C = "Um. What are Masteries?",
			QUESTION_2C_ALT = "Alright. So what are these Masteries?",

			ANSWER_2A = [[
				agent:
					!neutral
					!angry
					Yep. Why d'ya ask?
					!cough
					{name.dojo_cough}
			]],
			ANSWER_2B = [[
				agent:
					!neutral
					!dubious
					Would you trust me to teach you anything if I hadn't?
			]],
			ANSWER_2C = [[
				agent:
					!neutral
					!agree
					They're challenges.
					!point
					The best way for a Hunter to learn is in the field.
					!neutral
					!gruffnod
					So go on some Hunts, do some of my <#RED>Mastery</> challenges.
					!happy
					!point
					By the time you've done them all, I'll have molded you into a master of fighting techniques.
			]],
			QUESTION_3A = "How do I complete a Mastery?",
			ANSWER_3A = [[
				agent:
					!happy
					!gesture
					By the time a <#RED>Mastery</> becomes available, it's already active.
					!point
					All you have to do is go on a {name.run} and start fulfilling it.
					!think
					<#BLUE>{name.npc_scout}'ll</> tell me about any headway you made after the {name.run}, and I'll update my books.
			]],

			QUESTION_3B = "What do I get for doing Masteries?",
			ANSWER_3B = [[
				agent:
					!neutral
					!dubious
					Knowledge an'bragging rights, of course-- what else would you want?
					!happy
					!laugh
					Ghe-he-he, {name.dojo_cough} just messing with you.
					!gruffnod
					I reward all studious Hunters with <#KONJUR>Treats</>... like <#KONJUR>{name_multiple.konjur_soul_lesser}</> and other goodies.
			]],
			
			OPT_3C = "Let's see those Masteries!",

			OPT3C_RESPONSE = [[
				agent:
					!neutral
					!gruffnod
					Of course. You can ask me to check your <#RED>Masteries</> any time.
					!happy
					!laugh
					My office hours are all day every day. {name.dojo_cough}
			]],
		},

		explain_frenzy = {
			TALK = [[
				agent:
					!neutral
					!shocked
					'Ey, Hunter! Given that you've got your first <#RED>{name.rot_boss}</> under your belt--
					!happy
					!laugh
					I'd say it's time you learned about <#RED>Frenzy Levels</>!
			]],

			--BRANCH START--
			OPT_1A = "What are \"Frenzy Levels\"?",

			--BRANCH 1--
			OPT1A_RESPONSE = [[
				agent:
					!neutral
					!think
					Eh, <#BLUE>{name.npc_scout}</> had a good way of explaining it. How'd it go...
					!gesture
					They said it's like when you chop down a big tree in the forest. All the lil ones underneath are gonna grow to fill its place.
					!point
					When you cut down a <#RED>{name.rot_boss}</>, all the lil <#RED>{name_multiple.rot}</> in the area are gonna get meaner and tougher.
					!happy
					!shrug
					And you just cut down one <i>heck</i> of a tree.
					!neutral
			]],

			OPT_2A = "Interesting. Tell me more!",
			OPT_2B = "Can you give me a short version of this?",

			OPT2A_RESPONSE = [[
				agent:
					!neutral
					!think
					Eh, from what I understand, killing a <#RED>{name.rot_boss}</> releases all its <#KONJUR>{name.i_konjur}</>. Like popping a water balloon.
					!shrug
					Whenever that balloon is popped it makes <i>all</i> the <#RED>{name_multiple.rot}</> in that area more powerful. We call that a <#RED>Frenzy Level</>.
					!point
					But 'ey, stronger <#RED>{name_multiple.rot}</> just mean more chance to show off the skills I've taught you.
					!happy
					!gesture
					Plus you'll get <#KONJUR>1 {name.i_konjur_heart}</> for each <#RED>{name.rot_boss}</> you defeat on a new level.
					!neutral
					!dubious
					Be warned though, <#RED>Reviving</> allies costs <#RED>Health</> on <#RED>Frenzy Level 2</> and above.
			]],

			OPT2B_RESPONSE = [[
				agent:
					!happy
					!laugh
					Sorry. I'll cut to the chase.
					!neutral
					!gesture
					Because you downed that <#RED>{name.megatreemon}</>, you now have access to the next <#RED>Frenzy Level</> in the <#RED>{name.treemon_forest}</>.
					!dubious
					It'll make enemies more powerful, but you'll also get better stuff for beating them. <#RED>Reviving</> allies costs <#RED>Health</>, though.
					!agree
					You can set an area's <#RED>Frenzy Level</> on the map screen before you head out on a {name.run}.
			]],

			OPT_3A = "Wait... hunting {name_multiple.rot} makes them stronger?!",
			OPT_3B = "I see. Thanks for explaining!", --> leads to TALK_END

			OPT3A_RESPONSE = [[
				agent:
					!neutral
					!think
					Yeah. <#BLUE>{name.npc_scout}</> explained that to me once, too, but I didn't really get it.
					!shrug
					I'm just here to teach you how to hit stuff good.
					!gesture
					You should ask them about their plan to cull the <#RED>{name.rot}</> infestation if you're curious.
			]],

			TALK_END = [[
				agent:
					!happy
					!agree
					{name.dojo_cough} Mhm.
					!neutral
					!point
					By the by, you can hunt in <#RED>Frenzy Level 1</> at the <#RED>{name.treemon_forest}</> now.
					!greet
					You can set the level next time you're on the map to head out.
			]],
		},	

		--talk after flitt's 3rd heart insert dialogue
		flitts_secret = {
			TALK = [[
				agent:
					!neutral
					!dubious
					Psst. Hey kid.
					!point
					I heard you talkin' to the fox.
			]],

			QUESTION_1 = "{name.npc_dojo_master}... is {name.npc_scout} hiding something from me?",

			ANSWER_1 = [[
				agent:
					!neutral
					!think
					Hiding's a strong word. 'Too humble is more like.
					!point
					Tell me, who d'ya think that kid's grandpappy is?
			]],

			QUESTION_2A = "You?",
			QUESTION_2B = "Uhh, a fox probably?",
			QUESTION_2C = "Wait. Are you saying-- no <i>way</i>.",

			ANSWER_2A = [[
				agent:
					!angry
					<i>Do I look like</i>--
					!closedeyes
					No, nevermind. Listen up.
					!gesture
					<#BLUE>{name.npc_scout}'s</> grandpappy is <#BLUE>{name.npc_grandpa} {name.flitt_lastname}</>.
			]],

			ANSWER_2B = [[
				agent:
					!neutral
					!disagree
					Not just <i>any</i> fox.
					!point
					<#BLUE>{name.npc_grandpa} {name.flitt_lastname}</>.
			]],

			ANSWER_2C = [[
				agent:
					!neutral
					!gruffnod
					Yep. <i>The</i> renown <#BLUE>{name.npc_grandpa} {name.flitt_lastname}</>.
			]],

			QUESTION_3A = "...Who?",
			QUESTION_3B = "Inventor of the {name.town_grid_cryst} {name.npc_grandpa} {name.flitt_lastname}??",

			--3A should also play 3B's response right after as one big response
			ANSWER_3A = [[
				agent:
					!neutral
					!angry
					You been livin' under a rock the past two decades??
					!point
					<#BLUE>{name.npc_grandpa} {name.flitt_lastname}</>, famous inventor of the <#BLUE>{name.town_grid_cryst}</>!
			]],

			ANSWER_3B = [[
				agent:
					!neutral
					!dubious
					But not just that. He's the guy that figured out how to use <#KONJUR>{name.konjur}</> fer power.
					!point
					Every bit of tech you've seen yer whole life leads back to that guy.
			]],

			QUESTION_4A = "<i>Ohh</i>. That explains a lot.",
			QUESTION_4B = "Why would {name.npc_scout} hide that?",

			ANSWER_4A = [[
				agent:
					!gruffnod
					Yup.
					!point
					As <#BLUE>{name.flitt_lastname}'s</> last living relative, <#BLUE>{name.npc_scout}'s</> the only one with the know-how left to set this world right.
					!dubious
					'Lot of pressure.
					!gesture
					So... keep an eye on that fox for me, would you?
			]],
			ANSWER_4B = [[
				agent:
					!agree
					The <#BLUE>{name.flitt_lastname}</> name's left some big shoes to fill.
					!dubious
					<#BLUE>{name.npc_scout}'s</> not the type to brag. Or accept unearned praise.
					!gesture
					So... keep an eye on that fox for me, won't you?
			]],

			END_QUESTION = "Yeah. Sure thing.",

			END_ANSWER = [[
				agent:
					!happy
					!gruffnod
					Thanks, Hunter. 'Preciate it.
			]],
		},
	},
}
