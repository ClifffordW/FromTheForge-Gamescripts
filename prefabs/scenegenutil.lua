-- A SceneGen generates prop placements at runtime. Its member data specializes it for a particular dungeon.

local GroundTiles = require "defs.groundtiles"
local Lume = require "util.lume"
local SceneGenAutogenData = require "prefabs.scenegen_autogen_data"
local kassert = require "util.kassert"
local prefabutil = require "prefabs.prefabutil"
require "prefabs.world_autogen" -- for CollectAssetsFor*


-- Store lookup of prefab_lookup[biome-name][location-name] = Prefab
-- Default to nil so we crash if we forget to call EnsurePrefabsExist.
local prefab_lookup

-- The constructor creates an Entity from this Prefab.
local function NewSceneGenEntity(name, params)
	local entity = CreateEntity()
	entity:SetPrefabName(name)

	-- TODO we can hook into external event points
	-- entity.OnLoad = OnLoadWorld
	-- entity.OnRemoveEntity = OnRemoveEntity
	-- entity.OnPreLoad = OnPreLoad

	-- TODO translate edit-time params into runtime state
	entity:AddComponent("scenegen", params)

	return entity
end

-- Register the SceneGen Prefab in a global dictionary so we can look it up via biome/dungeon later.
-- Mods may similarly register their SceneGens, or even stomp prior registrations.
local function RegisterSceneGenPrefab(scene_gen, prefab)
	if scene_gen.biome and scene_gen.dungeon then
		prefab_lookup[scene_gen.biome] = prefab_lookup[scene_gen.biome] or {}
		prefab_lookup[scene_gen.biome][scene_gen.dungeon] = prefab
	end
end

-- A prefab is a constructor function and all of its dependencies.
local function NewSceneGenPrefab(name, params)
	local Biomes = require "defs.biomes"
	local props = {}
	local fxes = {}
	for _,zone_gen in ipairs(params.zone_gens or {}) do
		table.appendarrays(props, zone_gen.scene_props)
		table.appendarrays(fxes, zone_gen.fxes)
	end
	props = Lume(props)
		:map("prop")
		:result()
	fxes = Lume(fxes)
		:map("fx")
		:result()

	local destructibles = params.destructibles
		and Lume(params.destructibles)
			:map(function(destructible) return destructible.prop end)
			:result()
		or {}
	local underlay_props = params.underlay_props
		and Lume(params.underlay_props)
			:map(function(prop) return prop.prop end)
			:result()
		or {}
	local particle_systems = params.particle_systems
		and Lume(params.particle_systems)
			:map(function(particle_system) return particle_system.particle_system end)
			:result()
		or {}
	local creature_spawners = {}
	for _, category in pairs(params.creature_spawners) do
		for _, spawner in ipairs(category) do
			table.insert(creature_spawners, spawner.prop)
		end
	end

	local prefabs = {}
	local assets = {
		Asset("PKGREF", "scripts/prefabs/autogen/scenegen/".. name ..".lua"),
		Asset("PKGREF", "scripts/prefabs/scenegen_autogen.lua"),
		Asset("PKGREF", "scripts/prefabs/scenegen_autogen_data.lua"),
		Asset("PKGREF", "scripts/prefabs/scenegenutil.lua"),
	}
	prefabs = table.appendarrays(
		prefabs,
		props,
		creature_spawners,
		destructibles,
		underlay_props,
		particle_systems,
		fxes)
	if params.rooms then
		prefabs = table.appendarrays(prefabs, params.rooms)
	end
	local location_deps = Biomes.GetLocationDeps(params.biome, params.dungeon)
	if location_deps then
		table.insert(assets, location_deps.tile_bank)
		prefabs = table.appendarrays(prefabs, location_deps.prefabs)
	end
	
	for _, environment in ipairs(params.environments) do
		if environment.lighting.colorcube then 
			CollectAssetsForColorCube(assets, environment.lighting.colorcube.entrance)
			CollectAssetsForColorCube(assets, environment.lighting.colorcube.boss) 
		end
		CollectAssetsForCliffRamp(assets, environment.lighting.clifframp)
		CollectAssetsForCliffSkirt(assets, environment.lighting.cliffskirt)

		if environment.water then
			CollectAssetsForWaterRamp(assets, environment.water.water_settings and environment.water.water_settings.ramp)	
		end
	end

	if params.tile_group then
		GroundTiles.CollectAssetsForTileGroup(assets, params.tile_group)
	end

	local prefab = Prefab(
		name,
		function(_) return NewSceneGenEntity(name, params) end,
		assets,
		Lume(prefabs):unique():result()
	)
	RegisterSceneGenPrefab(params, prefab)
	return prefab
