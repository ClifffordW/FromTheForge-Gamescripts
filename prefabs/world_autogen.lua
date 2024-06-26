
--------------------------------------------------------------------------
--This prefab file is for loading autogenerated World prefabs
--------------------------------------------------------------------------

local Constructable = require "defs.constructable"
local Enum = require "util.enum"
local GroundTiles = require "defs.groundtiles"
local MapLayout = require "util.maplayout"
local PropManager = require "components.propmanager"
local WorldAutogenData = require "prefabs.world_autogen_data"
local animtag_init = require "prefabs.animtag_autogen"
local kassert = require "util.kassert"
local krandom = require "util.krandom"
local lume = require "util.lume"
local prefabutil = require "prefabs.prefabutil"
require "util.cliffgen.cliffgen"
require "util.shoredetection"
require "debug.inspectors.lighting"
require "debug.inspectors.sky"
require "debug.inspectors.water"
require "debug.inspectors.shadows"
local TileIdResolver = require "defs.tileidresolver"

local DEFAULT_WATER_COLOR = HexToStr(0x9ac3e500)
local DEFAULT_WATER_HEIGHT = -1.2
local DEFAULT_WATER_BOB_SPEED = 1
local DEFAULT_WATER_BOB_AMPLITUDE = 0.2

local DEFAULT_WATER_WAVE_SPEED = 1
local DEFAULT_WATER_WAVE_HEIGHT = 0.2
local DEFAULT_WATER_WAVE_PERIOD = 1
local DEFAULT_WATER_WAVE_OUTLINE = 0.05

local DEFAULT_WATER_REFRACTION = 0.3
local DEFAULT_WATER_REFRACTION_SPEED = 2


local function OnLoadWorld(inst, data)
	-- OnLoad is called on worlds even when world is generated from scratch.
end

-- Creation order for components on TheWorld:
-- * ctor
-- * OnLoad
-- * OnPostSpawn
-- * OnPostLoadWorld
-- * OnStartRoom
--
-- The world also sends out several events:
-- * room_locked
-- * room_unlocked
-- * room_complete
-- See SpawnCoordinator:_SetRoomComplete for details.
local function OnPostLoadWorld(inst, data)
end



local function OnRemoveEntity(inst)
	assert(TheWorld == inst)
	TheWorld = nil
end

local function IsGroundVisible(inst)
	return TheSim:GetRenderLayerVisible(LAYER_BELOW_GROUND)
end

local function ToggleGroundVisibility(inst)
	local should_show = not inst:IsGroundVisible()
	TheSim:SetRenderLayerVisible(LAYER_BELOW_GROUND, should_show)
	TheSim:SetRenderLayerVisible(LAYER_BACKGROUND, should_show)
end

local function GetPlayerProx(inst)
	return inst.components.playerproxrect or inst.components.playerproxradial
end

-- purposely not local, the editor can reset the collision edge
function GenerateCollisionEdge(inst, trim_at_blockers)
	local verts = GenerateCliffCollision(inst)

	if trim_at_blockers then
		-- Why does FindEntitiesXZ return no results?
		--~ local portals = TheSim:FindEntitiesXZ(0, 0, 10000, {"block_worldbounds"})
		local portals = lume(Ents)
			:values() -- handle gaps
			:filter(function(ent)
				return ent:HasTag("block_worldbounds")
			end)
			:result()

		if next(portals) then
			for i,xz in ipairs(verts) do
				local pt = Vector2(table.unpack(xz))
				local to_origin = pt:normalized() * -1
				for _,portal in ipairs(portals) do
					local playerprox = GetPlayerProx(portal)
					while playerprox:IsXZInRange(pt:unpack()) do
						pt = pt + to_origin
					end
					xz[1] = pt.x
					xz[2] = pt.y
				end
			end
		end
	end

	local looped = false
	inst.Map:SetCollisionEdges(verts, looped)
	return verts
end

