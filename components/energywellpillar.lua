local EffectEvents = require("effectevents")
local FollowPrompt = require("widgets/ftf/followprompt")
local HeartTooltip = require("widgets/ftf/hearttooltip")
local soundutil = require "util.soundutil"
local fmodtable = require "defs.sound.fmodtable"

local function _BuildSymbolName(player_num, idx)
	return ("player%s_%s"):format(player_num, idx)
end

local boss_name_idx = {
	["megatreemon"] = 0,
	["owlitzer"] = 1,
	["bandicoot"] = 2,
	["thatcher"] = 3,
}

local EnergyWellPillar = Class(function(self, inst)
	self.inst = inst
	self.is_active = false

	self.active_hearts = {}

	-- store a local of each player's heart levels.
	-- this lets us diff their data with ours to determine how it changed, and which anim we should do.
	self.heart_levels = {}

	self.active_widgets = {}

	-- hide all heart active symbols for p1 - p4
	for i = 1, 4 do
		self.inst.AnimState:HideLayer(_BuildSymbolName(i, 1))
		self.inst.AnimState:HideLayer(_BuildSymbolName(i, 2))
	end

	self.inst:ListenForEvent("playerdeactivated", function() self:OnPlayerDeactivated() end, TheWorld)

	-- do this in an onupdate loop for networking reasons
	self.inst:StartUpdatingComponent(self)
end)

function EnergyWellPillar:OnUpdate()
	if not self.biome_id then return end

	if not TheNet:IsInGame() then
		return
	end

	for _, player in ipairs(AllPlayers) do
		local id = player:GetHunterId()
		local active_heart = player.components.heartmanager:GetEquippedIdxForSlot(self.biome_id) or 0

		if not self.heart_levels[id] then
			self.heart_levels[id] = shallowcopy(player.components.heartmanager:GetHeartLevelsForSlot(self.biome_id))
		end

		local old_levels = self.heart_levels[id]
		local new_levels = player.components.heartmanager:GetHeartLevelsForSlot(self.biome_id)
		local changed_level = false
		local boss_name
		for i = 1, #old_levels do
			if old_levels[i] < new_levels[i] then
				changed_level = new_levels[i]
				boss_name = player.components.heartmanager.hearts[self.biome_id][i].name
				break
			end
		end

		if active_heart ~= self.active_hearts[id] or changed_level then
			local change_data = {
				is_init = GetTime() <= 1,
				changed_level = changed_level,
				boss_name = boss_name,
			}

			self:UpdatePlayerHeartStatus(player, change_data)
		end
	end
end

function EnergyWellPillar:SetBiomeID(id)
	self.biome_id = string.upper(id) -- HeartManager uses uppercase biome IDs to sort hearts
	return self
end

function EnergyWellPillar:GetBiomeID()
	return self.biome_id
end

function EnergyWellPillar:UpdatePlayerHeartStatus(player, change_data)
	self.active_hearts[player:GetHunterId()] = player.components.heartmanager:GetEquippedIdxForSlot(self.biome_id)
	self.heart_levels[player:GetHunterId()] = shallowcopy(player.components.heartmanager:GetHeartLevelsForSlot(self.biome_id))
	self:RefreshState(player, change_data)
end

function EnergyWellPillar:GetActiveIdxForPlayer(player)
	local id = player:GetHunterId()
	return self.active_hearts[id] or 0
end

function EnergyWellPillar:RefreshState(player, change_data)
	local active_idx = self:GetActiveIdxForPlayer(player)

	if active_idx > 0 then
		local boss_idx = boss_name_idx[change_data.boss_name] or 0
		if not self.is_active then
			self.is_active = true
			EffectEvents.MakeNetEventPushEventOnMinimalEntity(self.inst, "activate_well", { is_init = change_data.is_init })
			soundutil.PlayCodeSound(self.inst,fmodtable.Event.Wellspring_Pillar_Activate,{fmodparams = {bossName = boss_idx} })
			EffectEvents.MakeNetEventPushEventOnMinimalEntity(self.inst, "leveled_heart", { boss_name = change_data.boss_name })
		else
			if change_data.changed_level then
				EffectEvents.MakeNetEventPushEventOnMinimalEntity(self.inst, "add_heart")
				soundutil.PlayCodeSound(self.inst, fmodtable.Event.Wellspring_Pillar_LevelUp,
					{
						fmodparams = {
							bossName = boss_idx,
							heartLevel = change_data.changed_level
						}
					})
			else
				EffectEvents.MakeNetEventPushEventOnMinimalEntity(self.inst, "switch_heart")
				soundutil.PlayCodeSound(self.inst, fmodtable.Event.Wellspring_Pillar_Switch,
					{
						fmodparams = {
							bossName = boss_idx,
							heartLevel = change_data.changed_level
						}
					})
			end
		end
	end
end

function EnergyWellPillar:RefreshSymbolsForAllPlayers()
	for id = 1, 4 do
		-- always hide all, fixes case where player left game
		self.inst.AnimState:HideLayer(_BuildSymbolName(id, 1))
		self.inst.AnimState:HideLayer(_BuildSymbolName(id, 2))
	end

	for _, player in ipairs(AllPlayers) do
		local id = player:GetHunterId()
		local active_idx = self:GetActiveIdxForPlayer(player)
		self.inst.AnimState:ShowLayer(_BuildSymbolName(id, active_idx))
	end
end

function EnergyWellPillar:OnPlayerDeactivated()
	-- do any players that are still active have hearts?
	local any_active = false
	for _, player in ipairs(AllPlayers) do
		local active_idx = self:GetActiveIdxForPlayer(player)
		if active_idx > 0 then
			any_active = true
			break
		end
	end
	
	if self.is_active and not any_active then
		-- if no, then turn off the pillar.
		-- symbols are hidden as part of the state
		EffectEvents.MakeNetEventPushEventOnMinimalEntity(self.inst, "deactivate_well")
	else
		-- otherwise just hide the player's symbols
		self:RefreshSymbolsForAllPlayers()
	end
end

function EnergyWellPillar:ShowCurrentHeartDetails(player)
	local active_idx = self:GetActiveIdxForPlayer(player)
	if active_idx == 0 then return end

	local heart_data = player.components.heartmanager:GetEquippedHeartForSlot(self:GetBiomeID())

	if self.active_widgets[player] then
		self.tt:LayoutWithContent({
			player = player,
			heart_data = heart_data,
		})
		self.tt:SetPosition(0,0)
		return
	end

	self.active_widgets[player] = TheDungeon.HUD:AddWorldWidget(FollowPrompt(self.inst))
		:SetName("Heart Details")
		:SetTarget(player)
		:SetRegistration("right", "center")
		:SetOffsetFromTarget(Vector3(-0.6, 4.1, 0))
		:SetClickable(false)

	self.tt = self.active_widgets[player]:AddChild(HeartTooltip())
	self.tt:LayoutWithContent({
		player = player,
		heart_data = heart_data,
	})
	self.tt:SetPosition(0,0)
end

function EnergyWellPillar:HideCurrentHeartDetails(player)
	if self.active_widgets[player] then
		self.active_widgets[player]:Remove()
		self.active_widgets[player] = nil
	end
end

return EnergyWellPillar
