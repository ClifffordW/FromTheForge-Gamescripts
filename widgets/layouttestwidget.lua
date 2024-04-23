-- A debug widget used for determining UI widget placement
local ImageButton = require("widgets/imagebutton") -- For now use an imagebutton for ease of selection via mouse and Get/Size functions

local layoutBoundsH =
{
	"before",
	"left",
	"left_center",
	"center_left",
	"center",
	"center_right",
	"right_center",
	"right",
	"after",
}

local layoutBoundsV =
{
	"below",
	"bottom",
	"bottom_center",
	"center_bottom",
	"center",
	"center_top",
	"top_center",
	"top",
	"above",
}

local defaultWidth = 1
local defaultHeight = 1

local LayoutTestWidget = Class(ImageButton, function(self, debugWidgetNode)
    ImageButton._ctor(self, "images/global/square.tex")

	self.layoutTestWidget = true
	self:SetName("Layout Test Widget")
	self:SetScaleOnFocus(false)
	self.move_on_click = false
	self:SetMultColor(1, 1, 0, 0.5)

	defaultWidth, defaultHeight = self:GetSize()
	self:InitializeProperties()

	-- For copying selected widget properties
	self.debugWidgetNode = debugWidgetNode

	self.keepPositionOnReparent = false
end)

function LayoutTestWidget:InitializeProperties()

	self:SetSize(defaultWidth, defaultHeight)
	self.offsetX = 0
	self.offsetY = 0

	self.boundingBoxOffsetX = 0
	self.boundingBoxOffsetY = 0

	self.selectedLayoutBoundsIndexH = 5 -- center
	self.selectedLayoutBoundsIndexV = 5 -- center

	-- Offset values generated by Widget:CalcLayoutBoundsOffset()
	self.layoutBoundsOffsetX = 0
	self.layoutBoundsOffsetY = 0
end

function LayoutTestWidget:ApplyOffsetToChildren(offsetX, offsetY)
	-- Set the position of child widgets to position + layout bounds offset
	for _, childWidget in pairs(self.children) do
		childWidget:Offset(offsetX, offsetY)
	end
end

function LayoutTestWidget:ApplyLayoutBounds()
	-- Need to temporarily revert offset values before calculating layout bounds, since it impacts the layout bound calculation
	-- We want to apply both horizontal and vertial layout bounds at the same time, since in a real use-case, we apply LayoutBounds positioning to a widget only once.
	self:Offset(-self.offsetX, -self.offsetY)

	-- Also need to revert layout bounds offset values before calculating the new offset bounds and offsetting
	local h = layoutBoundsH[self.selectedLayoutBoundsIndexH]
	local v = layoutBoundsV[self.selectedLayoutBoundsIndexV]

	self:Offset(-self.layoutBoundsOffsetX, -self.layoutBoundsOffsetY)
	self.layoutBoundsOffsetX, self.layoutBoundsOffsetY = self:CalcLayoutBoundsOffset( h, v, self.parent )
	self:Offset(self.layoutBoundsOffsetX, self.layoutBoundsOffsetY)

	self:Offset(self.offsetX, self.offsetY)
end

function LayoutTestWidget:ResetSize()
	self:SetSize(defaultWidth, defaultHeight)
end

function LayoutTestWidget:ResetOffset()
	self.offsetX = 0
	self.offsetY = 0

	self:SetPosition(0,0)
end

function LayoutTestWidget:ResetBoundingBoxOffset()
	self:ApplyOffsetToChildren(-self.boundingBoxOffsetX, -self.boundingBoxOffsetY)
	self.boundingBoxOffsetX = 0
	self.boundingBoxOffsetY = 0
end

function LayoutTestWidget:RevertLayoutBounds()
	self.selectedLayoutBoundsIndexH = 5
	self.selectedLayoutBoundsIndexV = 5
	self.layoutBoundsOffsetX = 0
	self.layoutBoundsOffsetY = 0

	self:SetPosition(0,0)
end

