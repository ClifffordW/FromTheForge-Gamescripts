local PotionWidget = require("widgets/ftf/potionwidget")
local PowerWidget = require("widgets/ftf/powerwidget")
local ItemWidget = require("widgets/ftf/itemwidget")
local EquipmentTooltip = require("widgets/ftf/equipmenttooltip")
local Text = require("widgets/text")
local Widget = require("widgets/widget")
local Power = require("defs/powers/power")
local Equipment = require("defs/equipment")
local fmodtable = require("defs/sound/fmodtable")
local Enum = require("util/enum")
local lume = require("util/lume")
local easing = require("util/easing")


local DISPLAY_STATE = Enum{
	"HIDDEN", -- currently hidden
	"FADE_IN", -- fading into the world
	"IDLE", -- visible, but not doing anything right now
	"FADE_OUT", -- fading out of the world
}

-- The interactable radial menu that circles the player.
-- Shows either the player's current equipment or powers.
-- Toggle between them by pressing LB/RB
-- Can't switch to powers mode if you have none.
local RADIAL_MODE = Enum{
	"EQUIPMENT", -- show the player's equipment
	"POWERS", -- show the player's powers
}

local PlayerFollowStatus = Class(Widget, function(self, owner)
	Widget._ctor(self, "PlayerFollowStatus")
	self:SetOwningPlayer(owner)

	self:SetDisplayState(DISPLAY_STATE.s.HIDDEN)
	self:SetRadialMode(RADIAL_MODE.s.EQUIPMENT)

	self.layout_radius = 333
	self.fade_in_time = 0.33 -- how long it takes to fade in
	self.fade_out_time = 0.33 -- how long it takes to fade out
	self.time_visible_default = 0.5 -- how long the widget after releasing the keybind
	self.time_visible = self.time_visible_default
	self.actions_size = 96
	self.container_y_offset = 128

	self.status_focus_sound = fmodtable.Event.hover
	--~ assert(owner) -- TODO(demo): enable after demo
	-- Don't set self.owner until last!

	-- Widgets container
	self.container = self:AddChild(Widget())
		:SetPosition(0, self.container_y_offset)

	-- Appears above the health bar
	self.status_root = self.container:AddChild(Widget())
		:SetPosition(0, self.layout_radius)
		:Offset(0, 20)

	-- player id (i.e. "1P", "2P", etc.)
	self.id_widget = self.status_root:AddChild(Text(FONTFACE.BUTTON, 75 * HACK_FOR_4K, "", UICOLORS.RED))
		:SetShadowColor(UICOLORS.BLACK)
		:SetShadowOffset(1, -1)
		:SetOutlineColor(UICOLORS.BLACK)
		:EnableShadow()
		:EnableOutline()

	-- potion status (type, stock/count)
	self.potion_widget = self.status_root:AddChild(PotionWidget(self.actions_size * 2, owner))
		:ABOVE_HEAD()

	self.tab_controls = self.status_root:AddChild(Widget())
	self.left_tab = self.tab_controls:AddChild(Text(FONTFACE.BUTTON, 75, "<p bind='Controls.Digital.MENU_TAB_PREV'>", UICOLORS.RED))
	self.right_tab = self.tab_controls:AddChild(Text(FONTFACE.BUTTON, 75, "<p bind='Controls.Digital.MENU_TAB_NEXT'>", UICOLORS.RED))
	self.tab_controls:LayoutChildrenInRow(self.actions_size * 2, "bottom")
		:LayoutBounds("center", "center", self.power_widget)
	-- :Hide()

	-- Appears in a circle around the player.
	self.radial_root = self.container:AddChild(Widget())
	self.equipment_widgets = {}
	self.equipment_root = self.radial_root:AddChild(Widget())
	self:AddEquipmentSlot(Equipment.Slots.WEAPON)
	self:AddEquipmentSlot(Equipment.Slots.WAIST)
	self:AddEquipmentSlot(Equipment.Slots.BODY)
	self:AddEquipmentSlot(Equipment.Slots.HEAD)

	-- power status
	self.power_widgets = {}
	self.power_root = self.radial_root:AddChild(Widget())

	for _,pow in ipairs(owner.components.powermanager:GetAllPowersInAcquiredOrder()) do
		if pow.def.power_type == Power.Types.RELIC or pow.def.power_type == Power.Types.FABLED_RELIC then
			self:AddPower(pow.persistdata, owner)
		end
	end

	self.inst:ListenForEvent("add_power", function(owner_, pow)
		if self.owner then
			assert(owner_ == self.owner)
			if pow.def.power_type == Power.Types.RELIC or pow.def.power_type == Power.Types.FABLED_RELIC then
				if not lume.match(self.power_widgets, function(a) return a.power:GetDef().name == pow.def.name end) then
					self:AddPower(pow.persistdata, owner_)
				end
			end
		end
	end, owner)

	self.inst:ListenForEvent("remove_power", function(owner_, pow)
		if self.owner then
			assert(owner_ == self.owner)
			local v, i = lume.match(self.power_widgets, function(a) return a.power:GetDef().name == pow.def.name end)
			self:RemovePowerIdx(i)
		end
	end, owner)

	self.container:SetFadeAlpha(0)


	self.lastFocusedPowerName = nil
	self._focus_timer = 0

	self.toggleMode = false
	self.isHovering = false

	self._onremovetarget = function() self:SetOwner(nil) end
	self:Hide()
	self:SetOwner(owner)
end)

