local WaitingDialog = require "screens.dialogs.waitingdialog"
local Widget = require "widgets.widget"
local Image = require "widgets.image"
local ImageButton = require "widgets.imagebutton"
local Panel = require "widgets.panel"
local Text = require "widgets.text"
local TextButton = require "widgets.textbutton"
local Screen = require "widgets.screen"
local ScrollPanel = require "widgets.scrollpanel"
local TabGroup = require "widgets.tabgroup"
local templates = require "widgets.ftf.templates"
local ConfirmDialog = require "screens.dialogs.confirmdialog"

local PlayerPuppet = require "widgets.playerpuppet"
local PlayerTitleWidget = require "widgets.ftf.playertitlewidget"

local SelectableItemColor = require "widgets.ftf.selectableitemcolor"
local SelectableBodyPart = require "widgets.ftf.selectablebodypart"
local SelectableArmorDye = require "widgets.ftf.selectablearmordye"
local SelectablePlayerTitle = require "widgets.ftf.selectableplayertitle"

local audioid = require "defs.sound.audioid"
local soundutil = require "util.soundutil"
local fmodtable = require "defs.sound.fmodtable"

local lume = require "util.lume"
local easing = require "util.easing"
local krandom = require "util.krandom"

local Cosmetic = require "defs.cosmetics.cosmetics"
local Consumable = require "defs.consumable"

local ui = require "dbui.imgui"

-- The categories on the top tabs
local TOP_TABS =
{
	[1] = STRINGS.CHARACTER_CREATOR.TAB_TITLE,
	[2] = STRINGS.CHARACTER_CREATOR.TAB_SPECIES,
	[3] = STRINGS.CHARACTER_CREATOR.TAB_HEAD,
	[4] = STRINGS.CHARACTER_CREATOR.TAB_BODY,
	--[5] = STRINGS.CHARACTER_CREATOR.TAB_ARMORDYE,
}
-- Maps body parts to the top tabs
local SUB_TABS =
{
	[1] = {
		"PLAYER_TITLE"
	},

	[2] = {
		Cosmetic.BodyPartGroups.HEAD
	},
	[3] = {
		Cosmetic.BodyPartGroups.HAIR,
		Cosmetic.BodyPartGroups.HAIR_BACK,
		Cosmetic.BodyPartGroups.HAIR_FRONT,
		Cosmetic.BodyPartGroups.BROW,
		Cosmetic.BodyPartGroups.EYES,
		Cosmetic.BodyPartGroups.MOUTH,
		Cosmetic.BodyPartGroups.NOSE,
		Cosmetic.BodyPartGroups.EARS,
		Cosmetic.BodyPartGroups.ORNAMENT,
	},
	[4] = {
		Cosmetic.BodyPartGroups.SHIRT,
		Cosmetic.BodyPartGroups.UNDIES,
		Cosmetic.BodyPartGroups.ARMS,
		Cosmetic.BodyPartGroups.LEGS,
		Cosmetic.BodyPartGroups.OTHER,
	},

	-- TODO: Make this into slots like the bodypartgroups
	-- [5] =
	-- {
	-- 	"HEAD",
	-- 	"BODY",
	-- 	"WAIST",
	-- },
}

local BODY_PART_COLOR_MAP =
{
	[Cosmetic.BodyPartGroups.HEAD] = "SKIN_TONE",
	[Cosmetic.BodyPartGroups.HAIR] = "HAIR_COLOR",
	[Cosmetic.BodyPartGroups.HAIR_BACK] = "HAIR_COLOR",
	[Cosmetic.BodyPartGroups.HAIR_FRONT] = "HAIR_COLOR",
	[Cosmetic.BodyPartGroups.BROW] = "HAIR_COLOR",
	[Cosmetic.BodyPartGroups.EYES] = "EYE_COLOR",
	[Cosmetic.BodyPartGroups.NOSE] = "NOSE_COLOR",
	[Cosmetic.BodyPartGroups.EARS] = "EAR_COLOR",
	--[Cosmetic.BodyPartGroups.MOUTH] = "MOUTH_COLOR",
	[Cosmetic.BodyPartGroups.ORNAMENT] = "ORNAMENT_COLOR",
	[Cosmetic.BodyPartGroups.SHIRT] = "SHIRT_COLOR",
	[Cosmetic.BodyPartGroups.UNDIES] = "UNDIES_COLOR",
}


local BODY_PART_TRANSFORM = {
	[Cosmetic.BodyPartGroups.HEAD]     = { offset = Vector2(0, -264), scale  = 0.8 },
	[Cosmetic.BodyPartGroups.HAIR]     		= { offset = Vector2(0, -300), scale  = 1 },
	[Cosmetic.BodyPartGroups.HAIR_BACK]     = { offset = Vector2(0, -250), scale  = 0.75 },
	[Cosmetic.BodyPartGroups.HAIR_FRONT]    = { offset = Vector2(0, -290), scale  = 1 },
	[Cosmetic.BodyPartGroups.BROW]     = { offset = Vector2(-30, -560), scale = 1.6 },
	[Cosmetic.BodyPartGroups.EYES]     = { offset = Vector2(-60, -450), scale = 1.6  },
	[Cosmetic.BodyPartGroups.MOUTH]    = { offset = Vector2(-60, -465), scale = 1.76 },
	[Cosmetic.BodyPartGroups.NOSE]     = { offset = Vector2(-60, -496), scale = 1.76 },
	[Cosmetic.BodyPartGroups.EARS]     = { offset = Vector2(0,  -280), scale  = 1 },
	[Cosmetic.BodyPartGroups.ORNAMENT] = { offset = Vector2(80, -480), scale = 1.6 },
	[Cosmetic.BodyPartGroups.SHIRT]    = { offset = Vector2(4, -250), scale   = 1.32 },
	[Cosmetic.BodyPartGroups.UNDIES]   = { offset = Vector2(4, -148), scale   = 1.32 },
	[Cosmetic.BodyPartGroups.ARMS]     = { offset = Vector2(4, -110), scale   = 0.6 },
	[Cosmetic.BodyPartGroups.LEGS]     = { offset = Vector2(4, -76), scale   = 0.8 },
	[Cosmetic.BodyPartGroups.OTHER]    = { offset = Vector2(60, -110), scale = 0.9 },
	custom_cheeks              = { offset = Vector2(16, -264), scale  = 0.92 },
	custom_forehead            = { offset = Vector2(0, -560), scale = 1.6 },
}

local BODY_PART_SPECIES_REMAP = {
	[Cosmetic.BodyPartGroups.ORNAMENT] = {
		-- Each species puts ornament in a different location.
		[Cosmetic.BodyParts.HEAD.ogre_head_1.name] = Cosmetic.BodyPartGroups.HAIR,
		[Cosmetic.BodyParts.HEAD.mer_head_1.name] = "custom_cheeks",
		[Cosmetic.BodyParts.HEAD.canine_head_1.name] = "custom_forehead",
	},
}

local ARMOR_DYE_TRANSFORM =
{
	["HEAD"]  = { offset = Vector2(-30, -380), scale = 1.2 },
	["BODY"]  = { offset = Vector2(0, -220), scale = 1 },
	["WAIST"] = { offset = Vector2(0, -76),  scale = 1.4 },
}

-- In case we don't want to disply the colors of a body part for a specific species
-- Ear and nose colors for merms for instance
local COLOR_EXCEPTIONS = 
{
	mer = { "NOSE", "EARS" },
	canine = { "HAIR", "HAIR_FRONT", "HAIR_BACK" },
}

local ARMOR_HIGHLIGHT_PARTS =
{
	["HEAD"]  = { "HEAD", "HAIR", "HAIR_BACK", "HAIR_FRONT", "BROW", "EYES", "MOUTH", "NOSE", "EARS", "ORNAMENT"},
	["BODY"]  = {"TORSO","SHIRT","ARMS"},
	["WAIST"] = {"UNDIES", "LEGS", "OTHER"},
}

local SPECIES_CHANGE_COST = 10

