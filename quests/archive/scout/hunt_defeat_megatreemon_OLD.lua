-- local Convo = require "questral.convo"
-- local Quest = require "questral.quest"
-- local Quip = require "questral.quip"
-- local biomes = require "defs.biomes"
-- local quest_helper = require "questral.game.rotwoodquestutil"
-- local quest_strings = require("strings.strings_npc_scout").QUESTS.main_defeat_megatreemon
-- local log_strings = quest_strings.logstrings
-- local tips_strings = require("strings.strings_npc_scout").QUESTS.twn_chat_scout
-- local playerutil = require "util.playerutil"

-- -- This file is a real quest and a demonstration of how we write conversations
-- -- and quests in the new system. There's extra comments to help you understand
-- -- how some things work.
-- --
-- --
-- -- Quests spawn automatically. Each quest must define a Quest:Quest_EvaluateSpawn(quester) function.
-- -- That function is evaluated whenever a quester completes a quest or whenever the game is loaded.
-- -- If that function returns true, the quest will be added to the quester's quest log.
-- -- We never want to spawn a quest manually.
-- --
-- -- To debug quests, use Ctrl-p > Quest or Window > Quest. That will show all
-- -- the active and past quests. Click on one and you can see a log of how it
-- -- tried to activate (when you walk up to an npc it will try to activate
-- -- quests).

-- ------------------------------------------------------------------

