local InstanceLog = require "util.instancelog"
local kassert = require "util.kassert"
local krandom = require "util.krandom"
local iterator = require "util.iterator"
local lume = require "util.lume"
local flagslist = require "gen.flagslist"
local rotwoodtaginserters = require "questral.game.rotwoodtaginserters"
local sort = require "util.sort"
require "util.kstring"


-------------------------------------------------------------------------------

local MAX_RECENT_QUIPS = 10 -- How many recent quips in recent_lookups for debugging.

-------------------------------------------------------------------------------
-- A system for looking up randomized quips by a set of criterion tags.


local QuipMatcher = Class(function(self, ...) self:init(...) end)

function QuipMatcher:init(sim)
    self.sim = sim
    self.stats = {}
    self.recent_lookups = {}
end

function QuipMatcher:_EvaluateScore( match_tags, quip, player )
    if quip.notags:hasAny(match_tags) then
        self:Logf("  Matched notags. quip '%s'.", quip)
        return nil
    end

    --need to have the first tag
    if not quip:HasPrimaryTag(match_tags[1]) then
        self:Logf("  Missing primary tag. quip '%s'.", quip)
        return nil
    end

    -- Require all tags in the quip to be in match_tags. match_tags is like the
    -- game state and the quip must match the current state. It's okay if some
    -- tags in the game state are missing from the quip.
    if not quip.tags:subsetOf(match_tags) then
        self:Logf("  Quip has tags missing from match tags. quip '%s'.", quip)
        return nil
    end

    local score = 1
    --score the matching tags
    for tag in quip.tags:Iter() do
        local points = quip:GetScore(tag, player)
        score = score + points
        self:Logf("    %i points for tag '%s'.", points, tag)
    end
    self:Logf("  Score %i for quip '%s'.", score, quip)

    return score
end

-- Modify score at the last minute so untranslated quips are still included,
-- but deprioritized. If we have nothing else to say, we'll use them otherwise
-- we'll stick to translated ones.
local function ModifyScoreForTranslation(score, string_id)
    local str, missing_translation = LOC(string_id)
    if missing_translation then
        score = score - 10
    end
    return score
end
local function UnmodifiedScore(score, string_id)
    return score
end

