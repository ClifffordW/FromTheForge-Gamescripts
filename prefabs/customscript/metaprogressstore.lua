local CurrencyType = require "currency.currency_type"
local Constructable = require "defs.constructable"
local Cosmetic = require "defs.cosmetics.cosmetics"
local Power = require "defs.powers"
local MetaProgress = require "defs.metaprogression.metaprogress"
local Lume = require "util.lume"
local Enum = require "util.enum"
local CurrencyFactory = require "currency.currency_factory"
local LootEvents = require "lootevents"

local INTERACTOR_KEY <const> = "MetaProgressStore"

local StatusWidgetLocation = Enum {
	"Player",
	"Prop"
}

local PlayerBinding = Enum {
	"None",
	"Player 1",
	"Player 2",
	"Player 3",
	"Player 4",
}

local PurchaseType = Enum {
	"XPPerCurrency",
	"BiomeExploration",
	"Reward"
}
local DEFAULTS <const> = {
	currency = CurrencyType.s.Meta,
	meta_progress = MetaProgress.Slots.BIOME_EXPLORATION,
	interact_radius = 4,
	weapon = "polearm",
	purchase_type = PurchaseType.s.BiomeExploration,
	xp_per_currency = 10,
	currency_per_deposit = 1,
	status_widget_location = StatusWidgetLocation.s.Player,
	player_binding = PlayerBinding.s.None,
}

local MetaProgressStore = {
	default = {},
}

-- Exact name 'Defaults' is necessary for a custom script to have LivePropEdit work correctly.
MetaProgressStore.Defaults = DEFAULTS

MetaProgressStore.Events = Enum {
	"deposit",
	"not_enough_exp",
	"rewards_pending",
	"rewards_claimed",
	"rewards_delivery_request"
}

local function IsBoundPlayer(player, player_binding)
	local player_number = PlayerBinding.id[player_binding] - 1
	local hunter_id = player:GetHunterId()
	return player_number == hunter_id
end

function MetaProgressStore.BindToPlayer(inst, script_args)
	-- At the first moment we have access to the player to which we are bound, initialize the MetaProgressStore.
	if inst.on_player_entered_fn then
		return
	end
	inst.on_player_entered_fn = function(_source, player)
		if IsBoundPlayer(player, script_args.player_binding) then
			MetaProgressStore.OnBoundPlayerEntered(inst, script_args, player)
		end
	end
	inst:ListenForEvent("playerentered", inst.on_player_entered_fn, TheWorld)
end

function MetaProgressStore.OnBoundPlayerEntered(inst, args, player)
	-- If they have a pending reward, post some kind of "You've got mail!" notification.
	local progress_def, progress_instance = MetaProgressStore.GetProgressInstance(player, args)
	if not progress_instance then
		return
	end
	if progress_instance:IsPendingLevel() then
		inst:PushEvent(MetaProgressStore.Events.s.rewards_pending)
	end
	if not inst.on_rewards_delivery_requested_fn then
		inst.on_rewards_delivery_requested_fn = function(inst)
			MetaProgressStore.DeliverReward(inst, player, args, progress_instance)
		end
		inst:ListenForEvent(
			MetaProgressStore.Events.s.rewards_delivery_request,
			inst.on_rewards_delivery_requested_fn
		)
	end
end

