local assets = {
	-- Load assets here that will only get used from town (e.g., atlases for screens)
	--
	-- Don't need world prefabs placed in town here: we can pull
	-- them from the placmenets.



	-- DungeonSelectionScreen
	Asset("ANIM", "anim/dungeon_map_art.zip"),
	Asset("ATLAS", "images/bg_world_map_full.xml"),
	Asset("IMAGE", "images/bg_world_map_full.tex"),
	Asset("ATLAS", "images/bg_world_map_art_cloud_above.xml"),
	Asset("IMAGE", "images/bg_world_map_art_cloud_above.tex"),
	Asset("ATLAS", "images/bg_world_map_art_cloud_below.xml"),
	Asset("IMAGE", "images/bg_world_map_art_cloud_below.tex"),
	Asset("ATLAS", "images/bg_world_map_ocean_texture.xml"),
	Asset("IMAGE", "images/bg_world_map_ocean_texture.tex"),

}


-- These don't exist yet.
--~ local inv_equipment = require "gen.atlas.inv_equipment"
--~ for _,atlas in ipairs(inv_equipment.atlases) do
--~         table.insert(assets, Asset("ATLAS", atlas ..".xml"))
--~         table.insert(assets, Asset("IMAGE", atlas ..".tex"))
--~ end

--~ local inv_food = require "gen.atlas.inv_food"
--~ for _,atlas in ipairs(inv_food.atlases) do
--~         table.insert(assets, Asset("ATLAS", atlas ..".xml"))
--~         table.insert(assets, Asset("IMAGE", atlas ..".tex"))
--~ end

-- local inv_town_decoration = require "gen.atlas.inv_town_decoration"
-- for _,atlas in ipairs(inv_town_decoration.atlases) do
--         table.insert(assets, Asset("ATLAS", atlas ..".xml"))
--         table.insert(assets, Asset("IMAGE", atlas ..".tex"))
-- end

local prefabs = {
	GroupPrefab("deps_ui_decor"),
}

return Prefab(GroupPrefab("deps_town"), function() end, assets, prefabs)
