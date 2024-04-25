local loc = require "questral.util.loc"
--~ local AgentUtil = require "questral.agentutil"
local qconstants = require "questral.questralconstants"


local ConvoOption = Class(function(self, ...) self:init(...) end)
ConvoOption:add_mixin( require "questral.contentnode" )

-- Could specify dependencies here, but Rotwood uses icons very differently.
--~ ConvoOption:PreloadTextures{
--~     POSITIVE = "station_icons/stationicon_positive.tex",
--~     NEGATIVE = "station_icons/stationicon_negative.tex",
--~ }

ConvoOption:AddStrings{
}

function ConvoOption:init(convoplayer, cxt, txt)
    -- cxt is a context created by the ConvoPlayer and is unrelated to cxt in
    -- quests.
    self.cxt = cxt
    self.convoplayer = convoplayer
    self.txt = txt
    self.fns = {}
    self.tooltips = {}
    self.open_fn_list = self.fns
    self.open_tooltips = self.tooltips
    local info = debug.getinfo(5, "Sl")
    self.id = info.short_src .. tostring( info.currentline )
end

function ConvoOption:SetID(id)
    dbassert(id)
    self.id = id
    return self
end

function ConvoOption:MakeOppo()
    self:SetRightText("<p img='images/ui_ftf_dialog/convo_quest.tex' color=0>")
    return self
end

function ConvoOption:SetSound(snd)
    self.sound = snd
    return self
end

function ConvoOption:MakeQuestion()
    return self:SetRightText("<p img='images/ui_ftf_dialog/convo_more.tex' color=0>")
end

function ConvoOption:MakeMap()
    return self:SetRightText("<p img='images/ui_ftf_dialog/convo_map.tex' color=0>")
end

function ConvoOption:MakeArmor()
    return self:SetRightText("<p img='images/ui_ftf_dialog/convo_armor.tex' color=0>")
end

function ConvoOption:MakeWeapon()
    return self:SetRightText("<p img='images/ui_ftf_dialog/convo_weapon.tex' color=0>")
end

function ConvoOption:MakeFood()
    return self:SetRightText("<p img='images/ui_ftf_dialog/convo_food.tex' color=0>")
end

function ConvoOption:MakePotion()
    return self:SetRightText("<p img='images/ui_ftf_dialog/convo_potions.tex' color=0>")
end

function ConvoOption:MakeItem()
    return self:SetRightText("<p img='images/ui_ftf_dialog/convo_item.tex' color=0>")
end

-- An action to perform when the option is picked. You can call this multiple
-- times and the actions are performed in order.
function ConvoOption:Fn(fn)
    assert( fn == nil or type(fn) == "function" )
    table.insert(self.open_fn_list, fn)
    return self
end

function ConvoOption:SetSubText(txt)
    self.sub_text = txt
    return self
end

function ConvoOption:SubText(id, ...)
    return self:SetSubText( id and self.convoplayer:GetString(id, ...))
end

function ConvoOption:Text(txt)
    self.txt = txt
    return self
end

function ConvoOption:ShowReward(rewards)

    self:AppendRawTooltip( rewards:GetString() )

    local inv = rewards:GetInventory()
    if inv then
        for i, item in ipairs( inv:GetItems() ) do
            self:AppendTooltipData( item )
        end
    end

    return self
end

function ConvoOption:SetAgentButton(agent)
    assert(not self.is_back, "Can't have back agent button.")
    self.agent_button_agent = agent
    return self
end

-- The current_selection is to auto-select that character, in case the player came back to this part of the convo
function ConvoOption:SetCharacterSelection(on_selection_change_fn, current_selection)
    self.character_selection_fn = on_selection_change_fn
    self.character_selection_current = current_selection
    return self
end

function ConvoOption:GiveReward(rewards)
    if self.convoplayer:GetHeader() ~= self.convoplayer:GetQuest() then
        self:ShowReward( rewards )
    end
    self:Fn(function(cx)
            rewards:Grant(cx:GetPlayer())
            if rewards.boon then
                rewards.boon:SetAvailable( true )
                local state = rewards.boon:GetBoonConvo():GetDefaultState()
                cx:GoTo( state, nil, nil, rewards.boon )
            end
        end)
    return self
end

function ConvoOption:_DoSuccess(...)
    if self.on_success_fns then
        for k,v in ipairs(self.on_success_fns) do
            v(self.convoplayer, ...)
        end
    end
end

function ConvoOption:_DoFailure(...)
    if self.on_fail_fns then
        for k,v in ipairs(self.on_fail_fns) do
            v(self.convoplayer, ...)
        end
    end
end

function ConvoOption:OnSuccess(fn)
    assert(self.on_success_fns == nil)
    self.on_success_fns = {fn}
    self.open_fn_list = self.on_success_fns

    self.success_tooltips = {}
    self.open_tooltips = self.success_tooltips

    return self
end

function ConvoOption:OnFailure(fn)
    assert(self.on_fail_fns == nil)
    self.on_fail_fns = {fn}
    self.open_fn_list = self.on_fail_fns

    self.failure_tooltips = {}
    self.open_tooltips = self.failure_tooltips

    return self
end

function ConvoOption:CompleteQuest()
    return self:Fn(function()
            self.cxt.quest:Complete()
        end)
end

-- Choosing this option will complete the input or current objective.
function ConvoOption:CompleteObjective(id)
    return self:Fn(function()
        self.convoplayer:CompleteQuestObjective(id)
    end)
end

