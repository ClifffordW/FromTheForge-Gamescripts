local RotwoodActor = require "questral.game.rotwoodactor"
local kstring = require "util.kstring"


local RotwoodPlayer = Class(RotwoodActor, function(self, player)
    assert(player, "Players must always exist.")
    self:_SetPlayer(player)
end)

function RotwoodPlayer:__tostring()
    return string.format("RotwoodPlayer[%s %s]", self.player, kstring.raw(self))
end

function RotwoodPlayer:_SetPlayer(player)
    assert(player)
    self.inst = player
    return self
end

function RotwoodPlayer:GetPrettyName()
    -- Ignore base implementation!

    -- Not using player gamertag since title seems more thematic:
    -- return self.inst:GetCustomUserName()
    return self.inst.components.playertitleholder:GetPretty()
end

function RotwoodPlayer:GetRole()
    return "player"
end

function RotwoodPlayer:GetSpecies()
    return self.inst.components.charactercreator:GetSpecies()
end

return RotwoodPlayer