function MetaProgressStore.default.CustomInit(inst, script_args)
	-- Ensure all args are present. Code may outpace data and these script_args may come from data.
	for key, default_value in pairs(DEFAULTS) do
		if not script_args[key] then
			if type(default_value) == "table" then
				default_value = deepcopy(default_value)
			end
			script_args[key] = default_value
		end
	end
	dbassert(not inst.components.interactable, "Stomping interactable component")
	inst:AddComponent("interactable")
	inst:AddComponent("townhighlighter")

	MetaProgressStore.BindToPlayer(inst, script_args)

	inst.components.interactable
		:SetRadius(script_args.interact_radius)
		:SetInteractStateName("deposit_currency")
		:SetOnGainInteractFocusFn(function(inst, player) MetaProgressStore.OnGainInteractFocus(inst, player, script_args) end)
		:SetOnInteractFn(function(inst, player) 
			if MetaProgressStore.OnInteract(inst, player, script_args) then
				TheDungeon:GetDungeonMap():RecordActionInCurrentRoom("meta_progress_store")
			end
		end)
		:SetOnLoseInteractFocusFn(function(inst, player) MetaProgressStore.OnLoseInteractFocus(inst, player, script_args) end)

	if script_args.meta_progress == MetaProgress.Slots.BIOME_EXPLORATION then
		inst:SetStateGraph("sg_corestone_converter")
	end

	TheSim:LoadPrefabs({ GroupPrefab("deps_ui_decor") })
	inst:ListenForEvent("onremove", function() TheSim:UnloadPrefabs({ GroupPrefab("deps_ui_decor") }) end)
end

local CanInteractResult = Enum {
	"Ok",
	"BusyUi",
	"BusySg",
	"NoProgress",
	"WrongPlayer",
	"DeactivatedUi",
	"Inactive",
}

function MetaProgressStore.CanInteract(inst, player, args)
	local interactor = player.components.interactor

	if inst.sg and inst.sg:HasStateTag("no_interact") then
		interactor:SetStatusText(INTERACTOR_KEY, nil)
		return CanInteractResult.s.Inactive
	end

	if inst.is_animating then
		interactor:SetStatusText(INTERACTOR_KEY, nil)
		return CanInteractResult.id.BusyUi
	end

	if inst:HasTag("busy") then
		interactor:SetStatusText(INTERACTOR_KEY, nil)
		return CanInteractResult.id.BusySg
	end

	local progress_def, progress_instance = MetaProgressStore.GetProgressInstance(player, args)
	if not progress_instance then
		return CanInteractResult.id.NoProgress
	end

	if not MetaProgressStore.MatchesPlayerBinding(player, args) then
		return CanInteractResult.id.WrongPlayer
	end

	if args.status_widget_location == StatusWidgetLocation.s.Prop
		and not inst.meta_progress_store_ui
	then
		return CanInteractResult.id.DeactivatedUi
	end

	return CanInteractResult.id.Ok, progress_def, progress_instance
end

function MetaProgressStore.BuildCurrency(args)
	return CurrencyFactory.Build({currency_type = CurrencyType.id[args.currency]})
end

