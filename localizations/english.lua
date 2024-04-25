local Localization = require "questral.localization"
return Localization{
    id = "en",
    is_game_authored_language = true,
    name = "English",
    fonts =
    {
		-- TODO(L10n): We should use this to load fonts instead of
		-- fonts.lua since it allows custom fonts per language.
		blockhead = { font = "fonts/blockhead_sdf.zip", sdfthreshold = 0.4, sdfboldthreshold = 0.33 },
        title = { font = "fonts/blockhead_sdf.zip", sdfthreshold = 0.5, sdfboldthreshold = 0.33, scale = 0.6, line_height_scale = 0.85 },
        fixed = { font = "fonts/inconsolata_sdf.zip", sdfthreshold = 0.5, sdfboldthreshold = 0.33, scale = 0.6, line_height_scale = 0.85 },
        --~ alien = { font = "fonts/havarian_sdf.zip", sdfthreshold = 0.4, sdfboldthreshold = 0.33, image_scale = 0.7 },
        --~ speech = { font = "fonts/blockhead_sdf.zip", sdfthreshold = 0.54, sdfboldthreshold = 0.44, scale = 0.8, line_height_scale = 0.85, image_scale = 0.8 },
        --~ body = { font = "fonts/blockhead_sdf.zip", sdfthreshold = 0.47, sdfboldthreshold = 0.36, scale = 0.7, line_height_scale = 0.85, image_scale = 0.8 },
    },
    default_languages =
    {
        "en",
        "en-GB",
        "en-US",
        "en-CA",
    },
}
