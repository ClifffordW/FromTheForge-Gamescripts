local Consumable = require "defs.consumable"
local lume = require "util.lume"
local fmodtable = require "defs.sound.fmodtable"
local Recipe = require"defs/recipes"
local biomes = require"defs/biomes"
local encounters = require "encounter.encounters"
local SpawnBalancer = require"spawnbalancer"

-- This is a player component that contains persistent data used to decide
-- what loot to drop based on player progression, player's lucky status,
-- the enemy's loot table, etc.
local LootDropManager = Class(function(self, inst)
	self.inst = inst

    self.wave_info = {}
	self.selected_wave = {}
end)

function LootDropManager:InitRNG()
	if not self.rng then
		self.rng = CreatePlayerRNG(self.inst, 0x7007D208, "LootDropManager")
	end
end

function LootDropManager:OnPostLoadWorld()
	--don't try to create loot in town
	if not TheWorld or TheWorld:HasTag("town") then
		return
	end

	--no encounter in this room
	if TheWorld.components.spawncoordinator.encounter == nil then
		return
	end

	self:InitRNG()
	self.selected_wave = {}

	--look at my grab bag, see if I should drop loot
	local loot_count = self.inst.components.grabbag:PickFromBag( "loot_chance", TUNING.LOOT_REWARD_CHANCE, self.rng)
	if TheDungeon:GetDungeonMap().nav:GetProgressThroughDungeon() > 0.5 then
		--if you beat the miniboss, then pick twice!
		loot_count = loot_count + self.inst.components.grabbag:PickFromBag( "loot_chance", TUNING.LOOT_REWARD_CHANCE, self.rng)
	end

	if loot_count > 0 then
		--determine which wave I should drop it in
		local balancer = SpawnBalancer()
		local executer = { exec_fn = TheWorld.components.spawncoordinator.encounter }
		balancer.biome_location = biomes.locations[TheDungeon:GetDungeonMap().data.location_id]
		local info = balancer:EvaluateEncounter(TheWorld.components.spawncoordinator.encounter_idx, executer, 1)
		self.wave_info = info

		local eligible_waves = {}

		--if the wave has health, then it has enemies to drop loot...
		local spawn_wave = 0
		for _, wave in ipairs(info.wave_info) do
			if wave.wave_health and wave.wave_health > 0 and wave.wave_enemies and wave.wave_enemies > 0 then
				spawn_wave = spawn_wave + 1
				table.insert(eligible_waves, spawn_wave)
			end
		end
		self.wave_info.eligible_waves = eligible_waves

		--randomly select an eligible wave to drop loot
		for i = 1, loot_count do
			local selected_wave_idx = eligible_waves[self.rng:Integer(#eligible_waves)]

			--mark that wave to drop loot
			local loot_in_wave = self.selected_wave[ selected_wave_idx ]
			self.selected_wave[ selected_wave_idx ] = loot_in_wave and loot_in_wave + 1 or 1
		end
	end
end

function LootDropManager:GetLootCount(current_wave)
	return self.selected_wave[current_wave] or 0
end

----

function LootDropManager:OnLootDropperDeath(ent)

	local hasAddedLoot = false

	local ascension = TheDungeon.progression.components.ascensionmanager:GetCurrentLevel()
	local value
	if ent:HasTag("boss") then
		if not self.rng then
			-- Debug flow does not run OnPostLoadWorld(), so self.rng doesn't exist yet.
			self:InitRNG()
		end
		value = self.inst.components.grabbag:PickFromBag( "boss_loot_count_A"..ascension, TUNING.BOSS_LOOT_VALUE[ascension+1], self.rng)
	elseif ent:HasTag("miniboss") then
		if not self.rng then
			-- Debug flow does not run OnPostLoadWorld(), so self.rng doesn't exist yet.
			self:InitRNG()
		end
		value = self.inst.components.grabbag:PickFromBag( "miniboss_loot_count_A"..ascension, TUNING.MINIBOSS_LOOT_VALUE[ascension+1], self.rng)
	else
		value = ent.components.lootdropper:GetLootDropperValue()
	end

	if value >= 1 then
		local possible_drops = self:CollectPossibleLootDrops(ent.components.lootdropper.loot_drop_tags)
		hasAddedLoot = true
		local loot_to_drop, lucky_rolls = self:GenerateLootFromItems(possible_drops, value)
		ent.components.lootdropper:AddLootToDrop(self.inst, loot_to_drop)

		if next(lucky_rolls) then
			ent.components.lootdropper:AddLuckyLoot(self.inst, lucky_rolls)
		end
	end

	return hasAddedLoot
end

-- ent (i.e. mob enemy) used for non-instanced, immutable data only:
-- prefab (string)
-- loot drop tags via ent.components.lootdropper.loot_drop_tags
function LootDropManager:GenerateLootFromItems(possible_drops, initial_value)
	local rolled_drops = {}
	local luck_drops = {}
	local num_tries = 3 * initial_value

	self:InitRNG() -- try init here in case we receive early loot events before OnPostLoadWorld is run

	while (initial_value > 0) and num_tries > 0 do
		-- printf("%s dropped some loot!", ent.prefab)
		num_tries = num_tries - 1

		local weighted_drops = {}
		for _, def in ipairs(possible_drops) do
			weighted_drops[def.name] = def.weight
		end
		-- printf("rolled rarity: %s", rarity)
		local drop = self.rng:WeightedChoice(weighted_drops)
		if drop then
			-- printf("---added %s to drops", drop)
			if not rolled_drops[drop] then
				rolled_drops[drop] = 0
			end
			rolled_drops[drop] = rolled_drops[drop] + 1
			if self.inst.components.lucky and self.inst.components.lucky:DoLuckRoll() then
				if not luck_drops[drop] then
					luck_drops[drop] = 0
				end
				luck_drops[drop] = luck_drops[drop] + 1
				--sound
				local soundutil = require "util.soundutil"
				local params = {}
				params.fmodevent = fmodtable.Event.lucky
				params.sound_max_count = 1
				soundutil.PlaySoundData(self.inst, params)
			end

			initial_value = initial_value - 1
		else
			-- print("!!!!!!had nothing to add to drop!")
		end
	end

	return rolled_drops, luck_drops
end

function LootDropManager:CollectPossibleLootDrops(loot_tags)
	local loot = {}
	for _, tags in ipairs(loot_tags) do
		loot = lume.concat(loot, Consumable.GetItemList(Consumable.Slots.MATERIALS, tags))
	end
	return loot
end

function LootDropManager:DebugDrawEntity(ui, panel, colors)
	for wave, count in pairs(self.selected_wave) do
		ui:Value("Wave: "..tostring(wave), count)
	end
	if ui:Button("Wave Info") then
		panel:PushNode( panel:CreateDebugNode( self.wave_info ))
	end
end


return LootDropManager
