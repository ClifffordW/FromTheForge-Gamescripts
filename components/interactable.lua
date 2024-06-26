local DebugDraw = require "util.debugdraw"
local Enum = require "util.enum"
local kassert = require "util.kassert"
local Lume = require "util.lume"

local function noop() end
local function AlwaysTrue()
	return true
end


-- Allow the player to interact with an object.
--
-- Prefer this over playerprox for interactions because it only does one space
-- query per player per frame instead of one per playerproxradial/rect.
--
-- See StartInteract for interaction flow description.
local Interactable = Class(function(self, inst)
	self.inst = inst
	self.radius = 0
	self.ongainfocusfn = noop
	self.onlosefocusfn = noop
	self.caninteractfn = AlwaysTrue

	-- is_locked_on_focus is a mode, not a state variable. An Interactable with is_locked_on_focus set to true will
	-- permit only a single player to gain focus and a subsequent locked interaction.
	-- This mode needs to be enforced by the client by ensuring that OnGainInteractFocus is only invoked if 
	-- CanPlayerInteract is true.
	self.is_locked_on_focus = false

	-- self.lock will point at the interacting player during the interaction. It will be nil during the focus phase.
	self.lock = nil

	self.focused_players = {}

	self.abort_state_name = "idle"

	self:SetInteractCondition_Always()

	TheWorld:PushEvent("registerinteractable", self.inst)
	
	self._onplayerexited = function(source, player)
		if Lume(self.focused_players):find(player):result() or self.lock == player then
			self:ForceClearInteraction(player)
		end
	end
	self.inst:ListenForEvent("playerexited", self._onplayerexited, TheWorld)
end)

-- The maximum radius seen in any interactable ever spawned in the current world.
Interactable.MAX_RADIUS = 0

function Interactable:GetFocusedPlayerCount()
	return Lume.count(self.focused_players)
end

-- Avoid removing Interactable from entities. Use SetInteractCondition_Never to
-- disable interaction to avoid re-doing setup to re-activate interaction.
function Interactable:OnRemoveFromEntity()
	local focused_player_count = self:GetFocusedPlayerCount()
	if focused_player_count ~= 0 or self.lock then
		TheLog.ch.Interact:printf(
			"OnRemoveFromEntity() while active on <%s>. lock[%s] focused_players count[%d] IsLocalOrMinimal[%s]", 
			self.inst, 
			self.lock, 
			focused_player_count, 
			self.inst:IsLocalOrMinimal()
		)
	end

	self:ForceClearAllInteractions()

	kassert.assert_fmt(
		not self.lock, 
		"The state on SetAbortStateName should not restart interaction! Are we stuck in the interaction now? In OnRemoveFromEntity() on [%s] while active on [%s] and transitioned to [%s].", 
		self.inst, 
		self.lock, 
		self.abort_state_name
	)

	self.inst:RemoveEventCallback("playerexited", self._onplayerexited, TheWorld)

	self:SetInteractCondition_Never()
	dbassert(not self.inst:HasTag("interactable"))
end
Interactable.OnRemoveEntity = Interactable.OnRemoveFromEntity


-- Several main areas of config:
-- * when is interaction allowed
-- * what happens when interaction becomes allowed/disallowed
-- * what happens when interaction is triggered
-- * helpers for common configuration

