-- Generated by tools/imgui_upgrader/build_enums.lua

local ImGuiComboFlags_None           = 0
local ImGuiComboFlags_PopupAlignLeft = 1  -- 1 << 0
local ImGuiComboFlags_HeightSmall    = 2  -- 1 << 1
local ImGuiComboFlags_HeightRegular  = 4  -- 1 << 2
local ImGuiComboFlags_HeightLarge    = 8  -- 1 << 3
local ImGuiComboFlags_HeightLargest  = 16 -- 1 << 4
local ImGuiComboFlags_NoArrowButton  = 32 -- 1 << 5
local ImGuiComboFlags_NoPreview      = 64 -- 1 << 6

imgui.ComboFlags = {
	None           = ImGuiComboFlags_None,
	PopupAlignLeft = ImGuiComboFlags_PopupAlignLeft, -- Align the popup toward the left by default
	HeightSmall    = ImGuiComboFlags_HeightSmall,    -- Max ~4 items visible. Tip: If you want your combo popup to be a specific size you can use SetNextWindowSizeConstraints() prior to calling BeginCombo()
	HeightRegular  = ImGuiComboFlags_HeightRegular,  -- Max ~8 items visible (default)
	HeightLarge    = ImGuiComboFlags_HeightLarge,    -- Max ~20 items visible
	HeightLargest  = ImGuiComboFlags_HeightLargest,  -- As many fitting items as possible
	NoArrowButton  = ImGuiComboFlags_NoArrowButton,  -- Display on the preview box without the square arrow button
	NoPreview      = ImGuiComboFlags_NoPreview,      -- Display only a square arrow button
}
