local ChaseAndAttack = require("behaviors/chaseandattack")
local KnockdownRecovery = require("behaviors/knockdownrecovery")
local Wander = require("behaviors/wander")
local TargetLastAttacker = require ("behaviors.targetlastattacker")

local BrainThatcher = Class(Brain, function(self, inst)
	Brain._ctor(self, inst, PriorityNode({
		KnockdownRecovery(inst),
		TargetLastAttacker(inst),
		ChaseAndAttack(inst),
		Wander(inst),
	}, .1))
end)

return BrainThatcher
