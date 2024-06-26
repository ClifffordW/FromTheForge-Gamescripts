-- Generated by tools/imgui_upgrader/build_enums.lua

local ImFontAtlasFlags_None               = 0
local ImFontAtlasFlags_NoPowerOfTwoHeight = 1 -- 1 << 0
local ImFontAtlasFlags_NoMouseCursors     = 2 -- 1 << 1
local ImFontAtlasFlags_NoBakedLines       = 4 -- 1 << 2

imgui.FontAtlasFlags = {
	None               = ImFontAtlasFlags_None,
	NoPowerOfTwoHeight = ImFontAtlasFlags_NoPowerOfTwoHeight, -- Don't round the height to next power of two
	NoMouseCursors     = ImFontAtlasFlags_NoMouseCursors,     -- Don't build software mouse cursors into the atlas (save a little texture memory)
	NoBakedLines       = ImFontAtlasFlags_NoBakedLines,       -- Don't build thick line textures into the atlas (save a little texture memory, allow support for point/nearest filtering). The AntiAliasedLinesUseTex features uses them, otherwise they will be rendered using polygons (more expensive for CPU/GPU).
}