function PlayerFollowStatus:GetDisplayState()
	return self.display_state
end

function PlayerFollowStatus:SetDisplayState(new_state)
	self.display_state = new_state
end

function PlayerFollowStatus:GetRadialMode()
	return self.radial_mode
end

function PlayerFollowStatus:SetRadialMode(mode, delta)
	self.radial_mode = mode
	-- refresh view if visible
	if self:GetDisplayState() ~= DISPLAY_STATE.s.HIDDEN then
		self:Refresh(delta)
	end
end

function PlayerFollowStatus:ToggleRadialMode(delta)
	-- ugly, but works for now. Revisit if we ever add a third mode.
	if self:GetRadialMode() == RADIAL_MODE.s.EQUIPMENT and #self.power_widgets > 0 then
		self:SetRadialMode(RADIAL_MODE.s.POWERS, delta)
	else
		self:SetRadialMode(RADIAL_MODE.s.EQUIPMENT, delta)
	end
end

function PlayerFollowStatus:SetOwner(owner)
	if owner ~= self.owner then
		if self.owner ~= nil then
			self.inst:RemoveEventCallback("onremove", self._onremovetarget, self.owner)
		end

		self.owner = owner

		if self.owner ~= nil then
			self.inst:ListenForEvent("onremove", self._onremovetarget, self.owner)
		end
	end
end

function PlayerFollowStatus:ShowShowEquipment()
	return self:GetRadialMode() == RADIAL_MODE.s.EQUIPMENT and self.show_radial
end

function PlayerFollowStatus:ShouldShowPowers()
	return self:GetRadialMode() == RADIAL_MODE.s.POWERS and self.show_radial
end

function PlayerFollowStatus:PulseControlWidget(widget)
	self:RunUpdater(Updater.Ease(function(v) widget:SetScale(v) end, 0.8, 1, 0.1, easing.outElasticUI))
end

function PlayerFollowStatus:OnControl(controls, down)
	if controls:Has(Controls.Digital.MENU_TAB_PREV) and down then
		self:ToggleRadialMode(1)
		self:PulseControlWidget(self.left_tab)
		return true
	elseif controls:Has(Controls.Digital.MENU_TAB_NEXT) and down then
		self:ToggleRadialMode(-1)
		self:PulseControlWidget(self.right_tab)
		return true
	end

	if controls:Has(Controls.Digital.SHOW_PLAYER_STATUS) and not down then
		self:TryHideRadial()
		return true
	end
end

