local Widget = require("widgets/widget")
local Image = require("widgets/image")
local PlayerPuppet = require "widgets.playerpuppet"

local Cosmetic = require "defs.cosmetics.cosmetics"

local BODY_PART_TRANSFORM = {
	[Cosmetic.BodyPartGroups.HEAD]     		= { offset = Vector2(0, -264), scale  = 0.8 },
	
	[Cosmetic.BodyPartGroups.HAIR]     		= { offset = Vector2(-10, -130), scale  = 0.4 },
	[Cosmetic.BodyPartGroups.HAIR_BACK]     = { offset = Vector2(-10, -130), scale  = 0.4 },
	[Cosmetic.BodyPartGroups.HAIR_FRONT]    = { offset = Vector2(-10, -130), scale  = 0.4 },

	[Cosmetic.BodyPartGroups.BROW]     		= { offset = Vector2(-30, -180), scale = 0.6 },
	[Cosmetic.BodyPartGroups.EYES]     = { offset = Vector2(-30, -170), scale = 0.6  },
	[Cosmetic.BodyPartGroups.MOUTH]    = { offset = Vector2(-40, -180), scale = 0.7 },
	[Cosmetic.BodyPartGroups.NOSE]    = { offset = Vector2(-40, -180), scale = 0.7 },
	[Cosmetic.BodyPartGroups.EARS]     = { offset = Vector2(35,  -200), scale  = 0.6 },
	[Cosmetic.BodyPartGroups.ORNAMENT] = { offset = Vector2(-10, -140), scale = 0.45 },
	[Cosmetic.BodyPartGroups.SHIRT]    = { offset = Vector2(4, -250), scale   = 1.32 },
	[Cosmetic.BodyPartGroups.UNDIES]   = { offset = Vector2(4, -148), scale   = 1.32 },
	[Cosmetic.BodyPartGroups.ARMS]     = { offset = Vector2(4, -110), scale   = 0.6 },
	[Cosmetic.BodyPartGroups.LEGS]     = { offset = Vector2(4, -76), scale   = 0.8 },
	[Cosmetic.BodyPartGroups.OTHER]    = { offset = Vector2(60, -110), scale = 0.9 },
	custom_cheeks              = { offset = Vector2(16, -264), scale  = 0.92 },
	custom_forehead            = { offset = Vector2(0, -560), scale = 1.6 },
}

local CosmeticIcon = Class(Widget, function(self, def, size)
	Widget._ctor(self, "CosmeticIcon")

	local size = size or 90

	local xform = BODY_PART_TRANSFORM[def.bodypart_group]

	local image = self:AddChild(Image("images/global/square.tex"))
		:SetSize(size, size)

	self.mask = image:AddChild(Image("images/global/square.tex"))
		:SetName("Mask")
		:SetHiddenBoundingBox(true)
		:SetSize(size, size)
		:SetMask()

	self.puppet_bg = image:AddChild(PlayerPuppet())
		:SetName("Puppet")
		:SetHiddenBoundingBox(true)
		:SetFacing(FACING_RIGHT)
		:PauseInAnim("idle", 0)
		:SetMasked()
		:SetMultColor(HexToRGB(0x090909ff))
		:SetAddColor(HexToRGB(0xBCA693ff))
		:Offset(xform.offset:unpack())
		:SetScale(xform.scale)

	self.puppet = image:AddChild(PlayerPuppet())
		:SetName("Puppet")
		:SetHiddenBoundingBox(true)
		:SetFacing(FACING_RIGHT)
		:PauseInAnim("idle", 0)
		:SetMasked()
		:Offset(xform.offset:unpack())
		:SetScale(xform.scale)

	self.puppet.components.charactercreator:SetBodyPart(def.bodypart_group, def.name)
	self.puppet.components.charactercreator:ClearAllExcept(def.bodypart_group)
end)

return CosmeticIcon
