local lume = require "util.lume"
local spawnutil = require "util.spawnutil"
local Power = require "defs.powers"
local PrefabEditorBase = require "debug.inspectors.prefabeditorbase"
local DebugDraw = require "util.debugdraw"

---------------------------------------------------------------------------------------
--Custom script for auto-generated prop prefabs
---------------------------------------------------------------------------------------

-- Traps are just props. They call into here to add trap behaviour to their
-- existing setup. Currently, we want them to have mostly the same setup.
local trap = {
	default = {},
	trap_weed_thorns = {},
	trap_cold = {},
	trap_torch = {},
}

function trap.default.CollectPrefabs(prefabs, args)
	table.insert(prefabs, "fx_hit_player_round")
	if args.trap_type == "trap_spores" then
		local v = TUNING.TRAPS.trap_spores.VARIETIES[args.prefab]
		if v then
			table.insert(prefabs, v.burst_fx)
			table.insert(prefabs, v.target_fx)
		end
	end
end


function trap.GetTrapTypes()
	-- These must match the stategraph names.
	return {
		"trap_spike",
		"trap_exploding",
		"trap_zucco",
		"trap_bananapeel",
		"trap_spores",
		"trap_acid",
		"trap_acid_stage",
		"trap_acidgeyser",
		"trap_stalactite",
		"trap_windtotem",
		"trap_thorns",
		"trap_cold",
		"trap_torch",
	}
end

function trap.GetSporeTypes()
	return {
		"juggernaut",
		"smallify",
		"shield",
		"confused",
		"heal",
		"damage",
		"groak",
	}
end

function trap.GetDirections()
	return {
		"Right",
		"Up",
		"Left",
		"Down",
	}
end

function trap.default.CustomInit(inst, opts)
	local is_gameplay = not TheDungeon:GetDungeonMap():IsDebugMap()

	inst:AddTag("trap")

	-- Load prefab dependencies
	if opts.prefabs then
		local prefabs_to_load = {}
		for _, prefab in ipairs(opts.prefabs) do
			table.insert(prefabs_to_load, prefab)
		end
		TheSim:LoadPrefabs(prefabs_to_load)
	end
	
	-- TODO @chrisp #traps - pass opts.trap_type for more specific tuning
	local modifiers = TUNING:GetTrapModifiers()
	-- TODO @chrisp #traps - apply modifiers to more trap aspects (e.g. cooldown)?

	inst.entity:AddHitBox()
	inst:AddComponent("hitbox")
	if is_gameplay then
		inst.components.hitbox:SetHitGroup(HitGroup.NEUTRAL)
		inst.components.hitbox:SetHitFlags(HitGroup.CHARACTERS | HitGroup.CREATURES)
	end

	inst:AddComponent("dormantduringpeace")

	inst.entity:AddSoundEmitter()

	inst:AddComponent("combat")
	inst.components.combat:SetBaseDamage(inst, TUNING.TRAPS[opts.trap_type].BASE_DAMAGE)
	inst.components.combat:SetDungeonTierDamageMult(inst, modifiers.DungeonTierDamageMult)
	inst:AddComponent("hitstopper")

	inst:AddComponent("hitshudder")

	if TUNING.TRAPS[opts.trap_type].COLLISION_DATA ~= nil then
		MakeTrapPhysics(inst,
			TUNING.TRAPS[opts.trap_type].COLLISION_DATA.SIZE,
			TUNING.TRAPS[opts.trap_type].COLLISION_DATA.MASS,
			TUNING.TRAPS[opts.trap_type].COLLISION_DATA.COLLISIONGROUP,
			TUNING.TRAPS[opts.trap_type].COLLISION_DATA.COLLIDESWITH)
	end

	if TUNING.TRAPS[opts.trap_type].HEALTH ~= nil then
		inst:AddComponent("health")
		inst.components.health:SetMax(TUNING.TRAPS[opts.trap_type].HEALTH, true)
		-- TODO @chrisp #traps - could scale trap health in the same way we scale enemy health
		-- inst.components.health:SetMax(TUNING.TRAPS[opts.trap_type].HEALTH * (modifiers.HealthMult + modifiers.BasicHealthMult), true)
		inst.components.health:SetHealable(false)
	end

	if TUNING.TRAPS[opts.trap_type].JOINTAOE then
		local data = {
			name = opts.trap_type,
		}
		inst.jointaoechild = spawnutil.SetupAoECommon(data)
	end
	if TUNING.TRAPS[opts.trap_type].AURA_APPLYER then
		inst:AddComponent("auraapplyer")
		inst:AddComponent("powermanager")
		inst.components.powermanager:EnsureRequiredComponents()

		-- Set up aura power effect, hitbox
		local aura_data = TUNING.TRAPS[opts.trap_type].AURA_DATA
		if aura_data then
			inst.components.auraapplyer:SetEffect(aura_data.effect)
			if aura_data.beamhitbox then
				inst.components.auraapplyer:SetupBeamHitbox(table.unpack(aura_data.beamhitbox))
			else
				inst.components.auraapplyer:SetRadius(table.unpack(aura_data.radius))
			end
		end
	end

	if opts.spore_type then
		-- This is a spore trap. Get the correct information from the tuning table and init those things.
		local spore_type = "trap_spores_"..opts.spore_type
		inst.sporedata = TUNING.TRAPS.trap_spores.VARIETIES[spore_type]
		inst:AddTag("spore")
	elseif opts.shoot_spikeballs then
		inst.shoot_spikeballs = true
	end

	if (opts.trap_type == "trap_zucco") then
		inst:AddTag("zuccobomb")
	elseif (opts.trap_type == "trap_acid") then
		inst:AddTag("dbg_nohistory") -- Add this tag to disable history on this object, for debug performance reasons.
	end

	inst:SetStateGraph("sg_".. opts.trap_type)
