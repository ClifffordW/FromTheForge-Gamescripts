local Constructable = require "defs.constructable"
local kassert = require "util.kassert"
local fmodtable = require "defs.sound.fmodtable"

local function CreateLayer()
	local inst = CreateEntity()

	inst.entity:AddTransform()
	inst.entity:AddAnimState()

	inst:AddTag("FX")
	inst:AddTag("NOCLICK")
	inst.persists = false

	inst:AddComponent("colormultiplier")

	return inst
end

-- From groundtiles.lua
local DEFAULT_CRITICAL_PATH_TILES = {"DIRTTOWN", "GRASSDARKTOWN", "COBBLETOWN"}

local Placer = Class(function(self, inst)
	self.inst = inst
	self.placed_prefab = nil
	self.validatefn = nil
	self.onplacefn = nil
	self.oncancelfn = nil
	self.hasplaced = false

	self.flip = nil

	self.critical_path_tiles = deepcopy(DEFAULT_CRITICAL_PATH_TILES)

	self.inst:AddTag("placer")
	self.waiting_entities = {}

	
	self._onactualsuccess = function(prop)
		local x, z = prop.Transform:GetWorldXZ()
		local fx = SpawnPrefab("fx_dust_pickup_up")
		fx.Transform:SetPosition(x, 0, z - 0.5)
		self.inst.SoundEmitter:PlaySound(fmodtable.Event.place_building)
		if self.onplacefn ~= nil then
			self.onplacefn(self.inst, prop)
		end
	end
	
	self._onplacementsuccesful = function(_, data)
		if data and data.entityID then
			local guid = TheNet:FindGUIDForEntityID(data.entityID)
			if guid and guid ~= 0 and Ents[guid] and Ents[guid]:IsValid() then
				self._onactualsuccess(Ents[guid])
			else
				-- The Entity might not be spawned yet because of unreliable network packets
				-- So we add it to a waiting list along with a timer
				-- That introduces a possible exploit where players could build free decorations if they can place faster than the timeout
				if self.waiting_entities[data.propname] == nil then
					self.waiting_entities[data.propname] = {}
				end
				
				self.waiting_entities[data.propname][data.entityID] = 0
			end
		end
		
	end
	
	self._onplacementfailed = function(_, data)
		-- We don't need to return the item to the inventory here since it only gets removed on success
		-- TODO: add a fail fx, sound, etc
	end

	self._placementontimeout = function() 
		self._onplacementfailed()
	end

	self.inst.components.snaptogrid:SetDrawGridEnabled(true)
	inst:StartWallUpdatingComponent(self)
	self:OnWallUpdate(0)
end)

Placer.DECOR_TAG = "ManagedDecor"

function Placer:SetPlayer(player)
	self.player = player
	self.player.components.interactor:SetStatusText("place_instructions", STRINGS.UI.HUD.PLACE_INSTRUCTIONS)
	self.inst:ListenForEvent("placement_sucessful", self._onplacementsuccesful, self.player)
	self.inst:ListenForEvent("placement_failed", 	self._onplacementfailed, self.player)
end

function Placer:FlipPlacer()
	self.flip = not self.flip or nil
	local xscale = self.flip and -1 or 1
	if self.inst.AnimState ~= nil then
		self.inst.AnimState:SetScale(xscale, 1)
	end
	if self.inst.highlightchildren ~= nil then
		for i = 1, #self.inst.highlightchildren do
			local child = self.inst.highlightchildren[i]
			if child.AnimState ~= nil then
				child.AnimState:SetScale(xscale, 1)
			end
			-- local xp, yp, zp = child.Transform:GetLocalPosition()
			-- child.Transform:SetPosition(xp * -1, yp, zp)
		end
	end
end

function Placer:SetParams(params)
	self.params = params
	if params.variations then
		self.variation = 1
	end

	self:UpdateVisuals()
end

function Placer:AdvanceVariation()
	if not self.params.variations then
		self.variation = nil
		return
	end

	self.variation = self.variation + 1

	if self.variation > self.params.variations then
		self.variation = 1
	end

	self:UpdateVisuals()
end

