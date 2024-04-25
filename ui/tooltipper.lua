local Tooltip = require "widgets/tooltip"
local UIHelpers = require "ui/uihelpers"
local kassert = require "util.kassert"
require "class"
require "constants"


local TTDELAY = 0--.2

local ToolTipper = Class(function(self, hunter_id)
	self.hunter_id = hunter_id
	self.tooltip_widgets = {}
	self.tooltip_delay = TTDELAY
end)

function ToolTipper:OnControl(controls, down, trace)
	if controls:Has(Controls.Digital.INVENTORY_EXAMINE) then
		if self.tooltip_widget
			and self.tooltip_widget.OnExamine -- only if it supports examine
			and self.tooltip_focus
			and self.tooltip_widget.shown
			and not self.tooltip_focus.removed
			and not self.tooltip_widget.ignores_input
		then
			self.tooltip_widget:OnExamine(down)
			return true
		end
	end
end

function ToolTipper:UpdateToolTip(dt)
	if TheFrontEnd.fading then
		if self.tooltip_widget then
			self.tooltip_widget:Hide()
		end
		return

	end
	local focus
	if self.tooltip_focus_override then
		if self.tooltip_focus_override.removed then
			self.tooltip_focus_override = nil
		else
			focus = self.tooltip_focus_override
		end
	end

	if focus == nil then
		if self.hunter_id == TheInput:GetMouse():GetOwnerId() then
			focus = TheFrontEnd:GetHoverWidget()
		end
		-- If the current focused widget should show tooltip on focus, do that
		local focus_widget = TheFrontEnd:GetFocusWidget(self.hunter_id)
		if focus_widget then
			if focus_widget.show_tooltip_on_focus then
				focus = focus_widget
			else
				-- If any ancestor of focus_widget is flagged 'show_child_tooltip_on_focus', then also show tooltip.
				local focus_parent = focus_widget.parent
				while focus_parent do
					if focus_parent.show_child_tooltip_on_focus then
						focus = focus_widget
						break
					end
					focus_parent = focus_parent.parent
				end
			end
		end
	end

	local tt_class = Tooltip
	local tt

	if focus then
		while tt == nil and focus do
			tt = focus:GetToolTip()
			tt_class = focus:GetToolTipClass() or Tooltip
			if not tt then
				focus = focus.parent
			elseif type(tt) ~= 'string'  then
				-- We should hit a similar assert in Widget:SetToolTip() long before this point.
				kassert.assert_fmt(focus:GetToolTipClass(), "A widget used self.tooltip for something other than the tooltip text: %s", focus)
			end
		end
	end

	if tt_class and self.tooltip_widgets[ tt_class ] == nil then
		--print( "Creating new shared tooltip: ", tt_class._classname )
		self.tooltip_widgets[ tt_class ] = TheFrontEnd.fe_root:AddChild( tt_class():IgnoreInput( true ) )
	end
	local tooltip_widget = self.tooltip_widgets[ tt_class ]
	local want_hide = self.tooltip_widget ~= nil and (self.tooltip_widget ~= tooltip_widget or not tt)
	if want_hide then
		self.tooltip_delay = self.tooltip_delay - dt

		if self.tooltip_delay <= 0 or (self.tooltip_focus.removed or not self.tooltip_focus.shown) then
			self.tooltip_widget:Hide()
			self.tooltip_widget, self.tooltip_focus, self.tooltip_data = nil, nil, nil
			self.tooltip_delay = TTDELAY
		end
	end

	local want_show = tt and (focus ~= self.tooltip_focus or tt ~= self.tooltip_data or focus:GetToolTipDirty())
	if want_show then
		self.tooltip_delay = self.tooltip_delay - dt

		if self.tooltip_delay <= 0 or (self.tooltip_widget and self.tooltip_widget.shown) then
			local sm = TheFrontEnd:GetScreenMode()
			local layout_scale
			if tooltip_widget.LAYOUT_SCALE then
				layout_scale = tooltip_widget.LAYOUT_SCALE[ sm ] or LAYOUT_SCALE[ sm ]
			else
				layout_scale = LAYOUT_SCALE[ sm ]
			end

			tooltip_widget:SetOwningPlayer(nil) -- Shared tooltips have all content re-applied, so okay to clear.
			tooltip_widget:SetOwningPlayer(focus and focus:GetOwningPlayer())

			tooltip_widget:SetLayoutScale( layout_scale )
			if tooltip_widget:LayoutWithContent(tt) then
				self.tooltip_widget = tooltip_widget
				self.tooltip_widget.nodebug = true
				self.tooltip_widget:Show()
				self.tooltip_focus = focus
				self.tooltip_data = tt
				self.tooltip_delay = TTDELAY
				focus:SetToolTipDirty( nil )
			else
				tooltip_widget:Hide()
			end
		end
	end

	if self.tooltip_widget
		and self.tooltip_focus
		and self.tooltip_widget.shown
		and not self.tooltip_focus.removed
	then
		self:UpdateToolTipPos( self.tooltip_widget )
		-- if self.tooltip_focus.LayoutToolTip then
		--     self.tooltip_focus:LayoutToolTip( self.tooltip_widget )
		-- end
		local tooltiplayoutfn = self.tooltip_focus:GetToolTipLayoutFn()
		if tooltiplayoutfn then
			tooltiplayoutfn( self.tooltip_focus, self.tooltip_widget )
			self:ConstrainToolTipPos( tooltip_widget )
		end
	end
