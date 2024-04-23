-- Generated by tools/imgui_upgrader/build_enums.lua

local ImGuiTreeNodeFlags_None                 = 0
local ImGuiTreeNodeFlags_Selected             = 1    -- 1 << 0
local ImGuiTreeNodeFlags_Framed               = 2    -- 1 << 1
local ImGuiTreeNodeFlags_AllowOverlap         = 4    -- 1 << 2
local ImGuiTreeNodeFlags_NoTreePushOnOpen     = 8    -- 1 << 3
local ImGuiTreeNodeFlags_NoAutoOpenOnLog      = 16   -- 1 << 4
local ImGuiTreeNodeFlags_CollapsingHeader     = 26   -- ImGuiTreeNodeFlags_Framed | ImGuiTreeNodeFlags_NoTreePushOnOpen | ImGuiTreeNodeFlags_NoAutoOpenOnLog
local ImGuiTreeNodeFlags_DefaultOpen          = 32   -- 1 << 5
local ImGuiTreeNodeFlags_OpenOnDoubleClick    = 64   -- 1 << 6
local ImGuiTreeNodeFlags_OpenOnArrow          = 128  -- 1 << 7
local ImGuiTreeNodeFlags_Leaf                 = 256  -- 1 << 8
local ImGuiTreeNodeFlags_Bullet               = 512  -- 1 << 9
local ImGuiTreeNodeFlags_FramePadding         = 1024 -- 1 << 10
local ImGuiTreeNodeFlags_SpanAvailWidth       = 2048 -- 1 << 11
local ImGuiTreeNodeFlags_SpanFullWidth        = 4096 -- 1 << 12
local ImGuiTreeNodeFlags_NavLeftJumpsBackHere = 8192 -- 1 << 13

imgui.TreeNodeFlags = {
	None                 = ImGuiTreeNodeFlags_None,
	Selected             = ImGuiTreeNodeFlags_Selected,             -- Draw as selected
	Framed               = ImGuiTreeNodeFlags_Framed,               -- Draw frame with background (e.g. for CollapsingHeader)
	AllowOverlap         = ImGuiTreeNodeFlags_AllowOverlap,         -- Hit testing to allow subsequent widgets to overlap this one
	NoTreePushOnOpen     = ImGuiTreeNodeFlags_NoTreePushOnOpen,     -- Don't do a TreePush() when open (e.g. for CollapsingHeader) = no extra indent nor pushing on ID stack
	NoAutoOpenOnLog      = ImGuiTreeNodeFlags_NoAutoOpenOnLog,      -- Don't automatically and temporarily open node when Logging is active (by default logging will automatically open tree nodes)
	CollapsingHeader     = ImGuiTreeNodeFlags_CollapsingHeader,
	DefaultOpen          = ImGuiTreeNodeFlags_DefaultOpen,          -- Default node to be open
	OpenOnDoubleClick    = ImGuiTreeNodeFlags_OpenOnDoubleClick,    -- Need double-click to open node
	OpenOnArrow          = ImGuiTreeNodeFlags_OpenOnArrow,          -- Only open when clicking on the arrow part. If ImGuiTreeNodeFlags_OpenOnDoubleClick is also set, single-click arrow or double-click all box to open.
	Leaf                 = ImGuiTreeNodeFlags_Leaf,                 -- No collapsing, no arrow (use as a convenience for leaf nodes).
	Bullet               = ImGuiTreeNodeFlags_Bullet,               -- Display a bullet instead of arrow. IMPORTANT: node can still be marked open/close if you don't set the _Leaf flag!
	FramePadding         = ImGuiTreeNodeFlags_FramePadding,         -- Use FramePadding (even for an unframed text node) to vertically align text baseline to regular widget height. Equivalent to calling AlignTextToFramePadding().
	SpanAvailWidth       = ImGuiTreeNodeFlags_SpanAvailWidth,       -- Extend hit box to the right-most edge, even if not framed. This is not the default in order to allow adding other items on the same line. In the future we may refactor the hit system to be front-to-back, allowing natural overlaps and then this can become the default.
	SpanFullWidth        = ImGuiTreeNodeFlags_SpanFullWidth,        -- Extend hit box to the left-most and right-most edges (bypass the indented area).
	NavLeftJumpsBackHere = ImGuiTreeNodeFlags_NavLeftJumpsBackHere, -- (WIP) Nav: left direction may move to this TreeNode() from any of its child (items submitted between TreeNode and TreePop)
}