function Placer:UpdateVisuals()
	local params = self.params

	if params.parallax ~= nil then
		if self.inst.highlightchildren then
			for _, child in ipairs(self.inst.highlightchildren) do
				child:Remove()
			end
		end

		local bank = params.bank or self.placed_prefab
		local build = params.build or self.placed_prefab

		for i = 1, #params.parallax do
			local layerparams = params.parallax[i]
			if layerparams.anim ~= nil then
				local ent
				if layerparams.dist == nil or layerparams.dist == 0 then
					ent = self.inst
				else
					ent = CreateLayer()
					ent.entity:SetParent(self.inst.entity)
					ent.Transform:SetPosition(0, 0, layerparams.dist)

					if self.inst.highlightchildren == nil then
						self.inst.highlightchildren = { ent }
					else
						self.inst.highlightchildren[#self.inst.highlightchildren + 1] = ent
					end

					self.inst.components.colormultiplier:AttachChild(ent)
				end

				ent.AnimState:SetBank(bank)
				ent.AnimState:SetBuild(build)
				ent.baseanim = layerparams.anim

				-- Legacy anim setup. baseanim should be the anim
				-- suffix, but we have legacy data that used the suffix
				-- as the idle name.
				ent.use_baseanim_for_idle = self.params.parallax_use_baseanim_for_idle

				if layerparams.shadow then
					ent.AnimState:SetShadowEnabled(true)
				end

				if layerparams.flip then
					ent.AnimState:SetScale(-1, 1)
				end
			end
		end

		self:SetVariationInternal(self.variation)
	end
end

function Placer:SetVariationInternal(variation)
	self.variation = variation
	if self.inst.AnimState ~= nil then
		local anim = "idle_".. self.inst.baseanim
		if self.inst.use_baseanim_for_idle then
			anim = self.inst.baseanim
		end
		if variation ~= nil then
			anim = anim..tostring(variation)
		end
		self.inst.AnimState:PlayAnimation(anim, self.looping)
	end
	if self.inst.highlightchildren ~= nil then
		for i = 1, #self.inst.highlightchildren do
			local child = self.inst.highlightchildren[i]
			if child.AnimState ~= nil then
				local anim = "idle_".. child.baseanim
				if child.use_baseanim_for_idle then
					anim = child.baseanim
				end
				if variation ~= nil then
					anim = anim..tostring(variation)
				end
				child.AnimState:PlayAnimation(anim, self.looping)
			end
		end
	end
end


function Placer:OnRemoveEntity()
	self:ClearCollidingEnts()
	if self.player ~= nil then
		self.player.components.interactor:SetStatusText("placer_blocked", nil)
		self.player.components.interactor:SetStatusText("place_instructions", nil)
		self.inst:RemoveEventCallback("placement_sucessful", self._onplacementsuccesful)
		self.inst:RemoveEventCallback("placement_failed", self._onplacementfailed)
	end
	if self.oncancelfn ~= nil then
		self.oncancelfn(self.inst)
	end
end

function Placer:OnRemoveFromEntity()
	self:OnRemoveEntity()
end

function Placer:SetPlacedPrefab(name)
	self.placed_prefab = name
	local def = Constructable.FindItem(name)
	if def then
		self.constructable_type = def.slot
	end
end

function Placer:SetValidateFn(fn)
	self.validatefn = fn
end

function Placer:SetOnPlaceFn(fn)
	self.onplacefn = fn
end

function Placer:SetOnCancelFn(fn)
	self.oncancelfn = fn
end

function Placer:HasPlaced()
	return self.hasplaced
end

function Placer:GetPlotInCells()
	local ents = self.inst.components.snaptogrid:GetEntitiesInCells()
	for _, ent in ipairs(ents) do
		-- TODO: check for a tag instead
		if ent.prefab == "plot" then
			return ent
		end
	end
end

function Placer:GetPlotInPos(x, z)
	local snapgrid = TheWorld.components.snapgrid
	local _, _, row, col = snapgrid:SnapToGrid(x, z)
	local cellid = snapgrid:GetCellId(row, col, 0)
	local ents = snapgrid:GetEntitiesInCell(cellid)

	for _, ent in ipairs(ents) do
		-- TODO: check for a tag instead
		if ent.prefab == "plot" then
			return ent
		end
	end	
end


function Placer.StaticCanPlace(inst, constructable_type, critical_path_tiles)
	if not inst.components.snaptogrid then
		return true
	end

	local reason
	local is_grid_clear = inst.components.snaptogrid:IsGridClearForCells()

	if not is_grid_clear then
		reason = "OCCUPIED"
	end

	-- if constructable_type == Constructable.Slots.DECOR then
	-- 	return is_grid_clear, reason

	-- Testing out having nothing on the critical path
	if constructable_type == Constructable.Slots.STRUCTURES or constructable_type == Constructable.Slots.DECOR then
		local x,y,z = inst.Transform:GetWorldPosition()
		local tile = TheWorld.Map:GetNamedTileAtXZ(x,z)

		local is_critical_path = table.contains(critical_path_tiles or DEFAULT_CRITICAL_PATH_TILES, tile)
		if is_critical_path then
			reason = "CRITICAL_PATH"
		end

		return is_grid_clear and not is_critical_path, reason
	else
		return true
	end
end

function Placer:CanPlace()
	return Placer.StaticCanPlace(self.inst, self.constructable_type, self.critical_path_tiles) and TheNet:CanPlaceTownProp()
end

function Placer:GetDecorTag()
	return Placer.DECOR_TAG
end

function Placer:OnPlace()
	local is_valid = true
	if self.validatefn ~= nil then
		is_valid = self.validatefn(self.inst, self.placed_prefab)
		if not is_valid then
			--spawn_fail_fx()
			return
		end
	end

	if self:CanPlace() and is_valid then -- ON SUCCESS
		local x, z = self.inst.Transform:GetWorldXZ()

		-- TheNet doesn't like to receive nil arguments, so we make sure it doesn't
		local flip = self.flip
		if flip == nil then
			flip = false
		end
		local variation = self.variation
		if variation == nil then
			variation = 1
		end

		if self.player then
			local playerID = self.player.Network:GetPlayerID() -- TODO!
			TheNet:RequestPlaceTownProp(playerID, self.placed_prefab, x, z, flip, variation)
		end
	end
end

function Placer:ClearCollidingEnts()
	if self.colliding_ents ~= nil then
		for _, ent in ipairs(self.colliding_ents) do
			if ent ~= self.inst then
				if ent.components.colormultiplier then
					ent.components.colormultiplier:PopColor("placer")
				end
				ent.components.snaptogrid:SetDrawGridEnabled(false)
			end
		end
	end
end

function Placer:FilterCollidingEnts()
	local ents = self.inst.components.snaptogrid:GetEntitiesInCells()
	local filtered_ents = {}
	for _, ent in ipairs(ents) do
		if not ent:HasTag("ignore_placer") then
			table.insert(filtered_ents, ent)
		end
	end

	return filtered_ents
end

function Placer:OnWallUpdate(dt)
	if self.player then
		local x, y, z = self.player.components.playerplacer:GetPosition()
		self.inst.components.snaptogrid:MoveToNearestGridPos(x, y, z, true)
	end
	
	self:ClearCollidingEnts()

	local can_place, reason = self:CanPlace()

	if can_place then
		self.inst.components.colormultiplier:PushColor("placer", table.unpack(UICOLORS.GREEN))
		if self.player then
			self.player.components.interactor:SetStatusText("placer_blocked", nil)
		end
	else
		self.inst.components.colormultiplier:PushColor("placer", table.unpack(UICOLORS.RED))
		self.colliding_ents = self:FilterCollidingEnts()

		for _, ent in ipairs(self.colliding_ents) do
			if ent.components.colormultiplier then
				ent.components.colormultiplier:PushColor("placer", table.unpack(UICOLORS.RED))
			end
			ent.components.snaptogrid:SetDrawGridEnabled(true)
		end

		if self.player then
			self.player.components.interactor:SetStatusText("placer_blocked", STRINGS.UI.HUD.CANNOT_PLACE_PROP[reason])
		end
	end

	if self.player then
		self.player.components.interactor:ChangeStatusAlignment(self.player.Transform:GetFacingRotation() == 0)
	end

	-- Doing this last because actual success invokes a callback which has the potential to destroy the placer mid-update, making the entity invalid
	if self.waiting_entities ~= nil then
		for propname, waiting_data in pairs(self.waiting_entities) do
			for entityID, time in pairs(waiting_data) do
				local guid = TheNet:FindGUIDForEntityID(entityID)
				if guid and guid ~= 0 and Ents[guid] and Ents[guid]:IsValid() then
					waiting_data[entityID] = nil
					self._onactualsuccess(Ents[guid])
				else
					-- TODO: maybe the time out should be in frames instead of dt?
					waiting_data[entityID] = waiting_data[entityID] + dt
					if waiting_data[entityID] > 0.5 then
						waiting_data[entityID] = nil
						self._placementontimeout(propname)
					end
				end
			end
		end
	end
end

return Placer
