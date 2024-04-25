--component for UI to see if you've made an item before, and mark it as such
local HasMade = Class(function(self, inst)
	self.inst = inst
	self:Init()
end)

function HasMade:Init()
	self.has_made = 
	{
		decor = {},
	}
end

function HasMade:OnSave()
	local data = {}
	data.has_made = deepcopy(self.has_made)
	return data
end

function HasMade:OnLoad(data)
	if data then
		if data.has_made then
			self.has_made.decor = deepcopy(data.has_made.decor) or {}
		end
	end
end

function HasMade:HasMadeDecor(decor_name)
	return table.find(self.has_made.decor, decor_name) ~= nil
end

function HasMade:MarkDecorAsMade(decor_name)
	table.insert(self.has_made.decor, decor_name)
end

function HasMade:DebugDrawEntity(ui, panel, colors)
	if ui:Button("Reset") then
		self:Init()
	end

	panel:AppendTableInline(ui, self.has_made)
end

return HasMade