local function InitializeWater(inst, params)
	local settings = params.water_settings or {}
	local water = inst.components.worldwater
	water:Enable(settings.has_water)
	if not settings.has_water then
		return
	end

	water:SetColor(HexToRGBFloats(StrToHex(settings.water_color or DEFAULT_WATER_COLOR)))
	water:SetHeight(settings.water_height or DEFAULT_WATER_HEIGHT)
	water:SetAdditiveBlending(settings.additive)
	water:SetRampTexture(settings.ramp and "images/"..settings.ramp..".tex" or "images/water_ramp_01.tex")
	water:SetRefraction(settings.refraction or DEFAULT_WATER_REFRACTION)
	water:SetRefractionSpeed(settings.refraction_speed or DEFAULT_WATER_REFRACTION_SPEED)

	for i = 1,2 do
		local layer_settings = i == 1 and settings.prop or i==2 and settings.cliff or {}
		if not TheDungeon:GetDungeonMap():IsDebugMap() then
			water:SetBobSpeed(layer_settings.bob_speed or DEFAULT_WATER_BOB_SPEED, i)
			water:SetBobAmplitude(layer_settings.bob_amplitude or DEFAULT_WATER_BOB_AMPLITUDE, i)
		else
			water:SetBobSpeed(0, i)
			water:SetBobAmplitude(0, i)
		end
		water:SetWaveSpeed(layer_settings.wave_speed or DEFAULT_WATER_WAVE_SPEED, i)
		water:SetWaveHeight(layer_settings.wave_height or DEFAULT_WATER_WAVE_HEIGHT, i)
		water:SetWavePeriod(layer_settings.wave_period or DEFAULT_WATER_WAVE_PERIOD, i)
		water:SetWaveOutline(layer_settings.wave_outline or DEFAULT_WATER_WAVE_OUTLINE, i)
	end
end

local function SetCollisionEdge(inst, data)
	local looped = false -- the collision editor expects a loop
	inst.Map:SetCollisionEdges(data, looped)
end

local WorldCollision = Enum{ "Locked", "Unlocked", }
function OnRoomLocked(inst)
	inst:_SetWorldCollision(WorldCollision.id.Locked)
end

function OnRoomUnlocked(inst)
	inst:_SetWorldCollision(WorldCollision.id.Unlocked)
end

function CollectDepsForLayout(assets, prefabs, layoutfilename)
	if layoutfilename ~= nil then
		local maplayout = MapLayout(require("map.layouts."..layoutfilename))
		return maplayout:CollectDeps(assets, prefabs)
	end
end

function CollectAssetsForMapShadow(assets, shadow_tilegroup)
	if shadow_tilegroup then
		GroundTiles.CollectAssetsForTileGroup(assets, shadow_tilegroup)
	end
end

