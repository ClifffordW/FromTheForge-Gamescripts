local Screen = require "widgets.screen"
local Widget = require "widgets.widget"
local Text = require "widgets.text"
local Image = require"widgets.image"
local PanelButton = require "widgets.panelbutton"
local ActionButton = require("widgets/actionbutton")
local Panel = require"widgets.panel"
local ImageButton = require "widgets.imagebutton"
local ConfirmDialog = require "screens.dialogs.confirmdialog"
local TextEdit = require "widgets/textedit"
local fmodtable = require "defs.sound.fmodtable"

local easing = require "util.easing"

local EditNamePopUp = Class(Screen, function(self, w, h, slot)
	Screen._ctor(self, "EditNamePopUp")

	self.bg = self:AddChild(Image("images/global/square.tex"))
		:SetScale(100)
		:SetMultColor(0, 0, 0, 0.5)

	self.panel = self:AddChild(Panel("images/ui_ftf/dialog_bg.tex"))
		:SetName("BG")
		:SetNineSliceCoords(50, 28, 550, 239)
		:SetSize(w, h)

	self.name = self.panel:AddChild(Text(FONTFACE.DEFAULT, FONTSIZE.SCREEN_SUBTITLE))
		:SetGlyphColor(UICOLORS.LIGHT_TEXT_DARKER)
		:SetText("Rename Town")
		:IgnoreParentMultColor(true)
		:LayoutBounds("center", "top", self.panel)
		:Offset(0, -20)

	self.text_edit = self.panel:AddChild( TextEdit(FONTFACE.DEFAULT, 44) )
		:SetSize(w * 0.75, 100)
		:SetHAlign(ANCHOR_LEFT)
		:SetTextLengthLimit(15) -- pretty arbitrary limit for ui reasons
		:SetForceEdit(true)
		:LayoutBounds("center", "below", self.name)
		:Offset(0, -20)
		:SetString("")

	local confirm_fn = function()
		TheSaveSystem:SetSaveSlotName(slot, self.text_edit:GetText())
		TheFrontEnd:PopScreen(self)
	end

	self.text_edit.OnTextEntered = confirm_fn

	self.confirm_button = self.panel:AddChild(ActionButton())
		:SetSize(w/3, 125)
		:SetScaleOnFocus(false)
		:SetText(STRINGS.UI.BUTTONS.OK)
		:SetOnClick(confirm_fn)
		:LayoutBounds("center", "below", self.text_edit)
		:Offset(0, -20)
		:SetFocus()

	self.close_button = self:AddChild(ImageButton("images/ui_ftf/HeaderClose.tex"))
		:SetName("Close button")
		:SetSize(BUTTON_SQUARE_SIZE, BUTTON_SQUARE_SIZE)
		:SetOnClick(function() TheFrontEnd:PopScreen(self) end)
		:LayoutBounds("right", "top", self.panel)
		:SetScale(0.75, 0.75)
		:Offset(20, 20)
end)

