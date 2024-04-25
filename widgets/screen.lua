local Enum = require "util.enum"
local Image = require "widgets.image"
local Panel = require "widgets.panel"
local Widget = require "widgets.widget"
local ease = require "util.ease"
local easing = require "util.easing"
local fmodtable = require "defs.sound.fmodtable"
local kassert = require "util.kassert"
local lume = require "util.lume"
local playerutil = require "util.playerutil"
local strict = require "util.strict"


local Screen = Class(Widget, function(self, name)
	Widget._ctor(self, name)
	--self.focusstack = {}
	--self.focusindex = 0
	self.handlers = {}
	--self.inst:Hide()
	self.is_screen = true
	self.flush_inputs = true
	self.last_focus = {}

	-- Partial overlays are the most common, so default to that.
	self:SetAudioCategory(self.AudioCategory.s.PartialOverlay)

	-- Function to handle and propagate input mode changes while the screen is active
	self.on_notify_input_mode_changed = function(old_device_type, new_device_type)
		self:_NotifyInputModeChanged(old_device_type, new_device_type)
	end

	-- Called from here so widgets are notified when added as a child of a
	-- Screen and before the screen is added to the frontend.
	self:_NotifyAddedToScreen(self)
end)

Screen.AudioCategory = Enum{
	"None",           -- No default sounds.
	"Fullscreen",     -- Visibly blocks what's behind it.
	"PartialOverlay", -- Window with stuff visible behind.
	"Popup",          -- Small window with lots visible behind.
}

-- Override in screens to make it easy to test screens with d_open_screen.
--
-- This fallback implementation passes the input player since most screens
-- either take nothing or take the player.
function Screen.DebugConstructScreen(cls, player)
	assert(Screen ~= cls, "Cannot DebugConstructScreen for Screen: it's abstract.")
	return cls(player)
end

-- We usually only assign owning players to player-specific screens (i.e.
-- inventory). The player-specific input component will be used instead of
-- TheInput singleton see FrontEnd:Update.
function Screen:SetOwningPlayer(owningplayer)
	-- Ignore Widget:SetOwningPlayer. We're more strict since ownership limits control.
	-- TheLog.ch.FrontEnd:print("Screen:SetOwningPlayer=" .. tostring(owningplayer))
	self.owningplayer = self:ChangeTrackedEntity(owningplayer, "owningplayer")
	assert(not self.owningplayer or not self.owningplayer:IsLocal() or self.owningplayer.components.playercontroller:HasInputDevice(), "SetOwningPlayer requires an associated input device for local players.")
	return self
end

-- Check ownership with Widget:CanDeviceInteract. Get player if you actually
-- need them.
function Screen:GetOwningPlayer()
	-- Ignore Widget:GetOwningPlayer. Buck stops here.
	-- TheLog.ch.FrontEnd:print("Screen:GetOwningPlayer=" .. tostring(self.owningplayer))
	return self.owningplayer
end

function Screen:SetOwningDevice(input_device)
	assert(self.owningplayer == nil)
	assert(input_device, "Clearing owning device not yet supported.")
	local device_type, device_id = input_device:unpack()
	self.owningdevice = {
		device_type = device_type,
		device_id = device_id,
	}
end

-- Returns true for both keyboard and gamepad navigation.
function Screen:IsRelativeNavigation(hunter_id)
	local player = playerutil.GetByHunterId(hunter_id) or self.owningplayer
	if player then
		return player.components.playercontroller:IsRelativeNavigation()
	end
	return TheFrontEnd:IsRelativeNavigation()
end

-- Prefer Screen:IsRelativeNavigation() unless you are specifically excluding
-- keyboard.
function Screen:IsUsingGamepad()
	if self.owningplayer then
		local last_device = self.owningplayer.components.playercontroller:GetLastInputDeviceType()
		return last_device == "gamepad"
	end
	return TheInput:WasLastGlobalInputGamepad()
end