------------------------------
-- is interaction allowed {{{2

function Interactable:SetRadius(radius)
	self.radius = radius
	Interactable.MAX_RADIUS = math.max(Interactable.MAX_RADIUS, radius)
	return self
end

function Interactable:GetRadius()
	return self.radius
end

function Interactable:SetInteractionOffset(player_pos_delta)
	assert(player_pos_delta)
	assert(player_pos_delta.x >= 0, "We match x to player side, so negative doesn't make sense.")
	-- Table since other tuning is likely necessary.
	self.offset_tuning = {
		player_pos_delta = player_pos_delta,
	}
	return self
end

function Interactable:GetInteractionWorldPosition(player)
	if not self.offset_tuning then
		-- No position means it can happen anywhere.
		return
	end
	local pos = self.inst:GetPosition()
	local player_pos = player:GetPosition()
	local is_player_on_left = player_pos.x < pos.x
	local sign = 1
	if is_player_on_left then
		sign = -1
	end
	local delta = self.offset_tuning.player_pos_delta:clone()
	delta.x = delta.x * sign
	return TheWorld.Map:FindClosestWalkablePoint(pos + delta)
end

-- In addition to radius, we'll check this predicate. Pass nil to only check
-- radius. fn returns whether we can interact and a reason (for debug).
function Interactable:SetInteractConditionFn(fn)
	self.inst:AddTag("interactable")
	self.caninteractfn = fn or AlwaysTrue
	return self
end

-- Instead of removing interactable to disable interaction, use
-- SetInteractCondition_Never.
function Interactable:SetInteractCondition_Never()
	self:SetInteractConditionFn(noop)
	-- Remove tag to remove the interactable from space querying.
	self.inst:RemoveTag("interactable")
	return self
end
function Interactable:SetInteractCondition_Always()
	return self:SetInteractConditionFn(AlwaysTrue)
end

-- Can the fn passed to SetInteractConditionFn break us out of focus, or are we
-- only limited by radius once focused?
function Interactable:SetCanConditionBreakFocus(can_condition_break_focus)
	self.can_break_focus = can_condition_break_focus
	return self
end

-- Steal interaction clicks from another object. Useful when target is visible
-- but self is not. Affects mouse clicks but not position-base interaction
-- selection.
function Interactable:StealInteractionClicksFrom(target)
	assert(not target:HasTag("interactable"), "Not sure it's a good idea to steal interactions from an actual interactable.")
	target.GetInteractionClickStealer = function(inst)
		return self.inst
	end
	return self
end

------------------------------
-- when interaction is (dis)allowed {{{2


function Interactable:SetOnGainInteractFocusFn(fn)
	assert(fn, "Clearing a callback? Probably unintentional.")
	self.ongainfocusfn = fn
	return self
end

function Interactable:SetOnLoseInteractFocusFn(fn)
	assert(fn, "Clearing a callback? Probably unintentional.")
	self.onlosefocusfn = fn
	return self
end

-- By default, any player can activate/deactivate an interactable.
-- Setting this to true will only allow the first player that focuses to also unfocus.
function Interactable:SetLockOnFocus(is_locked_on_focus)
	dbassert(is_locked_on_focus ~= nil)
	self.is_locked_on_focus = is_locked_on_focus
	return self
end

------------------------------
-- when interaction is triggered {{{2

-- To animate the player during interactions, the player needs a StateGraph
-- state that will perform the animation and trigger StartInteract.
function Interactable:SetInteractStateName(state_name)
	-- I assume if it's on the hammer it will be on everything?
	dbassert(require("stategraphs.sg_player_hammer").states[state_name], "Not a valid sg state name.")
	self.state_name = state_name
	return self
end


-- Jump to this state when interaction is force cleared. It might be
-- interrupted by destruction of the interactable (usually because of a remote
-- player destroying), by the cleanup task, or something else. We'll clear the
-- Interaction *before* we jump to this state.
--
-- Defaults to 'idle'.
function Interactable:SetAbortStateName(state_name)
	dbassert(require("stategraphs.sg_player_hammer").states[state_name], "Not a valid sg state name.")
	self.abort_state_name = state_name
	return self
end

function Interactable:GetInteractStateName()
	return self.state_name or "pickup"
end

function Interactable:SetOnInteractFn(fn)
	self.oninteractfn = fn
	return self
end

------------------------------
-- common use cases {{{2

local PromptType = Enum{
	"Button",
	"Label",
}

-- Sets up for button prompt.
--
-- label can be a function to make it dynamic to current state. The
-- label will only change when the interaction gains focus or
-- after ForceClearInteraction.
--
-- y_offset is in world-space so it better adjusts as the camera moves.
function Interactable:SetupForButtonPrompt(label, ongainfocusfn, onlosefocusfn, y_offset)
	return self:_SetupForPrompt(PromptType.id.Button, label, ongainfocusfn, onlosefocusfn, y_offset)
end

function Interactable:_SetupForPrompt(prompt_type, label, ongainfocusfn, onlosefocusfn, y_offset)
	assert(PromptType:ContainsId(prompt_type))
	y_offset = y_offset or 4
	ongainfocusfn = ongainfocusfn or noop
	onlosefocusfn = onlosefocusfn or noop
	assert(not self.lock, "Only call SetupForButtonPrompt on object init, not after interactions.")
	self:SetOnGainInteractFocusFn(function(inst, player)
		local text = label
		if type(label) == "function" then
			text = label(inst, player)
		end
		local prompt
		if prompt_type == PromptType.id.Button then
			prompt = TheDungeon.HUD:ShowPrompt(inst, player)
				:SetTextAndResizeToFit(text, 50, 25)
				:SetOnClick(function()
					if TheFrontEnd:IsRelativeNavigation() then
						-- keyboard and gamepad click the button without going through onclick.
						return
					end
					if self:IsPlayerInteracting(player) then
						-- Possibly used interact key simultaneously with clicking button.
						return
					end
					local can_interact, reason = self:CanPlayerInteract(player, true)
					kassert.assert_fmt(can_interact, "Can't interact: '%s'. Why didn't we close prompt?", reason)
					local data = {
						target = inst,
						dir = 0,
					}
					player.components.playercontroller:SnapToInteractEvent(data)
					TheDungeon.HUD:HidePrompt(inst)
				end)

		elseif prompt_type == PromptType.id.Label then
			prompt = TheDungeon.HUD:ShowLabelPrompt(inst, player)
				:SetText(text)

		else
			error("Forgot to implement a PromptType.")
		end
		prompt:SetOffsetFromTarget(Vector3.unit_y * y_offset)
		ongainfocusfn(inst, player)
	end)
	self:SetOnLoseInteractFocusFn(function(inst, player)
		TheDungeon.HUD:HidePrompt(inst)
		onlosefocusfn(inst, player)
	end)
	return self
end

-- Similar to SetupForButtonPrompt, but not clickable. Good for button hold
-- or combo interactions.
function Interactable:SetupForLabelPrompt(label, ongainfocusfn, onlosefocusfn, y_offset)
	return self:_SetupForPrompt(PromptType.id.Label, label, ongainfocusfn, onlosefocusfn, y_offset)
end

local function ShowInteractIndicator(inst, player, indicator_prefab)
	if inst.indicator == nil then
		inst.indicator = SpawnPrefab(indicator_prefab, inst)
		inst.indicator.entity:SetParent(inst.entity)
		inst.indicator.components.targetindicator:SetRadius(.75)
		inst.indicator.components.targetindicator:SetTarget(player)
	end
	inst:RemoveTag("NOCLICK")
end

local function HideInteractIndicator(inst, player)
	if inst.indicator ~= nil then
		inst.indicator:Remove()
		inst.indicator = nil
	end
	inst:AddTag("NOCLICK")
end

-- Sets up a targetindicator (something visual in-world to show that we're
-- interactive).
-- indicator_prefab must have a targetindicator component.
function Interactable:SetupTargetIndicator(indicator_prefab, ongainfocusfn, onlosefocusfn)
	ongainfocusfn = ongainfocusfn or noop
	onlosefocusfn = onlosefocusfn or noop
	self:SetOnGainInteractFocusFn(function(inst, player)
		ShowInteractIndicator(inst, player, indicator_prefab)
		ongainfocusfn(inst, player)
	end)
	self:SetOnLoseInteractFocusFn(function(inst, player)
		HideInteractIndicator(inst, player)
		onlosefocusfn(inst, player)
	end)
	return self
end



------------------------------
-- State Queries {{{1


-- Are they in the middle of an interaction. Focus (visible prompt) is a
-- different question.
function Interactable:IsPlayerInteracting(player)
	return player == self.lock
end

function Interactable:CanPlayerInteract(player, is_focused, suppress_busy_filter)
	if not player:IsLocal() then
		return false, "remote player"
	end

	if self.lock then
		-- Never allow another interaction while active.
		--~ dbassert(not self:IsPlayerInteracting(player), "Did you mean to call IsPlayerInteracting?")
		return false, "active interaction"
	end

	if self.is_locked_on_focus and self:GetFocusedPlayerCount() ~= 0 then
		if Lume(self.focused_players):any(function(focused_player) return focused_player ~= player end):result() then
			-- Another player is focused but we're exclusive.
			return false, "is_locked_on_focus"
		end
	end

	local interactable = player.components.interactor:GetCurrentInteraction()
	if interactable and interactable ~= self.inst then
		return false, "player in another interaction"
	end

	-- If you start an interaction when busy, you will get stuck in a state.
	-- Also, preventing interaction while busy conveniently fixes bugs like
	-- "convo doesn't refresh after I drink potion".
	local busy = not suppress_busy_filter and player.sg:HasStateTag("busy")
	if busy
		-- Turning isn't busy enough to prevent interaction. Prevents
		-- interaction prompt flickering when moving mouse around.
		and not player.sg:HasStateTag("turning")
	then
		return false, "player busy: " .. player.sg:GetCurrentState()
	end

	if player.emote_ring
		and player.emote_ring:IsRingShowing()
	then
		return false, "selecting emote"
	end

	if is_focused and not self.can_break_focus then
		return true
	end

	--TODO: multi-player handling shared interaction targets
	return self.caninteractfn(self.inst, player, is_focused)
end

------------------------------
-- PlayerController api {{{1


-- When Player is given the option to interact.
function Interactable:OnGainInteractFocus(player)
	if not player:IsLocal() then
		return
	end

	TheLog.ch.InteractSpam:printf("OnGainInteractFocus(%s)", player)
	TheLog.ch.InteractSpam:indent()

	dbassert(not self.is_locked_on_focus or not Lume.find(self.focused_players, player))

	--~ TheLog.ch.Interact:printf("OnGainInteractFocus(<%s>) on <%s>", player, self.inst)
	table.insert(self.focused_players, player)
	self.ongainfocusfn(self.inst, player)
	self.inst:PushEvent("gain_interact_focus", player)
	TheLog.ch.InteractSpam:unindent()
end

function Interactable:OnLoseInteractFocus(player)
	if not player:IsLocal() then
		return
	end
	
	TheLog.ch.InteractSpam:printf("OnLoseInteractFocus(%s)", player)
	TheLog.ch.InteractSpam:indent()

	if self.is_locked_on_focus and not Lume.find(self.focused_players, player) then
		-- Ignore late lost focus notifications.
		TheLog.ch.InteractSpam:printf("Ignore late lost focus notifications.")
		TheLog.ch.InteractSpam:unindent()
		return
	end

	if self.lock == player then
		TheLog.ch.Interact:print("Interaction is active and needs to be stopped with ClearInteract. Ignoring focus OnLoseInteractFocus.")
		TheLog.ch.InteractSpam:unindent()
		return
	end

	--~ TheLog.ch.Interact:printf("OnLoseInteractFocus(<%s>) on <%s>", player, self.inst)
	Lume.remove(self.focused_players, player)
	self.onlosefocusfn(self.inst, player)
	self.inst:PushEvent("lose_interact_focus", player)
	TheLog.ch.InteractSpam:unindent()
end

-- Interaction is intended to be multi stage:
-- 1. GainInteractFocus: (optional) Indicate this interaction is available to
--    the player.
-- 2. StartInteract: Lock interaction to a player. may have no visible state
--    change but prevents other players from interacting.
-- 3. PerformInteract: Actually perform the interaction. Object may
--    be destroyed after this step. If not, it's still locked.
-- 4. ClearInteract: (optional) If object wasn't destroyed, release it so other
--    players may interact with it. If the object is destroyed before calling
--    ClearInteract, we'll jump to the SetAbortStateName state.
-- 5. LoseInteractFocus: (automatic) Indicate this interaction is no longer
--    available to the player. Handled by playercontroller or trigged after
--    ClearInteract.
--
-- These stages ensures we have a stable interaction target and the interaction
-- is locally exclusive (no two players interacting with the same item). We
-- need separate handling for network exclusive because interactables have
-- different network behaviour (destroy after interact, simultaneous network
-- interact, etc).
function Interactable:StartInteract(player)
	TheLog.ch.InteractSpam:printf("StartInteract(<%s>) on <%s> for '%s'", player, self.inst, self:GetInteractStateName())
	return self:_StartInteract(player)
end
function Interactable:_StartInteract(player)
	assert(player)
	assert(not self.lock, "Didn't expect multiple simultaneous interactions.")
	self.lock = player
	player.components.interactor:LockInteraction(self) -- tightly paired with changing self.lock
	player.components.interactor:StartSafetyTask(self)
end

function Interactable:PerformInteract(player)
	TheLog.ch.InteractSpam:printf("PerformInteract(<%s>) on <%s>", player, self.inst)
	TheLog.ch.InteractSpam:indent()
	local result = self:_PerformInteract(player)
	TheLog.ch.InteractSpam:unindent()
	return result
end
function Interactable:_PerformInteract(player)
	TheLog.ch.InteractSpam:printf("_PerformInteract(<%s>) on <%s>", player, self.inst)
	assert(player)
	assert(self.lock, "Always call StartInteract before PerformInteract.")
	assert(self:IsPlayerInteracting(player), "Incorrect player is calling PerformInteract.")

	player.components.interactor:CancelSafetyTask(self)

	local target_pos = self:GetInteractionWorldPosition(player)
	if target_pos then
		local pos = self.inst:GetPosition()
		player.components.forcedlocomote:LocomoteTo(target_pos, 1 * SECONDS, 0.5, pos)
	end

	self.oninteractfn(self.inst, player)

	self.inst:PushEvent("perform_interact", player)
end

function Interactable:ClearInteract(player, retain_target, suppress_busy_filter)
	TheLog.ch.InteractSpam:printf("ClearInteract(<%s>) on <%s>", player, self.inst)
	TheLog.ch.InteractSpam:indent()
	local result = self:_ClearInteract(player, retain_target, suppress_busy_filter)
	TheLog.ch.InteractSpam:unindent()
	return result
end
function Interactable:_ClearInteract(player, retain_target, suppress_busy_filter)
	TheLog.ch.InteractSpam:printf("_ClearInteract(<%s>) on <%s>", player, self.inst)
	TheLog.ch.InteractSpam:indent()

	assert(player)
	assert(self.lock, "Always call StartInteract before ClearInteract.")
	assert(self:IsPlayerInteracting(player), "Incorrect player is calling PerformInteract.")

	player.components.interactor:CancelSafetyTask(self)

	self.lock = nil
	player.components.interactor:UnlockInteraction(self)

	-- Typically you should not need to retain the target. This is a bit of a workaround to allow the player to 
	-- remain in one state for a long time and repeatedly start, perform, and complete an interaction within one frame, 
	-- while allowing the UI to stay up. See the interaction with vending machines, sg_player_common's deposit_currency 
	-- at time of writing.
	retain_target = retain_target and self:CanPlayerInteract(player, true, suppress_busy_filter)

	if not retain_target then
		-- Clear interact. Preferably through player controller.
		local playercontroller = player.components.playercontroller
		if playercontroller:GetInteractTarget() == self.inst then
			playercontroller:SetInteractTarget(nil)
		else
			self:OnLoseInteractFocus(player)
		end
		dbassert(
			not Lume.find(self.focused_players, player), 
			"Failed to clear focus. Calling ClearInteract from wrong (non interacting) player?"
		)
	end

	TheLog.ch.InteractSpam:unindent()
end

-- Perform an interact that resolves in a single frame. Intended for
-- interactions that occur from onupdate and don't prevent other players from
-- performing them. (Like holding a button to fill up a meter.)
function Interactable:ExecuteRepeatedInteract(player, n_interactions)
	TheLog.ch.InteractSpam:printf("ExecuteRepeatedInteract(<%s>) on <%s>", player, self.inst)
	TheLog.ch.InteractSpam:indent()
	dbassert(not self.lock, "Call interactable:ClearInteract(inst, true) from onenter before calling ExecuteRepeatedInteract from onupdate.")
	-- No logging here because we run this from sg's onupdate.
	local can, reason = self:CanPlayerInteract(player)
	if can then
		self:_StartInteract(player)
		for _ = 1, n_interactions do
			self:_PerformInteract(player)
			-- Bypass CanPlayerInteract to poll the client directly. We are in
			-- control of our interactable status, but we need to terminate
			-- when the client says so.
			can, reason = self.caninteractfn(self, player)
			if not can then
				break
			end
		end
		-- Don't make the interaction last multiple frames: clear it up
		-- immediately this frame.
		self:_ClearInteract(player, true)
	end
	TheLog.ch.InteractSpam:unindent()
	return can, reason
end

-- To ensure the current interact gets cleared (if it becomes invalid while
-- focused). We don't check CanPlayerInteract in update, so if your system may
-- change interact validity after we gain focus, call this to clear.
--
-- Aborts in-progress interactions (animations, pending state) *when* the
-- stategraph cleans up when transitioning to abort_state_name.
function Interactable:ForceClearInteraction(player)
	TheLog.ch.Interact:printf(
		"ForceClearInteraction(%s) on <%s>. lock=<%s>, focused=<%d>",
		player,
		self.inst, 
		self.lock, 
		self:GetFocusedPlayerCount()
	)
	TheLog.ch.Interact:indent()
	if self.lock == player then 
		self.lock.sg:GoToState(self.abort_state_name)
		-- lock is usually cleared now, but for safety:
		if self.lock then
			self:ClearInteract(self.lock)
		end
		dbassert(not self.lock, "self.lock should have been cleared")
	end
	player.components.interactor:CancelSafetyTask(self)
	-- Clearing interact target will make us lose focus and make the player
	-- re-select an interact target (so we can gain focus again if valid).
	player.components.playercontroller:SetInteractTarget(nil)
	dbassert(not Lume(self.focused_players):find(player):result(), "Failed to clear our focus!")
	TheLog.ch.Interact:unindent()
end

function Interactable:ForceClearAllInteractions()
	local players_to_unfocus = shallowcopy(self.focused_players)
	Lume(players_to_unfocus):each(function(player)
		self:ForceClearInteraction(player)		
	end)
	dbassert(self:GetFocusedPlayerCount() == 0)
end

------------------------------
-- Debug api {{{1


function Interactable:DebugDrawEntity(ui, panel, colors)
	if Interactable.MAX_RADIUS == 0 then
		ui:TextColored(WEBCOLORS.YELLOW, "MAX_RADIUS = 0. Probably because we hot reloaded this file.")
		-- Setting MAX_RADIUS at this point doesn't seem to change the value in
		-- PlayerController. Maybe because of how entity component caching
		-- works?
	end
	local color = WEBCOLORS.ORANGE
	ui:TextColored(colors.header, "Config")
	self.radius = ui:_SliderFloat("Interaction radius", self.radius, 0.001, 10)
	ui:SameLineWithSpace()
	ui:ColorButton("Interaction radius##color", color)
	local x,z = self.inst.Transform:GetWorldXZ()
	DebugDraw.GroundCircle(x, z, self.radius, color)
	ui:Value("Is Locked On Focus", self.is_locked_on_focus)
	ui:TextColored(colors.header, "State")
	ui:Value("Focused Player Count", self:GetFocusedPlayerCount())
	ui:Value("Interacting Player", self.lock or "<none>")
	for i,player in ipairs(AllPlayers) do
		local can_interact, reason = self:CanPlayerInteract(player)
		ui:Value("CanPlayerInteract(P".. i ..")", can_interact and ui.icon.done or ui.icon.wrong)
		ui:SameLineWithSpace()
		ui:Text(reason or "")
	end
end

function Interactable:GetDebugString()
	local t = {}
	for i,player in ipairs(AllPlayers) do
		local can_interact, reason = self:CanPlayerInteract(player)
		table.insert(t, string.format("CanPlayerInteract(P%i) = %s: [%s]", i, can_interact, reason or "<no reason>"))
	end
	return string.format("radius[%0.3f] is_locked_on_focus[%s] focused_players[%d] lock[%s]\n  %s",
		self.radius,
		self.is_locked_on_focus,
		self:GetFocusedPlayerCount(),
		self.lock,
		table.concat(t, "\n  "))
end

return Interactable
