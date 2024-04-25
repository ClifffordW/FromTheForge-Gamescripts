local Mastery = require "defs.masteries"
local MasteryPath = require"defs.mastery.masterypath"
local itemforge = require "defs.itemforge"

local iterator = require "util.iterator"
local lume = require "util.lume"

require "util"

local function create_default_data()
	local data =
	{
		masteries = {
			-- a list of all the masteries the player currently has
			-- slot = { ["mastery_name"] = mastery_def, ... },
		},

		acquire_index = 0,
	}

	for _, slot in pairs(Mastery.Slots) do
		assert(not data.masteries[slot], "The following slot already exists:"..slot)
		data.masteries[slot] = {}
	end

	return data
end

local MasteryManager = Class(function(self, inst)
	self.inst = inst
	self.data = create_default_data() -- mastery items (persistent data)
	self.masteries = {} -- mastery list (transient data)
	self.event_triggers = {}
	self.remote_event_triggers = {}
	self.update_masteries = {}
end)

function MasteryManager:OnSave()
	local mastery_data = deepcopy(self.data)

	for _,slot in pairs(mastery_data.masteries) do
		itemforge.ConvertToListOfSaveableItems(slot)
	end

	local data =
	{
		mastery_data = mastery_data,
	}

	return data
end

function MasteryManager:OnLoad(data)
	if data ~= nil then
		local mastery_data = deepcopy(data.mastery_data)
		for _,slot in pairs(mastery_data.masteries) do
			itemforge.ConvertToListOfRuntimeItems(slot)
		end

		-- Keeps older saves that didn't have rarities saved into their masteries working.
		for _,slot in pairs(mastery_data.masteries) do
			for k, v in pairs(slot) do
				if not v:GetRarity() then
					v:SetRarity(ITEM_RARITY.s.COMMON)
				end
			end
		end

		self.data = mastery_data
	end

	-- Init all first so masteries that depend on each other are fully init
	-- before firing events.
	local masteries = {}
	for _, slot in pairs(self.data.masteries) do
		for _, mastery in pairs(slot) do
			table.insert(masteries, self:_InitMastery(mastery))
		end
	end
	for _, mastery in ipairs(masteries) do
		self:_RegisterMastery(mastery)
	end

	-- Always make sure the player has this mastery, even from their first run.
	-- This is not part of 'default masteries' because those don't get delivered until the player speaks to Toot.
	-- This should be active from starting the game, in case they kill megatreemon on run 1.

	if not self:GetMasteryByName("megatreemon_kill") then
		self:AddMasteryByName("megatreemon_kill")
	end

	self:EvaluatePaths()

	self:RefreshTags()
end

function MasteryManager:_InitMastery(mastery)
	local mas = Mastery.MasteryInstance(mastery)
	assert(self.masteries[mas.def.name] == nil)
	mas:SetManager(self)
	self.masteries[mas.def.name] = mas

	-- Set up the update thresholds
	mas.persistdata.update_thresholds = {}
	for _,threshold in ipairs(mas.def.update_thresholds) do
		table.insert(mas.persistdata.update_thresholds, { threshold = threshold, updated = false })
	end

	return mas
end

function MasteryManager:_RegisterMastery(mastery)

	--set up event triggers if the mastery is not yet complete
	if not mastery:IsComplete() then
		self:SetUpEventTriggers(mastery)
	end

	if mastery.def.on_add_fn then
		mastery.def.on_add_fn(mastery, self.inst)
	end

	if mastery.def.on_update_fn then
		self:AddUpdateMastery(mastery)
	end

	-- Check to make sure they have all the masteries unlocked that they should. In case we add any new "next steps" after they already claimed it.
	if mastery.persistdata.claimed and mastery.def.next_step then
		for _,next_step in ipairs(mastery.def.next_step) do
			local def = Mastery.FindMasteryByName(next_step)
			if not self:GetMastery(def) then
				TheLog.ch.MasteryManager:printf("Found new next_step mastery for [%s]: %s. Adding it now.", mastery.def.name, def.name)
				self:AddMasteryByDef(def, true)
			end
		end
	end
end

function MasteryManager:CreateMastery(def)
	-- for instances where a mastery creates another mastery
	local mastery = itemforge.CreateMastery(def)
	return mastery
end

