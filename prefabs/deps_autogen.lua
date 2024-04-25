-- References for files created with PrefabEditorBase but aren't actually
-- prefabs. Maybe we should make it save them to a different location, but for
-- now do it this way. We need these package references so they don't get
-- stripped from the build.

local assets = {}

for name,val in pairs(require("prefabs.animtag_autogen_data")) do
	table.insert(assets, Asset("PKGREF", "scripts/prefabs/autogen/animtag/".. name ..".lua"))
end
table.insert(assets, Asset("PKGREF", "scripts/prefabs/animtag_autogen.lua"))
table.insert(assets, Asset("PKGREF", "scripts/prefabs/animtag_autogen_data.lua"))

-- See deps_player_cosmetics for cosmetic_autogen_data.

for name,val in pairs(require("prefabs.curve_autogen_data")) do
	table.insert(assets, Asset("PKGREF", "scripts/prefabs/autogen/curve/".. name ..".lua"))
end
table.insert(assets, Asset("PKGREF", "scripts/prefabs/curve_autogen_data.lua"))

for name,val in pairs(require("prefabs.mappath_autogen_data")) do
	table.insert(assets, Asset("PKGREF", "scripts/prefabs/autogen/mappath/".. name ..".lua"))
end
table.insert(assets, Asset("PKGREF", "scripts/prefabs/mappath_autogen_data.lua"))

-- Don't load any param files for AnimTester (it's debug-only), but we need the
-- top-level collection (which will be empty) for the editor to init.
table.insert(assets, Asset("PKGREF", "scripts/prefabs/animtest_autogen_data.lua"))


return Prefab(GroupPrefab("deps_autogen"), function() end, assets)
