local DebugDraw = require "util.debugdraw"
local DebugNodes = require "dbui.debug_nodes"
local iterator = require "util.iterator"
local csvutil = require "util.csvutil"

local DebugLister = Class(DebugNodes.DebugNode, function(self, name)
	DebugNodes.DebugNode._ctor(self, name)
	
	self.cols = {}
	self.values = {}
	self.source = {}

	self.filter = nil
end)

function DebugLister:SetColumns(cols)
	self.cols = cols
end

function DebugLister:GetColumns()
	return self.cols
end

function DebugLister:AddValue(val)
	table.insert(self.values, val)
end

function DebugLister:ResetValues()
	self.values = {}
end

function DebugLister:SetSource(source)
	self.source = source
end

DebugLister.PANEL_WIDTH = 800
DebugLister.PANEL_HEIGHT = 1000

function DebugLister:RenderPanel( ui, panel )
	if ui:Button("Copy CSV to Clipboard") then
		ui:SetClipboardText(csvutil.MakeCSV(self.cols, self.values))
	end

	self.filter = ui:_FilterBar(self.filter, nil, "Filter...")

	ui:Columns(#self.cols + 1)

	for _, v in ipairs(self.cols) do
		ui:Text(v.name)
		ui:NextColumn()
	end

	ui:Text("Data")
	ui:NextColumn()

	ui:Separator()

	for i, item in ipairs(self.values) do
		local should_display = false

		--if any of the columns fit the filter, then display the whole row
		for _, v in ipairs(self.cols) do
			if self.filter == nil or (type(item[v.key]) == "string" and item[v.key]:find(self.filter)) then
				should_display = true
			end
		end

		if should_display then
			for _, v in ipairs(self.cols) do
				if type(item[v.key]) == "function" then
					item[v.key](ui, panel)
				else
					ui:Text(item[v.key])
					if ui:IsItemHovered() then
						ui:SetTooltip(item[v.key])
					end
				end
				ui:NextColumn()
			end

			if item["data"] ~= nil then
				if ui:Button("Source Data##"..tostring(i)) then
					panel:PushNode( panel:CreateDebugNode( item["data"] ))
				end
			end
			ui:NextColumn()
		end

	end

	ui:Columns()

	self:AddFilteredAll(ui, panel, self.source)
end

return DebugLister
