
local fmodtable = require "defs.sound.fmodtable"
local Constructable = require "defs.constructable"

local PropRemover = Class(function(self, inst)
	self.inst = inst
	self.active = false

	self._onremovesuccessful = function(_, data)
		if data and data.entityID == self.removed_prop_data.entityID then
			local def = self.removed_prop_data.def
			local x = self.removed_prop_data.x
			local z = self.removed_prop_data.z

			self.inst.components.inventoryhoard:AddStackable(def, 1)
			local fx = SpawnPrefab("fx_dust_ground_ring")
			fx.Transform:SetPosition(x, 0, z)
	
			local function validate_fn()
				return self.inst.components.inventoryhoard:GetStackableCount(def) > 0
			end
	
			local function on_success(placer, placed_ent)
				local stackable_count = self.inst.components.inventoryhoard:GetStackableCount(def)
				dbassert(stackable_count > 0)
				self.inst.components.inventoryhoard:RemoveStackable(def, 1)
				self.inst.components.playercontroller:StopPlacer()
				TheFrontEnd:GetSound():PlaySound(fmodtable.Event.place_building)
				self.inst.components.playercontroller:StartPropRemover()
			end
	
			local function on_cancel(placer)
				local x, z = placer.Transform:GetWorldXZ()
				local fx = SpawnPrefab("fx_dust_ground_ring")
				fx.Transform:SetPosition(x, 0, z)
				self.inst:DoTaskInTime(0, function() 
					self.inst.components.playercontroller:StartPropRemover()
				end)
			end

			self.selected_prop = nil
			self.removed_prop_data = nil

			self.inst.components.playercontroller:StopPropRemover()
			self.inst.components.playercontroller:StartPlacer(def.name .. "_placer", validate_fn, on_success, on_cancel)
		end
	end

	self._onremovefailed = function(_, data)
		--TODO: add fx, sound, etc
		self.selected_prop = nil
		self.removed_prop_data = nil
	end

	self.inst:ListenForEvent("onremovesuccessful", self._onremovesuccessful)
	self.inst:ListenForEvent("onremovefailed", self._onremovefailed)

end)

function PropRemover:SetActive(active)
	if active then
		self:Activate()
	else
		self:Deactivate()
	end
end

function PropRemover:Activate()
	self.active = true
	self.inst.components.playerplacer.aim:Show()
	self.inst:StartWallUpdatingComponent(self)
end

function PropRemover:Deactivate()
	self.active = false
	if self.selected_prop ~= nil and self.selected_prop.components.colormultiplier then
		self.selected_prop.components.colormultiplier:PopColor("remover")
	end
	self.inst.components.interactor:SetStatusText("pickup_instructions", nil)
	self.inst.components.playerplacer.aim:Hide()
	self.inst:StopWallUpdatingComponent(self)
end

function PropRemover:GetPropInPos(x, z)
	local snapgrid = TheWorld.components.snapgrid
	local _, _, row, col = snapgrid:SnapToGrid(x, z) -- TODO @H: tune this better
	local cellid = snapgrid:GetCellId(row, col, 0)
	local ents = snapgrid:GetEntitiesInCell(cellid)

	for _, ent in ipairs(ents) do
		local def = Constructable.FindItem(ent.prefab)
		if def ~= nil and (def.slot == Constructable.Slots.DECOR or def.slot == Constructable.Slots.STRUCTURES) then
			return ent
		end
	end
end

function PropRemover:PickSelectedProp()
	if self.selected_prop == nil then
		return
	end

	local entityID = self.selected_prop.Network:GetEntityID()
	if not TheNet:CanRemoveTownProp(entityID) then
		return
	end

	self.removed_prop_data = {}
	self.removed_prop_data.def = Constructable.FindItem(self.selected_prop.prefab)
	
	local x, z = self.selected_prop.Transform:GetWorldXZ()
	self.removed_prop_data.x = x
	self.removed_prop_data.z = z

	self.removed_prop_data.entityID = entityID
	TheNet:RequestRemoveTownProp(self.inst.Network:GetPlayerID(), entityID)
end

function PropRemover:OnWallUpdate(dt)
	if not self.active or not self.inst:IsLocal() then
		return
	end

	local x, y, z = self.inst.components.playerplacer:GetPosition()
	local prop = self:GetPropInPos(x,z)
	if prop ~= self.selected_prop then

		if self.selected_prop ~= nil and self.selected_prop.components.colormultiplier then
			self.selected_prop.components.colormultiplier:PushColor("remover", table.unpack(UICOLORS.GREEN))
		end

		if prop ~= nil then
			if prop.components.colormultiplier then
				prop.components.colormultiplier:PushColor("remover", table.unpack(UICOLORS.RED))
			end
			self.inst.components.interactor:SetStatusText("pickup_instructions", STRINGS.UI.HUD.PICKUP_INSTRUCTIONS)
		else
			self.inst.components.interactor:SetStatusText("pickup_instructions", nil)
		end

		self.selected_prop = prop
	end

	if self.inst.components.interactor:HasStatusText("pickup_instructions") then
		self.inst.components.interactor:ChangeStatusAlignment(self.inst.Transform:GetFacingRotation() == 0)
	end

end

return PropRemover
