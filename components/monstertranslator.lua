local lume = require "util.lume"
local FollowLabel = require "widgets.ftf.followlabel"

-- These strings are defined here to translate into monster language from English.
-- Once we can access English strings from any language and want to see translated monster language in-game,
-- we should place these strings in STRINGS and reference them there.
local monster_strings =
{
	thatcher =
	{
		THATCHER_INTRO_1 = "[TEMP] Who are you? Who are WE?",
		THATCHER_INTRO_2 = "[TEMP] WE will protect her!",
		THATCHER_INTRO_3 = "[TEMP] Our HIVE! Our QUEEN!\nAway! Away!",
		THATCHER_INTRO_3 = "[TEMP] Shred! Shred! Shred!\nWE shred you!",

		THATCHER_DEATH_1 = "[TEMP] Q... QUEEN...",
		THATCHER_DEATH_2 = "[TEMP] Hurts.\n...Why...?",
		THATCHER_DEATH_3 = "[TEMP] Where is our body?",
		THATCHER_DEATH_4 = "[TEMP] Where are my bodies?",
		THATCHER_DEATH_4 = "[TEMP] QUEEN... help WE...",
		THATCHER_DEATH_5 = "[TEMP] I... WE... Swarm...",

		THATCHER_SPECIAL_1_1 = "[TEMP] Attack! Protect! We are getting you!",
		THATCHER_SPECIAL_1_2 = "[TEMP] SPINNING MANTIS BLADE!",

		THATCHER_SPECIAL_2_1 = "[TEMP] You cannot get away!",
		THATCHER_SPECIAL_2_2 = "[TEMP] RISING GRASSHOPPER!",
		THATCHER_SPECIAL_2_1 = "[TEMP] WE smell you!",

		THATCHER_SPECIAL_3_1 = "[TEMP] Fear WE!",
		THATCHER_SPECIAL_3_2 = "[TEMP] SUPER STING!",
		THATCHER_SPECIAL_3_3 = "[TEMP] BIG ATTACK! YOU GET HURT NOW!",
		THATCHER_SPECIAL_3_4 = "[TEMP] Leave HIVE alone!",

		THATCHER_PHASE_TRANSITION_1 = "[TEMP] You are bad.\nNasty to the BONE.",
		THATCHER_PHASE_TRANSITION_2 = "[TEMP] Your body will hit the FLOOR!",
		THATCHER_PHASE_TRANSITION_2 = "[TEMP] WE... were formed... to be WILD.",

		THATCHER_TAUNT_1 = "[TEMP] You are small! WE are many!",
		THATCHER_TAUNT_2 = "[TEMP] WE give you... ENCORE!",
		THATCHER_TAUNT_3 = "[TEMP] You want show?? WE give!",
		THATCHER_TAUNT_4 = "[TEMP] You! You will not hurt our QUEEN!",
		THATCHER_TAUNT_5 = "[TEMP] Away from loved QUEEN!\nAway!",
	}
}

local MonsterTranslator = Class(function(self, inst)
	self.inst = inst
	self.overlay_label = nil
	self.overlay_label_remove_task = nil
    self.current_id = nil
end)

function MonsterTranslator:OnNetSerialize()
	local e = self.inst.entity
	local has_display_string = self.current_id ~= nil
	e:SerializeBoolean(has_display_string)
	if has_display_string then
		e:SerializeString(self.current_id)
	end
end

function MonsterTranslator:OnNetDeserialize()
	local e = self.inst.entity
	local has_display_string = e:DeserializeBoolean()
	if has_display_string then
    	local updated_string_id = e:DeserializeString()
		-- Show/update/hide the serialized string if it changed compared to the local version.
		if self.current_id ~= updated_string_id then
			self:DisplayMonsterString(self.inst.prefab, updated_string_id)
			self.current_id = updated_string_id
		end
	elseif self.current_id and self.overlay_label then
		self.overlay_label:Remove()
		self.overlay_label = nil
		self.current_id = nil
	end
end

function MonsterTranslator:GetMonsterStringsList()
	return monster_strings
end