local TownSelectionButton = Class(Widget, function(self, slot, w, h)
	Widget._ctor(self, "TownSelectionButton")

	self.slot = slot

	self.selected = false

	local has_data = TheSaveSystem:GetSaveSlot(slot):GetTownSave():GetValue("progression")

	local delete_size = (h * 0.4) + 20

	local button_w = w - delete_size

	self.button = self:AddChild(PanelButton("images/ui_ftf_options/controls_bg.tex"))
		:SetName(("Town Select Button %s"):format(slot))
		:SetNineSliceCoords(22, 12, 304, 82)
		:SetSize(button_w, h)
		:SetMultColor(UICOLORS.LIGHT_TEXT_DARKER)

	local bw, bh = self.button:GetSize()

	self.button_bg = self.button.image:AddChild(Panel("images/ui_ftf_options/controls_bg.tex"))
		:SetNineSliceCoords(22, 12, 304, 82)
		:SetSize(bw+20, bh+20)
		:SetMultColor(UICOLORS.LIGHT_TEXT)
		:SetMultColorAlpha(0)
		:IgnoreParentMultColor(true)
		:LayoutBounds("center", "center", self.button)
		:SendToBack()

	self.title = self.button:AddChild(Text(FONTFACE.DEFAULT, FONTSIZE.SCREEN_SUBTITLE))
		:SetGlyphColor(UICOLORS.LIGHT_TEXT)
		:SetText("Start New Save")
		:LayoutBounds("center", "center", self.button)
		:IgnoreParentMultColor(true)

	self.opt_buttons_root = self:AddChild(Widget())

	self.edit_button = self.opt_buttons_root:AddChild(ImageButton("images/icons_ftf/character_title.tex"))
		:SetName("Edit Button")
		:SetSize(delete_size, delete_size)
		:SetImageFocusColour(UICOLORS.LIGHT_TEXT)
		:SetImageNormalColour(UICOLORS.LIGHT_TEXT_DARKER)
		:SetFocusScale(1.05, 1.05, 1.05)
		:SetOnClick(function()
			local rename = EditNamePopUp(1000, 400, slot)
			rename:SetCloseCallback(function()
				self.title:SetText(TheSaveSystem:GetSaveSlotName(slot))
			end)
			TheFrontEnd:PushScreen(rename)
			rename.text_edit:SetEditing(true)
		end)

	self.delete_button = self.opt_buttons_root:AddChild(ImageButton("images/icons_ftf/menu_trash.tex"))
		:SetName("Delete Button")
		:SetSize(delete_size, delete_size)
		:SetImageFocusColour(UICOLORS.LIGHT_TEXT)
		:SetImageNormalColour(UICOLORS.LIGHT_TEXT_DARKER)
		:SetFocusScale(1.05, 1.05, 1.05)
		:LayoutBounds("center", "below", self.edit_button)

	self.opt_buttons_root:LayoutBounds("after", "center", self.button)
		:Offset(20, 0)

	if has_data ~= nil then
		local name = TheSaveSystem:GetSaveSlotName(slot)
		self.title:SetText(name)
	else
		self.edit_button:Disable()
			:SetMultColorAlpha(0.1)

		self.delete_button:Disable()
			:SetMultColorAlpha(0.1)
	end

	-- TODO: A way to change names
end)

function TownSelectionButton:SetDeleteFn(fn)
	self.delete_button:SetOnClick(fn)
end

function TownSelectionButton:SetOnClickFn(...)
	self.button:SetOnClickFn(...)
	return self
end

function TownSelectionButton:SetOnFocusChangedFn(fn)
	self.on_focus_changed = fn
	return self
end

function TownSelectionButton:OnFocusChange(has_focus)

	if self.on_focus_changed then self.on_focus_changed(has_focus) end
	self:_UpdateFocusLook(has_focus)

	return self
end

function TownSelectionButton:SetSelected(is_selected)
	self.selected = is_selected
	self:_UpdateFocusLook()
	return self
end

function TownSelectionButton:_UpdateFocusLook(has_focus)
	local show_glow = has_focus or self.selected
	self.button_bg:AlphaTo(show_glow and 1 or 0, show_glow and 0.1 or 0.3, easing.outQuad)
	return self
end

local TownSelectionScreen = Class(Screen, function(self, owner, on_close_cb)
	Screen._ctor(self, "TownSelectionScreen")

	self.bg = self:AddChild(Image("images/ui_ftf_gems/weapons_panel_bg.tex"))
		:SetName("Background")

	self.close_button = self:AddChild(ImageButton("images/ui_ftf/HeaderClose.tex"))
		:SetName("Close button")
		:SetSize(BUTTON_SQUARE_SIZE, BUTTON_SQUARE_SIZE)
		:SetOnClick(function() self:OnClickClose() end)
		:LayoutBounds("right", "top", self.bg)

	self.title = self:AddChild(Text(FONTFACE.DEFAULT, FONTSIZE.SCREEN_TITLE))
		:SetGlyphColor(UICOLORS.LIGHT_TEXT)
		:SetText("Choose Save Slot")
		:LayoutBounds("center", "top", self.bg)
		:Offset(0, -50)

	self.contents = self:AddChild(Widget("Contents")) -- town buttons

	self:Refresh()
end)

