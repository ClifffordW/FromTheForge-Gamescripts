-- This file is dead and removing TheMixer is in progress. Use fmod instead.
--
-- https://klei.slack.com/archives/C030398NKG9/p1695226930685609
local Mixer = Class(function(self)
end)

function Mixer:AddNewMix(name, fadetime, priority, levels)
end
function Mixer:SetLevel(name, lev)
end
function Mixer:Update(dt)
end
function Mixer:PopMix(mixname)
end
function Mixer:PushMix(mixname)
end

return { Mixer = Mixer}
