--------------------------------------------------------------------------------------------------------------
--ABILITY DESC FORMATTING NOTES FOR WRITERS--

---Use red highlight on numbers, percentages and key combat concepts, ie, Attack, Dodge, Damage, Heal, Shield Segment, Runspeed, etc

---"Runspeed" is one word

---Anything within <#RED></> brackets should be capitalized as if a proper noun, ie <#RED>Damage</> :--VS--: <#RED>damage</>

---Try to keep numbers next to their associated nouns whenever possible, ie
-----"A <#RED>{percent}% Runspeed</> increase":--VS--: "A <#RED>{percent}%</> increase of <#RED>Runspeed</>"

--- If a description has too many elements to highlight, use best judgement to
--- choose the most important 3. Try to view the description in-game to help
--- prioritize

---End description sentences with a period
--------------------------------------------------------------------------------------------------------------

STRINGS.ITEMS.POWERS = {}

STRINGS.ITEMS.POWERS.SHIELD =
{
	-- shield_light_attack =
	-- {
	--	 name = "Even the Odds",
	--	 desc = "Gain <#BLUE>{shield} Shield Segment</> every {attack_count} <#RED>Light</> attacks that connect.", -- {shield} for # of shield added if we make them add >1 shield segment
	-- },

	shield_heavy_attack =
	{
		name = "Heavy Defense",
		desc = "When your <#RED>Heavy Attacks</> hit <#RED>{targets_required} or More Enemies</> at once, gain <#BLUE>{shield} Shield Segment</>."-- {shield} for # of shield added if we make them add >1 shield segment
	},

	shield_focus_kill =
	{
		name = "Resolute",
		desc = "When you <#RED>Kill</> an <#RED>Enemy</> with a <#BLUE>{name.concept_focus_hit}</>, gain <#BLUE>{shield} Shield Segment</>.", -- {shield} for # of shield added if we make them add >1 shield segment
	},

	shield_dodge =
	{
		name = "Tuck and Roll",
		desc = "When you <#RED>Perfect Dodge</>, gain <#BLUE>{shield} Shield Segments</>."
	},

	shield_hit_streak =
	{
		name = "The Best Defense",
		desc = "Every <#RED>{hitstreak} Hit Streak</>, gain <#BLUE>{shield} Shield Segment</>."
	},

	shield_when_hurt =
	{
		name = "Automated Defenses",
		desc = "When you take <#RED>{name.concept_damage}</>, gain <#BLUE>{shield} Shield Segment</>."
	},

	shield =
	{
		name = "Shield Segment",
		desc = "When you have <#BLUE>4 Shield Segments</>, any <#RED>{name.concept_damage}</> taken is reduced to <#RED>{damage}</>, then removes all <#BLUE>Segments</>."
	},

	shield_to_health =
	{
		name = "Inequivalent Exchange",
		desc = "When your <#BLUE>Shield</> breaks, {rarity_text} of the <#RED>{name.concept_damage}</> it prevented.",
		rarity_text_EPIC = "<#RED>Heal</> for half",
		rarity_text_LEGENDARY = "<#RED>Heal</> for all",
	},

	shield_dodge_knockback =
	{
		name = "Inertia",
		desc = "When you have <#BLUE>Shield</>, your <#RED>Dodge</> becomes an <#RED>Attack</> that deals <#RED>{damage_mod}% Weapon {name.concept_damage}</> and inflicts <#RED>Knockback</>.",
	},

	shield_move_speed_bonus =
	{
		name = "Resistance Training",
		desc = "Gain <#RED>+{speed}% {name.concept_runspeed}</> for every <#BLUE>Shield Segment</> you have.",
	},

	shield_heavy_attack_bonus_damage =
	{
		name = "Heavy Hitter",
		desc = "When you have <#BLUE>Shield</>, your <#RED>Heavy Attacks</> deal a bonus <#RED>+{percent}% {name.concept_damage}</>.",
	},

	shield_reduced_damage_on_break =
	{
		name = "Plan B",
		desc = "When your <#BLUE>Shield</> breaks, take <#RED>{percent}%</> reduced <#RED>{name.concept_damage}</> for <#RED>{time}</> seconds.",
	},

	shield_bonus_damage_on_break =
	{
		name = "Plan C",
		desc = "When your <#BLUE>Shield</> breaks, deal an extra <#RED>+{percent}% {name.concept_damage}</> for <#RED>{time}</> seconds.",
	},

	shield_move_speed_on_break =
	{
		name = "Plan Flee",
		desc = "When your <#BLUE>Shield</> breaks, gain <#RED>+{percent}% {name.concept_runspeed}</> for <#RED>{time}</> seconds.",
	},

	shield_steadfast =
	{
		name = "Adamantine",
		desc_EPIC = "When you have <#BLUE>Shield</>, your <#RED>Attacks</> can no longer be interrupted.",
		desc_LEGENDARY = "Your <#RED>Attacks</> can no longer be interrupted.",
	},

	shield_explosion_on_break =
	{
		name = "Shield Detonation",
		desc = "When your <#BLUE>Shield</> breaks, deal <#RED>{damage} {name.concept_damage}</> to all <#RED>Enemies</> in a <#RED>{radius}-Unit Radius</>."
	},

	shield_knockback_on_break =
	{
		name = "Aftershock",
		desc = "When your <#BLUE>Shield</> breaks, all <#RED>Enemies</> in a <#RED>{radius}-Unit Radius</> radius get <#RED>Knocked Down</>."
	},
}

STRINGS.ITEMS.POWERS.ELECTRIC =
{
	charged =
	{
		name = "Charge",
		desc = "When you <#RED>Die</>, trigger a <#RED>Chain Reaction</> which causes an additional <#RED>{damage_mod}% Weapon {name.concept_damage}</> to all other <#RED>Enemies</> that have <#RED>Charge</>, consuming one stack of <#RED>Charge</>."
	},

	charge_apply_on_light_attack =
	{
		name = "Static Charge",
		desc = "Apply <#RED>{stacks} Charge</> with your <#RED>Light Attacks</>.",
	},

	charge_apply_on_heavy_attack =
	{
		name = "Static Shock",
		desc = "Apply <#RED>{stacks} Charge</> in a large radius with your <#RED>Heavy Attacks</>."
	},

	charge_orb_on_dodge =
	{
		name = "Orb of ZAP!",
		desc = "When you <#RED>Dodge</>, drop an orb that applies <#RED>{stacks} Charge</> in a small radius <#RED>{pulses}</> times.", -- NOTE: not displaying cooldown here, because the cooldown is == how long the orb lasts. Effectively, you just can't summon two. Trying to avoid time-based cooldowns, personally!
	},

	charge_consume_on_crit =
	{
		name = "Catalyst",
		desc = "Trigger a <#RED>Chain Reaction</> when you land a <#RED>Critical Hit</>.",
	},

	charge_consume_on_focus =
	{
		name = "Lightning Rod",
		desc = "Trigger a <#RED>Chain Reaction</> when you land a <#BLUE>{name.concept_focus_hit}</>.",
	},

	charge_consume_all_stacks =
	{
		name = "Conductor",
		desc = "When you trigger a <#RED>Chain Reaction</>, consume all stacks of <#RED>Charge</>.",
	},

	charge_consume_extra_damage =
	{
		name = "Strike Twice",
		desc = "<#RED>Chain Reaction</> impulses cause an additional <#RED>+{damage_bonus_percent}% Weapon {name.concept_damage}</>.",
	},
}

