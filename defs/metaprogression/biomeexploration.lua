local MetaProgress = require "defs.metaprogression.metaprogress"
local Constructable = require "defs.constructable"
local Cosmetic = require "defs.cosmetics.cosmetics"
local Power = require"defs.powers"
local Consumable = require"defs.consumable"

function MetaProgress.AddBiomeExploration(id, data)
	-- add tags? (biome name for example?)
	-- define exp curve?

	-- Right now, completing one run gives 225 EXP by default

	-- Die at Miniboss: 75XP
	-- Die at Boss: 175XP
	-- Clear Boss: 225XP

	-- Clearing Miniboss adds +25
	-- Clearing Boss adds +50
	-- Total = 150 + 25 + 50 = 225 for one completed run

	-- Adding 1 corestone = 100 exp

	-- NEXTFEST 2024: Aim to have a few full runs between each unlock.
	data.base_exp = TUNING.BIOME_LEVEL_EXPERIENCE
	data.exp_growth = TUNING.BIOME_LEVEL_EXPERIENCE_GROWN

	MetaProgress.AddProgression(MetaProgress.Slots.BIOME_EXPLORATION, id, data)
	-- body
end

MetaProgress.AddProgressionType("BIOME_EXPLORATION")

MetaProgress.AddBiomeExploration("treemon_forest",
{
	-- NOTE: Players will be unlocking these through either Dungeon 1 or Dungeon 2
	endless_reward = MetaProgress.Reward(Consumable, Consumable.Slots.MATERIALS, "konjur_soul_lesser", TUNING.BIOME_EXPLORATION.CORESTONE_REWARDS),
	rewards =
	{
		MetaProgress.RewardGroup("focus_powers", {
			-- Some focus stuff and some general powers
			MetaProgress.Reward(Power, Power.Slots.PLAYER, "salted_wounds"),
			MetaProgress.Reward(Power, Power.Slots.PLAYER, "heal_on_focus_kill"),
			MetaProgress.Reward(Power, Power.Slots.PLAYER, "risk_reward"),
			MetaProgress.Reward(Power, Power.Slots.PLAYER, "crit_knockdown"),
		}),

		MetaProgress.RewardGroup("treemon_forest_decor", {
			-- Set of decor props 
			-- basic set
			MetaProgress.Reward(Constructable, Constructable.Slots.STRUCTURES, "bench_basic"),
			MetaProgress.Reward(Constructable, Constructable.Slots.STRUCTURES, "chair_basic"),
			MetaProgress.Reward(Constructable, Constructable.Slots.STRUCTURES, "lamp_basic"),
			MetaProgress.Reward(Constructable, Constructable.Slots.STRUCTURES, "outdoor_seating_basic"),
			MetaProgress.Reward(Constructable, Constructable.Slots.STRUCTURES, "stool_outdoor_seating_basic"),
		}),

		MetaProgress.RewardGroup("hitstreak_powers", {
			-- Stuff that starts to make it easier to build high hitstreaks, and pays off on it.
			MetaProgress.Reward(Power, Power.Slots.PLAYER, "battle_fame"),
			MetaProgress.Reward(Power, Power.Slots.PLAYER, "attack_dice"),
			MetaProgress.Reward(Power, Power.Slots.PLAYER, "no_pushback"),
			MetaProgress.Reward(Power, Power.Slots.PLAYER, "increased_hitstun"),
		}),

		MetaProgress.RewardGroup("treemon_forest_decor_2", {
			-- Set of decor props 
			MetaProgress.Reward(Constructable, Constructable.Slots.DECOR, "pergola"),

			--treemon forest set
			MetaProgress.Reward(Constructable, Constructable.Slots.STRUCTURES, "bench_forest_1"),
			MetaProgress.Reward(Constructable, Constructable.Slots.STRUCTURES, "chair_forest_1"),
			MetaProgress.Reward(Constructable, Constructable.Slots.STRUCTURES, "lamp_forest_1"),
			
		}),
		
		MetaProgress.RewardGroup("treemon_forest_exploration", {
			-- Title reward for exploring the biome
			MetaProgress.Reward(Constructable, Constructable.Slots.STRUCTURES, "bed_forest_1"),
			MetaProgress.Reward(Constructable, Constructable.Slots.STRUCTURES, "outdoor_seating_forest_1"),
			MetaProgress.Reward(Constructable, Constructable.Slots.STRUCTURES, "stool_outdoor_seating_forest_1"),
			MetaProgress.Reward(Cosmetic, Cosmetic.Slots.PLAYER_TITLE, "bushwhacker"),
		}),
	},
})

