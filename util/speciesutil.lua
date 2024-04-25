require "class"
local Enum = require "util.enum"

local speciesutil = {}

speciesutil.Species = Enum{
	"canine",
	"mer",
	"ogre",
}

function speciesutil.GetSpeciesPrettyName(species)
	if species then
		local species_id = "species_" .. species
		return STRINGS.NAMES[species_id]
	end
end

return speciesutil