function MetaProgressStore.UpdateStatus(inst, player, args, exp_log)
	local interactor = player.components.interactor

	local can_interact, progress_def, progress_instance = MetaProgressStore.CanInteract(inst, player, args)
	if can_interact ~= CanInteractResult.id.Ok then
		TheLog.ch.MetaProgressStore:printf(
			"MetaProgressStore.UpdateStatus->CanInteract failed: %s",
			CanInteractResult:FromId(can_interact)
		)
		interactor:SetStatusText(INTERACTOR_KEY, nil)
		if can_interact == CanInteractResult.id.NoProgress then
			inst.meta_progress_store_ui:Hide()
		end
		return
	end

	local currency = MetaProgressStore.BuildCurrency(args)
	local cost, _exp = MetaProgressStore.EvaluateDeposit(args, progress_instance)

	local deposit_verb = args.purchase_type == PurchaseType.s.XPPerCurrency
		and STRINGS.UI.VENDING_MACHINE.DEPOSIT..currency:GetIcon()
		or STRINGS.UI.VENDING_MACHINE.PURCHASE

	local deposit_action = currency:GetAvailableFunds(player) < cost
		and currency:MakeInsufficientFundsText()
		or deposit_verb

	local next_reward = MetaProgressStore.GetNextReward(player, args)
	local action

	if progress_instance:IsPendingLevel() then
		action = STRINGS.UI.META_PROGRESS.TAKE_REWARDS
	elseif next_reward then
		if cost > 0 then
			action = string.format( "%s (%d)", deposit_action, cost)
		else
			action = STRINGS.UI.META_PROGRESS.NOT_ENOUGH_XP
		end
	elseif progress_def.no_rewards_cb then
		if args.meta_progress == MetaProgress.Slots.WEAPON_UNLOCKS then
			local weapon = STRINGS.ITEM_CATEGORIES[string.upper(args.weapon)]
			action = STRINGS.UI.META_PROGRESS.WEAPON_RACK:subfmt({weapon = weapon})
		end
	end

	if args.status_widget_location == StatusWidgetLocation.s.Prop then
		if not action then
			interactor:SetStatusText(INTERACTOR_KEY, nil)
			inst.meta_progress_store_ui:Hide()
			return
		end

		if not next_reward then
			inst.meta_progress_store_ui:Hide()
		end
	end

	local xp_target = math.round(progress_instance:GetEXPForLevel(progress_instance:GetLevel()))

	if args.status_widget_location == StatusWidgetLocation.s.Player then
		local reward = next_reward.pretty.name
		local xp = math.round(progress_instance:GetEXP())
		local reward_status = STRINGS.UI.META_PROGRESS.REWARD_STATUS:subfmt({
			reward = reward,
			xp = xp,
			xp_target = xp_target,
		})
		local status = reward_status .. "\n"
			.. action .. "\n"
			.. next_reward.pretty.desc
		interactor:SetStatusText(INTERACTOR_KEY, status)

	elseif args.status_widget_location == StatusWidgetLocation.s.Prop then
		interactor:SetStatusText(INTERACTOR_KEY, action)

		-- TODO @chrisp #meta - weapon rack status can differ between players so we should either show all info on
		-- the player-specific interactor widget, or write the weapon rack widget to show info for multiple players

		if not exp_log then
			inst.meta_progress_store_ui:SetProgress(progress_instance)
		else
			local meta_progress = {
				meta_reward = progress_instance,
				meta_reward_def = progress_def,
				meta_level = progress_instance:GetLevel(),
				meta_exp = progress_instance:GetEXP(),
				meta_exp_max = xp_target,
				meta_reward_log = exp_log,
			}
			inst.meta_progress_store_ui:RefreshMetaProgress(meta_progress)
		end
		--inst.meta_progress_store_ui.price_tag:SetText(currency:MakePriceText(price, cost))
		inst.meta_progress_store_ui:SetPriceText(currency:MakePriceText({
			balance = cost,
			cost = cost,
		}))
		if cost == 0 then
			--inst.meta_progress_store_ui.price_tag:Hide()
		end
	else
		dbassert(false, "Unhandled StatusWidgetLocation variant: " .. (args.status_widget_location or "nil"))
	end
end

function MetaProgressStore.MatchesPlayerBinding(player, args)
	return args.player_binding == PlayerBinding.s.None
		or IsBoundPlayer(player, args.player_binding)
end

function MetaProgressStore.OnGainInteractFocus(inst, player, args)
	if not MetaProgressStore.MatchesPlayerBinding(player, args) then
		local interactor = player.components.interactor
		interactor:SetStatusText(INTERACTOR_KEY, STRINGS.UI.META_PROGRESS.NOT_MINE)
	else
		if args.status_widget_location == StatusWidgetLocation.s.Prop then
			local progress_def, progress_instance = MetaProgressStore.GetProgressInstance(player, args)
			local _cost, exp = MetaProgressStore.EvaluateDeposit(args, progress_instance)
			-- TODO @chrisp #meta - clean this widget up if OnLoseInteractFocus never gets hit
			if args.purchase_type == PurchaseType.s.Reward then
				local WeaponRackTooltip = require "widgets.ftf.weaponracktooltip"

				inst.meta_progress_store_ui = TheDungeon.HUD:AddWorldWidget(WeaponRackTooltip(
					player
				))
				:SetTarget(inst)
			else
				local MetaProgressStoreWidget = require "widgets.ftf.metaprogressstorewidget"

				inst.meta_progress_store_ui = TheDungeon.HUD:AddWorldWidget(MetaProgressStoreWidget(
					player,
					exp
				))
				:SetTarget(inst)
				:SetOffsetFromTarget(Vector3(0, 6.5, 0))
			end
		end
		MetaProgressStore.UpdateStatus(inst, player, args)

		local currency = MetaProgressStore.BuildCurrency(args)
		inst.currency = currency:GetType()
		inst.deposit_rate = currency.use_default_deposit_rates
			and require "currency.default_deposit_rates"
	end
