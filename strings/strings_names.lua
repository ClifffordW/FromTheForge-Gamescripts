local loc = require "questral.util.loc"

--[[

	HOW TO:
	Any time a character/enemy/item/concept name is used in a player facing string, use these strings with the name loc macro to programmatically insert the name into the string.
	This'll keep the formatting of names consistent across the game, and allow items and objects to be renamed across the entire project easily by changing the name in this file.
	For each entry added to the STRINGS.NAMES section, a matching entry will have to be added to STRING_METADATA.NAMES_PLURAL if its possible for that term to be pluralized.
	(Plurals aren't autogenerated bc they may grammatically vary in spelling)

	For a singular name, type {name.example}
		eg {name.yammo} = Yammo

	For a plural name, type {name_multiple.example}
		eg {name_multiple.yammo} = Yammos

	For a capitalized singular name, type {NAME.example}
		eg {NAME.yammo} = YAMMO

	For a capitalized plural name, type {NAME_MULTIPLE.example}
		eg {NAME_MULTIPLE.yammo} = YAMMOS

	When used in a game string, it'll look something like this
		"The orange rind of a <#RED>{name.yammo}</>."

	Note that the loc macro doesn't apply colour formatting, so <#RED> and <#BLUE> will still need to be added to the string where the macro is used if the name needs to be coloured.

--]]
STRINGS.NAMES =
{
	--Expedition Name
	foxtails = "Foxtail",

	--Hunters
	hunter = "Hunter",
	species_canine = "Mammimal",
	species_mer = "Amphibee",
	species_ogre =  "Ogre",

	--Town NPCs (no plural form)
	npc_scout = "Flitt", --they/them
	npc_dojo_master = "Toot", --he/him
	npc_apothecary = "Kuma", --she/her
	npc_refiner = "Lottie", --she/her
	npc_blacksmith = "Hamish", --he/him
	npc_armorsmith = "Berna", --she/her
	npc_cook = "Glorabelle",  --she/her
	npc_lunn = "Lunn", --he/him, glorabelle's tool

	dojo = "TEMP NAME",
	dojo_cough = "<#KONJUR><i><z 0.8>(cough cough)</z></i></>",
	pop_quiz = "<#LEGENDARY>P</><#RED>o</><#KONJUR>p</> <#BLUE>Q</><#HEALTH>u</><#LEGENDARY>i</><#RED>z</>",

	--Dungeon NPCs (no plural form)
	npc_konjurist = "Alki", --they/them
	npc_potionmaker_dungeon = "Doc Hoggins", --he/him
	npc_doc_firstname = "Doc",
	npc_doc_lastname = "Hoggins",

	npc_market_merchant = "Alphonse", --he/him

	shop_potion = "Doc Hoggins", --he/him
	shop_powerupgrade = "Alki", --they/them
	shop_armorsmith = "Alphonse", --he/him
	shop_magpie = "Nimble", --cute/bird (she/her tho)

	--Reynard, Godric, Cato, Oswald, Filbert
	npc_grandpa = "Reynard", --flitt's grandpa (might change)
	flitt_lastname = "Mulligan",

	--NPC Jobs
	job_scout = "Scout",
	job_blacksmith = "Blacksmith",
	job_armorsmith = "Armourer",
	job_apothecary = "Apothecary",
	job_refiner = "Researcher",
	job_cook = "Cook",
	job_dojo = "Battlemaster",
	job_konjurist = "Teffrite",

	research = "Research", --primarily used on the mosnter research page

	--Weight Classes
	light_weight = "Agile",
	medium_weight = "Balance",
	heavy_weight = "Power",

	--Job Stations
	station_scout = "Scout's Cartography Desk",
	station_blacksmith = "Blacksmith's Forge",
	station_gems = "Gemcutter's Table", --future note for me, the gemcutter refers to themselves as a "Lapidarist" and is offended when called a "Gemcutter"
	station_armorsmith = "Armourer's Workshop",
	station_apothecary = "Apothecary's Cauldron",
	station_refiner = "Researcher's Equipment",
	station_cook = "Cook's Kitchen",
	station_dojo = "Battlemaster's Pit", --meet me in the PIT
	station_marketroom_shop = "Market Caravan",

	elite_prefix = "Imbued",
	miniboss_prefix = "Greater",

	--General Monster Name
	rot = "Rot",
	rot_miniboss = "Rot Miniboss",
	rot_boss = "Boss Rot",

	--Biomes (used to refer to the groupings of dungeons, primarily for the exploration screen, no plural)
	forest = "Forest",
	tundra = "Tundra",
	swamp = "Bog",

	--Dungeons/Individual Locations (no plural)
	brundle = "Camp",
	treemon_forest = "Great Rotwood Forest",
	owlitzer_forest = "Nocturne Grove",
	bandi_swamp = "Blisterbane Bog",
	thatcher_swamp = "The Molded Grave",
	sedament_tundra = "???", --KRIS HELLOWRITER

	--Bosses
	arak = "Arak",
	bandicoot = "Enigmox",
	bonejaw = "Ossep",
	magmadillo = "Magmadillo",
	owlitzer = "Owlitzer",
	quetz = "Quetzalcoatl",
	rotwood = "Rotwood",
	thatcher = "Swarm",
	megatreemon = "Mother Treek",

	--Small monsters
	battoad = "Ribbat",
	battoad_elite = "{name.elite_prefix} Ribbat",
	blarmadillo = "Rillo",
	blarmadillo_elite = "{name.elite_prefix} Rillo",
	bulbug = "Bulbug",
	bulbug_elite = "{name.elite_prefix} Bulbug",
	beets = "Beets",
	beets_elite = "{name.elite_prefix} Beets",
	cabbageroll = "Bulbin",
	cabbageroll_elite = "{name.elite_prefix} Bulbin",
	gnarlic = "Gnarlic",
	gnarlic_elite = "{name.elite_prefix} Gnarlic",

	eyev = "Iriss",
	eyev_elite = "{name.elite_prefix} Iriss",
	mothball = "Mothball",
	mothball_elite = "{name.elite_prefix} Mothball",
	mothball_teen = "Greater Mothball",
	mothball_teen_elite = "{name.elite_prefix} Greater Mothball",
	mossquito = "Mossquito",
	mossquito_elite = "{name.elite_prefix} Mossquito",
	slowpoke = "Snortoise",
	slowpoke_elite = "{name.elite_prefix} Snortoise",
	totolili = "Totolilli",
	totolili_elite = "{name.elite_prefix} Totolilli",
	woworm = "Wollusk",
	woworm_elite = "{name.elite_prefix} Wollusk",
	swarmy = "Gloop",
	swarmy_elite = "{name.elite_prefix} Gloop",

	bunippy = "Bunippy",
	bunippy_elite = "{name.elite_prefix} Bunippy",
	meowl = "Meowl",
	meowl_elite = "{name.elite_prefix} Meowl",
	antleer = "Antleer",
	antleer_elite = "{name.elite_prefix} Antleer",

	-- Big monsters
	yammo = "Yammo",
	yammo_elite = "{name.elite_prefix} Yammo",
	yammo_miniboss = "{name.miniboss_prefix} Yammo",
	zucco = "Zucco",
	zucco_elite = "{name.elite_prefix} Zucco",
	gourdo = "Gourdo",
	gourdo_elite = "{name.elite_prefix} Gourdo",
	gourdo_miniboss = "{name.miniboss_prefix} Gourdo",

	floracrane = "Floracrane",
	floracrane_elite = "{name.elite_prefix} Floracrane",
	floracrane_miniboss = "{name.miniboss_prefix} Floracrane",
	groak = "Groak",
	groak_elite = "{name.elite_prefix} Groak",
	groak_miniboss = "{name.miniboss_prefix} Groak",
	seeker = "Seeker",
	seeker_elite = "{name.elite_prefix} Seeker",
	crystroll = "Crystroll",
	crystroll_elite = "{name.elite_prefix} Crystroll",
	crystroll_miniboss = "{name.miniboss_prefix} Crystroll",

	-- Stationary
	treemon = "Treek",
	treemon_elite = "{name.elite_prefix} Treek",
	trap_weed_spikes = "Spike Plant",
	trap_bomb_pinecone = "Paincone",
	trap_zucco = "Zucco Trap",

	sporemon = "Peashooter",
	sporemon_elite = "{name.elite_prefix} Peashooter",

	windmon = "Gustree",
	windmon_elite = "{name.elite_prefix} Gustree",

	npc_specialeventhost = "????",

	-- Key Props
	damselfly = "Damselfly",
	town_grid_cryst = "Wellspring",
	dgn_grid_cryst = "Spring Port", --STRING HOOKUP
	dgn_resource_converter = "Spring Port", --STRING HOOKUP

	--Currency
	konjur = "Teffra",
	i_konjur = "<p img='images/ui_ftf_icons/konjur.tex' rpad=1>Teffra", --konjur with icon. rpad inserts a space that won't split image from word.
	glitz = "Glitz",
	cosmetic = "Cosmetic",

	--Consumeable Categories
	lunchbox = "Lunch Box",

	-- Resources
	potion = "Potion",
	tonic = "{name.konjur} Pearl",
	material = "Material",
	konjur_soul_lesser = "Corestone",
	i_konjur_soul_lesser = "<p img='images/ui_ftf_icons/lesser_soul.tex' rpad=1>Corestone",
	konjur_soul_greater = "Metastone",
	konjur_heart = "Heartstone",
	i_konjur_heart = "<p img='images/ui_ftf_icons/konjur_heart.tex' rpad=1>Heartstone",
	boss_heart = "Heartstone",
	i_boss_heart = "<p img='images/ui_ftf_icons/konjur_heart.tex' rpad=1>Heartstone",
	gem = "Gem", --is excitement, oo-oo-oo gem!

	-- Generic names for weapon categories
	weapon_hammer = "Hammer",
	weapon_polearm = "Spear",
	weapon_shotput = "Striker",
	weapon_cannon = "Cannon",
	weapon_greatsword = "Cleaver",

	-- Ammunition
	cannon_ammo = "Cannonball",

	--Combat Concepts
	concept_relic = "Power",
	concept_skill = "Skill",
	concept_damage = "Damage",
	concept_attack = "Attack",
	concept_focus_hit = "Focus Hit",
	concept_critical = "Critical",
	concept_dodge = "Dodge",
	concept_runspeed = "Runspeed",
	concept_ally = "Ally",
	concept_revive = "Revive",
	concept_shield = "Shield",
	concept_shield_seg = "Shield Segment",
	concept_multistrike = "Multistrike",

	--Power/Equipment Effect Descriptions
	powerdesc_double = "double",
	powerdesc_triple = "triple",
	powerdesc_modifier = "Modifier",
	powerdesc_nopower = "No Power",


	-- Power variable names. Use the end of the name as your variable name and
	-- you don't need to include strings for this variable (name the variable
	-- damage_bonus to use powerdesc_damage_bonus). You can remap variable
	-- names in see GetStandardPowerDescVarPrettyName in itemforge.lua or
	-- create custom ones in strings_items. Use DebugMissingAssets to find
	-- missing strings.
	powerdesc_damage_bonus = "Damage Bonus",
	powerdesc_focus_damage_bonus = "{name.concept_focus_hit} Damage Bonus",
	powerdesc_weapon_damage_bonus = "Weapon Damage Bonus",
	powerdesc_damage_reduction = "Damage Resistance",
	powerdesc_multistrikechance = "Multistrike Chance",
	powerdesc_critchance = "Critical Hit Chance",
	powerdesc_critdamage = "Critical Damage Bonus",
	powerdesc_speed_bonus = "Runspeed Bonus",
	powerdesc_roll_speed_bonus = "{name.concept_dodge} Speed Bonus",
	powerdesc_hitstunbonus = "Hitstun Bonus",
	powerdesc_konjur_bonus = "{name.i_konjur} Bonus",
	powerdesc_konjur_cost = "{name.i_konjur} Cost",
	powerdesc_pullstrength = "Vacuum",
	powerdesc_seconds = "Duration (Seconds)",
	powerdesc_shield_segments = "{name.concept_shield} Segments", -- Can't use name_multiple from NAMES.
	powerdesc_invincibilityduration = "Invincibility Duration",

	powerdesc_maxhealth = "Maximum Health", --how much health you have total
	powerdesc_heal_bonus = "Healing Bonus", --how much you heal
	powerdesc_healingprocbonus = "Bonus Heal Chance", --number of times you heal
	powerdesc_shared_heal = "Heal Share", --how much of your healing you share with allies
	powerdesc_heal_on_enter = "Heal on Enter", --how much you heal when entering a new room

	dungeon_room = "Encounter",
	run = "Hunt",
	ascension = "Frenzy",

	basic = "Basic", -- starting equipment
}