end

local group_prefabs = prefabutil.CreateGroupPrefabs(SceneGenAutogenData, {})

local scenegenutil = {}
scenegenutil.ASSERT_ON_FAIL = { "assert_on_fail" }

local all_prefabs

-- Semi-lazily create prefabs. When scenegenutil is only used for queries, we
-- only create the prefabs when one of the functions is called. When used in
-- game, collecting prefabs will immediately create all prefabs so they always
-- exist. Being slightly lazy helps speed up test code that might require this
-- file, but not call it.
local function EnsurePrefabsExist()
	if not all_prefabs then
		prefab_lookup = {}
		all_prefabs = Lume(SceneGenAutogenData)
			:enumerate(NewSceneGenPrefab)
			:merge(group_prefabs)
			:values()
			:result()
	end
end



-- Only for scenegen_autogen. Use GetSceneGenForBiomeLocation to look up scenegens.
function scenegenutil.GetAllPrefabs()
	EnsurePrefabsExist()
	return all_prefabs
end

-- Returns the prefab name for the input biome location.
function scenegenutil.GetSceneGenForBiomeLocation(region_id, location_id, assert_on_failure)
	EnsurePrefabsExist()
	local prefab_list = prefab_lookup[region_id]
	local scene_gen = prefab_list and prefab_list[location_id]
	kassert.assert_fmt(
		not assert_on_failure or scene_gen,
		"No SceneGen registered for %s.%s. Create one and assign it in SceneGenEditor. Then restart the game.",
		region_id,
		location_id
	)
	return scene_gen and scene_gen.name
end

-- Returns the prefab name matching the input location.
function scenegenutil.FindSceneGenForLocation(location_id)
	EnsurePrefabsExist()
	for _, scene_gens in pairs(prefab_lookup) do
		local scene_gen = scene_gens[location_id]
		if scene_gen then
			return scene_gen.name
		end
	end
end

-- Returns a list of layouts (rooms created in WorldEditor) with names ending
-- with suffix. If no matching rooms exist but "nesw" rooms do, return them.
function scenegenutil.FindLayoutsForRoomSuffix(scene_gen, room_type_suffix, exits_suffix)
	kassert.typeof("string", scene_gen, room_type_suffix)
	kassert.typeof("string", scene_gen, exits_suffix)

	local scene_data = SceneGenAutogenData[scene_gen]
	if not (scene_data and scene_data.rooms) then
		return {}
	end

	local suffix = room_type_suffix..exits_suffix
	local perfect_matches = Lume(scene_data.rooms)
		:filter(function(scene_gen_room)
			return string.endswith(scene_gen_room, suffix)
		end)
		:result()
	if next(perfect_matches) then
		return perfect_matches
	end

	suffix = room_type_suffix.."_nesw"
	local all_exits_fallbacks = Lume(scene_data.rooms)
		:filter(function(scene_gen_room)
			return string.endswith(scene_gen_room, suffix)
		end)
		:result()
	return all_exits_fallbacks
end

function scenegenutil.GetAllLocations()
	EnsurePrefabsExist()
	local locations = {}
	for _, scene_gens in pairs(prefab_lookup) do
		locations = table.appendarrays(locations, Lume(scene_gens):keys():result())
	end
	table.sort(locations)
	return locations
end

return scenegenutil