end

function MetaProgressStore.OnLoseInteractFocus(inst, player, args)
	player.components.interactor:SetStatusText(INTERACTOR_KEY, nil)
	if inst.meta_progress_store_ui then
		inst.meta_progress_store_ui:Remove()
		inst.meta_progress_store_ui = nil
	end
	inst.is_animating = false
end

function MetaProgressStore.GetProgressInstance(player, args)
	local progress_defs = MetaProgress.Items[args.meta_progress];
	local progress_key
	if args.meta_progress == MetaProgress.Slots.BIOME_EXPLORATION then
		progress_key = TheDungeon:GetDungeonMap().data.location_id
	elseif args.meta_progress == MetaProgress.Slots.KONJUR_CONVERSION then
		progress_key = "basic"
	elseif args.meta_progress == MetaProgress.Slots.DEFAULT_UNLOCK then
		progress_key = "default"
	elseif args.meta_progress == MetaProgress.Slots.MONSTER_RESEARCH then
		progress_key = args.monster
	elseif args.meta_progress == MetaProgress.Slots.RELATIONSHIP_CORE then
		progress_key = args.npc
	elseif args.meta_progress == MetaProgress.Slots.WEAPON_UNLOCKS then
		progress_key = args.weapon
	end
	local progress_def = progress_key and progress_defs[progress_key]
	return progress_def,
		progress_def and player.components.metaprogressmanager:ManifestProgress(progress_def)
end

function MetaProgressStore.GetNextReward(player, args)
	local progress_def, progress_instance = MetaProgressStore.GetProgressInstance(player, args)
	return progress_instance and progress_instance:GetNextReward()
end

function MetaProgressStore.OnInteract(inst, player, args)
	local can_interact, progress_def, progress_instance = MetaProgressStore.CanInteract(inst, player, args)
	if can_interact ~= CanInteractResult.id.Ok then
		return false
	end

	if progress_instance:IsPendingLevel() then
		if inst.sg then
			inst:PushEvent(MetaProgressStore.Events.s.rewards_claimed)
		else
			MetaProgressStore.DeliverReward(inst, player, args, progress_instance)
		end
		return true
	end

	local next_reward = MetaProgressStore.GetNextReward(player, args)
	if next_reward then
		return MetaProgressStore.Deposit(
			inst,
			player,
			args,
			progress_instance,
			next_reward
		)
	elseif progress_def.no_rewards_cb then
		progress_def.no_rewards_cb(inst, player, args)
		return true
	else
		return false
	end
end

local function _SpawnPrefab(pfb, player, x, z)
	local prefab = SpawnPrefab(pfb, player)
	prefab.Transform:SetPosition(x, 0, z)
	if prefab.components.singlepickup then
		prefab.components.singlepickup:AssignToPlayer(player)
	end
end

function MetaProgressStore.SpawnCircleOfPrefabs(inst, player, prefabs)
	-- TODO #metashop make this a common util func
	local start_angles =
	{
		-- per count of prefabs
		0,
		0,
		90,
		45,
		90,
	}

	local num_spawns = #prefabs
	local angle_per_spawn = 360 / num_spawns
	local circle_radius = 2
	local start_angle = start_angles[num_spawns]

	local pos = inst:GetPosition()

	pos.z = pos.z - 5 -- Offset down a bit.

	for i, pfb in ipairs(prefabs) do
		local angle_deg = (i * angle_per_spawn) + start_angle
		local angle = math.rad(angle_deg)
		local zOffset = math.sin(angle) * circle_radius
		local xOffset = math.cos(angle) * circle_radius
		_SpawnPrefab(pfb, player, pos.x + xOffset, pos.z + zOffset)
	end