function QuipMatcher:_GenerateMatches( match_tags, formatter, player )
    -- TODO(quest): Collect relevant ContentNodes and pass to QuipMatcher so
    -- quips are automatically scoped to the relevant content (similar to how
    -- we FillOutQuipTags). Still fallback to ContentDB's quips for global quip
    -- content. This setup is more intuitive since when calling AddQuip on a
    -- quest, convo, or agent you'd assume those quips are only relevant when
    -- that entity is involved.
    --
    -- For now, we use the primary tag for the speaker because Quips aren't
    -- attached to the speaker node. ContentNode:GetQuips is never called: we
    -- only use ContentDB:GetQuips.

    local content = self.sim:GetContentDB()
    for i, tag in ipairs( match_tags ) do
        match_tags[i] = tag:lower()
    end

    self:Logf("Searching with %i tags:", #match_tags)
    self:LogTable("match_tags", match_tags)

    local ModifyScore = UnmodifiedScore
    if self.sim:GetContentDB():HasTranslationApplied() then
        ModifyScore = ModifyScoreForTranslation
    end

    local matches
    local primary_tag = match_tags[1]
    local quips = primary_tag and content:GetQuips( primary_tag )
    if quips then
        self:Logf("  Found %i quips from primary tag '%s'.", #quips, primary_tag)

        local matching_quips = {}

        --store all quips that have a score > 0
        for _, quip in ipairs( quips ) do
            local score = self:_EvaluateScore( match_tags, quip, player )
            if score and score > 0 then
                matching_quips[quip] = score
            end
        end

        --see if they are all read
        local all_lines_read = true
        for quip, _ in pairs(matching_quips) do
            if not quip:AreAllLinesRead(player) then
                all_lines_read = false
            end
        end

        --all read? then reset them all
        if all_lines_read then
            for quip, _ in pairs(matching_quips) do
                quip:ResetLines(player)
            end
        end

        for quip, score in pairs(matching_quips) do
            if matches == nil then
                matches = {}
            end

            for _, v in ipairs(quip:GetDialog(player)) do
                local quip_score = ModifyScore(score, v)
                table.insert( matches, { score = quip_score, string_id = v, emote = quip.emote, quip = quip } )
            end
        end
    else
        self:Logf("  Returned nothing from primary tag '%s'.", primary_tag)
    end

    if matches == nil then
        if self.debug_empty_matches then
            table.insert( self.recent_lookups, 1, {
                    matches = table.empty,
                    tags = shallowcopy(match_tags),
                    content = content,
                })
        end
        self:Logf("  No matches.")
        return
    end


    -- Shuffle and then stable sort to randomize order of equivalent scores.
    krandom.Shuffle(matches)
    sort.stable_sort(matches,
        function(a,b)
            local stats_a = (self.stats[a.string_id] or 0)
            local stats_b = (self.stats[b.string_id] or 0)
            local score_a = a.score
            local score_b = b.score

            if score_a == score_b then
                return stats_a < stats_b
            else
                return score_b < score_a
            end
        end)

    table.insert(self.recent_lookups, 1, {
            matches = matches and shallowcopy(matches) or table.empty,
            tags = shallowcopy(match_tags),
            content = content,
        })
    while #self.recent_lookups > MAX_RECENT_QUIPS do
        table.remove( self.recent_lookups )
    end

    local match = matches[1]
    if match then
        local string_id = match.string_id
        self.stats[string_id] = (self.stats[string_id] or 0) + 1

        local txt = formatter and formatter:FormatString(LOC(string_id)) or LOC(string_id)
        self:Logf("  Quip text:[[%s]] emote:[%s]", txt, match.emote)
        self:Logf("")
        return txt, match
    end
end

function QuipMatcher:LookupQuip( match_tags, formatter, player )
    local txt, match = self:_GenerateMatches( match_tags, formatter, player )
    if match and match.emote then
        txt = string.format("!%s\n%s", match.emote, txt)
    end
    return txt, match
end

-- Get the localized quip, but without inserting the emote into it.
--
-- Returns: localized quip string, quip match table
function QuipMatcher:LookupQuip_Raw( match_tags, formatter, player )
    return self:_GenerateMatches( match_tags, formatter, player )
end

local reject_tags = function( tags, tag_match )
    return lume.reject(tags, function(tag) return tag:find(tag_match) ~= nil end)
end

-- Top-level tag aggregation. Unlike FillOutQuipTags, this accepts and returns
-- a list of tags (with the primary tag as the first).
--
-- only core_tags are required.
-- player is an EntityScript, not a GameNode.
-- ... args are additional tags to add.
function QuipMatcher:CollectRelevantTags(core_tags, speaker, player, ...)

    if TheWorldData:GetSaveData() == nil then
        --jcheng: The host left, there's no save data, exit out
        return core_tags
    end

    local primary = core_tags[1]
    local tag_dict = lume.invert(core_tags)

    if speaker then
        speaker:FillOutQuipTags(tag_dict)
    end

    --add all the world flags
    local world_flags = TheWorldData:GetSaveData().Unlocks.FLAG or table.empty
    for flag, _ in pairs(world_flags) do
        tag_dict[flag] = true
    end

    --add player flags
    if player then
        rotwoodtaginserters.InsertTags(tag_dict, player, speaker)
        local player_id = player.Network:GetPlayerID()
        local player_flags = ThePlayerData:GetAllUnlocked(player_id, "FLAG");
        if player_flags then
            for flag, _ in pairs(player_flags) do
                tag_dict[flag] = true
            end
        end
    end

    for i=1,select('#', ...) do
        local t = select(i, ...)
        if t ~= nil then
            dbassert(type(t) == "table" and t.GetQuipID, "... must be objects with a quip id.")
            tag_dict[t:GetQuipID()] = true
        end
    end

    tag_dict[primary] = nil
    core_tags = lume.keys(tag_dict)
    table.sort(core_tags)  -- Sorted secondary tags makes debug easier to follow.
    table.insert(core_tags, 1, primary)

    return core_tags
end

function QuipMatcher:RenderDebugPanel( ui, panel )
    if ui:Checkbox( "Track Empty Matches", self.debug_empty_matches == true ) then
        self.debug_empty_matches = not self.debug_empty_matches
    end
    ui:SameLine( nil, 20 )
    if ui:Button( "Clear Recents" ) then
        table.clear( self.recent_lookups )
    end

    if ui:CollapsingHeader("Verify Quip Tags") then
        if ui:Button( "Verify Quip Tags##verifyquiptags" ) then
            self.warnings = self:VerifyQuipTags()
        end    

        if self.warnings ~= nil then
            for _, warning in ipairs(self.warnings) do
                ui:Text("Unknown tag: "..warning.tag)
                ui:Text(warning.example)
                ui:Separator()
            end
        end
    end

    self.debug_quip_tags = self.debug_quip_tags or {}
    if ui:CollapsingHeader("Tag Inserters") then
        if ui:Checkbox( "Show Flags##taginserter_showflags", self.taginsert_show_flags == true ) then
            self.taginsert_show_flags = not self.taginsert_show_flags
        end

        ui:Text("This is a non-exhaustive list of tags that can show up in quips")
        local tags = rotwoodtaginserters.GetPossibleTags()

        if self.taginsert_show_flags then
            tags = lume.concat(tags, flagslist)
        end

        ui:Columns(4)

        for _, tag in ipairs(tags) do
            if ui:Button( string.format("%s##possible_tag%s", tag, tag) ) then
                table.insert(self.debug_quip_tags, tag)

                ui:SetClipboardText(tag)
            end
            if ui:IsItemHovered() then
                ui:SetTooltip(string.format("%s\nClick to add to lookup and to your clipboard", tag))
            end
            ui:NextColumn()
        end

        ui:Columns()
    end

    if ui:CollapsingHeader("Test Tag Lookup") then

        local primary_tag = self.debug_quip_tags[1]
        local tag_to_add = ui:_InputText( "Set Primary Tag", primary_tag )
        if tag_to_add and primary_tag ~= tag_to_add then
            if tag_to_add:len() == 0 then
                tag_to_add = nil
            end
            self.debug_quip_tags[1] = tag_to_add
        end

        tag_to_add = ui:_InputText( "Add Tag", self.tag_to_add, ui.InputTextFlags.EnterReturnsTrue )
        if tag_to_add
            and tag_to_add:len() > 0
            and self.tag_to_add ~= tag_to_add
        then
            table.insert( self.debug_quip_tags, tag_to_add )
        end
        ui:SetTooltipIfHovered("Press Enter to add.")

        ui:SameLineWithSpace()
        if ui:Button("Clear Tags") then
            self.debug_quip_tags = nil
        end

        if self.debug_quip_tags ~= nil then

            local to_remove = {}
            ui:Columns(4)
            for _, tag in iterator.sorted_pairs(self.debug_quip_tags) do

                if ui:Button(tag) then
                    table.insert(to_remove, tag)
                end

                if ui:IsItemHovered() then
                    ui:SetTooltip(string.format("%s\nclick to remove", tag))
                end
                ui:NextColumn()
            end

            for _, tag in ipairs(to_remove) do
                lume.remove(self.debug_quip_tags, tag)
            end

            ui:Columns()

            ui:Separator()

            if ui:Button("Lookup Quip!") then
                if self:LookupQuip( self.debug_quip_tags, nil, GetDebugPlayer() ) == nil then
                    table.insert( self.recent_lookups, 1, { matches = table.empty, tags = deepcopy(self.debug_quip_tags) } )
                end
            end
        end
    end

    if ui:CollapsingHeader("Recent Quips", ui.TreeNodeFlags.DefaultOpen) then
        if ui:Checkbox( "Show Quest Tags", self.show_quest_tags == true ) then
            self.show_quest_tags = not self.show_quest_tags
        end
        ui:SameLineWithSpace()
        if ui:Checkbox( "Show Player Flags", self.show_player_flags == true ) then
            self.show_player_flags = not self.show_player_flags
        end
        ui:SameLineWithSpace()
        if ui:Checkbox( "Show World Flags", self.show_world_flags == true ) then
            self.show_world_flags = not self.show_world_flags
        end

        if #self.recent_lookups == 0 then
            ui:Text( "No recent quips" )
        else
            for i, v in ipairs( self.recent_lookups ) do
                -- GLN uses kstring.raw, but index should be enough to keep unique.
                local tags = string.format("%s (%d matches)##%i", table.concat( v.tags, " " ), #v.matches, i)
                if ui:TreeNode( tags ) then
                    if ui:TreeNode( "tags##tags_"..tostring(i), ui.TreeNodeFlags.DefaultOpen ) then
                        local display_tag = function(tag)
                            ui:Text(tag)
                            if ui:IsItemHovered() then
                                ui:SetTooltip(tag)
                            end
                            ui:NextColumn()
                        end

                        ui:Columns(4)
                        local all_tags = deepcopy(v.tags)

                        display_tag(all_tags[1])
                        table.remove(all_tags, 1)

                        if not self.show_quest_tags then
                            all_tags = reject_tags(all_tags, "in_quest")
                            all_tags = reject_tags(all_tags, "in_convo")
                        end

                        if not self.show_player_flags then
                            all_tags = reject_tags(all_tags, "pf_")
                        end

                        if not self.show_world_flags then
                            all_tags = reject_tags(all_tags, "wf_")
                        end

                        for _, tag in iterator.sorted_pairs(all_tags) do
                            display_tag(tag)
                        end
                        ui:Columns()

                        if ui:Button("Apply to Tag Lookup") then
                            self.debug_quip_tags = deepcopy(v.tags)
                        end

                        ui:TreePop()
                    end
                    local content = v.content
                    local content_key, content_id
                    if content and content.GetContentID then
                        content_key, content_id = content:GetContentKey(), content:GetContentID()
                    else
                        content_key, content_id = "ContentDB", ""
                    end
                    panel:AppendTable( ui, content, string.format( "%s.%s", tostring(content_key), tostring(content_id) ))
                    for j, match in ipairs( v.matches ) do
                        ui:Text( string.format( "%d) (Score: %d) %s", j, match.score, LOC(match.string_id) ))
                    end
                    ui:TreePop()
                end
                ui:SetTooltipIfHovered(tags)
            end
        end
    end
end

local reject_known_tags = function( tags )
    return lume.reject(tags, function(tag) 
        return 
            tag:find("in_quest_") ~= nil or 
            tag:find("in_convo_") ~= nil or
            tag:find("wf_") ~= nil or
            tag:find("pf_") ~= nil or
            tag:find("qc_") ~= nil or
            tag:find("role_") ~= nil
        end)
end

function QuipMatcher:VerifyQuipTags()

    local warnings = {}
    local possible_tags = rotwoodtaginserters.GetPossibleTags()

    local check_tags = function(tags, quip)
        tags = reject_known_tags(tags)

        for _, tag in ipairs( tags ) do
            local found_tag = false
            for _, possible_tag in ipairs(possible_tags) do
                if tag:find(possible_tag) ~= nil then
                    found_tag = true
                    break
                end
            end

            if not found_tag and not quip:HasPrimaryTag(tag) then
                table.insert( warnings, {
                    tag = tag,
                    example = LOC(quip.dialog[1])
                })
            end
        end
    end

    local content = self.sim:GetContentDB()
    local quips_list = content:GetAllQuips()
    for primary_tag, quips in pairs(quips_list) do
        --loop over the tags in these quips
        for _, quip in ipairs( quips ) do
            if not quip:HasPrimaryTag("huntprogressscreen") then
                check_tags(quip.tags:toList(), quip)
                check_tags(quip.notags:toList(), quip)
            end
        end
    end

    return warnings
end

function QuipMatcher:RenderDebugUI(ui, panel)
    if ui:Button("Inspect QuestCentral") then
        panel:PushDebugValue(self.sim)
    end
    ui:SameLineWithSpace()
    if ui:Button("Inspect ContentDB") then
        panel:PushDebugValue(self.sim:GetContentDB())
    end

    self:RenderDebugPanel(ui, panel)

    ui:Spacing()
    self:DebugDraw_Log(ui, panel, panel:GetNode().colorscheme)
end



-- InstanceLog lets us use self:Logf for logs that show in DebugEntity.
QuipMatcher:add_mixin(InstanceLog)
return QuipMatcher
