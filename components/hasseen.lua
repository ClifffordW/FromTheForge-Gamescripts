local Equipment = require("defs.equipment")
local Power = require "defs.powers"

--component for UI to see if you've seen an item before, and mark it as new
local HasSeen = Class(function(self, inst)
	self.inst = inst
	self:Init()
end)

function HasSeen:Init()
	self.has_seen = 
	{
		decor = {},
		mastery = {},
		quips = {},
		quip_lines = {},
	}
end

function HasSeen:OnSave()
	return deepcopy(self.has_seen)
end

function HasSeen:OnLoad(data)
	self.has_seen.decor = deepcopy(data.decor) or {}
	self.has_seen.mastery = deepcopy(data.mastery) or {}
	self.has_seen.quips = deepcopy(data.quips) or {}
	self.has_seen.quip_lines = deepcopy(data.quip_lines) or {}
end

function HasSeen:HasSeenDecor(decor_name)
	return table.find(self.has_seen.decor, decor_name) ~= nil
end

function HasSeen:HasSeenQuip(quip_id)
	if TheSaveSystem.cheats:GetValue("always_see_quips") then
		return false
	end

	return table.find(self.has_seen.quips, quip_id) ~= nil
end

function HasSeen:HasSeenQuipLine(string_id)
	if TheSaveSystem.cheats:GetValue("always_see_quips") then
		return false
	end

	return self.has_seen.quip_lines[string_id]
end

function HasSeen:HasSeenMastery(mastery_name)
	return table.find(self.has_seen.mastery, mastery_name) ~= nil
end

function HasSeen:MarkDecorAsSeen(decor_name)
	table.insert(self.has_seen.decor, decor_name)
end

function HasSeen:MarkQuipAsSeen(quip_id)
	table.insert(self.has_seen.quips, quip_id)
end

function HasSeen:MarkQuipLineAsSeen(string_id, seen)
	self.has_seen.quip_lines[string_id] = seen
end

function HasSeen:MarkMasteryAsSeen(mastery_name)
	table.insert(self.has_seen.mastery, mastery_name)
end

function HasSeen:DebugDrawEntity(ui, panel, colors)
	if ui:Button("Reset") then
		self:Init()
	end

	panel:AppendTableInline(ui, self.has_seen)
end



return HasSeen
