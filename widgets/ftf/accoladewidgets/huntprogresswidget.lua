local Widget = require "widgets/widget"
local Image = require "widgets/image"
local Text = require "widgets/text"

local easing = require "util/easing"
local Enum = require "util/enum"
local lume = require "util.lume"

local soundutil = require "util.soundutil"
local fmodtable = require "defs.sound.fmodtable"

local Moods = Enum{
	"motivational",
	"nervous",
	"skeptical",
	"confused",
	"sad",
	"frustrated"
}

local MOOD_TO_TEX =
{
	[Moods.s.motivational] = "images/ui_ftf_dungeon_progress/Flitt1.tex",
	[Moods.s.nervous] = "images/ui_ftf_dungeon_progress/Flitt2.tex",
	[Moods.s.skeptical] = "images/ui_ftf_dungeon_progress/Flitt3.tex",
	[Moods.s.confused] = "images/ui_ftf_dungeon_progress/Flitt4.tex",
	[Moods.s.sad] = "images/ui_ftf_dungeon_progress/Flitt5.tex",
	[Moods.s.frustrated] = "images/ui_ftf_dungeon_progress/Flitt6.tex",
}

local function _get_boss_icon()
	local biome = TheDungeon:GetDungeonMap().nav:GetBiomeLocation()
	return biome.icon
end

local function _get_miniboss_progress()
	return TheDungeon:GetDungeonMap().nav:GetProgressForFirstMinibossEncounter()
end

local function _get_miniboss_room()
	return TheDungeon:GetDungeonMap().nav:GetRoomForFirstMinibossEncounter()
end

local function _get_num_rooms()
	local seen, max = TheDungeon:GetDungeonMap().nav:GetRoomCount_SeenAndMaximum()
	-- _get_num_rooms() returns 1 too high because it is artificially
	-- increased by 1 to account for the boss room which is actually after the mapgen
	return max - 1
end

local function _build_progress_marker_table()
	local num_rooms = _get_num_rooms()
	local hype_room = num_rooms
	local miniboss_room = _get_miniboss_room()
	local progress_markers = {}

	local important_rooms =
	{
		[0] = { icon = nil, scale = 1, important = true },
		[miniboss_room] = { icon_fn = function() return "images/ui_ftf_pausescreen/ic_miniboss.tex" end, scale = 0.75, important = true },
		[hype_room] = { icon_fn = _get_boss_icon, scale = 1, important = true },
	}

	for i = 0, hype_room do
		local progress = i/num_rooms
		if important_rooms[i] then
			local tbl = shallowcopy(important_rooms[i])
			tbl.progress = progress
			table.insert(progress_markers, tbl)
		else
			table.insert(progress_markers, { progress = progress })
		end
	end


	return progress_markers
end

local FlittTipWidget = Class(Widget, function(self)
	Widget._ctor(self, "FlittTipWidget")
	
	local tip = self:GetTip()

	if not tip then
		-- fallback if no tip is selected
		tip = {
			text = STRINGS.UI.HUNTPROGRESSWIDGET.FALLBACK_FLITT_QUIP,
			mood = "skeptical",
		}
	end

	self.flitt_img = self:AddChild(Image(MOOD_TO_TEX[tip.mood]))

	self.flitt_tips = self:AddChild(Image("images/ui_ftf_dungeon_progress/Tips.tex"))
		:LayoutBounds("center", "above", self.flitt_img)
		:SendToBack()
		:Offset(-250, -110)

	local w, h = self.flitt_tips:GetSize()

	self.tip_text = self.flitt_tips:AddChild(Text(FONTFACE.DEFAULT, 70, tip.text, HexToRGB(0x5E4E4AFF)))
		:LeftAlign()
		:SetRegionSize(620, 300)
		:EnableWordWrap(true)
		:LayoutBounds("left", "center", self.flitt_tips)
		:Offset(100, 50)
		:Spool(25)
		-- commented out because this causes speech sounds that would need polish but we don't have time right now.
		-- :SetPersonalityText(tip.text)

end)

