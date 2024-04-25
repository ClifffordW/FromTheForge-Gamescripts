--------------------------------------------------------------------------
--This prefab file is for loading autogenerated Drop prefabs
--------------------------------------------------------------------------
local Consumable = require "defs.consumable"
local DropsAutogenData = require "prefabs.drops_autogen_data"
local prefabutil = require "prefabs.prefabutil"
require "util.kstring"


local DROP_TYPES =
{
	["solid"] = { symbol = "item", states = { "solid_low", "solid_low2", "solid_med", "solid_high" } },
	["curve"] = { symbol = "item_curve", states = { "curve_low", "curve_low2", "curve_high" } },
	["soft"] = { symbol = "item", states = { "soft_low", "soft_med", "soft_high" } },
	["jiggle"] = { symbol = "item", states = { "jiggle_low", "jiggle_med", "jiggle_high" } },
	["twigfall"] = { symbol = "item", states = { "solid_fall_high" } },
}

local ITEM_PICKUP =
{
	[ITEM_RARITY.s.COMMON] = "item_pickup_common",
	[ITEM_RARITY.s.UNCOMMON] = "item_pickup_uncommon",
	[ITEM_RARITY.s.RARE] = "item_pickup_rare",
	[ITEM_RARITY.s.EPIC] = "item_pickup_epic",
	[ITEM_RARITY.s.LEGENDARY] = "item_pickup_legendary",
	["LUCKY"] = "item_pickup_lucky",
	konjur = "item_pickup_konjur",
}

local ITEM_LAND =
{
	[ITEM_RARITY.s.COMMON] = "item_land_common",
	[ITEM_RARITY.s.UNCOMMON] = "item_land_uncommon",
	[ITEM_RARITY.s.RARE] = "item_land_rare",
	[ITEM_RARITY.s.EPIC] = "item_land_epic",
	[ITEM_RARITY.s.LEGENDARY] = "item_land_legendary",
	["LUCKY"] = "item_land_lucky",
	konjur = "item_land_konjur",
}

local ITEM_GROUNDTRAIL =
{
	[ITEM_RARITY.s.COMMON] = "item_groundtrail_common",
	[ITEM_RARITY.s.UNCOMMON] = "item_groundtrail_uncommon",
	[ITEM_RARITY.s.RARE] = "item_groundtrail_rare",
	[ITEM_RARITY.s.EPIC] = "item_groundtrail_epic",
	[ITEM_RARITY.s.LEGENDARY] = "item_groundtrail_legendary",
	["LUCKY"] = "item_groundtrail_lucky",
	konjur = "item_groundtrail_konjur",
}

local ITEM_AIRTRAIL =
{
	[ITEM_RARITY.s.COMMON] = "item_airtrail_common",
	[ITEM_RARITY.s.UNCOMMON] = "item_airtrail_uncommon",
	[ITEM_RARITY.s.RARE] = "item_airtrail_rare",
	[ITEM_RARITY.s.EPIC] = "item_airtrail_epic",
	[ITEM_RARITY.s.LEGENDARY] = "item_airtrail_legendary",
	konjur = "item_airtrail_konjur",
}


local prefabs =
{
	"item_pickup",  -- doesn't appear to be used anywhere
}

local item_collections = {
	ITEM_PICKUP,
	ITEM_LAND,
	ITEM_GROUNDTRAIL,
	ITEM_AIRTRAIL,
}
for key,items in pairs(item_collections) do
	for rarity,p in pairs(items) do
		table.insert(prefabs, p)
	end
end


local function MakePickupable(inst)
	inst.components.loot:MakePickupable()
end

local function OnPickedUp(inst, player, item)
	local x, z = inst.Transform:GetWorldXZ()
	local pfx
	if inst.prefab == "drop_konjur" then
		pfx = ITEM_PICKUP.konjur
	else
		pfx = ITEM_PICKUP[item.rarity]
	end
	local particles = SpawnPrefab(pfx, inst)
	particles.Transform:SetPosition(x, 0, z)
	particles:DoTaskInTime(1, particles.Remove)

	if inst.components.loot.lucky then
		local particles = SpawnPrefab(ITEM_PICKUP.LUCKY)
		particles.Transform:SetPosition(x, 0, z)
		particles:DoTaskInTime(1, particles.Remove)
	end
end

local function OnMove(inst)
	local pfx
	if inst.prefab == "drop_konjur" then
		pfx = ITEM_GROUNDTRAIL.konjur
	else
		pfx = ITEM_GROUNDTRAIL[inst.rarity]
	end

	local particles = SpawnPrefab(pfx, inst)
	particles.entity:SetParent(inst.entity)

	if inst.components.loot.lucky then
		local particles = SpawnPrefab(ITEM_GROUNDTRAIL.LUCKY)
		particles.entity:SetParent(inst.entity)
	end

	if inst.glow_fx then
		inst.glow_fx:Remove()
	end
end

