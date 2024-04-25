require "class"


local Pool = Class(function(self, createfn, getfn, recyclefn)
	self.pool = {}
	self.createfn = createfn
	self.getfn = getfn
	self.recyclefn = recyclefn
end)

--------------------------------------------------------------------------

local _recycled_mt =
{
	__index = function(t, k) assert(false, "Reading from recycled object.") end,
	__newindex = function(t, k, v) assert(false, "Writing to recycled object.") end,
}

local function _make_invalid(self, obj)
	local mt = getmetatable(obj)
	if self._mt == nil then
		self._mt = mt
	elseif self._mt ~= mt then
		return false
	end
	setmetatable(obj, _recycled_mt)
	return true
end

local function _make_valid(self, obj)
	if getmetatable(obj) ~= _recycled_mt then
		return false
	end
	setmetatable(obj, self._mt)
	return true
end

local function _check_valid(self, obj)
	return getmetatable(obj) == self._mt
end

--------------------------------------------------------------------------

function Pool:Get()
	local n = #self.pool
	if n > 0 then
		local obj = self.pool[n]
		self.pool[n] = nil
		dbassert(_make_valid(self, obj))
		if self.getfn ~= nil then
			self.getfn(obj)
		end
		dbassert(_check_valid(self, obj))
		return obj
	end
	return self.createfn()
end

function Pool:Recycle(obj)
	self.pool[#self.pool + 1] = obj
	if self.recyclefn ~= nil then
		self.recyclefn(obj)
	end
	dbassert(_make_invalid(self, obj))
end

--------------------------------------------------------------------------

-- Simplify pooling several similar objects. You pass the Class (constructor
-- object) to Get and it will ensure you have a matching pool. Recycle will
-- return it to the correct pool.
--
-- Adds _pool_key to your instances.
Pool.MultiPool = Class(function(self, create_wrapper_fn)
	self.create_wrapper_fn = create_wrapper_fn or function(...) return ... end
	self.pools = {}
end)

function Pool.MultiPool:_GetPool(ctor)
	local pool = self.pools[ctor]
	if not pool then
		local fn = function(...)
			return self.create_wrapper_fn(ctor(...))
		end
		pool = Pool(fn)
	end
	self.pools[ctor] = pool
	return pool
end

function Pool.MultiPool:Get(ctor)
	local obj = self:_GetPool(ctor):Get()
	obj._pool_key = ctor
	return obj
end

function Pool.MultiPool:Recycle(obj)
	dbassert(obj._pool_key)
	return self:_GetPool(obj._pool_key):Recycle(obj)
end

local function test_MultiPool()
	local creates = 0
	local function Lower()
		return { name = "one" }
	end
	local function Upper()
		return { name = "ONE" }
	end
	local p = Pool.MultiPool(function(...)
		creates = creates + 1
		return ...
	end)
	local g = p:Get(Lower)
	local f = p:Get(Lower)
	assert(creates == 2)
	assert(g)
	assert(g ~= f)
	assert(g.name == f.name)
	p:Recycle(f)
	local f2 = p:Get(Lower)
	assert(f == f2)
	local G = p:Get(Upper)
	local F = p:Get(Upper)
	assert(G)
	assert(G ~= F)
	assert(G ~= g)
	assert(G.name ~= g.name)
	assert(g.name == f.name)
	assert(creates == 4)
end


--------------------------------------------------------------------------

local function CreateTable()
	return {}
end

local ValidateEmptyTable
if DEV_MODE then
	ValidateEmptyTable = function(tbl)
		assert(next(tbl) == nil, "Recycled table is not empty.")
	end
end

Pool.SimpleTablePool = Class(Pool, function(self)
	Pool._ctor(self, CreateTable, ValidateEmptyTable, ValidateEmptyTable)
end)

return Pool