------------------------------------------------------------------------------------------
--- Displays a screen for the player to customize their playable character
-- ┌─────────────────────────────────────────────────────────────────────────────────────┐
-- │ bg                                                                                  │
-- │                                                                                     │
-- │                                                                                     │
-- │                                                                                     │
-- │     ┌─────────────────────────────────────────────────────────────────────────┐     │ ◄ panel_root is the
-- │     │ panel_root                                                              │     │   element that animates in
-- │     │ ┌─────────────────────────────────────────────────────────────────────┐ │     │
-- │     │ │ panel_bg                                                            │ │     │
-- │     │ │                                                                     │ │     │
-- │     │ │                                                                     │ │     │
-- │     │ │                                                                     │ │     │
-- │     │ │                                                                     │ │     │
-- │     │ │                                                                     │ │     │
-- │     │ │                                                                     │ │     │
-- │     │ │                                                                     │ │     │
-- │     │ │                                                                     │ │     │
-- │     │ │                                                                     │ │     │
-- │     │ └─────────────────────────────────────────────────────────────────────┘ │     │
-- │     └─────────────────────────────────────────────────────────────────────────┘     │
-- │                               ┌────────────────────┐                                │
-- │                               │                    │                                │
-- │                               │ start_btn          │                                │
-- │                               │                    │                                │
-- │                               └────────────────────┘                                │
-- │                                                                                     │
-- └─────────────────────────────────────────────────────────────────────────────────────┘
--
--   Shows up ingame when the player uses the mirror. Shows customization options.
------------------------------------------------------------------------------------------

local CharacterScreen = Class(Screen, function(self, owner, on_close_cb, new_character_data, debug_mode)
	Screen._ctor(self, "CharacterScreen")
	self:SetAudioCategory(Screen.AudioCategory.s.Fullscreen)

	dbassert(owner)
	self.owner = owner
	self.owner_player_id = owner.Network:GetPlayerID()
	if owner.components.playercontroller:HasInputDevice() then
		-- Since this screen is in our start game flow, it's somehow possible
		-- to get here without setting a device on the player.
		-- TODO(ui): Rework player creation flow to avoid problems like this.
		self:SetOwningPlayer(owner)
	else
		TheLog.ch.FrontEnd:printf("CharacterScreen: Somehow owner [%s] didn't have an input device!", owner)
		dbassert(false)
	end

	self.on_close_cb = on_close_cb

	self.is_new_character = new_character_data ~= nil
	if self.is_new_character then
		self.owner.components.charactercreator:SetSpecies(new_character_data.species)
		self.owner.components.charactercreator:LoadFromTable(new_character_data)
	end

	self.debug_mode = debug_mode
	if debug_mode then
		TheSim:LoadPrefabs({ GroupPrefab("deps_player_cosmetics_dev"), })
	end

	-- Showing armor by default
	self.showing_armor = true
	self.was_showing_armor = true -- Used when auto hiding armor

	-- Font sizes
	self.label_font_size = FONTSIZE.SCREEN_TITLE*0.6

	-- A background to darken the underlying village
	self.bg = self:AddChild(Image("images/global/square.tex"))
		:SetName("Background")
		:SetSize(RES_X, RES_Y)
		:SetMultColor(UICOLORS.BACKGROUND_DARK)
		:SetMultColorAlpha(0)

	if self.is_new_character then
		self.bg:SetTexture("images/bg_ChooseCharacterBg/ChooseCharacterBg.tex")
			:SetMultColor(0xFFFFFFff)
			:SetMultColorAlpha(1)
	end

	-- A container that will be animated in
	self.panel_root = self:AddChild(Widget())
		:SetName("Panel root")
		:SetOwningPlayer(owner)  -- in case we didn't set our own above

	-- A panel background
	self.panel_bg = self.panel_root:AddChild(Image("images/bg_CharacterScreenPopupBg/CharacterScreenPopupBg.tex"))
		:SetName("Panel background")
		:SetMultColorAlpha(0)
	self.panel_w, self.panel_h = self.panel_bg:GetSize()

	if self.debug_mode then
		self.debug_label_1 = self.panel_root:AddChild(Text(FONTFACE.DEFAULT, 120, "DEBUG MODE"))
			:SetGlyphColor(UICOLORS.RED)
			:EnableOutline()
			:SetOutlineColor(UICOLORS.BLACK)
			:LayoutBounds("left", "top", self.panel_bg)
			:Offset(500, -100)
		
		self.debug_label_2 = self.panel_root:AddChild(Text(FONTFACE.DEFAULT, 120, "DEBUG MODE"))
			:SetGlyphColor(UICOLORS.RED)
			:EnableOutline()
			:SetOutlineColor(UICOLORS.BLACK)
			:LayoutBounds("right", "top", self.panel_bg)
			:Offset(-500, -100)
	end

	-- The re-roll and armor buttons, which are shown independently of the current mode
	self.reroll_btn = self.panel_root:AddChild(TextButton())
		:SetName("Re-roll button")
		:SetTextSize(self.label_font_size)
		:OverrideLineHeight(self.label_font_size * 0.8)
		:SetText(STRINGS.CHARACTER_CREATOR.REROLL_BUTTON)
		:SetTextColour(UICOLORS.BACKGROUND_DARK)
		:SetTextFocusColour(UICOLORS.FOCUS_DARK)
		:LayoutBounds("center", "center", self.panel_bg)
		:Offset(-self.panel_w/2 + 260, -self.panel_h/2 + 180)
		:SetOnClickFn(function() self:OnRerollClicked() end)
		:SetMultColorAlpha(0)
		:SetShown(false)
		:SetControlUpSound(fmodtable.Event.ui_randomize)
		:SetToolTip(STRINGS.CHARACTER_CREATOR.REROLL_BUTTON_TOOLTIP)

	self.revert_btn = self.panel_root:AddChild(TextButton())
		:SetName("Revert button")
		:SetTextSize(self.label_font_size)
		:OverrideLineHeight(self.label_font_size * 0.8)
		:SetText(STRINGS.CHARACTER_CREATOR.REVERT_BUTTON)
		:SetTextColour(UICOLORS.BACKGROUND_DARK)
		:SetTextFocusColour(UICOLORS.FOCUS_DARK)
		:SetTextDisabledColour(UICOLORS.LIGHT_TEXT_DARK)
		:LayoutBounds("center", "center", self.panel_bg)
		:Offset(self.panel_w/2 - 240, -self.panel_h/2 + 220)
		:SetOnClickFn(function() self:OnRevertClicked() end)
		:SetMultColorAlpha(0)
		:SetShown(false)
		:SetControlUpSound(fmodtable.Event.ui_revert_undo)

	self.armor_btn = self.panel_root:AddChild(TextButton())
		:SetName("Armor button")
		:SetTextSize(self.label_font_size)
		:OverrideLineHeight(self.label_font_size * 0.8)
		:SetText(STRINGS.CHARACTER_CREATOR.SHOWING_ARMOR_BUTTON)
		:SetTextColour(UICOLORS.BACKGROUND_DARK)
		:SetTextFocusColour(UICOLORS.FOCUS_DARK)
		:LayoutBounds("center", "center", self.panel_bg)
		:Offset(-self.panel_w/2 + 180, self.panel_h/2 - 180)
		:SetOnClickFn(function() self:OnArmorClicked() end)
		:SetMultColorAlpha(0)
		:SetShown(false)

	self.customize_character_contents = self.panel_root:AddChild(Widget())
		:SetName("Customize-character contents")
		:SetMultColorAlpha(0)
		:Hide()

	-- Add player puppet
	self.puppet = self.customize_character_contents:AddChild(PlayerPuppet())
		:LayoutBounds("center", "center", self.panel_bg)
		:Offset(-950, -340)
		:SetScale(1.75)
		:SetFacing(FACING_RIGHT)
	self.puppet_shadow = self.customize_character_contents:AddChild(Image("images/ui_ftf_inventory/CharacterShadow.tex"))
		:SetScale(0.85)
		:SetMultColorAlpha(0.08)
		:LayoutBounds("center", "center", self.puppet)
	self.puppet:SendToFront()

	if owner ~= nil then
		if self.is_new_character then
			self.puppet:CloneCharacterAppearance(owner)
		else
			self.puppet:CloneCharacterWithEquipment(owner, true)
		end
		local title_def = Cosmetic.Items["PLAYER_TITLE"][owner.components.playertitleholder:GetTitleKey()]
		self.puppet.components.playertitleholder:SetTitle(title_def)
	end

	self.title_widget = self.customize_character_contents:AddChild(PlayerTitleWidget(self.puppet, FONTSIZE.SCREEN_TEXT))
		:SetScale(2)
		:LayoutBounds("center", "below", self.puppet_shadow)
		:Offset(0, -20)

	-- Add top nav
	self.navbar_height = 150
	self.navbar_root = self.customize_character_contents:AddChild(Widget())
		:SetName("Navbar root")
	self.navbar_bg = self.navbar_root:AddChild(Panel("images/ui_ftf_character/TopTabsBg.tex"))
		:SetName("Navbar bg")
		:SetNineSliceCoords(110, 0, 470, 150)
	self.navbar = self.navbar_root:AddChild(TabGroup())
		:SetName("Navbar")
		:SetTheme_DarkOnLight()
		:SetTabSpacing(70)

	-- Added this here as a temp fix to a weird Lua edge case
	local top_tabs = deepcopy(TOP_TABS)
	self.sub_tabs = deepcopy(SUB_TABS)
	if self.is_new_character then
		-- table.remove(top_tabs, 5)
		-- table.remove(self.sub_tabs, 5)
		table.remove(top_tabs, 1)
		table.remove(self.sub_tabs, 1)
	end

	-- Add tabs
	for k, title in ipairs(top_tabs) do
		local tab = self.navbar:AddTextTab(title, FONTSIZE.CHARACTER_CREATOR_TAB)
		tab.top_tab_index = k
	end
	self.navbar:SetTabOnClick(function(tab_btn) self:OnChangeTab(tab_btn) end)
		:SetNavFocusable(false) -- rely on CONTROL_MAP
		:LayoutChildrenInGrid(100, 50)

	-- Add cycle hotkey icons
	local icon_size = 60
	local icon_margin = 60
	self.navbar:AddCycleIcons(icon_size, icon_margin, UICOLORS.LIGHT_TEXT_DARK)

	-- Resize navbar background to tabs
	local w, h = self.navbar:GetSize()
	self.navbar_bg:SetSize(w + 560, self.navbar_height)
		:LayoutBounds("center", "center", self.navbar)
	self.navbar_root:LayoutBounds("center", "top", self.panel_bg)
		:Offset(0, -20)

	-- List background
	self.list_width, self.list_height = 1750, 900
	self.list_bg = self.customize_character_contents:AddChild(Panel("images/ui_ftf_character/ListBg.tex"))
		:SetName("List bg")
		:SetNineSliceCoords(106, 0, 157, 900)
		:SetSize(self.list_width+100, self.list_height)
		:SetMultColorAlpha(0.2)
		:LayoutBounds("center", "center", self.panel_bg)
		:Offset(500, 40)
	-- List scroll panel
	self.scroll = self.customize_character_contents:AddChild(ScrollPanel())
		:SetSize(self.list_width, self.list_height)
		:SetVirtualMargin(50)
		:LayoutBounds("center", "center", self.list_bg)
		:SetCanPageUpDown(false) -- same key as change tabs
	self.scroll_contents = self.scroll:AddScrollChild(Widget())

	-- Add subnav bg
	self.subnav_height = 110
	self.subnav_bg = self.customize_character_contents:AddChild(Panel("images/ui_ftf_character/BottomTabsBg.tex"))
		:SetName("Subnav bg")
		:SetNineSliceCoords(16, 0, 546, 110)
	self.subnav = self.customize_character_contents:AddChild(TabGroup())
		:SetName("Subnav")
		:SetTheme_DarkOnLight()
		:SetTabSpacing(60)
		:SetNavFocusable(false) -- rely on CONTROL_MAP
		:SetIsSubTab(true)

	-- Species description
	self.customize_character_description = self.customize_character_contents:AddChild(Text(FONTFACE.DEFAULT, self.label_font_size))
		:SetName("Customize-character description")
		:SetGlyphColor(UICOLORS.LIGHT_TEXT_DARK)

	-- Color chooser
	self.color_elements_list = self.customize_character_contents:AddChild(Widget("Color Options"))

	----------------------------------------------------------------------------------------
	-- Add buttons container below the panel
	self.buttons = self:AddChild(Widget("Buttons container"))

	-- And continue button
	self.continue_btn = self.buttons:AddChild(templates.Button(STRINGS.CHARACTER_CREATOR.CONTINUE_BUTTON))
		:SetPrimary()
		:SetNineSliceBorderScale(0.9)
		:SetSize(BUTTON_W, BUTTON_H*1.3)
		:SetOnClick(function() self:OnContinueClicked() end)
		:SetMultColorAlpha(0)
		:Hide()
		:SetControlUpSound(fmodtable.Event.ui_input_up_play)

	-- Close button in the corner
	self.close_button = self:AddChild(ImageButton("images/ui_ftf/HeaderClose.tex"))
		:SetNavFocusable(false) -- rely on CONTROL_MAP
		:SetSize(BUTTON_SQUARE_SIZE, BUTTON_SQUARE_SIZE)
		:LayoutBounds("right", "top", self.panel_bg)
		:Offset(-45, 10)
		:SetOnClick(function() self:OnCloseClicked() end)
		:Hide()

	----------------------------------------------------------------------------------------
	-- Store the default positions of the two panels
	self.customize_character_contents.start_x, self.customize_character_contents.start_y = self.customize_character_contents:GetPos()

	----------------------------------------------------------------------------------------

	----------------------------------------------------------------------------------------
	-- Set default focus widget
	self.default_focus = self.continue_btn

	self:CheckForChanges()

	-- Load the player's armor and equip it
	self:_ShowArmor()
end)

