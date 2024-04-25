local assets =
{
	Asset("ANIM", "anim/fx_thatcher_acid_geyser.zip"),
    Asset("ANIM", "anim/destructible_bandiforest_ceiling.zip"),
}

local prefabs =
{
	"fx_ground_target_red",
}

local function fn(prefabname, is_right)
	local inst = CreateEntity()
	inst:SetPrefabName(prefabname)

    inst.entity:AddTransform()
	inst.entity:AddAnimState()
	inst.entity:AddSoundEmitter()

	local r, g, b = HexToRGBFloats(StrToHex("98D023FF"))
	local intensity = 0.3
	inst.AnimState:SetLayerBloom("fx", r, g, b, intensity)
	inst.AnimState:SetLayerBloom("fx", r, g, b, intensity)

	inst.AnimState:SetShadowEnabled(false)
	inst.AnimState:SetRimEnabled(true)
	inst.AnimState:SetRimSize(3)
	inst.AnimState:SetRimSteps(3)

	inst.AnimState:SetBank("fx_thatcher_acid_geyser")
	inst.AnimState:SetBuild("fx_thatcher_acid_geyser")

	-- We want a specific version of this geyser without he pink highlights when in normal dungeon rooms
	local is_center = TheWorld:GetCurrentRoomType() ~= "boss"
	inst.is_center = is_center
	inst.is_right = is_right

	inst:SetStateGraph("levelprops/sg_thatcher_acid_geyser")

	inst:AddTag("prop") -- Classify this as a prop for prop-related interactions.
	inst:AddTag("acid_geyser")

	-- Spawn the bottom layer & set layering to make it appear properly among other background props.
	local base = CreateEntity()

	base.entity:SetName(prefabname .. "_base")
	base.entity:AddTransform()
	base.entity:AddAnimState()

	base.AnimState:SetBank("fx_thatcher_acid_geyser")
	base.AnimState:SetBuild("fx_thatcher_acid_geyser")
	base.AnimState:SetLayer(LAYER_BELOW_GROUND)
	base.AnimState:SetIsBGElement(true)
	base.AnimState:SetIsFGElement(false)
	base.AnimState:SetSortOrder(0)

	local anim = is_right and "r_base" or "l_base"
	anim = is_center and "c_base" or anim
	base.AnimState:PlayAnimation(anim)

	base.entity:AddFollower()
	base.entity:SetParent(inst.entity)
	inst.child_inst = base

	return inst
end

local function fn_right(prefabname)
	local inst = fn(prefabname, true)
	return inst
end

return Prefab("thatcher_acid_geyser_left", fn, assets, prefabs, nil, NetworkType_SharedHostSpawn),
	Prefab("thatcher_acid_geyser_right", fn_right, assets, prefabs, nil, NetworkType_SharedHostSpawn)