end

function trap.PropEdit(editor, ui, params)
	local all_traps = trap.GetTrapTypes()
	local no_trap = 1
	table.insert(all_traps, no_trap, "")

	--~ dumptable(params.script_args)

	local is_trap = params.script == "trap"
	local idx = lume.find(all_traps, is_trap and params.script_args and params.script_args.trap_type)
	local changed
	changed, idx = ui:Combo("Trap Type", idx or no_trap, all_traps)
	if changed then
		if idx == no_trap then
			params.script = nil
			params.script_args = nil
		else
			params.script = "trap"
			params.script_args = {
				trap_type = all_traps[idx],
			}
		end
		editor:SetDirty()
	end
	if is_trap then
		local tier
		changed, tier = ui:DragInt("Tier", params.script_args and params.script_args.tier or 1, 1, 1, 5)
		if changed then
			params.script_args.tier = tier
		end

		if ui:TreeNode("Prefab Dependencies") then
			params.script_args.prefabs = params.script_args.prefabs or {}

			for i = 1, #params.script_args.prefabs do
				if ui:Button(ui.icon.remove .."##"..i, nil, nil, i == 1 and #params.script_args.prefabs == 0) then
					-- delete this line
					table.remove(params.script_args.prefabs, i)
				end

				ui:SameLineWithSpace(3)

				local oldprefab = params.script_args.prefabs[i] or ""
				local prefab = PrefabEditorBase.PrefabPicker(ui, "Prefab##"..i, oldprefab)
				if prefab ~= oldprefab then
					params.script_args.prefabs[i] = prefab
				end
			end
			if ui:Button(ui.icon.add .."##addprefab") then
				-- insert another line after this one
				table.insert(params.script_args.prefabs, "")
			end
			ui:TreePop()
		end

		if params.script_args.trap_type == "trap_spores" then
			local all_spores = trap.GetSporeTypes()

			local spore_idx = lume.find(all_spores, params.script_args.spore_type)
			local spore_changed
			spore_changed, spore_idx = ui:Combo("Spore Type", spore_idx or 1, all_spores)
			if spore_changed then
				params.script_args.spore_type = all_spores[spore_idx]
			end
		elseif params.script_args.trap_type == "trap_windtotem" then
			local shoot_spikeballs_changed, shoot_spikeballs = ui:Checkbox("Shoots Spikeballs", params.script_args.shoot_spikeballs)
			if shoot_spikeballs_changed then
				params.script_args.shoot_spikeballs = shoot_spikeballs
			end
		end

		ui:Separator()

		if params.parallax then
			if params.parallax_use_baseanim_for_idle then
				editor:WarningMsg(ui,
					"!!! Warning !!!",
					"Traps using parallax should be setup with idle animations. Each parallax item should have a name used as a suffix to their animations. So you might have 'spike1', 'spike2' in the parallax list and 'idle_spike1', 'idle_spike2' in the flash file.")
			end
			if editor.main_layer_count == 0 then
				editor:WarningMsg(ui,
					"!!! Warning !!!",
					"Traps using parallax need one parallax layer at dist 0 so it can act as the main anim that drives the stategraph. Otherwise we never receive animover and animations loop infinitely.")
			end
		end
	end
end

---------------------------------------------------------------------
-- Code for handling trap spawner trap data
---------------------------------------------------------------------
function trap.InitSpawner(inst)
	inst.trap_types = {}
	inst.trap_directions = {}
	inst.components.prop.script_args = {}

	-- TODO: This should use LivePropEdit and Apply in this customscript
	-- instead of setting EditEditable and LoadScriptArgs.
	inst.EditEditable = trap.EditEditable -- Assign this for handling editable UI for this
	inst.LoadScriptArgs = trap.LoadScriptArgs; -- Assign this to handle loading of prop data from file
end

function trap.LoadScriptArgs(inst, data)
	if (not data.trap_types) then
		return
	end

	for _, trap_type in ipairs(data.trap_types) do
		inst.trap_types[trap_type] = true
	end

	for i, direction in ipairs(data.trap_directions or {}) do
		inst.trap_directions[direction] = true
	end
end

-- Editor UI for trap spawners.
function trap.EditEditable(inst, ui)
	ui:Separator()
	ui:Text("Spawnable Trap Types:")
	for _, trap_type in ipairs(trap.GetTrapTypes()) do
		local changed = false
		changed, inst.trap_types[trap_type] = ui:Checkbox(trap_type, inst.trap_types[trap_type])
		if changed then
			-- Need to convert trap types lookup table into an indexed table for save data
			local data = inst.components.prop.script_args
			data.trap_types = {}

			for _, trap_type in ipairs(trap.GetTrapTypes()) do
				if inst.trap_types[trap_type] then
					table.insert(data.trap_types, trap_type)
				end
			end

			inst.components.prop:OnPropChanged()
		end
	end

	ui:Separator()

	ui:Text("Facing Directions:")
	if ui:IsItemHovered() then
		ui:SetTooltip("Used to spawn certain traps facing in a certain direction, e.g. wind traps.")
	end
	ui:SameLineWithSpace()
	for i, direction in ipairs(trap.GetDirections()) do
		local direction_changed = false
		direction_changed, inst.trap_directions[i - 1] = ui:Checkbox(direction, inst.trap_directions[i - 1])
		if direction_changed then
			local data = inst.components.prop.script_args
			data.trap_directions = {}

			for j, _ in ipairs(trap.GetDirections()) do
				if inst.trap_directions[j - 1] then
					table.insert(data.trap_directions, j - 1) -- -1 due to directions being 0-based.
				end
			end

			inst.components.prop:OnPropChanged()
		end

		if i < #trap.GetDirections() then
			ui:SameLineWithSpace()
		end
	end
end




for key,val in pairs(trap.default) do
	-- Use same base setup as default.
	trap.trap_weed_thorns[key] = val
end

-- Thorn Traps

local function trap_weed_thorns_OnRoomComplete(inst)
	inst.sg.mem.is_room_clear = true
	inst.sg:GoToState("retract")
end

function trap.trap_weed_thorns.CustomInit(inst, opts)
	trap.default.CustomInit(inst, opts)

	-- Since thorns have a hitbox, prevent them from being teleported
	inst:AddTag("no_teleport")

	inst.HitBox:SetHitGroup(HitGroup.NEUTRAL)
	inst.HitBox:SetHitFlags(HitGroup.PLAYER | HitGroup.NPC | HitGroup.HOSTILES)

	inst:ListenForEvent("room_complete", function() trap_weed_thorns_OnRoomComplete(inst) end, TheWorld)

	return inst
end

-- Cold Traps

function ApplyCold()
	local cold = Power.FindPowerByName("cold")
	local frozen = Power.FindPowerByName("frozen")

	for _, player in ipairs(AllPlayers) do
		if (player:IsLocal()) then
			if (not player.components.powermanager:HasPower(frozen) and not player.components.powermanager:HasPower(cold)) then
				local power = player.components.powermanager:CreatePower(cold)
				player.components.powermanager:AddPower(power, nil)
			elseif (not player.components.powermanager:HasPower(frozen) and player.components.powermanager:HasPower(cold)) then
				player.components.powermanager:DeltaPowerStacks(cold, 5)
			end
		end
	end
end

function trap.trap_cold.CustomInit(inst, opts)
	-- The cold power maxes at 600 stacks, the cold trap adds X stacks every 100ms
	inst:DoPeriodicTask(0.1, ApplyCold)

	-- Remove cold and frozen from players when leaving the room so they dont carry it over to rooms without cold traps
	inst:ListenForEvent("onremove", function(trap_inst)
		local cold = Power.FindPowerByName("cold")
		local frozen = Power.FindPowerByName("frozen")
		for _, player in ipairs(AllPlayers) do
			if (player:IsLocal()) then
				if (player.components.powermanager:HasPower(cold)) then
					player.components.powermanager:RemovePower(cold, true)
				end
				if (player.components.powermanager:HasPower(frozen)) then
					player.components.powermanager:RemovePower(frozen, true)
				end
			end
		end
	end)

	return inst
end

-- Tundra Torch

function ReduceCold(inst)
	local cold = Power.FindPowerByName("cold")
	local frozen = Power.FindPowerByName("frozen")
	local inst_pos = Vector3(inst:GetPosition())
	local range = 10
	DebugDraw.GroundCircle(inst_pos.x, inst_pos.z, range, WEBCOLORS.ORANGERED, 0.1, 0.1)

	for _, player in ipairs(AllPlayers) do
		if (player:IsLocal()) then
			local player_pos = Vector3(player:GetPosition())
			local dist = Vector3.dist(inst_pos, player_pos)
			if (dist < range and not player.components.powermanager:HasPower(frozen) and player.components.powermanager:HasPower(cold)) then
				player.components.powermanager:DeltaPowerStacks(cold, -20)
			end
		end
	end
end

function trap.trap_torch.CustomInit(inst, opts)
	inst.entity:AddHitBox()
	inst.entity:AddSoundEmitter()
	inst:AddComponent("combat")
	inst:AddComponent("hitshudder")
	MakeObstaclePhysics(inst, 1.5)

	inst:DoPeriodicTask(0.1, ReduceCold, 0.05)

	--inst:SetStateGraph("sg_torch_trap")
	return inst
end

return trap