STRINGS.ITEMS.POWERS.SUMMON =
{
	summon_slots =
	{
		name = "Summon Slots",
		desc = "Summon up to <#RED>{summons} Minions</>."
	},

	summon_on_kill =
	{
		name = "With A Little Help",
		desc = "When you <#RED>Kill</> an <#RED>Enemy</>, summon a <#RED>Minion</> to fight for you."
	},

	charm_on_kill =
	{
		name = "Enchantée",
		desc = "Once per clearing, when you <#RED>Kill</> an <#RED>Enemy</> it will return to life as a <#RED>Charmed {name.concept_ally}</>."
	},

	summon_wormhole_on_dodge =
	{
		name = "Thinking With Portals",
		desc = "When you double tap <#RED>Dodge</>, summon up to <#RED>2 Portals</> to teleport between."
	},
}

STRINGS.ITEMS.POWERS.SEED =
{
	seeded =
	{
		name = "[TEMP] Seeded",
		desc = "[TEMP] It... does some stuff!"
	},

	seeded_on_light_attack =
	{
		name = "[TEMP] Seed: Light Attack",
		desc = "[TEMP]Your <#RED>Light Attack</> applies <#RED>Seed</>."--does <#RED>Half {name.concept_damage}</>, but applies <#RED>Seed</>."
	},

	seeded_on_heavy_attack =
	{
		name = "[TEMP] Seed: Heavy Attack",
		desc = "[TEMP]Your <#RED>Heavy Attack</> applies <#RED>Seed</> in a large radius."-- does <#RED>0 {name.concept_damage}</>, but applies <#RED>Seed</> in a large radius."
	},

	acid_on_dodge =
	{
		name = "[TEMP] Seed: Acid On Dodge",
		desc = "[TEMP]When you <#RED>Dodge</>, leave behind a trail of <#RED>Acid</>."-- does <#RED>0 {name.concept_damage}</>, but applies <#RED>Seed</> in a large radius."
	},
}

STRINGS.ITEMS.POWERS.CHEAT = {
	-- They're all hidden, so nothing goes in here.
}


STRINGS.ITEMS.POWERS.FOOD_POWER =
{
	thick_skin =
	{
		name = "Silver Lining",
		desc = "When you take <#RED>{name.concept_damage}</>, reduce it by <#RED>{reduction}</>.",
	},

	heal_on_enter =
	{
		name = "Breath of Fresh Air",
		desc = "When you enter a new clearing, <#RED>Heal</> for <#RED>{heal} Health</>.",
	},

	max_health =
	{
		name = "Vitality",
		desc = "Increase <#RED>Maximum Health</> by <#RED>{health}</>."
	},

	max_health_on_enter =
	{
		name = "Trailblazer",
		desc = "When you enter a new clearing, gain <#RED>+{max_health} Maximum Health</> and <#RED>Heal</> for <#RED>{heal} Health</>."
	},

	retail_therapy =
	{
		name = "Retail Therapy",
		desc = "When you enter a <#RED>Shop</>, <#RED>Heal</> for <#RED>{heal} Health</>."
	},

	perfect_pairing =
	{
		name = "Perfect Pairing",
		desc = "Your <#RED>Potion</> will <#RED>Heal</> an additional <#RED>+{bonus_heal}% Health</>."
	},

	pocket_money =
	{
		name = "Pocket Change",
		desc = "Gain <#KONJUR>{konjur} {name.i_konjur}</>."
	},

	private_healthcare =
	{
		name = "Abundance Mindset",
		desc = "Whenever you pick up <#KONJUR>{name.i_konjur}</>, <#RED>Heal {percent}%</> of the amount picked up."
	},
}

STRINGS.ITEMS.POWERS.POTION_POWER =
{
	soothing_potion =
	{
		name = "Soothing Spirits",
		desc = "Immediately <#RED>Heal</> for <#RED>{heal} Health</>.",
	},
	bubbling_potion =
	{
		name = "Bubbling Brew",
		desc = "Immediately <#RED>Heal</> for <#RED>{heal} Health</>.",
	},
	misting_potion =
	{
		name = "Misting Mixture",
		desc = "<#RED>Heal</> for <#RED>{heal} Health</> every <#RED>{tick_time}</> seconds until you've been healed <#RED>{num_heals}</> times.",
	},
}

STRINGS.ITEMS.POWERS.STATUSEFFECT =
{
	juggernaut =
	{
		name = "Juggernaut",
		desc = "Increases your <#RED>Size</> and <#RED>{name.concept_damage}</> by <#RED>+{damage}%</> per stack.\n\nEach stack also causes you to take <#RED>{damagereceivedmult}%</> less <#RED>{name.concept_damage}</>, but reduces your <#RED>{name.concept_runspeed}</> by <#RED>{speed}%</>.\n\nRemoved when combat ends.",
	},

	smallify =
	{
		name = "Tiny",
		desc = "Shrink in <#RED>Size</> by <#RED>{scale}%</>. Gain <#RED>+{speed}% {name.concept_runspeed}</>, but take <#RED>{damage}% Increased {name.concept_damage}</>.", --this kong's got STYLE, so listen up dudes, she can shrink in size, to suit. her. mood! she's quick and nimble when she needs to be, SHEee can float through the air, and climb. up. trees!
	},
	stuffed =
	{
		name = "Stuffed",
		desc = "Reduced <#RED>{name.concept_runspeed}</>.",
	},
	freeze =
	{
		name = "DEV_FREEZE",
		desc = "You should never see this in the UI.",
	},
	poison =
	{
		name = "DEV_POISON",
		desc = "You should never see this in the UI.",
	},
	hammer_totem_buff =
	{
		name = "DEV_HAMMER_TOTEM_BUFF",
		desc = "You should never see this in the UI.",
	},
	confused =
	{
		name = "DEV_CONFUSED",
		desc = "You should never see this in the UI.",
	},
	acid =
	{
		name = "DEV_ACID",
		desc = "You should never see this in the UI.",
	},
	toxicity =
	{
		name = "DEV_TOXICITY",
		desc = "You should never see this in the UI.",
	},
	bodydamage =
	{
		name = "DEV_BODYDAMAGE",
		desc = "You should never see this in the UI.",
	},
}

STRINGS.ITEMS.POWERS.TONIC =
{
	tonic_rage =
	{
		name = "Yammo Rage",
		desc = "Increase your <#RED>{name.concept_damage}</> by <#RED>+{damage}%</> for <#RED>{time}</> seconds.",
	},
	tonic_speed =
	{
		name = "Zucco Speed",
		desc = "Increase your <#RED>{name.concept_runspeed}</> by <#RED>+{speed}%</> for the rest of the encounter.",
	},
	tonic_explode =
	{
		name = "Explosive",
		desc = "Explode, dealing <#RED>{damage} {name.concept_damage}</> to all <#RED>Enemies</> within {radius} unit radius every <#RED>{tick_time}</> second for <#RED>{duration}</> seconds.",
	},
	tonic_freeze =
	{
		name = "Freeze",
		desc = "Freeze all <#RED>Enemies</> in the encounter.",
	},
	tonic_projectile =
	{
		name = "Mud Spray",
		desc = "Shoot <#RED>{projectiles} Projectiles</> that deal <#RED>{damage} {name.concept_damage}</> each.",
	},
	tonic_projectile_repeat =
	{
		name = "Sustained Spray",
		desc = "Shoot <#RED>{projectiles} Projectiles</> that deal <#RED>{damage} {name.concept_damage}</> every <#RED>{tick_time}</> second for <#RED>{duration}</> seconds.",
	},
}

