local DebugDraw = require "util.debugdraw"
local DebugSettings = require "debug.inspectors.debugsettings"
local DebugNodes = require "dbui.debug_nodes"
local Enum = require "util.enum"
local lume = require "util.lume"


local TransformType = Enum{
	"All",
	"UI",
	"World",
}

local DebugEntityExplorer = Class(DebugNodes.DebugNode, function(self)
	DebugNodes.DebugNode._ctor(self, "Debug Entity Explorer")

	self.options = DebugSettings("EntityExplorer.options")
		:Option("filter_component", "")
		:Option("filter_name", "")
		:Option("filter_prefabname", "")
		:Option("filter_onscreen", false)
		:Option("only_prefabs", false)
		:Option("only_props", false)
		:Option("transform_type", TransformType.s.All)

	self.selection = {}
	self.move_delta = Vector3.zero:clone()
end)

DebugEntityExplorer.PANEL_WIDTH = 700
DebugEntityExplorer.PANEL_HEIGHT = 1200

function DebugEntityExplorer:RenderPanel( ui, panel )
	self.options:Enum(ui, "Transform Type", "transform_type", TransformType:Ordered())
	self.options:Toggle(ui, "Only on screen", "filter_onscreen")
	self.options:Toggle(ui, "Only props", "only_props")
	self.options:Toggle(ui, "Only prefab instances", "only_prefabs")
	self.options:SaveIfChanged("filter_prefabname", ui:FilterBar(self.options.filter_prefabname, "Filter prefab", "Prefab name pattern..."))
	self.options:SaveIfChanged("filter_name", ui:FilterBar(self.options.filter_name, "Filter entity name", "Name pattern..."))
	self.options:SaveIfChanged("filter_component", ui:FilterBar(self.options.filter_component, "Filter component", "Lua component name pattern..."))

	-- not persistent, not saved
	self.net_id = ui:_FilterBar(self.net_id, "Filter network id", "id...") or ""
	ui:SameLineWithSpace()
	if ui:Button(ui.icon.list, ui.icon.width) then
		DebugNodes.DebugNetwork:FindOrCreateEditor()
	end

	local select_all_matches = ui:Button("Select Matching")
	ui:SetTooltipIfHovered("Adds all entities that match the above filters to the selection.")
	ui:SameLineWithSpace()
	local deselect_all_matches = ui:Button("Deselect Matching")
	ui:SetTooltipIfHovered("Removes all entities that match the above filters from the selection.")
	ui:SameLineWithSpace()
	if ui:Button("Clear Selection") then
		self.selection = {}
	end
	ui:SameLineWithSpace()
	ui:Text(string.format("%i selected", table.numkeys(self.selection)))


	local modify_lines = 3  -- number of widgets in "Modify Selection" section
	modify_lines = next(self.selection) and modify_lines or 0
	local avail = Vector2(ui:GetContentRegionAvail())
	avail.y = avail.y - modify_lines * ui:GetFrameHeightWithSpacing()
	ui:BeginChild("DebugEntityExplorer", avail:unpack())
	if ui:BeginTable("world-ents", 3) then
		ui:TableSetupColumn("selected", ui.TableColumnFlags.WidthFixed)
		local pick_with_debug_ent = self.last_debug_ent ~= GetDebugEntity()
		self.last_debug_ent = GetDebugEntity()
		for guid,ent in pairs(Ents) do
			local tt = self.options.transform_type
			local ok_transform = tt == TransformType.s.All
				or (tt == TransformType.s.UI	and ent.UITransform)
				or (tt == TransformType.s.World and ent.Transform)
			local ok_prop = not self.options.only_props or ent:HasTag("prop")
			local ok_prefab = ent.prefab or not self.options.only_prefabs
			local ok_component = not self.options.filter_component
				or self.options.filter_component:len() == 0
				or lume(ent.components)
					:keys()
					:match(function(v)
						return ui:MatchesFilterBar(self.options.filter_component, v)
					end)
					:result()
			local ok_name       = ui:MatchesFilterBar(self.options.filter_name, (ent.name or ""))
			local ok_prefabname = ui:MatchesFilterBar(self.options.filter_prefabname, (ent.prefab or ""))
			local ok_net_id     = ui:MatchesFilterBar(self.net_id, tostring(ent.Network and ent.Network:GetEntityID() or ""))
			local ok_onscreen   = not self.options.filter_onscreen or ent.entity:FrustumCheck()

			if ok_transform
				and ok_prop
				and ok_prefab
				and ok_component
				and ok_name
				and ok_prefabname
				and ok_net_id
				and ok_onscreen
			then
				local is_debug_entity = ent == GetDebugEntity()
				ui:TableNextColumn()
				if ui:Checkbox("##selected_".. guid, self.selection[guid]) then
					self.selection[guid] = not self.selection[guid] or nil
				end
				local is_hovered = ui:IsItemHovered()
				if select_all_matches
					or (pick_with_debug_ent and is_debug_entity)
				then
					self.selection[guid] = true
				elseif deselect_all_matches then
					self.selection[guid] = nil
				end

				ui:TableNextColumn()
				panel:AppendTable(ui, ent)
				is_hovered = is_hovered or ui:IsItemHovered()

				if is_debug_entity then
					ui:SameLineWithSpace()
					if ui:Button(ui.icon.location) then
						d_viewinpanel(ent)
					end
					ui:SetTooltipIfHovered("This is the current Debug Entity.")
				end

				ui:TableNextColumn()
				local id = tostring(ent)
				if ent:HasTag("widget") then
					if ui:Button("Debug Widget##"..id) then
						d_viewinpanel(ent.widget)
					end
				elseif ent.Transform then
					if ui:Button("Teleport to##"..id) then
						c_goto(ent)
					end
					ui:SetTooltipIfHovered({
						"Teleport player here.",
						"Pos: ".. tostring(ent:GetPosition()),
						string.format("Rotation: %0.3f", ent.Transform:GetRotation()),
					})
					is_hovered = is_hovered or ui:IsItemHovered()
				end

				if ent.Transform and is_hovered then
					DebugDraw.GroundHex(ent:GetPosition(), nil, 1, WEBCOLORS.YELLOW)
				end
			end
		end
		ui:EndTable()
	end
	ui:EndChild()


	if next(self.selection) then
		ui:Separator()

		ui:TextColored(self.colorscheme.header, "Modify Selection")

		ui:DragVec3f("Offset Position", self.move_delta, 0.1, -30, 30)
		ui:SameLineWithSpace()
		local apply_dir = ui:Button("Apply") and 1
		ui:SameLineWithSpace()
		if ui:Button("Reverse") then
			apply_dir = -1
		end
		if apply_dir then
			for guid in pairs(self.selection) do
				local ent = Ents[guid]
				if ent and ent:IsValid() then
					local pos = ent:GetPosition() + self.move_delta * apply_dir
					ent.Transform:SetWorldPosition(pos:unpack())
				end
			end
		end

		if ui:Button(ui.icon.remove .." Delete") then
			for guid in pairs(self.selection) do
				local ent = Ents[guid]
				if ent and ent:IsValid() then
					ent:Remove()
				end
			end
			self.selection = {}
		end
		ui:SameLineWithSpace()
		if ui:Button("Flip") then
			for guid in pairs(self.selection) do
				local ent = Ents[guid]
				if ent and ent:IsValid() and ent.components.prop then
					ent.components.prop:FlipProp()
				end
			end
		end
	end
end

DebugNodes.DebugEntityExplorer = DebugEntityExplorer

return DebugEntityExplorer