function PlayerFollowStatus:TryShowRadial(auto_fade)
	if self.radial_task then
		self.radial_task:Cancel()
		self.radial_task = nil
	end

	if auto_fade then
		self.radial_task = self.inst:DoTaskInTime(self.time_visible, function() 
			self.radial_task =  nil
			self:TryHideRadial()
		end)
	end

	self.owner.components.playercontroller:AddInputStealer(self)

	self.show_radial = true
	self:Reveal()
end

function PlayerFollowStatus:TryHideRadial()
	self.owner.components.playercontroller:RemoveInputStealer(self)
	self.show_radial = false
	self:_ClearStatusFocus()
	self:Refresh()
end

function PlayerFollowStatus:TryShowPotion(auto_fade)
	-- The widget shows potion status by default, but calling this will override ID and show Potion instead.
	if self.potion_task then
		self.potion_task:Cancel()
		self.potion_task = nil
	end

	if auto_fade then
		self.potion_task = self.inst:DoTaskInTime(self.time_visible, function() 
			self.potion_task =  nil
			self.show_potion = false
			self:Refresh()
		end)
	end

	self.show_potion = true
	self:Reveal()
end

function PlayerFollowStatus:TryShowID(auto_fade)
	-- only works if TryShowPotion isn't toggled.
	if self.id_task then
		self.id_task:Cancel()
		self.id_task = nil
	end

	if auto_fade then
		self.id_task = self.inst:DoTaskInTime(self.time_visible, function() 
			self.id_task =  nil
			self.show_id = false
			self:Refresh()
		end)
	end

	self.show_id = true
	self:Reveal()
end

function PlayerFollowStatus:Reveal()
	self:Refresh()

	if self:GetDisplayState() == DISPLAY_STATE.s.HIDDEN then
		self:FadeIn()
		if self:ShouldShowPowers() then
			self:PlaySpatialSound(fmodtable.Event.ui_playerFollowStatusWidget_open_powers, nil, true)
		else
			self:PlaySpatialSound(fmodtable.Event.ui_playerFollowStatusWidget_open_equipment, nil, true)
		end
	end
end

function PlayerFollowStatus:Refresh(delta)
	if self.owner then
		self.id_text = string.format("%dP", self.owner:GetHunterId())
		self.id_color = self.owner.uicolor
	end

	if self:ShouldShowPowers() then
		self:ShowPowers(delta)
	else
		self:HidePowers()
	end

	if #self.power_widgets > 0 and self.show_radial then
		self.tab_controls:Show()
		self.left_tab:SetGlyphColor(self.id_color)
		self.right_tab:SetGlyphColor(self.id_color)
	else
		self.tab_controls:Hide()
	end

	if self:ShowShowEquipment() then
		self:ShowEquipment(delta)
	else
		self:HideEquipment()
	end

	if self.show_potion or not self.show_id then
		self:ShowPotion()
		self:HideID()
	else
		self:HidePotion()
	end

	if self.show_id and not self.show_potion then
		self:ShowID()
		self:HidePotion()
	else
		self:HideID()
	end
end

function PlayerFollowStatus:ShowID()
	self.id_widget:SetText(self.id_text)
	self.id_widget:SetGlyphColor(self.id_color)

	-- if self.reveal_data.text_outline_color then
	-- 	self.id_widget:SetOutlineColor(self.reveal_data.text_outline_color)
	-- end

	self.id_widget:Show()
end

function PlayerFollowStatus:HideID()
	self.id_widget:Hide()
end

function PlayerFollowStatus:ShowPotion()
	self.potion_widget:RefreshUses()
	self.potion_widget:Show()
end

function PlayerFollowStatus:HidePotion()
	self.potion_widget:Hide()
end