function FlittTipWidget:GetTip()
	local run_state = TheDungeon.progression.components.runmanager:GetRunState()
	local progress = TheDungeon:GetDungeonProgress()

	local tags = {
		"huntprogressscreen", -- primary tag that ensures these quips won't accidentally appear in convos
	}

	if run_state == RunStates.s.ABANDON then
		table.insert(tags, "abandoned")
	elseif run_state == RunStates.s.DEFEAT or run_state == RunStates.s.ACTIVE then
		-- Support "ACTIVE" run state here so debug opening the screen still returns a string.
		local miniboss_progress = _get_miniboss_progress()
		local boss_progress = 1.0

		if progress < miniboss_progress then
			-- lost before reaching the miniboss
			table.insert(tags, "lost_early")
		elseif progress == miniboss_progress then
			-- lost while fighting the miniboss
			table.insert(tags, "lost_during_miniboss")
			table.insert(tags, TheDungeon:GetCurrentMiniboss())

		elseif progress > miniboss_progress and progress < boss_progress then
			-- lost after beating the miniboss, but before reaching the boss
			table.insert(tags, "lost_beat_miniboss")
			table.insert(tags, TheDungeon:GetCurrentMiniboss())

		elseif progress >= boss_progress then
			-- lost while fighting the boss
			table.insert(tags, "lost_boss")
			table.insert(tags, TheDungeon:GetCurrentBoss())

			-- TODO: convert health into buckets to use in tags: boss_low_health, boss_mid_health...
			if false then
			    local ents = TheSim:FindEntitiesXZ(0, 0, 1000, { "boss" })
				local boss_ent = ents and ents[1] or nil
				if boss_ent ~= nil then
					-- find boss, get current health
					local boss_health = boss_ent.components.health:GetPercent()
					local tip_options = {}

					for _, tip in ipairs(tips) do
						local health = tip.health or 1
						-- print("PRINT!")
						-- print(tip_options)
						-- print(tip)
						if tonumber(boss_health) <= health then
							table.insert(tip_options, tip)
						end
					end

					if #tip_options > 0 then
						-- Get the tip that is closest to the boss' health
						local smallest_delta = 1
						local best_tips = {}
						for _, tip in ipairs(tip_options) do
							local health = tip.health or 1
							local delta = health - boss_health
							if delta < smallest_delta then
								smallest_delta = delta
								-- wipe current list of best tips & start a new one
								best_tips = {}
								table.insert(best_tips, tip)
							elseif delta == smallest_delta then
								-- just add yourself to the list of best tips
								table.insert(best_tips, tip)
							end
						end

						if #best_tips > 0 then
							return best_tips[math.random(#best_tips)]
						end
					end
				end
			end
		end
	elseif run_state == RunStates.s.VICTORY then
		-- We currently do not show this screen if you win the run.
		table.insert(tags, "won")
	end

	-- get a random local player
	local local_players = TheNet:GetLocalPlayerList()
	local_players = lume.filter(local_players, function(id) 
		local player = GetPlayerEntityFromPlayerID(id)
		-- just needs to have a quest central... tags are not player-contextual
		return player and player.components.questcentral ~= nil
	end)

	if #local_players > 0 then
		local random_local_player = GetPlayerEntityFromPlayerID(local_players[math.random(#local_players)])

		local questcentral = random_local_player.components.questcentral

		local tip, match = questcentral:Quip(tags, "npc_scout")

		if not tip then
			table.insert(tags, "general")
			tip, match = questcentral:Quip(tags, "npc_scout")
		end

		return {
			text = tip,
			mood = match and match.emote,
		}
	end
end

local HuntProgressMarker = Class(Widget, function(self, marker)
	Widget._ctor(self, "HuntProgressMarker")
	self:AddChild(Image("images/ui_ftf_dungeon_progress/ProgressPoint.tex"))

	if marker.icon_fn ~= nil then
		self:AddChild(Image(marker.icon_fn()))
			:SetScale(marker.scale, marker.scale)
			:LayoutBounds("center", "below")
			:Offset(0, -5)
			:SetMultColor(HexToRGB(0x5E4E4AFF))
			:SetHiddenBoundingBox(true)
	end

end)

local HuntProgressBar = Class(Widget, function(self)
	Widget._ctor(self, "HuntProgressBar")
	TheFrontEnd:GetSound():PlaySound(fmodtable.Event.ui_dungeonProgressWidget_start)

	self.bar_root = self:AddChild(Widget("Bar Root"))

	self.bar_root:AddChild(Image("images/ui_ftf_dungeon_progress/ProgressBar_Cap_L.tex")) -- left cap
	local middle_bar = self.bar_root:AddChild(Image("images/ui_ftf_dungeon_progress/ProgressBar.tex")):LayoutBounds("after", "center") -- the middle
	self.bar_root:AddChild(Image("images/ui_ftf_dungeon_progress/ProgressBar_Cap_R.tex")):LayoutBounds("after", "center") -- right cap
	-- self.bar_root:LayoutChildrenInGrid(3, 0) -- arrange them as they should be

	self.bar_w = middle_bar:GetSize()

	self.progress_markers = _build_progress_marker_table()

	for _, marker in ipairs(self.progress_markers) do

		local progress_marker = nil
		local y_offset = 0

		if marker.important then
			progress_marker = middle_bar:AddChild(HuntProgressMarker(marker))
				:SetAnchors("left", "center")

			y_offset = -15
		else
			progress_marker = middle_bar:AddChild(Image("images/ui_ftf_dungeon_progress/ProgressPointSmall.tex"))
				:SetAnchors("left", "center")

			y_offset = -5
		end

		local x_offset = self.bar_w * marker.progress

		progress_marker:Offset(x_offset, y_offset)
	end

	self.player_marker = middle_bar:AddChild(Image("images/ui_ftf_dungeon_progress/ProgressPlayerIcon.tex"))
		:SetAnchors("center", "bottom")
	local w, h = self.player_marker:GetSize()

	self.player_marker:LayoutBounds("left", "above", middle_bar):Offset(-w/2, 0)

	-- speed up this sequence if you didn't make any progress
	local dungeon_progress = TheDungeon:GetDungeonProgress()
	local wait_time = dungeon_progress > 0 and 1 or 0
	self.inst:DoTaskInTime(wait_time, function() self:MoveMarkerToProgress(TheDungeon:GetDungeonProgress()) end)

	self.complete = false	
end)

function HuntProgressBar:MoveMarkerToProgress(progress)
	local x, y = self.player_marker:GetPosition()
	local x_delta = self.bar_w * progress
	local x_tar = x + x_delta
	local dungeon_progress = progress

	-- tween time for both the marker and the sound parameter adjustment
	-- also serves as cue for stopping the lp
	local ease_time = dungeon_progress > 0 and 1.33 or 0

	self:RunUpdater(Updater.Series{
		Updater.Ease(function(v) self.player_marker:SetPosition(v, y) end, x, x_tar, ease_time, easing.outExpo),
		Updater.Do( function()
			self.complete = true
			if self.progress_sound then
				TheFrontEnd:GetSound():KillSound(self.progress_sound)
				self.progress_sound = nil
			end
		end )
	})

	-- play sound if the widget's actually moving
	if dungeon_progress > 0 then
		self.progress_sound = TheFrontEnd:GetSound():PlaySound_Autoname(fmodtable.Event.ui_dungeonProgressWidget_LP,nil,true)

		if self.progress_sound then
			TheFrontEnd:GetSound():SetParameter(self.progress_sound, "ui_easePercentage", ease_time)

			-- Create a parallel updater
			self:RunUpdater(Updater.Parallel({
				-- update param over the ease time from 0 to % dungeon progress
				-- we stop the sound and easing earlier than 100% because movement gets infinitessimally small towards the end
				Updater.Ease(function(meter_value)
					if self.progress_sound then
						if meter_value / dungeon_progress < .99 then
							TheFrontEnd:GetSound():SetParameter(self.progress_sound, "progress", meter_value)
						else
							TheFrontEnd:GetSound():KillSound(self.progress_sound)
							self.progress_sound = nil
						end
					end
				end, 0, TheDungeon:GetDungeonProgress(), ease_time, easing.inSine),

				-- -- update param with how far into the ease we are
				-- -- need this to smooth volume presentation
				Updater.Ease(function(v)
					if self.progress_sound then
						TheFrontEnd:GetSound():SetParameter(self.progress_sound, "ui_easePercentage", v)
					end
				end, 0, ease_time, ease_time, easing.outQuad),
			}))
		end
	end

end

function HuntProgressBar:PopulateBar(data)

end

local HuntProgressWidget = Class(Widget, function(self, data)
	Widget._ctor(self, "HuntProgressWidget")

	self.panel_contents = self:AddChild(Widget())
		:SetName("Panel contents")
		:SendToBack()
		:SetShowDebugBoundingBox(true)

	self.bg = self.panel_contents:AddChild(Image("images/ui_ftf_dungeon_progress/PanelProgress.tex"))
		:SetName("Background")

	self:PopulatePanelContents()
end)

function HuntProgressWidget:IsAnimationComplete()
	return self.progress_bar.complete
end

function HuntProgressWidget:PopulatePanelContents()

	local biome = TheDungeon:GetDungeonMap().nav:GetBiomeLocation()

	self.title_bg = self.panel_contents:AddChild(Image("images/ui_ftf_gems/gem_panel_title_bg.tex"))
		:SetName("mastery title bg")
	self.title = self.title_bg:AddChild(Text(FONTFACE.DEFAULT, 100, biome.pretty.name_upper, HexToRGB(0x5E4E4AFF)))

	local w, h = self.title:GetSize()
	self.title_bg:SetSize(w + 350, 120)
		:LayoutBounds("center", "top", self.bg)
		:Offset(0, -20)

	self.title:LayoutBounds("center", "center", self.title_bg)

	local title_ornament = biome:GetRegion().title_ornament
	local deco_offset = 20

	self.deco_left = self.panel_contents:AddChild(Image(title_ornament))
		:SetMultColor(HexToRGB(0x5E4E4AFF))
		:LayoutBounds("before", "center", self.title)
		:Offset(-deco_offset, 0)

	self.deco_right = self.panel_contents:AddChild(Image(title_ornament))
		:SetMultColor(HexToRGB(0x5E4E4AFF))
		:LayoutBounds("after", "center", self.title)
		:Offset(deco_offset, 0)
		:SetScale(-1, 1)

	self.progress_bar = self.panel_contents:AddChild(HuntProgressBar())
	local w, h = self.progress_bar:GetSize()
	local progress_scale = 1.2
	self.progress_bar
		:SetScale(progress_scale, progress_scale)
		:LayoutBounds("center", "center", self.bg)
		--:Offset(0, 120)

	self.panel_contents:LayoutBounds("center", "bottom", self)

	self.flitt_tip = self:AddChild(FlittTipWidget())
		:SetHiddenBoundingBox(true)
		:LayoutBounds("before", "bottom", self.panel_contents)
		:Offset(385, 65)
end

return HuntProgressWidget
