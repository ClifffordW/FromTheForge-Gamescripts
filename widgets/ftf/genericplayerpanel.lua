local Widget = require("widgets/widget")
local Image = require("widgets/image")
local Panel = require("widgets/panel")
local Text = require("widgets/text")
local ImageButton = require "widgets/imagebutton"
local easing = require "util.easing"
local lume = require"util.lume"
local kstring = require "util.kstring"
local iterator = require "util.iterator"
local PlayerTitleWidget = require("widgets/ftf/playertitlewidget")
local PlayerPuppet = require("widgets/playerpuppet")
local Equipment = require("defs.equipment")
local SGPlayerCommon = require "stategraphs.sg_player_common"

local GenericPlayerPanel = Class(Widget, function(self, player, title)
	Widget._ctor(self, "GenericPlayerPanel")

	self:SetOwningPlayer(player)

	self.root = self:AddChild(Widget())
		:SetName("Root")
		:SetMultColorAlpha(0)

	local extra_height = 0.15
	self.bg = self.root:AddChild(Panel("images/bg_research_screen_left/research_screen_left.tex"))
		:SetName("Panel background")
		:SetNineSliceCoords(200, 1080, 1414, 1755)
		:SetSize(RES_X * .25, RES_Y*(1+extra_height))
		:LayoutBounds("center", "center")
		:Offset(0, 0)

	self.bg_mask = self.root:AddChild(Image("images/bg_popup_flat_inner_mask/popup_flat_inner_mask.tex"))
		:SetName("Dialog background mask")
		:SetSize(RES_X * .25, RES_Y * .75)
		:SetMask()

	self.title_bg = self.root:AddChild(Image("images/ui_ftf_gems/gem_panel_title_bg.tex"))
		:SetName("mastery title bg")
	self.title = self.title_bg:AddChild(Text(FONTFACE.DEFAULT, FONTSIZE.SCREEN_TITLE, title, UICOLORS.BACKGROUND_DARK))
		:SetName("mastery title")

	self:SetTitle(title)
	
	self.contents = self.root:AddChild(Widget())
		:LayoutBounds("center", "below", self.title_bg)

	-- Animated character
	local large_puppet_offset_x = 20
	local large_puppet_offset_y = -380
	self.large_puppet_container = self.root:AddChild(Widget())
		:SetHiddenBoundingBox(true)
		:Hide()

	self.large_puppet_bg = self.large_puppet_container:AddChild(Image("images/ui_ftf_gems/weapons_panel_bg.tex"))
		:SetName("Panel background")
		:SetSize(1100, 1200)

	self.large_puppet_shadow = self.large_puppet_container:AddChild(Image("images/ui_ftf_inventory/CharacterShadow.tex"))
		:SetScale(0.8)
		:Offset(large_puppet_offset_x, large_puppet_offset_y)
		:SetMultColorAlpha(0.6)
	self.large_puppet = self.root:AddChild(PlayerPuppet())
		:SetScale(1.8)
		:SetFacing(FACING_RIGHT)
		:SetHiddenBoundingBox(true)
		:Hide()

	-- Player portrait
	self.small_puppet_container = self.root:AddChild(Widget())
		:SetName("Puppet container")
	self.puppet_bg = self.small_puppet_container:AddChild(Image("images/ui_ftf_runsummary/CharacterMask.tex"))
		:SetName("Puppet bg")
		:SetMultColor(UICOLORS.WHITE)
	self.puppet_mask = self.small_puppet_container:AddChild(Image("images/ui_ftf_runsummary/CharacterMask.tex"))
		:SetName("Puppet mask")
		:SetMultColor(UICOLORS.WHITE)
		:SetMask()
	self.puppet = self.small_puppet_container:AddChild(PlayerPuppet())
		:SetName("Puppet")
		:SetScale(0.35 * HACK_FOR_4K)
		:SetFacing(FACING_RIGHT)
		:SetMasked()
		:CloneCharacterWithEquipment(player)
	self.puppet_overlay = self.small_puppet_container:AddChild(Image("images/ui_ftf_runsummary/CharacterBg.tex"))
		:SetName("Overlay")
		:SetMultColor(HexToRGB(0x3D3029ff))

	self.player_colour = player.uicolor or HexToRGB(0x8CBF91ff)
	self.puppet_bg:SetMultColor(self.player_colour)
	self.puppet_overlay:SetMultColor(self.player_colour)

	-- Player username
	self.username = self.small_puppet_container:AddChild(Text(FONTFACE.DEFAULT, 30 * HACK_FOR_4K, "", UICOLORS.LIGHT_TEXT_TITLE))
		:SetName("Username")
		:EnableShadow(true)
		:EnableOutline(true)
		:SetText(player:GetCustomUserName())

	-- Position puppet
	self.puppet:LayoutBounds("left", "bottom", self.small_puppet_container)
		:Offset(130, -30)
	self.small_puppet_container:LayoutBounds("left", "top", self.bg)
		:Offset(-80, -170)
		:SetHiddenBoundingBox(true)
		:SendToFront()

	self.large_puppet_container:LayoutBounds("before", "center", self.bg)
		:Offset(20, 0)
		:SendToBack()

	self.large_puppet:LayoutBounds("center", "center", self.large_puppet_bg)
		:Offset(large_puppet_offset_x, large_puppet_offset_y)

	self.username
		:SetRotation(-4)
		:LayoutBounds("center", "below", self.puppet_bg)
		:Offset(35, 20)

	self.start_x, self.start_y = self:GetPos()
end)