end

function MetaProgressStore.SpawnLinesOfPrefabs(inst, player, prefabs)
	-- TODO #metashop make this a common util func
	local pos = inst:GetPosition()
	local start_x = (#prefabs-1) * -1
	local start_z = -2
	local current_x = pos.x + start_x
	local current_z = pos.z + start_z

	local gap_x = 2
	local amount_in_row = 4

	local spawned = 1
	for i, pfb in ipairs(prefabs) do
		if spawned > amount_in_row then
			current_z = current_z - 5
			current_x = start_x
			spawned = 0
		end
		_SpawnPrefab(pfb, player, current_x, current_z)
		current_x = current_x + gap_x
		spawned = spawned + 1
	end
end

function MetaProgressStore.EvaluateDeposit(args, progress_instance)
	local cost
	local exp
	if args.purchase_type == PurchaseType.s.XPPerCurrency then
		local difficulty = TheSceneGen.components.scenegen:GetTier()
		cost = math.ceil(args.currency_per_deposit * TUNING.MARKET_ITEM_COSTS.DUNGEON_MODIFIER[difficulty])
		exp = math.round(cost * args.xp_per_currency)
	elseif args.purchase_type == PurchaseType.s.Reward then
		exp = progress_instance:GetEXPUntilNextLevel()
		cost = math.ceil(exp / args.xp_per_currency)
	elseif args.purchase_type == PurchaseType.s.BiomeExploration then
		exp = 0
		cost = 0
	else
		dbassert(false, "unsupported PurchaseType variant (" .. args.purchase_type .. ")")
	end
	return cost, exp
end

function MetaProgressStore.Deposit(inst, player, args, progress_instance, next_reward)
	local currency = MetaProgressStore.BuildCurrency(args)
	local cost, exp = MetaProgressStore.EvaluateDeposit(args, progress_instance)

	if args.purchase_type == PurchaseType.s.BiomeExploration then
		--jcheng: not enough xp, so just wiggle and stop
		inst:PushEvent(MetaProgressStore.Events.s.not_enough_exp)
		return false
	end

	if currency:GetAvailableFunds(player) < cost then
		return false
	end

	currency:ReduceFunds(player, cost)
	local exp_log = progress_instance:GrantExperienceIfPossible(exp)

	local did_level = next(exp_log) and exp_log[1].did_level
	inst:PushEvent(MetaProgressStore.Events.s.deposit, {did_level = did_level})

	local function ClaimRewards()
		-- If we do have an sg, rewards will be delivered via the sg sending a rewards_delivery_request event.
		-- This happens if we pushed the deposit event with did_level set to true.
		if not inst.sg then
			MetaProgressStore.DeliverReward(inst, player, args, progress_instance)
		end
		-- MetaProgressStore.OnLoseInteractFocus(inst, player, args)
	end

	-- If we can animate the deposit, let that process handle delivery of the reward if there is one, when the
	-- animation finishes.
	if not MetaProgressStore.AnimateDeposit(inst, player, args, exp_log, ClaimRewards) then
		-- Otherwise examine the exp_log directly and deliver the reward immediately if we levelled.
		if did_level then
			ClaimRewards()
		end
	end

	MetaProgressStore.UpdateStatus(inst, player, args, exp_log)

	return true
end

function MetaProgressStore.AnimateDeposit(inst, player, args, exp_log, on_reward_earned)
	if not exp_log then
		return false
	end

	if not inst.meta_progress_store_ui then
		return false
	end

	if args.purchase_type ~= PurchaseType.s.XPPerCurrency then
		return false
	end

	inst.is_animating = true
	inst.meta_progress_store_ui:OnExpGranted(exp_log, function(progress)
		inst.is_animating = false
		if progress.reward_earned then
			on_reward_earned()
		else
			MetaProgressStore.UpdateStatus(inst, player, args)
		end
	end)
	return true
end

function MetaProgressStore.DeliverReward(inst, player, args, progress_instance)
	-- TODO #metastore must refactor rewards to have a more uniform def

	local reward_def = progress_instance:GetPendingRewardDef()
	local rewards = reward_def.rewards
		and reward_def.rewards
		or { reward_def }

	local power_ids = {}
	local materials = {}

	local poptext_x_offset = -15
	local poptext_y_offset = 0

	local function MakePopText(str, color, size, fade_time)
		size = size or 75
		fade_time = fade_time or 5
		TheDungeon.HUD:MakePopText({
			target = player,
			button = str,
			color = color,
			size = 75,
			fade_time = 5,
			x_offset = poptext_x_offset,
			y_offset = 125 + poptext_y_offset,
		})
		poptext_x_offset = poptext_x_offset * -1
		poptext_y_offset = poptext_y_offset + 75
	end

	local constructable_rewards = {}
	local title_rewards = {}
	for i,reward in ipairs(rewards) do
		reward:UnlockRewardForPlayer(player, false)

		--TODO #metastore support more types, be less explicit
		if reward.def.slot == Power.Slots.PLAYER then
			if reward.def.can_drop then -- Only drop powers here if we've set them to be droppable. Otherwise, just unlock them and later if we set them to be droppable they'll start appearing.
				table.insert(power_ids, reward.def.name)
			end
		elseif Constructable.IsSlot(reward.def.slot) then
			-- TODO #metastore if we can actually drop the thing, then drop it. Until now, use this.
			local str = string.format("+ <p img='%s' scale=1.2> %s", reward.def.icon, reward.def.pretty.name)
			table.insert(constructable_rewards, str)
			--MakePopText(str, UICOLORS.GOLD_CLICKABLE)
		elseif reward.def.slot == Cosmetic.Slots.PLAYER_TITLE then
			local str = string.format(STRINGS.UI.MASTERYSCREEN.UNLOCK_NEW_TITLE,
									STRINGS.COSMETICS.TITLES[string.upper(reward.def.title_key)])
			table.insert(title_rewards, str)
		elseif reward.def.name == "konjur_soul_lesser" then
			for x=1,reward.count do
				table.insert(materials, "corestone_pickup_single")
			end
		end
	end

	local animation = Updater.Series()
	for i, reward in ipairs(constructable_rewards) do
		animation:Add(Updater.Do(function() 
			MakePopText(reward, UICOLORS.GOLD_CLICKABLE)
		end))

		if i < #constructable_rewards or #title_rewards > 0 then
			animation:Add(Updater.Wait(30 * TICKS))
		else
			animation:Add(Updater.Wait(20* TICKS)) -- It feels nicer if the last beat before the loot is a bit shorter
		end
	end

	for i, title in ipairs(title_rewards) do
		animation:Add(Updater.Do(function() 
			MakePopText(title, UICOLORS.BLUE, 85, 8)
		end))

		if i < #title_rewards then
			animation:Add(Updater.Wait(30 * TICKS))
		else
			animation:Add(Updater.Wait(20* TICKS))
		end
	end

	animation:Add(Updater.Do(function() 
		if not TheWorld:HasTag('town') then
			LootEvents.SpawnRandomLootForCurrentLocation(inst, { player }, 5)
			player.components.lootvacuum:Enable()
		end
	end))

	TheDungeon.HUD:RunUpdater(animation)

	if #power_ids > 0 then
		TheWorld.components.powerdropmanager:SpawnSpecificPowerItemsForPlayer(power_ids, player, inst:GetPosition())
	end

	if #materials > 0 then
		MetaProgressStore.SpawnCircleOfPrefabs(inst, player, materials)
	end
	progress_instance:OnPendingLevelClaimed()
	MetaProgressStore.UpdateStatus(inst, player, args)
end

function MetaProgressStore.PropEdit(prop_editor, ui, prop_params)
	local id = "##MetaProgressStore:PropEdit"

	-- Dany wants to add sound to all buildings.
	prop_params.sound = true

	ui:Indent()
	local args = prop_params.script_args or {}

	args.currency = ui:_ComboAsString(
		"Currency"..id,
		args.currency or DEFAULTS.currency,
		CurrencyType:Ordered()
	)
	args.purchase_type = ui:_ComboAsString(
		"Purchase Type" .. id,
		args.purchase_type or DEFAULTS.purchase_type,
		PurchaseType:Ordered()
	)
	if args.purchase_type == PurchaseType.s.XPPerCurrency then
		args.currency_per_deposit = ui:_DragInt(
			"Currency per deposit" .. id,
			args.currency_per_deposit or DEFAULTS.currency_per_deposit,
			1,
			1,
			100
		)
		args.xp_per_currency = ui:_DragInt(
			"XP per currency" .. id,
			args.xp_per_currency or DEFAULTS.xp_per_currency,
			1,
			1,
			100
		)
	end
	args.meta_progress = ui:_ComboAsString(
		"Meta Progress"..id,
		args.meta_progress or DEFAULTS.meta_progress,
		Lume(MetaProgress.Slots):keys():sort():result()
	)
	ui:Indent()
		if args.meta_progress == MetaProgress.Slots.MONSTER_RESEARCH then
			args.monster = ui:_ComboAsString(
				"Monster"..id,
				args.monster or DEFAULTS.monster,
				Lume(MetaProgress.Items[MetaProgress.Slots.MONSTER_RESEARCH]):keys():sort():result()
			)
		end

		if args.meta_progress == MetaProgress.Slots.RELATIONSHIP_CORE then
			args.npc = ui:_ComboAsString(
				"Npc"..id,
				args.npc or DEFAULTS.npc,
				Lume(MetaProgress.Items[MetaProgress.Slots.RELATIONSHIP_CORE]):keys():sort():result()
			)
		end

		if args.meta_progress == MetaProgress.Slots.WEAPON_UNLOCKS then
			args.weapon = ui:_ComboAsString(
				"Weapon"..id,
				args.weapon or DEFAULTS.weapon,
				Lume(MetaProgress.Items[MetaProgress.Slots.WEAPON_UNLOCKS]):keys():sort():result()
			)
		end
	ui:Unindent()
	args.interact_radius = ui:_DragFloat(
		"Interact Radius"..id,
		args.interact_radius or DEFAULTS.interact_radius,
		0.01,
		0.5,
		10.0
	)
	args.status_widget_location = ui:_ComboAsString(
		"Status Widget Location" .. id,
		args.status_widget_location or DEFAULTS.status_widget_location,
		StatusWidgetLocation:Ordered()
	)

	prop_params.script_args = args
	ui:Unindent()
end

function MetaProgressStore.LivePropEdit(editor, ui, params, defaults)
	local id = "##MetaProgressStore.LivePropEdit"
	ui:Indent()
	params.script_args.player_binding = ui:_ComboAsString(
		"Player Binding" .. id,
		params.script_args.player_binding
			or defaults.player_binding
			or DEFAULTS.player_binding,
		PlayerBinding:Ordered()
	)
	ui:Unindent()
end

function MetaProgressStore.Apply(inst, script_args)
	if TheWorld ~= nil and TheDungeon:GetDungeonMap():IsDebugMap() then
		return
	end

	if script_args.player_binding == PlayerBinding.s.None then
		return
	end

	local player_count = TheNet:GetNrPlayersOnRoomChange()
	local player_number = PlayerBinding.id[script_args.player_binding] - 1
	local enabled = player_number <= player_count
	if not enabled then
		inst:RemoveComponent("interactable")
		inst:RemoveComponent("townhighlighter")
		inst:PushEvent("corestone_converter_deactivate")
		return
	end
end

return MetaProgressStore
