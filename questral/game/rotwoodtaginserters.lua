local recipes = require "defs.recipes"
local rotwoodquestutil = require "questral.game.rotwoodquestutil"
local Equipment = require"defs.equipment"
local Consumable = require"defs.consumable"
local Mastery = require "defs.masteries"
local Recipes = require "defs.recipes"
local biomes = require"defs.biomes"

-- Game-specific utilities.
local taginserters = {}
local wildcard_tags = 
{
    last_killed_by = "last_killed_by_",
    location = "location_",
    weight = "weight_",
    weapon_type = "weapon_type_",
    weapon_name = "weapon_name_",
    room_type = "room_type_",
    frenzy = "frenzy_",
}

rotwoodtaginserters = {}
function rotwoodtaginserters.InsertTags(tag_dict, player, current_speaker)
    for _, inserter in ipairs(taginserters) do
        if inserter.fn(player, current_speaker) then
            tag_dict[inserter.tag] = true
        end
    end

    --add last killed by tag
    local last_killed_by = player.components.progresstracker:GetLastKilledBy()
    if last_killed_by ~= "" then
        tag_dict[wildcard_tags.last_killed_by..last_killed_by] = true
    end

    if TheDungeon then
        --location
        tag_dict[wildcard_tags.location..TheDungeon:GetDungeonMap().data.location_id] = true

        --room_type
        tag_dict[wildcard_tags.room_type..TheWorld:GetCurrentRoomType()] = true

        --frenzy
        local ascensionlevel = TheDungeon.progression.components.ascensionmanager:GetCurrentLevel()
        tag_dict[wildcard_tags.frenzy..tostring(ascensionlevel)] = true
    end

    --weight
    tag_dict[wildcard_tags.weight..tostring(player.components.weight:GetStatus()):lower()] = true

    --weapon type and name
    local equipped_item = player.components.inventoryhoard:GetEquippedItem(Equipment.Slots.WEAPON)
    if equipped_item then
        tag_dict[wildcard_tags.weapon_type..tostring(equipped_item:GetDef().weapon_type):lower()] = true
        tag_dict[wildcard_tags.weapon_name..tostring(equipped_item:GetDef().name):lower()] = true
    end
end

function rotwoodtaginserters.GetPossibleTags()
    local possible_tags = {}
    for _, inserter in ipairs(taginserters) do
        table.insert(possible_tags, inserter.tag)
    end

    for _, wildcard in pairs(wildcard_tags) do
        table.insert(possible_tags, wildcard)
    end

    return possible_tags
end

local AddInserter = function( tbl )
    table.insert(taginserters, tbl)
end

-- Hoggins Tags --

AddInserter{
    fn = function(player)
        local admission_recipe = recipes.ForSlot.PRICE.potion_refill
        return not admission_recipe:CanPlayerCraft(player) 
    end,
    tag = "cant_craft_potion" -- not a duplicate of the one below
}

AddInserter{
    fn = function(player)
        local admission_recipe = recipes.ForSlot.PRICE.potion_refill
        return admission_recipe:CanPlayerCraft(player) 
    end,
    tag = "can_craft_potion"
}

AddInserter{
    fn = function(player) return player.components.progresstracker:GetValue("total_potion_refills_hoggins") == 0 end,
    tag = "never_bought_potion"
}

AddInserter{
    fn = function(player) return rotwoodquestutil.PlayerHasRefilledPotion(player) end,
    tag = "has_refilled_potion"
}

AddInserter{
    fn = function(player) return rotwoodquestutil.PlayerNeedsPotion(player) end,
    tag = "needs_potion"
}

-- --

AddInserter{
    fn = function(player) return player.components.progresstracker:LostLastRun() end,
    tag = "lost_last_run"
}

AddInserter{
    fn = function(player) return player.components.progresstracker:AbandonedLastRun() end,
    tag = "abandoned_last_run"
}

AddInserter{
    fn = function(player) return player.components.progresstracker:WonLastRun() end,
    tag = "won_last_run"
}

AddInserter{
    fn = function(player, speaker)
        return player.components.progresstracker:GetNpcNumTimesSeen(speaker.prefab) == 1
    end,
    tag = "seen_first_time"
}

AddInserter{
    fn = function(player, speaker)
        return player.components.progresstracker:GetNpcNumTimesSeen(speaker.prefab) == 2
    end,
    tag = "seen_second_time"
}

AddInserter{
    fn = function(player, speaker)
        return player.components.progresstracker:GetNpcNumTimesSeen(speaker.prefab) == 3
    end,
    tag = "seen_third_time"
}

