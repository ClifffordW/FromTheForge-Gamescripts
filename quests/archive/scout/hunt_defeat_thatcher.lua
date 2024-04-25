local Quest = require "questral.quest"
local QuestTemplateFn = require"questral.game.templates.quest_template_hunt"
local biomes = require "defs.biomes"
local quest_strings = require("strings.strings_npc_scout").QUESTS.defeat_thatcher

------------------------------------------------------------------

local Q = Quest.CreateJob()

QuestTemplateFn(Q, biomes.locations.thatcher_swamp,
{
	quest_strings = quest_strings,

	objectives =
	{
		-- each objective & related convo will only be added if data is created for it here.
		quest_intro =
		{
			-- convo_filter_fn = function(quest, node, sim, convo_target) return quest:IsCool() end, -- extra filter logic
			-- strings_override = quest_strings.different_strings.extra_tables_for_fun, -- if not defined, defaults to the name of the objective (ie: "quest_intro")
			-- on_complete_fn = function(quest) quest:SetIsCool(true) end, -- extra on complete logic here

			-- unlock_player_flags_on_complete = {}, -- these flags will be unlocked when the objective is complete
			-- lock_player_flags_on_complete = {}, -- these flags will lock when the objective is complete

			-- required_player_flags = {}, -- convo will not happen if the player doesn't have these flags
			-- forbidden_player_flags = {}, -- convo will not happen if the player has any of these flags

			not_ready_to_translate = true,

			convo_fn = function(cx)
				cx:Talk("INTRO")
				cx.quest:Complete("quest_intro")
			end,
		},

		celebrate_defeat_boss =
		{
			not_ready_to_translate = true,

			convo_fn = function(cx)
				cx:Opt("HUB_OPT")
					:Fn(function()
						cx:Talk("CHAT")
						cx.quest:Complete("celebrate_defeat_boss")
					end)
			end,

			do_add_heart = true,
		},

		talk_after_konjur_heart =
		{
			not_ready_to_translate = true,

			convo_fn = function(cx)
				cx:Opt("HUB_OPT")
					:Fn(function()
						cx:Talk("CHAT")
						cx.quest:Complete("talk_after_konjur_heart")
					end)
			end,
		}
	},
})

return Q