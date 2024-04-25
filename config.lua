require "class"

local Config = Class(function(self, options)
	self.options = {}
	if options then
		self:SetOptions(options)
	end
end)

function Config:SetOptions(options)
	for k,v in pairs(options) do
		self.options[k] = v
	end
end

function Config:IsEnabled(option)
	return self.options[option]
end

function Config:Enable(option)
	self.options[option] = true
end

function Config:Disable(option)
	self.options[option] = nil
end

function Config:__tostring()
	local str = {}
	table.insert(str, "PLATFORM CONFIGURATION OPTIONS")
	for k,v in pairs (self.options) do
		table.insert(str, string.format("%s = %s", tostring(k), tostring(v) ))
	end

	return table.concat(str, "\n")
end


-------------------------------------------------

local defaults =
{
	hide_vignette = false,
	force_netbookmode = false,
}

local platform_overrides =
{
	
	ANDROID =
	{
--		hide_vignette = true,		-- RM - Disabled because we should do a fresh analysis on performance
--		force_netbookmode = true,	-- RM - Disabled because it causes Android to crash due to NULL-pointer to save-file.
	},
	IOS =
	{
--		hide_vignette = true,		-- RM - Disabled because we should do a fresh analysis on performance
--		force_netbookmode = true,	-- RM - Disabled because it (likely) causes iOS to crash like it did for Android.
	},
}

function Config.CreateDefaultConfig()
	local cfg = Config(defaults)
	if platform_overrides[PLATFORM] then
		cfg:SetOptions(platform_overrides[PLATFORM])
	end
	return cfg
end


return Config