STRINGS.ITEMS.POWERS.PLAYER =
{

	snowball_effect =
	{
		name = "Snowball Effect",
		-- TODO(dbriscoe): Can we use GL-style ability loc macros for On a Roll to ensure
		-- consistent translation and insert nbsp to prevent bad wrapping?
		-- For now, I added nbsp inside the string but that seems
		-- unreliable.
		desc = "When you <#RED>Kill</> an <#RED>Enemy</>, gain <#RED>{stacks} Stacks</> of <#RED>On a Roll</>.",
	},

	damage_until_hit =
	{
		name = "On a Roll",
		desc = "Gain <#RED>+1% {name.concept_damage}</> for each stack.\nRemove all stacks whenever you take <#RED>{name.concept_damage}</>.",
	},

	undamaged_target =
	{
		name = "Strong Start",
		desc = "Your <#RED>Attacks</> against <#RED>Enemies</> with full <#RED>Health</> deal <#RED>+{bonus}% {name.concept_damage}</>.",
	},

	thorns =
	{
		name = "Retaliation",
		desc = "When you're <#RED>Attacked</>, deal <#RED>{reflect} {name.concept_damage}</> back to the <#RED>Attacker</>.",
	},

	heal_on_focus_kill =
	{
		name = "Concentrated Cure",
		desc = "When you use a <#BLUE>{name.concept_focus_hit}</> to <#RED>Kill</> an <#RED>Enemy</> or break something in the environment, <#RED>Heal</> for <#RED>{heal} Health</>.",
	},

	heal_on_quick_rise =
	{
		name = "Stage Fall",
		desc = "When you <#RED>Quick Rise</>, <#RED>Heal</> for <#RED>{heal} Health</>.",
	},

	-- extra_damage_after_iframe_dodge =
	-- {
	--	 name = "Sting Like A Bee",
	--	 desc = "After a <#RED>Perfect Dodge</>, your next attack deals {damage_mult}x damage.\n\n<z 0.8><i><#GOLD>Perfect Dodge</>: Narrowly dodge an attack at the last second.</i></z>",
	-- },

	berserk =
	{
		name = "Cornered Coyote",
		desc = "When you have less than <#RED>{health} Health</>, deal <#RED>+{bonus}% {name.concept_damage}</>.",
	},


	max_health_and_heal =
	{
		name = "Waffle",
		desc = "Gain <#RED>+{health} Maximum Health</> and <#RED>Heal</> to full."
	},

	bomb_on_dodge =
	{
		name = "Parting Gifts",
		desc = "When you <#RED>Dodge</>, launch {rarity_text} in a random direction.\n\n<z 0.8><i>Cooldown: <#RED>{cd}</> seconds</i></z>",
		rarity_text_EPIC = "a <#RED>Bomb</>",
		rarity_text_LEGENDARY = "<#RED>2 Bombs</>", -- TODO: make a more elegant way of handling this, especially one that can read {num_bombs}
	},

	attack_dice =
	{
		name = "Attack Dice",
		desc = "When you deal <#RED>{name.concept_damage}</>, do an extra <#RED>{min}-{max} {name.concept_damage}</>, <#RED>{count}</> times."
	},

	running_shoes =
	{
		name = "Running Shoes",
		desc = "Gain <#RED>+{speed}% {name.concept_runspeed}</>."
	},

	coin_purse =
	{
		name = "Petty Cash",
		desc = "Inflict an extra <#RED>+{bonus}% {name.concept_damage}</> for every <#KONJUR>{currency} {name.i_konjur}</> you have."
	},

	extended_range =
	{
		name = "Pew Pew!",
		desc = "Every <#RED>{swings} Attacks</>, shoot {rarity_text} half your Weapon's <#RED>{name.concept_damage}</>.",
		rarity_text_COMMON = "<#RED>1 Projectile</> that deals",
		rarity_text_EPIC = "<#RED>2 Projectiles</> that deal",
		rarity_text_LEGENDARY = "<#RED>3 Projectiles</> that deal",
	},

	bloodthirsty =
	{
		name = "Bloodthirsty",
		desc = "<#RED>Heal {heal}%</> of <#RED>{name.concept_damage}</> you deal. Lose <#RED>{health_penalty}% Maximum Health</>.\n\nTake <#RED>{damage} {name.concept_damage}</> every <#RED>{time}</> seconds. <#RED>Bloodthirsty</> will never deal fatal <#RED>{name.concept_damage}</>.",
	},

	mulligan =
	{
		name = "Mulligan",
		desc = "When you <#RED>Die</>, remove this <#RED>{name.concept_relic}</> and <#RED>Heal</> to <#RED>{heal}% Max Health</>.",
	},

	iron_brew =
	{
		name = "Iron Brew",
		desc = "Refill your <#RED>Potion</>.\n\nEach time you <#RED>Drink</>, <#RED>Heal</> an additional <#RED>+{bonus_heal}%</> and gain <#BLUE>Shield</>.",
	},

	risk_reward =
	{
		name = "Thrill Seeker",
		desc = "Deal <#RED>+{outgoing}% Damage</>. Take <#RED>+{incoming}% {name.concept_damage}</>.",
	},

	retribution =
	{
		name = "Righteous Fury", --renamed from Retribution to help differentiate it from Retaliation
		desc = "When you take <#RED>{name.concept_damage}</>, your next <#RED>Attack</> deals <#RED>+{percent}% {name.concept_damage}</>.",
	},

	pump_and_dump =
	{
		name = "Wind Up",
		desc = "Every <#RED>{attacks}th Attack</> deals <#RED>+{percent}% {name.concept_damage}</>."
	},

	volatile_weaponry =
	{
		name = "Volatile Weaponry",
		desc = "Every <#RED>{count} Hit Streak</>, cause an explosion in an area around the target."
	},

	precision_weaponry =
	{
		name = "Precision Weaponry",
		desc = "Every <#RED>{count} Hit Streak</> is guaranteed to <#RED>Critical Hit</>. "
	},

	fractured_weaponry =
	{
		name = "Fractured Weaponry",
		desc = "Every <#RED>{count} Hit Streak</>, launch a <#RED>Bomb</> in a random direction."
	},

	weighted_weaponry =
	{
		name = "Weighted Weaponry",
		desc = "When you have at least <#RED>{count} Hit Streak</>, <#RED>Critical Hits</> deal <#RED>+{percent}% {name.concept_damage}</>."
	},

	momentum =
	{
		name = "Momentum",
		desc = "When you <#RED>Dodge</>, gain <#RED>+{speed}% {name.concept_runspeed}</> for <#RED>{time}</> seconds."
	},

	down_to_business =
	{
		name = "Straight to Business",
		desc = "When you enter a new clearing, gain <#RED>+{speed}% {name.concept_runspeed}</> for <#RED>{time}</> seconds."
	},

	grand_entrance =
	{
		name = "Big Stick",
		desc = "Your first <#RED>Heavy Attack</> per clearing deals <#RED>{damage} {name.concept_damage}</> to all <#RED>Enemies</>."
	},

	extroverted =
	{
		name = "Extroverted",
		desc = "When you enter a new clearing, gain <#RED>+{damage}% {name.concept_damage}</> for <#RED>{time}</> seconds."
	},

	introverted =
	{
		name = "Introverted",
		desc = "When you enter a new clearing, gain <#BLUE>Shield</>."
	},

	wrecking_ball =
	{
		name = "Wrecking Ball",
		desc = "Multiply your <#RED>{name.concept_damage}</> by your <#RED>{name.concept_runspeed} {name.powerdesc_modifier}</>"
	},

	steadfast =
	{
		name = "Relentless",
		desc = "Your <#RED>Attacks</> can no longer be interrupted."
	},

	getaway =
	{
		name = "Post-Kill Zoomies",
		desc = "When you <#RED>Kill</> an <#RED>Enemy</>, gain <#RED>+{speed}% {name.concept_runspeed}</> for <#RED>{time}</> seconds."
	},

	-- stronger_light_attack =
	-- {
	--	 name = "Light Might",
	--	 desc = "Your Light attacks deal {bonus}% more damage."
	-- },

	-- stronger_heavy_attack =
	-- {
	--	 name = "Heavy Hitter",
	--	 desc = "Your Heavy attacks deal {bonus}% more damage."
	-- },

	-- stronger_crits =
	-- {
	--	 name = "Concentration",
	--	 desc = "Your Focus attacks deal {bonus}% more damage."
	-- },

	-- increased_pushback =
	-- {
	--	 name = "Keepaway",
	--	 desc = "Your attacks push enemies further away."
	-- },

	no_pushback =
	{
		name = "Constructive Criticism",
		desc = "Your <#RED>Attacks</> no longer push <#RED>Enemies</> away."
	},

	increased_hitstun =
	{
		name = "Simply Stunning",
		desc = "Your <#RED>Attacks</> deal {rarity_text} <#RED>Hitstun</> to <#RED>Enemies</>.",
		rarity_text_COMMON = "more",
		rarity_text_EPIC = "even more",
		rarity_text_LEGENDARY = "significantly more",
	},

	combo_wombo =
	{
		name = "Confidence Building",
		desc = "Your <#RED>{name.concept_damage}</> is increased by an amount equal to {rarity_text} until it ends.",
		rarity_text_EPIC = "your current <#RED>Hit Streak</>",
		rarity_text_LEGENDARY = "<#RED>{name.powerdesc_double}</> your current <#RED>Hit Streak</>",
	},


	battle_fame =
	{
		name = "Surgical",
		desc = "When combat ends, gain <#KONJUR>{name.i_konjur}</> equal to {rarity_text} in that clearing.",
		rarity_text_COMMON = "your highest <#RED>Hit Streak</>",
		rarity_text_EPIC = "<#RED>{name.powerdesc_double}</> your highest <#RED>Hit Streak</>",
		rarity_text_LEGENDARY = "<#RED>{name.powerdesc_triple}</> your highest <#RED>Hit Streak</>",
		new_highest_popup = "New high: %s",
	},

	streaking =
	{
		name = "Excitable",
		desc = "Increase your <#RED>{name.concept_runspeed}</> by a percentage equal to {rarity_text}.",
		rarity_text_COMMON = "your current <#RED>Hit Streak</>",
		rarity_text_EPIC = "<#RED>{name.powerdesc_double}</> your current <#RED>Hit Streak</>",
		rarity_text_LEGENDARY = "<#RED>{name.powerdesc_triple}</> your current <#RED>Hit Streak</>",
	},

	crit_streak =
	{
		name = "Piñata",
		desc = "Increase your <#RED>Critical Chance</> by a percentage equal to {rarity_text}.",
		rarity_text_EPIC = "your current <#RED>Hit Streak</>",
		rarity_text_LEGENDARY = "<#RED>{name.powerdesc_double}</> your current <#RED>Hit Streak</>",
	},

	crit_movespeed =
	{
		name = "Ambush Predator",
		desc = "Increase your <#RED>Critical Chance</> by a percentage equal to {rarity_text}.",
		rarity_text_LEGENDARY = "your current <#RED>{name.concept_runspeed}</>",
	},

	lasting_power =
	{
		name = "Encore",
		desc = "When a <#RED>Hit Streak</> ends, gain <#RED>Critical Chance</> equal to that <#RED>Hit Streak</> for <#RED>{time}</> seconds.",
	},

	sting_like_a_bee =
	{
		name = "Sting Like a Bee",
		desc = "When you <#RED>Perfect Dodge</>, the next time you deal <#RED>{name.concept_damage}</> is guaranteed to <#RED>Critical Hit</>."
	},

	advantage =
	{
		name = "Good First Impression",
		desc = "Your <#RED>Attacks</> against <#RED>Enemies</> with <#RED>{desc} Health</> are guaranteed to <#RED>Critical Hit</>."
	},

	salted_wounds =
	{
		name = "Salted Wounds",
		desc = "Your <#BLUE>{name_multiple.concept_focus_hit}</> have <#RED>+{bonus}% Critical Chance</>.",
	},

	crit_knockdown = --kris
	{
		name = "High Ground",
		desc = "Your <#RED>Attacks</> against <#RED>Enemies</> that are <#RED>Knocked Down</> have <#RED>+{chance}% Critical Chance</>."
	},

	heal_on_crit = --kris
	{
		name = "Morale Booster",
		desc = "When you <#RED>Critical Hit</>, <#RED>Heal</> for <#RED>{heal}</>.",
	},


	konjur_on_crit =
	{
		name = "Jackpot",
		desc = "<#RED>Critical Hits</> drop <#KONJUR>{konjur} {name.i_konjur}</>."
	},

	-- reprieve =
	-- {
	--	 name = "Reprieve",
	--	 desc = "<#RED>Hit Streaks</> decay {percent}% slower.",
	-- },

	sanguine_power =
	{
		name = "Sanguine Power",
		desc = "Each time you <#RED>Kill</> an <#RED>Enemy</>, gain <#RED>+{bonus}% Critical Chance</> for <#RED>{time}</> seconds.",
	},

	feedback_loop =
	{
		name = "Feedback Loop",
		desc = "Each time you <#RED>Critical Hit</>, gain <#RED>+{bonus}% Critical Chance</> for <#RED>{time}</> seconds."
	},

	-- crit_to_crit_damage =
	-- {
	--	 name = "Crit to Crit Damage",
	--	 desc = "Increase the <#RED>Critical Damage</> of attacks by the <#RED>Critical Chance</> of the attack."
	-- },

	bad_luck_protection =
	{
		name = "Get'em Next Time",
		desc = "Gain <#RED>+{bonus}% Critical Chance</> each time you hit something.\n\nResets when you <#RED>Critical Hit</>."
	},

	-- critical_roll =
	-- {
	--	 name = "Counter Argument",
	--	 desc = "Each time you <#RED>Perfect Dodge</>, gain <#RED>+{bonus}% Critical Chance</> for <#RED>{time}</> seconds."
	-- },

	optimism =
	{
		name = "Healthy Optimism",
		desc = "Each time you <#RED>Heal</>, gain <#RED>+{bonus}% Critical Chance</> for <#RED>{time}</> seconds."
	},

	pick_of_the_litter =
	{
		name = "Pick of the Litter",
		-- desc_EPIC = "When you activate a <#RED>{name.concept_relic}</>, choose from <#RED>{count}</> more option.",
		desc_LEGENDARY = "When you activate a <#RED>{name.concept_relic}</>, choose from <#RED>{count}</> more option.",
	},

	-- stronger_counter_hits =
	-- {
	--	 name = "Counter Puncher",
	--	 desc = "Your attacks that land during an enemy's attack startup deal <#RED>+{bonus}% Damage</>."
	-- },

	free_upgrade =
	{
		name = "First One's Free",
		desc = "Whenever you get a new <#RED>{name.concept_relic}</>, upgrade it once."
	},

	shrapnel =
	{
		name = "Shrapnel",
		desc = "Anything you break in the environment shatters into <#RED>{projectiles} Projectiles</> that deal <#RED>{damage} {name.concept_damage}</> each.",
	},

	analytical =
	{
		name = "Lil' Schemer",
		desc = "If you do not <#RED>Attack</> for <#RED>{seconds}</> seconds, your next <#RED>Attack</> gains <#RED>+{percent}% {name.concept_damage}</>.",
	},

	dont_whiff =
	{
		name = "Strength of Conviction",
		desc = "Your <#RED>Light Attack</> deals an extra <#RED>{otherdamage} {name.concept_damage}</>, but inflicts <#RED>{selfdamage} {name.concept_damage}</> to you when you miss.",
	},

	dizzyingly_evasive =
	{
		name = "Acrobat",
		desc = "Your <#RED>Dodge</> can be chained into itself infinitely.",
	},

	carefully_critical =
	{
		name = "Light Precision",
		desc = "When you land a <#RED>Light Attack</>, gain <#RED>+{bonus}% Critical Chance</>.\n\nWhen you miss with a <#RED>Light Attack</>, reset the bonus.",
	},

	reflective_dodge =
	{
		name = "I'm Rubber, You're Glue",
		desc = "When you <#RED>Dodge</>, reflect <#RED>{percent}% {name.concept_damage}</> taken for the next <#RED>{time}</> seconds.",
	},

	ping =
	{
		name = "Ping!",
		desc = "When you <#RED>Light Attack</>, your next <#RED>Attack</> deals double <#RED>{name.concept_damage}</> if it's a <#RED>Heavy Attack</>."--but <#RED>Half Damage</> if it's another <#RED>Light Attack</>.",
	},

	pong =
	{
		name = "Pong!",
		desc = "When you <#RED>Heavy Attack</>, your next <#RED>Attack</> deals double <#RED>{name.concept_damage}</> if it's a <#RED>Light Attack</>."--but <#RED>Half Damage</> if it's another <#RED>Heavy Attack</>.",
	},

	-- Skill-specific Powers
	moment37 =
	{
		-- Parry
		name = "Thirty-Seven", -- from EVO Moment #37, famous fighting game parry
		desc = "When you <#RED>Parry</>, gain <#RED>100% Critical Chance</> for an extra <#RED>{time}</> seconds.",
	},

	jury_and_executioner =
	{
		-- Hammer Thump - "Order in the Court"
		name = "Jury and Executioner",
		desc = "Your <#RED>Skill</> Order in the Court deals <#RED>{damage_per_consecutive_hit} {name.concept_damage}</> for each consecutive hit.",
	},

	loot_increase_rarity_loot_chance = {
		-- Loot powers:
		COMMON = "more likely",
		EPIC = "<i>much</i> more likely",
		LEGENDARY = "<i>significantly</i> more likely",
		-- We can't really show any meaningful numbers to the players because of the way our loot system works, unfortunately.
		-- If we want to show numbers instead of "more likely / much more likely / etc", we'll need to find a way to make it grokable.
	},

	max_health_wanderer =
	{
		name = "Tendrel", -- jambell name, please ask before changing
		desc = "Increase <#RED>Maximum Health</> by <#RED>{health}</>."
	},

	-- REVIVE POWERS:
	-- Multiplayer-only powers which get triggered when you revive someone.
	-- do we have macros for revive, 'ally', etc?
	-- RESPONSE: we do now: {name.concept_ally} {name.concept_revive}
	revive_gain_konjur =
	{
		name = "Grave Robber",
		desc = "When you <#RED>{name.concept_revive}</> an <#RED>{name.concept_ally}</> during combat, gain <#KONJUR>{konjur} {name.i_konjur}</>."
	},

	revive_explosion =
	{
		name = "Phoenix Burst",
		desc = "When you <#RED>{name.concept_revive}</> an <#RED>{name.concept_ally}</> during combat, deal <#RED>{damage} {name.concept_damage}</> to all <#RED>Enemies</>.",
	},

	revive_damage_bonus =
	{
		name = "Lich King",
		desc = "When you <#RED>{name.concept_revive}</> an <#RED>{name.concept_ally}</> during combat, gain <#RED>+{percent_per_revive}% {name.concept_damage}</> for the rest of the {name.run}." --what doesnt kill you makes me stronger :)
	},

	revive_borrow_power =
	{
		name = "Departing Gift", --Dearly Departing Gift too wordy?
		desc = "When you <#RED>{name.concept_revive}</> an <#RED>{name.concept_ally}</> during combat, copy <#RED>{powers_borrowed} {name.concept_relic}</> from their loadout for the rest of the {name.dungeon_room}.",
		--rarity_text_COMMON = "<#RED>{powers_borrowed} {name.concept_relic}</>",
		--rarity_text_EPIC = "<#RED>{powers_borrowed} {name_multiple.concept_relic}</>",
	},
}

