--~ local CmpAgentHistory = require "sim.components.agent.cmpagenthistory"
--~ local Condition = require "sim.condition"
local Agent = require "questral.agent"
local DebugNodes = require "dbui.debug_nodes"
local DebugQuestManager = require "dbui.debug_questmanager"
local Quest = require "questral.quest"
local iterator = require "util.iterator"
local qconstants = require "questral.questralconstants"

-------------------------------------------------------------------

local DebugQuips = Class(DebugNodes.DebugNode, function(self) 
    DebugNodes.DebugNode._ctor(self, "Debug Quips")

    local questcentral = GetDebugPlayer().components.questcentral
    self.sim = questcentral

end)

function DebugQuips:RenderPanel( ui, panel )
    local matcher = self.sim:GetQuipMatcher()
    matcher:RenderDebugUI(ui, panel)
end

DebugNodes.DebugQuips = DebugQuips
return DebugQuips