MetaProgress.AddBiomeExploration("owlitzer_forest",
{
	endless_reward = MetaProgress.Reward(Consumable, Consumable.Slots.MATERIALS, "konjur_soul_lesser", TUNING.BIOME_EXPLORATION.CORESTONE_REWARDS),
	rewards =
	{
		MetaProgress.RewardGroup("critchance_1_powers", {
			-- Stuff that starts to give you more critical chance, and pays off critical chance. Easy options.
			-- Capitalizes off of the hitstreak they learned to develop in the previous batch.
			MetaProgress.Reward(Power, Power.Slots.PLAYER, "lasting_power"),
			MetaProgress.Reward(Power, Power.Slots.PLAYER, "feedback_loop"),
			MetaProgress.Reward(Power, Power.Slots.PLAYER, "crit_movespeed"),
			MetaProgress.Reward(Power, Power.Slots.PLAYER, "sting_like_a_bee"),
		}),

		MetaProgress.RewardGroup("owlitzer_forest_decor", {
			-- Set of decor props
			MetaProgress.Reward(Constructable, Constructable.Slots.STRUCTURES, "wood_wooden_cart"),
			MetaProgress.Reward(Constructable, Constructable.Slots.STRUCTURES, "straw_wooden_cart"),
			MetaProgress.Reward(Constructable, Constructable.Slots.STRUCTURES, "fence_stone"),

			MetaProgress.Reward(Constructable, Constructable.Slots.DECOR, "well"),
			MetaProgress.Reward(Constructable, Constructable.Slots.DECOR, "town_flower_coralbell"),
		}),

		MetaProgress.RewardGroup("critproc_1_powers", {
			MetaProgress.Reward(Power, Power.Slots.PLAYER, "carefully_critical"),
			MetaProgress.Reward(Power, Power.Slots.PLAYER, "advantage"),
			MetaProgress.Reward(Power, Power.Slots.PLAYER, "konjur_on_crit"),
			MetaProgress.Reward(Power, Power.Slots.PLAYER, "analytical"),
		}),

		MetaProgress.RewardGroup("owlitzer_forest_decor", {
			-- Set of decor props
			MetaProgress.Reward(Constructable, Constructable.Slots.STRUCTURES, "bench_forest_2"),
			MetaProgress.Reward(Constructable, Constructable.Slots.STRUCTURES, "chair_forest_2"),
			MetaProgress.Reward(Constructable, Constructable.Slots.STRUCTURES, "lamp_forest_2"),
		}),

		MetaProgress.RewardGroup("owlitzer_forest_exploration", {
			-- Title reward for exploring the biome
			MetaProgress.Reward(Constructable, Constructable.Slots.STRUCTURES, "bed_forest_2"),
			MetaProgress.Reward(Constructable, Constructable.Slots.STRUCTURES, "outdoor_seating_forest_2"),
			MetaProgress.Reward(Constructable, Constructable.Slots.STRUCTURES, "stool_outdoor_seating_forest_2"),
			MetaProgress.Reward(Cosmetic, Cosmetic.Slots.PLAYER_TITLE, "duskfarer"),
		}),
	},
})

