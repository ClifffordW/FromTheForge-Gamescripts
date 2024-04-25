local LANGUAGE = require "languages.langs"
local Localization = require "questral.localization"
require "constants"


local LOC_ROOT_DIR = "localizations/" -- in root data dir: Rotwood/data/localizations/
local EULA_FILENAME = "eula_english.txt"
if Platform.IsXB1() then
	-- TODO(l10n): Why did DST use a different LOC_ROOT_DIR on consoles?
	-- LOC_ROOT_DIR = "data/scripts/languages/"
	EULA_FILENAME = "eula_english_x.txt"
else
	EULA_FILENAME = "eula_english_p.txt"
end



local LOC = {}


function LOC.GetActiveLocalization()
	return TheGameContent:GetContentDB().current_localization
end

local function GetAllLocalizations()
	return TheGameContent:GetContentDB():GetAll(Localization)
end

local function FindFirstLocalizationMatch(pred)
	for _,loc in pairs(GetAllLocalizations()) do
		if pred(loc) then
			return loc
		end
	end
end

-- Find locale object by iso language code (eg, "zh-CN").
function LOC._FindLocaleByCode(lang_code)
	local found_loc = FindFirstLocalizationMatch(function(loc)
		return loc:SupportsLocale(lang_code)
	end)
	found_loc = found_loc or FindFirstLocalizationMatch(function(loc)
		return loc:IsFallbackForLocale(lang_code)
	end)
	return found_loc
end

function LOC.GetLanguages()
	local localizations = GetAllLocalizations()
	local lang_options = {}
	local native
	for _, loc in pairs(localizations) do
		if loc.is_game_authored_language then
			native = loc
		else
			table.insert(lang_options, loc.id)
		end
	end
	assert(native, "Must setup a Localization that is the game's native language.")
	table.insert(lang_options, 1, native.id) -- make native language first.
	return lang_options
end

function LOC.GetCurrentLanguageId()
	local loc = LOC.GetActiveLocalization()
	return loc and loc.id or "<none>"
end

function LOC.GetEulaFilename()
    local eula_file = LOC_ROOT_DIR .. EULA_FILENAME
    return eula_file
end

function LOC.DetectLanguage()
	local last_detected_code = TheGameSettings:Get("language.last_detected")
	local platform_lang_code = TheSim:GetPreferredLanguage()
	if last_detected_code == platform_lang_code then
		-- Already detected this language. Do nothing since user may have
		-- selected a different one.
		return
	end
	local platform_locale = LOC._FindLocaleByCode(platform_lang_code)
	if platform_locale and (platform_locale ~= LOC.GetActiveLocalization() or last_detected_code == "NONE") then
		local locale_id = platform_locale and platform_locale.id or LANGUAGE.ENGLISH
		TheLog.ch.Loc:printf("Detected platform locale [%s] to use from platform language [%s].", locale_id, platform_lang_code)
		-- Only set last_detected on successful language change so if we add
		-- new languages, we'll still detect the new suggestion.
		TheGameSettings:Set("language.last_detected", platform_lang_code)
		TheGameSettings:Set("language.selected", locale_id) -- calls SwapLanguage.
	end
end

function LOC.SwapLanguage(lang_id)
    TheLog.ch.Loc:printf("SwapLanguage: Changing from locale [%s] to [%s].", LOC.GetCurrentLanguageId(), lang_id)
    TheGameContent:SetLanguage(lang_id)
end

--~ function LOC.GetLongestTranslatedString(strid)
--~     local str = nil
--~     for _, lang in pairs(self.languages) do
--~         if lang[strid] then
--~             local temp_str = self:ConvertEscapeCharactersToRaw(lang[strid])
--~             if nil == str then
--~                 str = temp_str
--~             elseif string.len(temp_str) > string.len(str) then
--~                 str = temp_str
--~             end
--~         end
--~     end
--~     return str
--~ end

-- Recursive function to process table structure
local function DoTranslateStringTable(db, base, tbl)
	for k,v in pairs(tbl) do
		local path = base.."."..k
		if type(v) == "table" then
			DoTranslateStringTable(db, path, v)
		elseif type(v) == "string" then
			local str = db:GetString(path)
			--~ if LanguageTranslator.use_longest_locs then
			--~     str = LanguageTranslator:GetLongestTranslatedString(path)
			--~ else
			--~     str = LanguageTranslator:GetTranslatedString(path)
			--~ end

			if str and str ~= "" then
				tbl[k] = str
			end
		end
	end
end

--called during load
function LOC.TranslateStringTable(tbl)
	local root = "STRINGS"
	DoTranslateStringTable(TheGameContent:GetContentDB(), root, tbl)
end



-- Call like LOC"STRINGS.UI.TOOLTIPS.LUCKY.NAME" to lookup strings by string
-- id.
-- Returns two values: the translated string and whether the string is missing
-- translation.
setmetatable(LOC, {
	__call = function(class_tbl, ...)
		return TheGameContent:GetContentDB():GetString(...)
	end
})

return LOC
