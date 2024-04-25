local MetaProgress = require "defs.metaprogression.metaprogress"
local Consumable = require"defs.consumable"
local Power = require"defs.powers"
local Constructable = require"defs.constructable"
local Cosmetic = require "defs.cosmetics.cosmetics"
local Equipment = require "defs.equipment"
local slotutil = require "defs.slotutil"
local reward_group_icons = require "gen.atlas.ui_ftf_reward_group_icons"
local fmodtable = require "defs.sound.fmodtable"

MetaProgress.all_rewards = {}

MetaProgress.Reward = Class(function(self, category, slot, id, count)
	table.insert(MetaProgress.all_rewards, self)
	local def = category.Items[slot][id]

	assert(def ~= nil, ("Tried to create a reward that doesn't exist: [%s/%s]"):format(slot, id))

	self.slot = slot
	self.def = def
	self.count = count or 1 -- default to 1. Only used when giving players items.

	if def ~= nil then
		-- if the reward has a def then give the reward easy access to the icon and pretty strings of the reward
		self.pretty = def.pretty or {name = "[NOTLOCALIZED] "..id}
		self.icon = def.icon
	end
end)

function MetaProgress.Reward:UnlockRewardForPlayer(player, add_to_inventory)
	if self.def.slot == Power.Slots.PLAYER then
		player.components.unlocktracker:UnlockPower(self.def.name)
	elseif self.def.slot == Power.Slots.SKILL then
		player.components.unlocktracker:UnlockPower(self.def.name)
	elseif self.def.slot == Equipment.Slots.WEAPON then
		-- Unlocking a weapon type.
		local weapon_type = self.def.weapon_type
        player.components.unlocktracker:UnlockWeaponType(WEAPON_TYPES[weapon_type])

        -- itemforge can't be at top of the file
		local itemforge = require "defs.itemforge"
		local item = itemforge.CreateEquipment(self.def.slot, self.def)

		local hoard = player.components.inventoryhoard
		hoard:AddToInventory(self.def.slot, item)
		hoard:SetLoadoutItem(hoard.data.selectedLoadoutIndex, self.def.slot, item)
		hoard:EquipSavedEquipment()
		player.sg:GoToState("unsheathe_fast")

        player:DoTaskInAnimFrames(20, function()
			TheWorld.components.ambientaudio:PlayMusicStinger(fmodtable.Event.Mus_weaponUnlock_Stinger)

			local title = STRINGS.WEAPONS.UNLOCK.TITLE
			local unlock_string = STRINGS.WEAPONS.UNLOCK[weapon_type] or string.format("%s UNLOCK STRING MISSING", weapon_type)
			local how_to_play = STRINGS.WEAPONS.HOW_TO_PLAY[weapon_type] or string.format("%s HOW TO PLAY STRING MISSING", weapon_type)
			local focus_hit = STRINGS.WEAPONS.FOCUS_HIT[weapon_type] or string.format("%s FOCUS HIT STRING MISSING", weapon_type)
			local description = string.format("%s\n\n%s\n\n%s", unlock_string, how_to_play, focus_hit)

			local ItemUnlockPopup = require "screens.itemunlockpopup"
			local screen = ItemUnlockPopup(nil, nil, true)
				:SetItemUnlock(item, title, description)

			screen:SetOnDoneFn(
				function()
				TheFrontEnd:PopScreen(screen)
			end)
			
			-- DANY ADD YOUR SOUND HERE
			--TheFrontEnd:GetSound():PlaySound("")
			TheFrontEnd:PushScreen(screen)
			screen:AnimateIn()
		end)

	elseif Cosmetic.IsSlot(self.def.slot) then
		player.components.unlocktracker:UnlockCosmetic(self.def.name, self.def.slot)
	elseif Constructable.IsSlot(self.def.slot) then
		player.components.unlocktracker:UnlockRecipe(self.def.name)
		-- if add_to_inventory then
		-- 	player.components.inventoryhoard:AddStackable(self.def, 1)
		-- end
	elseif self.def.slot == Consumable.Slots.KEY_ITEMS then
		if self.def.recipes then
			for _, data in ipairs(self.def.recipes) do
				player.components.unlocktracker:UnlockRecipe(data.name)
			end
		end
	elseif self.def.slot == Consumable.Slots.MATERIALS then
		if add_to_inventory then
			player.components.inventoryhoard:AddStackable(self.def, self.count)
		end
		-- we'll only Unlock things here: everything else we will Drop in metaprogressstore.
	else
		assert(true, string.format("Invalid progress Type! [%s - %s]", self.def.slot, self.def.name))
	end
end

local function GetIcon(group_id)
	local icon_name = ("reward_group_%s"):format(group_id)
	local tex = reward_group_icons.tex[icon_name] or reward_group_icons.tex["reward_group_temp"]
	return tex
end

MetaProgress.RewardGroup = Class(function(self, name, rewards)
	self.name = name
	self.icon = GetIcon(name) -- All reward groups will have the temp texture right now

	-- Currently does NOT validate that strings for these exist
	self.pretty = slotutil.GetPrettyStrings("REWARDGROUPS", name)

	self.rewards = rewards
end)

function MetaProgress.RewardGroup:GetRewards()
	return self.rewards
end

function MetaProgress.RewardGroup:GetIcon()
	return self.icon
end

function MetaProgress.RewardGroup:UnlockRewardForPlayer(player)
	for _, reward in ipairs(self:GetRewards()) do
		-- printf("Unlocking reward for player has part of reward group: %s", reward.def.name)
		reward:UnlockRewardForPlayer(player)
	end
end