function ConvoOption:MarkWithQuests(quests)
    assert(quests)
    if quests then
        for k,v in ipairs(quests) do
            self:MarkWithQuest(v)
        end
    end
    return self
end

function ConvoOption:MarkWithQuest(quest)
    self.quests = self.quests or {}
    table.insert_unique(self.quests, quest or self.cxt.quest)
    return self
end

function ConvoOption:GetQuestMarks()
    return self.quests
end

function ConvoOption:MarkAsNew()
    self.is_new = true
    return self
end

function ConvoOption:SetQuestNode(node)
    if node then
        local quest_marks = node:GetQC():GetQuestManager():CollectMarksForNode(node)
        if #quest_marks > 0 then
            for _, quest in ipairs(quest_marks) do
                self:MarkWithQuest(quest)
            end
        end
    end
    return self
end

-- Number of times this option was picked during this conversation. If we
-- reload/quit and come back, it resets to 0 (it's not saved). Options defined
-- in helper functions need to use SetID().
function ConvoOption:GetPickCount()
    return self.convoplayer.picked_options[self.id] or 0
end
-- Has the user picked this option before during this session? Only valid when
-- called from within an Opt's Fn (where picked will be at least 1).
function ConvoOption:HasPreviouslyPickedOption()
    return self:GetPickCount() > 1
end

-- After user's picked this option, disable it when displayed again in the same
-- session.
function ConvoOption:JustOnce()
    self.show_once = true
    return self
end

function ConvoOption:IsEnabled()
    if self.disabled then
        return false
    end

    return true
end

function ConvoOption:Disable( reason_txt, ... )
    self.disabled = true
    if reason_txt then
        self:AppendTooltip( reason_txt, ... )
    end

    return self
end

function ConvoOption:AppendRawTooltip( txt )
    table.insert( self.open_tooltips, txt )
    return self
end

function ConvoOption:AppendTooltip( tt, ... )
    local txt = self.convoplayer:GetString(tt, ...)
    self:AppendRawTooltip( txt )
    return self
end

function ConvoOption:AppendTooltipData( t )
    table.insert( self.open_tooltips, t )
    return self
end

function ConvoOption:GetTooltips()
    return self.tooltips or table.empty
end

function ConvoOption:GetFailureTooltips()
    return self.failure_tooltips or table.empty
end

function ConvoOption:GetSuccessTooltips()
    return self.success_tooltips or table.empty
end

function ConvoOption:ReqCondition( condition, txt, ... )
    if self.open_fn_list == self.fns then
        if not condition then
            self:Disable( txt, ... )
        end
    end
    return self
end

function ConvoOption:_ReqConditionRaw( condition, txt )
    if self.open_fn_list == self.fns then
        if not condition then
            self:Disable()
            if txt then
                self:AppendRawTooltip(txt)
            end
        end
    end
    return self
end

function ConvoOption:TestCooldown( mem, time, tt )
    time = time or 1
    tt = tt or "TALK.TT_TOO_SOON"

    self:ReqCondition( not self.convoplayer:GetAgent():TestMemory(mem, time), tt)
    return self
end

function ConvoOption:AgentCooldown( mem, time, tt )
    self:TestCooldown( mem, time, tt )

    return self:Fn(function(cx)
            cx:GetAgent():Remember(mem)
        end)
end

function ConvoOption:Priority( priority )
    -- Higher priority options come first.
    self.priority = priority
    return self
end

function ConvoOption:GetPriority()
    return self.priority or 0
end

function ConvoOption:ReqMemory( token, time_since_test, txt, ... )
    local duration = self.convoplayer:GetAgent():GetTimeSinceMemory( token )
    if duration ~= nil then
        self:ReqCondition( duration >= time_since_test, txt, time_since_test - duration, ... )
    end
    return self
end

function ConvoOption:SetRightText( right_text )
    self.right_text = right_text
    return self
end

function ConvoOption:GetRightText()
    return self.right_text
end

function ConvoOption:Icon( tex_id )
    -- self:SetIcon( self.convoplayer:GetCurrentConvo():IMG( tex_id ) or self:IMG( tex_id ))
    return self
end

function ConvoOption:SetHidden( is_hidden )
    self.is_hidden = is_hidden
    return self
end

function ConvoOption:IsHidden()
    if self.show_once and self.convoplayer.picked_options[self.id] then
        return true
    end

    return self.is_hidden == true
end

function ConvoOption:Back()
    assert(not self.is_lower, "Is already lower. Can't be both.")
    assert(not self.agent_button_agent, "Can't have back agent button.")
    self.is_back = true
    return self
end

function ConvoOption:Lower()
    assert(not self.is_back, "Is already back. Can't be both.")
    assert(not self.agent_button_agent, "Can't have back lower button.")
    self.is_lower = true
    return self
end

function ConvoOption:Talk(...)
    local args = {...}
    return self:Fn(function(cx)
        cx:Talk(table.unpack(args))
    end)
end

function ConvoOption:Quip( speaker, ... )
    local tags = {...}
    return self:Fn(function(cx)
        cx:Quip( speaker, tags )
    end)
end

--create wrappers for action calls
local fns = {"End", "Exit", "GoTo", "Close", "EndLoop", "Loop"}
for k,v in ipairs(fns) do
    ConvoOption[v] = function(self, ...)
        local args = {...}
        return self:Fn(function(convoplayer)
                        convoplayer[v](convoplayer, table.unpack(args))
                    end)
    end
end


return ConvoOption
