-- Base class for elements placed in a scene by a SceneGen.
-- TODO @chrisp #scenegen - rename to DecorElement...and subclasses too!

local DungeonProgress = require "proc_gen.dungeon_progress"
local Enum = require "util.enum"
local PropProcGen = require "proc_gen.prop_proc_gen"
local Lume = require "util.lume"

local TILE_TYPES = PropProcGen.Tile:AlphaSorted()
setmetatable(TILE_TYPES, nil)

local RADIUS_MAXIMUM = 5
local COUNT_MAXIMUM = 10
local HEIGHT_MAXIMUM = 10.0

DecorType = Enum {
	"Unknown",
	"Prop",
	"Spacer",
	"ParticleSystem",
	"Fx"
}

TileTypeFilterShape = Enum {
	"Point",
	"Circle"
}

local SceneElement = Class(function(self)
	self.dungeon_progress_constraints = DungeonProgress.DefaultConstraints()
	self.enabled = true
	self.name = nil
	self.filter_by_tile_type = false
	self.tile_types = nil
	self.tile_type_filter_shape = TileTypeFilterShape.s.Point
end)

SceneElement.PLACEMENT_CONTEXT = "++PLACEMENT_CONTEXT"

function SceneElement:GetDecorType()
	return DecorType.s.Unknown
end

-- TODO @chrisp #scenegen - hard-coded tile types
local tile_types = {
	DIRT = PropProcGen.Tile.s.path,
	MOLD = PropProcGen.Tile.s.path,
	MOLDDIRT = PropProcGen.Tile.s.path,
	GRASS = PropProcGen.Tile.s.rough,
	FUZZ = PropProcGen.Tile.s.rough,
	FUZZGRASS = PropProcGen.Tile.s.rough,
	ACIDPOOL = PropProcGen.Tile.s.pool,
}

function SceneElement.TileNameToType(name)
	return tile_types[name]
end

-- Return true if the specified tile_name maps to an accepted tile_type, or if the tile_name is unknown.
-- Return false if the specified tile_name is known but not in the whitelist of accepted tile types.
function SceneElement:CanPlaceOnTile(tile_name)
	return not self.filter_by_tile_type 
		or Lume(self.tile_types):find(tile_types[tile_name]):result()
end

-- Placement radius is the effective size of the prop when it is being placed. By setting the buffer to be
-- larger than zero, you can prevent other props from being placed too close to this prop in THIS
-- ZoneGen pass. In subsequent passes, the prop will be represented using only its un-buffered radius.

function SceneElement:GetCount()
	return (self.placement and self.placement.count or self.count) or 1
end

function SceneElement:GetHeight()
	return (self.placement and self.placement.height or self.height) or 0
end

function SceneElement:GetPersistentRadius()
	return (self.placement and self.placement.radius or self.radius) or 1
end

function SceneElement:GetBufferRadius()
	return (self.placement and self.placement.buffer or self.buffer) or 0
end

function SceneElement:GetPlacementRadius()
	return self:GetPersistentRadius() + self:GetBufferRadius()
end

function SceneElement:GetLabel()
	return self.name
end

function SceneElement:GetDungeonProgressConstraints()
	return self.dungeon_progress_constraints
end

function SceneElement:Ui(ui, id)
	self.name = ui:_InputTextWithHint("Name"..id, self:GetLabel(), self.name)
	ui:SetTooltipIfHovered("Override the generated label for this element")
	if self.name == "" then
		self.name = nil
	end

	-- Move data into 'placement' table so we can copy/paste.
	if not self.placement then
		self.placement = {
			count = self.count or 1,
			radius = self.radius or 1,
			buffer = self.buffer or 0,
			height = self.height or 0
		}
		self.count = nil
		self.radius = nil
		self.buffer = nil
		self.height = nil
	end

	if ui:CollapsingHeader("Placement"..id) then
		local id = id .. "Placement"

		local new_placement = ui:CopyPasteButtons(SceneElement.PLACEMENT_CONTEXT, id, self.placement)
		if new_placement then
			self.placement = new_placement
		end

		local changed, count = ui:DragInt("Count"..id, self.placement.count or 1, 1, 1, COUNT_MAXIMUM)
		ui:SetTooltipIfHovered("Number of elements in this ZoneGen, relative to other element Counts")
		if changed then
			self.placement.count = count
		end

		self.placement.radius = ui:_DragFloat("Radius"..id, self.placement.radius or 1, 0.1, 0, RADIUS_MAXIMUM)
		ui:SetTooltipIfHovered("Effective placement size")

		self.placement.buffer = ui:_DragFloat("Buffer Radius"..id, self.placement.buffer or 0, 0.1, 0, RADIUS_MAXIMUM)
		ui:SetTooltipIfHovered("Additional space occupied for this generation phase only")

		self.placement.height = ui:_DragFloat("Height"..id, self.placement.height or 0, 0.1, -HEIGHT_MAXIMUM, HEIGHT_MAXIMUM)
		ui:SetTooltipIfHovered("Offset in y")
	end

	DungeonProgress.Ui(ui, id.."DungeonProgressConstraintsUi", self)
	
	self.filter_by_tile_type = ui:_Checkbox(id.."FilterByTileType", self.filter_by_tile_type)
	ui:SameLineWithSpace()
	if not self.filter_by_tile_type then
		ui:PushDisabledStyle()
		ui:CollapsingHeader("Tile Types")
		ui:PopDisabledStyle()
	else
		if not self.tile_types then
			self.tile_types = {}
		end
		ui:FlagRadioButtons("Tile Types" .. id, TILE_TYPES, self.tile_types)
		ui:Indent()
		self.tile_type_filter_shape = ui:_ComboAsString("Shape"..id, self.tile_type_filter_shape, TileTypeFilterShape:Ordered())
		ui:Unindent()
	end
end

return SceneElement
