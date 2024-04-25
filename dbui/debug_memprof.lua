require "constants"
local DebugNodes = require("dbui/debug_nodes")


local DebugMemProf = Class( DebugNodes.DebugNode, function(self)
	self.name = "Debug Memory Profiler"

	local sx, sy = TheSim:GetScreenSize()
	local scale = TheFrontEnd.imgui_font_size
	self.PANEL_WIDTH = sx * 0.9 / scale
	self.PANEL_HEIGHT = sy * 0.9 / scale
end)

local function ShowHelp(panel)
	panel:PushNode(DebugNodes.DebugValue([[
DebugMemProf lets you see current lua memory allocations and function call
counts for a single frame. You can (probably) capture two frames to look for
lua memory leaks.

* Click Capture to collect data from the next frame.
* Right click on a row to be able to see Parents (callers) or Children (called functions).
* Memory allocated by a function is displayed in "Memory (Direct)".
* Memory allocated by a function or its called functions is displayed in "Memory (Total)".
* Add regions in lua to narrow down where allocations are occurring:
	TheSim:ProfilerPush("region")
	...code...
	TheSim:ProfilerPop()
  These regions show up at the bottom of the window with bytes allocated during
  the capture. They will also show up in Tracy.
]]))
end

DebugMemProf.MENU_BINDINGS = {
	{
		name = "Help",
		bindings = {
			{
				name = "DebugMemProf Help",
				fn = function(params)
					ShowHelp(params.panel)
				end,
			},
		},
	},
}

function DebugMemProf:OnActivate(panel)
	TheSim:StartMemProfiler()
end

function DebugMemProf:OnDeactivate(panel)
	TheSim:EndMemProfiler()
end

function DebugMemProf:RenderPanel( ui, panel )
	local x,y = ui:GetCursorPos()
	local w = 70
	ui:SetCursorPosX(ui:GetContentRegionAvail() - w)
	if ui:Button("Help", w) then
		ShowHelp(panel)
	end
	ui:SetCursorPos(x,y)

   	TheSim:DrawMemProfiler()
end

DebugNodes.DebugMemProf = DebugMemProf

return DebugMemProf
