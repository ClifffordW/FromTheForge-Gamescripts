local Biomes = require "defs.biomes"
local Consumable = require "defs.consumable"
local Npc = require "components.npc"
local Quip = require "questral.quip"
local Quest = require "questral.quest"
local fmodtable = require "defs.sound.fmodtable"
local kassert = require "util.kassert"
local lume = require "util.lume"
local soundutil = require "util.soundutil"

-- Game-specific utilities.
local rotwoodquestutil = {}


function rotwoodquestutil.Not(fn)
    return function(...)
        return not fn(...)
    end
end

function rotwoodquestutil.IsCastPresent(quest, cast_id)
    assert(quest.def.cast[cast_id], "Input cast doesn't exist. Should be the name passed to AddCast.")
    local ent = quest:GetCastMember(cast_id)
    -- Currently, checking for the inst is enough to know they are in the scene.
    return ent and ent.inst
end

local function fmt_color_desire(pretty_string)
    -- Orange is the colour of desire.
    return ("<#EA7722>%s</>"):format(pretty_string)
end

local function get_first_interesting_ingredient(ingredients)
    for ing_name,needs in pairs(ingredients) do
        if ing_name ~= "glitz" then
            return ing_name
        end
    end
    local ing_name = next(ingredients)
    return ing_name
end

-- Gets the most interesting ingredient as a string to display to user.
function rotwoodquestutil.GetPrettyRecipeIngredient(recipe)
    assert(recipe)
    kassert.greater(lume.count(recipe.ingredients), 0, "Must have ingredients")
    local ing_name = get_first_interesting_ingredient(recipe.ingredients)
    local mat = Consumable.Items.MATERIALS[ing_name]
    return fmt_color_desire(mat.pretty.name)
end

