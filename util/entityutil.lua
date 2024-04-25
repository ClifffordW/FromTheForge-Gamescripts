local entityutil = {}

------------------------------

-- Local Functions & Variables

------------------------------

-- entityutil Functions

function entityutil.TryGetEntity(entity_id)
	local guid = TheNet:FindGUIDForEntityID(entity_id)
	if guid and guid ~= 0 and Ents[guid] and Ents[guid]:IsValid() then
		return Ents[guid]
	end
	return nil
end



return entityutil