AddInserter{
    fn = function(player, speaker)
        return player.components.progresstracker:GetNpcNumTimesSeen(speaker.prefab) >= 10
    end,
    tag = "seen_many_times"
}

AddInserter{
    fn = function() return TheWorld:HasTag("town") end,
    tag = "in_town"
}

AddInserter{
    fn = function() return #TheNet:GetPlayerList() == 1 end,
    tag = "singleplayer"
}

AddInserter{
    fn = function() return #TheNet:GetPlayerList() > 1 end,
    tag = "multiplayer"
}

AddInserter{
    fn = function(player) return player.components.playercontroller:HasGamepad() end,
    tag = "using_gamepad"
}

AddInserter{
    fn = function(player)
        local powers = player.components.powermanager:GetUpgradeablePowers()
        return #powers > 0
    end,
    tag = "upgradable_powers",
}

AddInserter{
    fn = function(player)
        return player:GetTempData('free_power_upgrades') == nil
    end,
    tag = "can_get_free_upgrade",
}

AddInserter{
    fn = function(player)
        return player:GetTempData('used_healingfountain')
    end,
    tag = "steal_five_finger_brew",
}

AddInserter{
    fn = function(player) 
        local equipped_item = player.components.inventoryhoard:GetEquippedItem(Equipment.Slots.HEAD)
        return equipped_item ~= nil
    end,
    tag = "is_wearing_head"
}

AddInserter{
    fn = function(player) 
        local equipped_item = player.components.inventoryhoard:GetEquippedItem(Equipment.Slots.BODY)
        return equipped_item ~= nil
    end,
    tag = "is_wearing_body"
}

AddInserter{
    fn = function(player) 
        local equipped_item = player.components.inventoryhoard:GetEquippedItem(Equipment.Slots.WAIST)
        return equipped_item ~= nil
    end,
    tag = "is_wearing_waist"
}


AddInserter{
    fn = function(player, speaker)
        for name, mastery in pairs(player.components.masterymanager.masteries) do
            if mastery:IsComplete() and not mastery:IsClaimed() then
                return true
            end
        end
    end,
    tag = "can_claim_mastery",
}

AddInserter{
    tag = "can_upgrade_gear",
    fn = function(player, speaker)
        local slots =
        {
            Equipment.Slots.HEAD,
            Equipment.Slots.BODY,
            Equipment.Slots.WAIST,
        }

        for _, slot in ipairs(slots) do
            local item = player.components.inventoryhoard:GetEquippedItem(slot)

            if item then
                local upgrade_recipe = Recipes.FindItemUpgradeRecipeForItem(item)
                if upgrade_recipe and upgrade_recipe:CanPlayerCraft(player) then
                    return true
                end

                upgrade_recipe = Recipes.FindUsageUpgradeRecipeForItem(item)
                if upgrade_recipe and upgrade_recipe:CanPlayerCraft(player) then
                    return true
                end
            end
        end
    end,
}

AddInserter{
    tag = "can_upgrade_weapon",
    fn = function(player, speaker)
        local slots =
        {
            Equipment.Slots.WEAPON,
        }

        for _, slot in ipairs(slots) do
            local item = player.components.inventoryhoard:GetEquippedItem(slot)

            if item then
                local upgrade_recipe = Recipes.FindItemUpgradeRecipeForItem(item)
                if upgrade_recipe and upgrade_recipe:CanPlayerCraft(player) then
                    return true
                end

                upgrade_recipe = Recipes.FindUsageUpgradeRecipeForItem(item)
                if upgrade_recipe and upgrade_recipe:CanPlayerCraft(player) then
                    return true
                end
            end
        end
    end,
}

AddInserter{
    tag = "struggling_on_miniboss",
    fn = function(player)
        for id, def in pairs(biomes.locations) do
            if def.type == biomes.location_type.DUNGEON and not def.hide then
                for _, prefab in ipairs(def.monsters.minibosses) do
                    local miniboss = prefab.."_miniboss"

                    local been_in_dungeon = player.components.progresstracker:GetNumRuns(id) > 2
                    local has_seen_miniboss = player.components.unlocktracker:IsEnemyUnlocked(miniboss)
                    local has_killed_miniboss = player.components.progresstracker:GetNumKills(miniboss) > 0

                    if been_in_dungeon and has_seen_miniboss and not has_killed_miniboss then
                        return true
                    end
                end
            end
        end
    end,
}

AddInserter{
    tag = "has_killed_any_boss",
    fn = function(player)
        for id, def in pairs(biomes.locations) do
            if def.type == biomes.location_type.DUNGEON and not def.hide then
                for _, prefab in ipairs(def.monsters.bosses) do
                    if (player.components.progresstracker:GetNumKills(prefab) > 0) then
                        return true
                    end
                end
            end
        end
    end
}