function CharacterScreen.DebugConstructScreen(cls, player, ...)
	return cls(player, ...)
end

CharacterScreen.CONTROL_MAP =
{
	{
		control = Controls.Digital.MENU_SCREEN_ADVANCE,
		hint = function(self, left, right)
			table.insert(right, loc.format(LOC"UI.CONTROLS.ACCEPT", Controls.Digital.MENU_SCREEN_ADVANCE))
		end,
		fn = function(self)
			if self.continue_btn:IsShown() then
				TheFrontEnd:GetSound():PlaySound(fmodtable.Event.ui_input_up_play)
				self.continue_btn:SetFocus()
				return true
			end
		end,
	},
	{
		control = Controls.Digital.MENU_TAB_PREV,
		hint = function(self, left, right)
			table.insert(right, loc.format(LOC"UI.CONTROLS.PREV_TAB", Controls.Digital.MENU_TAB_PREV))
		end,
		fn = function(self)
			self:NextTab(-1)
			TheFrontEnd:GetSound():PlaySound(fmodtable.Event.input_down)
			return true
		end,
	},
	{
		control = Controls.Digital.MENU_TAB_NEXT,
		hint = function(self, left, right)
			table.insert(right, loc.format(LOC"UI.CONTROLS.NEXT_TAB", Controls.Digital.MENU_TAB_NEXT))
		end,
		fn = function(self)
			self:NextTab(1)
			TheFrontEnd:GetSound():PlaySound(fmodtable.Event.input_down)
			return true
		end,
	},
	{
		control = Controls.Digital.MENU_SUB_TAB_PREV,
		hint = function(self, left, right)
			table.insert(right, loc.format(LOC"UI.CONTROLS.PREV_TAB", Controls.Digital.MENU_SUB_TAB_PREV))
		end,
		fn = function(self)
			self.subnav:NextTab(-1)
			TheFrontEnd:GetSound():PlaySound(fmodtable.Event.input_down)
			return true
		end,
	},
	{
		control = Controls.Digital.MENU_SUB_TAB_NEXT,
		hint = function(self, left, right)
			table.insert(right, loc.format(LOC"UI.CONTROLS.NEXT_TAB", Controls.Digital.MENU_SUB_TAB_PREV))
		end,
		fn = function(self)
			self.subnav:NextTab(1)
			TheFrontEnd:GetSound():PlaySound(fmodtable.Event.input_down)
			return true
		end,
	},
	{
		control = Controls.Digital.CANCEL,
		hint = function(self, left, right)
			table.insert(right, loc.format(LOC"UI.CONTROLS.CANCEL", Controls.Digital.CANCEL))
		end,
		fn = function(self)
			if not self.is_new_character then
				self:OnCloseClicked()
			end
			return true
		end,
	},
}

-------------------------------------------------------------------------------------
-- Button functions
-------------------------------------------------------------------------------------
function CharacterScreen:OnCloseClicked()
	if self:IsCharacterEqual() then
		TheFrontEnd:PopScreen(self)
	else
		self:OnContinueClicked()
		-- local popup = ConfirmDialog(self:GetOwningPlayer(), nil, true,
		-- 	STRINGS.CHARACTER_CREATOR.UNSAVED_POPUP_TITLE,
		-- 	nil,
		-- 	STRINGS.CHARACTER_CREATOR.UNSAVED_POPUP_DESC
		-- 	):SetYesButton(STRINGS.CHARACTER_CREATOR.UNSAVED_POPUP_YES, function()
		-- 		TheFrontEnd:PopScreen()
		-- 		TheFrontEnd:PopScreen(self)
		-- 	end)
		-- 	:SetNoButton(STRINGS.CHARACTER_CREATOR.UNSAVED_POPUP_NO, function()
		-- 		TheFrontEnd:PopScreen()
		-- 	end)
		-- 	:HideArrow()
		-- 	:SetMinWidth(600)
		-- 	:CenterText()
		-- 	:CenterButtons()
		
		-- TheFrontEnd:PushScreen(popup)
	end