function MasteryManager:AddMastery(mastery, silent)
	local mastery_def = mastery:GetDef()

	if mastery_def.prerequisite_fn ~= nil and not mastery_def.prerequisite_fn(self.inst) then
		return
	end

	assert(mastery_def.name, "AddMastery takes a mastery def from Mastery.Items")
	local slot = self.data.masteries[mastery_def.slot]
	local equipped_mastery = slot[mastery_def.name]

	if equipped_mastery ~= nil then
		-- Something has gone wrong! The player is not supposed to be able to get two of the same mastery.
		assert(nil, "Attempted to add a mastery more than once!: "..mastery_def.name.." on "..self.inst.prefab)
	end

	mastery.acquire_order = self.data.acquire_index
	self.data.acquire_index = self.data.acquire_index + 1

	local mst = self:_InitMastery(mastery)
	assert(mst)
	self:_RegisterMastery(mst)

	slot[mastery_def.name] = mst.persistdata

	if #mastery_def.tags > 0 then
		self:RefreshTags()
	end

	if silent ~= true then
		self:OnActivateMastery(mst)
	end

	--don't notify others if silent is on
	self.inst:PushEvent("add_mastery", mst)
end

function MasteryManager:RemoveMastery(mastery_def)
	local slot = self.data.masteries[mastery_def.slot]
	local mst = self.masteries[mastery_def.name]

	if mst ~= nil then
		self:RemoveEventTriggers(mst)
		if mastery_def.on_remove_fn then
			mastery_def.on_remove_fn(mst, self.inst)
		end
		if self.update_masteries[mst] then
			self.update_masteries[mst] = nil
		end

		slot[mastery_def.name] = nil

		self.masteries[mastery_def.name] = nil

		if #mastery_def.tags > 0 then
			for i, tag in ipairs(mastery_def.tags) do
				self.inst:RemoveTag(tag)
			end
			self:RefreshTags()
		end

		self.inst:PushEvent("remove_mastery", mst)
	end
end

function MasteryManager:AddMasteryByName(name)
	local def = Mastery.FindMasteryByName(name)
	self:AddMasteryByDef(def)
end

function MasteryManager:AddMasteryByDef(def, silent)
	local mastery = self:CreateMastery(def)
	self:AddMastery(mastery, silent)
end

function MasteryManager:SetUpEventTriggers(mastery)
	if next(mastery.def.event_triggers) then
		if self.event_triggers[mastery.def.name] ~= nil then
			assert(nil, "Tried to set up event triggers for a mastery that already has them!")
		end
		self.event_triggers[mastery.def.name] = {}
		local triggers = self.event_triggers[mastery.def.name]
		for event, fn in pairs(mastery.def.event_triggers) do
			local listener_fn = function(inst, ...) fn(mastery, inst, ...) end
			triggers[event] = listener_fn
			self.inst:ListenForEvent(event, listener_fn)
		end
	end

	if next(mastery.def.remote_event_triggers) then
		if self.remote_event_triggers[mastery.def.name] ~= nil then
			assert(nil, "Tried to set up remote event triggers for a mastery that already has them!")
		end

		self.remote_event_triggers[mastery.def.name] = {}
		local triggers = self.remote_event_triggers[mastery.def.name]
		for event, data in pairs(mastery.def.remote_event_triggers) do
			local source = data.source()
			local listener_fn = function(source, ...) data.fn(mastery, self.inst, source, ...) end
			triggers[event] = { fn = listener_fn, source = source }
			self.inst:ListenForEvent(event, listener_fn, source)
			-- printf("Set Up Event Trigger: %s on %s", event, source)
		end
	end
end

function MasteryManager:RemoveEventTriggers(mastery)
	if next(mastery.def.event_triggers) then
		local triggers = self.event_triggers[mastery.def.name]
		if triggers then
			for event, fn in pairs(triggers) do
				self.inst:RemoveEventCallback(event, fn)
			end
		end
		self.event_triggers[mastery.def.name] = nil
	end

	if next(mastery.def.remote_event_triggers) then
		local triggers = self.remote_event_triggers[mastery.def.name]
		if triggers then
			for event, data in pairs(triggers) do
				self.inst:RemoveEventCallback(event, data.fn, data.source)
			end
		end
		self.remote_event_triggers[mastery.def.name] = nil
	end
end

function MasteryManager:AddUpdateMastery(mastery)
	self.update_masteries[mastery] = mastery.def
	self.inst:StartUpdatingComponent(self)
end

function MasteryManager:OnUpdate(dt)
	if not next(self.update_masteries) then
		self.inst:StopUpdatingComponent(self)
		return
	end

	if self.inst:IsLocal() then
		for mastery, mastery_def in pairs(self.update_masteries) do
			mastery_def.on_update_fn(mastery, self.inst, dt)
		end
	end
