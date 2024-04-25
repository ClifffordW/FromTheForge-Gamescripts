local Power = require "defs.powers"
local Lume = require "util.lume"

local biomes_with_hazards = {"thatcher_swamp"} --Add biomes that have hazards here

local TileHazard = Class(function(self, inst)
	self.inst = inst
    self.poweracid = Power.FindPowerByName("acid")
    self.hazardactive = false

    --Only run this thing when in use
    local biome_location = TheDungeon:GetDungeonMap():GetBiomeLocation()
    if (Lume.find(biomes_with_hazards, biome_location.id)) then
        self.inst:StartUpdatingComponent(self)
    end
end)

local function InValidState(inst)
    return not inst:IsDying() and not inst:IsDead()
end

function TileHazard:OnUpdate(dt)
	if (TheWorld.zone_grid) then
        local x, z = self.inst.Transform:GetWorldXZ()
		local tile, tile_name = TheWorld.zone_grid:GetTile({x = x, z = z})
        if (InValidState(self.inst) and not self.inst.sg:HasStateTag("airborne") and not self.inst.sg:HasStateTag("airborne_high") and tile_name == "ACIDPOOL") then
            if (not self.inst.components.powermanager:HasPower(self.poweracid)) then
                local power = self.inst.components.powermanager:CreatePower(self.poweracid)
                self.inst.components.powermanager:AddPower(power, nil)
                self.hazardactive = true
            end
        else
            if (self.hazardactive and self.inst.components.powermanager:HasPower(self.poweracid)) then
                self.inst.components.powermanager:RemovePowerByName("acid", true)
                self.hazardactive = false
            end
        end
    end
end

return TileHazard