end

-- Added due to some issues with the tab refreshing and elements losing focus and trying to Clear the preview
-- Currently missing dye data
function CharacterScreen:ForceResetPreviewData()
	self.current_species = nil
	self.current_data = nil
	self.current_bodypart_group = nil 
	self.current_bodypart_name = nil
	self.current_colorgroup = nil
	self.current_color_name = nil
end

-- Randomize button clicked
function CharacterScreen:OnRerollClicked()
	local current_species = self.puppet.components.charactercreator:GetSpecies()
	if self.is_new_character then
		current_species = nil
	end

	self.puppet.components.charactercreator:Randomize(current_species, self.owner)

	local unlocked_titles = self.owner.components.unlocktracker:GetAllUnlockedCosmetics("PLAYER_TITLE")
	local picked_title = Cosmetic.Items["PLAYER_TITLE"][krandom.PickFromArray(unlocked_titles)]
	
	self:ForceResetPreviewData()

	self.puppet.components.playertitleholder:SetTitle(picked_title)
	self.title_widget:Refresh() -- Due to some event fuckery in the UI we gotta refresh this manually

	self:RefreshTab()
	self:CheckForChanges()

	self.reroll_btn:SetFocus()
end

function CharacterScreen:OnRevertClicked()
	local owner_data = self.owner.components.charactercreator:SaveToTable()

	self.puppet.components.charactercreator:SetSpecies(owner_data.species)
	self.puppet.components.charactercreator:LoadFromTable(owner_data)

	local owner_title_key = self.owner.components.playertitleholder:GetTitleKey()
	self.puppet.components.playertitleholder:SetTitle(Cosmetic.Items["PLAYER_TITLE"][owner_title_key])
	self.title_widget:Refresh() -- Due to some event fuckery in the UI we gotta refresh this manually

	for _, slot in ipairs(Cosmetic.DyeSlots) do
		local set = self.owner.components.inventory.equips[slot]
		local active_dye = self.owner.components.equipmentdyer:GetActiveDye(slot, set)
		local dye_name = active_dye ~= nil and active_dye.short_name or nil

		self.puppet.components.equipmentdyer:SetEquipmentDye(slot, set, dye_name)
	end

	self:RefreshTab()
	self:CheckForChanges()
end

-- Toggles the puppets between showing armor to not
function CharacterScreen:OnArmorClicked()
	self.showing_armor = not self.showing_armor
	if self.showing_armor then
		self:_ShowArmor()
	else
		self:_HideArmor()
	end
	-- Used to auto turn armor off in certain categories
	self.was_showing_armor = self.showing_armor
end

function CharacterScreen:ApplyChanges()
	local data = self.puppet.components.charactercreator:SaveToTable()
	self.owner.components.charactercreator:SetSpecies(data.species)
	self.owner.components.charactercreator:LoadFromTable(data)

	local title_key = self.puppet.components.playertitleholder:GetTitleKey()
	if title_key ~= self.owner.components.playertitleholder:GetTitleKey() then
		self.owner.components.playertitleholder:SetTitle(Cosmetic.Items["PLAYER_TITLE"][title_key])
	end

	for _, slot in ipairs(Cosmetic.DyeSlots) do
		local set = self.puppet.components.inventory.equips[slot]
		local active_dye = self.puppet.components.equipmentdyer:GetActiveDye(slot, set)
		local dye_name = active_dye ~= nil and active_dye.short_name or nil
		self.owner.components.equipmentdyer:SetEquipmentDye(slot, set, dye_name)
	end

	TheSaveSystem:SaveCharacterForPlayerID(self.owner.Network:GetPlayerID())
end

function CharacterScreen:OnContinueClicked()
	local wait_for_save_popup = WaitingDialog()
		:SetTitle(STRINGS.UI.NOTIFICATION.SAVING)
	TheFrontEnd:PushScreen(wait_for_save_popup)

	local data = self.puppet.components.charactercreator:SaveToTable()
	self.owner.components.charactercreator:SetSpecies(data.species)
	self.owner.components.charactercreator:LoadFromTable(data)

	local title_key = self.puppet.components.playertitleholder:GetTitleKey()
	if title_key ~= self.owner.components.playertitleholder:GetTitleKey() then
		self.owner.components.playertitleholder:SetTitle(Cosmetic.Items["PLAYER_TITLE"][title_key])
	end

	for _, slot in ipairs(Cosmetic.DyeSlots) do
		local set = self.puppet.components.inventory.equips[slot]
		local active_dye = self.puppet.components.equipmentdyer:GetActiveDye(slot, set)
		local dye_name = active_dye ~= nil and active_dye.short_name or nil

		self.owner.components.equipmentdyer:SetEquipmentDye(slot, set, dye_name)
	end

	local playerID = self.owner.Network:GetPlayerID()
	TheSaveSystem:SaveCharacterForPlayerID(playerID, function()
		TheFrontEnd:PopScreen(wait_for_save_popup)
		if self.on_close_cb then
			self.on_close_cb(self.owner)
		end

		TheFrontEnd:PopScreen(self)
	end)
end

-------------------------------------------------------------------------------------
-- Animate Functions
-------------------------------------------------------------------------------------

function CharacterScreen:_AnimatePanelIn(panel, on_done)
	panel:SetMultColorAlpha(0)
		:Show()
		:AlphaTo(1, 0.05, easing.outQuad)
		:SetPos(panel.start_x, panel.start_y - 40)
		:MoveTo(panel.start_x, panel.start_y, 0.15, easing.outQuad, on_done)
end

function CharacterScreen:_AnimatePanelOut(panel, on_done)
	panel:AlphaTo(0, 0.05, easing.outQuad, function() panel:Hide() end)
		:MoveTo(panel.start_x, panel.start_y + 10, 0.05, easing.outQuad, on_done)
end

-- Animates in the continue_btn
function CharacterScreen:_AnimateStartButtonIn(on_done)
	self.continue_btn:SetMultColorAlpha(0)
		:Show()
		:RefreshText()

	self.buttons:LayoutBounds("center", "below", self.panel_bg)
		:Offset(0, -10)

	-- Get their positions
	self.continue_btn.start_x, self.continue_btn.start_y = self.continue_btn:GetPos()

	-- Fade out the buttons
	self.continue_btn:SetMultColorAlpha(0):Show()

	-- Animate each button in
	local timing = 0.4
	self:RunUpdater(
		Updater.Parallel({
			-- Animate in the start button first
			Updater.Ease(function(y) self.continue_btn:SetPos(self.continue_btn.start_x, y) end, self.continue_btn.start_y - 30, self.continue_btn.start_y, timing, easing.outElastic),
			Updater.Ease(function(a) self.continue_btn:SetMultColorAlpha(a) end, 0, 1, timing/2, easing.outQuad),

			Updater.Series({
				Updater.Wait(0.15),
				-- Invoke callback, if any
				Updater.Do(function()
					if on_done then on_done() end
				end)
			})
		})
	)
end

-- Animates in the continue_btn
function CharacterScreen:_AnimateSpeciesDescription(species)
	-- Only spool text if choosing character species
	-- The sound can be heard even if the widgets aren't shown
	-- And on the customize-character one
	self.customize_character_description:SetText("")
		:Show()
		:SetText(STRINGS.CHARACTER_CREATOR.CHARACTER_DESC:subfmt({
			species_desc = STRINGS.SPECIES_DESCRIPTIONS[species]
		}))
		:LayoutBounds("center", "below", self.list_bg)
		:Offset(0, -50)
		:Spool(100)
end

function CharacterScreen:_AnimateIn()
	self.panel_root:RunUpdater(Updater.Parallel{
		Updater.Ease(function(v) 
				if not self.is_new_character then
					self.bg:SetMultColorAlpha(v)
				end
			end, self.bg:GetMultColorAlpha(), 0.4, 0.6, easing.outQuad),
		Updater.Series{
			Updater.Wait(0.3),
			Updater.Parallel{
				-- Animate in the background
				Updater.Ease(function(v) self.panel_bg:SetMultColorAlpha(v) end, 0, 1, 0.4, easing.outQuad),
				Updater.Ease(function(v) self.panel_bg:SetPos(nil, v) end, -40, 0, 0.6, easing.outElastic),
				-- And the corner buttons
				Updater.Ease(function(v) self.reroll_btn:SetMultColorAlpha(v) end, 0, 1, 0.6, easing.outQuad),
				Updater.Ease(function(v) self.revert_btn:SetMultColorAlpha(v) end, 0, 1, 0.6, easing.outQuad),
				Updater.Ease(function(v) self.armor_btn:SetMultColorAlpha(v) end, 0, 1, 0.6, easing.outQuad),
			}
		},

		Updater.Series{
			Updater.Wait(0.5),
			Updater.Do(function()
				local species_tab_index = self.is_new_character and 1 or 2
				self.navbar:OpenTabAtIndex(species_tab_index) -- Species Tab
				self:_AnimatePanelIn(self.customize_character_contents)
				self:_AnimateStartButtonIn()
				self.revert_btn:Show()
				self.reroll_btn:Show()
				self.armor_btn:Show()
				if not self.is_new_character then
					self.close_button:Show()
				end
			end)
		}
	})

	return self
