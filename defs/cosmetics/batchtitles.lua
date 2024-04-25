return {

    ----------------------------NOTES----------------------------
    --[[
        --The strings for these titles can be found in data/scripts/defs/cosmetics/strings_cosmetics.lua
        
        --Titles can be batch generated and/or individually edited in the Cosmetic Editor in-game (control-P and type "cosmetic editor")
        
        --Autogenning titles using the "Gen from batch" button will create game files that can be found at
        data/scripts/prefabs/autogen/cosmetic

        --The "Gen from batch" button *won't* delete game files if a title has been removed, so you'll have to
        go into data/scripts/prefabs/autogen/cosmetic and delete the file to remove a title from the game

        --If you group select all the files in data/scripts/prefabs/autogen/cosmetic and delete them to do a fresh gen batch, 
        make sure you don't delete the default_title.lua or the game will have no title to default to and will crash
    ]]

    ----------------------------TITLES----------------------------

    --UNASSIGNED!-- These titles have no associated mastery. Give them a home!
        {
            name = "buckaroo",
            cosmetic_data={ title_key="BUCKAROO",},
        },
        {
            name = "ace",
            cosmetic_data={ title_key="ACE",},
        },
        {
            name = "pawbeans",
            cosmetic_data={ title_key="PAWBEANS",},
        },
        --titles that unlock from completing toot tutorials
        {
            name = "teacherspet",
            cosmetic_data={ title_key="TEACHERSPET",},
        },
        {
            name = "hunterphd",
            cosmetic_data={ title_key="HUNTERPHD",},
        },
        --queen/king/royalty should unlock together
        {
            name = "highqueen",
            cosmetic_data={ title_key="HIGHQUEEN",},
        },
        {
            name = "highking",
            cosmetic_data={ title_key="HIGHKING",},
        },
        {
            name = "highroyalty",
            cosmetic_data={ title_key="HIGHROYALTY",},
        },
        {
            name = "goofygoober",
            cosmetic_data={ title_key="GOOFYGOOBER",},
        },
        {
            name = "shredder",
            cosmetic_data={ title_key="SHREDDER",},
        },
        {
            name = "creepycryptid",
            cosmetic_data={ title_key="CREEPYCRYPTID",},
        },
        {
            name = "teammascot",
            cosmetic_data={ title_key="TEAMMASCOT",},
        },
        {
            name = "pocketmedic",
            cosmetic_data={ title_key="POCKETMEDIC",},
        },
        {
            name = "glasscannon",
            cosmetic_data={ title_key="GLASSCANNON",},
        },
        {
            name = "tank",
            cosmetic_data={ title_key="TANK",},
        },
        --maybe from crafting a certain number of armour pieces?
        {
            name = "fashionista",
            cosmetic_data={ title_key="FASHIONISTA",},
        },
        {
            name = "jokesclown",
            cosmetic_data={ title_key="JOKESCLOWN",},
        },
        {
            name = "mysteriousstranger",
            cosmetic_data={ title_key="MYSTERIOUSSTRANGER",},
        },
        {
            name = "chickenchaser",
            cosmetic_data={ title_key="CHICKENCHASER",},
        },
        {
            name = "impostor",
            cosmetic_data={ title_key="IMPOSTOR",},
        },

    --------------------------

    --HAMMER ("HAMMER_MASTERY")--
        --golf swing mastery
        {
            name = "albatross",
            mastery="HAMMER_MASTERY",
            
            cosmetic_data={ title_key="ALBATROSS",},
        },
    --------------------------

    --POLEARM ("POLEARM_MASTERY")--
        --advanced drill mastery
        {
            name = "drillsergeant",
            mastery="POLEARM_MASTERY",
            
            cosmetic_data={ title_key="DRILLSERGEANT",},
        },
    --------------------------
    
    --CANNON ("CANNON_MASTERY")--
        {
            name = "boomer",
            
            cosmetic_data={ title_key="BOOMER",},
        },
    --------------------------

    --STRIKER ("STRIKER_MASTERY")--
        {
            name = "juggler",
            
            cosmetic_data={ title_key="JUGGLER",},
        },
    --------------------------

    --ALL WEAPONS--
        --all weapon mastery
        {
            name = "battlemaster",
            
            cosmetic_data={ title_key="BATTLEMASTER",},
        },
    --------------------------

    --TREEMON FOREST TITLES--
        --cabbage roll mastery
        {
            name = "lilbuddy",
            mastery="CABBAGEROLL_MASTERY",
            
            cosmetic_data={ title_key="LILBUDDY",},
        },

        --beets mastery
        {
            name = "beetmaster",
            
            cosmetic_data={ title_key="BEETMASTER",},
        },

        --zucco, gourdo, yammo kill mastery
        {
            name = "piemaster",
            
            cosmetic_data={ title_key="PIEMASTER",},
        },

        --treemon mastery
        {
            name = "treehugger",
            
            cosmetic_data={ title_key="TREEHUGGER",},
        },

        --megatreemon mastery
        {
            name = "forestkeeper",
            
            cosmetic_data={ title_key="FORESTKEEPER",},
        },

        --gnarlic mastery
        {
            name = "stinky",
            
            cosmetic_data={ title_key="STINKY",},
        },
    --------------------------

    --OWLITZER FOREST TITLES--
        --owlitzer mastery
        {
            name = "nightshroud",
            
            cosmetic_data={ title_key="NIGHTSHROUD",},
        },

        --floracrane mastery
        {
            name = "primaballerina",
            
            cosmetic_data={ title_key="PRIMABALLERINA",},
        },

        --eyev mastery
        {
            name = "watcher",
            
            cosmetic_data={ title_key="WATCHER",},
        },
    --------------------------

    --BANDICOOT SWAMP TITLES--
        --bandicoot mastery
        {
            name = "madtrickster",
            
            cosmetic_data={ title_key="MADTRICKSTER",},
        },

        --slowpoke mastery
        {
            name = "chubbster",
            
            cosmetic_data={ title_key="CHUBBSTER",},
        },

        --woworm mastery
        {
            name = "woworm",
            
            cosmetic_data={ title_key="WOWORM",},
        },
    --------------------------
}