-- -- Differences from Griftlands/gln:
-- -- * Functions contain the word "String" when they accept pretty text so
-- --   writers can search for String and find those functions and the Strings
-- --   collection.
-- -- * Renamed Dialog -> Talk for clarity (it doesn't show a pop up dialog).
-- -- * Added AllocateEnemy
-- -- * Added PromptString so we can quest-specific text pop up to indicate
-- --   interesting dialogue.
-- -- * CompleteQuestObjective should default to completing the objective we're
-- --   inside of.
-- -- * Added TalkAndCompleteQuestObjective to simplify simple setup.
-- -- * Many functions pass 'root' which is (currently) CastManager, but we
-- --   usually access data from 'quest' instead: it's less opaque. Probably only
-- --   use this root to pass to other parts of the quest system.
-- --
-- -- TODO(quest):
-- -- * I don't think we should use AddConvo directly. Maybe make an Entrypoint()
-- --   thing for it instead?
-- -- * Invisible, PromptString need implementation to enable.
-- --

-- -- Usage Notes:
-- -- GetPlayer returns a RotwoodActor and GetPlayer().inst returns the player entity.

-- ------QUEST SETUP------

-- local Q = Quest.CreateJob()

-- Q:TitleString(quest_strings.TITLE) -- use String for all pretty text
-- Q:DescString(quest_strings.DESC)
-- Q:Icon("images/ui_ftf_dialog/convo_quest.tex")
-- Q:SetIsImportant()
-- Q:SetPriority(QUEST_PRIORITY.HIGHEST)

-- function Q:Quest_EvaluateSpawn(quester)
-- 	return false -- quester:IsLocationUnlocked(biomes.locations.treemon_forest.id)
-- end

-- -- Died during a fight against this cast member.
-- local function CreateCondition_DiedFighting(quest, sim, attacker_role)
-- 	if quest:GetObjectiveState("pre_miniboss_death_convo") == QUEST_OBJECTIVE_STATE.s.COMPLETED then
-- 		local qplayer = quest:GetPlayer()
-- 		if sim:WasLastRunVictorious() then
-- 			-- if you won then you obviously didn't die
-- 			return false
-- 		end

-- 		local prefab = quest:GetCastMemberPrefab(attacker_role)
-- 		-- have you seen the thing
-- 		local seen = qplayer.components.unlocktracker:IsEnemyUnlocked(prefab)
-- 		-- have you killed the thing?

-- 		local defeated = qplayer.components.progresstracker:GetNumKills(prefab) > 0
-- 		-- if you've seen it, but not killed it... you must've died.
-- 		return seen and not defeated
-- 	else
-- 		quest:ActivateObjective("pre_miniboss_death_convo")
-- 		return true
-- 	end
-- end

-- local function is_struggling_on_miniboss(runs, quest, node, sim)
-- 	--player
-- 	local player = quest:GetPlayer()

-- 	-- player has done at least 3 runs, has seen yammo, but has not killed yammo.
-- 	local num_runs = player.components.progresstracker:GetValue("total_num_runs") or 0
-- 	local has_seen_miniboss = player:IsFlagUnlocked("pf_first_miniboss_seen")
-- 	local has_killed_miniboss = player:IsFlagUnlocked("pf_first_miniboss_defeated")

-- 	return num_runs >= runs and has_seen_miniboss and not has_killed_miniboss
-- end

-- ------CAST DECLARATIONS------

-- Q:UpdateCast("giver")
-- 	:FilterForPrefab("npc_scout")

-- Q:AddCast("target_dungeon")
-- 	:CastFn(function(quest, root)
-- 		return root:GetLocationActor(biomes.locations.treemon_forest.id)
-- 	end)

-- Q:MarkLocation{"target_dungeon"}

-- Q:AddCast("miniboss")
-- 	:CastFn(function(quest, root)
-- 		return root:AllocateEnemy("yammo_elite")
-- 	end)

-- Q:AddCast("boss")
-- 	:CastFn(function(quest, root)
-- 		return root:AllocateEnemy("megatreemon")
-- 	end)

-- Q:AddCast("town_pillar")
-- 	:CastFn(function(quest, root)
-- 		return root:AllocateInteractable("town_grid_cryst")
-- 	end)

-- ------OBJECTIVE DECLARATIONS------

-- Q:AddObjective("abandoned_run")
-- 	:InitialState(QUEST_OBJECTIVE_STATE.s.ACTIVE)
-- 	:SetIsUnimportant()
-- 	:SetPriority(QUEST_PRIORITY.NORMAL)

-- Q:AddObjective("pre_miniboss_death_convo")
-- 	:InitialState(QUEST_OBJECTIVE_STATE.s.ACTIVE)
-- 	:OnComplete(function(quest)
-- 		if quest:GetPlayer():IsFlagUnlocked("pf_first_boss_seen") then -- FLAG
-- 			quest:ActivateObjective("die_to_boss_convo")
-- 			quest:Cancel("die_to_miniboss_convo")
-- 		else
-- 			if quest:GetPlayer():IsFlagUnlocked("pf_first_miniboss_seen") then -- FLAG
-- 				quest:ActivateObjective("die_to_miniboss_convo")
-- 			end
-- 		end
-- 	end)

-- quest_helper.AddCompleteObjectiveOnCast(Q,
-- {
-- 	objective_id = "find_target_miniboss",
-- 	cast_id = "miniboss",
-- 	on_complete_fn = function(quest)
-- 		quest:ActivateObjective("defeat_target_miniboss")
-- 	end,
-- }):LogString(log_strings.find_target_miniboss)
-- :UnlockPlayerFlagsOnComplete{"pf_first_miniboss_seen"}
-- :InitialState(QUEST_OBJECTIVE_STATE.s.ACTIVE)

-- Q:AddObjective("die_to_miniboss_convo")

-- Q:AddObjective("flitt_miniboss_tip")
-- 	:InitialState(QUEST_OBJECTIVE_STATE.s.ACTIVE)

-- Q:AddObjective("defeat_target_miniboss")
-- 	:LogString(log_strings.defeat_target_miniboss)
-- 	:UnlockPlayerFlagsOnComplete{"pf_first_miniboss_defeated"}
-- 	:OnComplete(function(quest)
-- 		quest:ActivateObjective("celebrate_defeat_miniboss")
-- 		quest:ActivateObjective("find_target_boss")
-- 		quest:Cancel("die_to_miniboss_convo")
-- 		quest:Cancel("pre_miniboss_death_convo")
-- 		quest:Cancel("flitt_miniboss_tip")
-- 	end)

-- Q:AddObjective("celebrate_defeat_miniboss")
-- 	:LogString(log_strings.celebrate_defeat_miniboss)

-- quest_helper.AddCompleteObjectiveOnCast(Q,
-- {
-- 	objective_id = "find_target_boss",
-- 	cast_id = "boss",
-- 	on_complete_fn = function(quest)
-- 		quest:ActivateObjective("defeat_target_boss")
-- 		quest:ActivateObjective("die_to_boss_convo")
-- 		quest:Cancel("celebrate_defeat_miniboss")
-- 	end,
-- }):LogString(log_strings.find_target_boss)
-- :UnlockPlayerFlagsOnComplete{"pf_first_boss_seen"}

-- Q:AddObjective("die_to_boss_convo")

-- Q:AddObjective("defeat_target_boss")
-- 	:UnlockPlayerFlagsOnComplete{"pf_first_boss_defeated"}
-- 	:LogString(log_strings.defeat_target_boss)
-- 	:OnComplete(function(quest)
-- 		quest:ActivateObjective("celebrate_defeat_boss")
-- 		quest:Cancel("die_to_boss_convo")
-- 		quest:Cancel("abandoned_run")
-- 	end)

-- Q:AddVar("direction_time", 0)
-- local WAIT_FOR_DIRECTIONS = 10

-- Q:AddObjective("celebrate_defeat_boss_first_run")
-- 	:UnlockPlayerFlagsOnComplete{"pf_energy_pillar_unlocked"}
-- 	:LogString(log_strings.celebrate_defeat_boss)
-- 	:SetRateLimited(false) -- these objectives shouldn't be restricted, we want them to flow freely!
-- 	:SetPriority(QUEST_PRIORITY.HIGHEST)
-- 	:OnActivate(function(quest)
-- 		quest:Cancel("celebrate_defeat_boss")
-- 	end)
-- 	:OnComplete(function(quest)
-- 		quest:ActivateObjective("directions", true)
-- 		quest:ActivateObjective("talk_after_konjur_heart", true)
-- 		quest:SetVar("direction_time", GetTime() + WAIT_FOR_DIRECTIONS)
-- 		TheWorld:DoTaskInTime(WAIT_FOR_DIRECTIONS, function()
-- 			if quest:GetParent() then
-- 				quest:GetPlayer().components.questcentral:UpdateQuestMarks()
-- 			else
-- 				TheLog.ch.Quest:print("Quest was no longer attached after delay. Was this quest completed with debug?", quest)
-- 			end
-- 		end)
-- 	end)

-- Q:AddObjective("celebrate_defeat_boss")
-- 	:UnlockPlayerFlagsOnComplete{"pf_energy_pillar_unlocked"}
-- 	:LogString(log_strings.celebrate_defeat_boss)
-- 	:SetRateLimited(false) -- these objectives shouldn't be restricted, we want them to flow freely!
-- 	:SetPriority(QUEST_PRIORITY.HIGHEST)
-- 	:OnActivate(function(quest)
-- 		quest:Cancel("celebrate_defeat_boss_first_run")
-- 	end)
-- 	:OnComplete(function(quest)
-- 		quest:ActivateObjective("directions", true)
-- 		quest:ActivateObjective("add_heart", true)
-- 		quest:SetVar("direction_time", GetTime() + WAIT_FOR_DIRECTIONS)
-- 		TheWorld:DoTaskInTime(WAIT_FOR_DIRECTIONS, function()
-- 			if quest:GetParent() then
-- 				quest:GetPlayer().components.questcentral:UpdateQuestMarks()
-- 			else
-- 				TheLog.ch.Quest:print("Quest was no longer attached after delay. Was this quest completed with debug?", quest)
-- 			end
-- 		end)
-- 	end)

-- Q:AddObjective("add_heart")
-- 	:SetRateLimited(false)
-- 	:Mark{"town_pillar"}
-- 	:OnEvent("we_heart_screen_opened", function(quest)
-- 		quest:Complete("add_heart")
-- 	end)
-- 	:OnComplete(function(quest)
-- 		quest:ActivateObjective("talk_after_konjur_heart", true)
-- 	end)

-- Q:AddObjective("directions")
-- 	:SetRateLimited(false) -- these objectives shouldn't be restricted, we want them to flow freely!
-- 	:OnEvent("playeractivated", function(quest, player) 
-- 		if player == quest:GetPlayer() then
-- 			quest:SetVar("direction_time", 0)
-- 			quest:GetPlayer().components.questcentral:UpdateQuestMarks()
-- 		end
-- 	end)

-- Q:AddObjective("talk_after_konjur_heart")
-- 	:SetRateLimited(false) -- these objectives shouldn't be restricted, we want them to flow freely!
-- 	:OnComplete(function(quest)
-- 		quest:Complete()
-- 	end)

-- Q:OnEvent("player_kill", function(quest, victim)
-- 	local player = quest:GetPlayer()
-- 	if player and player.components.health:IsDead() then
-- 		return false
-- 	end

-- 	return quest_helper.CompleteObjectiveIfCastMatches(quest, "defeat_target_boss", "boss", victim.prefab)
-- 		or quest_helper.CompleteObjectiveIfCastMatches(quest, "defeat_target_miniboss", "miniboss", victim.prefab)
-- end)

-- ------CONVERSATIONS AND QUESTS------

-- -- This is a Convo. It's related to an objective (quest_intro) and requires
-- -- a cast member (giver). Attract means it fires when a player talks to the
-- -- cast member. You can use the same objective for different convos and use
-- -- their filter function to determine which should fire.

-- --convo for if the player's abandoned a run 
-- Q:OnTownChat("abandoned_run", "giver", function(quest) return quest:GetPlayer().components.progresstracker:AbandonedLastRun() end)
-- 	:Strings(tips_strings.abandoned_run)
-- 	:SetPriority(Convo.PRIORITY.NORMAL)
-- 	:Fn(function(cx)
-- 		cx:Talk("TALK")
-- 		cx:Opt("OPT_1A")
-- 			:Fn(function(cx)
-- 				cx:Talk("OPT1A_RESPONSE")
-- 				cx.quest:Complete("abandoned_run")
-- 			end)
-- 		cx:Opt("OPT_1B")
-- 			:Fn(function(cx)
-- 				cx:Talk("OPT1B_RESPONSE")
-- 				cx.quest:Complete("abandoned_run")
-- 			end)
-- 	end)

-- --DIE TO REGULAR ENEMY
-- --Chat plays the first time the player dies (pre-miniboss)
-- Q:OnTownChat("pre_miniboss_death_convo", "giver",
-- 	function(quest, node, sim)
-- 		local num_runs = quest:GetPlayer().components.progresstracker:GetValue("total_num_runs") or 0
-- 		local miniboss_defeated = quest:GetPlayer():IsFlagUnlocked("pf_first_miniboss_defeated")
-- 		return (num_runs >= 0) and not miniboss_defeated and quest:GetPlayer().components.progresstracker:LostLastRun()
-- 	end)
-- 	:SetPriority(Convo.PRIORITY.HIGHEST)
-- 	:Strings(quest_strings.pre_miniboss_death_convo)
-- 	:Fn(function(cx)
-- 		local function ReusedSequence(cx)
-- 			cx:Talk("TALK_FIRST_DEATH2")
-- 			cx:Opt("OPT_2A")
-- 				:Fn(function(cx)
-- 					cx:Talk("OPT2A_RESPONSE")
-- 					cx.quest:Complete("pre_miniboss_death_convo")
-- 				end)

-- 			cx:Opt("OPT_2B")
-- 				:Fn(function(cx)
-- 					cx:Talk("OPT2B_RESPONSE")
-- 					cx.quest:Complete("pre_miniboss_death_convo")
-- 				end)

-- 		end

-- 		cx:Talk("TALK_FIRST_DEATH")

-- 		cx:Opt("OPT_1A")
-- 			:Fn(function(cx)
-- 				cx:Talk("OPT1A_RESPONSE")
-- 				ReusedSequence(cx)
-- 			end)
-- 		cx:Opt("OPT_1B")
-- 			:Fn(function(cx)
-- 				cx:Talk("OPT1B_RESPONSE")
-- 				ReusedSequence(cx)
-- 			end)
-- 		cx:Opt("OPT_1C")
-- 			:Fn(function(cx)
-- 				cx:Talk("OPT1C_RESPONSE")
-- 				ReusedSequence(cx)
-- 			end)
-- 	end)

-- --DIE TO YAMMO
-- Q:OnTownChat("die_to_miniboss_convo", "giver", function(quest, node, sim) 
-- 	return CreateCondition_DiedFighting(quest, sim, "miniboss") 
-- end)
-- 	:SetPriority(Convo.PRIORITY.HIGHEST)
-- 	:Strings(quest_strings.die_to_miniboss_convo)
-- 	:Fn(function(cx)
-- 		cx:Talk("TALK")
-- 		cx:Opt("OPT_1")
-- 			:Fn(function()
-- 				cx:Talk("TALK2")
-- 				cx:AddEnd("OPT_2")
-- 					:Fn(function()
-- 						cx:Talk("TALK3")
-- 					end)
-- 					:CompleteObjective()
-- 			end)
-- 	end)

-- --DIE TO MOTHER TREEK
-- Q:OnTownChat("die_to_boss_convo", "giver", function(quest, node, sim)
-- 	return CreateCondition_DiedFighting(quest, sim, "boss")
-- end)
-- 	:SetPriority(Convo.PRIORITY.HIGHEST)
-- 	:Strings(quest_strings.die_to_boss_convo)
-- 	:TalkAndCompleteQuestObjective("TALK")

-- --miniboss tip hookups
-- Q:OnTownChat("flitt_miniboss_tip", "giver", function(...) return is_struggling_on_miniboss(5, ...) end)
-- 	:SetPriority(Convo.PRIORITY.HIGH)
-- 	:Strings(quest_strings.multiple_die_to_miniboss_convo)
-- 	:Fn(function(cx)
-- 		local function Opt1B_EndConvo()
-- 			cx:AddEnd("OPT_1B")
-- 				:Fn(function(cx)
-- 					cx:Talk("OPT1B_RESPONSE")
-- 				end)
-- 				:CompleteObjective()
-- 		end

-- 		cx:Talk("TALK")
-- 		cx:Opt("OPT_1A")
-- 			:Fn(function(cx)
-- 				cx:Talk("OPT1A_RESPONSE")
-- 				Opt1B_EndConvo()
-- 			end)
-- 		Opt1B_EndConvo()
-- 	end)

-- --KILL YAMMO
-- Q:OnTownChat("celebrate_defeat_miniboss", "giver")
-- 	:SetPriority(Convo.PRIORITY.HIGHEST)
-- 	:Strings(quest_strings.celebrate_defeat_miniboss)
-- 	:Fn(function(cx)
-- 		cx:Talk("TALK_FIRST_MINIBOSS_KILL")
-- 		cx:Opt("OPT_1A")
-- 			:Fn(function(cx)
-- 				cx:Talk("OPT1A_RESPONSE")
-- 				cx:Talk("TALK2")
-- 			end)
-- 			:CompleteObjective()
-- 		cx:Opt("OPT_1B")
-- 			:Fn(function(cx)
-- 				cx:Talk("OPT1B_RESPONSE")
-- 				cx:Talk("TALK2")
-- 			end)
-- 			:CompleteObjective()
-- 	end)
-- Q:OnTownChat("celebrate_defeat_boss_first_run", "giver")
-- 	:SetPriority(Convo.PRIORITY.HIGHEST)
-- 	:Strings(quest_strings.celebrate_defeat_boss.defeated_first_run)
-- 	:Fn(function(cx)

-- 		local function EndConvo()
-- 			cx.quest:Complete("celebrate_defeat_boss_first_run")
-- 		end

-- 		cx:Talk("TALK")

-- 		cx:Opt("OPT_1A")
-- 			:Fn(function()
-- 				cx:Talk("OPT1A_RESPONSE")
-- 			end)
-- 		cx:Opt("OPT_1B")
-- 			:Fn(function()
-- 				cx:Talk("OPT1B_RESPONSE")
-- 			end)
-- 		cx:Opt("OPT_1C")
-- 			:Fn(function()
-- 				cx:Talk("OPT1C_RESPONSE")
-- 			end)

-- 		cx:JoinAllOpt_Fn(function()
-- 			cx:Talk("TALK2")
-- 			cx:Opt("OPT_2A")
-- 				:Fn(function()
-- 					cx:Talk("OPT2A_RESPONSE")
-- 				end)
-- 			cx:Opt("OPT_2B")
-- 				:Fn(function()
-- 					cx:Talk("OPT2B_RESPONSE")
-- 				end)
-- 			cx:JoinAllOpt_Fn(function()
-- 				cx:Talk("TALK3")
-- 				cx:Opt("OPT_3")
-- 					:Fn(function()
-- 						cx:Talk("OPT3_RESPONSE")
-- 						cx:Opt("OPT_4A")
-- 							:Fn(function()
-- 								cx:Talk("OPT4A_RESPONSE")
-- 							end)
-- 						cx:Opt("OPT_4B")
-- 							:Fn(function()
-- 								cx:Talk("OPT4B_RESPONSE")
-- 							end)
-- 						cx:JoinAllOpt_Fn(function()
-- 							cx:Talk("TALK4")
-- 							cx:Opt("OPT_5A")
-- 								:Fn(function()
-- 									cx:Talk("OPT5A_RESPONSE")
-- 									cx:AddEnd("OPT_5B_ALT")
-- 										:Fn(function()
-- 											EndConvo()
-- 										end)
-- 								end)
-- 							cx:AddEnd("OPT_5B")
-- 								:Fn(function()
-- 									EndConvo()
-- 								end)
-- 						end)
-- 					end)
-- 			end)
-- 		end)
-- 	end)
-- --KILL MOTHER TREEK AND GIVE FLITT HEARTSTONE
-- Q:OnTownChat("celebrate_defeat_boss", "giver")
-- 	:SetPriority(Convo.PRIORITY.HIGHEST)
-- 	:Strings(quest_strings.celebrate_defeat_boss.defeated_regular)
-- 	:Fn(function(cx)
-- 		local function EndConvo()
-- 			cx.quest:Complete("celebrate_defeat_boss")
-- 			quest_helper.ConvoCooldownGiver(cx, 5)
-- 		end

-- 		--find out how many crew members the player has recruited - if it's 2 or more they've rescued all the foxtails
-- 		local function PickAltLine()
-- 			local player = cx.quest:GetPlayer()

-- 			if TheWorld:IsFlagUnlocked("wf_town_has_armorsmith") then
-- 				cx:Talk("TALK2_ALT1")
-- 			else
-- 				cx:Talk("TALK2_ALT2")
-- 			end
-- 		end

-- 		local function OPT_1C(btnText)
-- 			cx:Opt(btnText)
-- 				:Fn(function()
-- 					cx:Talk("OPT1C_RESPONSE")
-- 					cx:Opt("OPT_2A")
-- 						:Fn(function()
-- 							cx:Talk("OPT2A_RESPONSE")
-- 							cx:AddEnd("OPT_2B_ALT")
-- 								:Fn(function()
-- 									EndConvo()
-- 								end)
-- 						end)
-- 					cx:AddEnd("OPT_2B")
-- 						:Fn(function()
-- 							EndConvo()
-- 						end)
-- 				end)
-- 		end

-- 		cx:Talk("TALK")
		
-- 		--chooses an alt line based on how many villagers the player has recruited
-- 		PickAltLine()
		
-- 		cx:Talk("TALK3")
-- 		cx:Opt("OPT_1A")
-- 			:Fn(function(cx)
-- 				cx:Talk("OPT1A_RESPONSE")
-- 				OPT_1C("OPT_1C_ALT")
-- 			end)
-- 		cx:Opt("OPT_1B")
-- 			:Fn(function(cx)
-- 				cx:Talk("OPT1B_RESPONSE")
-- 				OPT_1C("OPT_1C_ALT")
-- 			end)
-- 		OPT_1C("OPT_1C")
-- 	end)

-- -- After completing "heartstone_tips", wait WAIT_FOR_DIRECTIONS seconds before this chat is valid
-- Q:OnTownChat("directions", "giver", function(quest, node, sim) 
-- 		return Quest.Filters.InTown(quest, node, sim) 
-- 			and GetTime() >= quest:GetVar("direction_time") 
-- 	end)
-- 	:SetPriority(Convo.PRIORITY.HIGHEST)
-- 	:ForbiddenPlayerFlags{"pf_seen_heart_screen"}
-- 	:Strings(quest_strings.directions)
-- 	:Fn(function(cx)
-- 		cx:Talk("LOST")
-- 		cx:AddEnd("OPT_1A")
-- 			:Fn(function(cx)
-- 				cx.quest:Complete("directions")
-- 				quest_helper.ConvoCooldownGiver(cx, 5)
-- 			end)
-- 	end)

-- Q:OnTownChat("talk_after_konjur_heart", "giver", function(quest)
-- 		return quest:IsComplete("directions")
-- 	end)
-- 	:ForbiddenPlayerFlags{"pf_seen_heart_screen"}
-- 	:SetPriority(Convo.PRIORITY.HIGHEST)
-- 	:Strings(quest_strings.talk_after_konjur_heart)
-- 	:Fn(function(cx)
-- 		cx:Talk("REMINDER_GIVE_KONJUR_HEART")
-- 	end)

-- --USE HEARTSTONE (happens immediately after celebrate_defeat_boss)
-- Q:OnTownChat("talk_after_konjur_heart", "giver")
-- 	:RequiredPlayerFlags{"pf_seen_heart_screen"}
-- 	:SetPriority(Convo.PRIORITY.HIGHEST)
-- 	:Strings(quest_strings.talk_after_konjur_heart)
-- 	:Fn(function(cx)

-- 		local function AddEndFn()
-- 			cx:AddEnd("OPT_AGREE")
-- 				:Fn(function()
-- 					cx.quest:Complete("talk_after_konjur_heart")
-- 				end)
-- 		end

-- 		--MENU LOGIC--
-- 		local function MenuLoop(optAClicked, optBClicked)
-- 			--ask if all hearts do the same thing
-- 			if not optAClicked then
-- 				cx:Opt("OPT_2A")
-- 					:Fn(function()
-- 						cx:Talk("OPT2A_RESPONSE")
-- 						optAClicked = true
-- 						MenuLoop(optAClicked, optBClicked)
-- 					end)
-- 			end

-- 			--ask how long heart effects last
-- 			if not optBClicked then
-- 				cx:Opt("OPT_2B")
-- 					:Fn(function()
-- 						cx:Talk("OPT2B_RESPONSE")
-- 						optBClicked = true
-- 						MenuLoop(optAClicked, optBClicked)
-- 					end)
-- 			end

-- 			--direction where to go next (changes whether or not you have berna already)
-- 			if TheWorld:IsFlagUnlocked("wf_town_has_armorsmith") then
-- 				cx:Opt("OPT_2C")
-- 					:Fn(function()
-- 						cx:Talk("OPT2C_RESPONSE_HAVEBERNA")
-- 						AddEndFn()
-- 					end)
-- 			else
-- 				cx:Opt("OPT_2C")
-- 					:Fn(function()
-- 						cx:Talk("OPT2C_RESPONSE_NOBERNA")
-- 						cx:Opt("OPT_3_NOBERNA")
-- 							:Fn(function()
-- 								cx:Talk("OPT3_NOBERNA_RESPONSE")
-- 								AddEndFn()
-- 							end)
-- 						AddEndFn()
-- 					end)
-- 			end	
-- 		end
-- 		--END MENU LOGIC--

-- 		--CONVO LOGIC START--
-- 		cx:Talk("TALK")

-- 		cx:Opt("OPT_1A")
-- 			:Fn(function()
-- 				cx:Talk("OPT1A_RESPONSE")
-- 			end)
-- 		cx:Opt("OPT_1B")

-- 		cx:JoinAllOpt_Fn(function()
-- 			cx:Talk("TALK2")

-- 			MenuLoop(false, false)
-- 		end)
-- 		--------------------

-- 		--[[
-- 		--keep track of if options 3A, 3B and 3C have been clicked or not
-- 		local menuButtonState = {}
-- 		menuButtonState = { false, false, false}

-- 		--keep track of if options 5A, 5B, and 6 have been clicked or not
-- 		local wrapupButtonState = {}
-- 		wrapupButtonState = { false, false, false }

-- 		--menu for OPT_5A and OPT_5B in "talk_after_konjur_heart", these are last two options before the player exits the convo
-- 		local function WrapUp(cx)
-- 			--the option necessary for convo progression, after the player clicks
-- 			--through once the exit conversation option replaces it
-- 			if wrapupButtonState[2] then
-- 				cx:AddEnd("OPT_7")
-- 					:Fn(function(cx)
-- 						cx:Talk("OPT7_RESPONSE")
-- 						cx.quest:Complete()
-- 						cx:End()
-- 					end)
-- 			else
-- 				cx:Opt("OPT_5B")
-- 					:Fn(function(cx)
-- 						cx:Talk("OPT5B_RESPONSE")
-- 						wrapupButtonState[2] = true
-- 						WrapUp(cx)
-- 					end)
-- 			end
-- 		end

-- 		--menu for 3A/3B/3C lore on heartstones in "talk_after_konjur_heart", leads into WrapUp(cx) which ends the conversation
-- 		local function Menu(cx)
-- 			--player asks why flitt wants to restore the grid (doesn't show up if they clicked "why" in the last option menu)
-- 			if menuButtonState[1] == false then
-- 				cx:Opt("OPT_3A")
-- 					:Fn(function(cx)
-- 						cx:Talk("OPT3A_RESPONSE")
-- 						menuButtonState[1] = true
-- 						cx:Opt("OPT_4A")
-- 							:Fn(function(cx)
-- 								cx:Talk("OPT4A_RESPONSE")
-- 								Menu(cx)
-- 							end)
-- 						cx:Opt("OPT_4B")
-- 							:Fn(function(cx)
-- 								cx:Talk("OPT4B_RESPONSE")
-- 								Menu(cx)
-- 							end)
-- 					end)
-- 			end

-- 			--player asks how many heartstones are needed to restore the mcguffin
-- 			if menuButtonState[2] == false then
-- 				cx:Opt("OPT_3B")
-- 					:Fn(function(cx)
-- 						cx:Talk("OPT3B_RESPONSE")
-- 						menuButtonState[2] = true
-- 						Menu(cx)
-- 					end)
-- 			end

-- 			--player figures out they're being asked to kill rot bosses
-- 			if menuButtonState[3] == false then
-- 				cx:Opt("OPT_3C")
-- 					:Fn(function(cx)
-- 						cx:Talk("OPT3C_RESPONSE")
-- 						menuButtonState[3] = true
-- 						Menu(cx)
-- 					end)
-- 			else
-- 				WrapUp(cx) --unlock new dialogue options after choosing the "So I need to kill Rot Bosses" option
-- 			end
-- 		end

-- 		cx:Talk("TALK")

-- 		cx:Opt("OPT_1")
-- 			:Fn(function()
-- 				cx:Talk("OPT1_RESPONSE")

-- 				--player asks why flitt wants to restore the grid
-- 				cx:Opt("OPT_2A")
-- 					:Fn(function(cx)
-- 						cx:Talk("OPT3A_RESPONSE")
-- 						menuButtonState[1] = true
-- 						cx:Opt("OPT_4A")
-- 							:Fn(function(cx)
-- 								cx:Talk("OPT4A_RESPONSE")
-- 								--player is funneled into asking how to restore the grid
-- 								cx:Opt("OPT_2B_ALT")
-- 									:Fn(function(cx)
-- 										cx:Talk("OPT2B_RESPONSE")
-- 										--menu of 3 options that disappear after the player goes through them
-- 										Menu(cx)
-- 									end)
-- 							end)
-- 						cx:Opt("OPT_4B")
-- 							:Fn(function(cx)
-- 								cx:Talk("OPT4B_RESPONSE")
-- 								--player is funneled into asking how to restore the grid
-- 								cx:Opt("OPT_2B_ALT")
-- 									:Fn(function(cx)
-- 										cx:Talk("OPT2B_RESPONSE")
-- 										--menu of 3 options that disappear after the player goes through them
-- 										Menu(cx)
-- 									end)
-- 							end)
-- 					end)

-- 				--player asks how to restore the grid
-- 				cx:Opt("OPT_2B")
-- 					:Fn(function(cx)
-- 						cx:Talk("OPT2B_RESPONSE")
-- 						--menu of 3 options that disappear after the player goes through them
-- 						Menu(cx)
-- 					end)
-- 			end)]]

-- 	end)

-- return Q
