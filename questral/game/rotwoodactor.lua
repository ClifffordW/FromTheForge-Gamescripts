local Agent = require "questral.agent"
local NpcAutogenData = require "prefabs.npc_autogen_data"
local kstring = require "util.kstring"


-- Anything specific to how agents work within Rotwood's systems should go
-- here: components, dungeon, player, etc
local RotwoodActor = Class(Agent, function(self, inst)
    self.inst = inst
    self.prefab = inst and inst.prefab
end)

-- This is the npc system role and not related to roles/castdef in questral.
function RotwoodActor:SetNpcRole(role)
    self.role = role
    return self
end

function RotwoodActor:FillOutQuipTags(tag_dict)
    RotwoodActor._base.FillOutQuipTags(self, tag_dict)

    if self.role then
        tag_dict["role_"..self.role] = true
    end

    -- TODO(quest): Can we just rely on the above so the npc entity isn't required?
    if self.inst and self.inst.components.npc then
        tag_dict["role_"..self.inst.components.npc:GetRole()] = true
    end
end

function RotwoodActor:OverrideInteractingPlayerEntity(player)
    -- used for checking if hooks are valid
    self.player_override = player
end

function RotwoodActor:GetInteractingPlayerEntity()
    dbassert(self.inst or self.player_override, "We only know how to get players from conversation.")
    return self.player_override ~= nil and self.player_override or self.inst.components.conversation.target
end

function RotwoodActor:__tostring()
    return string.format("RotwoodActor[%s %s]", tostring(self.inst), kstring.raw(self))
end

function RotwoodActor:GetPrettyName()
    if self.prefab then
        return STRINGS.NAMES[self.prefab]
    end
end

function RotwoodActor:_GetNpcData()
    if self.prefab then
        return NpcAutogenData[self.prefab]
    end
end

function RotwoodActor:GetRole()
    local data = self:_GetNpcData()
    if data then
        return data.role
    end
end

function RotwoodActor:GetSpecies()
    local data = self:_GetNpcData()
    if data then
        return data.species
    end
end

function RotwoodActor:GetHome()
    local data = self:_GetNpcData()
    if data then
        return data.home
    end
end

return RotwoodActor
