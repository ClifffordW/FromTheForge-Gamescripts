--------------------------------------------------------------------------
--This prefab file is for loading autogenerated Prop prefabs
--------------------------------------------------------------------------
local Constructable = require "defs.constructable"
local Placers = require "prefabs.placers"
local PropAutogenData = require "prefabs.prop_autogen_data"
local prefabutil = require "prefabs.prefabutil"
local SGCommon = require("stategraphs.sg_common")
local SceneGen = require "components.scenegen"
local Hsb = require "util.hsb"
local Placer = require "components.placer"
require "physics"


local function CreateLayer()
	local inst = CreateEntity()

	inst.entity:AddTransform()
	inst.entity:AddAnimState()

	inst:AddTag("FX")
	inst.persists = false

	inst:AddComponent("bloomer")
	inst:AddComponent("colormultiplier")
	inst:AddComponent("coloradder")

	return inst
end

local function ParseFxTargets(targets)
	local symbols, layers
	if targets ~= nil then
		for i,v in ipairs(targets) do
			if v.name then
				if v.type == "Symbol" then
					symbols = symbols or {}
					symbols[v.name] = true
				elseif v.type == "Layer" then
					layers = layers or {}
					layers[v.name] = true
				end
			end
		end
	end
	return symbols, layers
end

local function ApplyParams(inst, params, layerparams)
	if params.hidemouseover then
		inst.AnimState:HideLayer("MOUSEOVER")
	end

	if params.onground then
		inst.AnimState:SetOrientation(ANIM_ORIENTATION.OnGround)
		-- onground is never colorized under water
		inst.AnimState:SetColorizeUnderWater(false)
	end

	if params.layer ~= nil then
		if params.layer == "backdrop" then
			inst.AnimState:SetLayer(LAYER_BACKDROP)
		elseif params.layer == "bg" then
			inst.AnimState:SetLayer(LAYER_BACKGROUND)
		elseif params.layer == "auto" then
			if layerparams then
				if not layerparams.autosortlayer then	-- is both above and below, so add cutoffs to both sides
					if layerparams.underground then
						inst.AnimState:SetLayer(LAYER_BELOW_GROUND)
						inst.AnimState:SetIsBGElement(true)
						inst.AnimState:SetIsFGElement(false)
						inst.AnimState:SetSortOrder(0)
					else
						inst.AnimState:SetLayer(LAYER_WORLD)
						inst.AnimState:SetIsBGElement(false)
						inst.AnimState:SetIsFGElement(true)
						inst.AnimState:SetSortOrder(0)
					end
				 elseif layerparams.autosortlayer == "below" then
					inst.AnimState:SetLayer(LAYER_BELOW_GROUND)
					inst.AnimState:SetIsBGElement(true)
					inst.AnimState:SetIsFGElement(false)
					inst.AnimState:SetSortOrder(0)
				 else	-- must be above, no cutoff so we can have shaped edges on groundplane
					inst.AnimState:SetLayer(LAYER_WORLD)
					inst.AnimState:SetIsBGElement(false)
					inst.AnimState:SetIsFGElement(false)
					inst.AnimState:SetSortOrder(0)
				 end
			end
		end
	end

	if params.sortorder ~= nil then
		inst.AnimState:SetSortOrder(params.sortorder)
	end

	if params.silhouette ~= nil then
		inst.AnimState:SetSilhouetteMode(SilhouetteMode.Show)
	end

	Hsb.FromRawTable(params):Set(inst)

	if params.lightoverride ~= nil then
		local symbols, layers = ParseFxTargets(params.lighttargets)
		local lightoverride = params.lightoverride / 100
		if symbols == nil and layers == nil then
			inst.AnimState:SetLightOverride(lightoverride)
		else
			if symbols ~= nil then
				for symbol in pairs(symbols) do
					inst.AnimState:SetSymbolLightOverride(symbol, lightoverride)
				end
			end
			if layers ~= nil then
				for layer in pairs(layers) do
					inst.AnimState:SetLayerLightOverride(layer, lightoverride)
				end
			end
		end
	end

	if params.fade then
		inst.AnimState:SetFadeValues(params.fade.bottom, params.fade.top)
	end

	if layerparams then
		if layerparams.onground then
			inst.AnimState:SetOrientation(ANIM_ORIENTATION.OnGround)
			-- Don't allow child to be closer than background layer.
			inst.AnimState:SetSortOrder(math.min(params.sortorder or 0, -2))
			-- onground is never colorized under water
			inst.AnimState:SetColorizeUnderWater(false)
		end
	end
