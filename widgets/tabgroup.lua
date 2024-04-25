local Clickable = require "widgets.clickable"
local Image = require "widgets.image"
local ImageButton = require "widgets.imagebutton"
local TextButton = require "widgets.textbutton"
local Text = require "widgets.text"
local Widget = require "widgets/widget"
local easing = require "util.easing"
require "class"
require "util"

local TabGroup = Class(Widget, function(self)
	Widget._ctor(self, "TabGroup")
	self.tabs = {}
	self.tabs_container = self:AddChild(Widget())
		:SetName("Tabs container")
	self:SetTheme_DarkOnLight()
	self.tab_spacing = 40
end)

function TabGroup:_RemoveListeners()
	self.inst:RemoveEventCallback("input_device_changed", self._ondevicechange_fn, self:GetOwningPlayer())
	self.inst:RemoveEventCallback("input_device_changed_kbm", self._ondevicechange_fn, self:GetOwningPlayer())
	TheInput:UnregisterForDeviceChanges(self._ondevicechange_fn)
	self._ondevicechange_fn = nil
end

function TabGroup:OnRemoved()
	self:_RemoveListeners()
end


function TabGroup:SetTheme_DarkOnLight()
	self.colors = {
		normal = UICOLORS.DARK_TEXT,
		focus = UICOLORS.FOCUS,
		disabled = UICOLORS.DISABLED,
		selected = UICOLORS.BLACK,
	}
	return self
end

function TabGroup:SetTheme_LightTransparentOnDark()
	local normal = deepcopy(UICOLORS.LIGHT_TEXT_DARK)
	normal[4] = normal[4] * 0.5
	self.colors = {
		normal = normal,
		focus = UICOLORS.LIGHT_TEXT_DARK,
		disabled = UICOLORS.DISABLED,
		selected = UICOLORS.LIGHT_TEXT_SELECTED,
	}
	return self
end