-- Override to click on an initial tab or other creation that must occur after
-- we're in the screen hierarchy.
function GenericPlayerPanel:OnOpenPanel()
end

function GenericPlayerPanel:UseLargePuppet()
	self.small_puppet_container:Hide()
	self.large_puppet_container:Show()
	self.large_puppet:Show()
	return self
end

function GenericPlayerPanel:IsScreenActive()
	return self.screen == TheFrontEnd:GetActiveScreen()
end

function GenericPlayerPanel:SetPanelFocus(target_focus)
	local player = self:GetOwningPlayer()
	if target_focus and self:IsScreenActive() then
		-- If there's a target and the screen is active, set focus now
		target_focus:SetFocus(player:GetHunterId())
	elseif target_focus then
		-- If there's a focus target, but our screen isn't on top (a popup could be there),
		-- save the focus target for later
		self.screen.last_focus[player:GetHunterId()] = target_focus
	end
	return self
end

function GenericPlayerPanel:Refresh()
	local player = self:GetOwningPlayer()

	self.puppet:CloneCharacterWithEquipment(player)
	self.large_puppet:CloneCharacterWithEquipment(player)

	local equipped_weapon = player.components.inventoryhoard:GetEquippedItem(Equipment.Slots.WEAPON)

	-- Animate the puppet according to the active weapon
	local weapon_idle_animation = SGPlayerCommon.Fns.GetWeaponPrefix(equipped_weapon, "idle_ui")

	local anim_name = self.large_puppet:GetAnimState():GetCurrentAnimationName()
	if anim_name:lower() ~= weapon_idle_animation:lower() then
		self.large_puppet:PlayAnim(weapon_idle_animation, true)
	end
end

function GenericPlayerPanel:SetTitle(title)
	self.title:SetText(title)
	local w, h = self.title:GetSize()
	self.title_bg:SetSize(w + 150, 120)
		:LayoutBounds("center", "top", self.bg)
		:Offset(0, -185)

	self.title:LayoutBounds("center", "center", self.title_bg)

	return self
end

function GenericPlayerPanel:GetContents()
	return self.contents
end

function GenericPlayerPanel:AnimateIn()
	local animate_from_x = self.start_x - 150
	self:RunUpdater(
		Updater.Series({
			Updater.Parallel({
				-- Updater.Ease(function(v) self.darken:SetMultColorAlpha(v) end, 
				-- 	self.darken:GetMultColorAlpha(), BACKGROUND_DARK_ALPHA, 0.6, easing.outQuad),
				Updater.Ease(function(v) self.root:SetMultColorAlpha(v) end, 
					self.root:GetMultColorAlpha(), 1, 0.2, easing.outQuad),
				Updater.Ease(function(v) self.root:SetPos(v, self.start_y) end, animate_from_x, self.start_x, 0.4, easing.outQuad),
			}),
		}))

	return self
end

function GenericPlayerPanel:AnimateOut()
	-- self.darken:SetMultColorAlpha(0)
	self.root:SetMultColorAlpha(0)
	return self
end

return GenericPlayerPanel
