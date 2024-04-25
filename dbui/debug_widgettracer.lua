local DebugNodes = require "dbui.debug_nodes"
local DebugWidget = require "dbui.debug_widget"
local Enum = require "util.enum"
local Widget = require "widgets.widget"
local iterator = require "util.iterator"
require "input.input"


----------------------------------------------------
-- A debug class used to trace hover/control handling through the Widget hierarchy.
-- Originally from Griftlands.

local DebugWidgetTracer = Class(DebugNodes.DebugNode, function(self, ...) self:init(...) end)

DebugWidgetTracer.PANEL_WIDTH = 600
DebugWidgetTracer.PANEL_HEIGHT = 600
DebugWidgetTracer.MENU_BINDINGS = DebugWidget.MENU_BINDINGS

local Devices = Enum{
	"Keyboard",
	"Mouse",
	"Gamepad",
}


function DebugWidgetTracer:init( tracer )
	DebugNodes.DebugNode._ctor(self, "Widget Tracer")
    self.tracer = tracer
    self.menu_params = { tracer }

    self.all_controls = { "HOVER" }
    for k, v in iterator.sorted_pairs( Controls.Digital ) do
        table.insert( self.all_controls, k )
    end
end

function DebugWidgetTracer:PushWidget( widget )
    assert(Widget.is_instance(widget))
    table.insert( self.trace, widget )
end

function DebugWidgetTracer:PopWidget( desc )
    table.insert( self.trace, desc )
end

function DebugWidgetTracer:_GetInputDevice()
	if self.input_device_name == Devices.s.Keyboard then
		return TheInput:GetKeyboard()
	elseif self.input_device_name == Devices.s.Mouse then
		return TheInput:GetMouse()
	elseif self.input_device_name == Devices.s.Gamepad then
		return TheInput:GetGamepad(self.gamepad_id or 1)
	end
end

function DebugWidgetTracer:RunTrace()
    self.trace = {}
    if (self.control_idx or 1) == 1 then
        -- Same logic as FrontEnd:FocusHoveredWidget()
        local x, y = TheFrontEnd:GetUIMousePos()
        TheFrontEnd:CheckMouseHover(x, y, self)
    else
        local controls = TheInput.ControlSet()
        controls:AddControl( self.all_controls[ self.control_idx or 1 ] )
		controls:SetDevice(self:_GetInputDevice())
        local trace = self
        TheFrontEnd:OnControlDown( controls, nil, trace )
    end
end

function DebugWidgetTracer:RenderPanel( ui, panel )
	if TheInput:IsKeyDown(InputConstants.Keys.CTRL)
		and TheInput:IsKeyDown(InputConstants.Keys.I)
		and not ui:WantCaptureMouse()
	then
		self:RunTrace()
	end

	self.input_device_name = ui:_Enum("Input Device", self.input_device_name, Devices)
	if self.input_device_name == Devices.s.Gamepad then
		self.gamepad_id = ui:_SliderInt("Gamepad ID", self.gamepad_id or 1, 1, 4)
	end

	for hunter_id=1,MAX_PLAYER_COUNT do
		ui:Value("Focus p"..hunter_id, TheFrontEnd:GetFocusWidget(hunter_id))
	end
    ui:Value("Hover", TheFrontEnd:GetHoverWidget())

    local idx = ui:_Combo( "Control", self.control_idx or 1, self.all_controls )
    if idx and idx ~= self.control_idx then
        self.control_idx = idx
    end
    ui:Separator()

    if self.trace == nil then
        ui:TextColored( HexToRGB(0x777777FF), "No trace." )
        ui:Text( "Use CTRL+I to trace a Control over the current mouse position." )
    else
        ui:Text( string.format( "%d widgets traced", #self.trace / 2 ))
        local depth = 0
        for i, v in ipairs( self.trace ) do
            if Widget.is_instance(v) then
                if depth == 0 and ui:TreeNode( string.format( "%s##%d", tostring(v), i )) then
                    panel:AppendTable( ui, v )
                else
                    depth = depth + 1
                end
            else
                if depth <= 0 then
                    ui:Text( v )
                    ui:TreePop()
                else
                    depth = depth - 1
                end
            end
        end
    end
end


DebugNodes.DebugWidgetTracer = DebugWidgetTracer
return DebugWidgetTracer