end

function ToolTipper:SetToolTipOverride( tooltip_focus )
	self.tooltip_focus_override = tooltip_focus
end

function ToolTipper:GetToolTipOverride()
	return self.tooltip_focus_override
end

function ToolTipper:UpdateToolTipPos( tooltip_widget )
	if tooltip_widget and tooltip_widget.shown then
		-- take the letterbox into account.
		-- If we don't letterbox we want to use the widget's worldboundingbox and the screenDims instead
		local screenw, screenh = RES_X, RES_Y
		--        local screenw, screenh = TheFrontEnd:GetScreenDims()
		local scrx_min, scrx_max = -screenw/2, screenw/2
		local scry_min, scry_max = -screenh/2, screenh/2

		local xmin, ymin, xmax, ymax = tooltip_widget:GetVirtualBoundingBox()
		--        xmin, ymin, xmax, ymax = tooltip_widget:GetWorldBoundingBox()
		local tw, th = xmax - xmin, ymax - ymin

		xmin, ymin, xmax, ymax = self.tooltip_focus:GetVirtualBoundingBox()
		--        xmin, ymin, xmax, ymax = self.tooltip_focus:GetWorldBoundingBox()

		local layout_x, layout_y = "after", "top"

		if (xmax  + tw)  <=  scrx_max and ymax <= scry_max then -- does it fit top right?
			layout_x, layout_y = "after", "top"
		elseif (xmin - tw) >= scrx_min and ymax <= scry_max then -- top left?
			layout_x, layout_y = "before", "top"
		elseif (xmax + tw) <= scrx_max and ymin >= scry_min then  -- bottom right?
			layout_x, layout_y = "after", "bottom"
		elseif (xmin - tw) >= scrx_min and ymin >= scry_min then -- bottom left?
			layout_x, layout_y = "before", "bottom"
		elseif (ymax + th) <= scry_max then -- center above
			layout_x, layout_y = "center", "above"
		else -- center below
			layout_x, layout_y = "center", "below"
		end

		tooltip_widget:LayoutBounds( layout_x, layout_y, self.tooltip_focus )

		if tooltip_widget.OnLayout then
			tooltip_widget:OnLayout(layout_x, layout_y)
		end

		self:ConstrainToolTipPos( tooltip_widget )
	end
end

function ToolTipper:ConstrainToolTipPos( tooltip_widget )
	UIHelpers.KeepOnScreen(tooltip_widget)
end


return ToolTipper