end

-------------------------------------------------------------------------------------
-- Event handlers
-------------------------------------------------------------------------------------

function CharacterScreen:OnBecomeActive()
	CharacterScreen._base.OnBecomeActive(self)

	if not self.owner or not self.owner:IsValid() then
		-- Likely player disconnected gamepad and then removed our player when
		-- PlayersScreen popped up. They're not fully created, so remove them
		-- from active players.
		TheSaveSystem:OnLocalPlayerLeave(self.owner_player_id)
		TheFrontEnd:PopScreen(self) -- Not self:OnCloseClicked() because that allows cancel.
		return
	end

	if not self.animated_in then
		local species_tab_index = self.is_new_character and 1 or 2
		self.navbar:OpenTabAtIndex(species_tab_index)
		self.continue_btn:SetFocus()

		self:_AnimateIn()
		self.animated_in = true
	end
end

function CharacterScreen:OnBecomeInactive()
	CharacterScreen._base.OnBecomeInactive(self)
	TheAudio:StopPersistentSound(audioid.persistent.ui_music)
end

--------------------------------------------------------------------------------------
-- Tab Functions
--------------------------------------------------------------------------------------

function CharacterScreen:NextTab(direction)
	if self.navbar:IsVisible() then
		self.navbar:NextTab(direction)
	end
end

function CharacterScreen:RefreshTab()
	local current_subnav_idx = self.subnav:GetCurrentIdx()
	self.navbar:OpenTabAtIndex(self.navbar:GetCurrentIdx())
	self.subnav:OpenTabAtIndex(current_subnav_idx)
end

function CharacterScreen:FocusFirstElement()
	if #self.scroll_contents.children > 0 then
		self.scroll_contents.children[1]:SetFocus()
	end
end