end

-- Whatever we can apply without crashing.
local function ApplyPropParams_Safe(inst, params)
	if inst.AnimState then
		ApplyParams(inst, params)
	end
	if inst.highlightchildren and params.parallax then
		-- layerparams also has the parent object, we need to skip that one while iterating the parallax
		local childindex = 1
		for i=1,#params.parallax do
			local layerparams = params.parallax[i]
			if layerparams.anim ~= nil then
				local child = inst.highlightchildren[childindex]
				if layerparams.dist == 0 or layerparams.dist == nil then
					-- this is the parent object
				elseif child then
					ApplyParams(child, params, layerparams)
					childindex = childindex + 1
				else
					-- Can't prevent the user from changing which is the main
					-- ent live because all layers start with dist 0. Fail with
					-- warning and we'll also show a warning in editor if they
					-- have no zero prop. Alternatively, we could force
					-- respawn, but that seems more likely to cause additional
					-- errors.
					TheLog.ch.Editor:printf("WARNING: Cannot apply child params to former root object. Please respawn to apply.")
				end
			end
		end
	end

	if params.multcolor ~= nil then
		inst.components.colormultiplier:PushColor("prop_autogen", HexToRGBFloats(StrToHex(params.multcolor)))
	end

	if params.addcolor ~= nil then
		inst.components.coloradder:PushColor("prop_autogen", HexToRGBFloats(StrToHex(params.addcolor)))
	end

	if params.bloom ~= nil then
		local symbols, layers = ParseFxTargets(params.bloomtargets)
		local target = nil
		if symbols or layers then
			target = {
				symbols = symbols,
				layers = layers,
			}
		end
		-- Ensure no bloom is set since we're changing targets.
		inst.components.bloomer:PopBloom("prop_autogen")
		inst.components.bloomer:ChangeTarget(target)

		local intensity = params.bloom / 100
		if params.glowcolor ~= nil then
			local r, g, b = HexToRGBFloats(StrToHex(params.glowcolor))
			inst.components.bloomer:PushBloom("prop_autogen", r, g, b, intensity)
		else
			inst.components.bloomer:PushBloom("prop_autogen", intensity)
		end
	end
end

local function GotoSpawnFromEditorState(inst)
	if inst.sg:HasState("spawn_from_editor") then
		inst.sg:GoToState("spawn_from_editor")
	else
		-- Setup this state in your sg so your prop works in Embellisher and PropEditor.
		TheLog.ch.Editor:print("Add spawn_from_editor sg state for extra setup to allow prop to spawn from tools. (For StateGraph Name Override.)", inst)
	end
end

local function GetParallaxLayer(inst, index)
	assert(index)
	local root_index = inst.root_parallax_index or 1
	if index == root_index then
		return inst
	end
	if index > root_index then
		index = index - 1
	end
	if inst.highlightchildren then
		return inst.highlightchildren[index]
	end
end