function CollectAssetsForCliffRamp(assets, clifframp_texture)
	if clifframp_texture then
		assets[#assets + 1] = Asset("IMAGE", "images/"..clifframp_texture..".tex")
	end
end

function CollectAssetsForWaterRamp(assets, waterramp_texture)
	if waterramp_texture then
		assets[#assets + 1] = Asset("IMAGE", "images/"..waterramp_texture..".tex")
	end
end

function CollectAssetsForCliffSkirt(assets, cliffskirt_texture)
	if cliffskirt_texture then
		assets[#assets + 1] = Asset("ATLAS", "levels/tiles/"..cliffskirt_texture..".xml")
		assets[#assets + 1] = Asset("IMAGE", "levels/tiles/"..cliffskirt_texture..".tex")
	end
end

function CollectAssetsForColorCube(assets, colorcube)
	assets[#assets + 1] = Asset("IMAGE", prefabutil.ColorCubeNameToTex(colorcube))
end

local function SceneFilesFromScenes(scenelist)
	return lume.map(scenelist, function(w)
		return w .."_propdata"
	end)
end

local function IsAuthored(inst)
	if inst:HasTag("town") then return true end
	if string.match(inst.prefab, "_test_") then
		return true
	end
	return TheDungeon:GetDungeonMap():IsInBossArea()
end

local function IsProcedurallyGenerated(inst, proc_gen_mode)
	return TheSceneGen
		and not IsAuthored(inst)
		and not TheDungeon:GetDungeonMap():IsDebugMap()
end

function CollectPropPlacements(scene_files)
	local prop_placements = {}
	for _, scene_file in ipairs(scene_files) do
		local mod_name = "map.propdata." .. scene_file
		if kleimoduleexists(mod_name) then
			local data = require(mod_name)
			kassert.typeof("table", data)
			-- Each prefab is used as a key of the filedata table, with the associated type being an array of placements.
			for prefab, placements in pairs(data) do
				prop_placements[prefab] = table.appendarrays(prop_placements[prefab] or {}, placements)
			end
		else
			TheLog.ch.Prop:printf("Failed to load scene %s for world '%s'.", mod_name, TheWorld.prefab)
		end
	end
	return prop_placements
end

local function MakeAutogenWorld(name, params)
	local assets =
	{
		Asset("ATLAS", "levels/tiles/snowmtn_falloff.xml"),
		Asset("IMAGE", "levels/tiles/snowmtn_falloff.tex"),

		--Asset("SOUND", "sound/forest_stream.bank"),
		--Asset("SOUND", "sound/amb_stream.bank"),
		--Asset("SOUND", "sound/turnoftides_amb.bank"),

		Asset("IMAGE", "images/ramp_toni.tex"),
		Asset("IMAGE", "images/water_ramp_01.tex"),
	}

	local prefabs =
	{
		-- TODO(roomtravel): Move these to BACKEND_PREFABS?
		"sounddebugicon",
		"entityproxy",

		"world_network",

		"hud",
		"mapscreen",
		"focalpoint",
		"offscreenentityproxy",
		"cliffedge",

		"canopy_shadow",
		"stategraph_autogen",
	}

	CollectDepsForLayout(assets, prefabs, params.layout)
	CollectAssetsForMapShadow(assets, params.shadow_tilegroup or "forest_shadow")
	if params.scene_gen_overrides then
		if params.scene_gen_overrides.lighting then
			local lighting = params.scene_gen_overrides.lighting
			CollectAssetsForColorCube(assets, lighting.colorcube and lighting.colorcube.entrance)
			CollectAssetsForColorCube(assets, lighting.colorcube and lighting.colorcube.boss)
			CollectAssetsForCliffRamp(assets, lighting.clifframptexture)
			CollectAssetsForCliffSkirt(assets, lighting.cliffskirt)
		end
	end
	CollectAssetsForWaterRamp(assets, params.water_settings and params.water_settings.ramp)

	local scenelist = params.scenes or { {
			name = name,
	} }

	local scenefiles = SceneFilesFromScenes(lume.map(scenelist, "name"))
	for i,scenefile in ipairs(scenefiles) do
		PropManager.CollectPrefabs(prefabs, scenefile)
	end

	if params.town then
		Constructable.CollectPrefabs(prefabs)
		table.insert(prefabs, GroupPrefab("deps_town"))
	end

	local function OnPreLoad(inst, data)
		-- Don't create props from scenes and scene_gens if we are loading them from a save file.
		if data then
			return
		end

		--Newly generated world
		--Use propmanager to load static layout one time
		--See gamelogic.lua
		inst:AddComponent("propmanager")
		local scene_files = SceneFilesFromScenes(inst.scenelist)
		local function FilterAuthoredDecorFiles(files)
			return lume(files):filter(function(prop_file)
				local decor_tags = {"_early_", "_midway_", "_nearboss_", "_grid_decor_"}
				return not lume(decor_tags):any(function(decor_tag) return string.match(prop_file, decor_tag) end):result()
			end):result()
		end
		if Profile:GetValue("suppress_decor_props", false) then
			scene_files = FilterAuthoredDecorFiles(scene_files)
		elseif inst:ProcGenEnabled() then
			scene_files = FilterAuthoredDecorFiles(scene_files)
		end
		inst.components.propmanager:SetDataFiles(scene_files)
	end

	-- TODO(roomtravel): Shims until migration is complete.
	local function GetCurrentBoss(inst)
		return TheDungeon:GetCurrentBoss()
	end
	local function GetDungeonProgress(inst)
		return TheDungeon:GetDungeonProgress()
	end
	local function IsCurrentRoomType(inst, ...)
		return TheDungeon:IsCurrentRoomType(...)
	end

	local function GetCurrentRoomType(inst)
		return TheDungeon:GetDungeonMap():GetCurrentRoomType()
	end

	local function IsRegionUnlocked(inst, ...)
		return TheDungeon:IsRegionUnlocked(...)
	end

	local function IsLocationUnlocked(inst, ...)
		return TheDungeon:IsLocationUnlocked(...)
	end

	local function IsFlagUnlocked(inst, ...)
		return TheDungeon:IsFlagUnlocked(...)
	end

	local function UnlockRegion(inst, ...)
		return TheDungeon:UnlockRegion(...)
	end

	local function UnlockLocation(inst, ...)
		return TheDungeon:UnlockLocation(...)
	end

	local function UnlockFlag(inst, ...)
		return TheDungeon:UnlockFlag(...)
	end

	local function LockFlag(inst, ...)
		return TheDungeon.progression.components.worldunlocks:LockFlag(...)
	end

	local function GetAllUnlocked(inst, ...)
		return TheDungeon:GetAllUnlocked(...)
	end

	-- local function UnlockRecipe(inst, ...)
	-- 	return TheDungeon:UnlockRecipe(...)
	-- end

	-- local function IsRecipeUnlocked(inst, ...)
	-- 	return TheDungeon:IsRecipeUnlocked(...)
	-- end

	local function GetMetaProgress(inst)
		return TheDungeon:GetMetaProgress()
	end

	-- Encounter is complete or nothing dangerous was happening anyway.
	local function IsSafeFromCombat(inst)
		return inst:HasTag("town")
			or not inst.components.roomclear
			or inst.components.roomclear:IsRoomComplete()
	end

	local function fn(prefabname)
		local inst = CreateEntity()
		inst:SetPrefabName(prefabname)

		assert(TheWorld == nil)
		TheWorld = inst
		TheDungeon.room = inst -- see also dungeon.lua
		inst.net = nil

		inst:AddTag("NOCLICK")
		inst:AddTag("CLASSIFIED")

		if params.town then
			inst:AddTag("town")
		end
		if params.is_debug then
			inst:AddTag("debug")
		end

		inst.persists = false

		--Add core components
		inst.entity:AddTransform()
		inst.entity:AddSoundEmitter()
		inst.entity:AddMap()
		require "components.map" --extends Map component

		inst:AddComponent("meta")
		inst:AddComponent("cameralimits")

		if params.layout ~= nil then
			inst.map_layout = MapLayout(require("map/layouts/"..params.layout))
			inst.has_debug_visible_exits = InstanceParams.dbg and not TheSaveSystem.cheats:GetValue("eliminate_all_exits") or nil
			if not inst.has_debug_visible_exits then
				inst.map_layout:EliminateInvalidExits(TheDungeon:GetDungeonMap())
			end
			local layouttiles = inst.map_layout:GetGroundLayer()

			local from_tile_group = inst.map_layout.layout.tilesets[1].name
			local to_tile_group = TheSceneGen
				and TheSceneGen.components.scenegen.tile_group
				or from_tile_group
			local tile_id_resolver = TileIdResolver(
				layouttiles.data,
				from_tile_group,
				to_tile_group
			)
			if not tile_id_resolver:IsRemapper() then
				TheLog.ch.World:print("Warning: Cannot remap from tile group '"..from_tile_group.."' to '"..to_tile_group.."'.")
				to_tile_group = from_tile_group
			end

			inst.tilegroup = GroundTiles.TileGroups[to_tile_group]
			assert(TheSceneGen or inst.map_layout.tilegroup == inst.tilegroup)

			-- Create a RenderLayer for each tile type in our active TileGroup.
			-- Order is important to have the layers draw correctly.
			for i = 1, #inst.tilegroup.Order do
				local def = GroundTiles.Tiles[inst.tilegroup.Order[i]]
				if def then
					local handle = MapLayerManager:CreateRenderLayer(
						i, --embedded map array value
						resolvefilepath(def.tileset_atlas),
						resolvefilepath(def.tileset_image),
						resolvefilepath(def.noise_texture),
						def.colorize					-- this should probably go? Or is it a nice to have?
					)
					if def.underground then
						inst.Map:SetUndergroundRenderLayer(handle)
					else
						inst.Map:AddRenderLayer(handle)
					end
				end
			end

			--Legacy: IMPASSABLE Id needs to be explicitly set
			inst.Map:SetImpassableType(inst.tilegroup.Ids.IMPASSABLE)

			-- Set the Map size to be the same as the TileLayout.
			assert(layouttiles.width == inst.map_layout.layout.width and layouttiles.height == inst.map_layout.layout.height)
			kassert.assert_fmt(layouttiles.encoding == 'lua' and type(layouttiles.data) == 'table',
				"Export layouts as csv. In Tiled, Map > Map Properties > Set 'Tile Layer Format' to CSV. '%s' was using '%s'.",
				params.layout, layouttiles.encoding)
			inst.Map:SetSize(layouttiles.width, layouttiles.height)

			-- Assign TileIds to each tile so the Map knows what to draw there.
			-- Flip the Y-axis so it visually matches our tile editor
			local tilesidx = 1
			for tiley = layouttiles.height - 1, 0, -1 do
				for tilex = 0, layouttiles.width - 1 do
					local tile_id, _ = tile_id_resolver:IndexToId(tilesidx)
					inst.Map:SetTile(tilex, tiley, tile_id)
					tilesidx = tilesidx + 1
				end
			end

			local bounds = inst.map_layout:GetWorldspaceBounds()
			if bounds then
				-- Convert to world camera limits.
				bounds.min.x = bounds.min.x + TILE_SIZE * 3
				bounds.max.x = bounds.max.x - TILE_SIZE * 3
				bounds.min.y = bounds.min.y + TILE_SIZE * 2
				bounds.max.y = bounds.max.y - TILE_SIZE * 3

				local padding = (bounds.max - bounds.min) / 4
				if bounds.min.x < bounds.max.x then
					inst.components.cameralimits:SetDefaultXRange(bounds.min.x, bounds.max.x, padding.x)
				end
				if bounds.min.y < bounds.max.y then
					inst.components.cameralimits:SetDefaultZRange(bounds.min.y, bounds.max.y, padding.y)
				end
			end

			-- All tile setup must occur before Map:Finalize()
			inst.shadow_layers = {}
			inst.map_shadow = {}
			for tiley = 1, layouttiles.height do
				inst.map_shadow[tiley] = {}
			end
			ApplyShadows(params, true)

			-- I *think* this should only be debug.
			inst.Debug_RemoveShadowLayer = RemoveShadowLayer

			if inst.tilegroup.hasunderground then
				local cliff = {}
				if params.scene_gen_overrides and params.scene_gen_overrides.lighting then
					cliff = params.scene_gen_overrides.lighting
				elseif TheSceneGen then
					cliff = TheSceneGen.components.scenegen.lighting
				end
				inst.cliff_mesh = GenerateCliffMesh(inst, cliff)
				if cliff.clifframp then
					inst.cliff_mesh.Model:SetTopTexture("images/"..cliff.clifframp..".tex")
				else
					inst.cliff_mesh.Model:SetTopTexture("images/ramp_toni.tex")
				end
			end

			inst._SetWorldCollision = function(_inst, collision_type)
				kassert.typeof("number", collision_type)
				local use_locked_collision = WorldCollision.id.Locked == collision_type
				local locked_collision_points = params.worldCollision and params.worldCollision.points
				local unlocked_collision_points = params.worldCollisionUnlocked and params.worldCollisionUnlocked.points
				if use_locked_collision and locked_collision_points then
					SetCollisionEdge(inst, locked_collision_points)
				elseif not use_locked_collision and unlocked_collision_points then
					SetCollisionEdge(inst, unlocked_collision_points)
				else
					GenerateCollisionEdge(inst, use_locked_collision)
				end
			end
			inst:_SetWorldCollision(WorldCollision.id.Locked)
		else
			inst.Map:SetSize(1, 1)
			inst._SetWorldCollision = function(_inst, collision_type) end
		end

		--TODO: remove?
		inst.Map:ResetVisited()

		animtag_init()

		TheGameSettings:GetGraphicsOptions():DisableStencil()
		TheGameSettings:GetGraphicsOptions():DisableLightMapComponent()
		inst.Map:Finalize(true) --true: remove wallsa

		--Public member functions
		inst.OnLoad = OnLoadWorld
		inst.OnPostLoadWorld = OnPostLoadWorld
		inst.OnRemoveEntity = OnRemoveEntity
		inst.IsGroundVisible = IsGroundVisible
		inst.ToggleGroundVisibility = ToggleGroundVisibility
		inst.ProcGenEnabled = IsProcedurallyGenerated

		inst.GetDungeonProgress = GetDungeonProgress
		inst.IsCurrentRoomType = IsCurrentRoomType
		inst.GetCurrentRoomType = GetCurrentRoomType
		inst.GetCurrentBoss = GetCurrentBoss
		inst.IsSafeFromCombat = IsSafeFromCombat

		inst.IsRegionUnlocked = IsRegionUnlocked
		inst.IsLocationUnlocked = IsLocationUnlocked
		inst.IsFlagUnlocked = IsFlagUnlocked
		inst.UnlockRegion = UnlockRegion
		inst.UnlockLocation = UnlockLocation
		inst.UnlockFlag = UnlockFlag
		inst.LockFlag = LockFlag
		inst.GetAllUnlocked = GetAllUnlocked

		inst.GetMetaProgress = GetMetaProgress

		-- Initialize rngs to share the worldmap's. If proc_gen is active, these will be switched to the proc_gen rng
		-- when proc_gen begins.
		local prop_rng_seed = TheDungeon:GetDungeonMap():GetCurrentRoomSeed()
		TheLog.ch.World:printf("Prop RNG Random Seed: %d", prop_rng_seed)
		inst.prop_rng = krandom.CreateGenerator(prop_rng_seed)

		inst:AddComponent("ambientaudio")
		inst:AddComponent("audioparams")
		inst:AddComponent("soundtracker")
		inst:AddComponent("lightcoordinator")

		inst:AddComponent("playerspawner")

		inst:AddComponent("blurcoordinator")

		inst:AddComponent("spawncoordinator")
		inst:AddComponent("powerdropmanager")
		inst:AddComponent("craftingdropmanager")
		inst:AddComponent("konjurrewardmanager")
		inst:AddComponent("questmarkmanager")

		inst:AddComponent("snapgrid")

		inst:AddComponent("worldwater")
		if params.water_settings and params.water_settings.ramp then
			TheSim:SetWaterEdgeRampTexture("images/"..params.water_settings.ramp..".tex")
		else
			TheSim:SetWaterEdgeRampTexture("images/water_ramp_01.tex")
		end

		InitializeWater(inst, params)

		local dungeon_progress = GetDungeonProgress(inst)
		inst.scene_gen_overrides = {}
		if params.scene_gen_overrides then
			if params.scene_gen_overrides.lighting then
				inst.scene_gen_overrides.lighting = true
				ApplyLighting(params.scene_gen_overrides.lighting, dungeon_progress)
			end
			if params.scene_gen_overrides.sky then
				inst.scene_gen_overrides.sky = true
				ApplySky(params.scene_gen_overrides.sky, dungeon_progress)
			end
			if params.scene_gen_overrides.water then
				inst.scene_gen_overrides.water = true
				ApplyWater(params.scene_gen_overrides.water, dungeon_progress)
			end
		end

		if params.cameralimits ~= nil then
			inst.components.cameralimits:SetXRange(params.cameralimits.xmin, params.cameralimits.xmax, params.cameralimits.xpadding)
			inst.components.cameralimits:SetZRange(params.cameralimits.zmin, params.cameralimits.zmax, params.cameralimits.zpadding)
		else
			inst.components.cameralimits:SetToDefaultLimits()
		end

		if params.town then
			inst:AddComponent("npctracker")
			inst:AddComponent("plotmanager")
		else
			inst:AddComponent("roomclear")
			inst:AddComponent("dungeontravel")
		end

		inst:AddComponent("roomlockable")
		inst:ListenForEvent("room_locked", OnRoomLocked)
		inst:ListenForEvent("room_unlocked", OnRoomUnlocked)

		-- Must run after worldmap so we can check if edit mode.
		if
			InstanceParams.dbg
			and InstanceParams.dbg.target_scene
		then
			kassert.typeof("string", InstanceParams.dbg.target_scene)
			if InstanceParams.dbg.want_single_scene then
				inst.scenelist = {}
			else
				local requested_scene = lume.match(scenelist, { name = InstanceParams.dbg.target_scene, })
				if not requested_scene then
					TheLog.ch.Editor:print("Requested scene '%s' that doesn't exist in '%s' (%s) scene list. Did you remove it in the WorldEditor?", InstanceParams.dbg.target_scene, prefabname, name)
				end
				local had_progress = requested_scene and requested_scene.progress
				local matching_scenes = lume.filter(scenelist, function(s)
					if s.progress then
						-- Load a single progress since they're mutually exclusive.
						if had_progress then
							return false
						end
						had_progress = true
					end
					-- No roomtype means all rooms.
					return not s.roomtype
				end)
				inst.scenelist = lume.map(matching_scenes, "name")
				lume.remove(inst.scenelist, InstanceParams.dbg.target_scene) -- prevent dupes
			end
			-- Put target scene first so it becomes our default.
			table.insert(inst.scenelist, 1, InstanceParams.dbg.target_scene)
			InstanceParams.dbg.target_scene = nil
			InstanceParams.dbg.want_single_scene = nil

		elseif TheInput:IsEditMode() then
			-- Default to first scene.
			inst.scenelist = { scenelist[1].name }
		else
			-- Default gameplay behaviour.
			local progress_segment = prefabutil.ProgressToSegment(dungeon_progress)
			local dungeon_boss = GetCurrentBoss(inst)
			local matches = lume.filter(scenelist, function(s)
				if s.progress and s.progress ~= progress_segment then
					return false
				end
				if s.required_boss and s.required_boss ~= dungeon_boss then
					return false
				end
				return not s.roomtype
					or IsCurrentRoomType(inst, s.roomtype)
			end)
			inst.scenelist = lume.map(matches, "name")
		end

		inst.OnPreLoad = OnPreLoad

		TheDungeon:RegisterRoomCreated(inst)
		TheGlobalInstance:PushEvent("room_created", inst)

		inst.DebugDrawEntity = function(self, ui, panel, colors)
			panel:AppendTable(ui, TheDungeon, "TheDungeon")
			ui:Indent() do
				self.map_layout:RenderDebugUI(ui, panel, colors)
			end ui:Unindent()
		end

		inst.IsInitialized = true
		return inst
	end

	return Prefab(name, fn, assets, prefabs)
end

local ret = {}
local groups = {}

for name, params in pairs(WorldAutogenData) do
	if params.group ~= nil and string.len(params.group) > 0 then
		local worldlist = groups[params.group]
		if worldlist ~= nil then
			worldlist[#worldlist + 1] = name
		else
			groups[params.group] = { name }
		end
	end
	ret[#ret + 1] = MakeAutogenWorld(name, params)
end

--Don't need group prefabs for worlds
--[[for groupname, worldlist in pairs(groups) do
	--Dummy prefab (no fn) for loading dependencies
	ret[#ret + 1] = Prefab(GroupPrefab(groupname), nil, nil, worldlist)
end]]

return table.unpack(ret)