function Screen:HandleControlDown(controls, trace)
	if not TheFrontEnd:IsScreenInStack(self) then
		-- Some screens are used as widgets and aren't pushed. We don't want
		-- them to handle focus move.
		return
	end

	local dir
	if controls:Has(Controls.Digital.MENU_LEFT) then
		dir = FocusMove.s.left
	elseif controls:Has(Controls.Digital.MENU_RIGHT) then
		dir = FocusMove.s.right
	elseif controls:Has(Controls.Digital.MENU_UP) then
		dir = FocusMove.s.up
	elseif controls:Has(Controls.Digital.MENU_DOWN) then
		dir = FocusMove.s.down
	end

	if dir then
		-- Pass back to frontend. This back and forth through OnControlDown allows us to:
		-- * use input's repeat filtering
		-- * skip focus move if a widget handles direction
		-- * and limit input handling to the screen owner.
		local input_device = controls:GetDevice()
		return TheFrontEnd:FocusMove(self, dir, input_device)
	end
end

function Screen:SetAudioCategory(cat)
	dbassert(Screen.AudioCategory:Contains(cat))
	-- Audio people: Setup defaults for each category here:
	if cat == Screen.AudioCategory.s.Fullscreen then
		self:SetAudioSnapshotOverride(fmodtable.Event.FullscreenOverlay_LP)
			:SetAudioEnterOverride(fmodtable.Event.ui_fullscreen_enter)
			:SetAudioExitOverride(fmodtable.Event.ui_fullscreen_exit)
			-- Careful here. This is only okay because fullscreen is not the default.
			:PushAudioParameterWhileOpen(fmodtable.GlobalParameter.Music_InMenu)

	elseif cat == Screen.AudioCategory.s.PartialOverlay then
		self:SetAudioSnapshotOverride(fmodtable.Event.PartialOverlay_LP)
			:SetAudioEnterOverride(fmodtable.Event.ui_overlay_enter)
			:SetAudioExitOverride(fmodtable.Event.ui_overlay_exit)

	elseif cat == Screen.AudioCategory.s.Popup then
		self:SetAudioSnapshotOverride(fmodtable.Event.PopUp_LP)
			:SetAudioEnterOverride(fmodtable.Event.ui_popup_enter)
			:SetAudioExitOverride(fmodtable.Event.ui_popup_exit)

	elseif cat == Screen.AudioCategory.s.None then
		self:SetAudioSnapshotOverride(nil)
			:SetAudioEnterOverride(nil)
			:SetAudioExitOverride(nil)
	end
	return self
end

-- This must be an fmod event that plays a snapshot! That allows us to play
-- multiple snapshots and stack them on top of each other so removing the top
-- one doesn't remove them all.
-- Snapshots of consecutive screens will stack, so you need to control how they
-- interact in fmod (instance limit to 1).
function Screen:SetAudioSnapshotOverride(sound_event)
	dbassert(sound_event == nil or lume.find(fmodtable.Event, sound_event), "SetAudioSnapshotOverride requires an event, not a snapshot.")
	self.snapshot_sound = sound_event
	return self
end
-- Sound that plays on enter. Will be stopped by next screen enter sound.
function Screen:SetAudioEnterOverride(sound_event)
	self.enter_sound = sound_event
	return self
end
-- Sound that plays on exit. Will be stopped by next screen exit sound.
function Screen:SetAudioExitOverride(sound_event)
	self.exit_sound = sound_event
	return self
end

-- So long as this screen is open (but maybe not active or visible), we'll keep
-- this parameter set.
function Screen:PushAudioParameterWhileOpen(param)
	--allow audio to pass nothing if they don't want the music filtered
	if param == nil then
		return self
	end

	assert(param and type(param) == "string", "Should be an fmodtable entry: fmodtable.GlobalParameter.Music_InMenu")
	self.audio_params_while_open = self.audio_params_while_open or {}
	table.insert(self.audio_params_while_open, param)
	TheFrontEnd:PushAudioParameter(param)
	return self