STRINGS.ITEMS.POWERS.SKILL = {
	parry =
	{
		name = "Parry",
		desc = "Nullify an incoming <#RED>Attack</> to gain a brief window of <#RED>100% Critical Chance</>."
	},

	buffnextattack =
	{
		name = "Fist Pound", -- This buffs the entire attack, not just until the critical hit. An entire swing will have the buff. Should maybe change to simplify.
		desc = "Pound your fists together to gain <#RED>+{stackspertrigger}% Critical Chance</> until your next <#RED>Critical Hit</>.",
	},

	bananapeel =
	{
		name = "Banana Peel",
		desc = "<#RED>Heals</> for <#RED>{heal} Health</> when eaten.\n\nLeaves behind a <#RED>Banana Peel</> that inflicts <#RED>Knock Down</> on any target that steps on it.\n\nRegain <#RED>1 Banana</> for every <#RED>{damage_til_new_banana} {name.concept_damage}</> dealt.",
	},

	throwstone =
	{
		name = "Throw Stone",
		desc = "Throw a stone <#RED>Projectile</> which deals your <#RED>Weapon {name.concept_damage}</>.",
	},

	-- POLEARM
	polearm_shove =
	{
		name = "Crosscheck",
		desc = "Push an <#RED>Enemy</> away from you, creating space.",
	},

	polearm_vault =
	{
		name = "Pole Vault",
		desc = "Launch yourself over an obstacle or <#RED>Enemy</> to help with positioning.",
	},

	-- SHOTPUT
	shotput_summon =
	{
		name = "Direct Recall", -- Use skill to summon the ball to your hands, which travels quickly horizontally towards you hitting anything in its way
		desc = "Your <#RED>{name.weapon_shotput}</> surges toward you in a straight line, causing <#RED>{name.concept_damage}</> to all targets in its path.",
	},

	shotput_recall =
	{
		name = "Arcing Recall", -- Use skill to summon the ball to your hands, which travels in an arc and can land on any enemies if you don't catch it.
		desc = "Your <#RED>{name.weapon_shotput}</> returns to you in a high arc, causing <#RED>{name.concept_damage}</> to all targets it lands on if not caught.",
	},

	shotput_seek =
	{
		name = "Reverse Recall", -- Use skill to throw yourself towards your ball, tackling anything along the way.
		desc = "Launch yourself toward your <#RED>{name.weapon_shotput}</>, causing <#RED>{name.concept_damage}</> to all targets in your path.",
	},

	shotput_lob =
	{
		name = "Lob", -- Use skill to lob the ball high over opponents' heads.
		desc = "Toss your <#RED>{name.weapon_shotput}</> a long distance, over <#RED>Enemies'</> heads.",
	},

	shotput_slam =
	{
		name = "Dribble", -- Use skill to jump up and slam the ball on the ground, as an attack.
		desc = "Slam your <#RED>{name.weapon_shotput}</> into the ground, knocking nearby <#RED>Enemies</> back.",
	},

	-- HAMMER
	hammer_thump =
	{
		name = "Order in the Court",
		desc = "Pound the head of your <#RED>{name.weapon_hammer}</> into the ground, causing <#RED>Knockback</> to any nearby <#RED>Enemies</>.\n\nHold <#RED>Skill</> to charge.",
	},

	hammer_totem =
	{
		name = "Hazard Idol",
		desc = "Sacrifice <#RED>{healthtocreate} Health</> to summon a <#RED>Hazard Idol</>.\n\n<#RED>Everything</> in a large radius of the <#RED>Idol</> deals <#RED>+{bonusdamagepercent}% {name.concept_damage}</>.\n\nThe Idol <#RED>Heals</> its destroyer for <#RED>{healthtocreate} Health</>.",
	},

	hammer_explodingheavy =
	{
		name = "Unstable Equilibrium",
		desc = "Overcharge your <#RED>{name.weapon_hammer}</> with energy which explodes the next time your <#RED>Heavy Attack</> hits something.",
	},

	-- CANNON
	cannon_butt =
	{
		name = "Battering Ram",
		desc = "Hit an enemy with the butt of your <#RED>{name.weapon_cannon}</>.\n\nOn hit, gain <#RED>1 {name.cannon_ammo}</>.",
	},
	cannon_singlereload =
	{
		name = "Reload One",
		desc = "Reload <#RED>1 {name.cannon_ammo}</>.",
	},

	-- MOBS
	miniboss_yammo =
	{
		name = "Big {name.yammo} Slammo",
		desc = "Perform a punch that inflicts <#RED>Knocked Down</> on <#RED>Enemies</>.\n\nHold to charge a <#BLUE>Focus Hit</>, adding any <#RED>Damage</> received while charging to the total <#RED>Damage</> of your punch.",
	},

	miniboss_floracrane =
	{
		name = "{name.floracrane}'s Divebeak",
		desc = "Leap into the air and divebomb the ground in front of you.\n\nHold to charge, turning your dive into a <#BLUE>Focus Hit</>.",
	},

	miniboss_groak =
	{
		name = "Grody {name.groak} Gulp",
		desc = "<#RED>Vacuum</> all <#RED>Enemies</> standing in front of you in towards yourself.",
	},

	miniboss_gourdo =
	{
		name = "{name.gourdo}'s Community Garden",
		desc = "Channel your inner seedling, restoring <#RED>{heal} Health</> to yourself and all <#RED>Allies</> within a small radius.\n\nRegain <#RED>1 Charge</> for every <#RED>{damage_til_new_stock} {name.concept_damage}</> dealt, up to a maximum of <#RED>3 Charges</>.",
	},

	--BOSSES
	-- MOTHER TREEK
	megatreemon_weaponskill =
	{
		name = "Mother of Methuselah",
		desc = "Summon a line of <#RED>{name.megatreemon} Roots</>.",
	},
}



