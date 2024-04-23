-- Generated by tools/imgui_upgrader/build_enums.lua

local ImGuiButtonFlags_None              = 0
local ImGuiButtonFlags_MouseButtonLeft   = 1 -- 1 << 0
local ImGuiButtonFlags_MouseButtonRight  = 2 -- 1 << 1
local ImGuiButtonFlags_MouseButtonMiddle = 4 -- 1 << 2

imgui.ButtonFlags = {
	None              = ImGuiButtonFlags_None,
	MouseButtonLeft   = ImGuiButtonFlags_MouseButtonLeft,   -- React on left mouse button (default)
	MouseButtonRight  = ImGuiButtonFlags_MouseButtonRight,  -- React on right mouse button
	MouseButtonMiddle = ImGuiButtonFlags_MouseButtonMiddle, -- React on center mouse button
}