end

function MasteryManager:EvaluatePaths()
	if self.inst:IsFlagUnlocked("pf_unlocked_masteries") then
		MasteryPath.EvaluatePaths(self.inst)
	end
end

function MasteryManager:RefreshTags()
	for _, slot in pairs(self.data.masteries) do
		for _, mastery in pairs(slot) do
			local mastery_def = mastery:GetDef()
			if #mastery_def.tags > 0 then
				for i, tag in ipairs(mastery_def.tags) do
					self.inst:AddTag(tag)
				end
			end
		end
	end
end

function MasteryManager:_NotifyMastery(mastery_instance, time, is_past_threshold)

	time = time or 2
	TheDungeon.HUD:MakePopMasteryProgress({
		target = self.inst,
		mastery = mastery_instance,
		fade_time = time,
		y_offset = -170,
		is_past_threshold = is_past_threshold
	}, mastery_instance)
end

---------------------------------------------------------------------

function MasteryManager:GetMasteryByName(mastery_name)
	if self.masteries[mastery_name] ~= nil then
		return self.masteries[mastery_name]
	else
		return nil
	end
end

function MasteryManager:HasMastery(def)
	return self.data.masteries[def.slot][def.name] ~= nil
end

function MasteryManager:GetMasteryInstance(def)
	return self.data.masteries[def.slot][def.name]
end

function MasteryManager:GetMastery(def)
	return self.masteries[def.name]
end

function MasteryManager:OnActivateMastery(mst)
	-- if mst:GetDef().default_unlocked then return end

	-- don't notify about new masteries until we hammer out pres/ when it is activated.
	if not mst:IsNew() then 
		self:_NotifyMastery(mst, 5)
	end
end

function MasteryManager:OnProgressUpdated(mst)
	local progress = mst:GetProgressPercent()

	local is_past_threshold = false
	for _,threshold_data in ipairs(mst.persistdata.update_thresholds) do
		if progress >= threshold_data.threshold and not threshold_data.updated then
			--mark this threshold as passed
			threshold_data.updated = true
			is_past_threshold = true
		end
	end

	--if past threshold, use large notification
	self:_NotifyMastery(mst, 2, is_past_threshold)
end

function MasteryManager:OnCompleteMastery(mst)
	self:RemoveEventTriggers(mst)
	self:_NotifyMastery(mst, 3.5)
	TheWorld:PushEvent("refresh_markers", {player = self.inst})
end

function MasteryManager:CreateNextMastery(mst)
	local new_masteries = mst:GetDef().next_step

	if new_masteries then
		for i,mastery in ipairs(new_masteries) do
			if mastery then
				if self:GetMasteryByName(mastery) ~= nil then
					print(string.format("WARNING: Already have mastery %s unlocked, moving on...", mastery))
				else
					self:AddMasteryByName(mastery)
				end
			end
		end
	end
end

function MasteryManager:Debug_GetMasteryListing()
	return table.inspect(self.data.masteries, { depth = 3, process = table.inspect.processes.skip_mt, })
end

local function _build_debug_progress_bar(progress)
	progress = progress * 10
	local str = ""
	for i = 1, 10, 0.5 do
		if i <= progress then
			str = str.."|"
		else
			str = str.."-"
		end
	end
	return str
end

