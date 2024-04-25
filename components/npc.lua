local Constructable = require "defs.constructable"
local emotion = require "defs.emotion"
local DebugDraw = require "util.debugdraw"
local Enum = require "util.enum"
local recipes = require "defs.recipes"
local ParticleSystemHelper = require "util.particlesystemhelper"

local Npc = Class(function(self, ...)
	return self:init(...)
end)

function Npc:init(inst)
	self.inst = inst
	self.home = nil
	self.onhomechangedfn = nil

	-- TODO: Load personality from npc tuning.
	self.text_personality = Npc.BuildDefaultTextPersonality()

	--This is for hiding/showing Npc's when the player is placing buildings
	self._onstartplacing = function()
		inst.sg:GoToState("idle")
		inst:RemoveFromScene()
	end

	self._onstopplacing = function(world, hasplaced)
		inst:ReturnToScene()
	end

	--inst:ListenForEvent("startplacing", self._onstartplacing, TheWorld)
	--inst:ListenForEvent("stopplacing", self._onstopplacing, TheWorld)

	--inst:ListenForEvent("startcustomizing", self._onstartplacing, TheWorld)
	--inst:ListenForEvent("stopcustomizing", self._onstopplacing, TheWorld)

	local flag_string = string.format("wf_seen_%s", self.inst.prefab)
	TheWorld:UnlockFlag(flag_string)
end

Npc.Role = Enum{
	"visitor", -- pseudo role for newcomers

	"apothecary",
	"armorsmith",
	"blacksmith",
	"cook",
	"hunter",
	"konjurist",
	"refiner",
	"scout",
	"specialeventhost",
	"travelling_salesman",
	"market_merchant",
}

function Npc.BuildDefaultTextPersonality() -- no args!
	-- For the structure of personality, see Text:SetPersonalityText.
	local personality = {
		character_delay = 0.02,
		spool_by_character = true,
		separator = {
			["!"] = {
				delay = 0.5,
			},
			["?"] = {
				delay = 0.5,
			},
			[","] = {
				delay = 0.3,
			},
			["."] = {
				delay = 0.3,
			},
			["-"] = {
				delay = 0.15,
			},
			[" "] = {
				delay = 100, -- see below
			},
		},
		feeling = emotion.feeling.neutral,
	}
	personality.separator[" "].delay = personality.spool_by_character and personality.character_delay*0.5 or 0.15
	return personality
end

function Npc:GetTextPersonality()
	-- TODO: Listen to event to set their current feeling.
	self.text_personality.feeling = emotion.feeling.neutral
	return self.text_personality
end

-- Should be one of Npc.Role
function Npc:GetRole()
	return self.role
end

function Npc:SetSpecies(species)
	self.species = species
	return self
end

function Npc:GetSpecies()
	return self.species
end

function Npc:SetOnHomeChangedFn(fn)
	self.onhomechangedfn = fn
end

function Npc:SetHome(home)
	dbassert(home and not self:_HasHome())
	self.home = home
	if self.onhomechangedfn ~= nil then
		self.onhomechangedfn(self.inst, home)
	end
end

function Npc:GetHome()
	return self.home
end

-- Initial spawn point (not a building) counts as a "home".
function Npc:_HasHome()
	return self.home ~= nil
end

function Npc:OnSave()
	return
	{
		role = self.role,
	}
end

function Npc:OnLoad(data)
	self.role = data.role
end

function Npc:DebugDrawEntity(ui, panel, colors)
	local home = self:GetHome()
	if home then
		local maxdist = self.inst.tuning.wander_dist
		ui:ColorButton("Wander Radius", WEBCOLORS.GREEN)
		ui:SameLineWithSpace()
		-- Value lives inside brain, so it's nontrivial to live edit so just show it.
		ui:Value("Wander Radius", maxdist)
		local x,z = home.Transform:GetWorldXZ()
		DebugDraw.GroundCircle(x, z, maxdist, WEBCOLORS.GREEN)
	else
		ui:Text("No home")
	end

	ui:Value("role", self.role)
end

function Npc:GetDebugString()
	return "Home: "..tostring(self.home)
end



return Npc