MetaProgress.AddBiomeExploration("bandi_swamp",
{
	endless_reward = MetaProgress.Reward(Consumable, Consumable.Slots.MATERIALS, "konjur_soul_lesser", TUNING.BIOME_EXPLORATION.CORESTONE_REWARDS),
	rewards =
	{
		MetaProgress.RewardGroup("weaponry_powers", {
			-- Stuff that starts to make it easier to build high hitstreaks, and pays off on it.
			MetaProgress.Reward(Power, Power.Slots.PLAYER, "fractured_weaponry"),
			MetaProgress.Reward(Power, Power.Slots.PLAYER, "precision_weaponry"),
			MetaProgress.Reward(Power, Power.Slots.PLAYER, "weighted_weaponry"),
		}),

		-- This is too many rewards in this group
		MetaProgress.RewardGroup("hitstreak_2_powers", {
			MetaProgress.Reward(Power, Power.Slots.PLAYER, "streaking"),
			MetaProgress.Reward(Power, Power.Slots.PLAYER, "combo_wombo"),
			MetaProgress.Reward(Power, Power.Slots.PLAYER, "crit_streak"),
		}),

		MetaProgress.RewardGroup("bandi_swamp_decor", {
			-- Set of decor props
			MetaProgress.Reward(Constructable, Constructable.Slots.STRUCTURES, "rugged_weapon_rack"),
			MetaProgress.Reward(Constructable, Constructable.Slots.STRUCTURES, "rustic_weapon_rack"),
			MetaProgress.Reward(Constructable, Constructable.Slots.STRUCTURES, "hammock_basic"),

			MetaProgress.Reward(Constructable, Constructable.Slots.DECOR, "basket"),
		}),

		MetaProgress.RewardGroup("power_modifiers", {
			MetaProgress.Reward(Power, Power.Slots.PLAYER, "pick_of_the_litter"),
			MetaProgress.Reward(Power, Power.Slots.PLAYER, "free_upgrade"),
			MetaProgress.Reward(Power, Power.Slots.PLAYER, "snowball_effect"),
		}),

		MetaProgress.RewardGroup("bandi_swamp_decor", {
			-- Set of decor props
			MetaProgress.Reward(Constructable, Constructable.Slots.STRUCTURES, "bench_swamp_1"),
			MetaProgress.Reward(Constructable, Constructable.Slots.STRUCTURES, "chair_swamp_1"),
			MetaProgress.Reward(Constructable, Constructable.Slots.STRUCTURES, "lamp_swamp_1"),
		}),
		
		MetaProgress.RewardGroup("bandi_swamp_exploration", {
			-- Title reward for exploring the biome
			MetaProgress.Reward(Constructable, Constructable.Slots.STRUCTURES, "bed_swamp_1"),
			MetaProgress.Reward(Constructable, Constructable.Slots.STRUCTURES, "outdoor_seating_swamp_1"),
			MetaProgress.Reward(Constructable, Constructable.Slots.STRUCTURES, "stool_outdoor_seating_swamp_1"),
			MetaProgress.Reward(Cosmetic, Cosmetic.Slots.PLAYER_TITLE, "gallivanter"),
		}),
	},
})

MetaProgress.AddBiomeExploration("thatcher_swamp",
{
	endless_reward = MetaProgress.Reward(Consumable, Consumable.Slots.MATERIALS, "konjur_soul_lesser", TUNING.BIOME_EXPLORATION.CORESTONE_REWARDS),
	rewards =
	{
		MetaProgress.RewardGroup("onheal_powers", {
			-- Stuff that helps you heal regularly or triggers off of receiving healing
			MetaProgress.Reward(Power, Power.Slots.PLAYER, "bloodthirsty"),
			MetaProgress.Reward(Power, Power.Slots.PLAYER, "heal_on_crit"),
			MetaProgress.Reward(Power, Power.Slots.PLAYER, "optimism"),
		}),

		MetaProgress.RewardGroup("thatcher_swamp_decor", {
			-- Set of decor props
			MetaProgress.Reward(Constructable, Constructable.Slots.STRUCTURES, "fence_iron"),
			MetaProgress.Reward(Constructable, Constructable.Slots.STRUCTURES, "bread_basket"),
			MetaProgress.Reward(Constructable, Constructable.Slots.STRUCTURES, "fruit_basket"),
			MetaProgress.Reward(Constructable, Constructable.Slots.DECOR, "bread_oven"),
		}),

		MetaProgress.RewardGroup("gamechanger_powers", {
			-- Stuff that makes you fundamentally change the way you're playing.
			MetaProgress.Reward(Power, Power.Slots.PLAYER, "dont_whiff"),
			MetaProgress.Reward(Power, Power.Slots.PLAYER, "ping"),
			MetaProgress.Reward(Power, Power.Slots.PLAYER, "pong"),
		}),

		MetaProgress.RewardGroup("thatcher_swamp_decor", {
			-- Set of decor props
			MetaProgress.Reward(Constructable, Constructable.Slots.STRUCTURES, "bench_swamp_2"),
			MetaProgress.Reward(Constructable, Constructable.Slots.STRUCTURES, "chair_swamp_2"),
			MetaProgress.Reward(Constructable, Constructable.Slots.STRUCTURES, "lamp_swamp_2"),
		}),
		
		MetaProgress.RewardGroup("thatcher_swamp_exploration", {
			-- Title reward for exploring the biome
			MetaProgress.Reward(Constructable, Constructable.Slots.STRUCTURES, "bed_swamp_2"),
			MetaProgress.Reward(Constructable, Constructable.Slots.STRUCTURES, "outdoor_seating_swamp_2"),
			MetaProgress.Reward(Constructable, Constructable.Slots.STRUCTURES, "stool_outdoor_seating_swamp_2"),
			MetaProgress.Reward(Cosmetic, Cosmetic.Slots.PLAYER_TITLE, "swamprunner"),
		}),
	},
})

-- TODO @design #sedament_tundra - meta progress
MetaProgress.AddBiomeExploration("sedament_tundra",
{
	rewards =
	{
	},
})
