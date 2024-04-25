local assets = {
	-- Assets used in gameplay.
	--
	-- If you have anything town-specific, put it in deps_town.lua instead.
	-- If it needs to be loaded in mainmenu, see global.lua.
	-- TODO: Rename this file deps_hud.lua and use GroupPrefab.


	--In-game only
	Asset("ANIM", "anim/boss_healthbar.zip"),
	Asset("ANIM", "anim/potion_widget.zip"),
	Asset("ANIM", "anim/world_map_banner.zip"),

	-- Dungeon Map Screen
	Asset("ANIM", "anim/dungeon_map_node_icons.zip"),
	Asset("ANIM", "anim/dungeon_map_paths.zip"),
	Asset("ANIM", "anim/dungeon_map_scroll.zip"),
	Asset("ANIM", "anim/dungeon_map_tally_marks.zip"),
	Asset("ATLAS", "images/bg_dungeonmap_paperborder.xml"),
	Asset("IMAGE", "images/bg_dungeonmap_paperborder.tex"),
	Asset("ATLAS", "images/ui_dungeonmap.xml"),
	Asset("IMAGE", "images/ui_dungeonmap.tex"),

	-- These aren't actually prefabs, so they need to be a dependency somewhere.
	Asset("PKGREF", "scripts/prefabs/bossutil.lua"),
	Asset("PKGREF", "scripts/prefabs/prefabutil.lua"),

}

local prefabs = {
	GroupPrefab("deps_autogen"),
}

return Prefab("hud", function() end, assets, prefabs)
