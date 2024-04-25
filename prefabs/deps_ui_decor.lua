local assets = {}

local inv_town_decoration = require "gen.atlas.inv_town_decoration"
for _,atlas in ipairs(inv_town_decoration.atlases) do
        table.insert(assets, Asset("ATLAS", atlas ..".xml"))
        table.insert(assets, Asset("IMAGE", atlas ..".tex"))
end


return Prefab(GroupPrefab("deps_ui_decor"), function() end, assets)