end


local audiohandles = strict.strictify{
	screen_enter = "screen_enter",
	screen_exit = "screen_exit",
}

-- OnOpen is only called once when this instance is first displayed.
-- OnBecomeInactive is called when another screen is pushed on top and
-- OnBecomeActive when screens are popped off and this screen is displayed
-- again.
--
-- Not hugely different from ctor, but screen is hooked up to fe and active.
function Screen:OnOpen()
	if self.snapshot_sound then
		self.snapshot_handle = TheFrontEnd:GetSound():PlaySound_Autoname(self.snapshot_sound)
	end
	-- Kill any previous enter sound to avoid stacking long sounds.
	TheFrontEnd:GetSound():KillSound(audiohandles.screen_enter)
	TheFrontEnd:GetSound():KillSound(audiohandles.screen_exit)
	if self.enter_sound then
		TheFrontEnd:GetSound():PlaySound(self.enter_sound, audiohandles.screen_enter)
	end
end

function Screen:OnClose()
	for _,param in ipairs(self.audio_params_while_open or table.empty) do
		TheFrontEnd:PopAudioParameter(param)
	end
	TheFrontEnd:GetSound():KillSound(audiohandles.screen_enter)
	TheFrontEnd:GetSound():KillSound(audiohandles.screen_exit)
	if self.exit_sound then
		TheFrontEnd:GetSound():PlaySound(self.exit_sound, audiohandles.screen_exit)
	end
	if self.snapshot_handle then
		TheFrontEnd:GetSound():KillSound(self.snapshot_handle)
		self.snapshot_handle = nil
	end
	if self.close_cb then
		self.close_cb(self)
	end
end

function Screen:SetCloseCallback(cb)
	assert(not cb or not self.close_cb, "Clobbering close callback.")
	self.close_cb = cb
end

function Screen:OnUpdate(dt)
	Screen._base.OnUpdate(self, dt)
	return true
end

function Screen:OnBecomeInactive()
	for hunter_id=1,MAX_PLAYER_COUNT do
		self.last_focus[hunter_id] = self:GetDeepestFocus(hunter_id)
	end

	-- If this screen lost top, and has brackets, hide them
	if self.bracket_root then
		self.bracket_root:Hide()
	end

	TheInput:UnregisterForDeviceChanges(self.on_notify_input_mode_changed)
end

-- Called every time this instance is displayed. See OnOpen.
function Screen:OnBecomeActive()
	TheSim:SetUIRoot(self.inst.entity)

	for hunter_id=1,MAX_PLAYER_COUNT do
		local w = self.last_focus[hunter_id]
		if w and w.inst:IsValid() then
			w:SetFocus(hunter_id)
		else
			self:SetDefaultFocus(hunter_id)
		end
	end

	-- If this screen regained top, and should be showing brackets, do it
	if self.bracket_root then
		self.bracket_root:Show()
	end

	TheInput:RegisterForDeviceChanges(self.on_notify_input_mode_changed)
end

function Screen:AddEventHandler(event, fn)
	if not self.handlers[event] then
		self.handlers[event] = {}
	end

	self.handlers[event][fn] = true

	return fn
end

function Screen:RemoveEventHandler(event, fn)
	if self.handlers[event] then
		self.handlers[event][fn] = nil
	end
end

function Screen:HandleEvent(type, ...)
	local handlers = self.handlers[type]
	if handlers then
		for k, v in pairs(handlers) do
			k(...)
		end
	end
end

function Screen:FindDefaultFocus(hunter_id)
	return self.default_focus
end

function Screen:SetDefaultFocus(hunter_id)
	if hunter_id then
		local default_focus = self:FindDefaultFocus(hunter_id)
		if default_focus then
			default_focus:SetFocus(hunter_id)
			return true
		end
	else
		local found_focus = false
		for h_id=1,MAX_PLAYER_COUNT do
			local default_focus = self:FindDefaultFocus(h_id)
			if default_focus then
				default_focus:SetFocus(h_id)
				found_focus = true
			end
		end
		return found_focus
	end
