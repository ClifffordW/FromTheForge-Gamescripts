return
{
	QUESTS = {
		shop_powerupgrade =
		{
			OPT_UPGRADE = "<#RED>[Upgrade {name.concept_relic}]</> Please do!",
			TT_NO_POWERS = "No powers",
		},

		first_meeting = 
		{
			TALK = [[
				agent:
					!notebook
					<i>Woah!</i> What the heck is with these readings--
					!shocked
					You! You're making my equipment go nuts!
					!point
					I'm guessing you're a Hunter?
			]],

			QUESTION_1A = "Yeah, who are you?",
			ANSWER_1A = [[
				agent:
					!notebook_stop
					I'm a <#KONJUR>{name.job_konjurist}</>. The name's {name.npc_konjurist}.
			]],

			QUESTION_1B = "Yeah... What're you doing out here?",
			ANSWER_1B = [[
				agent:
					!notebook_stop
					<i>Um</i>. I'm a <#KONJUR>{name.job_konjurist}</>. We've always been out here.
			]],

			TALK2 = [[
				agent:
					!dubious
					Now do you want <#RED>{name.concept_relic} Upgrades</> or not?
			]],

			QUESTION_2A = "Upgrades?",
			ANSWER_2A = [[
				agent:
					!shrug
					Oh. I just assumed that was why you were here.
					!gesture
					Hunters manifest pretty cool <#RED>{name_multiple.concept_relic}</>, but you're hopeless at honing them without us <#KONJUR>{name_multiple.job_konjurist}</>.
					!eyeroll
					<#RED>Upgrades</> will make your <#RED>{name_multiple.concept_relic}</> way stronger, so if you want one then let's hurry it up.
					!notebook
					I have research to get back to.
			]],
		},
	}
}
