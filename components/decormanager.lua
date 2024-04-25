--- Component to be installed on a town World entity to manage player-placed and -removed decor.
local Constructable = require "defs.constructable"
local Placer = require "components.placer"

local ON_PLAYER_SET_EVENT = "on_player_set"

local DecorManager = Class(function(self, inst)
	self.inst = inst
	self.on_player_set_fn = function(_, player) self:OnPlayerSet(player) end
	self.inst:ListenForEvent(ON_PLAYER_SET_EVENT, self.on_player_set_fn, TheDungeon)
end)

function DecorManager:OnDecorSpawned(decor)
	decor:AddTag(Placer.DECOR_TAG)
end

--- Verify that the town_props are still placeable. For any that are not, return them to inventory.
function DecorManager:OnPlayerSet(player)
	-- If we are editing the town map via Level Prop Layout Editor, we don't want to modify it AT ALL.
	if TheDungeon:GetDungeonMap():IsDebugMap() then
		return
	end

	local hoard = player.components.inventoryhoard
	local unlocks = player.components.unlocktracker
	for i = 1, #Ents do
		local inst = Ents[i]
		if inst and inst:HasTag(Placer.DECOR_TAG) then
			local item_def = Constructable.FindItem(inst.prefab)
			if not item_def then
				TheLog.ch.DecorManager:printf("%s is not a Constructable", inst.prefab)
			else
				if not Placer.StaticCanPlace(inst, item_def.slot) then
					-- TODO @chrisp #town - how do we know that this is the correct player to refund things to?
					hoard:AddStackable(item_def, 1)

					-- Unlock the Constructable that we have just inserted into the player's hoard such that they will
					-- be able to re-place it in the town via the Build menu.
					if not unlocks:IsRecipeUnlocked(item_def.name) then
						unlocks:UnlockRecipe(item_def.name)
					end
					inst:Remove()
				end
			end
		end
	end
	self.inst:RemoveEventCallback(ON_PLAYER_SET_EVENT, self.on_player_set_fn, TheDungeon)
end

return DecorManager