end

function Screen:SetNonInteractive()
	self.is_noninteractive = true
	return self
end

-- OnFocusMove gets the widget to focus and ApplyFocusMove changes the focus.
function Screen:ApplyFocusMove(dir, input_device)
	if self.is_noninteractive then
		return false
	end

	local hunter_id = input_device:GetOwnerId_strict()

	local fe = self:GetFE()
	local focus = fe:GetFocusWidget(hunter_id)
	if not focus or focus == self then
		self:SetDefaultFocus(hunter_id)
		focus = fe:GetFocusWidget(hunter_id) or fe:GetFocusWidget()
		kassert.assert_fmt(
			focus,
			"Failed to find a focus widget. Set default_focus or implement SetDefaultFocus on '%s'.",
			self._widgetname
		)
		kassert.assert_fmt(
			focus ~= self,
			"Failed to find nonscreen focus widget. Set default_focus or implement SetDefaultFocus on '%s'.",
			self._widgetname
		)
	end
	-- OnFocusMove returns one of three values:
	-- * widget: give focus to this widget
	-- * true: ignore the focus move
	-- * false: didn't handle the focus move
	local new_focus = focus:OnFocusMove(dir, input_device)
	if new_focus and new_focus ~= true then
		if new_focus:HasMatchingFocusOwner(focus, input_device:GetPlayer()) then
			new_focus:SetFocus(hunter_id)
		else
			new_focus = nil
		end
	end
	return new_focus
end

-- show_immediately makes the focus brackets display on this widget straight away, no animation to it
function Screen:OnFocusChanged(new_focus, hunter_id, show_immediately)
	if self.focus_brackets
		and new_focus
		and new_focus.can_focus_with_nav
		and new_focus:IsVisible()
	then
		local selection_brackets = self:GetSelectionBracketsForPlayer(hunter_id)
		if self.focus_brackets_mouse_enabled or self:IsRelativeNavigation(hunter_id) then
			-- Move brackets to the focused element
			self:_UpdateSelectionBrackets(new_focus, show_immediately, selection_brackets)
		else
			selection_brackets:Hide()
		end
	end
end

function Screen:GetBoundingBox()
	local w, h = RES_X, RES_Y
	if self.fe then
		--w, h = self.fe:GetScreenDims()
		w, h = self:GetSize()
	end

	local x1, y1, x2, y2 = -w / 2, -h / 2, w / 2, h / 2
	return x1, y1, x2, y2
end

function Screen:OnScreenResize(w, h)
	Screen._base.OnScreenResize(self, w, h)
end

function Screen:GetSize()
	local w, h = RES_X, RES_Y
	--local w,h = TheFrontEnd:GetScreenDims()
	return w, h
end

function Screen:IsOnStack()
	if self.fe and self.fe:FindScreen(self) ~= nil then
		return true
	else
		return false
	end
end

function Screen:SinksInput()
	return not self.is_overlay or self.sinks_input
end

function Screen:SetupUnderlay( fade )
    if self.underlay then
        return
    end

    self.underlay = Image( "images/bg_loading/loading.tex" )
    self.underlay:SetAnchors( "fill", "fill" )
    self:AddChild( self.underlay, 1 )
		:MoveToBack()
    if fade then
        self.underlay:SetMultColorAlpha( 0 )
        self.underlay:AlphaTo( 1.0, 0.3, easing.outQuad )
    end
end

