local prefabs =
{
	GroupPrefab("UI"),
}

local function SetBusy(inst)
	inst.components.npcmarker:SetBusy()
end

local function SpawnMarker(inst)
	inst.components.npcmarker:SpawnMarkerFX()
end

local function DespawnMarker(inst, cb)
	inst.components.npcmarker:DespawnMarkerFX(cb)
end

local function fn(prefabname)
	local inst = CreateEntity()
	inst:SetPrefabName(prefabname)
	inst.entity:AddTransform()
	inst.entity:AddFollower()

	inst:AddTag("FX")
	inst:AddTag("NOCLICK")
	--[[Non-networked entity]]
	inst.persists = false

	inst:AddComponent("npcmarker")

	inst.SpawnMarker = SpawnMarker
	inst.DespawnMarker = DespawnMarker
	inst.SetBusy = SetBusy

	return inst
end

return Prefab("npcmarker", fn, nil, prefabs)
