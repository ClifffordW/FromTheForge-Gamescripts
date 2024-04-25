local SGCommon = require "stategraphs.sg_common"
local SGPlayerCommon = require "stategraphs.sg_player_common"
local fmodtable = require "defs.sound.fmodtable"
local PlayerSkillState = require "playerskillstate"


local function RecallOneBall(inst, horizontal)
	SGPlayerCommon.Fns.RecallOneShotput(inst, horizontal)
end

local events = {}
local states =
{
	PlayerSkillState({
		name = "skill_shotput_lob",
		tags = { "busy" },

		onenter = function(inst)
			inst.sg:GoToState("lob_throw")
		end,
	}),
}

return StateGraph("sg_player_shotput_skill_lob", states, events, "skill_shotput_lob")