function LayoutTestWidget:DebugDraw_AddSection(ui, panel)

	local selectedWidget = self.debugWidgetNode.focus_widget

	if ui:Button("Re-Parent to Selected Widget", nil, nil, selectedWidget) then
		if self.keepPositionOnReparent then
			self:Reparent(selectedWidget)
		else
			local delta = self:GetWorldPosition() - self.parent:GetWorldPosition()
			-- Reparent preserves position, so re-apply our relative offsets.
			self:Reparent(selectedWidget)
			local scale = self:GetResolvedScale()
			self.offsetX = self.offsetX + delta.x / scale
			self.offsetY = self.offsetY + delta.y / scale
			self:SetPosition(self.offsetX, self.offsetY)
		end
	end

	ui:SameLineWithSpace()

	local keepPositionChecked, keepPosition = ui:Checkbox("Keep Position", self.keepPositionOnReparent)
	if keepPositionChecked then
		self.keepPositionOnReparent = keepPosition
	end

	if ui:Button("Copy Selected Widget Properties", nil, nil, selectedWidget) then
		-- Calculate parent bounding box center point to determine the bounding box offsets and how much to offset children
		local widgetCenterX, widgetCenterY = selectedWidget:GetCentroid()
		local dx = widgetCenterX - self.boundingBoxOffsetX
		local dy = widgetCenterY - self.boundingBoxOffsetY
		self:ApplyOffsetToChildren(dx, dy)

		self.boundingBoxOffsetX = widgetCenterX
		self.boundingBoxOffsetY = widgetCenterY

		-- Calculate sized based on the parent's bounding box
		local x1, y1, x2, y2 = selectedWidget:GetBoundingBox()
		local width = math.abs(x2 - x1)
		local height = math.abs(y2 - y1)

		self:SetSize(width, height)
	end

	if ui:Button("Reset All") then
		self:ResetBoundingBoxOffset()
		self:RevertLayoutBounds()
		self:ResetOffset()
		self:ResetSize()
	end

	ui:SameLineWithSpace()

	ui:PushStyleColor(ui.Col.Button, { .75, 0, 0, 1 })
	ui:PushStyleColor(ui.Col.ButtonHovered, { 1, .2, .2, 1 })
	ui:PushStyleColor(ui.Col.ButtonActive, { .95, 0, 0, 1 })

	if ui:Button("Remove") then
		self:Remove()
		self.debugWidgetNode.selectedLayoutTestWidget = nil
	end

	ui:PopStyleColor(3)

	ui:Separator()

	ui:PushItemWidth(100)

	-- Size
	if ui:Button("Reset##Size") then
		self:ResetSize()
	end

	ui:SameLineWithSpace()

	local width, height = self:GetSize()
	local changedW, newWidth = ui:DragInt("Width", width, 1, 0, 10000)
	if changedW then
		self:SetSize(newWidth, height)
	end

	ui:SameLineWithSpace(23)

	local changedH, newHeight = ui:DragInt("Height", height, 1, 0, 10000)
	if changedH then
		self:SetSize(width, newHeight)
	end

	ui:SameLineWithSpace(50)

	if ui:Button("Copy to Clipboard##Size") then
		ui:SetClipboardText(string.format(":SetSize(%i, %i)", width, height))
	end

	-- Offset
	if ui:Button("Reset##Offset") then
		self:ResetOffset()
	end

	ui:SameLineWithSpace()

	local changedOffsetX, offsetX = ui:DragInt("Offset x", self.offsetX)

	ui:SameLineWithSpace()

	local changedOffsetY, offsetY = ui:DragInt("Offset y", self.offsetY)

	if changedOffsetX or changedOffsetY then
		self.offsetX = offsetX or self.offsetX
		self.offsetY = offsetY or self.offsetY
		self:SetPosition(self.offsetX + self.layoutBoundsOffsetX, self.offsetY + self.layoutBoundsOffsetY)
	end

	ui:SameLineWithSpace(42)

	if ui:Button("Copy to Clipboard##Offset") then
		ui:SetClipboardText(string.format(":Offset(%i, %i)", offsetX, offsetY))
	end

	-- Bounding Box Offset
	-- When a widget has offset children, the widget's bounding box sometimes doesn't match up with its position.
	-- This offset shows the difference between the bounding box center point and the widget's position.
	if ui:TreeNode("Other...") then

		ui:Text("Bounding Box Offset")

		if ui:IsItemHovered() then
            ui:SetTooltip( "This offset shows the difference between the bounding box center point and the widget's position.\nIn cases where the widget has offset children, its position may not line up with the bounding box center point." )
        end

		if ui:Button("Reset##BoundingBoxOffset") then
			self:ResetBoundingBoxOffset()
		end

		ui:SameLineWithSpace()

		local changedBboxOffsetX, bboxOffsetX = ui:DragInt("x", self.boundingBoxOffsetX)
		if changedBboxOffsetX then
			local dx = bboxOffsetX - self.boundingBoxOffsetX
			self:ApplyOffsetToChildren(dx, 0)
			self.boundingBoxOffsetX = bboxOffsetX
		end

		ui:SameLineWithSpace()

		local changedBboxOffsetY, bboxOffsetY = ui:DragInt("y", self.boundingBoxOffsetY)
		if changedBboxOffsetY then
			local dy = bboxOffsetY - self.boundingBoxOffsetY
			self:ApplyOffsetToChildren(0, dy)
			self.boundingBoxOffsetY = bboxOffsetY
		end

		ui:TreePop()
	end

	ui:PopItemWidth()

	ui:Separator()

	-- LayoutBounds
	ui:Text("Layout Bounds")

	if ui:IsItemHovered() then
		ui:SetTooltip( "When using this to test positioning, keep in mind the order if you've edited width, height, and offset values beforehand or after, since it affects the final visualization." )
	end

	ui:PushItemWidth(150)

	if ui:Button("Reset##LayoutBounds") then
		self:RevertLayoutBounds()
	end

	ui:SameLineWithSpace()

	local changedLayoutBoundsH, indexH = ui:Combo("Horizontal", self.selectedLayoutBoundsIndexH, layoutBoundsH)

	ui:SameLineWithSpace(20)

	local changedLayoutBoundsV, indexV = ui:Combo("Vertical", self.selectedLayoutBoundsIndexV, layoutBoundsV)

	if changedLayoutBoundsH or changedLayoutBoundsV then
		self.selectedLayoutBoundsIndexH = indexH or self.selectedLayoutBoundsIndexH
		self.selectedLayoutBoundsIndexV = indexV or self.selectedLayoutBoundsIndexV
		self:ApplyLayoutBounds()
	end

	ui:SameLineWithSpace(20)

	if ui:Button("Copy to Clipboard##Layout Bounds") then
		ui:SetClipboardText(string.format(":LayoutBounds(\"%s\", \"%s\", %s)",
												layoutBoundsH[self.selectedLayoutBoundsIndexH],
												layoutBoundsV[self.selectedLayoutBoundsIndexV],
												"REPLACE_ME"))
	end

	ui:PopItemWidth()

	-- Draw bounding box
	local color = RGB(255, 0, 255)
	DebugWidgetBoundingBox:DrawDebugBoundingBox(ui, self, color)
	DebugWidgetBoundingBox:DrawDebugOriginPoint(ui, self, color)

end

return LayoutTestWidget
