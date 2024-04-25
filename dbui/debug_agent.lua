--~ local CmpAgentHistory = require "sim.components.agent.cmpagenthistory"
--~ local Condition = require "sim.condition"
local Agent = require "questral.agent"
local DebugNodes = require "dbui.debug_nodes"
local DebugQuestManager = require "dbui.debug_questmanager"
local Quest = require "questral.quest"
local iterator = require "util.iterator"
local qconstants = require "questral.questralconstants"

-------------------------------------------------------------------

local DebugAgent = Class(DebugNodes.DebugNode, function(self, ...) self:init(...) end)

DebugAgent.REGISTERED_CLASS = Agent
DebugAgent.MENU_BINDINGS = {
	DebugQuestManager.QUEST_MENU,
}

local DBG = d_view

function DebugAgent:init( agent )
	DebugNodes.DebugNode._ctor(self, "Debug Agent")
    self.agent = agent
end

function DebugAgent:RenderPanel( ui, panel, dbg )
    ui:Value("Agent", tostring(self.agent:GetPrettyName()) )

    ui:SameLineWithSpace()
    if ui:Button("View Entity", nil, nil, self.agent.inst == nil) then
        panel:PushNode(DebugNodes.DebugEntity(self.agent.inst))
    end

    ui:Separator()

    if ui:CollapsingHeader("Quest Membership") then
        for _, quest in ipairs(self.agent:GetQuests()) do
            if ui:Button(tostring(quest)) then
                panel:PushNode(DebugNodes.DebugQuest(quest))        
            end
        end
    end

	self:AddFilteredAll(ui, panel, self.agent)
end

DebugNodes.DebugAgent = DebugAgent
return DebugAgent
