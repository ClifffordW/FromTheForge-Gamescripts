-- Generated by AnimTagger and loaded by animtag_autogen.lua
return {
  __displayName="sound_heartstone",
  anim_events={
    power_drop_boss={
      shatter={ done=true, events={ { frame=3, name="sfx-absorb", postfix="_heart",},},},
      spawn={
        done=true,
        events={
          { frame=1, name="sfx-energy", postfix="_heart",},
          { frame=43, name="sfx-explode", postfix="_heart",},
        },
      },
    },
    power_drop_generic={
      idle={
        done=true,
        events={
          { frame=0, name="sfx-rattle", postfix="_1",},
          { frame=15, name="sfx-rattle", postfix="_1",},
          { frame=45, name="sfx-rattle", postfix="_1",},
          { frame=84, name="sfx-rattle", postfix="_1",},
          { frame=119, name="sfx-rattle", postfix="_1",},
        },
      },
      shatter={
        done=true,
        events={
          { frame=1, name="sfx-rumble", postfix="_1",},
          { frame=10, name="sfx-shatter_crystal", postfix="_1",},
          { frame=10, name="sfx-shatter_tail", postfix="_1",},
        },
      },
      spawn={
        done=true,
        events={
          { frame=1, name="sfx-energy", postfix="_1",},
          { frame=5, name="sfx-crystallize", postfix="_1",},
          { frame=34, name="sfx-ping", postfix="_1",},
        },
      },
    },
  },
  prefab={
    { baseanim="heart", prefab="soul_drop_boss_megatreemon",},
    { baseanim="heart", prefab="soul_drop_boss_bandicoot",},
    { baseanim="heart", prefab="soul_drop_boss_owlitzer",},
    { baseanim="heart", prefab="soul_drop_boss_thatcher",},
  },
}