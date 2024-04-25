--------------------------------------------------------------------------
--This prefab file is for loading autogenerated Cine prefabs
--------------------------------------------------------------------------

local cineutil = require "prefabs.cineutil"
local cine_autogen_data = require "prefabs.cine_autogen_data"


local ret = {}

for name, params in pairs(cine_autogen_data) do
	ret[#ret + 1] = cineutil.MakeAutogenCine(name, params)
end

--Don't need group prefabs for cines
-- prefabutil.CreateGroupPrefabs(cine_autogen_data, ret)

return table.unpack(ret)