function Screen:SetTabLoop(tab_loop)
    for k,v in ipairs(tab_loop) do
        if k == 1 then
            v:SetFocusDir("prev", tab_loop[#tab_loop])
        else
            v:SetFocusDir("prev", tab_loop[k-1])
        end

        if k == #tab_loop then
            v:SetFocusDir("next", tab_loop[1])
        else
            v:SetFocusDir("next", tab_loop[k+1])
        end
    end
end

----------------------------------------------------------------------
-- Animate transitions                                             {{{

-- Offset matches 1.1 scale to ensures we don't see the edges of the screen bg.
local MAX_ANIM_OFFSET = Vector2(150, 150)

-- Simple screen transition animation for basic screens. Some screens should
-- have completely custom transitions, but many can just use this blend from
-- full transparency with a bit of motion.
--
-- Should gracefully handle quitting during animation with _AnimateOutToDirection.
--
-- @param dir Vector2: direction the screen appears from. Try stuff like:
--		-Vector2.unit_x
--		Vector2.unit_y:rotate(math.pi * 2 * 0.25)
--		Vector2.zero -- no movement, just alpha!
--		etc
function Screen:_AnimateInFromDirection(dir, total_duration)
	if self._screentask_anim_in then
		return
	end

	total_duration = total_duration or 0.5
	local offset = dir * MAX_ANIM_OFFSET

	self:StopUpdater(self._screentask_anim_out)
	self._screentask_anim_out = nil

	-- Hide elements
	self:SetMultColorAlpha(0)

	-- Alpha blend is slower to be smoother but still move into place quick.
	local move_duration = total_duration - 0.2

	local start_pos = self:GetPositionAsVec2()
	self._screentask_anim_in = Updater.Series({
			Updater.Parallel({
					Updater.Ease(function(v) self:SetMultColorAlpha(v) end, 0, 1, total_duration, easing.outQuad),
					Updater.Ease(function(v) self:SetScale(v) end, 1.1, 1, move_duration, easing.outQuad),
					Updater.Ease(function(v)
						local step_pos = start_pos + offset * v
						self:SetPosition(step_pos:unpack())
					end, 1, 0, move_duration, easing.outQuad),
				}),
			Updater.Do(function()
				self._screentask_anim_in = nil
			end),
		})

	self:RunUpdater(self._screentask_anim_in)
end

function Screen:_AnimateOutToDirection(dir, total_duration)
	if self._screentask_anim_out then
		return
	end

	total_duration = total_duration or 0.3
	local offset = dir * MAX_ANIM_OFFSET

	self:StopUpdater(self._screentask_anim_in)
	self._screentask_anim_in = nil

	TheFrontEnd:PopScreensAbove(self)
	self:Disable()

	local start_pos = self:GetPositionAsVec2()
	self._screentask_anim_out = Updater.Series({
			Updater.Parallel({
					-- Unlike animate in, we use the same duration for alpha to be a bit faster.
					Updater.Ease(function(v) self:SetMultColorAlpha(v) end, 1, 0, total_duration, easing.outQuad),
					Updater.Ease(function(v) self:SetScale(v) end, 1, 1.1, total_duration, easing.outQuad),
					Updater.Ease(function(v)
						local step_pos = start_pos + offset * v
						self:SetPosition(step_pos:unpack())
					end, 0, 1, total_duration, easing.outQuad),
				}),
			Updater.Do(function()
				self._screentask_anim_out = nil
				TheFrontEnd:PopScreen(self)
			end),
		})

	self:RunUpdater(self._screentask_anim_out)
end


----------------------------------------------------------------------
-- Focus brackets                                                  {{{

local FocusBrackets = Class(Widget, function(self, hunter_id, texture, minx, miny, maxx, maxy, border_scale)
	Widget._ctor(self, "FocusBrackets")

	self.hunter_id = hunter_id

	minx = minx or 78
	miny = miny or 94
	maxx = maxx or 80
	maxy = maxy or 96
	border_scale = border_scale or 0.8

	self
		:SetHiddenBoundingBox(true)
		:IgnoreInput(true)
		:Hide()

	self.bottom = self:AddChild(Panel(texture.color_bg or "images/ui_ftf/selection_brackets_fill.tex"))
		:SetNineSliceCoords(minx, miny, maxx, maxy)
		:SetNineSliceBorderScale(border_scale)
		:SetMultColor(UICOLORS.PLAYERS[hunter_id])
	self.top = self:AddChild(Panel(texture.black_fg or "images/ui_ftf/selection_brackets_overlay.tex"))
		:SetNineSliceCoords(minx, miny, maxx, maxy)
		:SetNineSliceBorderScale(border_scale)

	self.brackets_w = 100
	self.brackets_h = 100
	-- Animate them too
	local speed = 1.35 * 2
	self:RunUpdater(
		Updater.Loop({
				Updater.Ease(function(v) self:SetAnimProgress(v) end, 0, 1, speed, easing.linear),
		}))
end)

local anim_offset = {
	0,
	0.5, -- biggest offset for 2p
	0.25,
	0.75,
}
function FocusBrackets:SetAnimProgress(t)
	local amplitude = 14
	-- Offset anim for each player so they don't hide each other.
	local offset = anim_offset[self.hunter_id]
	t = t + offset
	t = lume.pingpong(t * 2)
	t = ease.quadinout(t)
	local s = t * amplitude
	self:SetSize(self.brackets_w + s, self.brackets_h + s)
	return self
end

function FocusBrackets:SetSize(...)
	self.bottom:SetSize(...)
	self.top:SetSize(...)
	return self
end

function FocusBrackets:HasValidPlayer()
	if InGamePlay() then
		local player = playerutil.GetByHunterId(self.hunter_id)
		return player and player:IsLocal()
	else
		return self.hunter_id == 1
	end
end

function Screen:GetSelectionBracketsForPlayer(player_id)
	dbassert(player_id)
	return self.focus_brackets and self.focus_brackets[player_id]
end

-- If you SetOwningPlayer on this widget or its parent, then we'll get their
-- selection brackets.
function Screen:GetSelectionBracketsForWidget(widget)
	dbassert(widget)
	local player = widget:GetOwningPlayer()
	local player_id = player and player:GetHunterId() or 1
	return self:GetSelectionBracketsForPlayer(player_id)
end

-- I don't see a good reason to destroy them outside of debug.
function Screen:Debug_DestroyFocusBrackets()
	self.bracket_root:Remove()
	self.bracket_root = nil
	self.focus_brackets = nil
end

function Screen:_CreateFocusBrackets(texture, minx, miny, maxx, maxy, border_scale)
	if self.focus_brackets then
		-- Don't add more brackets
		return self
	end
	texture = texture or table.empty

	self.focus_brackets = {}
	self.bracket_root = self:AddChild(Widget("bracket_root"))

	for hunter_id=1,MAX_PLAYER_COUNT do
		self.focus_brackets[hunter_id] = self.bracket_root:AddChild(FocusBrackets(hunter_id, texture, minx, miny, maxx, maxy, border_scale))
	end

	return self
end

-- Usually you call one of these *after* you animate the screen in. That
-- presents nicely and ensures we have our owner setup.
--
-- Calling too early may assert about invalid ancestor.
function Screen:EnableFocusBracketsForGamepad(texture, minx, miny, maxx, maxy, border_scale)
	self:_CreateFocusBrackets(texture, minx, miny, maxx, maxy, border_scale)
	self:_ImmediatelyShowFocusBrackets()
	return self
end

function Screen:EnableFocusBracketsForGamepadAndMouse(texture, minx, miny, maxx, maxy, border_scale)
	self.focus_brackets_mouse_enabled = true
	self:EnableFocusBracketsForGamepad(texture, minx, miny, maxx, maxy, border_scale)
	return self
end

function Screen:HideFocusBracketsUntilMove(hunter_id)
	dbassert(self.focus_brackets, "Did you call EnableFocusBracketsForGamepad yet?")
	local owner = self:GetOwningPlayer()
	hunter_id = hunter_id or owner and owner:GetHunterId()
	local h_min = 1
	local h_max = MAX_PLAYER_COUNT
	if hunter_id then
		h_min = hunter_id
		h_max = hunter_id
	end
	for h_id=h_min,h_max do
		local brackets = self:GetSelectionBracketsForPlayer(h_id)
		kassert.assert_fmt(brackets, "Did this screen make its own self.focus_brackets? player=%s", h_id)
		brackets:Hide()
	end
	return self
end

-- TODO: Do we need this? Maybe if a scroll list scrolls, then we need to refresh positions?
--~ function Screen:RefreshFocusBrackets(show_immediately)
--~ 	for hunter_id=1,MAX_PLAYER_COUNT do
--~ 		local w = TheFrontEnd:GetFocusWidget(hunter_id)
--~ 		self:OnFocusChanged(w, hunter_id, show_immediately)
--~ 	end
--~ end

function Screen:_ImmediatelyShowFocusBrackets()
	dbassert(self.focus_brackets, "Did you call EnableFocusBracketsForGamepad yet?")
	local owner = self:GetOwningPlayer()
	if owner then
		local hunter_id = owner:GetHunterId()
		self:OnFocusChanged(TheFrontEnd:GetFocusWidget(hunter_id), hunter_id, true)
	else
		for hunter_id=1,MAX_PLAYER_COUNT do
			self:OnFocusChanged(TheFrontEnd:GetFocusWidget(hunter_id), hunter_id, true)
		end
	end
end

-- If show_immediately, then the brackets will show on the target_widget
-- straight away, with no animation. Used when opening a screen
function Screen:_UpdateSelectionBrackets(target_widget, show_immediately, selection_brackets)
	selection_brackets = selection_brackets or self:GetSelectionBracketsForWidget(target_widget)
	if not self.focus_brackets
		or not selection_brackets:NeedsUpdate(target_widget)
	then
		return self
	end

	if selection_brackets:HasValidPlayer() then
		selection_brackets:MoveToWidget(target_widget, show_immediately)
	end
end

function FocusBrackets:MoveToWidget(target_widget, snap)
	-- Get the brackets' starting position
	local start_pos = self:GetPositionAsVec2()
	-- Get starting size
	local start_w, start_h = self:GetSize()

	-- Align them with the target
	self:LayoutBounds("center", "center", target_widget)
		:Offset(target_widget:GetFocusBracketsOffset())

	-- Get the new position
	local end_pos = self:GetPositionAsVec2()

	-- And the new size
	local w, h = target_widget:GetBracketSizeOverride()
	if w == nil or h == nil then
		w, h = target_widget:GetScaledSize()
	end

	local end_w, end_h = w + 60, h + 60

	-- If we're starting the brackets right now, don't animate them into place.
	-- Just start them at the end position.
	if snap then
		start_pos = end_pos
		start_w, start_h = end_w, end_h
	end

	-- Calculate midpoint
	local mid_pos = start_pos:lerp(end_pos, 0.2)
	-- Calculate a perpendicular vector from the midpoint
	local dir = start_pos - end_pos
	dir = dir:perpendicular()
	dir = dir:normalized()
	dir = mid_pos + dir*250

	-- Move them back and animate them in
	self:SetPos(start_pos.x, start_pos.y)
		:CurveTo(end_pos.x, end_pos.y, dir.x, dir.y, 0.35, easing.outElasticUI)
		:Ease2dTo(function(w, h)
			self.brackets_w = w
			self.brackets_h = h
		end, start_w, end_w, start_h, end_h, 0.1, easing.linear)

	self.last_target_widget = target_widget
	self.last_pos = target_widget:GetPositionAsVec2()
	self:Show()
	return self
end

function FocusBrackets:NeedsUpdate(target_widget)
	return (target_widget ~= self.last_target_widget
		or not self.last_pos
		or self.last_pos.x ~= target_widget.x
		or self.last_pos.y ~= target_widget.y)
end

----------------------------------------------------------------------{{{

Screen.FocusBrackets = FocusBrackets

return Screen