local alphabet = { 'a', 'b', 'c', 'd', 'e', 'f', 'g', 'h', 'i', 'j', 'k', 'l', 'm', 'n', 'o', 'p', 'q', 'r', 's', 't', 'u', 'v', 'w', 'x', 'y', 'z' }
local monster_translators =
{
	-- TODO: iterate on the translation function to make things sound more... bug-like?
	thatcher = function(str)
		local vowel_replacements =
		{
			a = "-CHRP- ",
			e = "'Brr", -- Thatcher's favourite word ;)
			i = "'Uzz",
			o = "'Scree",
			u = "'itchitch",
			y = "'chit",
		}

		-- Generate consonant shift table
		local CONSONANT_SHIFT <const> = 5
		local consonant_shifts = {}
		for i, chr in ipairs(alphabet) do
			if not vowel_replacements[chr] then
				consonant_shifts[chr] = CONSONANT_SHIFT
			end
		end

		-- Iterate through each letter in the string, replacing vowels & shifting consonants
		local translated_string = ""

		-- Strip out the [TEMP] on temp text strings
		local _, start = string.find(str, "TEMP", 1, true)
		start = start + 1 or 1

		for i = start, #str do
			local chr = string.sub(str, i, i)
			local lookup_char = string.lower(chr)

			if vowel_replacements[lookup_char] then
				translated_string = translated_string .. vowel_replacements[lookup_char]
			elseif consonant_shifts[lookup_char] then
				local isUpperCase = chr == string.upper(chr)

				local letter_idx = lume.find(alphabet, lookup_char)
				local new_letter = alphabet[(letter_idx + consonant_shifts[lookup_char]) % 26]
				if isUpperCase then
					new_letter = string.upper(new_letter)
				end
				translated_string = translated_string .. new_letter
			elseif str.match(chr, "[ !.?\n]") then
				translated_string = translated_string .. chr
			else
				-- Ignore the character
			end
		end

		return translated_string
	end,
}

-- Returns a string in monster language.
function MonsterTranslator:GetTranslatedMonsterString(id, string_id)
	local monster_string = self:GetMonsterString(id, string_id)

	if not monster_translators[id] then
		TheLog.ch.MonsterTranslator:printf("Monster id %s does not have a translation function!", id)
		return ""
	end

	monster_string = monster_translators[id](monster_string)

	return monster_string
end

-- Returns a string in the localized language.
function MonsterTranslator:GetMonsterString(id, string_id)
	-- TODO: Implement properly once monster strings are stored in STRINGS. For now return the English string defined in monster_strings.
	if not monster_strings[id] then
		TheLog.ch.MonsterTranslator:printf("Monster id %s does not have any strings!", id)
		return ""
	elseif not monster_strings[id][string_id] then
		TheLog.ch.MonsterTranslator:printf("Monster string id %s does not exist!", string_id)
		return ""
	end

	return monster_strings[id][string_id]
end

function MonsterTranslator:ClearMonsterString()
	if self.overlay_label then
		if self.overlay_label_remove_task then
			self.overlay_label_remove_task:Cancel()
		end

		self.overlay_label:Remove()
		self.overlay_label = nil
	end
end

function MonsterTranslator:DisplayMonsterString(id, string_id, duration, offset_y)
	-- TODO: Check to see if we should display the non-translated or translated monster string.
	local text_string = self:GetTranslatedMonsterString(id, string_id)

	-- Only allow one overlay label to be shown at a time; update the previous one if it exists.
	self:ClearMonsterString()

	self.overlay_label = TheDungeon.HUD:OverlayElement(FollowLabel())
				:SetText(text_string)
				:SetTarget(self.inst)
				:Offset(0, offset_y or 600)
				:SetClickable(false)
	self.overlay_label:GetLabelWidget()
				:SetShadowColor(UICOLORS.BLACK)
				:SetShadowOffset(1, -1)
				:SetOutlineColor(UICOLORS.BLACK)
				:EnableShadow()
				:EnableOutline()
	if self.inst:IsLocal() then
		self.overlay_label_remove_task = self.inst:DoTaskInAnimFrames(duration or 45, function()
			self.overlay_label:Remove()
			self.overlay_label = nil
			self.current_id = nil
		end)
	end

	self.current_id = string_id
end

return MonsterTranslator