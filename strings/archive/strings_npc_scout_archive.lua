return
{
	QUIPS =
	{
		quip_scout_done_mirror_quest = {
			[[
				!gesture
				Don't forget, you can customize your look at the <#KONJUR>Vanity Mirror</>.
				!clap
				Neat, huh?
			]],
			--[[
				!gesture
				You can use <#KONJUR>{name.glitz}</> to buy new <#BLUE>{name_multiple.cosmetic}</>. Treat yourself!
			]]--,
		},
		dojo_inhalerquest_one = {
			--quips that can play while the quest to refill toot's inhaler is active
			mid_quest_quips = {
				[[
					!point
					Let's get back out there.
					!gesture
					I wanna get <#BLUE>{name.npc_dojo_master}</> his inhaler.
				]],
				[[
					!gesture
					Let's not waste too much time.
					!think
					<#BLUE>{name.npc_dojo_master}'s</> in bad shape.
				]],
			},
		},

		twn_tips_scout =
		{
			tutorial_glitz =
			{
				TALK_GO_CUSTOMIZE = [[
					agent:
						!greet
						Oh, hey Hunter-- have you had a chance to check out the little <#BLUE>Vanity Mirror</> to the right of <#BLUE>{name.npc_dojo_master}</>?
						!gesture
						You can use it to customize your hair, your colours... even your features!
						!shrug
						One of the many perks of existing inside a <#RED>Game</>, huh?
						!gesture
						Why don't you try it out? I'll give you a little somethin' for your time if you do.			
				]],

				OPT_1A = "Ooo, sounds fun!",
				OPT_1B = "Pfft, I look great already.",

				OPT1A_RESPONSE = [[
					agent:
						!greet
						Enjoy!
				]],

				OPT1B_RESPONSE = [[
					agent:
						!point
						Haha. No argument here.
						!shrug
						Anyway, the mirror's there if you want it.
				]],

				TALK_DONE_CUSTOMIZE = [[
					agent:
						!shocked
						Hey, I can tell you used the mirror! You sure look...
						!clap
						Like a Hunter!
						!closedeyes
						I know things like customization aren't strictly necessary to the {name_multiple.foxtails}' mission, but I hope to make living here as homey as possible.
						!gesture
						Thanks for humouring me.
				]],
						--!point
						--As promised, here's a bit of <#KONJUR>{name.glitz}</>. You can use it to buy new <#RED>Cosmetics</>!

				OPT_END = "Thanks, {name.npc_scout}!",
				END_RESPONSE = [[
					agent:
						!laugh
						Don't spend it in one place!
				]],
			},
		},

	},

	QUESTS =
	{	
		main_defeat_megatreemon =
		{
			TITLE = "Rough Landing",
			DESC = [[
				{giver} spotted a {boss} in {target_dungeon}! Eliminate it and make these woods a bit safer.
			]],

			logstrings = {
				find_target_miniboss = "The {miniboss} was last sighted in {target_dungeon}.",
				defeat_target_miniboss = "Defeat {miniboss}.",
				celebrate_defeat_miniboss = "{giver} won't believe what you encountered in the woods.",
				find_target_boss = "The {boss} was last sighted in {target_dungeon}.",
				defeat_target_boss = "Defeat the {boss} in {target_dungeon}.",
				celebrate_defeat_boss = "Tell {giver} of your triumph.",
				add_konjur_heart = "Add the {boss}'s {item.konjur_heart} to {pillar}",
				find_berna = "Locate {name.npc_armorsmith} in the {name.treemon_forest}.",
				find_hamish = "Locate {name.npc_blacksmith} in the {name.owlitzer_forest}.",
			},

			quest_intro =
			{
				TALK_INTRO = [[
					agent:
						!greet
						Hunter! Thank goodness, you're on your feet.
				]],
		
				OPT_1 = "<i>Oof</i>, what hit us?",
		
				TALK_INTRO2 = [[
					agent:
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
						agent:
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
						!think
						The <#RED>{name.damselfly}</> is still operational, so I'm headed back up.
						!agree
						I'll watch from the air to make sure you stay safe, and scoop up anyone you find along the way.
				]],

				--BRANCH 4--
				OPT3B_RESPONSE = [[
					agent:
						!think
						Oh, um. I know the basics of fighting, I could give you refresher if you'd like?
				]],

				OPT_4A = "Yes, please!",
				OPT_4B = "Actually, I've had a burst of bravery.",

				OPT4A_RESPONSE = [[
						agent:
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
						!agree
						Glad to hear it.
						!shocked
						Oh! And if your <#RED>Health</> gets low, you have a <#RED>Potion</> you can drink with <p bind='Controls.Digital.USE_POTION' color=BTNICON_DARK>. 
						!gesture
						You only have one, though, so use it wisely.
						!shocked
						Now let's get out there and save some people!
				]],

				--opt 4B ends the conversation, doesnt go on to opt 5
				OPT4B_RESPONSE = [[
					agent:
						!gesture
						Don't worry Hunter, I'll be right behind you the whole way.
						!point
						Now let's go.
				]],				
				--4--

				OPT3C_RESPONSE = [[
					agent:
						!clap
						Hold on everyone, we're coming!
				]],
			},


			--[[dojo_master_returned = {
				TALK = [[
					agent:
						!clap
						Great news, Hunter!
						!bliss
						<#BLUE>{name.npc_dojo_master}</> made it back to camp while we were out!
						!gesture
						You should go introduce yourself if you haven't had a chance yet.
			},]]

			directions = -- WRITER! Temp for tutorial flow
			{
				LOST = [[
					agent:
						!dubious
						Looking for the <#KONJUR>{name.town_grid_cryst}</>?
						!gesture
						It's the big glowy rock I dropped you off next to.
				]],

				OPT_1A = "OH! The purple well."
			},
		},

		main_defeat_owlitzer =
		{
			TITLE = "Defeat {name.owlitzer}",
			DESC = [[
				{giver} spotted a {boss} in {target_dungeon}! Eliminate it and make these woods a bit safer.
			]],

			has_not_seen_boss =
			{
				HUB_OPT = "[TEMP] So, about {boss}...",

				TALK_FIRST_PLAYER_DEATH = [[
					agent:
						!dejected
						Oh good, you're okay!
						!point
						I found you out there in the <#RED>Rotwood</> and brought you back.
						!think
						I'm so glad you're okay or I might have to deal with the <#RED>{boss}</> myself!
				]],
			},

			die_to_miniboss_convo =
			{
				TALK_DEATH_TO_MINIBOSS = [[
					agent:
						!point
						That <#RED>{miniboss}</> is terrifying!
						!clap
						I'm glad you're the one fighting those <#RED>{name_multiple.rot}</>!
				]],
			},

			die_to_boss_convo =
			{
				HUB_OPT = "[TEMP] So, about {boss}...",

				TALK_DEATH_TO_BOSS = [[
					agent:
						!gesture
						I barely got you out of there!
						!think
						Not sure how that <#RED>{boss}</> didn't notice me.
				]],
			},

			celebrate_defeat_miniboss =
			{
				TALK_FIRST_MINIBOSS_KILL = [[
					agent:
						!clap
						Wow, killing that <#RED>{miniboss}</> sure was something!
						!dejected
						But that <#RED>{boss}</> is still out there!
				]],
			},

			celebrate_defeat_boss =
			{
				HUB_OPT = "[TEMP] So, about {boss}...",

				TALK = [[
					agent:
						!clap
						Hunter, I see you've got a new <#KONJUR>{name.i_konjur_heart}</> with you!
						!point
						Don't leave me in suspense-- pop it into the <#KONJUR>{name.town_grid_cryst}</> and let's see what sort of ability you get!
				]],

				OPT_1 = "Okay, okay!",


				defeated_regular = 
				{
					OPT1_RESPONSE = [[
						agent:
							!gesture
							You know the <#KONJUR>{name.i_konjur}</> grid that ran through the city, back before the disaster?
							!point
							This is one of the last working <#RED>{name_multiple.town_grid_cryst}</> that fed that system. 
							!gesture
							I want to bring it back online.
					]],

					OPT_2A = "Why?",
					OPT_2B = "How do we do that?",
					OPT_2B_ALT = "How would we restore the grid?",

					OPT2B_RESPONSE = [[
						!dubious
						The <#RED>{name_multiple.town_grid_cryst}</> need an absurdly concentrated form of <#KONJUR>{name.i_konjur}</> to use as fuel.
						!point
						For example, the watered-down liquid stuff you manifest abilities with wouldn't cut it.
						!gesture
						I've noticed a <#RED>{name.rot}'s</> strength is a good indicator of how potent the <#KONJUR>{name.i_konjur}</> in their system is.
						!point
						<#RED>{name_multiple.rot_boss}</> are practically guaranteed to have a <#KONJUR>{name.i_konjur_heart}</>, which is just what the <#RED>{name_multiple.town_grid_cryst}</> ordered.
					]],

					OPT_3A = "Why would restoring the grid help us?",
					OPT_3B = "How many {name_multiple.konjur_heart} do we need?",
					OPT_3C = "So I need to kill {name_multiple.rot_boss}.",

					--BRANCH 1-- 
					--ALSO USED AS OPT_2A RESPONSE!
					OPT3A_RESPONSE = [[
						agent:
							!point
							The grid powered multiple utilities, but the one I'm after is the <#RED>Bubble Shield</>.
							!gesture
							If we could raise a <#RED>Bubble Shield</>, even just around the campsite--
							!closedeyes
							We could make things safe enough for normal people to return to the <#RED>{name.rotwood}</>.
							!agree
							After that, who knows. Maybe there'd be a chance to restore normal life.
					]],

					OPT_4A = "You're a good person, {name.npc_scout}.",
					OPT_4B = "Sounds like a lofty goal.",

					OPT4A_RESPONSE = [[
						agent:
							!gesture
							Thanks, Hunter... though none of this would be possible without every person here who was crazy enough to come with me.
					]],

					OPT4B_RESPONSE = [[
						agent:
							!angry
							I know the odds are against us, but we'll never take back our home if no one's brave enough to try.
					]],

					--1--

					--BRANCH 2--
					OPT3B_RESPONSE = [[
						agent:
							!think
							We don't know enough to calculate exactly how many <#KONJUR>{name_multiple.i_konjur_heart}</> it'd take to bring this node back online.
							!point
							But <#KONJUR>{name_multiple.i_konjur_heart}</> could also be useful for improving your powers.
							!gesture
							There's no shortage of big nasty <#RED>{name_multiple.rot_boss}</> out there, so keep feeding those <#KONJUR>{name_multiple.i_konjur_heart}</> into the {name.town_grid_cryst}!
							!laugh
							The stronger you are, the more <#KONJUR>{name_multiple.i_konjur_heart}</> you'll be able to procure for the {name_multiple.foxtails} in the future.
							!tic
							Plus I'd be less worried about you.
					]],
					--2--

					--BRANCH 3--
					OPT3C_RESPONSE = [[
						agent:
							!point
							Exactly. New <#RED>{name_multiple.rot_boss}</> always possess a <#KONJUR>{name.i_konjur_heart}</>.
							!shrug
							It's what turned them into <#RED>{name_multiple.rot_boss}</> in the first place.
					]],
					--3--

					--OPT_5A = "How d'you know so much about this stuff?",
					OPT_5B = "Do you have any leads on {name_multiple.rot_boss}?",				

					--BRANCH 5--

					-- HELLOWRITER: TELL THE PLAYER TO KILL OWLITZER NOT BANDICOOT Slight programmer edits to update functionality of what hearts do
					OPT5B_RESPONSE = [[
						agent:
							!think
							Well, this is temp writing but you should go kill {name.owlitzer}.
							!point
							If you're ready to start looking for more <#KONJUR>{name_multiple.i_konjur_heart}</>, that's where I'd start.
					]],
					--5--

					OPT_7 = "Alright, alright! Let's go kill an {name.owlitzer}!",

					OPT7_RESPONSE = [[
						agent:
							!clap
							To <#RED>{name.owlitzer_forest}</>!
					]],
				},
			},

			talk_after_konjur_heart =
			{
				HUB_OPT = "[TEMP] So, about {boss}...",

				TALK = [[
					agent:
						!closedeyes
						...
				]],

				OPT_1A = "Flitt?",
				OPT_1B = "Something wrong?",

				OPT1A_RESPONSE = [[
					agent:
						!dubious
						Yes?
						!shocked
						Oh! Sorry.
				]],
				OPT1B_RESPONSE = [[
					agent:
						!dubious
						Hm?
						!shocked
						Oh! No. Sorry.
				]],
				TALK2 = [[
					agent:
						!nervous
						I-it looks like that stone gave you the ability to <#RED>Heal</> a bit when entering a new clearing!
						!agree
						How interesting!
				]],

				OPT_2A = "Is everything okay?",
				OPT_2B = "How come we're putting {name_multiple.konjur_heart} in the {name.town_grid_cryst}?",
				OPT_2C = "Okay. So what's our next move?", -->OPT5B_RESPONSE

				OPT2A_RESPONSE = [[
					agent:
						!thinking
						Yeah. I've just... never seen the <#KONJUR>{name.town_grid_cryst}</> operating up close before.
				]],

				--2B BRANCH--
				OPT2B_RESPONSE = [[
					agent:
						!gesture
						You know the <#KONJUR>{name.i_konjur}</> grid that ran through the city, back before the disaster?
						!point
						This is one of the last working <#RED>{name_multiple.town_grid_cryst}</> that fed that system. 
						!gesture
						I want to bring it back online.
				]],

				OPT_3A = "Why?", --> OPT4A_RESPONSE
				OPT_3B = "How do we do that?",
				OPT_3B_ALT = "How would we restore the grid?",

				OPT3B_RESPONSE = [[
					!dubious
					The <#RED>{name_multiple.town_grid_cryst}</> need an absurdly concentrated form of <#KONJUR>{name.i_konjur}</> to use as fuel.
					!point
					For example, the watered-down liquid stuff you manifest abilities with wouldn't cut it.
					!gesture
					I've noticed a <#RED>{name.rot}'s</> strength is a good indicator of how potent the <#KONJUR>{name.i_konjur}</> in their system is.
					!point
					<#RED>{name_multiple.rot_boss}</> are practically guaranteed to have a <#KONJUR>{name.i_konjur_heart}</>, which is just what the <#RED>{name_multiple.town_grid_cryst}</> ordered.
				]],

				OPT_4A = "Why would restoring the grid help us?",
				OPT_4B = "How many {name_multiple.konjur_heart} do we need?",
				OPT_4C = "We didn't use {name_multiple.konjur_heart} as fuel back in the day.",
				OPT_4D = "So I need to kill {name_multiple.rot_boss}.",

				--BRANCH 4A--
					--ALSO USED AS OPT_2A RESPONSE!
					OPT4A_RESPONSE = [[ 
						agent:
							!point
							The grid powered multiple utilities, but the one I'm after is the <#RED>Bubble Shield</>.
							!gesture
							If we could raise a <#RED>Bubble Shield</>, even just around the campsite--
							!closedeyes
							We could make things safe enough for normal people to return to the <#RED>{name.rotwood}</>.
							!agree
							After that, who knows. Maybe there'd be a chance to restore normal life.
					]],
					OPT_5A = "You're a good person, {name.npc_scout}.",
					OPT_5B = "Sounds like a lofty goal.",

					OPT5A_RESPONSE = [[
						agent:
							!gesture
							Thanks, Hunter... though none of this would be possible without every person here who was crazy enough to come with me.
					]],

					OPT5B_RESPONSE = [[
						agent:
							!angry
							I know the odds are against us, but we'll never take back our home if no one's brave enough to try.
					]],
				--END BRANCH 4A--
				OPT4B_RESPONSE = [[
					agent:
						!think
						We don't know enough to calculate exactly how many <#KONJUR>{name_multiple.i_konjur_heart}</> it'd take to bring this node back online.
						!point
						But <#KONJUR>{name_multiple.i_konjur_heart}</> could also be useful for improving your powers.
						!gesture
						There's no shortage of big nasty <#RED>{name_multiple.rot_boss}</> out there, so keep feeding those <#KONJUR>{name_multiple.i_konjur_heart}</> into the {name.town_grid_cryst}!
						!laugh
						The stronger you are, the more <#KONJUR>{name_multiple.i_konjur_heart}</> you'll be able to procure for the {name_multiple.foxtails} in the future.
						!tic
						Plus I'd be less worried about you.
				]],
				OPT4C_RESPONSE = [[
					agent:
						!shrug
						No, but unfortunately there are no more <#KONJUR>{name.konjur}</> mines left that could manufacture fuel rods.
						!point
						But the <#KONJUR>{name_multiple.i_konjur_heart}</> are super potent, and they work the same in a pinch.
						!gesture
						Plus we clean up the <#RED>{name.rot}</> infestation <i>and</i> enhance your abilities by acquiring them.
						!agree
						It's a win-win-<i>win</i>.                  
				]],

				OPT4D_RESPONSE = [[
					agent:
						!point
						Exactly. New <#RED>{name_multiple.rot_boss}</> always possess a <#KONJUR>{name.i_konjur_heart}</>.
						!shrug
						It's what turned them into <#RED>{name_multiple.rot_boss}</> in the first place.
				]],

				--OPT_5A = "How d'you know so much about this stuff?",
				OPT_6B = "Do you have any leads on {name_multiple.rot_boss}?",

				OPT6B_RESPONSE = [[
					agent:
						!gesture
						While you were working on taking down the <#RED>{name.owlitzer}</>, I was busy scouting another area called <#BLUE>{name.bandi_swamp}</>.
				]],

				OPT_7A = "Hey! I thought you were spotting me!",
				--[[OPT_6B = "Tell me about this new area.",
				OPT_6B_ALT = "Sigh. Tell me about the area you scouted.",]]
				OPT_7C = "Well then. To {name.bandi_swamp}!",

				OPT7A_RESPONSE = [[
					agent:
						!nervous
						Haha... Hey, you didn't notice my absence, did you?
				]],
				--[[OPT6B_RESPONSE = [[
					agent:
						!thinking
						It's uh, very fungus-y.
						!scared
						And at the heart of the <#BLUE>Bog</> I swear I saw <i>two</i> <#RED>{name_multiple.rot_boss}</>...
						!shocked
						But when I rubbed my eyes, they were gone!
				]]--,
				OPT7C_RESPONSE = [[
					agent:
						!agree
						Let's go get that <#KONJUR>{name.i_konjur_heart}</>.
				]],

				--FUTURE KRIS
				--[[OPT_4D = "Tell me about {name.thatcher_swamp}",
				OPT4D_RESPONSE = [[
					agent:
						Well, for starters, just flying over it made my nose sting.
						There's a massive pre-eruption insect at the center being guarded by a <#RED>{name.rot_boss}</>.
						But... something seems wrong about it.
				]]--,
			},
		},

		main_defeat_bandicoot =
		{
			TITLE = "Defeat {name.bandicoot}",
			DESC = [[
				{giver} spotted a {boss} in {target_dungeon}! Eliminate it and make these woods a bit safer.
			]],

			quest_intro =
			{
				--{last_boss} to reference treek
				
			},

			has_not_seen_boss =
			{
				HUB_OPT = "[TEMP] So, about {boss}...",

				TALK_FIRST_PLAYER_DEATH = [[
					agent:
						!clap
						Oh good, you're okay!
						!point
						I found you out there in the <#RED>Rotwood</> and brought you back.
						!think
						I'm so glad you're okay or I might have to deal with the <#RED>{boss}</> myself!
				]],
			},

			die_to_miniboss_convo =
			{
				TALK_DEATH_TO_MINIBOSS = [[
					agent:
						!nervous
						That <#RED>{miniboss}</> was terrifying!
						!clap
						I'm glad you're the one fighting those <#RED>{name_multiple.rot}</> and not me!
				]],
			},

			die_to_boss_convo =
			{
				HUB_OPT = "[TEMP] So, about {boss}...",

				TALK_DEATH_TO_BOSS = [[
					agent:
						!gesture
						I barely got you out of there!
						!think
						Not sure how that <#RED>{boss}</> didn't notice me.
				]],
			},

			celebrate_defeat_miniboss =
			{
				TALK_FIRST_MINIBOSS_KILL = [[
					agent:
						!clap
						Wow, killing that <#RED>{miniboss}</> sure was something!
						!dejected
						But that <#RED>{boss}</> is still out there!
				]],
			},

			celebrate_defeat_boss =
			{
				HUB_OPT = "[TEMP] So, about {boss}...",

				TALK_FIRST_BOSS_KILL = [[
					agent:
						!shocked
						I can't believe it! You downed <i>another</> <#RED>{name.rot_boss}</>!
						!point
						You're practically unstoppable, Hunter.
						!clap
						Quickly, go pop it in the <#RED>{name.town_grid_cryst}</>.
						!bliss
						I can't wait another second!
				]],
			},

			talk_after_konjur_heart =
			{
				HUB_OPT = "[TEMP] So, about {boss}...",

				TALK_GAVE_KONJUR_HEART = [[
					agent:
						!clap
						It's working! We're one step closer to powering the <#RED>{name.town_grid_cryst}</>!
						!think
						Unfortunately, that's the end of the story content for this <#RED>Focus Test</>.
						!bliss
						But you're welcome to keep playing. It might be fun to try some runs on higher <#RED>Frenzy Levels</>.
						!point
						I have to say, Hunter, you've been a <i>very</i> welcome addition to the {name_multiple.foxtails}.
						!bliss
						I hope you'll come back again for the <#RED>Full Game</>!
				]],
			},
		},

		hunt_defeat_thatcher = 
		{
			quest_intro =
			{
				INTRO = [[
					agent:
						Welcome to the next hunt!
						You've got some rots to uproot... up-rot... there's a joke there.
						!think
						Anyways, have fun!
						!point
						Oh, by the way, all text in this quest is temp.
				]],
			},

			has_not_seen_boss =
			{
				HUB_OPT = "[TEMP] So, about {boss}...",
				CHAT = [[
					agent:
						What about {boss}?
						We haven't even seen {boss} yet.
						Have you tried getting further in the hunt before you need rescuing?
				]],
			},

			die_to_boss_convo =
			{
				HUB_OPT = "[TEMP] So, about {boss}...",
				CHAT = [[
					agent:
						Well, you died to {boss}.
						Did you know if you don't take damage you won't get knocked out?
						I hope that helps.
				]],
			},

			celebrate_defeat_boss =
			{
				HUB_OPT = "[TEMP] So, about {boss}...",
				CHAT = [[
					agent:
						I saw! You did your job!
						Now go put that heart in the thingy.
				]],
			},

			talk_after_konjur_heart =
			{
				HUB_OPT = "[TEMP] So, about {boss}...",

				CHAT = [[
					agent:
						!clap
						Yay, you did it!
						This concludes Bryce's horrible temp writing.
				]],
			},
		},

		dgn_power_crystal = {
			TALK = [[
				agent:
					!point
					Hey look, a <#RED>{name.concept_relic} Crystal</>!
					!clap
					Have you ever seen one before?
			]],

			OPT_1A = "Nope! What's a {name.concept_relic} Crystal?",
			OPT_1B = "Yeah, I've seen {name.concept_relic} Crystals before.",

			--BRANCH 1--
			OPT1A_RESPONSE = [[
				agent:
					!think
					It's technically <#KONJUR>{name.i_konjur}</>, but in the special form Hunters can realize <#RED>{name_multiple.concept_relic}</> with.
					!point
					Make sure to pick them up whenever you see them.
					!gesture
					<#RED>{name_multiple.concept_relic}</> are <i>very</i> important for surviving against <#RED>{name_multiple.rot}</>.
			]],

			OPT_2A = "How do I use a {name.concept_relic} Crystal?",
			OPT_2B = "How long do \"{name_multiple.concept_relic}\" last?", -->only appears when OPT_2A is exhausted
			OPT_2C = "Where did this Crystal come from?",
			OPT_2D = "Do you want it?",-->only appears when OPT_2C is exhausted
			OPT_2E = "Alright, I'm gonna get going.", --> go to TALK2

			OPT2A_RESPONSE = [[
				agent:
					!gesture
					Just go up and absorb it with <p bind='Controls.Digital.ATTACK_LIGHT' color=BTNICON_DARK>.
			]],
			OPT2B_RESPONSE = [[
				agent:
					!dubious
					You can use <#RED>{name_multiple.concept_relic}</> as much as you want while you're here, but they aren't <i>forever</i>-forever.
					!gesture
					They'll all wear off when we fly back to camp.
			]],
			OPT2C_RESPONSE = [[
				agent:
					!think
					I think <#RED>{name.concept_relic} Crystals</> come from ambient <#KONJUR>{name.i_konjur}</>, which is often released from defeated <#RED>{name_multiple.rot}</>.
					!shrug
					Maybe it formed during your last excursion.
					!point
					At any rate, you're sure to see more of them as you clear the rooms ahead.
			]],
			OPT2D_RESPONSE = [[
				agent:
					!shocked
					The <#RED>{name.concept_relic} Crystal</>?
					!disagree
					Nah, I don't touch the stuff.
				player:
					Why not?
				agent:
					!laugh
					I'm not a Hunter, silly.
			]],
			--1--

			--BRANCH 2--
			OPT1B_RESPONSE = [[
				agent:
					!agree
					Ah, so you know what to do with them then.
			]],
			OPT_3A = "I wouldn't mind hearing some tips.", --> go to OPT2's menu
			OPT_3B = "Yup! See ya.", --> go to TALK2

			OPT3A_RESPONSE = [[
				agent:
					!shrug
						Sure. Anything in particular you want to know?
			]], 
			--2--

			TALK2 = [[
				agent:
					!greet
					Good luck!
			]],
		},

		--regular town chat like shop dialogue/tutorials/etc
		twn_chat_scout =
		{
			multiplayer_start = {
				TALK = [[
					agent:
						!greet
						Hi, Hunter! Welcome to the <#RED>Demo</>!
						!think
						In this version a peculiar shop seems to have appeared in the dungeons.
						!clap
						You might also get to meet a good friend of mine!
						!nervous
						The game is pretty new and a liiittle unstable though, so you'll have to help me put it through the wringer.
						!think
						All you need to do is play with some friends, kill some <#RED>{name_multiple.rot}</>, and most importantly, report any nasty bugs or crashes you encounter with <#RED>F8</>.
						!bliss
						Thanks for participating in this test and I hope you have fun-- the {name_multiple.foxtails} really appreciate your efforts!
						!greet
						Be safe now!
				]],
			},

			--happens after toot returns and once the quest to recharge the inhaler has been actived (no longer available once you refill the inhaler)
			TOOT_RETURNED = {
				TALK1 = [[
					agent:
						!dejected
						I feel terrible about <#BLUE>{name.npc_dojo_master}'s</> condition.
						!nervous
						I'm so used to him being the strongest person in the room, it didn't occur to me he might need help getting back.
				]],

				OPT_1A = "What's wrong with him?",
				OPT_1B = "So... you want me to refill his inhaler with {name.i_konjur}?",
				OPT_1C = "It's not your fault, {name.npc_scout}.",

				OPT1A_RESPONSE = [[
					agent:
						!think
						Hmm, maybe you should ask him that yourself.
						!shocked
						Err, once he's feeling better though.
						!shrug
						<#BLUE>{name.npc_dojo_master}</> gets cranky when he's not feeling well.
				]],
				OPT1B_RESPONSE = [[
					agent:
						!gesture
						Haha. I know it sounds dangerous but unfortunately his doctor's back in the Brinks, so we'll have to make do.
						!disagree
						Don't worry. His regular medicine's derived from <#KONJUR>{name.i_konjur}</>.
						!gesture
						It won't hurt him.
				]],
				OPT1C_RESPONSE = [[
					agent:
						!disagree
						It is.
						!closeeyes
						But it's okay.
						!agree
						I'll just keep a better eye on him and the other {name_multiple.foxtails} in the future.
				]],
			},

			--chats that can pop up while berna and/or hamish are not yet recruited to town
			missing_friends = {

				BERNA_ONLY = {
					risk_assessment = {
						TALK = [[
							agent:
								!scared
								I hope <#BLUE>{name.npc_armorsmith}'s</> confidence doesn't get her into any trouble out there.
								!gesture
								She's, uh, not the best at risk assessment.
						]],
					},

					flitts_morale = {
						TALK = [[
							agent:
								!dejected
								We still haven't rescued <#BLUE>{name.npc_armorsmith}</>! I'm beside myself with worry.
						]],

						OPT_1A = "We'll find her, {name.npc_scout}.",
						OPT_1B = "Moping around here won't help.",

						OPT1A_RESPONSE = [[
							agent:
								!agree
								Yeah. Of course we will.
								!closedeyes
								Thanks, Hunter.
						]],
						OPT1B_RESPONSE = [[
							agent:
								!agree
								You're right.
						]],
					},

					no_armorsmith_in_camp = {
						TALK = [[
							agent:
								!nervous
								I hired <#BLUE>{name.npc_armorsmith}</> to do upkeep and modifications for the whole camp.
								!dejected
								Our Hunters won't stand a chance against some of the stuff out there without her.
						]],
					},

					itch_cream = {
						TALK = [[
							agent:
								!dubious
								I found <#BLUE>{name.npc_armorsmith}'s</> anti-itch cream in some debris.
								!scared
								She's probably missing that by now. 
						]],
					},
				},

				HAMISH_ONLY = {
					hamishs_book = {
						TALK = [[
							agent:
								!dubious
								I found the novel <#BLUE>{name.npc_blacksmith}'s</> was reading.
								!disagree
								Poor guy. He doesn't sleep well if he doesn't read before bed.
						]],

						OPT_1A = "What book?",
						OPT_1B = "I'll get back to searching.",

						OPT1A_RESPONSE = [[
							agent:
								!notebook
								Uhh--
								!think
								The font is too flowery for me to read but there's a picture of two hammers kissing on the front.
						]],
					},
				},

				BERNA_AND_HAMISH = {
					who_am_i_looking_for = {
						TALK = [[
							agent:
								!greet
								Hey, Hunter. Ready to get back out there?
						]],

						OPT_1A = "Could you tell me a bit about the missing folks first?",
						OPT_1B = "I sure am!", --> end convo

						OPT1A_RESPONSE = [[
							agent:
								!gesture
								Oh, <#BLUE>{name.npc_armorsmith}</> and <#BLUE>{name.npc_blacksmith}</>?
						]],

						OPT1B_RESPONSE = [[
							agent:
								!clap
								The {name.damselfly} awaits!
						]],

						OPT_2A = "Yeah, tell me about {name.npc_armorsmith}.",
						OPT_2A_ALT = "And {name.npc_armorsmith}?",
						OPT_2A_ALT2 = "Tell me about {name.npc_armorsmith}.",
						OPT_2B = "What's {name.npc_blacksmith} like?",
						OPT_2B_ALT = "And {name.npc_blacksmith}?",
						OPT_2C = "Why do we need them?",
						OPT_2D = "Thanks, I'll keep looking.",
						OPT_2D_ALT = "Okay. I'm ready to get back out there.", --only if you ran through OPT_2C

						OPT2A_RESPONSE = [[
							agent:
								!think
								Well, she's got a big, pink hair bun, and carries around a leatherworking tool with her.
								!shrug
								A bit eccentric. You definitely won't miss her.
								!disagree
								She tends to stand out wherever she goes.
						]],

						OPT2B_RESPONSE = [[
							agent:
								!shrug
								He's a man of few words and not one to raise a fuss.
								!point
								Make sure you keep your eyes peeled for him.
								!gesture
								I'm not sure he'd even call out to you if he spotted you in the field! Haha.
						]],

						--BRANCH--
						OPT2C_RESPONSE = [[
							agent:
								!gesture
								Like I mentioned earlier, I hired them as our {name.job_armorsmith} and {name.job_blacksmith}, respectively.
								!point
								You'll need them both if you want to upgrade all your gear.
								!gesture
								And trust me. You'll want the upgrades.
								!dubious
								But... I hope you don't just want to rescue them because of what they can do for you.
						]],

						OPT_3A = "Sorry, I didn't mean it like that. I was just curious.",
						OPT_3B = "It's more like an added bonus.",
						OPT_3C = "Nooo... Of cooourse not... Ha-ha...",

						OPT3A_RESPONSE = [[
							agent:
								!agree
								Yeah, understandable. Hopefully I didn't offend.

						]],
						OPT3B_RESPONSE = [[
							agent:
								!shrug
								Fair enough. Your life's on the line, after all.

						]],
						OPT3C_RESPONSE = [[
							agent:
								!dubious
								...
						]],
						--END BRANCH--

						OPT2D_RESPONSE = [[
							agent:
								!agree
								And I'll watch your back!
						]],

						--only if you picked OPT_3C
						OPT2D_RESPONSE_ALT = [[
							agent:
								!agree
								Right. Let's go.
						]],
					},

					tea = {
						TALK = [[
							agent:
								!think
								I wonder if <#BLUE>{name.npc_armorsmith}</> and <#BLUE>{name.npc_blacksmith}</> are getting hungry about now.
								!agree
								I'll see if I can scrounge up some tea before they get back.
						]],
					},

					no_bath = {
						TALK = [[
							agent:
								!dubious
								Hmm... It occurs to me <#BLUE>{name.npc_blacksmith}</> and <#BLUE>{name.npc_armorsmith}</> haven't bathed since we last saw them...
								!think
								<z 0.7>Maybe I'll add an air freshener to the {name.damselfly}'s dash.</z>
								!nervous
								Oh! I didn't mean to say that out loud!
						]],
					},
				},

				ANY = {
					smushed_rations = {
						TALK = [[
							agent:
								!think
								Hm... our food got pretty smushed in the {name.damselfly} crash.
								!shrug
								I hope no one's picky.
						]],
					},
					cards = {
						TALK = [[
							agent:
								!bliss
								Oh hey! My pack of playing cards survived the crash!
								!gesture
								Well at least we have the essentials! Haha.
						]],
					},
				},
			},

			bonion_cry = {
				TALK = [[
					agent:
						!dejected
						Every time I see a <#RED>{name.cabbageroll}</> die I end up crying a little bit.
						!think
						But I'm not sure if that's because I feel bad for it, or because of the <#RED>{name.cabbageroll}</> stink.
				]],
			},

			gathering_data = {
				TALK = [[
					agent:
						!gesture
						It's a lot easier to scout when you've got a fighter on the ground!
						!bliss
						I'm gathering so much info from your {name_multiple.run}!
				]],
			},

			glitz_allergy = {
				TALK = [[
					agent:
						!angry
						Aw geez, this is just great.
				]],

				OPT_1A = "What's wrong, {name.npc_scout}?",

				TALK2 = [[
					agent:
						!shocked
						Oh! Hunter. This is embarrassing.
						!shrug
						I saw some <#KONJUR>{name.glitz}</> while we were out and tried to nab it for you to make <#BLUE>{name_multiple.cosmetic}</>.
						!gesture
						But then I sneezed and scattered it all.
						!angry
						Now I've got no <#KONJUR>{name.glitz}</> for you <i>and</i> I can't get this glitter out of my fur.
				]],

				OPT_2A = "Haha. Well, it's the thought that counts.",
				OPT_2B = "A belated \"gesundheit\" to you, my friend.",
				OPT_2C = "Bummer. I love {name.glitz}.",

				TALK3 = [[
					agent:
						!shocked
						ach-<i>OO!</i>
				]],
			},

			beautiful_future = {
				TALK = [[
					agent:
						!gesture
						Y'know... even in it's corrupted state, the woods still look beautiful from the air.
						!closedeyes
						I wonder what it'll look like after we've saved the world?
				]],

				OPT_1A = "It'll be just as we remembered as kids.",
				OPT_1B = "It'll never be the same, but it can be good.",
				OPT_1C = "Nothing will change. This is the world now.",

				OPT1A_RESPONSE = [[
					agent:
						!think
						You think so? I hope you're right, for the sake of whoever comes after us.
						!gesture
						I like to think that as long as you're breathing, it's never too late to start making things better.
				]],
				OPT1B_RESPONSE = [[
					agent:
						!agree
						You're right. We can't undo what's already been done, but that doesn't mean we can't build something new.
						!gesture
						There's room for beauty in change.
				]],
				OPT1C_RESPONSE = [[
					agent:
						!dubious
						Haha. You don't believe that.
						!gesture
						Otherwise you wouldn't be here.
				]],
			},
			
			bandages = {
				TALK = [[
					agent:
						!greet
						Hey, Hunter.
				]],

				OPT_1A = "Hey, what's with the bandages? Are you injured?",
				OPT_1B = "Hey, {name.npc_scout}. See ya, {name.npc_scout}.",

				OPT1A_RESPONSE = [[
					agent:
						!dubious
						Huh?
						!shocked
						Oh! No. Um...
						!nervous
						I just thought they might make me look more rugged.
				]]
			},

			foraging = {
				part_one = {
					TALK = [[
						agent:
							!think
							I was thinking about doing some foraging in the woods...
							!dejected
							But everything out there's probably too <#KONJUR>{name.i_konjur}</>-contaminated for me to eat.
							!shocked
							Hm... Oh!
							!bliss
							I guess I could just give whatever I find to you Hunters!
					]],

					OPT_1A = "Yum! Food!",
					OPT_1B = "As long as you're having fun.",
					OPT_1C = "I would love some supplies.",

					TALK2 = [[
						agent:
							!agree
							Nice. That'll be fun!
					]],
				},
				part_two = {
					TALK = [[
						agent:
							!greet
							Hey, Hunter! Remember when I mentioned I was gonna go foraging in the woods?
							!giveitem
							I brought you back a little something.
					]],

					OPT_1 = "Thanks, {name.npc_scout}!",

					TALK2 = [[
						agent:
							!laugh
							Thank <i>you</i> for giving me an excuse to go!
					]],
				},

				part_three = {
					TALK = [[
						agent:
							!greet
							Hey, Hunter! I went out foraging again!
							!giveitem
							Here, have some of the spoils.
					]],

					OPT_1A = "Isn't it dangerous for to you be out there alone?",
					OPT_1B = "Thanks!",
					OPT_1B_ALT = "Thanks for the grub!",

					OPT1A_RESPONSE = [[
						agent:
							!laugh
							Don't worry, nothing will see me.
							!gesture
							I'm <i>very</i> sneaky.
					]],
				},
			},

			abandoned_run = {
				TALK = [[
					agent:
						!gesture
						Got cold feet out there, huh?
				]],
				OPT_1A = "Yeah, {name.npc_scout}, things try to bite me out there!",
				OPT_1B = "Nah, I just had to pee.",

				OPT1A_RESPONSE = [[
					agent:
						!agree
						Haha, yeah.
						!laugh
						That's why I prefer the air.
				]],
				OPT1B_RESPONSE = [[
					agent:
						!think
						Ah, yeah.
						!agree
						That <i>is</i> worth an emergency airlift.
				]],
			},

			tutorial_feedback =
			{
				TALK_FEEDBACK_REMINDER = [[
					agent:
						!clap
						Remember to press F8 to give feedback!
						!gesture
						I really appreciate it.
				]],
			},

			upgrade_home =
			{
				TALK_HINT_UPGRADE = [[
					agent:
						Heading out?
						While you're out there, maybe you could get something for me?
						With some {primary_ingredient_name}, I can scout a bit further.
						Keep an eye out.
				]],
		
				TALK_CAN_UPGRADE = [[
					agent:
						What do you have there?
						Did you get some {primary_ingredient_name} so I can upgrade this dismal little tent?
				]],
		
				OPT_UPGRADE = "Let's build it.",
			},

			resident =
			{
				TALK_INTRO = [[
					agent:
						!greet
						%scout instruction startrun
					player:
						Hop in the flying machine. Got it.
				]],
			},
		},

		--friendly chats are inconsequential conversations you can unlock with flitt about world lore/his backstory etc
		twn_friendlychat = 
		{
			INITIATE_CHITCHAT = [[
				agent:
					...
				player:
					<i>(It looks like {name.npc_scout} has some time to chat.)</i>
					Hey {name.npc_scout}--
				agent:
					!dubious
					What's up, Hunter?

			]],

			--used for if a friendly chat is long and needs early exits
			--note that early exited friendly chats wont be completed and can be played again from the beginning
			PREEMPTIVE_END = "Sorry, do you mind if we continue another time?",
			PREEMPTIVE_END_RESPONSE = [[
				agent:
					!laugh
					Of course. But I'm gonna make you hear me out from the beginning next time!
			]],

			EMPTY_LIST = [[
				player:
					...Uh, I totally forgot what I was gonna say.
				agent:
					!agree
					Haha. Well no worries, I'm around if you need me.
			]],

			END_CHITCHAT = "That's all.",

			END_CHITCHAT_RESPONSE = [[
				agent:
					!laugh
					Bye!
			]],

			--VILLAGER UNLOCKS--
			--Blacksmith
			blacksmith =
			{
				blacksmith_recruited = {
					BLACKSMITH_QUESTION = "So it seems we have a {name.job_blacksmith} now.",
					BLACKSMITH_TALK = [[
						agent:
							!clap
							Yeah! I'm so relieved you brought him back!
							!gesture
							Thanks, Hunter. It gives me real peace of mind to know {name.npc_blacksmith}'s safe.
							!laugh
							Plus he seems to really be warming up to you.
							!think
							When you get the chance you should speak to him about honing your weapons.
					]],
				},
			},			

			--Armorsmith
			armorsmith = {
				armorsmith_recruited = {
					ARMORSMITH_QUESTION = "Any thoughts on the {name.job_armorsmith}?",
					ARMORSMITH_TALK = [[
						agent:
							!clap
							You found {name.npc_armorsmith}!
						berna:
							!angry
							A-hem!
						agent:
							!scared
							Oh!
							!agree
							A-and {name.npc_lunn}.
						berna:
							!bliss
							And {name.npc_lunn}.
						agent:
							!gesture
							Thank-you for bringing them back in one piece.
							!point
							When you get a moment, you should speak with {name.npc_armorsmith} about reinforcing your armour.
							!clap
							She might even make you something new if you have the materials.
						berna:
							!greet
							Come by any time!
					]],
				},
			},

			--Dojo
			dojo_master = {
				recruit_chat = {
					QUESTION = "I'm impressed {name.job_dojo} got back on his own.",
					TALK = [[
						agent:
							!laugh
							You know he was one of the original Hunters, right?
							!agree
							I hope you get to know him. He could teach you a lot about fighting <#RED>{name_multiple.rot}</>.
							!shrug
							Heck, most of our knowledge on the <#RED>{name_multiple.rot}</> comes from his original expeditions.
					]],
				},

				toot_and_flitt_origin = {
					QUESTION = "How do you and {name.npc_dojo_master} know each other?",
					
					TALK = [[
						agent:
							!laugh
							Oh, that's a funny story!
							!think
							After the eruption I probably spent about a year bouncing from place to place.
							!point
							I got <i>really</i> good at pickpocketing during that time.
					]],

					OPT_1A = "You were a thief??",
					OPT_1B = "Gotta do what you gotta do to survive.",

					OPT1A_RESPONSE = [[
						agent:
							!agree
							Hunger's a pretty powerful motivator.
					]],

					OPT1B_RESPONSE = [[
						agent:
							!agree
							Oh yeah. Especially in those days.
					]],

					TALK2 = [[
						agent:
							!eyeroll
							Not my proudest moment, but hey--
							!shrug
							I might not be such an expert {name.job_scout} today if not for all that time I spent sneaking around. 
							!point
							Meanwhile <#BLUE>{name.npc_dojo_master}</> was kicking off the first Hunter school around that time.
							!nervous
							And my teenage self made the mistake of thinking he'd be an easy mark.
					]],

					OPT_2A = "Uh-oh.",
					OPT_2B = "Pfft, you could take him.",

					OPT2A_RESPONSE = [[
						agent:
							!laugh
							You see where this is going.
					]],
					OPT2B_RESPONSE = [[
						agent:
							!dubious
							<i>Maybe</i> now... if I got lucky. But definitely not in his prime.
					]],

					TALK3 = [[
						agent:
							Anyway, while he was distracted at the registration table I snuck up... reached into his pocket, and...
							!shocked
							<z 2.0>BAM!</z>
							!laugh
							Next thing I know I'm dangling by my ankle two feet off the ground.
					]],

					OPT_3A = "Woah! {name.npc_dojo_master} was fast!",
					OPT_3B = "Woah! {name.npc_dojo_master} was strong!",

					TALK4 = [[
						agent:
							!bliss
							Haha! Yeah, he got a ton of signups after that show!
					]],

					OPT_4 = "Was he mad?",

					OPT4_RESPONSE = [[
						agent:
							!disagree
							Nah. One squint and he clocked my story instantly.
							!gesture
							I wasn't a bad kid. Just in a bad situation.
							!agree
							He took me in. What happened then is a whole 'nother story, but from then on at least I was safe, warm and fed.
							!point
							I want everyone else in the Brinks to have that, too.
					]],

					OPT_5A = "So you started the {name_multiple.foxtails}.",
					OPT_5B = "Wait, so {name.npc_dojo_master}'s like... your dad??",

					OPT5A_RESPONSE = [[
						agent:
							!clap
							Yup!
							!gesture
							No one can be their best selves in survival mode.
							!point
							So let's take this place back from the <#RED>{name_multiple.rot}</> and give everyone what <#BLUE>{name.npc_dojo_master}</> gave me!
					]],

					OPT5B_RESPONSE = [[
						agent:
							!agree
							Absolutely!
							!think
							Although... I'm not sure he'd use that word.
							!closeeyes
							But the fact he came on this expedition tells me all I need to know.
					]],

					OPT_END = "Thanks for chatting, {name.npc_scout}",
					END_RESPONSE = [[
						agent:
							!gesture
							Anytime. I'm an open book.
					]],
				},

				konjur_allergy = {
					QUESTION = "For someone who isn't a Hunter, you sure can explain a lot about combat techniques.",

					TALK = [[
						agent:
							!dubious
							Oh!
							!nervous
							The story behind that is a bit embarrassing.
					]],
					OPT_1A = "Don't worry, I won't make fun.",
					OPT_1B = "Spill the beans!",

					TALK2 = [[
						agent:
							!thinking
							I was still pretty young when the eruption happened, y'know?
							!gesture
							I met <#BLUE>{name.npc_dojo_master}</> not long after the Brinks was settled.
							!agree
							He gave me a place to stay and I started training as his pupil.
					]],

					OPT_2A = "What a great opportunity!",
					OPT_2B = "Sounds like you didn't have much choice.",

					OPT2A_RESPONSE = [[
						agent:
							!dubious
							Plenty of people would certainly think so.
					]],
					OPT2B_RESPONSE = [[
						agent:
							!shrug
							Well, I believe we all have <i>some</i> choice.
					]],

					TALK3 = [[
						agent:
							!gesture
							Anyway. I made it through all the combat basics, but when it came time to practice Hunter abilities...
							!nervous
							Well, let's just say we learned I was allergic to <#KONJUR>{name.i_konjur}</> <i>pre</i>-tty fast.
					]],

					OPT_3 = "You're allergic to {name.konjur}?",

					OPT3_RESPONSE = [[
						agent:
							!shrug
							Can't even touch the stuff! I swell up like a balloon...
							!shocked
							Pop!
					]],

					OPT_4A = "That's awful!",
					OPT_4B = "That's hilarious!",

					OPT4A_RESPONSE = [[
						agent:
							!shrug
							Ah, but it's just as well.
							!shocked
							I hated every second I was learning to fight!
					]],

					--!laugh
					--...And that's the story of how I became a combat encyclopedia.

					--opt4B plays this response and then plays opt4A's response directly after
					OPT4B_RESPONSE = [[
						agent:
							!angry
							Hey! You said you wouldn't make fun!
					]],
				},
			},

			--Cook
			cook = {
				cook_recruited = {
					COOK_QUESTION = "What do you think of the {name.job_cook}?",
					COOK_TALK = [[
						agent:
							!think
							You know...
							!shrug
							It was a bit of an oversight on my part, not hiring a cook.
							!nervous
							I was so worried about procuring weapons and armour, I totally forgot we need to eat!
							!agree
							Good thing you're here to pick up my slack. {name.npc_cook}'ll be a welcome addition to the team.
							!bliss
							I can't wait to eat some good food!
					]],
				},
			},

			--Apothecary
			apothecary = {
				apothecary_recruited = {
					APOTHECARY_QUESTION = "About the {name.job_apothecary}.",
					APOTHECARY_TALK = [[
						agent:
							!think
							Stuff to think about.
					]],
				},
			},

			--Researcher
			researcher = {
				researcher_recruited = {
					RESEARCHER_QUESTION = "What do you think of the {name.job_refiner}.",
					RESEARCHER_TALK = [[
						agent:
							!shocked
							I can't believe it!
							!bliss
							Word of our progress has spread so far, we're actually attracting new recruits!
							!gesture
							Can I trust you to ensure our researcher friend settles in okay?!
							!clap
							I want to leave a good impression.
					]],
				},
			},

			dungeon_npcs = {
				alphonse_encountered = {
					QUESTION = "About the strange {name.shop_armorsmith} I met...",
					TALK = [[
						agent:
							!shocked
							Oh! That reminds me!
							!point
							You should chat with {name.npc_armorsmith} about your new "friend".
							!shrug
							As part of the {name.job_armorsmith}'s Guild, she might know who they are.
					]],
					END = "Thanks for the tip.",
				},
			},

			lore = {
				DAMSELFLY = {
					QUESTION = ""
				},

				konjur_tech = {
					QUESTION = "How do you know so much about the {name.i_konjur} tech around here?",
					Q_RESPONSE = [[
						agent:
							!shrug
							Oh, I practically grew up in my grandfather's <#KONJUR>{name.i_konjur}</> workshop.
					]],

					OPT_1A = "Wait... you're {name.npc_grandad} {name.flitt_lastname}'s grandson?",
					
					OPT1A_RESPONSE = [[
						agent:
							!clap
							Yep yep!
							!shrug
							To grandpa's chagrin I never really clicked with all that science stuff--
							!point
							But I picked up enough that I can still operate his <#KONJUR>{name.i_konjur}</> machines.
							!bliss
							Grandpa's legacy might just save us all in the end.
					]],
				},
			},
		},

		twn_recruit_mascot = 
		{
			TITLE = "Mascot Quest",

			explain_problem = {
				TALK = [[
					agent:
						!greet
						Hey Hunter, you got a second?
				]],

				OPT_1A = "Sure, what's up?",
				OPT_2A = "Not right now, sorry!",

				OPT1A_RESPONSE = [[
					agent:
						!dubious
						Well, I was scouting over <#BLUE>{name.thatcher_swamp}</> recently and I saw something...
						!nervous
						Strange.
				]],

				OPT1B_RESPONSE = [[
					agent:
						!nervous
						Oh, no problem.
						!nod
						Come catch me when you've got a moment.
				]], -->exit convo

				OPT_2A = "Bones?",
				OPT_2B = "Like what?",

				OPT2A_RESPONSE = [[
					player:
						There's tons of bones there.
					agent:
						!agree
						So many bones!
						!disagree
						But that's not what I'm talking about.
				]],

				TALK2 = [[
					agent:
						!nervous
						It was the mold.
						!scared
						It was... <i>moving</i>.
				]],

				OPT_3A = "Ew.",
				OPT_3B = "Are you sure it wasn't the wind?",

				OPT3A_RESPONSE = [[
					agent:
						!point 
						Yeah, it was super gross.
				]],

				OPT3B_RESPONSE = [[
					agent:
						!angry
						I didn't imagine it!
				]],

				TALK3 = [[
					agent:
						!gesture
						I think the mold spores are gaining sentience.
						In the past year I've noticed the emergence of a new creature in the Bog...
						You'd recognize them as <#RED>{name_multiple.mossquito}</>.
				]],

				OPT_4A = "I hate those guys!",
				OPT_4B = "I assumed they'd always been there.",

				OPT4A_RESPONSE = [[
					agent:
						!agree 
						Yeah, me too. That's why I've been trying to figure out where they're coming from.
				]],
				OPT4B_RESPONSE = [[
					agent:
						!agree
						Haha yeah, it's hard to imagine a world before <#RED>{name_multiple.mossquito}</> bites, huh?
				]],

				TALK4 = [[
					agent:
						!gesture
						But that's why I mention it.
						!point
						I <i>finally</i> saw where they're coming from. It's the <i>mold</i>.
						I saw it wriggling and then suddenly a <#RED>{name.mossquito}</> schlorped out!
						It's coming alive or something.
						If you have the chance, I'd really appreciate it if you could talk to Dr. {name.npc_refiner} and see if she has any insight.
				]],

				OPT_5A = "This is too interesting to stay away!",
				OPT_5B = "I'll see.",

				OPT5A_RESPONSE = [[
					agent:
						!nervous
						I hope you two can sort it out soon.
						!shocked
						I can't stand those lil suckers!
				]],
				OPT5B_RESPONSE = [[
					agent:
						!nervous
						Thanks, Hunter.
				]],
			},

			recruit_mascot = {

			},

			use_potion_on_monster = {

			},
		},

		twn_magpie_delivery = {
			TALK = [[
				agent:
					!scared
					Hey Hunter??
					!nervous
					Can you help me with this bird?? It won't go away!
				magpie:
					<i>SQUAAAWK</i>
			]],

			OPT_1A = "Oh neat, my package is here!",
			OPT_1B = "Relax, {name.npc_scout}. He's cool.",

			OPT1A_RESPONSE = [[
				agent:
					!shocked
					Package? Where did you get a--
				magpie:
					<i>KA-CAW</i>
				agent:
					!scared
					--Ah! It moved!
			]],
			OPT1B_RESPONSE = [[
				agent:
					!shocked
					You <i>know</i> him?
			]],

			--OPT_2 = "",
			OPT_2_ALT = "I met an {name.job_armorsmith} in the field.",

			TALK2 = [[
				player:
					This is the stuff I bought from him on our last outing.
				agent:
					!thinking
					Huh? I don't remember ever seeing you talk to another {name.job_armorsmith}.
			]],

			OPT_3A = "He seemed cool.",
			OPT_3B = "He seemed a little sketchy.",
			OPT_3C = "He had some good pieces.",

			OPT3A_RESPONSE = [[

			]],

			OPT3B_RESPONSE = [[

			]],

			OPT3C_RESPONSE = [[
				agent:
					!thinking
					Hmm...
					!dubious
					I don't know if I approve of you buying gear from an unvetted vendor.
					!gesture
					But quality gear is quality gear.
					!shrug
					And we don't really have the luxury of being picky, do we?
			]],

			TALK3 = [[
				agent:
					!angry
					I'm okay with you getting more deliveries, as long as I don't have to sign for them.
					!nervous
					Birds freak me out.
				nimble:
					SQUAWKK
				agent:
					!scared
					Ah!
			]],
		},
	}
}