function PlayerFollowStatus:ShowPowers(delta)
	self:LayoutRadialWidgets(self.power_widgets)
	self.power_root:Show()

	if delta then
		local x, y = self.power_root:GetPos()
		local offset_pos = x + (100 * delta)
		local handle = self:PlaySpatialSound(fmodtable.Event.ui_playerFollowStatusWidget_page, nil, true)
		TheFrontEnd:GetSound():SetParameter(handle, "local_discreteBinary", 1) -- toggle pitch
		self:RunUpdater(Updater.Series{
			Updater.Do(function() self.power_root:SetPosition(offset_pos, y) end),
			Updater.Ease(function(v) self.power_root:SetPosition(v, y) end, offset_pos, x, 0.1, easing.outExpo), 
		})
	end
end

function PlayerFollowStatus:HidePowers()
	self.power_root:Hide()
end

function PlayerFollowStatus:ShowEquipment(delta)
	for _, data in ipairs(self.equipment_widgets) do
		local equipped_item = self.owner.components.inventoryhoard:GetEquippedItem(data.slot)

		if equipped_item then
			data.widget:SetItem(equipped_item:GetDef())
				:SetToolTip({ item = equipped_item, player = self.owner })
				:DisableToolTip(false)
		else
			data.widget:SetEmptySlot(data.slot)
				:DisableToolTip(true)
		end
	end

	self:LayoutRadialWidgets(self.equipment_widgets)

	self.equipment_root:Show()

	if delta then
		local x, y = self.equipment_root:GetPos()
		local offset_pos = x + (100 * delta)
		local handle = self:PlaySpatialSound(fmodtable.Event.ui_playerFollowStatusWidget_page, nil, true)
		TheFrontEnd:GetSound():SetParameter(handle, "local_discreteBinary", 0) -- toggle pitch
		self:RunUpdater(Updater.Series{
			Updater.Do(function() self.equipment_root:SetPosition(offset_pos, y) end),
			Updater.Ease(function(v) self.equipment_root:SetPosition(v, y) end, offset_pos, x, 0.1, easing.outExpo), 
		})
	end
end

function PlayerFollowStatus:HideEquipment()
	self.equipment_root:Hide()
end

function PlayerFollowStatus:FadeIn()
	self:SetDisplayState(DISPLAY_STATE.s.FADE_IN)
	self:UpdatePosition()
	self:Show()
	self:StartUpdating()

	self:RunUpdater(Updater.Series{
		Updater.Ease(function(v) self.container:SetFadeAlpha(v) end, 0, 1, 0.1, easing.outExpo), 
		Updater.Do(function() self:SetDisplayState(DISPLAY_STATE.s.IDLE) end),
	})
end

function PlayerFollowStatus:FadeOut()
	if self.start_fade then return end
	self.start_fade = true

	self:PlaySpatialSound(fmodtable.Event.ui_playerFollowStatusWidget_close, nil, true)

	self:_ClearStatusFocus()
	self:SetDisplayState(DISPLAY_STATE.s.FADE_OUT)

	local follow_health_bar = self.owner.follow_health_bar
	if follow_health_bar then
		follow_health_bar:FadeOut()
	end

	self:RunUpdater(Updater.Series{
		Updater.Ease(function(v) end, 1, 0, self.fade_out_time, easing.inExpo),
		Updater.Do(function()
			self:SetDisplayState(DISPLAY_STATE.s.HIDDEN)
			self:StopUpdating()
			self:Hide()
			self.start_fade = false
		end)
	})
end

function PlayerFollowStatus:DoShake()
	self.owner.components.playercontroller:TryPlayRumble_IdentifyPlayer()
	local x, y = self.container:GetPosition()
	self:RunUpdater(Updater.Series{
		Updater.Do(function() self.container:SetPosition(0, y+100) end),
		Updater.Ease(function(v) self.container:SetPosition(0, v) end, y+100, y, 1, easing.outElastic)
	})
end