-- Equipment grants you powers.
STRINGS.ITEMS.POWERS.EQUIPMENT = {
	-- basic
	equipment_basic_head =
	{
		name = "equipment_basic_head",
		desc = "Increase your <#RED>{name.powerdesc_maxhealth}</>.",
	},
	equipment_basic_body =
	{
		name = "equipment_basic_body",
		desc = "Increase your <#RED>{name.powerdesc_maxhealth}</>.",
	},
	equipment_basic_waist =
	{
		name = "equipment_basic_waist",
		desc = "Increase your <#RED>{name.powerdesc_maxhealth}</>.",
	},

	-- cabbageroll
	equipment_cabbageroll_head =
	{
		name = "equipment_cabbageroll_head",
		desc = "Your <#RED>{name.concept_dodge}</> deals a <#RED>Knockback</> hit to <#RED>Enemies</>.", --\nYour <#RED>Dodge</> temporarily increases your <#RED>{name.concept_runspeed}</>.",
	},
	equipment_cabbageroll_body =
	{
		name = "equipment_cabbageroll_body",
		desc = "Your <#RED>{name.concept_dodge}</> is <#RED>Invincible</> for longer.",
		--Your <#BLUE>Focus Attacks</> deal extra <#RED>{name.concept_damage}</>.
	},
	equipment_cabbageroll_waist =
	{
		name = "equipment_cabbageroll_waist",
		desc = "Your <#RED>{name.concept_dodge}</> is faster.",
	},

	-- blarma
	equipment_blarmadillo_head =
	{
		name = "equipment_blarmadillo_head",
		desc = "Take less <#RED>{name.concept_damage}</> from <#RED>Projectiles</>.",
	},
	equipment_blarmadillo_body =
	{
		name = "equipment_blarmadillo_body",
		desc = "Take less <#RED>{name.concept_damage}</> from <#RED>{name_multiple.rot_miniboss}</>.",
	},
	equipment_blarmadillo_waist =
	{
		name = "equipment_blarmadillo_waist",
		desc = "Take less <#RED>{name.concept_damage}</> from <#RED>Traps</>.",
	},

	-- battoad
	equipment_battoad_head =
	{
		name = "equipment_battoad_head",
		desc = "When you gain <#KONJUR>{name.i_konjur}</>, gain more.",
	},
	equipment_battoad_body =
	{
		name = "equipment_battoad_body",
		desc = "When you take <#RED>Damage</>, lose <#KONJUR>{name.i_konjur}</> and <#RED>Heal</> back some of the <#RED>{name.concept_damage}</> taken.",
	},
	equipment_battoad_waist =
	{
		name = "equipment_battoad_waist",
		desc = "Gain <#KONJUR>{name.i_konjur}</> when breaking anything in the environment.", --TODO: come up with strong keyword for "destructible props but NOT traps/windmon projectiles"
	},

	-- battoad
	equipment_windmon_head =
	{
		name = "equipment_windmon_head",
		desc = "When you <#RED>{name.concept_dodge}</>, create a gust of <#RED>Wind</> behind you.",
		variables =
		{
			wind_strength = "Wind Strength"
		}
	},
	equipment_windmon_body =
	{
		name = "equipment_windmon_body",
		desc = "When you <#RED>Perfect {name.concept_dodge}</>, drop a <#RED>{name.windmon} Spikeball</> behind you.",
		variables =
		{
			number_of_balls = "Number of Spikeballs"
		}
	},
	equipment_windmon_waist =
	{
		name = "equipment_windmon_waist",
		desc = "Gain <#RED>Wind Resistance</> while standing still.",
		variables =
		{
			wind_resistance = "Wind Resistance",
		}
	},

	-- gnarlic
	equipment_gnarlic_head =
	{
		name = "equipment_gnarlic_head",
		desc = "Your run becomes an <#RED>{name.concept_attack}</> that deals <#RED>{name.concept_damage}</> based on how fast you are moving.",
	},
	equipment_gnarlic_body =
	{
		name = "equipment_gnarlic_body",
		desc = "Gain bonus <#RED>{name.concept_runspeed}</> for each second you spend running in a single direction.",
	},
	equipment_gnarlic_waist =
	{
		name = "equipment_gnarlic_waist",
		desc = "Your <#RED>{name.concept_dodge}</> travels farther.",
		variables =
		{
			percent_distance_bonus = "{name.concept_dodge} Distance",
		}
	},


	-- groak
	equipment_groak_weapon =
	{
		name = "equipment_gourdo_head",
		desc = "<#RED>Hitstreaks</> decay slower between <#RED>Hits</>.",
		variables =
		{
			time_mult = "Bonus Time",
		},
	},
	equipment_groak_head =
	{
		name = "equipment_groak_head",
		desc = "<#RED>Enemies</> are <#RED>Stunned</> longer by your <#RED>Heavy {name_multiple.concept_attack}</>.",
	},
	equipment_groak_body =
	{
		name = "equipment_groak_body",
		desc = "Your <#RED>Heavy {name_multiple.concept_attack}</> pull <#RED>Enemies</> towards you.",
	},
	equipment_groak_waist =
	{
		name = "equipment_groak_waist",
		desc = "You have a chance of negating the effect of any <#RED>Spore</>.",
		variables =
		{
			chance = "Spore Negation Chance",
		}
	},

	-- yammo
	equipment_yammo_weapon =
	{
		name = "equipment_yammo_weapon",
		desc = "<#RED>Enemies</> you <#RED>Knock Down</> deal <#RED>Damage</> while flying through the air.",
		variables =
		{
			knockdown_distance = "Knock Down Distance",
		},
	},
	equipment_yammo_head =
	{
		name = "equipment_yammo_head",
		desc = "Your <#BLUE>Heavy {name_multiple.concept_focus_hit}</> deal bonus <#RED>{name.concept_damage}</>.",
	},
	equipment_yammo_body =
	{
		name = "equipment_yammo_body",
		desc = "Take less <#RED>{name.concept_damage}</> from <#RED>{name_multiple.rot_boss}</>.",
	},
	equipment_yammo_waist =
	{
		name = "equipment_yammo_waist",
		desc = "Take less <#RED>{name.concept_damage}</> while you're not <#RED>Attacking</>.",
	},
	-- gourdo
	equipment_gourdo_weapon =
	{
		name = "equipment_gourdo_head",
		desc = "When <#RED>Healing</> more than 10 Health, deal that much <#RED>Damage</> in a large radius.",
		variables =
		{
			damage_mult = "Percentage of Heal Dealt",
		},
	},
	equipment_gourdo_head =
	{
		name = "equipment_gourdo_head",
		desc = "When you <#RED>Heal</>, heal more.",
	},
	equipment_gourdo_body =
	{
		name = "equipment_gourdo_body",
		desc = "When you <#RED>Heal</>, heal all <#RED>{name_multiple.concept_ally}</> for a portion.",
	},
	equipment_gourdo_waist =
	{
		name = "equipment_gourdo_waist",
		desc = "<#RED>Heal</> when you enter a new clearing.",
	},
	-- zucco
	equipment_zucco_head =
	{
		name = "equipment_zucco_head",
		desc = "Increase your <#RED>{name.concept_runspeed}</>.",
		variables =
		{
			speed = "{name.concept_runspeed}",
		},
	},
	equipment_zucco_body =
	{
		name = "equipment_zucco_body",
		desc = "Your <#BLUE>{name_multiple.concept_focus_hit}</> deal extra <#RED>{name.concept_damage}</>.",
	},
	equipment_zucco_waist =
	{
		name = "equipment_zucco_waist",
		desc = "{NAME.powerdesc_nopower}",
	},
	-- megatreemon
	equipment_megatreemon_head =
	{
		name = "equipment_megatreemon_head",
		desc = "Deal increased <#RED>{name.concept_damage}</> to all <#RED>Regular {name_multiple.rot}</>.",
	},
	equipment_megatreemon_body =
	{
		name = "equipment_megatreemon_body",
		desc = "Chance to summon a <#RED>Defensive Root</> when hit.",
		variables =
		{
			chance_to_summon = "Summon Chance",
			root_lifetime = "Root Lifetime",
		},
	},
	equipment_megatreemon_waist =
	{
		name = "equipment_megatreemon_waist",
		desc = "{NAME.powerdesc_nopower}",
		variables =
		{
			chance_to_summon = "Summon Chance",
			root_lifetime = "Root Lifetime",
		},
	},

	-- owlitzer
	equipment_owlitzer_head =
	{
		name = "equipment_owlitzer_head",
		desc = "<#RED>{damage_per_stack} {name.concept_damage}</> to <#RED>Regular {name_multiple.rot}</>.",
	},
	equipment_owlitzer_body =
	{
		name = "equipment_owlitzer_body",
		desc = "<#RED>{damage_per_stack} {name.concept_damage}</> to <#RED>Regular {name_multiple.rot}</>.",
	},
	equipment_owlitzer_waist =
	{
		name = "equipment_owlitzer_waist",
		desc = "", -- HELLOWRITER
	},

	--mothball
	equipment_mothball_head =
	{
		name = "equipment_mothball_head",
		desc = "Deal more <#RED>{name.concept_damage}</> when fighting near an <#RED>{name.concept_ally}</>.",
	},
	equipment_mothball_body =
	{
		name = "equipment_mothball_body",
		desc = "Take less <#RED>{name.concept_damage}</> when fighting near an <#RED>{name.concept_ally}</>.",
	},
	equipment_mothball_waist =
	{
		name = "equipment_mothball_waist",
		desc = "Gain more <#RED>Health</> when healing near an <#RED>{name.concept_ally}</>.",
	},

	--eyev
	equipment_eyev_head =
	{
		name = "equipment_eyev_head",
		desc = "When you <#RED>Perfect {name.concept_dodge}</>, your attacker takes increased <#RED>{name.concept_damage}</> for a few seconds.",
		variables =
		{
			debuff_stacks = "Debuff Stacks",
		},
	},
	equipment_eyev_body =
	{
		name = "equipment_eyev_body",
		desc = "When you <#RED>Perfect {name.concept_dodge}</>, gain increased <#RED>{name.powerdesc_critchance}</> for a few seconds.",
	},
	equipment_eyev_waist =
	{
		name = "equipment_eyev_waist",
		desc = "Your <#RED>{name.concept_dodge}</> is faster and moves through objects.",
	},

	--bulbug
	equipment_bulbug_head =
	{
		name = "equipment_bulbug_head",
		desc = "When you break an enemy's <#BLUE>{name.concept_shield}</>, deal <#RED>{name.concept_damage}</> to the target anyway.",
	},

	equipment_bulbug_body =
	{
		name = "equipment_bulbug_body",
		desc = "When you break an enemy's <#BLUE>{name.concept_shield}</>, gain <#BLUE>{name_multiple.concept_shield_seg}</>.",
	},

	equipment_bulbug_waist =
	{
		name = "equipment_bulbug_waist",
		desc = "When you gain <#BLUE>{name.concept_shield}</>, instantly break it and deal <#RED>{name.concept_damage}</> in an area around you.",
	},

	--swarmy
	equipment_swarmy_head =
	{
		name = "equipment_swarmy_head",
		desc = "Increase your <#RED>{name.concept_runspeed}</> when poisoned.",
		variables =
		{
			acid_speed_bonus = "{name.concept_runspeed}"
		}
	},
	equipment_swarmy_body =
	{
		name = "equipment_swarmy_body",
		desc = "Create a Poison Pool on <#RED>Kill</>.",
		variables =
		{
			acid_duration = "Pool Duration"
		}
	},
	equipment_swarmy_waist =
	{
		name = "equipment_swarmy_waist",
		desc = "Your <#RED>{name.concept_dodge}</> is faster when poisoned.",
		variables =
		{
			acid_dodge_bonus = "{name.concept_dodge} Speed Bonus"
		}
	},

	--woworm
	equipment_woworm_head =
	{
		name = "equipment_woworm_head",
		desc = "<#RED>Heal</> for a percent of <#RED>Poison Damage</>.",
		variables =
		{
			heal_percent = "Heal Amount"
		}
	},
	equipment_woworm_body =
	{
		name = "equipment_woworm_body",
		desc = "Leave a Poison Pool when you <#RED>{name.concept_dodge}</>.",
		variables =
		{
			acid_duration = "Pool Duration"
		}
	},
	equipment_woworm_waist =
	{
		name = "equipment_woworm_waist",
		desc = "Take less <#RED>{name.concept_damage}</> when poisoned.",
		variables =
		{
			damage_reduction = "Damage Reduction"
		}
	},

	--slowpoke
	equipment_slowpoke_head =
	{
		name = "equipment_slowpoke_head",
		desc = "Prevent <#RED>Poison Damage</> when health is low.",
		variables =
		{
			low_health = "Health Threshold"
		}
	},
	equipment_slowpoke_body =
	{
		name = "equipment_slowpoke_body",
		desc = "Deal <#RED>Weapon Damage</> in an area when landing on the ground.",
		variables =
		{
			aoe_damage = "Damage"
		}
	},
	equipment_slowpoke_waist =
	{
		name = "equipment_slowpoke_waist",
		desc = "<#RED>Poison</> builds up slower.",
		variables =
		{
			reduction = "Resistance"
		}
	},

	-- floracrane
	equipment_floracrane_weapon =
	{
		name = "equipment_floracrane_weapon",
		desc = "Increased <#RED>{name.powerdesc_critchance}</> while <#RED>Airborne</>.",
	},
	equipment_floracrane_head =
	{
		name = "equipment_floracrane_head",
		desc = "<#RED>Critical Hits</> deal additional <#RED>{name.concept_damage}</>.",
	},
	equipment_floracrane_body =
	{
		name = "equipment_floracrane_body",
		desc = "<#BLUE>{name_multiple.concept_focus_hit}</> have an increased <#RED>{name.powerdesc_critchance}</>.",
	},
	equipment_floracrane_waist =
	{
		name = "equipment_floracrane_waist",
		desc = "<#RED>Skills</> have increased <#RED>{name.powerdesc_critchance}</>.",
	},

	equipment_bandicoot_head =
	{
		name = "equipment_bandicoot_head",
		desc = "Your <#RED>{name_multiple.concept_attack}</> have a chance to <#RED>{name.concept_multistrike}</>.",
	},
	equipment_bandicoot_body =
	{
		name = "equipment_bandicoot_body",
		desc = "Your <#RED>{name_multiple.concept_attack}</> have a chance to <#RED>{name.concept_multistrike}</>.",
	},
	equipment_bandicoot_waist =
	{
		name = "equipment_bandicoot_waist",
		desc = "{NAME.powerdesc_nopower}",
	},

	equipment_cannon_pierce_focus =
	{
		name = "Piercing Focus Shots",
		desc = "<#BLUE>Focus</> shots pierce through <#RED>Enemies</>.",
	},
	equipment_cannon_light_pierce_focus =
	{
		name = "Piercing Focus Lights",
		desc = "<#BLUE>Focus</> <#RED>Light Attacks</> pierce through <#RED>Enemies</>.",
	},
	equipment_cannon_heavy_pierce_focus =
	{
		name = "Piercing Focus Heavies",
		desc = "<#BLUE>Focus</> <#RED>Heavy Attacks</> pierce through <#RED>Enemies</>.",
	},

	equipment_cannon_clusterbomb =
	{
		name = "Cluster Shot",
		desc = "<#RED>Mortar Shot</> is replaced with <#RED>Cluster Shot</> that shoots <#RED>1 {name.cannon_ammo}</> and bursts into clusters.",
		variables =
		{
			clusters = "Clusters",
		},
	},

	equipment_shotput_explode_on_land =
	{
		name = "Exploding {name.weapon_shotput}",
		desc = "<#RED>Explodes</> on landing, dealing a percentage of your <#RED>Weapon Damage</>.",
		variables =
		{
			percent_of_weapondamage = "Percentage of Weapon Damage",
		},
	},

	equipment_shotput_rebounds_to_owner =
	{
		name = "Returning {name.weapon_shotput}",
		desc = "<#RED>Rebounds</> to its owner. Deals bonus <#BLUE>Focus Damage</>.",
		variables =
		{
			focus_damage_mult = "Bonus Focus Damage",
		},
	},


	equipment_speed_bonus_after_dodge_cancel =
	{
		name = "",
		desc = "Gain <#RED>{name.concept_runspeed}</> after <#RED>Dodge Canceling</>.",
		variables =
		{
			speed = "{name.concept_runspeed}",
			time = "Seconds",
		},
	},

	-- Hammer
	equipment_hammer_charged_hits_again =
	{
		name = "",
		desc = "Fully charged <#RED>Attacks</> hit multiple times.",
		variables =
		{
			extra_hits = "Extra Hits",
			damage = "Extra Hit Damage",
		},
	},

	equipment_hammer_charged_golfswing_hits_again =
	{
		name = "",
		desc = "Fully charged <#RED>Golf Swing</> (<p bind='Controls.Digital.DODGE'> <p img='images/ui_ftf/arrow_right.tex' scale=0.4> hold Backwards <p bind='Controls.Digital.ATTACK_HEAVY'>) hits multiple times.",
		variables =
		{
			extra_hits = "Extra Hits",
			damage = "Extra Hit Damage",
		},
	},

	-- Polearm
	-- I think these names may actually never show up anywhere, only the DESCs
	equipment_polearm_infinite_multithrust =
	{
		name = "Hundred Spear Poke",
		desc = "Mash <#RED>Heavy Attack</> during the Multi-thrust (<p bind='Controls.Digital.ATTACK_LIGHT'> <p bind='Controls.Digital.ATTACK_LIGHT'> <p bind='Controls.Digital.ATTACK_LIGHT'> <p bind='Controls.Digital.ATTACK_HEAVY'>) attack to keep attacking.",
	},

	equipment_polearm_extended_multithrust =
	{
		name = "Hundred Spear Poke",
		desc = "Hold <#RED>Heavy Attack</> to extend the length of your <#RED>Multi-thrust</> (<p bind='Controls.Digital.ATTACK_LIGHT'> <p bind='Controls.Digital.ATTACK_LIGHT'> <p bind='Controls.Digital.ATTACK_LIGHT'> <p bind='Controls.Digital.ATTACK_HEAVY'>) attack.",
		variables =
		{
			additional_loops = "Additional Loops",
		},
	},

	equipment_polearm_extended_drill =
	{
		name = "Psycho Crusher",
		desc = "Hold <#RED>Light Attack</> to extend the length of your <#RED>Spear Drill</> (<p bind='Controls.Digital.DODGE'> <p bind='Controls.Digital.ATTACK_LIGHT'>) attack.",
		variables =
		{
			additional_loops = "Additional Loops",
		},
	},

	equipment_polearm_long_range =
	{
		name = "Long {name.weapon_polearm}",
		desc = "Long range. <#BLUE>Focus Attacks</> do more <#RED>Damage</>, but <#RED>Normal Attacks</> do less.",
		variables =
		{
			normal_damage_reduction = "Reduced Normal Damage",
			focus_damage_bonus = "Bonus Focus Damage",
		},
	},
}




-- Hearts are actually powers.
STRINGS.ITEMS.POWERS.HEART =
{
	heart_megatreemon =
	{
		name = "Aspect of {name.megatreemon}",
		desc = "Increase your <#RED>{name.powerdesc_maxhealth}</>.",
	},
	heart_owlitzer =
	{
		name = "Aspect of {name.owlitzer}",
		desc = "When you enter a new clearing, <#RED>Heal</>."
	},
	heart_bandicoot =
	{
		name = "Aspect of {name.bandicoot}",
		desc = "Your <#RED>{name.concept_dodge}</> is faster.",
	},
	heart_thatcher =
	{
		name = "Aspect of {name.thatcher}",
		desc = "Your <#RED>{name.concept_dodge}</> travels farther.",
		variables =
		{
			percent_distance_bonus = "{name.concept_dodge} Distance",
		},
	},
}