-- Use these in *quests* with the * plurality markup (see loc.format()):
--   "Go kill {count} {count*{name_plurality.yammo}} for me."
-- Or in item descriptions and other strings where the count is constant:
--   "He loved {name_multiple.arak}."
--
-- You don't *have* to specify a plural version for everything in
-- STRINGS.NAMES. Only need the ones we use with {name_multiple.blah} or
-- {name_plurality.blah}. However, all entries here must have a matching
-- entry in STRINGS.NAMES.
--
-- !!! STRING_METADATA table is only for loc and does not exist at runtime !!!
STRING_METADATA.NAMES_PLURAL =
{
	--Expedition Name
	foxtails = "Foxtails",

	--NPC Jobs
	job_scout = "Scouts",
	job_blacksmith = "Blacksmiths",
	job_armorsmith = "Armourers",
	job_apothecary = "Apothecaries",
	job_refiner = "Researchers",
	job_cook = "Cooks",
	job_dojo = "Battlemasters",
	job_konjurist = "Teffrites",

	--General Monster Name
	rot = "Rots",
	rot_miniboss = "Rot Minibosses",
	rot_boss = "Boss Rots",

	--Hunters
	hunter = "Hunters",
	species_canine = "Mammimals",
	species_mer = "Amphibees",
	species_ogre =  "Ogres",

	-- Bosses
	arak = "Araks",
	bandicoot = "Enigmoxes",
	bonejaw = "Ossepi",
	magmadillo = "Magmadillos",
	owlitzer = "Owlitzers",
	quetz = "Quetzalcoatl",
	rotwood = "Rotwoods",
	thatcher = "Shredders",
	megatreemon = "Mother Treeks",

	--Small monsters
	battoad = "Ribbats",
	battoad_elite = "{name.elite_prefix} Ribbats",
	blarmadillo = "Rillos",
	blarmadillo_elite = "{name.elite_prefix} Rillos",
	bulbug = "Bulbugs",
	bulbug_elite = "{name.elite_prefix} Bulbugs",
	beets = "Beetses",
	beets_elite = "{name.elite_prefix} Beetses",
	cabbageroll = "Bulbins",
	cabbageroll_elite = "{name.elite_prefix} Bulbins",
	gnarlic = "Gnarlics",
	gnarlic_elite = "{name.elite_prefix} Gnarlics",

	eyev = "Irisses",
	eyev_elite = "{name.elite_prefix} Irisses",
	mothball = "Mothballs",
	mothball_elite = "{name.elite_prefix} Mothballs",
	mothball_teen = "Greater Mothballs",
	mothball_teen_elite = "{name.elite_prefix} Greater Mothballs",
	mossquito = "Mossquitoes",
	mossquito_elite = "{name.elite_prefix} Mossquitoes",
	slowpoke = "Snortoises",
	slowpoke_elite = "{name.elite_prefix} Snortoise",
	totolili = "Totolillies",
	totolili_elite = "{name.elite_prefix} Totolillies",
	woworm = "Wollusks",
	woworm_elite = "{name.elite_prefix} Wollusks",
	swarmy = "Gloops",
	swarmy_elite = "{name.elite_prefix} Gloops",

	-- Big monsters
	yammo = "Yammos",
	yammo_elite = "{name.miniboss_prefix} Yammos",
	zucco = "Zuccos",
	zucco_elite = "{name.miniboss_prefix} Zuccos",
	gourdo = "Gourdos",
	gourdo_elite = "{name.miniboss_prefix} Gourdos",

	floracrane = "Floracranes",
	floracrane_elite = "{name.miniboss_prefix} Floracranes",
	groak = "Groaks",
	groak_elite = "{name.miniboss_prefix} Groaks",
	seeker = "Seekers",
	seeker_elite = "{name.miniboss_prefix} Seekers",

	-- Stationary
	treemon = "Treeks",
	treemon_elite = "{name.elite_prefix} Treeks",
	trap_weed_spikes = "Spike Plants",
	trap_bomb_pinecone = "Paincones",
	trap_zucco = "Zucco Traps",

	sporemon = "Peashooters",
	sporemon_elite = "{name.elite_prefix} Peashooters",

	windmon = "Gustrees",
	windmon_elite = "{name.elite_prefix} Gustrees",

	--Currency
	konjur = "Teffra",
	glitz = "Glitz",
	cosmetic = "Cosmetics",

	--Consumeable Categories
	lunchbox = "Lunch Boxes",

	--Resources and Consumables
	potion = "Potions",
	tonic = "{name.konjur} Pearls",
	gem = "Gems",
	material = "Materials",
	konjur_soul_lesser = "Corestones",
	konjur_soul_greater = "Metastones",
	konjur_heart = "Heartstones",
	i_konjur_heart = "<p img='images/ui_ftf_icons/konjur_heart.tex' rpad=1>Heartstones",
	boss_heart = "Heartstones",
	boss_heart = "<p img='images/ui_ftf_icons/konjur_heart.tex' rpad=1>Heartstones",


	-- Generic names for weapon categories
	weapon_hammer = "Hammers",
	weapon_polearm = "Spears",
	weapon_shotput = "Strikers",
	weapon_cannon = "Cannons",
	weapon_greatsword = "Cleavers",

	-- Ammunition
	cannon_ammo = "Cannonballs",

	--Combat Concepts (note that if the context requires punctuation these can't be used and have to be hardcoded, ie Focus Hit's)
	concept_relic = "Powers",
	concept_skill = "Skills",
	concept_damage = "Damages",
	concept_attack = "Attacks",
	concept_focus_hit = "Focus Hits",
	concept_critical = "Criticals",
	concept_dodge = "Dodges",
	concept_ally = "Allies",
	concept_revive = "Revives",
	concept_shield = "Shields",
	concept_shield_seg = "Shield Segments",
	concept_multistrike = "Multistrikes",

	dungeon_room = "Encounters",
	run = "Expeditions",

	-- Key Props
	town_grid_cryst = "Wellsprings",
}