function PlayerFollowStatus:AddPower(power, owner)
	local def = power:GetDef()
	if not def.show_in_ui then return end

	-- Only ever shown in a single ring.
	-- Starts out with larger icons, but scales down as more powers are added.
	-- Not really designed to show more than around 20 powers.

	-- TODO(demo): Rename to _AddPower and assert instead.
	owner = owner or self.owner

	if owner then
		local w = self.power_root:AddChild(PowerWidget(self.actions_size, owner, power))
			:SetGainFocusSound(self.status_focus_sound)
		w:SetClickable(false)
		table.insert(self.power_widgets, { power = power, widget = w })
		if self:GetRadialMode() == RADIAL_MODE.s.POWERS then
			self:LayoutRadialWidgets(self.power_widgets)
			self:RunUpdater(Updater.Ease(function(v) w:SetScale(v) end, 0, 1, 0.2, easing.outElasticUI))
		end
	end

	if #self.power_widgets == 1 then
		self:Refresh()
	end
end

function PlayerFollowStatus:RemovePowerIdx(idx)
	local data = self.power_widgets[idx]

	if data ~= nil then
		data.widget:Remove()
		table.remove(self.power_widgets, idx)
		if self:GetRadialMode() == RADIAL_MODE.s.POWERS then
			self:LayoutRadialWidgets(self.power_widgets)
		end
	end
end

function PlayerFollowStatus:AddEquipmentSlot(slot)
	local w = self.equipment_root:AddChild( ItemWidget(nil, nil, 150) ) --InventorySlot(150, descriptors[slot].icon))
		:SetToolTipClass(EquipmentTooltip)
		:HideQuantity()
		:SetGainFocusSound(self.status_focus_sound)

	table.insert(self.equipment_widgets, { widget = w, slot = slot })

	if self:GetRadialMode() == RADIAL_MODE.s.EQUIPMENT then
		self:LayoutRadialWidgets(self.equipment_widgets)
	end
end

