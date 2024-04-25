local remove_ptr_prefabs = {
	"remove_decor_pointer_p1",
	"remove_decor_pointer_p2",
	"remove_decor_pointer_p3",
	"remove_decor_pointer_p4",
}


local PlayerPlacer = Class(function(self, inst)
	self.inst = inst
	self.aim = nil
	self.player = nil

	self.active = false

	self.last_angle = 0
	self.offset = 3
end)

function PlayerPlacer:SetPlayer(player)
	self.player = player
	self.inst:ListenForEvent("onremove", self._onremovetarget, player)

	if not self.active and player.GetHunterId then
		local playerID = player:GetHunterId() or 1
		-- For local players
		if self.inst:IsLocal() then
			local aim_pfb = remove_ptr_prefabs[playerID]
			local aim = SpawnPrefab(aim_pfb, player)
			aim.AnimState:SetScale(-1, 1)

			self.aim = aim
			self.inst:StartUpdatingComponent(self)
		end

		self.active = true
		if self.aim then
			self.aim:Hide()
		end
	end
end

function PlayerPlacer.CollectAssets(assets, prefabs)
	for _,p in pairs(remove_ptr_prefabs) do
		table.insert(prefabs, p)
	end
end

function PlayerPlacer:GetControlAngle()
	local angle
	if self.player.components.playercontroller:HasGamepad() then
		angle = self.player.components.playercontroller:GetAnalogDir()
	else
		angle = self.player.components.playercontroller:GetMouseActionDirection()
	end

	if angle then
		angle = math.floor(angle)
		-- Clamp the angle of the aim indicator to the actual effective angles that a player can attack
		local angle_snap = 0 --TUNING.player.attack_angle_clamp - 10 -- Give a bit less angle
		if math.abs(angle) < 90 then
			-- angle = 0
			angle = math.clamp(angle, -angle_snap, angle_snap)
		elseif math.abs(angle) > 90 then
			-- angle = 180
			if angle < 0 then
				angle = math.clamp(angle, -180, -180 + angle_snap)
			else
				angle = math.clamp(angle, 180 - angle_snap, 180)
			end
		end
	end
	return angle
end

function PlayerPlacer:OnUpdate(dt)
	if not self.active or not self.inst:IsLocal() then
		return
	end

	local angle
	-- If we're local, update the angle ourselves. Otherwise, use last_angle from OnNetSerialize.
	-- Facing right = 0
	-- Facing left = 180 or -180
	if self.player:IsLocal() then
		angle = self:GetControlAngle()
		if angle == nil then
			angle = self.last_angle
		end
	else
		angle = self.last_angle
	end

	if self.player ~= nil and self.player:IsValid() then
		if angle then
			self.aim.Transform:SetRotation(angle)
			self.last_angle = angle
		end
		
		local offset = 3

		local x,y,z = self.player.Transform:GetWorldPosition()
		if angle == 0 then
			x = x + offset
		else
			x = x - offset
		end

		self.aim.Transform:SetPosition(x, y, z)
	end
end

function PlayerPlacer:GetPosition()
	return self.aim.Transform:GetWorldPosition()
end

-- function PlayerPlacer:OnNetSerialize()
-- 	local e = self.inst.entity
-- 	local positive = self.last_angle ~= nil and self.last_angle >= 0
-- 	local abs_angle = math.abs(self.last_angle)
-- 	e:SerializeBoolean(positive)
-- 	e:SerializeUInt(abs_angle, 8)
-- end

-- function PlayerPlacer:OnNetDeserialize()
-- 	local e = self.inst.entity
-- 	local positive = e:DeserializeBoolean()
-- 	local abs_angle = e:DeserializeUInt(8)

-- 	if not positive then
-- 		abs_angle = abs_angle * -1
-- 	end

-- 	self.last_angle = abs_angle
-- end

return PlayerPlacer