local function Validate()
	for key,val in pairs(STRINGS.NAMES) do
		dbassert(key:find(loc.name_replacement_pattern), "Table keys must be lowercase letters, numbers, or underscore (same should go for prefab names).")
	end
	return true
end
dbassert(Validate())


STRINGS.TITLE_CARDS = {
	-- These must be short because they're only displayed for a short time and in a small space.
	-- Include TITLE to override the name from STRINGS.NAMES.
	megatreemon = {
		LOWERTHIRD = "Rotten Heart of the Forest",
	},
	yammo = {
		-- Remove if we stop using yammo for miniboss.
		LOWERTHIRD = "Big, yellow, and doesn't mean well in the least",
	},
	yammo_miniboss = {
		LOWERTHIRD = "Menace of the Woods",
	},
	floracrane_miniboss = {
		LOWERTHIRD = "Highest in the pecking order"
	},
	gourdo_miniboss = {
		LOWERTHIRD = "Gourd big or go home"
	},
	groak_miniboss = {
		LOWERTHIRD = "Big mouth. Bigger temper"
	},
	bandicoot = {
		LOWERTHIRD = "The Illusory Vixen"
	},
	owlitzer = {
		LOWERTHIRD = "Mother of Darkness"
	},
	thatcher = {
		LOWERTHIRD = "The Orphaned Hivemind"
	},
	npc_armorsmith = {
		LOWERTHIRD = "{name.npc_armorsmith} joined your camp!"
	},
	npc_blacksmith = {
		LOWERTHIRD = "{name.npc_blacksmith} joined your camp!"
	},
	npc_cook = {
		LOWERTHIRD = "{name.npc_cook} joined your camp!"
	},
	npc_apothecary = {
		LOWERTHIRD = "{name.npc_apothecary} joined your camp!"
	},
	npc_refiner = {
		LOWERTHIRD = "{name.npc_refiner} joined your camp!"
	},
	npc_dojo_master = {
		LOWERTHIRD = "{name.npc_dojo_master} joined your camp!"
	},
}