function PlayerFollowStatus:LayoutRadialWidgets(widgets)
	self.active_radial_widgets = widgets

	local min_widgets = 3
	local max_widgets = 20
	-- don't actually clamp to max_widgets
	-- if we do, widgets above max_widgets move into the reserved space.
	-- instead, understand that widgets will appear funny past max_widgets
	local num_widgets = math.max(#widgets, min_widgets) 

	local min_reserved = 90 -- we reserve the smallest amount of space when we have to show the largest amount of widgets
	local max_reserved = 140
	local reserved_degrees = easing.linear(num_widgets, max_reserved, min_reserved-max_reserved, max_widgets)

	-- local reserved_degrees = 90 -- the top of the circle is reserved for the status widget
	local reserved_circ = (self.layout_radius * 2) * (math.pi * (reserved_degrees/360))
	local radial_circ = (math.pi * (self.layout_radius * 2)) - reserved_circ
	local radial_degrees = 360 - reserved_degrees

	local max_widget_size = 200
	local min_widget_size = 140
	local widget_size = radial_circ / num_widgets
	widget_size = math.clamp(widget_size, min_widget_size, max_widget_size)

	local angle_per_widget = radial_degrees/(num_widgets - 1)

	local angle_offset = easing.linear(reserved_degrees, 90, -180, 360)

	for i, data in ipairs(widgets) do
		local layout_pos = i-1
		local angle_deg = angle_offset - (layout_pos * angle_per_widget)
		local angle = math.rad(angle_deg)
		if angle < 0 then
			angle = (2 * math.pi) + angle
		end
		local wx = self.layout_radius * math.cos(angle)
		local wy = self.layout_radius * math.sin(angle)
		local wsize = widget_size - 10
		data.angle = angle

		if data.widget:IsShown() and i ~= #widgets then
			local s = data.widget:GetSizeVar()
			local move_time = 0.1
			self:RunUpdater(Updater.Parallel{
				Updater.Do(function() data.widget:MoveTo(wx, wy, move_time, easing.outExpo) end),
				Updater.Ease(function(_s) data.widget:SetSize(_s) end, s, wsize, move_time, easing.outExpo),
			})
		else
			data.widget:SetPosition(wx, wy)
			data.widget:SetSize(wsize)
		end
	end
end

function PlayerFollowStatus:UpdatePosition()
	if self.owner then
		local x, y = self:CalcLocalPositionFromEntity(self.owner)
		self:SetPosition(x, y)
	end
end

function PlayerFollowStatus:_ShouldClose()
	if self.show_radial or self.show_potion or self.show_id then
		return false
	else
		return true
	end
end

function PlayerFollowStatus:OnUpdate(dt)
	self:_CheckStatusFocus(dt)
	self:_UpdateFocus()
	self:UpdatePosition()

	local should_close = self:_ShouldClose()

	if not self.start_fade then
		local follow_health_bar = self.owner.follow_health_bar
		if follow_health_bar then
			follow_health_bar:ShowHealthBar()
		end
	end

	if should_close then
		self:FadeOut()
	end
end

function PlayerFollowStatus:_SetStatusFocus(widget)
	if not self.show_radial then return end

	widget:SetFocus(self.owner:GetHunterId())
	widget:ShowToolTipOnFocus()
	widget:SendToFront()
	self.focused_widget = widget
	self:RunUpdater(Updater.Ease(function(v) widget:SetScale(v) end, 1, 1.5, 0.33, easing.outExpo))
end

function PlayerFollowStatus:_ClearStatusFocus()
	if self.focused_widget then
		-- clear focus
		local hunter_id = self.owner and self.owner:GetHunterId()
		local old_widget = self.focused_widget
		self:RunUpdater(Updater.Ease(function(v) old_widget:SetScale(v) end, 1.5, 1, 0.33, easing.outExpo))
		self.focused_widget:ClearFocus(hunter_id)
		self.focused_widget = nil
	end
end

function PlayerFollowStatus:_CheckStatusFocus(dt)
	local hunter_id = self.owner:GetHunterId()
	if self.active_radial_widgets then
		for _, data in ipairs(self.active_radial_widgets) do
			if data.widget.hover == hunter_id
				or data.widget:HasFocus(hunter_id)
			then
				self.isHovering = true
				self.lastCheckFocus = 0.3
				return
			end
		end

		-- throttle last check for mouse hover twitchiness
		-- gaps between widgets and the scaling effect can cause premature auto-close
		if self.lastCheckFocus then
			self.lastCheckFocus = self.lastCheckFocus - dt
			if self.lastCheckFocus <= 0 then
				self.lastCheckFocus = nil
			end
		end

		if self.lastCheckFocus == nil then
			self.isHovering = false
		end
	end
end

function PlayerFollowStatus:_UpdateFocus()
	if self.owner then
		if self:GetDisplayState() ~= DISPLAY_STATE.s.IDLE then
			return
		end

		local playercontroller = self.owner.components.playercontroller

		local r, angleDeg = playercontroller:GetRadialMenuDir()
		local usingGamepad = playercontroller:GetLastInputDeviceType() == "gamepad"

		if not usingGamepad then
			if self.isHovering then
				-- generate r, angleDeg for relative mouse position from widget origin
				local mx, my = TheInput:GetVirtualMousePos()
				local wx, wy = self:GetPosition()
				local dx = mx - wx
				local dy = my - wy - self.container_y_offset
				angleDeg = math.deg(ReduceAngleRad(-math.atan(dy, dx)))
				local maxAxisLen = self.layout_radius * 0.9
				r = math.sqrt(dx * dx + dy * dy) / maxAxisLen
			end
		end

		if r then
			angleDeg = -angleDeg
			local angle = ReduceAngleRad(math.rad(angleDeg))

			if angle < 0 then
				angle = (2 * math.pi) + angle
			end

			local closest_angle = 2*math.pi
			local best_match = nil

			for i, data in ipairs(self.active_radial_widgets) do
				local delta = math.abs(data.angle - angle)
				if delta < closest_angle then
					closest_angle = delta
					best_match = data.widget
				end
			end

			if not self.focused_widget or self.focused_widget ~= best_match then
				self:_ClearStatusFocus()
				self:_SetStatusFocus(best_match)
			end
		else
			self:_ClearStatusFocus()
		end

	end
end

return PlayerFollowStatus
