local Convo = require "questral.convo"
local Npc = require "components.npc"
local Quest = require "questral.quest"
local Quip = require "questral.quip"
local iterator = require "util.iterator"
local kassert = require "util.kassert"
local lume = require "util.lume"
local quest_helper = require "questral.game.rotwoodquestutil"

--jcheng:
-- How this works:
-- - This chat is the main OnAttract that NPC's use
-- - It's possible to override it with another quest's OnAttract, but we should do that sparingly as it means
--		you're possibly going to stomp on important options in the Hub
-- - The OnAttract is called when you walk up to an NPC, which then selects a quip and saves it, then displays the first line of the quip
-- 		- The selected quip is marked as read, and if the quip was marked as unique, the player will never see the quip again
--		- The selected quip line (the randomly selected line inside the quip) is stored. Unless marked as repeatable, this quip line will not be played again
--			until all eligible quip lines are played. At that time, all the eligible quip lines are reverted and they can be played again
--		- If the player interacts with the NPC while the first line of the quip is played, the rest of the quip plays
-- - If the player walks away from the NPC, then walks back, a nothingtosay quip is played instead.
-- 		- At this point the chat checks the saved quip to see if it has an associated hub option to insert, and also any other hub
--			options that may exist from other quests
--		- If there are no options, the player cannot interact with the NPC (but still sees the nothingtosay quip)
-- - When a player interacts with the NPC, the chat inserts all the hub options, including any that is associated with the saved quip

local Q = Quest.CreateRecurringChat()

local AddQuipsFromTables = function(quip_tables)
	local quips = {}
	for _, quip_tbl in ipairs(quip_tables) do
		local quip = Quip(table.unpack(quip_tbl.tags))
	        :PossibleStrings(quip_tbl)
	        :Not(quip_tbl.not_tags or {})

	    if quip_tbl.unique then
	        quip:SetUnique(quip_tbl.unique)
	    end

	    if quip_tbl.tag_scores then
	        for tag, score in pairs(quip_tbl.tag_scores) do
	            quip:Tag(tag, score)
	        end
	    end

	    table.insert(quips, quip)
	end

	Q:AddQuips { table.unpack(quips) }
end

Q:AddTags({"fallback"})

Q:AllowDuplicates(true)
Q:SetIsTemporary(true)

-- Should/can we make this a single fallback quest instance shared by all npcs?
Q:UpdateCast("giver")
	:SetDeferred()

Q:AddObjective("chitchat")
	:InitialState(QUEST_OBJECTIVE_STATE.s.ACTIVE)

Q:SetIsUnimportant()

--add the quips for the different NPCs
AddQuipsFromTables(require("strings.strings_npc_dojo_master_quips"))
AddQuipsFromTables(require("strings.strings_npc_scout_quips"))
AddQuipsFromTables(require("strings.strings_npc_armorsmith_quips"))
AddQuipsFromTables(require("strings.strings_npc_blacksmith_quips"))
AddQuipsFromTables(require("strings.strings_npc_konjurist_quips"))
AddQuipsFromTables(require("strings.strings_npc_market_merchant_quips"))
AddQuipsFromTables(require("strings.strings_npc_potionmaker_quips"))
AddQuipsFromTables(require("strings.strings_npc_generic_quips"))

--main attract, you should not override this OnAttract unless you REALLY want to
Q:OnAttract("chitchat", "giver")
	:SetPriority(Convo.PRIORITY.LOWEST)
	:Fn(function(cx)

		--once you've selected a quip, don't select another one
		local chosen_quip = cx.quest:GetVar("chosen_quip")

		if chosen_quip == nil then
			chosen_quip = {}
			local quip, script, string_id = cx:SelectQuip("giver", { "chitchat" })
			chosen_quip.quip = quip
			chosen_quip.script = script
			chosen_quip.string_id = string_id
			cx.quest:SetVar("chosen_quip", chosen_quip)
			cx.quest:SetVar("has_interacted", false)

			--tell the quip that we're using this line, so it doesn't show again
        	quip:MarkLineAsRead(cx:GetPlayer().inst, string_id)
		end

		if cx.quest:GetVar("has_interacted") ~= true then
			cx:ExecuteScript(chosen_quip.quip, chosen_quip.script, chosen_quip.string_id)

			--run the function related to the quip if it exists
			if chosen_quip.quip:GetFn() then
				chosen_quip.quip:GetFn()(cx)
			end

			--inject collected hubs
			cx:InjectHubOptions()

			cx.quest:SetVar("has_interacted", true)
		else
			--run the function related to the quip if it exists
			if chosen_quip.quip:GetFn() then
				chosen_quip.quip:GetFn()(cx)
			end

			--first collect the hub options so we know how many there are
			local qm = cx.sim:GetQuestManager()
			local hub_options = qm:GetHubOptions(cx:GetAgent())

			--we have none, and there's nothing to say, so don't let you interact
			if #hub_options == 0 then
				--no hub options, so don't let you interact with it
				cx:ForceNonInteractiveConvo()
			end

			cx:Quip("giver", { "nothingtosay" })

			--actually do the injection of the collected hub options
		    for _, opt in ipairs(hub_options) do
		        cx:_InjectOption(opt.state, opt.quest)
		    end
		end

		--auto exit if we have no hub options
		if cx:GetNumOptions() == 0 then
			cx:End()
		elseif not cx:HasBackOption() then
			cx:AddEnd()
		end
		-- else: write added more context-specific back option.
	end)

return Q
