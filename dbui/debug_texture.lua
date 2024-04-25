local Consumable = require "defs.consumable"
local DebugDraw = require "util.debugdraw"
local DebugNodes = require "dbui.debug_nodes"
local Enum = require "util.enum"
local iterator = require "util.iterator"
local lume = require "util.lume"
require "consolecommands"
require "constants"

local DebugTexture = Class(DebugNodes.DebugNode, function(self)
	DebugNodes.DebugNode._ctor(self, "Debug Texture")

	self.texture_path = ""
end)

DebugTexture.PANEL_WIDTH = 500
DebugTexture.PANEL_HEIGHT = 500

function DebugTexture:RenderPanel( ui, panel )

	local changed, new_path = ui:InputText("texture path", self.texture_path)
	if changed then
		self.texture_path = new_path
	end

	local function image_from_atlastexture(label, atlastexture)
		local parts = atlastexture:split()
		if #parts == 2 then
			ui:AtlasImage(parts[1], parts[2], 200, 200)
		end
	end

	if type(self.texture_path) == "string" and self.texture_path:find(".tex") ~= nil then
		local atlas, tex = GetAtlasTex(self.texture_path)
		image_from_atlastexture("atlas:texture", string.format("%s:%s", atlas or "", tex or ""))
	end

end

DebugNodes.DebugTexture = DebugTexture

return DebugTexture
