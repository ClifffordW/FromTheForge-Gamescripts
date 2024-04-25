local DebugNodes = require "dbui.debug_nodes"
local Mastery = require "defs.masteries"
local Cosmetic = require "defs.cosmetics.cosmetics"
local DebugLister = require "debug.inspectors.debug_lister"
local MetaProgress = require "defs.metaprogression"

local unlocked_via = function(item)
	if not item.locked then
		return "default"
	end

	for _, mastery_group in pairs(Mastery.Items) do
		for _, mastery in pairs(mastery_group) do
			for _, reward in ipairs(mastery.rewards) do
				if reward.slot == "PLAYER_BODYPART" and reward.def.name == item.name then
					return "Mastery: "..mastery.name
				end
			end
		end
	end

	for groupname, progress_group in pairs(MetaProgress.Items) do
		-- print("Progress Group:", groupname)
		for progressname, progress in pairs(progress_group) do
			-- print("		Progress:", progressname)
			for _, reward_data in ipairs(progress.rewards) do
				-- print("			Reward Data:", _)
				-- If this is a reward group, this will be a table. Otherwise, it will be a single def.

				if reward_data.rewards then
					for _, reward in ipairs(reward_data.rewards) do
						if reward.slot == "PLAYER_BODYPART" and reward.def.name == item.name then
							return groupname.."."..progressname
						end
					end
				end
			end
		end
	end

	return ""
end

local CosmeticLister = Class(DebugLister, function(self)
	DebugLister._ctor(self, "Cosmetic Lister")

	self:SetColumns({
		{ key = "bodypart_group", name = "Group" },
		{ key = "name", name = "Name" },
		{ key = "species", name = "Species" },
		{ key = "locked", name = "Locked" },
		{ key = "unlocked", name = "Unlocked Via", 
			fn = function(item) 
				return unlocked_via(item)
			end
		},
	})

	self:Refresh()
	self:SetSource(Cosmetic)

	self.reward_available_only = false
end)

function CosmeticLister:Refresh()	
	self:ResetValues()

	local body_items = Cosmetic.Items["PLAYER_BODYPART"]
	for key, item in pairs(body_items) do

		local should_add = true

		if self.reward_available_only then
			if unlocked_via(item) ~= "" then
				should_add = false
			end
		end

		if should_add then
			local item_v = {}

			for _, v in ipairs(self:GetColumns()) do
				if v.fn then
					item_v[v.key] = v.fn(item)
				else
					item_v[v.key] = tostring(item[v.key])
				end
			end

			item_v["data"] = item

			self:AddValue(item_v)
		end
	end
end

function CosmeticLister:RenderPanel( ui, panel )
	local changed, available = ui:Checkbox("Available for Reward Only", self.reward_available_only)
	if changed then
		self.reward_available_only = available
		self:Refresh()
	end

 	CosmeticLister._base.RenderPanel(self, ui, panel)
end

CosmeticLister.PANEL_WIDTH = 800
CosmeticLister.PANEL_HEIGHT = 1000

DebugNodes.CosmeticLister = CosmeticLister

return CosmeticLister