local function OnLand(inst, rarity)
	local x, z = inst.Transform:GetWorldXZ()
	local pfx
	if inst.prefab == "drop_konjur" then
		pfx = ITEM_LAND.konjur
	else
		pfx = ITEM_LAND[rarity]
	end
	local particles = SpawnPrefab(pfx, inst)
	particles.Transform:SetPosition(x, 0, z)
	particles:DoTaskInTime(1, particles.Remove)

	if inst.components.loot.lucky then
		local particles = SpawnPrefab(ITEM_LAND.LUCKY)
		particles.Transform:SetPosition(x, 0, z)
		particles:DoTaskInTime(1, particles.Remove)
	end

	if inst.trail_particles then
		inst.trail_particles.components.particlesystem:StopThenRemoveEntity()
		inst.trail_particles = nil
	end

	if inst.lucky_trail_particles then
		inst.lucky_trail_particles.components.particlesystem:StopThenRemoveEntity()
		inst.lucky_trail_particles = nil
	end
end

local function OnSave(inst, data)
	data.flip = inst._flip or nil
end

local function OnLoad(inst, data)
	inst.sg:GoToState("loaded")

	if inst._flip ~= nil then
		inst._flip = data ~= nil and data.flip == true
		inst.AnimState:SetScale(inst._flip and -1 or 1, 1)
	end
end

function MakeAutogenDrop(name, params, debug)
	local assets =
	{
		Asset("PKGREF", "scripts/prefabs/autogen/drops/".. name ..".lua"),
		Asset("PKGREF", "scripts/prefabs/drops_autogen.lua"),
		Asset("PKGREF", "scripts/prefabs/drops_autogen_data.lua"),
		Asset("ANIM", "anim/drop_anims.zip"), -- Might be the movement anims for the drops.
	}

	if params.build ~= nil then
		prefabutil.TryAddAsset_Anim(assets, params.build, debug)
	end


	local function fn(prefabname)
		local loot_drop = nil
		local inst = CreateEntity()
		inst:SetPrefabName(prefabname)

		inst.entity:AddTransform()
		inst.entity:AddAnimState()

		local droptype = DROP_TYPES[params.droptype]

		inst.AnimState:SetBank("drop_anims")
		if params.build ~= nil and params.symbol ~= nil then
			inst.AnimState:SetBuild(params.build)
			inst.AnimState:OverrideSymbol(droptype.symbol, params.build, params.symbol)
		end
		inst.AnimState:SetShadowEnabled(true)

		if not params.noflip then
			if params.motionfacing then
				inst.Transform:SetTwoFaced()
			elseif params.randomflip then
				inst._flip = math.random() < .5
				if inst._flip then
					inst.AnimState:SetScale(-1, 1)
				end
			elseif params.reversefacing then
				--Whoever's spawning us will handle flipping our scaling
				--so that our facing is independent of physics direction
				inst.reversefacing = true
			else
				--Whoever's spawning us will handle flipping our scaling
				--so that our facing is independent of physics direction
				inst.autofacing = true
			end
		end

		inst.droppos = params.pos

		MakeItemDropPhysics(inst, 1)

		inst:AddComponent("hitstopper")

		inst:AddComponent("loot")
			:SetOnPickedUpFn(OnPickedUp)
			:SetLootType(params.droptype)

		local rarity = ITEM_RARITY.s.COMMON

		local pfx
		if params.loot_id then
			inst.components.loot:SetLootID(params.loot_id)
			local def = Consumable.FindItem(params.loot_id)
			rarity = def.rarity
			inst.rarity = rarity
			if params.loot_id == "konjur" then
				pfx = ITEM_AIRTRAIL.konjur
			end
		end

		if pfx == nil then
			pfx = ITEM_AIRTRAIL[rarity]
		end

		local trail = SpawnPrefab(pfx, inst)
--		trail.components.particlesystem:LoadParams(pfx)
		-- trail.entity:SetParent(inst.entity)
		trail.Transform:SetPosition(0,0,0)
		trail.entity:AddFollower()
		local symbol = params.droptype == "curve" and "item_curve" or "item"
		trail.Follower:FollowSymbol(inst.GUID, symbol)
		inst.trail_particles = trail
		-- we want this attached to the symbol, not the base of the entity
		-- symbol is "item" or "item_curve"

		if params.count_thresholds then
			inst.components.loot:SetCountThresholds(params.count_thresholds)

			inst.SetSymbolOverride = function(_inst, symbol)
				inst.AnimState:OverrideSymbol(droptype.symbol, params.build, symbol)
			end
		end

		inst:SetStateGraph("sg_drops")

		local state = droptype.states[math.random(#droptype.states)]
		local speed = 1 + math.random()
		inst.sg:GoToState(state, speed)

		inst.MakePickupable = MakePickupable
		inst.OnSave = OnSave
		inst.OnLoad = OnLoad
		inst.OnLand = function() OnLand(inst, rarity) end
		inst.OnMove = OnMove

		return inst
	end


	return Prefab(name, fn, assets, prefabs)
end

local ret = {}

for name, params in pairs(DropsAutogenData) do
	ret[#ret + 1] = MakeAutogenDrop(name, params)
end

prefabutil.CreateGroupPrefabs(DropsAutogenData, ret)

return table.unpack(ret)
