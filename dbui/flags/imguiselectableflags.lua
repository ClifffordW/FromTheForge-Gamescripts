-- Generated by tools/imgui_upgrader/build_enums.lua

local ImGuiSelectableFlags_None             = 0
local ImGuiSelectableFlags_DontClosePopups  = 1  -- 1 << 0
local ImGuiSelectableFlags_SpanAllColumns   = 2  -- 1 << 1
local ImGuiSelectableFlags_AllowDoubleClick = 4  -- 1 << 2
local ImGuiSelectableFlags_Disabled         = 8  -- 1 << 3
local ImGuiSelectableFlags_AllowOverlap     = 16 -- 1 << 4

imgui.SelectableFlags = {
	None             = ImGuiSelectableFlags_None,
	DontClosePopups  = ImGuiSelectableFlags_DontClosePopups,  -- Clicking this doesn't close parent popup window
	SpanAllColumns   = ImGuiSelectableFlags_SpanAllColumns,   -- Selectable frame can span all columns (text will still fit in current column)
	AllowDoubleClick = ImGuiSelectableFlags_AllowDoubleClick, -- Generate press events on double clicks too
	Disabled         = ImGuiSelectableFlags_Disabled,         -- Cannot be selected, display grayed out text
	AllowOverlap     = ImGuiSelectableFlags_AllowOverlap,     -- (WIP) Hit testing to allow subsequent widgets to overlap this one
}