function MakeAutogenProp(name, params, debug)
	local assets =
	{
		Asset("PKGREF", "scripts/prefabs/autogen/prop/".. name ..".lua"),
		Asset("PKGREF", "scripts/prefabs/prop_autogen.lua"),
		Asset("PKGREF", "scripts/prefabs/prop_autogen_data.lua"),
		Asset("PKGREF", "scripts/prefabs/placers.lua"),
	}
	local prefabs = {}

	local build = params.build or name
	local bank = params.bank or name

	prefabutil.CollectAssetsForAnim(assets, build, bank, params.bankfile, debug)
	prefabutil.CollectAssetsAndPrefabsForScript(assets, prefabs, name, params.script, params.script_args, debug)

	if params.childprefab then
		table.insert(prefabs, params.childprefab)
	end

	local networktype = NetworkType_None

	if params.networked then
		-- If the network type is manually assigned, use that instead of the group setting
		if params.networked == 1 then	-- On
			networktype = NetworkTypeFlags_Enabled

			if params.isminimal then
				networktype = NetworkType_ClientMinimal
			end
			if params.hostspawn then
				networktype = networktype + NetworkTypeFlags_SpawnHostOnly
			end
			if not params.isminimal and params.transferable then
				networktype = networktype + NetworkTypeFlags_Transferable
			end
		end -- else it will just be networked OFF, meaning NetworkType_None
	else
		-- Auto-assign the network type based on the script assigned to the prefab
		if params.script == "prop_destructible" then
			networktype = NetworkType_SharedHostSpawn
		elseif params.script == "trap" then
			networktype = NetworkType_HostAuth
		elseif params.script == "buildings" then
			networktype = NetworkType_Minimal
		elseif params.script == "powerdrops" and params.script_args.power_type == "FABLED_RELIC" then
			-- networking2022: hack to get fabled relic to be network entities because
			-- the default for the "visible" power drops is not to be a network entity
			-- since the main relic power drop is already networked
			networktype = NetworkType_HostAuth
			params.animhistory = true
		elseif params.script == "dummies" then
			networktype = NetworkType_Minimal
		end
	end

	local function fn(prefabname)

		local inst_params = deepcopy(params)
		-- Apply prop instance params
		if inst_params.script_args then
			for i,v in pairs(params.script_args) do
				inst_params[i] = v
			end
		end

		local inst = CreateEntity()
		inst:SetPrefabName(prefabname)

		-- Anim history is costly wrt performance. Unless the prop is "complex", as deduced from whether or not it has
		-- an attached script as indicated by the presence of script_args, suppress anim history.
		local grid_prop = not params.proptype or params.proptype == PropType.Grid
		local complex_prop = params.script ~= nil
		local physics_prop = params.physicstype and params.physicstype ~= "None"
		if not (grid_prop and complex_prop) and not physics_prop
		then
			inst:AddTag("dbg_nohistory")
		end

		inst.sgname_override = inst_params.stategraph_override

		inst.entity:AddTransform()

		if inst_params.nonpersist then
			inst.persists = false
		end

		if inst_params.sound then
			inst.entity:AddSoundEmitter()
		end

		--See if we need AnimState first
		if inst_params.parallax ~= nil then
			for i = 1, #inst_params.parallax do
				local layerparams = inst_params.parallax[i]
				if layerparams.anim ~= nil and (layerparams.dist == nil or layerparams.dist == 0) then
					inst.entity:AddAnimState()
					break
				end
			end
		end

		if not inst_params.clickable then
			inst:AddTag("NOCLICK")
		end

		if inst_params.ignore_placer then
			inst:AddTag("ignore_placer")
		end

		if inst_params.physicssize ~= nil
			and inst_params.physicssize > 0
			and params.proptype ~= PropType.Decor
		then
			if inst_params.physicstype == "obs" then
				MakeObstaclePhysics(inst, inst_params.physicssize)
			elseif inst_params.physicstype == "vert_obs" then
				MakeVerticalObstaclePhysics(inst, inst_params.physicssize)
			elseif inst_params.physicstype == "smobs" then
				MakeSmallObstaclePhysics(inst, inst_params.physicssize)
			elseif inst_params.physicstype == "dec" then
				MakeDecorPhysics(inst, inst_params.physicssize)
			elseif inst_params.physicstype == "smdec" then
				MakeSmallDecorPhysics(inst, inst_params.physicssize)
			elseif inst_params.physicstype == "holeblock" then
				MakeHolePhysics(inst, inst_params.physicssize)
			end
		end

		inst:AddComponent("bloomer")
		inst:AddComponent("colormultiplier")
		inst:AddComponent("coloradder")

		local def = Constructable.FindItem(inst.prefab)

		if def ~= nil and (def.slot == Constructable.Slots.DECOR or def.slot == Constructable.Slots.STRUCTURES) then

			inst._onstartpropremover = function()
				if inst.components.colormultiplier then
					inst.components.colormultiplier:PushColor("remover", table.unpack(UICOLORS.GREEN))
					inst.components.snaptogrid:SetDrawGridEnabled(true)
				end
			end
			inst:ListenForEvent("start_prop_remover", inst._onstartpropremover, TheWorld)

			inst._onstoppropremover = function()
				if inst.components.colormultiplier then
					inst.components.colormultiplier:PopColor("remover")
					inst.components.snaptogrid:SetDrawGridEnabled(false)
				end
			end
			inst:ListenForEvent("stop_prop_remover", inst._onstoppropremover, TheWorld)

			inst:ListenForEvent("onremove", function() 
				inst:RemoveEventCallback("start_prop_remover", inst._onstartpropremover, TheWorld)
				inst:RemoveEventCallback("stop_prop_remover", inst._onstoppropremover, TheWorld)
			end)
			
			inst:AddComponent("snaptogrid_init")

			inst:AddTag(Placer.DECOR_TAG)
		end

		if params.placer then
			inst:AddComponent("interactable")

			if def == nil then
				printf("WARNING: %s DOES NOT HAVE A PLACEABLE PROP ITEM!", inst.prefab)
			end

			inst.components.interactable:SetInteractConditionFn(function(_, player)
				local interact = player.components.playercontroller:IsBuilding() and not inst.components.npchome
				return interact
			end)
			inst.components.interactable:SetOnInteractFn(function(_, player)
				if def then
					player.components.inventoryhoard:AddStackable( def, 1 )
					inst:Remove()
				end
			end)

			inst.components.interactable
				:SetRadius(3)
				:SetupTargetIndicator("interact_pointer")
				:SetInteractStateName("pickup")
				:SetAbortStateName("idle")
		end

		if inst_params.parallax ~= nil then
			inst.GetParallaxLayer = GetParallaxLayer

			local dungeon_progress = TheDungeon:GetDungeonMap().nav:GetProgressThroughDungeon()
			local progress_per_type = {
				-- Two values, both in [0,1]:
				-- * Minimum progress for boss variant (hard cutoff to ensure lots of normal forest).
				-- * Progress after we guarantee boss variant.
				[PropType.Grid]  = { 0.30, 0.8, },
				[PropType.Decor] = { 0.20, 0.8, },
			}
			local minmax_progress = progress_per_type[inst_params.proptype] or progress_per_type[PropType.Grid]
			local use_boss_variant = (inst_params.bossvariant
				and dungeon_progress >= TheWorld.prop_rng:Float(table.unpack(minmax_progress))) -- @chrisp #proc_rng

			-- When autosorting I generate entities at spawn time, I don't want these to be stored in the data
			-- so backup original layerdata
			local layerbackup
			if inst_params.layer == "auto" then
				local layers = #inst_params.parallax
				local index = layers + 1
				for i = 1, layers do
					local layerparams = inst_params.parallax[i]
					if not layerparams.autosortlayer then	-- is both above and below, so make one copy below and make original above
						layerbackup = layerbackup or deepcopy(inst_params.parallax)
						inst_params.parallax[index] = {
										anim = layerparams.anim,
										dist = (layerparams.dist or 0) + 0.0001,
										xoffset = layerparams.xoffset,
										yoffset = layerparams.yoffset,
										cutoff = true,
										underground = true,
										dependent_child = true,	-- Mark it as a dependent_child, meaning it will copy the animation from the parent on remote machines. 
									}
						index = index + 1
					end
				end
			end

			for i = 1, #inst_params.parallax do
				local layerparams = inst_params.parallax[i]
				if layerparams.anim ~= nil then
					local ent
					if layerparams.dist == nil or layerparams.dist == 0 then
						if inst.baseanim == nil then
							ent = inst
							inst.root_parallax_index = i
						end
					else
						ent = CreateLayer()
						ent.entity:SetParent(inst.entity)
						ent.Transform:SetPosition(
							layerparams.xoffset or 0,
							layerparams.yoffset or 0,
							layerparams.dist)

						if not inst_params.clickable then
							ent:AddTag("NOCLICK")
						end

						if inst_params.on_water	then
							ent.AnimState:SetOnWater(true)
							ent.AnimState:SetColorizeUnderWater(not inst_params.water_colorize == false)
							inst.AnimState:SetLayer(LAYER_BELOW_GROUND)
						end

						--TODO: create a symbolskinner component based on value stacker and add it here and in buildingskinner
						inst.components.bloomer:AttachChild(ent)
						inst.components.colormultiplier:AttachChild(ent)
						inst.components.coloradder:AttachChild(ent)
						
						ent.dependent_child = layerparams.dependent_child
 
						if inst.highlightchildren == nil then
							inst.highlightchildren = { ent }
						else
							inst.highlightchildren[#inst.highlightchildren + 1] = ent
						end
					end

					if ent ~= nil then
						ent.AnimState:SetBank(bank)
						ent.AnimState:SetBuild(build)
						ent.baseanim = layerparams.anim
						if use_boss_variant then
							ent.baseanim = "boss_".. ent.baseanim
						end
						-- Legacy anim setup. baseanim should be the anim
						-- suffix, but we have legacy data that used the suffix
						-- as the idle name.
						ent.use_baseanim_for_idle = inst_params.parallax_use_baseanim_for_idle

						if layerparams.shadow then
							ent.AnimState:SetShadowEnabled(true)
						end

						if inst_params.script == "trap" and grid_prop and ent.AnimState then
							ent.AnimState:SetSilhouetteColor(0/255, 0/255, 0/255, 0.1)
							ent.AnimState:SetSilhouetteMode(SilhouetteMode.Have)
						end

						if layerparams.flip then
							ent.AnimState:SetScale(-1, 1)
						end
						ApplyParams(ent, inst_params, layerparams)
					end
				end
			end
			if layerbackup then
				inst_params.parallax = deepcopy(layerbackup)
			end
		end


		-- If there are highlightchildren, make sure that all layers are updated when the animation changes
		-- (Only for networked entities)
		if inst.highlightchildren and networktype ~= NetworkType_None then
			if inst.AnimState then
				inst.AnimState:SetSendRemoteUpdatesToLua(true)
				inst:ListenForEvent("remoteanimupdate", SGCommon.Fns.RemoteAnimUpdate)
			else
				print("Warning: inst.AnimState is null but it has highlightchildren! " .. prefabname)
			end
		end


		inst.ApplyPropParams_Safe = ApplyPropParams_Safe
		inst:ApplyPropParams_Safe(inst_params)

		inst:AddComponent("prop")
		inst.components.prop:SetPropType(inst_params.proptype)

		inst.components.prop:SetupParams(inst_params, TheWorld.prop_rng) -- @chrisp #proc_rng

		if inst_params.on_water	then
			inst:AddComponent("bobber")
			inst.AnimState:SetOnWater(true)
			inst.AnimState:SetColorizeUnderWater(not inst_params.water_colorize == false)
			inst.AnimState:SetLayer(LAYER_BELOW_GROUND)
		end

		inst.serializeHistory = inst_params.animhistory	-- Tell it to precisely sync animations

		if inst_params.gridsize ~= nil and #inst_params.gridsize > 0 then
			-- Find the last valid gridsize.
			local final_gridsize
			for i = 1, #inst_params.gridsize do
				local gridsize = inst_params.gridsize[i]
				if gridsize.w ~= nil and gridsize.h ~= nil then
					final_gridsize = gridsize
				end
			end

			-- If there is one, create a snapgrid component and initialize it with the selected gridsize.
			if final_gridsize then
				inst:AddComponent("snaptogrid")
				inst.components.snaptogrid:SetDimensions(final_gridsize.w, final_gridsize.h, final_gridsize.level, final_gridsize.expand)
			end
		end

		if inst_params.childprefab then
			local child_entity = SpawnPrefab(inst_params.childprefab, inst)

			-- Will spawn each time we spawn, so no persist.
			child_entity.persists = false

			child_entity.entity:SetParent(inst.entity)

			if inst_params.childanim then
				child_entity.baseanim = inst_params.childanim
				inst.highlightchildren = inst.highlightchildren or {}
				table.insert(inst.highlightchildren, child_entity)
			end

			inst.child_prop = child_entity

			local offset = deepcopy(inst_params.childoffset) or { x = 0, y = 0, z = 0 }
			child_entity.Transform:SetPosition(Vector3.unpack(offset))
		end

		if inst.sgname_override then
			local require_succeeded, sg = pcall(function()
				return require("stategraphs.".. inst_params.stategraph_override)
			end)
			if not require_succeeded then -- if the sg override doesn't exist, make a dummy one
				inst:SetStateGraph(inst.prefab, MakeAutogenStategraph(inst_params.stategraph_override))
			else
				inst:SetStateGraph(inst_params.stategraph_override)
			end
		end

		if inst_params.stategraph_override then
			-- Fine if script overrides with something better.
			inst.OnEditorSpawn = GotoSpawnFromEditorState
		end

		-- Do this last so script code gets the fully initialized prop!
		prefabutil.ApplyScript(inst, name, inst_params.script, inst_params.script_args)
		return inst
	end

	return Prefab(name, fn, assets, prefabs, nil, networktype)
end

local ret = {}

for name, params in pairs(PropAutogenData) do
	ret[#ret + 1] = MakeAutogenProp(name, params)
	if params.placer then
		for i, prefab in ipairs(Placers.MakePlacerPrefab(name, params)) do
			ret[#ret + 1] = prefab
		end
	end
end

prefabutil.CreateGroupPrefabs(PropAutogenData, ret)

return table.unpack(ret)