function MasteryManager:DebugDrawEntity(ui, panel, colors)
	if ui:Button("Give All Masteries") then
		for slot, masteries in pairs(Mastery.Items) do
			for name, def in pairs(masteries) do
				self:AddMasteryByDef(def)
			end
		end
	end

	ui:SameLineWithSpace()

    ui:PushStyleColor(ui.Col.Button, {245/255, 46/255, 39/255, 1})
    ui:PushStyleColor(ui.Col.ButtonHovered, {168/255, 32/255, 27/255, 1})
    ui:PushStyleColor(ui.Col.ButtonActive, {209/255, 39/255, 33/255, 1})
	if ui:Button("Reset Data") then
		self:DEBUG_ResetMasteries()
	end
    ui:PopStyleColor(3)

	ui:Separator()

	local debug_output = {}

	for slot, mastery_list in pairs(Mastery.Items) do
		local slot_tbl = {}
		for mastery_name, mastery_def in pairs(mastery_list) do
			local mastery_inst = self:GetMastery(mastery_def)
			local type_tbl = slot_tbl[mastery_def.mastery_type] or { inactive = {}, complete = {}, inprogress = {}}

			if not mastery_inst then
				type_tbl.inactive[mastery_name] = mastery_def
			elseif mastery_inst:IsComplete() then
				type_tbl.complete[mastery_name] = mastery_inst
			else
				type_tbl.inprogress[mastery_name] = mastery_inst
			end

			slot_tbl[mastery_def.mastery_type] = type_tbl
		end
		debug_output[slot] = slot_tbl
	end

	for slot, types in iterator.sorted_pairs(debug_output) do
		local total_num = 0

		for type, masteries in pairs(types) do
			total_num = total_num + lume.count(masteries.inprogress)
			total_num = total_num + lume.count(masteries.complete)
		end

		local slot_label = ("%s (%d)###%s"):format(slot, total_num, slot)

		if ui:CollapsingHeader(slot_label) then
			ui:Indent()
			for type, masteries in iterator.sorted_pairs(types) do
				local type_label = ("%s###%s"):format(type, type)
				if ui:CollapsingHeader(type_label) then
					ui:Indent()

					-- IN PROGRESS MASTERIES

					local count = table.count(masteries.inprogress)
					ui:Text(("In Progress (%d)"):format(count))
					for mastery_name, mastery in iterator.sorted_pairs(masteries.inprogress) do
						panel:AppendTable(ui, mastery, mastery_name)
						ui:SameLineWithSpace()
						if ui:Button(("[%s]##%s"):format(_build_debug_progress_bar(mastery:GetProgressPercent()), mastery_name)) then
							ui:OpenPopup(mastery_name)
						end
						if ui:BeginPopup(mastery_name) then
							ui:Text(mastery:GetDef().pretty.name)
							ui:Text(mastery:GetDef().pretty.desc)
							ui:Separator()
							ui:ProgressBar(mastery:GetProgressPercent(), ("%d/%d"):format(mastery:GetProgress(), mastery:GetMaxProgress()), 300)
							ui:SameLineWithSpace()
							if ui:Button(ui.icon.playback_play) then
								mastery:DeltaProgress(1)
							end
							ui:SameLineWithSpace()
							if ui:Button(ui.icon.playback_ffwd) then
								mastery:DeltaProgress( math.ceil(mastery:GetMaxProgress()/4) )
							end
							ui:SameLineWithSpace()
							if ui:Button(ui.icon.done) then
								mastery:DeltaProgress( mastery:GetMaxProgress() )
							end
							ui:EndPopup()
						end
					end
					ui:Separator()

					-- COMPLETED MASTERIES

					count = table.count(masteries.complete)
					ui:Text(("Complete (%d)"):format(count))
					for mastery_name, mastery in iterator.sorted_pairs(masteries.complete) do
						panel:AppendTable(ui, mastery, mastery_name)
					end

					ui:Separator()

					-- INACTIVE MASTERIES

					count = table.count(masteries.inactive)
					ui:Text(("Inactive (%d)"):format(count))
					for mastery_name, mastery_def in iterator.sorted_pairs(masteries.inactive) do
						panel:AppendTable(ui, mastery_def, mastery_name)
						ui:SameLineWithSpace()
						if ui:Button(ui.icon.add.."##"..mastery_name) then
							self:AddMasteryByDef(mastery_def)
						end
					end

					ui:Unindent()
				end
			end
			ui:Unindent()
		end
	end
end

function MasteryManager:DEBUG_ResetMasteries()
	-- Loop over savedata to ensure we reset loaded state.
	for _, slot in pairs(self.data.masteries) do
		for _, mastery in pairs(slot) do
			local mastery_def = mastery:GetDef()
			self:RemoveMastery(mastery_def, true)
		end
	end

	assert(not next(self.event_triggers), "Mastery data is reset but self.event_triggers is not empty.")
	assert(not next(self.remote_event_triggers), "Mastery data is reset but self.remote_event_triggers is not empty.")
	assert(not next(self.update_masteries), "Mastery data is reset but self.update_masteries is not empty.")

	self.data = create_default_data()
end

function MasteryManager:DEBUG_CanAddMastery(mastery)
	local mastery_def = mastery:GetDef()
	assert(mastery_def.name, "AddMastery takes a mastery def from Mastery.Items")
	local slot = self.data.masteries[mastery_def.slot]

	if not slot then
		self.data.masteries[mastery_def.slot] = {}
		slot = self.data.masteries[mastery_def.slot]
	end

	local equipped_mastery = slot[mastery_def.name]
	return not equipped_mastery or mastery_def.stackable
end

return MasteryManager
