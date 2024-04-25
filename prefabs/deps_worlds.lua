local SceneGenAutoGenData = require "prefabs.scenegen_autogen_data"
local biomes = require "defs.biomes"

-- The worlds/rooms that ship with the game.

local prefabs = {
	TOWN_LEVEL,
}

-- Seems like everything non-town comes in from scenegen.
--~ local WorldAutogenData = require "prefabs.world_autogen_data"
--~ for world in pairs(WorldAutogenData) do
--~ 	if not world.town then
--~ 		table.insert(prefabs, world)
--~ 	end
--~ end

for name,scene_gen in pairs(SceneGenAutoGenData) do
	local biome_location = biomes.locations[scene_gen.dungeon]
	if biome_location and not biome_location.hide then
		table.insert(prefabs, name)
	end
end

return Prefab(GroupPrefab("deps_worlds"), function() end, nil, prefabs)
