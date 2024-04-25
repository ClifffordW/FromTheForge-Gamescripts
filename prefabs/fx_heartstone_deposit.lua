local assets =
{
	Asset("ANIM", "anim/power_drop_boss.zip"),
}

local function MakeAutogenHeart(boss_name)

	local function fn(prefabname)
		local inst = CreateEntity()
		inst:SetPrefabName(prefabname)

		inst.entity:AddTransform()
		inst.entity:AddAnimState()
		inst.entity:AddSoundEmitter()

		inst.AnimState:SetBank("power_drop_boss_"..boss_name)
		inst.AnimState:SetBuild("power_drop_boss")
		inst.AnimState:SetShadowEnabled(true)

		inst:SetStateGraph("sg_fx_heartstone_deposit")

		inst:AddTag("FX")
		inst:AddTag("NOCLICK")
		--[[Non-networked entity]]
		inst.persists = false

		inst.Despawn = function() inst.sg:GoToState("despawn") end

		return inst
	end

	return Prefab("fx_konjur_heart_"..boss_name, fn, assets, nil, nil, NetworkType_ClientMinimal)
end

local biomes = require"defs.biomes"

local ret = {}

for id, def in pairs(biomes.locations) do
    if def.type == biomes.location_type.DUNGEON and not def.hide then
    	for _, boss in ipairs(def.monsters.bosses) do
    		ret[#ret + 1] = MakeAutogenHeart(boss)
    	end
    end
end

return table.unpack(ret)