local DebugDraw = require "util.debugdraw"
local Vector3 = require "math.modules.vec3"

local SnapGrid = Class(function(self, inst)
	self.inst = inst
	self.cellsize = 1
	self.grid = {}

	self._onstartplacing = function()
		--self:SetDrawGridEnabled(true)
	end

	self._onstopplacing = function()
		--self:SetDrawGridEnabled(false)
	end

	self.inst:ListenForEvent("startplacing", self._onstartplacing, TheWorld)
	self.inst:ListenForEvent("stopplacing", self._onstopplacing, TheWorld)

end)

function SnapGrid:GetCellSize()
	return self.cellsize
end

function SnapGrid:GetCellId(row, col, level)
	dbassert(row >= -256 and row < 256)
	dbassert(col >= -256 and col < 256)
	dbassert(level >= -256 and level < 256)
	return ((level + 256) << 18) | ((row + 256) << 9) | (col + 256)
end

function SnapGrid:GetRowColFromCellId(cellid)
	return ((cellid >> 9) & 511) - 256, (cellid & 511) - 256, (cellid >> 18) - 256
end

-- Return world_coordinates, grid_coordinates that result from 'snapping' a box centered at the (x,z) world coordinates.
-- odd_width and odd_height describe qualities of the box.
-- For an even box dimension, it will snap to a grid line; for an odd box dimension, it will snap to a cell center.
-- Pass nil for dimensional oddness to imply a single-cell context.
-- Q: How EXACTLY do world coordinates map to grid coordinates?
-- A: The grid coordinate is essentially the floor of the world value. For example with the (simplifying) cell size of 1,
-- world values in [0.0, 1.0) map to a grid value of 0; [-1.0, 0.0) map to -1.
function SnapGrid:SnapToGrid(x, z, odd_width, odd_height)
	-- Dimensional nil-ness implies a single cell context.
	local odd_cell_size = (self.cellsize % 2) ~= 0
	if not odd_width then
		odd_width = odd_cell_size
	end
	if not odd_height then
		odd_height = odd_cell_size
	end

	-- Dimensional oddness is often stored as a number (0 or 1). Add some safety netting...
	local function ManifestBool(var)
		if type(var) == "number" then
			return var ~= 0
		else
			return var
		end
	end
	odd_width = ManifestBool(odd_width)
	odd_height = ManifestBool(odd_height)

	local function SnapCoordinate(world_coord, odd)
		local grid_coord, new_world_coord
		if odd then
			grid_coord = math.floor(world_coord / self.cellsize)
			new_world_coord = (grid_coord + 0.5) * self.cellsize
		else
			grid_coord = math.round(world_coord / self.cellsize)
			new_world_coord = grid_coord * self.cellsize
		end

		return grid_coord, new_world_coord
	end
	local col, snapped_x = SnapCoordinate(x, odd_width)
	local row, snapped_z = SnapCoordinate(z, odd_height)
	return snapped_x, snapped_z, row, col
end

-- Given the origin cell of (col, row), return row_span, col_span for the specified width, height.
-- For even dimensions, the larger number of cells will be on the negative side of the origin.
function SnapGrid:GetRowColSpan(row, col, width, height)
	return row - math.floor(height / 2) -- from_row
		, col - math.floor(width / 2)   -- from_col
		, row + math.floor((height - 1) / 2) -- to_row
		, col + math.floor((width - 1) / 2) -- to_col
end

function SnapGrid:Set(cellid, ent)
	local cell = self.grid[cellid]
	if cell == nil then
		self.grid[cellid] = { [ent] = true }
	else
		cell[ent] = true
	end
end

function SnapGrid:Clear(cellid, ent)
	local cell = self.grid[cellid]
	if cell ~= nil then
		cell[ent] = nil
		if next(cell) == nil then
			self.grid[cellid] = nil
		end
	end
end

--TODO: move this logic to the placer
function SnapGrid:IsClear(cellid, ent)
	local cell = self.grid[cellid]
	if cell ~= nil then
		for k in pairs(cell) do
			if k ~= ent then
				if k.prefab == "plot" or (k.entity and (k:HasTag("placer") or k:HasTag("ignore_placer"))) then
					return true
				end
				return false
			end
		end
	end
	return true
end

function SnapGrid:GetEntitiesInCell(cellid)
	local ents = {}
	local cell = self.grid[cellid]
	
	if cell ~= nil then
		for k in pairs(cell) do
			table.insert(ents, k)
		end
	end

	return ents
end

function SnapGrid:GetEntityInCell(cellid)
	local ents = self:GetEntitiesInCell(cellid)
	return ents[1]
end

function SnapGrid:SetDebugDrawEnabled(enable)
	if enable then
		if not self.drawgrid and not self.debugdraw then
			self.inst:StartWallUpdatingComponent(self)
		end
		self.debugdraw = true
	else
		self.debugdraw = false
		if not self.drawgrid and not self.debugdraw then
			self.inst:StopWallUpdatingComponent(self)
		end
	end
end

function SnapGrid:SetDrawGridEnabled(enable)
	if enable then
		if not self.drawgrid and not self.debugdraw then
			self.inst:StartWallUpdatingComponent(self)
		end
		self.drawgrid = true
	else
		self.drawgrid = false
		if not self.drawgrid and not self.debugdraw then
			self.inst:StopWallUpdatingComponent(self)
		end
	end
end

function SnapGrid:_DrawWorldGridAt(world_x, world_z, width, height)
	dbassert((width % 2) ~= 0, "Make world grid odd width so the origin snaps to grid lines")
	dbassert((height % 2) ~= 0, "Make world grid odd height so the origin snaps to grid lines")
	local x_origin, z_origin = self:SnapToGrid(world_x, world_z, true, true)

	local cell_size = self:GetCellSize()
	local half_world_width = width * cell_size / 2
	local half_world_height = height * cell_size / 2
	local x_start = x_origin - half_world_width
	local x_end = x_origin + half_world_width
	local z_start = z_origin - half_world_height
	local z_end = z_origin + half_world_height

	local color = shallowcopy(WEBCOLORS.LAVENDER)
	color[4] = 0.2

	-- Draw horizontal lines.
	for i = 1, height + 1 do
		local z = z_start + (i - 1) * cell_size
		DebugDraw.GroundLine_Vec(Vector3(x_start, 0, z), Vector3(x_end, 0, z), color)
	end

	-- Draw vertical lines.
	for i = 1, width + 1 do
		local x = x_start + (i - 1) * cell_size
		DebugDraw.GroundLine_Vec(Vector3(x, 0, z_start), Vector3(x, 0, z_end), color)
	end
end

-- Draw a grid in the 15x15 cell area around the debug entity.
function SnapGrid:_DrawWorldGridForDebugEntity()
	local ent = GetDebugEntity()
	local snaptarget = ent and ent.components.snaptogrid
	if not snaptarget then
		self:SetDebugDrawEnabled(false)
		return
	end
	
	local SIZE <const> = 15
	local world_x, _, world_z = ent.Transform:GetWorldPosition()
	self:_DrawWorldGridAt(world_x, world_z, SIZE, SIZE)
end

-- Draw a 101x61 cell grid centered at world-XZ origin. The origin will lie on a cell nexus, not in a cell.
function SnapGrid:_DrawWorldGrid()
	self:_DrawWorldGridAt(0, 0, 101, 61)
end

function SnapGrid:OnWallUpdate()
	if self.debugdraw then
		self:_DrawWorldGridForDebugEntity()
	end

	if self.drawgrid then
		self:_DrawWorldGrid()
	end
end

return SnapGrid