function TownSelectionScreen:SetDefaultFocus()
	if self.town_slot_buttons then
		self.town_slot_buttons[1]:SetFocus()
	else
		self.close_button:SetFocus()
	end
end

function TownSelectionScreen:Refresh()
	self.town_data = TheSaveSystem:GetAllSaveSlots()

	self.contents:RemoveAllChildren()
	self.town_slot_buttons = {}

	local last_selected = TheSaveSystem:GetActiveSaveSlot()

	local w, h = self.bg:GetSize()

	w = w * 0.8
	h = h/5.5

	local num_slots = table.count(self.town_data)

	for i = 1, num_slots do
		local slot = i

		local button = self.contents:AddChild(TownSelectionButton(slot, w, h))

		button:SetOnClickFn(function()
			self:OnTownSlotClicked(button, slot)
		end)

		button:SetOnFocusChangedFn(function(has_focus)
			self:OnTownFocusChanged(has_focus, button, slot, i)
		end)

		button:SetDeleteFn(function()
			local function delete_town()
				local mcb = MultiCallback()

				TheSaveSystem:GetSaveSlot(slot):Erase(mcb)

				mcb:WhenAllComplete(function()
					self:Refresh()
					TheFrontEnd:PopScreen()
				end)
			end

			local function cancel()
				TheFrontEnd:PopScreen() -- confirmation message box
			end

			local confirmation = ConfirmDialog(self:GetOwningPlayer(), nil, true,
				"Delete Town?",
				("Do you want to delete [%s]?"):format(TheSaveSystem:GetSaveSlotName(slot)),
				"Cannot be undone"
			)
			:SetYesButton(STRINGS.CHARACTER_SELECTOR.DELETE_CONFIRM, delete_town)
			:SetNoButton(STRINGS.CHARACTER_SELECTOR.DELETE_CANCEL, cancel)
			:HideArrow()
			:SetMinWidth(600)
			:CenterText()
			:CenterButtons()

			TheFrontEnd:PushScreen(confirmation)
		end)

		if slot == last_selected then
			button:SetSelected(true)
		end

		self.town_slot_buttons[i] = button
	end

	self.contents:LayoutChildrenInColumn(40)
	self.contents:LayoutBounds("center", "below", self.title)
		:Offset(0, -75)
end

function TownSelectionScreen:OnTownSlotClicked(button, slot)
	for k, btn in ipairs(self.town_slot_buttons) do
		btn:SetSelected(button == btn)
	end

	self.selected_slot = slot

	TheSaveSystem:SetActiveSaveSlot(slot)
end

function TownSelectionScreen:OnTownFocusChanged(has_focus, button, slot, idx)
	if not self:IsRelativeNavigation() then return self end

	for k, btn in ipairs(self.town_slot_buttons) do
		btn:SetSelected(button == btn)
	end

	self.selected_slot = slot
end

function TownSelectionScreen:OnInputModeChanged(old_device_type, new_device_type)
	-- self.continue_btn:SetShown(not self:IsRelativeNavigation() and self.selected_slot)
end

function TownSelectionScreen:OnClickClose()
	if self.on_click_close_fn then
		self.on_click_close_fn()
	else
		TheFrontEnd:PopScreen(self)
	end
	return self
end

TownSelectionScreen.CONTROL_MAP =
{
	{
		control = Controls.Digital.CANCEL,
		fn = function(self)
			if self:IsRelativeNavigation() then
				self:OnClickClose()
				TheFrontEnd:GetSound():PlaySound(fmodtable.Event.ui_simulate_click)
				return true
			end
		end,
	},
}

return TownSelectionScreen
