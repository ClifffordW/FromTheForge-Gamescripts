--jcheng: archiving old scripts for now where it's easy to find so you don't have to look at svn history to find them
local INCLUDE_ARCHIVED = false
local LIST_FILES = require "util.listfilesenum"


-- Use as mixin, or just a raw table. Doesn't store any state.
local ScriptLoader = {}

function ScriptLoader:LoadScript(filename, post_fn)
    local param = filename:match( "^scripts/(.+)[.]lua$")
    assert( param or error( string.format( "invalid ScriptLoader filename: '%s'", filename )))

    local result = require( param )

    if post_fn then
        result = post_fn( filename, result )
    end

    if self.OnLoadScript then
        self:OnLoadScript(result, filename)
    end
    return result
end

-- base_dir is relative to data. ex: "scripts/dbui"
-- post_fn( filename, result ) lets you process the content of each file.
function ScriptLoader:LoadAllScript(base_dir, post_fn)
    --~ local _perf1 <close> = PROFILE_SECTION( "ScriptLoader:LoadAllScript", base_dir )
    local function recurse( folder )
        -- Hit an error because lua.exe doesn't have TheSim? If the lua code is
        -- *never* run by the game, add to your script: require "nativeshims"
        local files = TheSim:ListFiles( folder, "*.lua", LIST_FILES.FILES)
        table.sort( files )
        local directories = TheSim:ListFiles( folder, "*", LIST_FILES.DIRS)
        table.sort( directories )

        for _,v in ipairs(files) do
            local filename = folder.."/"..v
            if INCLUDE_ARCHIVED or folder:find("archive") == nil then
                self:LoadScript( filename, post_fn )
            end
        end
        local count = #files

        for _,v in ipairs(directories) do
            local filename = folder.."/"..v
            count = count + recurse( filename )
        end

        return count
    end

    local st = os.clock()
    local count = recurse( base_dir )
    print( "Preloading", count, "script files in", base_dir, "took", (os.clock() - st) * 1000, "ms" )
end

return ScriptLoader
