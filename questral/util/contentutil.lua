local contentutil = {}

function contentutil.GetContentDB()
	-- We could move content loading earlier so it's accessible in the FE menu,
	-- but why? Especially since we restart the lua sim so it's wasted time
	-- anyway.
	return TheGameContent:GetContentDB()
end

-- So long as BuildClassName functions tail call, they don't add to the stack depth.
local function BuildClassNameFromCallstack(depth)
    return debug.getinfo(depth, "S").source:match("^.*/(.*).lua$"):lower()
end

-- Use from a factory function to get the caller's filename.
function contentutil.BuildClassNameFromCallingFile()
    return BuildClassNameFromCallstack(3)
end

-- GLN uses these as global functions instead of a global STRINGS table. Since
-- we don't use ContentDB pervasively, I'm limiting these to static functions
-- that you can assign as a local for file-wide convenience.
function contentutil.ANIM(path)
	return contentutil.GetContentDB():GetAnimAsset(path)
end
function contentutil.IMG(path)
	return contentutil.GetContentDB():GetImageAsset(path)
end
function contentutil.LOC(str)
	return contentutil.GetContentDB():GetString(str)
end

-- Use to define at the top of a file.
-- local ANIM, IMG, LOC = contentutil.anim_img_loc()
function contentutil.anim_img_loc()
	return contentutil.ANIM, contentutil.IMG, contentutil.LOC
end

return contentutil
