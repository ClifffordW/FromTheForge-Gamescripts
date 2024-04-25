local spawnutil = require "util.spawnutil"
local DebugDraw = require "util.debugdraw"

local room_loot_drops =
{
	"power_drop_player",
	"drop_konjur",
	"power_drop_skill",

	"soul_drop_lesser",
	"soul_drop_greater",
	"soul_drop_heart",

	GroupPrefab("power_drops"),
}

local function DrawPowerSpawns(inst)
	if (TheFrontEnd:GetScreenStackSize() > 1) then return end -- Dont render overtop of fullscreen menus
	local spawns = { -- This is taken from the table TEMP_SPAWNER_PER_PLAYER in powerdropmanager.lua
		{ x = -8, z = 7 },
		{ x =  8, z = 7 },
		{ x = -8, z = -8 },
		{ x =  8, z = -8 },
		{ x = 0, z = -8 },
		{ x = -6, z = 0 },
		{ x = 6, z = 0 },
		{ x = 0, z = 0 },
	}
	local thickness = 0.5
	local lifetime = 0.5
	local pos =  inst:GetPosition()
	for _, drop in ipairs(spawns) do
		DebugDraw.GroundCircle(pos.x + drop.x, pos.z + drop.z, 0.5, UICOLORS.KONJUR_LIGHT, thickness, lifetime)
	end
	DebugDraw.GroundCircle(pos.x, pos.z, 2.25, UICOLORS.KONJUR_LIGHT, thickness, lifetime)
	DebugDraw.GroundCircle(pos.x, pos.z, 3.5, UICOLORS.KONJUR_LIGHT, thickness, lifetime)
	DebugDraw.GroundCircle(pos.x, pos.z, 5.5, UICOLORS.KONJUR_LIGHT, thickness, lifetime)
	DebugDraw.GroundCircle(pos.x, pos.z, 6.5, UICOLORS.KONJUR_LIGHT, thickness, lifetime)
end

local function fn(prefabname)
	local inst = CreateEntity()
	inst:SetPrefabName(prefabname)

	inst.entity:AddTransform()

	if TheDungeon:GetDungeonMap():IsDebugMap() then
		inst:DoPeriodicTask(0.5, DrawPowerSpawns)
		inst.entity:AddAnimState()
		inst.AnimState:SetBank("mouseover")
		inst.AnimState:SetBuild("mouseover")
		inst.AnimState:SetMultColor(table.unpack(UICOLORS.KONJUR_DARK))
		inst.AnimState:PlayAnimation("square")
		inst.AnimState:SetScale(1, 1)
		inst.AnimState:SetOrientation(ANIM_ORIENTATION.OnGround)
		inst.AnimState:SetLayer(LAYER_BACKGROUND)
		inst.AnimState:SetSortOrder(1)
		inst:AddTag("FX")
		inst:AddTag("NOCLICK")
		spawnutil.SetupPreviewPhantom(inst, "power_drop_generic_1p")
	end

	inst:AddTag("CLASSIFIED")
	--[[Non-networked entity]]

	inst:AddComponent("prop")
	inst:AddComponent("snaptogrid")
	inst.components.snaptogrid:SetDimensions(3, 3, -2)

	TheWorld.components.powerdropmanager:AddSpawner(inst)

	return inst
end

return Prefab("room_loot", fn, nil, room_loot_drops)
