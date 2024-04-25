local loc = require "questral.util.loc"
local qconstants = require "questral.questralconstants"
local speciesutil = require "util.speciesutil"
--~ local ScalarAccumulator = require "util.scalaraccumulator"
local QuestralActor = require "questral.questralactor"

---------------------------------------------------------------

-- Agent is usually an NPC. They're an actor who can speak in conversations.
-- They could also be a location or enemy or something else.
local Agent = Class(QuestralActor)
Agent:add_mixin( require "questral.contentnode" )

Agent.DebugNodeName = "DebugAgent"

Agent:AddStrings{
}

function Agent:GetGender()
    return self.skin:GetGender()
end

function Agent:OnActivate()
    self.skin = {
        id = "default",
        quip_tag = "", -- appropriate quips?
        role = "scout", -- npc job
    }
end

function Agent:OnDeactivate()
end

-- The localized name of the character
function Agent:GetPrettyName()
    if self.name then
        return self.name:Get()
    --~ elseif self.skin and self.skin:GetPrettyName() then
    --~     return self.skin and self.skin:GetPrettyName()
    else
        return "[NONAME]"
    end
end

function Agent:HasTag(tag)
    return Agent._base.HasTag(self, tag)
end

function Agent:IsPlayer()
    return self:HasTag( qconstants.ETAG.s.PLAYER )
end

function Agent:IsHostile()
    return self.is_hostile
end

function Agent:SetHostile(hostile)
    assert(hostile ~= nil)
    self.is_hostile = hostile
    return self
end

function Agent:__tostring()
    if self.activationId then
        return string.format( "%d-%s'%s'", self.activationId, self.role or self._classname, (self.name and self.name.id) or (self.skin and self.skin.id))
    else
        return string.format( "%s'%s'", self.role or self._classname, (self.name and self.name.id) or (self.skin and self.skin.id) )
    end
end

function Agent:LocMacro(value, ...)
    if value == nil then
        return string.format( "<!node_%d><#ACTOR_NAME>%s</></>", self:GetActivationID() or 0000, self:GetPrettyName() )
    elseif value == "species" then
        local species = self.GetSpecies and self:GetSpecies()
        if species then
            return speciesutil.GetSpeciesPrettyName(species)
        end

    -- Add more like so:
    --~ elseif value == "home" then
    --~     local home = self.GetHome and self:GetHome()
    --~     if home then
    --~         return STRINGS.NAMES[home]
    --~     end

    -- Rotwood doesn't have gender setup and doesn't have generated characters.
    --~ elseif value == "gender" then
    --~     local gender = self:GetGender()
    --~     local args = {...}
    --~     if gender == qconstants.GENDER.s.MALE then
    --~         return args[1] or "[MISSING MALE WORD]"
    --~     elseif gender == qconstants.GENDER.s.FEMALE then
    --~         return args[2] or "[MISSING FEMALE WORD]"
    --~     else
    --~         return args[3] or "[MISSING NONBINARY WORD]"
    --~     end
    --~ elseif value == "hisher" then
    --~     local gender_nouns = (require "content.strings").GENDER_NOUNS
    --~     local gender = self:GetGender()
    --~     return gender_nouns[gender][value]
    end

    return loc.format("[BAD AGENT LOCMACRO '{1}']", value)
end

function Agent:FillOutQuipTags(tag_dict)
    Agent._base.FillOutQuipTags(self, tag_dict)
    -- Add npc data in RotwoodActor.

    if self.playerdata and self.playerdata.quip_tag then
        tag_dict[self.playerdata.quip_tag] = true
    end

    if self:IsHostile() then
        tag_dict.hostile = true
    else
        tag_dict.not_hostile = true
    end
end

function Agent:Remember(id)
    local now = self:GetQC():GetRunCount()
    self.memories = self.memories or {}
    self.memories[id] = now
end

function Agent:HasMemory(id)
    return self.memories and self.memories[id] ~= nil
end

function Agent:GetTimeSinceMemory(id)
    local now = self:GetQC():GetRunCount()
    local when = self.memories and self.memories[id]
    if when then
        return now - when
    end
end

function Agent:TestMemory(id, time_since_test)
    local time_since = self:GetTimeSinceMemory(id)
    return time_since and time_since <= time_since_test
end

return Agent