-- Common NPC quest filters {{{1

--Meeting any NPC for the first time in one run
function rotwoodquestutil.Filter_FirstMeetingNPC(filter_fn, quest, node, sim, objective_id)
    local can_spawn = not TheDungeon.progression.components.runmanager:HasMetTownNPCInDungeon()
    -- check that runmanager isn't flagged as having met an NPC already this run

    -- check extra filter_fn if one was passed in
    if filter_fn then
        can_spawn = can_spawn and filter_fn(quest, node, sim, objective_id)
    end

    return can_spawn
end

--Meeting a specific NPC for the first time in the game
function rotwoodquestutil.Filter_FirstMeetingSpecificNPC(quest, node, sim, npc, objective_id, filter_fn)
    local can_spawn = not quest:GetPlayer().components.unlocktracker:IsFlagUnlocked(npc)

    if can_spawn == false then
        print ("CAN'T MEET NPC FOR THE FIRST TIME WHO HAS ALREADY BEEN MET")
    end

    -- check extra filter_fn if one was passed in
    if filter_fn then
        can_spawn = can_spawn and filter_fn(quest, node, sim, objective_id)
    end

    return can_spawn
end

------------- FETCH QUEST

function rotwoodquestutil.GetPrettyMaterialName(mat_name)
    local mat = rotwoodquestutil.GetMaterial(mat_name)
    return fmt_color_desire(mat.pretty.name)
end

function rotwoodquestutil.GetMaterial(mat_name)
    assert(mat_name)
    local mat = Consumable.Items.MATERIALS[mat_name]
    assert(mat, mat_name)
    return mat
end

function rotwoodquestutil.HasFetchMaterial(quest, node, sim, objective_id)
    local player = quest:GetPlayer()
    local mat_name = quest:GetVar("request_material")
    local mat = rotwoodquestutil.GetMaterial(mat_name)

    return player.components.inventoryhoard:GetStackableCount(mat) >= 1
end

--check if an item exists in a player inventory using cx
function rotwoodquestutil.HasFetchMaterialCx(cx, objective_id)
    local player = cx.quest:GetPlayer()
    local mat_name = cx.quest:GetVar("request_material")
    local mat = rotwoodquestutil.GetMaterial(mat_name)

    return player.components.inventoryhoard:GetStackableCount(mat) >= 1
end

function rotwoodquestutil.DeliverFetchMaterial(cx)
    local player = cx.quest:GetPlayer()
    local mat_name = cx.quest:GetVar("request_material")
    local mat = rotwoodquestutil.GetMaterial(mat_name)

    return player.components.inventoryhoard:RemoveStackable(mat, 1)
end

-- Common NPC actions {{{1
function rotwoodquestutil.FocusCameraOnNPCIfLocal(quest, npc, playerID)
    local local_players = TheNet:GetLocalPlayerList()

    if table.contains(local_players, playerID) then
        local cast_inst = quest:GetCastMember(npc).inst
        cast_inst:DoTaskInTime(0, function() TheFocalPoint.components.focalpoint:AddExplicitTarget(cast_inst) end)
        cast_inst:DoTaskInTime(2, function() TheFocalPoint.components.focalpoint:ClearExplicitTargets() end)
    end
end

local function GetGiverNpcAndPlayerEntities(cx)
    local node = rotwoodquestutil.GetGiver(cx)
    local inst = node.inst
    local player = node:GetInteractingPlayerEntity()
    return inst, player
end

rotwoodquestutil.GetGiverNpcAndPlayerEntities = GetGiverNpcAndPlayerEntities

-- Prevents the giver from restarting a convo for input seconds. Useful to
-- allow their animation to play out before restarting conversation.
function rotwoodquestutil.ConvoCooldownGiver(cx, delay_seconds)
    local node = rotwoodquestutil.GetGiver(cx)
    node.inst.components.timer:StartTimer("talk_cd", delay_seconds)
end

function rotwoodquestutil.OpenShop(cx, screen_ctor)
    local inst, player = GetGiverNpcAndPlayerEntities(cx)
    kassert.typeof("table", player)
    cx:PresentCallbackScreen(screen_ctor, player, inst)
    -- TheFrontEnd:PushScreen(screen_ctor(player, inst))
end

-- /end NPC actions

-- Prefer to use quest:GetQuestManager() if possible.
function rotwoodquestutil.Debug_GetQuestManager()
    local player = ConsoleCommandPlayer()
    return player and player.components.questcentral:GetQuestManager()
end

-- Prefer to use quest:GetRoot() if possible.
function rotwoodquestutil.Debug_GetCastManager()
    return TheDungeon.progression.components.castmanager
end

function rotwoodquestutil.CompleteObjectiveIfCastMatches(quest, objective, role, prefab)
    if quest:IsActive(objective) and prefab == quest:GetCastMemberPrefab(role) then
        quest:Complete(objective)
        return true
    end
end

function rotwoodquestutil.OpenMap(cx)
    local player_actor = cx:GetPlayer()
    local DungeonSelectionScreen = require "screens.town.dungeonselectionscreen"

    local function make_screen()
        local screen = DungeonSelectionScreen(player_actor.inst)
        return screen
    end

    cx:PresentCallbackScreen(make_screen)
end

function rotwoodquestutil.IsInDungeon(id)
    return TheDungeon:GetDungeonMap().data.location_id == id
end

function rotwoodquestutil.IsInBiome(id)
    return TheDungeon:GetDungeonMap().data.region_id == id
end

function rotwoodquestutil.SelectDiscoveredMobDrop(rarity)
    local drops = rotwoodquestutil.GetDiscoveredMobDrops(rarity)

    if #drops == 0 then
        print ("No drops found, picking default")
        return "cabbageroll_skin" -- Failsafe
    end

    return drops[math.random(1, #drops)]
end

function rotwoodquestutil.PickFetchMaterial(cx)
    if cx.quest.param.request_material ~= "PLACEHOLDER" then
        return
    end

    local drop = rotwoodquestutil.SelectDiscoveredMobDrop({ITEM_RARITY.s.COMMON, ITEM_RARITY.s.UNCOMMON})
    cx.quest.param.request_material = drop
end

function rotwoodquestutil.GiveReward(cx)
    local player = cx:GetPlayer().inst
    player.components.playercrafter:UnlockItem(cx.quest.param.reward, true)
end

-- LockRoom: cause an entity to lock the room. You have to pass an entity to this function because we have to track *who* is keeping the room locked.
function rotwoodquestutil.LockRoom(quest)
    -- When this function is typically first called, giver's inst doesn't yet exist. Wait a few ticks.
    TheWorld:DoTaskInTicks(10, function()
        local giver = quest:GetCastMember("giver")
        if giver and giver.inst then
            giver.inst:AddComponent("roomlock")
        end
    end)
end

function rotwoodquestutil.UnlockRoom(quest)
    local giver = quest:GetCastMember("giver")
    if giver and giver.inst then
        giver.inst:RemoveComponent("roomlock")
    end
end

function rotwoodquestutil.GetGiver(cx_or_quest)
    local giver

    if cx_or_quest.GetCastMember then
        -- This is a quest, so just get the giver
        giver = cx_or_quest:GetCastMember("giver")
    elseif cx_or_quest.quest then
        -- This is a cx, so get the quest and then get the giver
        giver = cx_or_quest.quest:GetCastMember("giver")
    end

    assert(giver, "Couldn't find giver from what was provided!")

    return giver
end

--return how much dungeon currency is in the player's inventory 
function rotwoodquestutil.GetPlayerKonjur(player)
    return player.components.inventoryhoard:GetStackableCount(Consumable.Items.MATERIALS.konjur)
end

function rotwoodquestutil.HasDoneQuest(player, id)
    -- TODO: Once players each have their own quest state, this should be evaluated per-player
    local qman = player.components.questcentral:GetQuestManager()
    return qman:HasEverCompletedQuest(id)
end

function rotwoodquestutil.IsQuestActiveOrComplete(player, id)
    local qman = player.components.questcentral:GetQuestManager()
    local active_quest = qman:FindQuestByID(id)
    return active_quest ~= nil or qman:HasEverCompletedQuest(id)
end

function rotwoodquestutil.IsQuestActive(player, id)
    local qman = player.components.questcentral:GetQuestManager()
    local quest = qman:FindQuestByID(id)
    return quest ~= nil
end

function rotwoodquestutil.PlayerNeedsPotion(player)
    return player.components.potiondrinker:CanGetMorePotionUses()
end

function rotwoodquestutil.PlayerHasRefilledPotion(player)
    return player.components.potiondrinker:HasRefilledPotionThisRoom()
end

function rotwoodquestutil.GiveItemToPlayer(player, slot, id, num, should_equip)
    player.components.inventoryhoard:Debug_GiveItem(slot, id, num, should_equip)
end

function rotwoodquestutil.CompleteQuestOnRoomExit(quest)
    quest:ActivateObjective("wait_for_exit_room")
end

function rotwoodquestutil.AddCompleteQuestOnRoomExitObjective(Q)
    Q:AddObjective("wait_for_exit_room")
        :OnEvent("exit_room", function(quest)
            quest:Complete("wait_for_exit_room")
        end)
        :OnEvent("end_current_run", function(quest)
            quest:Complete("wait_for_exit_room")
        end)
        :OnComplete(function(quest)
            quest:Complete()
        end)
end

-- data can contain:
-- objective_id
-- cast_id
-- on_activate_fn
-- on_complete_fn
function rotwoodquestutil.AddCompleteObjectiveOnCast(Q, data)
    local function complete_if_cast_exists(quest)
        -- if this cast exists, complete the objective
        local cast = quest:GetCastMember(data.cast_id)
        if cast and not cast.is_reservation then
            quest:Complete(data.objective_id)
        end
    end

    local obj = Q:AddObjective(data.objective_id)
                :OnActivate(function(quest)
                    if data.on_activate_fn then
                        data.on_activate_fn(quest)
                    end
                    complete_if_cast_exists(quest)
                end)
                :OnEvent("cast_member_filled", complete_if_cast_exists)
                :OnEvent("playerentered", complete_if_cast_exists)
                :OnComplete(function(quest)
                    if data.on_complete_fn then
                        data.on_complete_fn(quest)
                    end
                end)

    if data.default_active then
        obj:InitialState(QUEST_OBJECTIVE_STATE.s.ACTIVE)
    end

    return obj
end


-- only works with enemies
function rotwoodquestutil.CreateCondition_DiedFighting(cast_id)
    return function(quest, node, sim, convo_target)
        local player = quest:GetPlayer() or convo_target
        local lost_last_run = player.components.progresstracker:LostLastRun()

        if not lost_last_run then
            -- if the didn't lose then they didn't die - maybe abandoned
            return
        end

        local prefab = quest:GetCastMemberPrefab(cast_id)
        local seen = player.components.unlocktracker:IsEnemyUnlocked(prefab)
        local defeated = player.components.progresstracker:GetNumKills(prefab) > 0
        return seen and not defeated
    end
end

function rotwoodquestutil.DiedFighting(cast_id)

end

function rotwoodquestutil.AlreadyHasCharacter(npc_role)
    dbassert(Npc.Role:Contains(npc_role), "Unknown role. See npc.lua for the list.")
    return TheWorld:IsFlagUnlocked("wf_town_has_" .. npc_role)
        or TheWorld:IsFlagUnlocked("wf_seen_npc_" .. npc_role)
end

--use "unlockable_title_IDs" to choose which title to unlock-- and remember lua starts at base 1 lmao
function rotwoodquestutil.UnlockCosmeticTitle(player, _title)
    local Cosmetics = require "defs.cosmetics.cosmetics"
    local unlock_tracker = player.components.unlocktracker
    local title_key = Cosmetics.PlayerTitles[_title].title_key

    --unlock the title
    unlock_tracker:UnlockCosmetic(_title, "PLAYER_TITLE")

    --pop a notif on screen
    TheDungeon.HUD:MakePopText({ 
        target = player, 
        button = string.format(STRINGS.UI.INVENTORYSCREEN.TITLE_UNLOCKED, STRINGS.COSMETICS.TITLES[title_key]), 
        color = UICOLORS.KONJUR, 
        size = 100, 
        fade_time = 3.5,
        y_offset = 650,
    })
end

function rotwoodquestutil.GiveItemReward(player, item_type, reward_amount)
    local Consumable = require "defs.consumable"
    local reward_item = Consumable.FindItem(item_type)
    local invscreen_str = Consumable.GetItemPopText(reward_item.name, reward_amount)
    --rotwoodquestutil.GetPrettyMaterialName(reward_item.name)

    if player:IsLocal() then
        if item_type == "konjur_soul_lesser" then
            soundutil.PlayCodeSound(player,fmodtable.Event.corestone_accept)
        end
        player.sg:GoToState("konjur_accept")
    end

    player.components.inventoryhoard:AddStackable(reward_item, reward_amount)
    TheDungeon.HUD:MakePopText({
        target = player,
        button = string.format(invscreen_str, reward_amount),
        color = UICOLORS.KONJUR,
        size = 100,
        fade_time = 3.5,
        y_offset = 650,
    })
end

function rotwoodquestutil.AddNPCToTown(Q, cast_id, unlock_flag)
    -- will not actually cause the NPC to spawn
    -- spawning conditions must be added to the objective manually.
    local objective_name = ("spawn_%s_in_dungeon"):format(cast_id)

    local obj = Q:AddObjective(objective_name)
                    :InitialState(QUEST_OBJECTIVE_STATE.s.ACTIVE)
                    :OnEvent("meetingmanager_spawn_npc_in_dungeon", function(quest, npc)
                        if not TheNet:IsHost() then return end

                        local cast_member = quest:GetCastMember(cast_id)

                        if cast_member and cast_member.inst and cast_member.inst == npc then
                            quest:Complete(objective_name)
                        end
                    end)
                    :UnlockWorldFlagsOnComplete{unlock_flag}  -- the npc will now appear in this town
                    :OnComplete(function(quest)
                        TheDungeon.progression.components.runmanager:SetHasMetTownNPCInDungeon(true)
                    end)
    return obj
end

function rotwoodquestutil.CompleteObjectiveIfCastPresent(quest, cast_id, objective_id)
    local cast_member = quest:GetCastMember(cast_id)
    if cast_member and cast_member.inst then
        quest:Complete(objective_id)
    end
end

function rotwoodquestutil.GetUpgradeablePowerCount(player)
    local powers = player.components.powermanager:GetUpgradeablePowers()
    return #powers
end


--jcheng:
-- local quip_convo = 
-- {
--     tags = {},                       -- tags to add on the quip
--     not_tags = {},                   -- not tags to add on the quip
--     tag_scores = 
--     {
--         chitchat = 100               -- specify scores to specific tags
--     },
--     strings = quest_strings,         -- strings used in the conversation
--     quip = quest_strings.TALK,       -- quip line used when this quip is said
--     convo = convo,                   -- called from OnHub
--     repeatable = true,               -- quip line is not marked as read and can continually be used
--     prefab = "npc_dojo_master",      -- who is talking
-- }
function rotwoodquestutil.AddQuipConvo(Q, quip_convo)
    Q.Quest_EvaluateSpawn = function(self, quester)
        return true
    end

    Q:UpdateCast("giver")
        :FilterForPrefab(quip_convo.prefab)

    local objective = Q:AddObjective("convo")
        :InitialState(QUEST_OBJECTIVE_STATE.s.ACTIVE)

    Q:UnlockPlayerFlagsOnComplete({ "qc_"..Q:GetContentID()})

    local quip = Quip(table.unpack(quip_convo.tags))
        :Not(quip_convo.not_tags or {})
        :PossibleStrings({quip_convo.quip})
        :SetFn(function(cx)
            local convo_player = cx:GetPlayer()
            local qman = convo_player.inst.components.questcentral:GetQuestManager()
            local quest = qman:FindQuestByID(Q:GetContentID())

            --jcheng: it's possible that we can't find this quest, because the quest is complete, 
            --  BUT the fallback chat continued to hold on to the quip
            if quest then
                quest:SetVar("display_hub", true)
            end
        end)

    if quip_convo.tag_scores then
        for tag, score in pairs(quip_convo.tag_scores) do
            quip:Tag(tag, score)
        end
    end

    if quip_convo.repeatable then
        quip:SetRepeatable()
    end

    if quip_convo.important then
        quip:SetImportant()
    end

    --jcheng: remove the quip string from the strings
    local quip_str_key = table.find(quip_convo.strings, quip_convo.quip)
    dbassert(quip_str_key ~= nil)
    quip_convo.strings[quip_str_key] = nil

    Q:AddQuip( quip )

    Q:OnHub("convo", "giver", function(quest)
        local test = quest:GetVar("display_hub")
        quest:SetVar("display_hub", false)
        return test
    end)
        :Strings(quip_convo.strings)
        :Fn(quip_convo.convo)

    return objective
end

function rotwoodquestutil.ResetChosenQuipForNPC(player, npc_prefab)
    --[[
        loops through the player's quest log and looks at the `twn_fallback_chat` quests.
        When it finds one that has a giver prefab that equals npc_prefab then it resets the
        "chosen_quip" variable on the quest, allowing a new quip to be chosen
    --]]

    local quip_chats = player.components.questcentral:GetQuestManager():FindAllQuestByID('twn_fallback_chat')
    for _, chat in ipairs(quip_chats) do
        local cast = chat:GetCastMember("giver")
        if cast and cast.prefab == npc_prefab then
            -- completeing the quest causes a new/ fresh one to spawn next time you speak to the NPC.
            -- this handles all variables that need to be reset.
            chat:Complete() 
            break
        end
    end

    TheWorld:PushEvent("refresh_markers", {player = player})
end

return rotwoodquestutil