function TabGroup:SetFontSize(font_size)
	assert(#self.tabs == 0, "SetFontSize before adding tabs.")
	self.font_size = font_size
	return self
end

function TabGroup:SetTabSize(w,h)
	for _,tab in ipairs(self.tabs) do
		tab:SetSize(w,h)
	end
	return self
end

function TabGroup:SetTabSpacing(tab_spacing)
	self.tab_spacing = tab_spacing or 40
	return self
end

function TabGroup:SetTabOnClick(onclickfn)

	-- Save callback function
	self.on_click_fn = function(tab)
		if self.current then
			self.current:Unselect()
		end
		self.current = tab
		self.current:Select()
		onclickfn(tab)
	end

	-- If there are tabs already, set the callback on them
	for _,tab in ipairs(self.tabs) do
		tab:SetOnClick(function() self.on_click_fn(tab) end)
	end
	return self
end

function TabGroup:SelectTab(index, trigger_click)
	for i ,tab in ipairs(self.tabs) do
		if i == index then
			if self.current then
				self.current:Unselect()
			end
			self.current = tab
			self.current:Select()
			if trigger_click then
				self.on_click_fn(tab)
			end
		end
	end
end

function TabGroup:SetNavFocusable(can_focus_with_nav)
	for _,tab in ipairs(self.tabs) do
		tab:SetNavFocusable(can_focus_with_nav)
	end
	return self
end


function TabGroup:GetNumTabs()
	return #self.tabs
end

function TabGroup:GetCurrentIdx()
	for i,v in ipairs(self.tabs) do
		if self.current == v then
			return i
		end
	end
end

function TabGroup:NextTab(delta)
	delta = delta or 1
	local idx = self:GetCurrentIdx()
	local slot = circular_index(self.tabs, idx + delta)
	slot:Click()
end

function TabGroup:OpenTabAtIndex(idx)
	local tab = self.tabs[idx]
	if tab then
		tab:Click()
		return tab
	end
end

function TabGroup:AddCycleIcons(icon_size, icon_margin, icon_color)
	assert(not self._ondevicechange_fn, "Don't call AddCycleIcons more than once.")
	assert(#self.tabs > 0, "AddCycleIcons after adding all your tabs.")

	self._ondevicechange_fn = function(old_device_type, device_type)
		self:RefreshHotkeyIcon()
	end
	local owning_player = self:GetOwningPlayer()
	if owning_player then
		self.inst:ListenForEvent("input_device_changed", self._ondevicechange_fn, owning_player)
		self.inst:ListenForEvent("input_device_changed_kbm", self._ondevicechange_fn, owning_player)
	else
		TheInput:RegisterForDeviceChanges(self._ondevicechange_fn)
	end


	icon_size = icon_size or 50
	self.icon_margin = icon_margin or 20
	icon_color = icon_color or self.colors.normal

	if not self.prev_icon then
		self.prev_icon = self:AddChild(Image())
			:SetSize(icon_size, icon_size)
			:SetMultColor(icon_color)
			:SetHiddenBoundingBox(true)
	end
	if not self.next_icon then
		self.next_icon = self:AddChild(Image())
			:SetSize(icon_size, icon_size)
			:SetMultColor(icon_color)
			:SetHiddenBoundingBox(true)
		self:RefreshHotkeyIcon()
	end

	self:Layout()
	return self
end

function TabGroup:SetIsSubTab(is_subtab)
	self.is_subtab = is_subtab
	return self
end

function TabGroup:RefreshHotkeyIcon()
	local owner = self:GetOwningPlayer()
	local playercontroller = owner and owner.components.playercontroller
	local nav = playercontroller or TheFrontEnd
	if nav:IsRelativeNavigation() then
		local prev_control = Controls.Digital.MENU_TAB_PREV
		local next_control = Controls.Digital.MENU_TAB_NEXT

		if self.is_subtab then
			prev_control = Controls.Digital.MENU_SUB_TAB_PREV
			next_control = Controls.Digital.MENU_SUB_TAB_NEXT
		end

		-- Fall back to last input device so TabGroup works in main menu or
		-- screens not tied to a single player.
		local input_source = playercontroller or TheInput

		self.prev_icon:SetTexture(input_source:GetTexForControl(prev_control))
			:Show()
		self.next_icon:SetTexture(input_source:GetTexForControl(next_control))
			:Show()
	else
		-- Hide the keyboard icons because they don't match the size of gamepad
		-- and are a bit ugly.
		self.prev_icon:Hide()
		self.next_icon:Hide()
	end
end


function TabGroup:_HookupTab(tab)
	table.insert(self.tabs, tab)
	if not self.current then
		self.current = tab
	end
	if self.on_click_fn then tab:SetOnClick(function() self.on_click_fn(tab) end) end
	self:Layout()
	return tab
end

-- A tab with an icon and tooltip.
-- TODO(dbriscoe): Rename to AddIconTab
function TabGroup:AddTab(icon)
	local tab = self.tabs_container:AddChild(ImageButton(icon))
		:SetImageNormalColour(self.colors.normal)
		:SetImageFocusColour(self.colors.focus)
		:SetImageDisabledColour(self.colors.disabled)
		:SetImageSelectedColour(self.colors.selected)

	return self:_HookupTab(tab)
end

-- A tab with a square icon and text label.
function TabGroup:AddIconTextTab(icon, text)
	assert(icon)
	assert(text)
	local tab = self.tabs_container:AddChild(Clickable())
	tab.icon = tab:AddChild(Image(icon))
		:SetMultColor(WEBCOLORS.WHITE)

	tab.text = tab:AddChild(Text(FONTFACE.DEFAULT, self.font_size or 20))
		:SetGlyphColor(WEBCOLORS.WHITE)
		:SetText(text)
		:LeftAlign()
	tab.text.offset = 8

	function tab:RelayoutTab()
		self.text
			:LayoutBounds("after", "center", self.icon)
			:Offset(self.text.offset, 0)
		return self
	end
	function tab:SetSize(x, y)
		self.icon:SetSize(y, y)
		if x then
			-- Force the text to fill up remaining space. Useful for vertical
			-- alignment, but not so great for horizontal tabs.
			local w = x - y - self.text.offset
			self.text:SetSize(w, y)
		end
		return self:RelayoutTab()
	end

	tab:RelayoutTab()

	self:_ApplyFancyTint(tab)
	return self:_HookupTab(tab)
end

-- A tab with just text.
function TabGroup:AddTextTab(label, font_size)
	font_size = font_size or self.font_size
	local tab = self.tabs_container:AddChild(TextButton())
		-- All colors are white because we tint the text for prettier fades.
		:SetTextColour(WEBCOLORS.WHITE)
		:SetTextFocusColour(WEBCOLORS.WHITE)
		:SetTextDisabledColour(WEBCOLORS.WHITE)
		:SetTextSelectedColour(WEBCOLORS.WHITE)
		:SetTextSize(font_size or 20)
		:SetText(label)
	self:_HookupTab(tab)
	return self:_ApplyFancyTint(tab)
end

function TabGroup:_ApplyFancyTint(tab)
	tab:SetOnGainFocus(function()
		tab:TintTo(nil, self.colors.focus, 0.05, easing.inQuad)
	end)
	tab:SetOnLoseFocus(function()
		tab:TintTo(nil, tab:IsSelected() and self.colors.selected or self.colors.normal, 0.3, easing.outQuad)
	end)
	tab:SetOnDown(function()
		tab:TintTo(nil, self.colors.selected, 0.05, easing.inQuad)
	end)
	tab:SetOnUp(function()
		tab:TintTo(nil, tab:IsSelected() and self.colors.selected or self.colors.normal, 0.3, easing.outQuad)
	end)
	tab:SetOnSelect(function()
		tab:TintTo(nil, self.colors.selected, 0.05, easing.inQuad)
	end)
	tab:SetOnUnSelect(function()
		tab:TintTo(nil, self.colors.normal, 0.3, easing.outQuad)
	end)

	-- Snap to initial color
	tab:TintTo(nil, self.colors.normal, 0, easing.outQuad)

	return tab
end

function TabGroup:RemoveAllTabs()
	self.tabs_container:RemoveAllChildren()
	self:_RemoveListeners()
	self.tabs = {}
	self.current = nil
	return self
end

-- TODO(ui): POSTVS We should have some way of preventing tab cycling
-- during screen animations. IgnoreInput, Disable, etc.
--~ function TabGroup:OnEnable()
--~ 	for _,tab in ipairs(self.tabs) do
--~ 		tab:Enable()
--~ 	end
--~ end

--~ function TabGroup:OnDisable()
--~ 	for _,tab in ipairs(self.tabs) do
--~ 		tab:Disable()
--~ 	end
--~ end

function TabGroup:SetGridLayout(max_columns, vertical_spacing)
	self.max_columns = max_columns or nil
	self.tab_spacing_vertical = vertical_spacing or 15
	self:Layout()
	return self
end

function TabGroup:Layout()

	-- Layout all the tabs
	if self.tab_spacing_vertical then	-- If this is set, it's a grid
		self.tabs_container:LayoutChildrenInGrid(self.max_columns or 100000, {h = self.tab_spacing, v = self.tab_spacing_vertical})
	else
		self.tabs_container:LayoutChildrenInRow(self.tab_spacing)
	end

	-- If there are prev and next icons, position those accordingly
	if self.prev_icon then
		self.prev_icon:LayoutBounds("before", "center", self.tabs_container):Offset(-self.icon_margin, 0)
	end
	if self.next_icon then
		self.next_icon:LayoutBounds("after", "center", self.tabs_container):Offset(self.icon_margin, 0)
	end

	return self
end

return TabGroup
