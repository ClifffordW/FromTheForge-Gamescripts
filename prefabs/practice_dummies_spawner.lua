local spawnutil = require "util.spawnutil"

local assets = spawnutil.GetEditableAssets()

local patterns = spawnutil.CenterPatternsOnOrigin({
		{
			{ prefab="dummy_toot",	x=0, 		z=0, },
			{ prefab="dummy_toot",	x=7, 		z=0, },
			{ prefab="dummy_toot",	x=5.5, 		z=2.5, },
		},
	})

-- For now, lump these all into a single spawner. We might want to split these
-- out and place different spawners in each biome?
local biome_remap_prefabs = {
	treemon_forest = {
		dummy_toot = {
			"dummy_cabbageroll",
			"dummy_cabbageroll",
			"dummy_cabbageroll",
		},
	},
	owlitzer_forest = {
		dummy_toot = {
			"dummy_battoad",
			"dummy_battoad",
			"dummy_battoad",
		},
	},
	bandi_swamp = {
		dummy_toot = {
			"dummy_bandicoot",
			"dummy_bandicoot",
			"dummy_bandicoot",
		},
	},
	thatcher_swamp = {
		dummy_toot = {
			"dummy_bandicoot",
			"dummy_bandicoot",
			"dummy_bandicoot",
		},
	},
}

local prefabs = spawnutil.GetPossiblePrefabsFromPatterns(patterns)
for _,biome_remap in pairs(biome_remap_prefabs) do
	for _,biome_prefabs in pairs(biome_remap) do
		table.appendarrays(prefabs, biome_prefabs)
	end
end

local function DrawDestinations(inst)
	spawnutil.DrawPatternLocation(inst, patterns)
end

local function EditEditable(inst, ui)
	spawnutil.PatternsEditor(inst, ui, patterns)
end

local function DoSpawn(inst, difficulty)
	local pattern = patterns[1]
	local remap = biome_remap_prefabs[TheDungeon:GetDungeonMap():GetBiomeLocation().id]
	if remap then
		pattern = deepcopy(pattern)
		for _,s in ipairs(pattern) do
			local replacements = remap[s.prefab]
			if replacements then
				s.prefab = rng:PickFromArray(replacements)
			end
		end
	end
	spawnutil.SpawnPattern(inst, pattern)

	spawnutil.FlagForRemoval(inst)
end

local function OnPostLoadWorld(inst)
	local preview = false
	if TheDungeon:GetDungeonMap():IsDebugMap() then
		return
	end

	if TheNet:IsHost() then
		DoSpawn(inst, inst.difficulty)
	end
end

local function fn()
	local inst = spawnutil.CreatePatternSpawner()

	if TheDungeon:GetDungeonMap():IsDebugMap() then
		spawnutil.MakeEditable(inst, "square")
		-- In Tiled, we need grassy areas that are 5x3.
		inst.AnimState:SetScale(5.25, 3)
		inst.debug_draw_task = inst:DoPeriodicTask(0, DrawDestinations, 0)
		inst.EditEditable = EditEditable
	else
		inst.OnPostLoadWorld = OnPostLoadWorld
	end

	return inst
end

return Prefab("practice_dummies_spawner", fn, assets, prefabs)
