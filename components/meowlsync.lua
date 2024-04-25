local entityutil = require "util.entityutil"

local DEFAULT_MIN_COOLDOWN <const> = 2
local NUM_RAGE_ATTACKS <const> = 3 -- If we change this value, make sure the appropriate number of bits are sent during meowlsync serialization!
local NUM_RAGE_ATTACKS_BITS <const> = 2

local MeowlSync = Class(function(self, inst)
	self.inst = inst
	self.is_raged = false
	self.num_rage_attacks = 0
	self.target = nil
end)

function MeowlSync:IsRaged()
	return self.is_raged
end

function MeowlSync:SetRaged(is_raged)
	self.is_raged = is_raged

	local cooldown = self.is_raged and 0 or DEFAULT_MIN_COOLDOWN
	self.inst.components.attacktracker:SetMinimumCooldown(cooldown)

	self.target = self.inst.components.combat:GetLastAttacker()

	if not self.is_raged then
		self:ResetRageAttackCount()
	end
end

function MeowlSync:GetMaxNumRageAttacks()
	return NUM_RAGE_ATTACKS
end

function MeowlSync:GetRageAttackCount()
	return self.num_rage_attacks
end

function MeowlSync:AddRageAttackCount()
	self.num_rage_attacks = self.num_rage_attacks < NUM_RAGE_ATTACKS and self.num_rage_attacks + 1 or self.num_rage_attacks
end

function MeowlSync:ResetRageAttackCount()
	self.num_rage_attacks = 0
end

function MeowlSync:IsTargetAlive()
	return self.target and self.target:IsValid() and self.target:IsAlive()
end

function MeowlSync:OnNetSerialize()
	local e = self.inst.entity
	e:SerializeBoolean(self.is_raged)

	local has_target = self.target ~= nil
	e:SerializeBoolean(has_target)

	if has_target then
		e:SerializeEntityID(self.target.Network:GetEntityID())
	end

	e:SerializeUInt(self.num_rage_attacks, NUM_RAGE_ATTACKS_BITS)
end

function MeowlSync:OnNetDeserialize()
	local e = self.inst.entity
	self.is_raged = e:DeserializeBoolean()

	local cooldown = self.is_raged and 0 or DEFAULT_MIN_COOLDOWN
	self.inst.components.attacktracker:SetMinimumCooldown(cooldown)

	local has_target = e:DeserializeBoolean()
	if has_target then
		local ent_id = e:DeserializeEntityID()
		self.target = entityutil.TryGetEntity(ent_id)
	end

	local num_rage_attacks = e:DeserializeUInt(NUM_RAGE_ATTACKS_BITS)
	if self.num_rage_attacks ~= num_rage_attacks then
		self.num_rage_attacks = num_rage_attacks
	end
end

return MeowlSync