function CharacterScreen:OnChangeTab(tab_button)
	-- Remove old content
	self.scroll_contents:RemoveAllChildren()
	self.subnav:RemoveAllTabs()

	-- Get the top-tab index
	local top_tab_index = tab_button.top_tab_index
	local sub_tabs = self.sub_tabs[top_tab_index]

	local is_title = top_tab_index == 1 and not self.is_new_character
	local is_dye = false -- top_tab_index == 5 and not self.is_new_character

	-- Show the correct sub-tabs
	local new_tab_id
	for k, id in ipairs(sub_tabs) do

		--jcheng: see if there are multiple items, if not, don't display it
		local bodypart_list = self.puppet.components.charactercreator:GetBodyPartList(id, true)
		bodypart_list = self:SortBodyPartList(bodypart_list, id)

		local bodypart_count = 0
		for i, def in ipairs(bodypart_list) do
			-- Check if this part is locked
			local is_locked = not self.owner.components.unlocktracker:IsCosmeticUnlocked(def.name, "PLAYER_BODYPART")

			if not is_locked then
				bodypart_count = bodypart_count + 1
			end
		end

		--only show the tabs if it's the head, title, or if you have more than one option or if it's debug mode
		if bodypart_count > 1 or is_title or id == Cosmetic.BodyPartGroups.HEAD or self.debug_mode then
			-- Keep the first tab as the new one
			if not new_tab_id then
				new_tab_id = id
			end

			local txt
			if is_title then
				txt = "PLAYER_TITLE"
			elseif is_dye then
				txt = string.upper(STRINGS.ITEM_CATEGORIES[id])
			else
				txt = string.upper(STRINGS.BODY_PARTS[id])
			end

			-- Add tabs to subnav
			local tab = self.subnav:AddTextTab(txt, self.label_font_size)
			tab.body_tab_id = id
		end
	end

	if is_title then
		if self.showing_armor ~= self.was_showing_armor then
			self:OnArmorClicked()
		end
	elseif is_dye then
		self:_ShowArmor()
	end

	self.subnav:AddCycleIcons(50, 40, UICOLORS.LIGHT_TEXT_DARK)

	-- Layout tabs
	self.subnav:SetTabOnClick(function(tab_btn) self:OnChangeSubTab(tab_btn) end)

	-- Resize navbar background to tabs
	local w, h = self.subnav:GetSize()
	self.subnav_bg:SetScale(1, 1)
		:SetSize(w + 280, self.subnav_height)
		:LayoutBounds("center", "above", self.list_bg)
		:Offset(0, -1)
		:SetScale(1, -1)
	self.subnav:LayoutBounds("center", "center", self.subnav_bg)
		:Offset(0, -2)

	-- Select the first sub tab
	self.subnav:OpenTabAtIndex(1)

	-- If there is only one tab (for species), hide the subnav
	self.subnav_bg:SetShown(#sub_tabs > 1)
	self.subnav:SetShown(#sub_tabs > 1)

	local is_species_tab = (self.is_new_character and top_tab_index == 1) or top_tab_index == 2

	-- And show the species description
	if is_species_tab then
		self:_AnimateSpeciesDescription(self.puppet.components.charactercreator:GetSpecies())
	else
		self.customize_character_description:Hide()
	end

	self:FocusFirstElement()
end

function CharacterScreen:OnChangeSubTab(sub_tab)
	if sub_tab.body_tab_id == "PLAYER_TITLE" then
		self:GenerateTitleList()
		return
	elseif self.navbar:GetCurrentIdx() == 5 then -- HACK
		self:GenerateArmorDyeList(sub_tab.body_tab_id)
		return
	end

	self:ClearColorPreview()

	-- Generate the list of body parts upon selecting a body part category
	self:GenerateBodyPartList(sub_tab.body_tab_id)

	if sub_tab.body_tab_id == Cosmetic.BodyPartGroups.SHIRT or sub_tab.body_tab_id == Cosmetic.BodyPartGroups.UNDIES then
	 	self:_HideArmor()
	else
		if self.showing_armor ~= self.was_showing_armor then
			self:OnArmorClicked()
		end
	end	

	-- If this part supports colors, show them
	if BODY_PART_COLOR_MAP[sub_tab.body_tab_id] then
		-- Display available colors
		self:GenerateColorList(BODY_PART_COLOR_MAP[sub_tab.body_tab_id])

		-- Select active color
		local active_color = self.puppet.components.charactercreator:GetColor(BODY_PART_COLOR_MAP[sub_tab.body_tab_id])
		for k, btn in ipairs(self.color_elements_list.children) do
			btn:SetSelected(active_color == btn:GetItemColorId())
		end

	else
		-- Remove old colors
		self.color_elements_list:RemoveAllChildren()
	end

	self:FocusFirstElement()
end

----------------------------------------------------------------------------------------------------
-- Preview Functions
----------------------------------------------------------------------------------------------------

function CharacterScreen:SpeciesPreview(species)
	self.current_species = self.puppet.components.charactercreator:GetSpecies()
	self.current_data = self.puppet.components.charactercreator:SaveToTable()
	
	for i, data in ipairs(DEFAULT_CHARACTERS_SETUP) do
		if data.species == species then
			self.puppet.components.charactercreator:SetSpecies(species)
			self.puppet.components.charactercreator:LoadFromTable(data)
		end
	end
end

function CharacterScreen:ClearSpeciesPreview()
	if self.current_species ~= nil and self.current_data ~= nil then
		self.puppet.components.charactercreator:SetSpecies(self.current_species)
		self.puppet.components.charactercreator:LoadFromTable(self.current_data)
	end
end

function CharacterScreen:BodyPartPreview(group, name)
	self.current_bodypart_group = group
	self.current_bodypart_name = self.puppet.components.charactercreator:GetBodyPart(group)
	self.puppet.components.charactercreator:SetBodyPart(group, name)
end

function CharacterScreen:ClearBodyPartPreview()
	if self.current_bodypart_group ~= nil and self.current_bodypart_name ~= nil then
		self.puppet.components.charactercreator:SetBodyPart(self.current_bodypart_group, self.current_bodypart_name)
	end
	self.current_bodypart_group = nil
	self.current_bodypart_name = nil
end

function CharacterScreen:ColorPreview(group, name)
	self.current_colorgroup = group
	self.current_color_name = self.puppet.components.charactercreator:GetColor(group)
	self.puppet.components.charactercreator:SetColorGroup(group, name)
end

function CharacterScreen:ClearColorPreview()
	if self.current_colorgroup ~= nil and self.current_color_name ~= nil then
		self.puppet.components.charactercreator:SetColorGroup(self.current_colorgroup, self.current_color_name)
	end
	self.current_colorgroup = nil
	self.current_color_name = nil
end

function CharacterScreen:DyePreview(def, armorslot)
	local equipped_dye = self.puppet.components.equipmentdyer:GetActiveDye(armorslot, def.armour_set)
	self.current_dye_slot = armorslot
	self.current_dye_set = def.armour_set
	self.current_dye_name = equipped_dye ~= nil and equipped_dye.short_name or nil

	self.puppet.components.equipmentdyer:SetEquipmentDye(armorslot, def.armour_set, def.short_name)
end

function CharacterScreen:ClearDyePreview()
	self.puppet.components.equipmentdyer:SetEquipmentDye(self.current_dye_slot, self.current_dye_set, self.current_dye_name)
	self.current_dye_slot = nil
	self.current_dye_set = nil
	self.current_dye_name = nil
end

function CharacterScreen:TitlePreview(def)
	self.title_widget:ForceTitleText(STRINGS.COSMETICS.TITLES[def.title_key])
end

function CharacterScreen:ClearTitlePreview(def)
	self.title_widget:Refresh()
end

----------------------------------------------------------------------------------------------------
-- Sort Functions
----------------------------------------------------------------------------------------------------

function CharacterScreen:SortCosmeticList(list, category, getactivefn, uitagsortfn, itemstatusfn)
	
	if itemstatusfn == nil then
		itemstatusfn = function (item)
			local unlocked = self.owner.components.unlocktracker:IsCosmeticUnlocked  (item.name, category)
			return unlocked
		end
	end

	if #list == 0 then
		return list
	end

	local unlocked = lume.filter(list, function(item)
		local unlocked = itemstatusfn(item)
		return unlocked
	end)

	if uitagsortfn then
		unlocked = lume.sort(unlocked, uitagsortfn)
	end

	local active_item_name = getactivefn()
	local index = -1
	for i, def in ipairs(unlocked) do
		if active_item_name == def.name then
			index = i
			break
		end
	end
	if index ~= -1 then
		local active_item = table.remove(unlocked, index)
		table.insert(unlocked, 1, active_item)
	end

	if self.is_new_character then
		return unlocked
	end

	local locked = lume.filter(list, function(item)
		local unlocked = itemstatusfn(item)
		return not unlocked
	end)
	
	if uitagsortfn then
		locked = lume.sort(locked, uitagsortfn)
	end

	if self.debug_mode then
		return lume.concat(unlocked, locked)
	end

	return lume.concat(unlocked)
end

function CharacterScreen:SortBodyPartList(list, bodypart)
	local function UITagSorting(a, b) -- UI Tag sorting
		if not a.uitags.blank and not b.uitags.blank then
			return a.name < b.name
		end
		return false
	end

	local function GetActiveBodyPart()
		return self.puppet.components.charactercreator:GetBodyPart(bodypart)
	end

	return self:SortCosmeticList(list, "PLAYER_BODYPART", GetActiveBodyPart, UITagSorting)
end

function CharacterScreen:SortTitleList(list)
	local function GetActiveTitle()
		return self.puppet.components.playertitleholder:GetTitleKey()
	end

	return self:SortCosmeticList(list, "PLAYER_TITLE", GetActiveTitle)
end

function CharacterScreen:SortColorList(list, colorgroup)
	local function GetActiveColor()
		return self.puppet.components.charactercreator:GetColor(colorgroup)
	end

	return self:SortCosmeticList(list, "PLAYER_COLOR", GetActiveColor)
end

function CharacterScreen:SortDyeList(list, armour_slot, armour_set)
	local function GetDyeStatus(item)
		if item.name == "NONE" then
			return true, true
		end

		local unlocked = self.owner.components.unlocktracker:IsCosmeticUnlocked  (item.armour_slot, item.short_name)
		return unlocked
	end

	local function GetActiveDye()
		local active_dye = self.puppet.components.equipmentdyer:GetActiveDye(armour_slot, armour_set)
		if active_dye == nil then
			active_dye = "NONE"
		end
		return active_dye
	end

	return self:SortCosmeticList(list, "", GetActiveDye, nil, GetDyeStatus)
end

-------------------------------------------------------------------------------------
-- Content Generation Functions
-------------------------------------------------------------------------------------

function CharacterScreen:ElementTooltipFn(debug_mode, def, is_head, is_locked, is_purchasable)
	if debug_mode then
		local status = is_locked and "\nLOCKED" or "\n UNLOCKED"
		return def.name .. status
	elseif is_head then
		if is_purchasable then
			if self.owner.components.inventoryhoard:GetStackableCount(Consumable.Items.MATERIALS.konjur_soul_lesser) >= SPECIES_CHANGE_COST then
				return string.format(STRINGS.CHARACTER_CREATOR.BUY_SPECIES_TT, SPECIES_CHANGE_COST)
			else
				return STRINGS.CHARACTER_CREATOR.NOT_ENOUGH_TT
			end
		else
			return STRINGS.SPECIES_DESCRIPTIONS[def.species]
		end
	elseif is_locked then
		return STRINGS.CHARACTER_CREATOR.LOCKED_TOOLTIP
	end

	return nil
end

function CharacterScreen:GenerateBodyPartList(bodypart)
	local is_head = bodypart == Cosmetic.BodyPartGroups.HEAD

	-- Remove old list items
	self.scroll_contents:RemoveAllChildren()

	local bodypart_list = self.puppet.components.charactercreator:GetBodyPartList(bodypart, not is_head)
	bodypart_list = self:SortBodyPartList(bodypart_list, bodypart)

	local bodypart_elements_list = {}
	local image_w = 320

	-- Individual pieces for a body part type
	for i, def in ipairs(bodypart_list) do
		-- Check if this part is locked
		local is_locked = not self.owner.components.unlocktracker:IsCosmeticUnlocked(def.name, "PLAYER_BODYPART")
		local is_purchasable = false

		if is_head and not self.is_new_character  then
			is_purchasable = self.puppet.components.charactercreator:GetSpecies() ~= def.species
		end

		-- Add button
		local bodypart_element = self.scroll_contents:AddChild(SelectableBodyPart(image_w))
			:SetBodyPartId(def.name) -- TODO @H: pass the whole def here
			:SetSelected(i == 1)
			:SetLocked(is_locked)
			:SetPurchasable(is_purchasable, SPECIES_CHANGE_COST)
			
		bodypart_element:SetOnClick(function()
			if self.debug_mode and not is_head then
				--is_locked = self:Debug_UpdateAvailability(bodypart_element, def.name, "PLAYER_BODYPART")
				ui:SetClipboardText(def.name)
				TheFrontEnd:ShowTextNotification("images/ui_ftf_notifications/clipboard.tex", "Copied", def.name, 3)
			elseif is_head and is_purchasable then
				if self.owner.components.inventoryhoard:GetStackableCount(Consumable.Items.MATERIALS.konjur_soul_lesser) >= SPECIES_CHANGE_COST then
					self:OnSwitchSpecies(bodypart, def)
				end
			elseif not is_locked then
				self:OnBodyPartElementSelected(bodypart, def)
			end
		end)

		bodypart_element:SetOnGainFocus(function()
			bodypart_element:OnFocusChange(true)
			if is_head then
				if self.puppet.components.charactercreator:GetSpecies() ~= def.species then
					self:SpeciesPreview(def.species)
				end
			elseif not is_locked and not bodypart_element:IsSelected() then
				self:BodyPartPreview(bodypart, def.name)
			end
		end)
		:SetOnLoseFocus(function()
			bodypart_element:OnFocusChange(false)
			if is_head then
				if self.current_species ~= def.species and not self.unlocking_species then
					self:ClearSpeciesPreview()
				end
			else
				if not bodypart_element:IsSelected() then
					self:ClearBodyPartPreview()
				end
			end
		end)

		bodypart_element:SetToolTipFn(function()
			return self:ElementTooltipFn(self.debug_mode, def, is_head, is_locked, is_purchasable)
		end)
		:ShowToolTipOnFocus(true)

		
		if not is_head or self.puppet.components.charactercreator:GetSpecies() == def.species then
			bodypart_element:CloneCharacterAppearance(self.puppet)
		else
			bodypart_element:SetPuppetSpecies(def.species)
			for i, data in ipairs(DEFAULT_CHARACTERS_SETUP) do
				if data.species == def.species then
					bodypart_element:SetCharacterData(data)
				end
			end
		end

		-- if not i == 1 and not is_locked then
		-- 	bodypart_element:HighlightBodyPart(bodypart)
		-- end

		-- (TEMP) Store part BG to reference later; sort of a workaround to have the vertical spacing of the grid work correctly.
		-- LayoutChildrenInGrid() doesn't vertical space things out 'correctly' due to the partAnims being scaled...
		table.insert(bodypart_elements_list, bodypart_element)
	end

	self.scroll_contents:LayoutInDiagonal(3, 60, 60)
		:SetPosition(-self.list_width/2 + image_w, -image_w/2)
	self.scroll:RefreshView()

	self.colorize_puppets = {}
	local current_head = self.puppet.components.charactercreator:GetBodyPart(Cosmetic.BodyPartGroups.HEAD)
	for i, def in ipairs(bodypart_list) do

		local xform_part = BODY_PART_SPECIES_REMAP[bodypart] and BODY_PART_SPECIES_REMAP[bodypart][current_head] or bodypart
		local xform = BODY_PART_TRANSFORM[xform_part]
		assert(xform, bodypart)

		-- Update body part representation within button
		bodypart_elements_list[i]:SetPuppetOffset(xform.offset:unpack())
			:SetPuppetScale(xform.scale)

		-- if not is_head then
		-- 	bodypart_elements_list[i]:SetPuppetBodyPart(Cosmetic.BodyPartGroups.HEAD, current_head)
		-- end
		bodypart_elements_list[i]:SetPuppetBodyPart(bodypart, def.name)

		-- Don't colorize heads because they share palettes we don't want
		-- canine head color applied to mer.
		if not is_head and not self.debug_mode then
			bodypart_elements_list[i]:HighlightBodyPart(bodypart)
			table.insert(self.colorize_puppets, bodypart_elements_list[i]:GetPuppet())
		end
	end

	-- Curent part's color
	local selectedPart = self.puppet.components.charactercreator:GetBodyPart(bodypart)
	local def = Cosmetic.BodyParts[bodypart][selectedPart]
	if def ~= nil and def.colorgroup ~= nil then
		self:ApplyColorToPartsList(def.colorgroup, self.puppet.components.charactercreator:GetColor(def.colorgroup))
	end
	-- Body color comes from head
	def = Cosmetic.BodyParts.HEAD[current_head]
	if def ~= nil and def.colorgroup ~= nil then
		self:ApplyColorToPartsList(def.colorgroup, self.puppet.components.charactercreator:GetColor(def.colorgroup))
	end
end

function CharacterScreen:OnSwitchSpecies(bodypart, def)
	self.unlocking_species = true
	local popup = ConfirmDialog(self:GetOwningPlayer(), nil, true,
		STRINGS.CHARACTER_CREATOR.SWITCH_SPECIES_POPUP_TITLE,
		nil,
		string.format(STRINGS.CHARACTER_CREATOR.SWITCH_SPECIES_POPUP_DESC, SPECIES_CHANGE_COST)
		):SetYesButton(STRINGS.CHARACTER_CREATOR.UNSAVED_POPUP_YES, function()
			self:OnBodyPartElementSelected(bodypart, def)
			self:GenerateBodyPartList(bodypart)
			self:ApplyChanges()
			self:CheckForChanges()
			self.owner.components.inventoryhoard:RemoveStackable(Consumable.Items.MATERIALS.konjur_soul_lesser, SPECIES_CHANGE_COST)
			TheFrontEnd:PopScreen()
			self.unlocking_species = nil
		end)
		:SetNoButton(STRINGS.CHARACTER_CREATOR.UNSAVED_POPUP_NO, function()
			self.unlocking_species = nil
			TheFrontEnd:PopScreen()
		end)
		:HideArrow()
		:SetMinWidth(600)
		:CenterText()
		:CenterButtons()
		
	TheFrontEnd:PushScreen(popup)
end

function CharacterScreen:OnBodyPartElementSelected(bodypart, def)
	local selected_btn = nil

	self.current_bodypart_group = nil
	self.current_bodypart_name =  nil

	-- Set this button as selected
	for k, btn in ipairs(self.scroll_contents.children) do
		if def.name == btn:GetBodyPartId() then
			btn:SetSelected(true)
			selected_btn = btn
		else
			btn:SetSelected(false)
		end
	end

	if bodypart == Cosmetic.BodyPartGroups.HEAD then
		self.puppet.components.charactercreator:SetSpecies(def.species)
		self.puppet.components.charactercreator:LoadFromTable(selected_btn.puppet.components.charactercreator:SaveToTable())
		self:_AnimateSpeciesDescription(self.puppet.components.charactercreator:GetSpecies())

		self.current_species = nil
		self.current_data = nil
	end
	
	-- Change the body part
	self.puppet.components.charactercreator:SetBodyPart(bodypart, def.name)

	if bodypart == Cosmetic.BodyPartGroups.HEAD and BODY_PART_COLOR_MAP[bodypart] then
		self.color_elements_list:RemoveAllChildren()
		self:GenerateColorList(BODY_PART_COLOR_MAP[bodypart])
	end

	self:CheckForChanges()
end

function CharacterScreen:GenerateColorList(colorgroup)
	-- Remove old colors
	self.color_elements_list:RemoveAllChildren()

	local species = self.puppet.components.charactercreator:GetSpecies()
	if COLOR_EXCEPTIONS[species] and table.contains(COLOR_EXCEPTIONS[species], self.subnav.current.body_tab_id)  then
		return
	end

	-- Add new ones
	local colors_list = self.puppet.components.charactercreator:GetColorList(colorgroup, true)
	colors_list = self:SortColorList(colors_list, colorgroup)

	if colors_list ~= nil then
		for i, def in ipairs(colors_list) do
			-- Check if this color is locked
			local is_locked = not self.owner.components.unlocktracker:IsCosmeticUnlocked(def.name, "PLAYER_COLOR")

			-- Add button
			local color_element = self.color_elements_list:AddChild(SelectableItemColor())
				:SetImageColor (def.rgb)
				:SetItemColorId(def.name)
				:SetLocked(is_locked)
				:SetControlUpSound(nil)
			
			color_element:SetToolTipFn(function() 
				return self:ElementTooltipFn(self.debug_mode, def, false, is_locked)
			end)
			:ShowToolTipOnFocus(true)

			color_element:SetOnClick(function()
				if self.debug_mode then
					--is_locked = self:Debug_UpdateAvailability(color_element, def.name, "PLAYER_COLOR")
					ui:SetClipboardText(def.name)
					TheFrontEnd:ShowTextNotification("images/ui_ftf_notifications/clipboard.tex", "Copied", def.name, 3)
				elseif not is_locked then
					self:OnColorElementSelected(colorgroup, def.name)
				end
			end)
			
			color_element:SetOnGainFocus(function()
				color_element:OnFocusChange(true)
					if not is_locked and not color_element:IsSelected() then
						self:ColorPreview(colorgroup, def.name)
					end
				end)
				:SetOnLoseFocus(function()
					color_element:OnFocusChange(false)
					if self.purchasing == nil and not color_element:IsSelected() then
						self:ClearColorPreview()
					end
				end)
		end

		self.color_elements_list:LayoutChildrenInGrid(1000, 15)
			:LayoutBounds("center", "bottom", self.panel_bg)
			:Offset(0, 100)
	end
end

function CharacterScreen:OnColorElementSelected(colorgroup, id)
	self.current_colorgroup = colorgroup
	self.current_color_name = id

	-- Select correct button
	for k, btn in ipairs(self.color_elements_list.children) do
		btn:SetSelected(id == btn:GetItemColorId())
	end

	-- Apply the color to the player
	self.puppet.components.charactercreator:SetColorGroup(colorgroup, id)
	self:ApplyColorToPartsList(colorgroup, id)

	self:CheckForChanges()
end

function CharacterScreen:ApplyColorToPartsList(colorgroup, color_id)
	for _, puppet in ipairs(self.colorize_puppets) do
		puppet.components.charactercreator:SetColorGroup(colorgroup, color_id)
	end
end

function CharacterScreen:GenerateArmorDyeList(armorslot)
	-- Remove old list items
	self.scroll_contents:RemoveAllChildren()
	self.color_elements_list:RemoveAllChildren()

	local equipped_set = self.owner.components.inventory.equips[armorslot]
	-- This slot does not have an equipped set
	if equipped_set == nil then
		return
	end

	-- This set does not have any available dyes
	if Cosmetic.EquipmentDyes[armorslot][equipped_set] == nil then
		return
	end
	
	local dye_list = {}
	for k, def in pairs(Cosmetic.EquipmentDyes[armorslot][equipped_set]) do
		table.insert(dye_list, def)
	end
	local none_def = { name = "NONE", armour_slot = armorslot, armour_set = equipped_set }
	table.insert(dye_list, none_def)

	dye_list = self:SortDyeList(dye_list, armorslot, equipped_set)

	local image_w = 320
	for i, def in ipairs(dye_list) do

		local is_locked
		if def.name == "NONE" then
			is_locked = false
		else
			is_locked = not self.owner.components.unlocktracker:IsCosmeticUnlocked  (def.armour_slot, def.short_name)
		end

		local dye_element = self.scroll_contents:AddChild(SelectableArmorDye(image_w))
			:SetDyeId(def.name) -- TODO @H: pass the whole def here
			:SetLocked(is_locked)
			:SetSelected(i == 1)

		dye_element:CloneCharacterAppearance(self.puppet)
			:SetPuppetArmorDye(armorslot, equipped_set, def.short_name)
			--:HighlightParts(ARMOR_HIGHLIGHT_PARTS[armorslot])

		dye_element:SetToolTipFn(function()
			if is_locked then
				return STRINGS.CHARACTER_CREATOR.LOCKED_DYE_TOOLTIP
			end

			return STRINGS.CHARACTER_CREATOR.CLICK_TOOLTIP
		end)
		:ShowToolTipOnFocus(true)
	
		dye_element:SetOnClick(function()
			if self.debug_mode then
				--is_locked, is_purchased = self:Debug_UpdateAvailability(dye_element, def.name, "PLAYER_TITLE")
			else
				if not is_locked then
					self:OnDyeElementSelected(def)
				end
			end
		end)
	
		dye_element:SetOnGainFocus(function()
			dye_element:OnFocusChange(true)
			if not is_locked and not dye_element:IsSelected() then
				self:DyePreview(def, armorslot)
			end
		end)
		:SetOnLoseFocus(function()
			dye_element:OnFocusChange(false)
			if not is_locked and not dye_element:IsSelected() then
				self:ClearDyePreview()
			end
		end)

		local xform = ARMOR_DYE_TRANSFORM[armorslot]
		dye_element:SetPuppetOffset(xform.offset:unpack())
				   :SetPuppetScale(xform.scale)
	end


	self.scroll_contents:LayoutInDiagonal(3, 60, 60)
		:SetPosition(-self.list_width/2 + image_w, -image_w/2)
	self.scroll:RefreshView()
end

function CharacterScreen:OnDyeElementSelected(def)
	self.puppet.components.equipmentdyer:SetEquipmentDye(def.armour_slot, def.armour_set, def.short_name)

	-- We can't set these to nil otherwise they get reverted when the dye preview clears up
	self.current_dye_slot = def.armour_slot
	self.current_dye_set = def.armour_set
	self.current_dye_name = def.short_name

	for k, element in ipairs(self.scroll_contents.children) do
		if def.name == element:GetDyeId() then
			element:SetSelected(true)
		else
			element:SetSelected(false)
		end
	end

	self:CheckForChanges()
end

function CharacterScreen:GenerateTitleList()
	self.scroll_contents:RemoveAllChildren()
	
	local title_width = 400
	local title_height = 250

	local sortable_list = {}

	for id, def in pairs(Cosmetic.Items["PLAYER_TITLE"]) do
		table.insert(sortable_list, def)
	end

	sortable_list = self:SortTitleList(sortable_list)

	for i, def in ipairs(sortable_list) do
		local is_locked = not self.owner.components.unlocktracker:IsCosmeticUnlocked(def.name, "PLAYER_TITLE")

		local title_element = self.scroll_contents:AddChild(SelectablePlayerTitle(title_width, title_height))
			:SetTitle(def)
			:SetLocked(is_locked)
			:SetSelected(i == 1)

		title_element:SetToolTipFn(function()
			return self:ElementTooltipFn(self.debug_mode, def, false, is_locked)
		end)
		:ShowToolTipOnFocus(true)

		title_element:SetOnClick(function()
			if self.debug_mode then
				is_locked = self:Debug_UpdateAvailability(title_element, def.name, "PLAYER_TITLE")
			elseif not is_locked then
				self:OnTitleElementSelected(def)
			end
		end)

		title_element:SetOnGainFocus(function()
			title_element:OnFocusChange(true)
			if not is_locked and not title_element:IsSelected() then
				self:TitlePreview(def)
			end
		end)
		:SetOnLoseFocus(function()
			title_element:OnFocusChange(false)
			if self.purchasing == nil and not title_element:IsSelected() then
				self:ClearTitlePreview()
			end
		end)
	end

	self.scroll_contents:LayoutInDiagonal(3, 60, 60)
		:SetPosition(-self.list_width/2 + title_width/2, -title_height/2)
	self.scroll:RefreshView()
end

function CharacterScreen:OnTitleElementSelected(def)
	self.puppet.components.playertitleholder:SetTitle(def)

	for k, title in ipairs(self.scroll_contents.children) do
		if def.title_key == title:GetTitleKey() then
			title:SetSelected(true)
		else
			title:SetSelected(false)
		end
	end

	self:CheckForChanges()
end

-------------------------------------------------------------------------------------
-- Debug Functions
-------------------------------------------------------------------------------------

-- Changes status
function CharacterScreen:Debug_UpdateAvailability(element, cosmetic_name, cosmetic_category)
	local is_locked = not self.owner.components.unlocktracker:IsCosmeticUnlocked(cosmetic_name, cosmetic_category)

	if is_locked then
		self.owner.components.unlocktracker:UnlockCosmetic(cosmetic_name, cosmetic_category)
		is_locked = false
	else
		self.owner.components.unlocktracker:LockCosmetic(cosmetic_name, cosmetic_category)
		
		is_locked = true
	end

	element:SetLocked(is_locked)

	return is_locked
end

-------------------------------------------------------------------------------------
-- Other Functions
-------------------------------------------------------------------------------------

function CharacterScreen:_ShowArmor()
	self.showing_armor = true

	-- Update button text
	self.armor_btn:SetText(STRINGS.CHARACTER_CREATOR.SHOWING_ARMOR_BUTTON)
	self.armor_btn:SetToolTip(STRINGS.CHARACTER_CREATOR.HIDE_ARMOR_BUTTON_TOOLTIP)
	-- Get player armor
	for slot, item in pairs(self.owner.components.inventory.equips) do
		-- Update customize-character puppet
		self.puppet.components.inventory:Equip(slot, item)
	end
end

function CharacterScreen:_HideArmor()
	self.showing_armor = false

	-- Update button text
	self.armor_btn:SetText(STRINGS.CHARACTER_CREATOR.HIDING_ARMOR_BUTTON)
	self.armor_btn:SetToolTip(STRINGS.CHARACTER_CREATOR.SHOW_ARMOR_BUTTON_TOOLTIP)

	-- Get player armor
	for slot, item in pairs(self.owner.components.inventory.equips) do
		-- Update customize-character puppet
		self.puppet.components.inventory:Equip(slot, nil)
	end
end

function CharacterScreen:IsCharacterEqual()
	local owner_body_data = self.owner.components.charactercreator:SaveToTable()
	local are_bodyparts_equal = deepcompare(self.puppet.components.charactercreator:SaveToTable(), owner_body_data)

	local owner_title_key = self.owner.components.playertitleholder:GetTitleKey()
	local are_titles_equal = self.puppet.components.playertitleholder:GetTitleKey() == owner_title_key

	local are_dyes_equal = true

	for _, slot in ipairs(Cosmetic.DyeSlots) do
		local set = self.owner.components.inventory.equips[slot]
		
		local owner_dye = self.owner.components.equipmentdyer:GetActiveDye(slot, set)
		local puppet_dye = self.puppet.components.equipmentdyer:GetActiveDye(slot, set)

		if owner_dye ~= puppet_dye then
			are_dyes_equal = false
			break
		end
	end

	return are_bodyparts_equal and are_titles_equal and are_dyes_equal
end

function CharacterScreen:CheckForChanges()
	local is_equal = self:IsCharacterEqual()

	self.revert_btn:SetEnabled(not is_equal)
	self.revert_btn:SetToolTip(is_equal and STRINGS.CHARACTER_CREATOR.NO_CHANGES or STRINGS.CHARACTER_CREATOR.REVERT_BUTTON_TOOLTIP)
end

return CharacterScreen