AddInserter{
    tag = "holding_any_heart",
    fn = function(player, speaker)
        local held_hearts = player.components.inventoryhoard:GetMaterialsWithTag("konjur_heart")
        if #held_hearts == 0 then return false end

        for id, def in pairs(biomes.locations) do
            if def.type == biomes.location_type.DUNGEON and not def.hide then
                for _, prefab in ipairs(def.monsters.bosses) do
                    for _, heart in ipairs(held_hearts) do
                        local heart_def = heart:GetDef()

                        if heart_def.name == ("konjur_heart_%s"):format(prefab) then
                            return true
                        end
                    end
                end
            end
        end
    end,
}

-------------------------------------------------------------------------
-----------------BOSS AND MINIBOSS COMMON FUNCTIONS----------------------
-------------------------------------------------------------------------

local create_struggling_tag = function(prefab, location, runs)
    AddInserter{
        fn = function(player, speaker)
            return 
                player.components.progresstracker:GetNumRuns(location) > runs and
                player.components.unlocktracker:IsEnemyUnlocked(prefab) and
                player.components.progresstracker:GetNumKills(prefab) == 0
        end,
        tag = ("struggling_on_%s"):format(prefab)
    }
end

local create_has_killed_tag = function(prefab)
    -- printf("Create Tag: %s [%s]", "create_has_killed_tag", prefab)
    AddInserter{
        fn = function(player, speaker)
            return player.components.progresstracker:GetNumKills(prefab) > 0
        end,
        tag = "has_killed_"..prefab
    }
end

local create_has_heart_tag = function(prefab)
    -- printf("Create Tag: %s [%s]", "create_has_heart_tag", prefab)
    AddInserter{
        fn = function(player, speaker)
            local held_hearts = player.components.inventoryhoard:GetMaterialsWithTag("konjur_heart")
            if #held_hearts == 0 then return false end

            for _, heart in ipairs(held_hearts) do
                local def = heart:GetDef()

                if def.name == ("konjur_heart_%s"):format(prefab) then
                    return true
                end
            end

            return false
        end,
        tag = ("has_%s_heart"):format(prefab)
    }
end

local create_just_deposited_heart_tag = function(prefab)
    -- printf("Create Tag: %s [%s]", "create_just_deposited_heart_tag", prefab)
    AddInserter{
        fn = function(player, speaker)
            local action_mem = player.components.heartmanager.action_mem
            for _, action in ipairs(action_mem) do
                local heart = player.components.heartmanager:GetHeartDataForSlotIdx(action.slot, action.idx)
                if heart.name == prefab then
                    return true
                end
            end
        end,
        tag = ("just_deposited_%s_heart"):format(prefab)
    }
end

local create_heart_level_tags = function(prefab)
    -- printf("Create Tag: %s [%s]", "create_heart_level_tags", prefab)
    for i = 0, 4 do
        AddInserter{
            fn = function(player, speaker)
                return player.components.heartmanager:GetHeartLevelForBoss(prefab) == i
            end,
            tag = ("%s_heart_level_%s"):format(prefab, i)
        }
    end
end

local create_heart_active_tag = function(prefab)
    -- printf("Create Tag: %s [%s]", "create_heart_active_tag", prefab)
    AddInserter{
        fn = function(player, speaker)
            return player.components.heartmanager:IsBossHeartActive(prefab)
        end,
        tag = ("%s_heart_active"):format(prefab)
    }
end

local create_has_seen_tag = function(prefab)
    AddInserter{
        fn = function(player, speaker)
            return player.components.unlocktracker:IsEnemyUnlocked(prefab)
        end,
        tag = ("has_seen_%s"):format(prefab)
    }
end

for id, def in pairs(biomes.locations) do
    if def.type == biomes.location_type.DUNGEON and not def.hide then
        for _, prefab in ipairs(def.monsters.bosses) do
            create_has_killed_tag(prefab)
            create_struggling_tag(prefab, id, 6)
            create_has_heart_tag(prefab)
            create_just_deposited_heart_tag(prefab)
            create_heart_level_tags(prefab)
            create_heart_active_tag(prefab)
            create_has_seen_tag(prefab)
        end

        for _, prefab in ipairs(def.monsters.minibosses) do
            local miniboss = prefab.."_miniboss"
            create_has_killed_tag(miniboss)
            create_struggling_tag(miniboss, id, 2)
        end
    end
end

return rotwoodtaginserters
